import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

export type CachedPostPayload = Record<string, unknown>;

/**
 * Optional Redis cache for hot post reads (shared payload, no per-user fields).
 * Fail-open: if Redis is down, all paths fall back to PostgreSQL.
 */
@Injectable()
export class CommunityCacheService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(CommunityCacheService.name);
  private client: Redis | null = null;
  private readonly keyPrefix = 'comm:v1:post:';

  constructor(private readonly config: ConfigService) {}

  async onModuleInit() {
    const host = this.config.get<string>('redis.host', 'localhost');
    const port = this.config.get<number>('redis.port', 6379);
    const password = this.config.get<string>('redis.password');
    const redis = new Redis({
      host,
      port,
      password: password || undefined,
      lazyConnect: true,
      maxRetriesPerRequest: 2,
      enableReadyCheck: true,
    });
    try {
      await redis.connect();
      this.client = redis;
      this.logger.log('Redis connected (community post cache)');
    } catch (e) {
      this.logger.warn(
        `Community cache disabled — Redis unavailable: ${(e as Error).message}`,
      );
      redis.disconnect();
      this.client = null;
    }
  }

  async onModuleDestroy() {
    if (this.client) {
      await this.client.quit().catch(() => undefined);
      this.client = null;
    }
  }

  private enabled(): boolean {
    return this.client !== null && this.client.status === 'ready';
  }

  postKey(postId: string): string {
    return `${this.keyPrefix}${postId}`;
  }

  async getPostPayload(postId: string): Promise<CachedPostPayload | null> {
    if (!this.enabled()) return null;
    try {
      const raw = await this.client!.get(this.postKey(postId));
      if (!raw) return null;
      return JSON.parse(raw) as CachedPostPayload;
    } catch (e) {
      this.logger.warn(`getPostPayload ${postId}: ${(e as Error).message}`);
      return null;
    }
  }

  async setPostPayload(
    postId: string,
    payload: CachedPostPayload,
    ttlSec: number,
  ): Promise<void> {
    if (!this.enabled()) return;
    try {
      await this.client!.set(
        this.postKey(postId),
        JSON.stringify(payload),
        'EX',
        ttlSec,
      );
    } catch (e) {
      this.logger.warn(`setPostPayload ${postId}: ${(e as Error).message}`);
    }
  }

  async invalidatePost(postId: string): Promise<void> {
    if (!this.enabled()) return;
    try {
      await this.client!.del(this.postKey(postId));
    } catch (e) {
      this.logger.warn(`invalidatePost ${postId}: ${(e as Error).message}`);
    }
  }
}
