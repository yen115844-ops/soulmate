import { BadRequestException, ForbiddenException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConversationStatus, MessageStatus, MessageType, NotificationType } from '@prisma/client';
import { PrismaService } from '../../database/prisma/prisma.service';
import { NotificationsService } from '../notifications';
import {
    CreateConversationDto,
    QueryConversationsDto,
    QueryMessagesDto,
    SendMessageWithMediaDto
} from './dto';

// Online users tracking (in-memory, consider Redis for production with multiple instances)
const onlineUsersMap = new Map<string, boolean>();

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ==================== Online Status ====================

  /**
   * Set user online status
   */
  setUserOnline(userId: string, isOnline: boolean) {
    if (isOnline) {
      onlineUsersMap.set(userId, true);
    } else {
      onlineUsersMap.delete(userId);
    }
    this.logger.debug(`User ${userId} is now ${isOnline ? 'online' : 'offline'}`);
  }

  /**
   * Check if user is online
   */
  isUserOnline(userId: string): boolean {
    return onlineUsersMap.get(userId) || false;
  }

  /**
   * Get online status for multiple users
   */
  getOnlineStatus(userIds: string[]): Record<string, boolean> {
    const result: Record<string, boolean> = {};
    for (const userId of userIds) {
      result[userId] = this.isUserOnline(userId);
    }
    return result;
  }

  // ==================== Block User Checks ====================

  /**
   * Check if there's a block relationship between two users
   */
  async isBlockedRelationship(userId1: string, userId2: string): Promise<boolean> {
    const block = await this.prisma.userBlacklist.findFirst({
      where: {
        OR: [
          { blockerId: userId1, blockedId: userId2 },
          { blockerId: userId2, blockedId: userId1 },
        ],
      },
    });
    return !!block;
  }

  /**
   * Check if current user blocked the target user
   */
  async hasUserBlocked(userId: string, targetUserId: string): Promise<boolean> {
    const block = await this.prisma.userBlacklist.findUnique({
      where: {
        blockerId_blockedId: {
          blockerId: userId,
          blockedId: targetUserId,
        },
      },
    });
    return !!block;
  }

  /**
   * Get list of blocked user IDs (both directions)
   */
  async getBlockedUserIds(userId: string): Promise<string[]> {
    const blocks = await this.prisma.userBlacklist.findMany({
      where: {
        OR: [
          { blockerId: userId },
          { blockedId: userId },
        ],
      },
      select: {
        blockerId: true,
        blockedId: true,
      },
    });

    const blockedIds = new Set<string>();
    blocks.forEach((block) => {
      if (block.blockerId === userId) {
        blockedIds.add(block.blockedId);
      } else {
        blockedIds.add(block.blockerId);
      }
    });

    return Array.from(blockedIds);
  }

  /**
   * Get all conversations for a user
   */
  async getConversations(userId: string, dto: QueryConversationsDto) {
    const { page = 1, limit = 20 } = dto;
    const skip = (page - 1) * limit;

    const [conversations, total] = await Promise.all([
      this.prisma.conversation.findMany({
        where: {
          participants: {
            some: {
              userId,
              leftAt: null, // Chỉ lấy cuộc trò chuyện chưa bị xoá
            },
          },
          status: ConversationStatus.ACTIVE,
        },
        include: {
          participants: {
            include: {
              user: {
                include: {
                  profile: {
                    select: {
                      fullName: true,
                      displayName: true,
                      avatarUrl: true,
                    },
                  },
                },
                omit: {
                  passwordHash: true,
                },
              },
            },
          },
          messages: {
            take: 1,
            orderBy: { createdAt: 'desc' },
          },
        },
        orderBy: { lastMessageAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.conversation.count({
        where: {
          participants: {
            some: {
              userId,
              leftAt: null,
            },
          },
          status: ConversationStatus.ACTIVE,
        },
      }),
    ]);

    // Transform to include unread count and other user info
    // Also filter out blocked users
    const blockedUserIds = await this.getBlockedUserIds(userId);
    
    const filteredConversations = conversations.filter((conv) => {
      const otherParticipant = conv.participants.find((p) => p.userId !== userId);
      return otherParticipant && !blockedUserIds.includes(otherParticipant.userId);
    });

    // Batch fetch unread counts in a single query to avoid N+1
    const unreadCountsRaw = await this.prisma.message.groupBy({
      by: ['conversationId'],
      where: {
        conversationId: { in: filteredConversations.map((c) => c.id) },
        senderId: { not: userId },
        isDeleted: false,
      },
      _count: { id: true },
    });

    // Build a map: conversationId -> total messages not from user
    const totalMsgMap = new Map(unreadCountsRaw.map((r) => [r.conversationId, r._count.id]));

    // For conversations with lastReadAt, we need to count only messages after lastReadAt
    // Build the participant map for lastReadAt
    const participantMap = new Map(
      filteredConversations.map((conv) => {
        const participant = conv.participants.find((p) => p.userId === userId);
        return [conv.id, participant?.lastReadAt ?? null];
      }),
    );

    // For conversations that have lastReadAt, do a single batch query
    const convsWithLastRead = filteredConversations.filter(
      (c) => participantMap.get(c.id) != null,
    );
    
    let unreadAfterReadMap = new Map<string, number>();
    if (convsWithLastRead.length > 0) {
      // Use Promise.all but with a single query per conversation that has lastReadAt
      // This is still better than N+1 since we only query conversations with read markers
      const unreadCounts = await Promise.all(
        convsWithLastRead.map(async (conv) => {
          const lastReadAt = participantMap.get(conv.id)!;
          const count = await this.prisma.message.count({
            where: {
              conversationId: conv.id,
              senderId: { not: userId },
              isDeleted: false,
              createdAt: { gt: lastReadAt },
            },
          });
          return { id: conv.id, count };
        }),
      );
      unreadAfterReadMap = new Map(unreadCounts.map((r) => [r.id, r.count]));
    }

    const transformedConversations = filteredConversations.map((conv) => {
      const currentParticipant = conv.participants.find((p) => p.userId === userId);
      const otherParticipant = conv.participants.find((p) => p.userId !== userId);

      // Use batch unread count: if lastReadAt exists, use the filtered count; otherwise use total
      const unreadCount = participantMap.get(conv.id)
        ? (unreadAfterReadMap.get(conv.id) ?? 0)
        : (totalMsgMap.get(conv.id) ?? 0);

      return {
        id: conv.id,
        lastMessage: conv.messages[0] || null,
        lastMessageAt: conv.lastMessageAt,
        lastMessagePreview: conv.lastMessagePreview,
        createdAt: conv.createdAt,
        otherUser: otherParticipant
          ? {
              id: otherParticipant.userId,
              name:
                otherParticipant.user.profile?.displayName ||
                otherParticipant.user.profile?.fullName ||
                otherParticipant.user.email.split('@')[0],
              avatarUrl: otherParticipant.user.profile?.avatarUrl,
              isOnline: this.isUserOnline(otherParticipant.userId),
            }
          : null,
        unreadCount,
        isMuted: currentParticipant?.isMuted || false,
      };
    });

    return {
      data: transformedConversations,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNextPage: page * limit < total,
        hasPreviousPage: page > 1,
      },
    };
  }

  /**
   * Get or create a conversation with another user
   */
  async getOrCreateConversation(userId: string, dto: CreateConversationDto) {
    const { participantId, initialMessage } = dto;

    // Check if user is not talking to themselves
    if (userId === participantId) {
      throw new BadRequestException('Cannot create conversation with yourself');
    }

    // Check if blocked
    const isBlocked = await this.isBlockedRelationship(userId, participantId);
    if (isBlocked) {
      throw new BadRequestException('Không thể trò chuyện với người dùng này. Đã bị chặn.');
    }

    // Check if the other user exists
    const otherUser = await this.prisma.user.findUnique({
      where: { id: participantId },
      include: {
        profile: {
          select: {
            fullName: true,
            displayName: true,
            avatarUrl: true,
          },
        },
      },
    });

    if (!otherUser) {
      throw new NotFoundException('User not found');
    }

    // Find existing conversation between these two users
    const existingConversation = await this.prisma.conversation.findFirst({
      where: {
        AND: [
          { participants: { some: { userId } } },
          { participants: { some: { userId: participantId } } },
        ],
        status: ConversationStatus.ACTIVE,
      },
      include: {
        participants: {
          include: {
            user: {
              include: {
                profile: {
                  select: {
                    fullName: true,
                    displayName: true,
                    avatarUrl: true,
                  },
                },
              },
              omit: {
                passwordHash: true,
              },
            },
          },
        },
      },
    });

    if (existingConversation) {
      // If initial message provided, send it
      if (initialMessage) {
        await this.sendMessage(userId, existingConversation.id, {
          content: initialMessage,
          type: 'text',
        });
      }

      return this.transformConversation(existingConversation, userId);
    }

    // DON'T create empty conversation - only create when there's an initial message
    // This prevents "ghost" conversations appearing in the other user's list
    if (!initialMessage) {
      // Return a virtual conversation object (not saved to DB)
      return {
        id: null, // null indicates no real conversation yet
        isVirtual: true,
        createdAt: new Date(),
        lastMessageAt: null,
        lastMessagePreview: null,
        otherUser: {
          id: participantId,
          name:
            otherUser.profile?.displayName ||
            otherUser.profile?.fullName ||
            otherUser.email.split('@')[0],
          avatarUrl: otherUser.profile?.avatarUrl,
          isOnline: this.isUserOnline(participantId),
        },
        unreadCount: 0,
        isMuted: false,
      };
    }

    // Create new conversation only when there's an initial message
    const newConversation = await this.prisma.conversation.create({
      data: {
        participants: {
          create: [
            { userId, role: 'user' },
            { userId: participantId, role: 'partner' },
          ],
        },
      },
      include: {
        participants: {
          include: {
            user: {
              include: {
                profile: {
                  select: {
                    fullName: true,
                    displayName: true,
                    avatarUrl: true,
                  },
                },
              },
              omit: {
                passwordHash: true,
              },
            },
          },
        },
      },
    });

    this.logger.log(`Created new conversation: ${newConversation.id}`);

    // Send the initial message
    await this.sendMessage(userId, newConversation.id, {
      content: initialMessage,
      type: 'text',
    });

    return this.transformConversation(newConversation, userId);
  }

  /**
   * Find existing conversation between two users (doesn't create new one)
   */
  async findConversation(userId: string, participantId: string) {
    // Check if user is not talking to themselves
    if (userId === participantId) {
      throw new BadRequestException('Cannot create conversation with yourself');
    }

    // Check if either user has blocked the other
    const blockExists = await this.prisma.userBlacklist.findFirst({
      where: {
        OR: [
          { blockerId: userId, blockedId: participantId },
          { blockerId: participantId, blockedId: userId },
        ],
      },
    });

    if (blockExists) {
      throw new ForbiddenException('Không thể nhắn tin với người dùng này');
    }

    // Check if the other user exists
    const otherUser = await this.prisma.user.findUnique({
      where: { id: participantId },
      include: {
        profile: {
          select: {
            fullName: true,
            displayName: true,
            avatarUrl: true,
          },
        },
      },
    });

    if (!otherUser) {
      throw new NotFoundException('User not found');
    }

    // Find existing conversation between these two users
    const existingConversation = await this.prisma.conversation.findFirst({
      where: {
        AND: [
          { participants: { some: { userId } } },
          { participants: { some: { userId: participantId } } },
        ],
        status: ConversationStatus.ACTIVE,
      },
      include: {
        participants: {
          include: {
            user: {
              include: {
                profile: {
                  select: {
                    fullName: true,
                    displayName: true,
                    avatarUrl: true,
                  },
                },
              },
              omit: {
                passwordHash: true,
              },
            },
          },
        },
      },
    });

    if (existingConversation) {
      return this.transformConversation(existingConversation, userId);
    }

    // Return virtual conversation info (not saved to DB)
    return {
      id: null,
      isVirtual: true,
      createdAt: new Date(),
      lastMessageAt: null,
      lastMessagePreview: null,
      otherUser: {
        id: participantId,
        name:
          otherUser.profile?.displayName ||
          otherUser.profile?.fullName ||
          otherUser.email.split('@')[0],
        avatarUrl: otherUser.profile?.avatarUrl,
        isOnline: this.isUserOnline(participantId),
      },
      unreadCount: 0,
      isMuted: false,
    };
  }

  /**
   * Create conversation and send first message (used when sending to a new user)
   */
  async createConversationWithMessage(
    userId: string,
    participantId: string,
    message: string,
  ) {
    // Check if user is not talking to themselves
    if (userId === participantId) {
      throw new BadRequestException('Cannot create conversation with yourself');
    }

    // Check if blocked
    const isBlocked = await this.isBlockedRelationship(userId, participantId);
    if (isBlocked) {
      throw new BadRequestException('Không thể trò chuyện với người dùng này. Đã bị chặn.');
    }

    // Check if the other user exists
    const otherUser = await this.prisma.user.findUnique({
      where: { id: participantId },
    });

    if (!otherUser) {
      throw new NotFoundException('User not found');
    }

    // Check for existing conversation first
    const existingConversation = await this.prisma.conversation.findFirst({
      where: {
        AND: [
          { participants: { some: { userId } } },
          { participants: { some: { userId: participantId } } },
        ],
        status: ConversationStatus.ACTIVE,
      },
    });

    if (existingConversation) {
      // Send message to existing conversation
      const sentMessage = await this.sendMessage(userId, existingConversation.id, {
        content: message,
        type: 'text',
      });
      
      return {
        conversation: await this.getConversationById(existingConversation.id, userId),
        message: sentMessage,
        isNew: false,
      };
    }

    // Create new conversation
    const newConversation = await this.prisma.conversation.create({
      data: {
        participants: {
          create: [
            { userId, role: 'user' },
            { userId: participantId, role: 'partner' },
          ],
        },
      },
    });

    // Send the first message
    const sentMessage = await this.sendMessage(userId, newConversation.id, {
      content: message,
      type: 'text',
    });

    this.logger.log(`Created new conversation with message: ${newConversation.id}`);

    return {
      conversation: await this.getConversationById(newConversation.id, userId),
      message: sentMessage,
      isNew: true,
    };
  }

  /**
   * Get conversation by ID
   */
  async getConversationById(conversationId: string, userId: string) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
      include: {
        participants: {
          include: {
            user: {
              include: {
                profile: {
                  select: {
                    fullName: true,
                    displayName: true,
                    avatarUrl: true,
                  },
                },
              },
              omit: {
                passwordHash: true,
              },
            },
          },
        },
      },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    return this.transformConversation(conversation, userId);
  }

  /**
   * Get messages for a conversation
   */
  async getMessages(userId: string, conversationId: string, dto: QueryMessagesDto) {
    const { page = 1, limit = 50, before } = dto;

    // Check user is participant
    const participant = await this.prisma.conversationParticipant.findUnique({
      where: {
        conversationId_userId: { conversationId, userId },
      },
    });

    if (!participant) {
      throw new NotFoundException('Conversation not found');
    }

    const where: any = {
      conversationId,
      isDeleted: false,
    };

    // Cursor-based pagination
    if (before) {
      const beforeMessage = await this.prisma.message.findUnique({
        where: { id: before },
      });
      if (beforeMessage) {
        where.createdAt = { lt: beforeMessage.createdAt };
      }
    }

    const [messages, total] = await Promise.all([
      this.prisma.message.findMany({
        where,
        include: {
          sender: {
            select: {
              id: true,
              email: true,
              profile: {
                select: {
                  fullName: true,
                  displayName: true,
                  avatarUrl: true,
                },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
      }),
      this.prisma.message.count({ where: { conversationId, isDeleted: false } }),
    ]);

    // Mark messages as read
    await this.markMessagesAsRead(userId, conversationId);

    return {
      data: messages.reverse(), // Return in chronological order
      meta: {
        total,
        page,
        limit,
        hasMore: messages.length === limit,
      },
    };
  }

  /**
   * Send a message
   */
  async sendMessage(userId: string, conversationId: string, dto: SendMessageWithMediaDto) {
    // Check user is participant
    const participant = await this.prisma.conversationParticipant.findUnique({
      where: {
        conversationId_userId: { conversationId, userId },
      },
      include: {
        conversation: {
          include: {
            participants: true,
          },
        },
      },
    });

    if (!participant) {
      throw new NotFoundException('Conversation not found');
    }

    // Check if blocked by the other user or if user has blocked the other user
    const otherParticipant = participant.conversation.participants.find(
      (p) => p.userId !== userId,
    );
    
    if (otherParticipant) {
      const isBlocked = await this.isBlockedRelationship(userId, otherParticipant.userId);
      if (isBlocked) {
        throw new BadRequestException('Không thể gửi tin nhắn. Người dùng đã bị chặn hoặc đã chặn bạn.');
      }
    }

    const messageType = this.parseMessageType(dto.type);
    const content = dto.content || (dto.mediaUrl ? dto.mediaUrl : '');
    const preview = this.createMessagePreview(content, messageType);

    const message = await this.prisma.message.create({
      data: {
        conversationId,
        senderId: userId,
        content,
        type: messageType,
        status: MessageStatus.SENT,
        mediaUrl: dto.mediaUrl,
      },
      include: {
        sender: {
          select: {
            id: true,
            email: true,
            profile: {
              select: {
                fullName: true,
                displayName: true,
                avatarUrl: true,
              },
            },
          },
        },
      },
    });

    // Update conversation
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: {
        lastMessageAt: message.createdAt,
        lastMessagePreview: preview,
      },
    });

    // Send push notification to other participants
    const otherParticipants = await this.prisma.conversationParticipant.findMany({
      where: {
        conversationId,
        userId: { not: userId },
      },
      select: { userId: true },
    });

    const senderName = message.sender.profile?.displayName || message.sender.email;
    const senderAvatar = message.sender.profile?.avatarUrl || undefined;

    for (const participant of otherParticipants) {
      // Only send FCM push, do NOT save to notification panel
      // (messages have their own chat history)
      await this.notificationsService.sendNotification({
        userId: participant.userId,
        type: NotificationType.CHAT,
        title: senderName,
        body: preview,
        imageUrl: senderAvatar,
        actionType: 'chat',
        actionId: conversationId,
        data: {
          conversationId,
          messageId: message.id,
          senderId: userId,
        },
        saveToDb: false,
      });
    }

    return message;
  }

  /**
   * Mark messages as read
   */
  async markMessagesAsRead(userId: string, conversationId: string) {
    // Update participant's last read
    await this.prisma.conversationParticipant.update({
      where: {
        conversationId_userId: { conversationId, userId },
      },
      data: {
        lastReadAt: new Date(),
      },
    });

    // Mark all unread messages as read
    await this.prisma.message.updateMany({
      where: {
        conversationId,
        senderId: { not: userId },
        status: { not: MessageStatus.READ },
      },
      data: {
        status: MessageStatus.READ,
        readAt: new Date(),
      },
    });
  }

  /**
   * Get unread count for user
   */
  async getUnreadCount(userId: string): Promise<number> {
    const conversations = await this.prisma.conversationParticipant.findMany({
      where: { userId, leftAt: null },
      select: {
        conversationId: true,
        lastReadAt: true,
      },
    });

    let totalUnread = 0;
    for (const conv of conversations) {
      const unread = await this.prisma.message.count({
        where: {
          conversationId: conv.conversationId,
          senderId: { not: userId },
          createdAt: conv.lastReadAt ? { gt: conv.lastReadAt } : undefined,
        },
      });
      totalUnread += unread;
    }

    return totalUnread;
  }

  /**
   * Get unread count for a specific conversation
   */
  async getUnreadCountForConversation(
    conversationId: string,
    userId: string,
    lastReadAt?: Date | null,
  ): Promise<number> {
    const whereCondition: any = {
      conversationId,
      senderId: { not: userId },
      isDeleted: false,
    };

    if (lastReadAt) {
      whereCondition.createdAt = { gt: lastReadAt };
    }

    return this.prisma.message.count({ where: whereCondition });
  }

  /**
   * Search messages in a conversation
   */
  async searchMessages(
    userId: string,
    conversationId: string,
    dto: { query: string; page?: number; limit?: number },
  ) {
    const { query, page = 1, limit = 20 } = dto;
    const skip = (page - 1) * limit;

    // Check user is participant
    const participant = await this.prisma.conversationParticipant.findUnique({
      where: {
        conversationId_userId: { conversationId, userId },
      },
    });

    if (!participant) {
      throw new NotFoundException('Conversation not found');
    }

    const [messages, total] = await Promise.all([
      this.prisma.message.findMany({
        where: {
          conversationId,
          isDeleted: false,
          content: {
            contains: query,
            mode: 'insensitive',
          },
        },
        include: {
          sender: {
            include: {
              profile: {
                select: {
                  fullName: true,
                  displayName: true,
                  avatarUrl: true,
                },
              },
            },
            omit: {
              passwordHash: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.message.count({
        where: {
          conversationId,
          isDeleted: false,
          content: {
            contains: query,
            mode: 'insensitive',
          },
        },
      }),
    ]);

    return {
      data: messages.map((msg) => ({
        id: msg.id,
        conversationId: msg.conversationId,
        senderId: msg.senderId,
        sender: msg.sender,
        type: msg.type,
        content: msg.content,
        status: msg.status,
        mediaUrl: msg.mediaUrl,
        createdAt: msg.createdAt,
        readAt: msg.readAt,
      })),
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Toggle mute for a conversation
   */
  async toggleMuteConversation(
    userId: string,
    conversationId: string,
    muted: boolean,
  ) {
    // Check user is participant
    const participant = await this.prisma.conversationParticipant.findUnique({
      where: {
        conversationId_userId: { conversationId, userId },
      },
    });

    if (!participant) {
      throw new NotFoundException('Conversation not found');
    }

    await this.prisma.conversationParticipant.update({
      where: {
        conversationId_userId: { conversationId, userId },
      },
      data: {
        isMuted: muted,
      },
    });

    return { success: true, muted };
  }

  /**
   * Xoá cuộc trò chuyện khỏi danh sách (ẩn cho user hiện tại)
   */
  async leaveConversation(userId: string, conversationId: string) {
    const participant = await this.prisma.conversationParticipant.findUnique({
      where: {
        conversationId_userId: { conversationId, userId },
      },
    });

    if (!participant) {
      throw new NotFoundException('Conversation not found');
    }

    if (participant.leftAt) {
      return { success: true, message: 'Conversation already left' };
    }

    await this.prisma.conversationParticipant.update({
      where: {
        conversationId_userId: { conversationId, userId },
      },
      data: { leftAt: new Date() },
    });

    return { success: true, message: 'Conversation removed' };
  }

  // ==================== Gateway Helper Methods ====================

  /**
   * Check if user is participant of a conversation
   */
  async isConversationParticipant(
    conversationId: string,
    userId: string,
  ): Promise<boolean> {
    const participant = await this.prisma.conversationParticipant.findUnique({
      where: {
        conversationId_userId: { conversationId, userId },
      },
    });
    return !!participant;
  }

  /**
   * Get conversation participants
   */
  async getConversationParticipants(conversationId: string) {
    return this.prisma.conversationParticipant.findMany({
      where: { conversationId },
      select: {
        userId: true,
        role: true,
      },
    });
  }

  /**
   * Mark messages as delivered
   */
  async markMessagesAsDelivered(conversationId: string, userId: string) {
    await this.prisma.message.updateMany({
      where: {
        conversationId,
        senderId: { not: userId },
        status: MessageStatus.SENT,
      },
      data: {
        status: MessageStatus.DELIVERED,
        deliveredAt: new Date(),
      },
    });
  }

  /**
   * Update message status
   */
  async updateMessageStatus(
    messageId: string,
    status: 'SENT' | 'DELIVERED' | 'READ',
  ) {
    const data: any = { status };
    
    if (status === 'DELIVERED') {
      data.deliveredAt = new Date();
    } else if (status === 'READ') {
      data.readAt = new Date();
    }

    return this.prisma.message.update({
      where: { id: messageId },
      data,
    });
  }

  /**
   * Send message with media (for socket)
   */
  async sendMessageWithMedia(
    userId: string,
    conversationId: string,
    dto: SendMessageWithMediaDto,
  ) {
    // Check user is participant
    const participant = await this.prisma.conversationParticipant.findUnique({
      where: {
        conversationId_userId: { conversationId, userId },
      },
    });

    if (!participant) {
      throw new NotFoundException('Conversation not found');
    }

    const messageType = this.parseMessageType(dto.type);
    const preview = this.createMessagePreview(dto.content || '', messageType);

    const messageData: any = {
      conversationId,
      senderId: userId,
      content: dto.content,
      type: messageType,
      status: MessageStatus.SENT,
    };

    // Add media data if present
    if (dto.mediaUrl) {
      messageData.mediaUrl = dto.mediaUrl;
    }

    // Add location data if present
    if (dto.location) {
      messageData.locationLat = dto.location.lat;
      messageData.locationLng = dto.location.lng;
      messageData.locationAddress = dto.location.address;
    }

    const message = await this.prisma.message.create({
      data: messageData,
      include: {
        sender: {
          select: {
            id: true,
            email: true,
            profile: {
              select: {
                fullName: true,
                displayName: true,
                avatarUrl: true,
              },
            },
          },
        },
      },
    });

    // Update conversation
    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: {
        lastMessageAt: message.createdAt,
        lastMessagePreview: preview,
      },
    });

    // Send push notification to offline participants
    const otherParticipants = await this.prisma.conversationParticipant.findMany({
      where: {
        conversationId,
        userId: { not: userId },
      },
      select: { userId: true },
    });

    const senderName = message.sender.profile?.displayName || message.sender.email;
    const senderAvatar = message.sender.profile?.avatarUrl || undefined;

    for (const p of otherParticipants) {
      // Only send push if user is offline
      if (!this.isUserOnline(p.userId)) {
        // Only send FCM push, do NOT save to notification panel
        await this.notificationsService.sendNotification({
          userId: p.userId,
          type: NotificationType.CHAT,
          title: senderName,
          body: preview,
          imageUrl: senderAvatar,
          actionType: 'chat',
          actionId: conversationId,
          data: {
            conversationId,
            messageId: message.id,
            senderId: userId,
          },
          saveToDb: false,
        });
      }
    }

    return message;
  }

  // ==================== Helper Methods ====================

  private parseMessageType(type?: string): MessageType {
    switch (type?.toLowerCase()) {
      case 'image':
        return MessageType.IMAGE;
      case 'voice':
        return MessageType.VOICE;
      case 'location':
        return MessageType.LOCATION;
      case 'system':
        return MessageType.SYSTEM;
      default:
        return MessageType.TEXT;
    }
  }

  private createMessagePreview(content: string, type: MessageType): string {
    switch (type) {
      case MessageType.IMAGE:
        return '📷 Hình ảnh';
      case MessageType.VOICE:
        return '🎤 Tin nhắn thoại';
      case MessageType.LOCATION:
        return '📍 Vị trí';
      case MessageType.SYSTEM:
        return content?.substring(0, 100) || 'Thông báo hệ thống';
      default:
        return content?.substring(0, 100) || '';
    }
  }

  private transformConversation(conversation: any, userId: string) {
    const currentParticipant = conversation.participants.find(
      (p: any) => p.userId === userId,
    );
    const otherParticipant = conversation.participants.find(
      (p: any) => p.userId !== userId,
    );

    return {
      id: conversation.id,
      createdAt: conversation.createdAt,
      lastMessageAt: conversation.lastMessageAt,
      lastMessagePreview: conversation.lastMessagePreview,
      otherUser: otherParticipant
        ? {
            id: otherParticipant.userId,
            name:
              otherParticipant.user.profile?.displayName ||
              otherParticipant.user.profile?.fullName ||
              otherParticipant.user.email.split('@')[0],
            avatarUrl: otherParticipant.user.profile?.avatarUrl,
            isOnline: this.isUserOnline(otherParticipant.userId),
          }
        : null,
      unreadCount: 0,
      isMuted: currentParticipant?.isMuted || false,
    };
  }
}
