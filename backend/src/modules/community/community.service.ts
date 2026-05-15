import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../database/prisma/prisma.service';
import {
  NotificationType,
  PostModerationStatus,
  Prisma,
} from '../../generated/prisma/client';
import { NotificationsService } from '../notifications/notifications.service';
import { CommunityCacheService } from './community-cache.service';
import {
  CreateCommentDto,
  CreatePostDto,
  QueryCommentsDto,
  QueryCommunityFeedDto,
} from './dto';

type CursorPayload = { t: string; id: string };

const postInclude = {
  author: {
    select: {
      id: true,
      profile: {
        select: {
          displayName: true,
          fullName: true,
          avatarUrl: true,
        },
      },
    },
  },
} satisfies Prisma.PostInclude;

function mapMediaUrls(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw.filter((x): x is string => typeof x === 'string' && x.length > 0);
}

type AuthorRow = {
  id: string;
  profile: {
    displayName: string | null;
    fullName: string;
    avatarUrl: string | null;
  } | null;
};

function mapAuthor(u: AuthorRow): {
  userId: string;
  displayName: string;
  avatarUrl: string | null;
} {
  const p = u.profile;
  const displayName =
    (p?.displayName?.trim().length ? p.displayName!.trim() : null) ??
    (p?.fullName?.trim().length ? p.fullName!.trim() : null) ??
    'Thành viên';
  return {
    userId: u.id,
    displayName,
    avatarUrl: p?.avatarUrl ?? null,
  };
}

function encodeCursor(createdAt: Date, id: string): string {
  const payload: CursorPayload = { t: createdAt.toISOString(), id };
  return Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
}

function decodeCursor(raw: string): CursorPayload {
  let parsed: unknown;
  try {
    const json = Buffer.from(raw, 'base64url').toString('utf8');
    parsed = JSON.parse(json);
  } catch {
    throw new BadRequestException('Invalid cursor');
  }
  if (
    typeof parsed !== 'object' ||
    parsed === null ||
    !('t' in parsed) ||
    !('id' in parsed)
  ) {
    throw new BadRequestException('Invalid cursor');
  }
  const { t, id } = parsed as CursorPayload;
  if (typeof t !== 'string' || typeof id !== 'string') {
    throw new BadRequestException('Invalid cursor');
  }
  return { t, id };
}

@Injectable()
export class CommunityService {
  private readonly logger = new Logger(CommunityService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly cache: CommunityCacheService,
    private readonly config: ConfigService,
    private readonly notifications: NotificationsService,
  ) {}

  private postCacheTtlSec(): number {
    return this.config.get<number>('COMMUNITY_POST_CACHE_TTL_SEC', 45);
  }

  private async resolveDisplayLabel(userId: string): Promise<string> {
    const row = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        profile: { select: { displayName: true, fullName: true } },
      },
    });
    const p = row?.profile;
    return (
      (p?.displayName?.trim() ? p.displayName!.trim() : null) ??
      (p?.fullName?.trim() ? p.fullName!.trim() : null) ??
      'Một thành viên'
    );
  }

  private fireCommunityPush(
    recipientId: string,
    title: string,
    body: string,
    postId: string,
    data: Record<string, string>,
  ) {
    void this.notifications
      .sendNotification({
        userId: recipientId,
        type: NotificationType.COMMUNITY,
        title,
        body,
        actionType: 'community_post',
        actionId: postId,
        data,
      })
      .catch((e: Error) =>
        this.logger.warn(`Community push skipped: ${e.message}`),
      );
  }

  private toPostPayload(
    row: Prisma.PostGetPayload<{ include: typeof postInclude }>,
  ): Record<string, unknown> {
    return {
      id: row.id,
      authorId: row.authorId,
      author: mapAuthor(row.author),
      body: row.body,
      mediaUrls: mapMediaUrls(row.mediaUrls),
      likeCount: row.likeCount,
      commentCount: row.commentCount,
      createdAt: row.createdAt.toISOString(),
      updatedAt: row.updatedAt.toISOString(),
    };
  }

  async createPost(userId: string, dto: CreatePostDto) {
    const mediaUrls = dto.mediaUrls?.length ? dto.mediaUrls : [];
    const post = await this.prisma.post.create({
      data: {
        authorId: userId,
        body: dto.body.trim(),
        mediaUrls,
        status: PostModerationStatus.ACTIVE,
      },
      include: postInclude,
    });
    await this.cache.invalidatePost(post.id);
    return this.mergeLikedForViewer(
      this.toPostPayload(post) as Record<string, unknown>,
      userId,
    );
  }

  async listFeed(viewerId: string, q: QueryCommunityFeedDto) {
    const limit = q.limit ?? 20;

    let sinceDate: Date | undefined;
    if (q.since?.trim()) {
      const parsed = new Date(q.since.trim());
      if (Number.isNaN(parsed.getTime())) {
        throw new BadRequestException('Invalid since');
      }
      sinceDate = parsed;
    }

    const rawSearch = q.search?.trim();

    const where: Prisma.PostWhereInput = {
      status: PostModerationStatus.ACTIVE,
      ...(q.authorId ? { authorId: q.authorId } : {}),
      ...(rawSearch
        ? {
            body: {
              contains: rawSearch,
              mode: Prisma.QueryMode.insensitive,
            },
          }
        : {}),
      ...(sinceDate ? { createdAt: { gte: sinceDate } } : {}),
    };

    if (q.cursor) {
      const { t, id } = decodeCursor(q.cursor);
      const cursorDate = new Date(t);
      if (Number.isNaN(cursorDate.getTime())) {
        throw new BadRequestException('Invalid cursor');
      }
      where.AND = [
        {
          OR: [
            { createdAt: { lt: cursorDate } },
            {
              AND: [
                { createdAt: cursorDate },
                { id: { lt: id } },
              ],
            },
          ],
        },
      ];
    }

    const rows = await this.prisma.post.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      include: postInclude,
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const ids = page.map((p) => p.id);

    const likes = await this.prisma.postLike.findMany({
      where: { userId: viewerId, postId: { in: ids } },
      select: { postId: true },
    });
    const likedSet = new Set(likes.map((l) => l.postId));

    const items = page.map((row) => ({
      ...(this.toPostPayload(row) as Record<string, unknown>),
      likedByMe: likedSet.has(row.id),
    }));

    const last = page[page.length - 1];
    const nextCursor =
      hasMore && last ? encodeCursor(last.createdAt, last.id) : null;

    return { items, nextCursor };
  }

  async getPostById(viewerId: string, postId: string) {
    const ttl = this.postCacheTtlSec();
    let base: Record<string, unknown> | null =
      (await this.cache.getPostPayload(postId)) as Record<
        string,
        unknown
      > | null;

    if (!base) {
      const row = await this.prisma.post.findFirst({
        where: { id: postId, status: PostModerationStatus.ACTIVE },
        include: postInclude,
      });
      if (!row) throw new NotFoundException('Post not found');
      base = this.toPostPayload(row) as Record<string, unknown>;
      await this.cache.setPostPayload(postId, base, ttl);
    } else {
      // Single cheap check — post may have been hidden since cache write
      const exists = await this.prisma.post.findFirst({
        where: { id: postId, status: PostModerationStatus.ACTIVE },
        select: { id: true },
      });
      if (!exists) {
        await this.cache.invalidatePost(postId);
        throw new NotFoundException('Post not found');
      }
    }

    return this.mergeLikedForViewer(base, viewerId);
  }

  private async mergeLikedForViewer(
    base: Record<string, unknown>,
    viewerId: string,
  ) {
    const postId = base['id'] as string;
    const liked = !!(await this.prisma.postLike.findUnique({
      where: {
        postId_userId: { postId, userId: viewerId },
      },
      select: { postId: true },
    }));
    return { ...base, likedByMe: liked };
  }

  async deletePost(userId: string, postId: string) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId },
      select: { id: true, authorId: true, status: true },
    });
    if (!post || post.status === PostModerationStatus.DELETED) {
      throw new NotFoundException('Post not found');
    }
    if (post.authorId !== userId) {
      throw new ForbiddenException('Not your post');
    }
    await this.prisma.post.update({
      where: { id: postId },
      data: { status: PostModerationStatus.DELETED },
    });
    await this.cache.invalidatePost(postId);
    return { success: true };
  }

  async toggleLike(viewerId: string, postId: string) {
    const postRow = await this.prisma.post.findFirst({
      where: { id: postId, status: PostModerationStatus.ACTIVE },
      select: { id: true, authorId: true },
    });
    if (!postRow) throw new NotFoundException('Post not found');

    const result = await this.prisma.$transaction(async (tx) => {
      const like = await tx.postLike.findUnique({
        where: {
          postId_userId: { postId, userId: viewerId },
        },
      });
      if (like) {
        await tx.postLike.delete({
          where: {
            postId_userId: { postId, userId: viewerId },
          },
        });
        await tx.post.update({
          where: { id: postId },
          data: { likeCount: { decrement: 1 } },
        });
        return { liked: false as const };
      }
      await tx.postLike.create({
        data: { postId, userId: viewerId },
      });
      await tx.post.update({
        where: { id: postId },
        data: { likeCount: { increment: 1 } },
      });
      return { liked: true as const };
    });

    await this.cache.invalidatePost(postId);

    const row = await this.prisma.post.findUnique({
      where: { id: postId },
      select: { likeCount: true },
    });

    if (
      result.liked &&
      postRow.authorId !== viewerId
    ) {
      const who = await this.resolveDisplayLabel(viewerId);
      this.fireCommunityPush(
        postRow.authorId,
        'Có thích mới trên bài của bạn',
        `${who} đã thích một bài đăng của bạn.`,
        postId,
        { kind: 'LIKE', actorId: viewerId, postId },
      );
    }

    return { liked: result.liked, likeCount: row?.likeCount ?? 0 };
  }

  async addComment(
    viewerId: string,
    postId: string,
    dto: CreateCommentDto,
  ) {
    const post = await this.prisma.post.findFirst({
      where: { id: postId, status: PostModerationStatus.ACTIVE },
      select: { id: true, authorId: true },
    });
    if (!post) throw new NotFoundException('Post not found');

    const comment = await this.prisma.$transaction(async (tx) => {
      const c = await tx.postComment.create({
        data: {
          postId,
          authorId: viewerId,
          body: dto.body.trim(),
          status: PostModerationStatus.ACTIVE,
        },
        include: {
          author: postInclude.author,
        },
      });
      await tx.post.update({
        where: { id: postId },
        data: { commentCount: { increment: 1 } },
      });
      return c;
    });

    await this.cache.invalidatePost(postId);

    if (post.authorId !== viewerId) {
      const who = await this.resolveDisplayLabel(viewerId);
      const preview =
        dto.body.trim().length > 80
          ? `${dto.body.trim().slice(0, 80)}…`
          : dto.body.trim();
      this.fireCommunityPush(
        post.authorId,
        'Bình luận mới',
        `${who}: ${preview}`,
        postId,
        {
          kind: 'COMMENT',
          actorId: viewerId,
          postId,
          commentId: comment.id,
        },
      );
    }

    return {
      id: comment.id,
      postId: comment.postId,
      author: mapAuthor(comment.author),
      body: comment.body,
      createdAt: comment.createdAt.toISOString(),
    };
  }

  async listComments(postId: string, q: QueryCommentsDto) {
    const limit = q.limit ?? 30;
    const post = await this.prisma.post.findFirst({
      where: { id: postId, status: PostModerationStatus.ACTIVE },
      select: { id: true },
    });
    if (!post) throw new NotFoundException('Post not found');

    const where: Prisma.PostCommentWhereInput = {
      postId,
      status: PostModerationStatus.ACTIVE,
    };

    if (q.cursor) {
      const { t, id } = decodeCursor(q.cursor);
      const cursorDate = new Date(t);
      if (Number.isNaN(cursorDate.getTime())) {
        throw new BadRequestException('Invalid cursor');
      }
      where.AND = [
        {
          OR: [
            { createdAt: { lt: cursorDate } },
            {
              AND: [
                { createdAt: cursorDate },
                { id: { lt: id } },
              ],
            },
          ],
        },
      ];
    }

    const rows = await this.prisma.postComment.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      include: { author: postInclude.author },
    });

    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    const items = page.map((c) => ({
      id: c.id,
      postId: c.postId,
      author: mapAuthor(c.author),
      body: c.body,
      createdAt: c.createdAt.toISOString(),
    }));
    const last = page[page.length - 1];
    const nextCursor =
      hasMore && last ? encodeCursor(last.createdAt, last.id) : null;

    return { items, nextCursor };
  }
}
