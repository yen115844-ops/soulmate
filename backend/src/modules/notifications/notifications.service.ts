import { InjectQueue } from '@nestjs/bull';
import { Injectable, Logger, NotFoundException, OnModuleInit } from '@nestjs/common';
import { NotificationType } from '@prisma/client';
import type { Queue } from 'bull';
import { PrismaService } from '../../database/prisma/prisma.service';
import { SettingsService } from '../settings/settings.service';
import { AdminQueryNotificationsDto, AdminSendNotificationDto, NotificationStats } from './dto/admin-notification.dto';
import { QueryNotificationsDto } from './dto/query-notifications.dto';
import { NotificationJobData } from './dto/send-notification.dto';
import {
    NOTIFICATION_JOBS,
    NOTIFICATION_QUEUE,
} from './processors/notification.processor';

const ADMIN_ALERT_SETTINGS_KEYS = {
  new_user_alert: true,
  new_booking_alert: true,
  kyc_pending_alert: true,
  admin_email_alerts: true,
  sos_alert: true,
  report_alert: true,
} as const;

export interface PushQueueStatus {
  lastError: string | null;
  lastErrorAt: string | null;
  failedCount: number;
  waitingCount: number;
}

@Injectable()
export class NotificationsService implements OnModuleInit {
  private readonly logger = new Logger(NotificationsService.name);
  private lastPushError: string | null = null;
  private lastPushErrorAt: Date | null = null;

  constructor(
    private prisma: PrismaService,
    private settingsService: SettingsService,
    @InjectQueue(NOTIFICATION_QUEUE) private notificationQueue: Queue,
  ) {}

  onModuleInit() {
    this.notificationQueue.on('failed', (job: any, err: Error) => {
      const msg = `Job ${job?.id} failed: ${err?.message ?? String(err)}`;
      this.lastPushError = msg;
      this.lastPushErrorAt = new Date();
      this.logger.error(`[NotificationsService] Push queue job failed: ${msg}`, err?.stack ?? '');
    });
    this.notificationQueue.on('error', (err: Error) => {
      const msg = `Queue error: ${err?.message ?? String(err)}`;
      this.lastPushError = msg;
      this.lastPushErrorAt = new Date();
      this.logger.error(`[NotificationsService] Push queue error: ${msg}`, err?.stack ?? '');
    });
    this.notificationQueue.on('stalled', (jobId: string) => {
      this.logger.warn(`[NotificationsService] Push queue job stalled: ${jobId}`);
      this.lastPushError = `Job stalled: ${jobId}`;
      this.lastPushErrorAt = new Date();
    });
  }

  async getPushQueueStatus(): Promise<PushQueueStatus> {
    let failedCount = 0;
    let waitingCount = 0;
    try {
      failedCount = await this.notificationQueue.getFailedCount();
      waitingCount = await this.notificationQueue.getWaitingCount();
    } catch (e: any) {
      this.logger.warn(`[NotificationsService] Could not get queue counts: ${e?.message}`);
    }
    return {
      lastError: this.lastPushError,
      lastErrorAt: this.lastPushErrorAt ? this.lastPushErrorAt.toISOString() : null,
      failedCount,
      waitingCount,
    };
  }

  /**
   * If the given app_settings key is true, create in-app notifications for all admin users.
   * Used for: new_user_alert, new_booking_alert, kyc_pending_alert.
   */
  async notifyAdminsIfEnabled(
    settingsKey: keyof typeof ADMIN_ALERT_SETTINGS_KEYS,
    title: string,
    body: string,
    data?: Record<string, unknown>,
  ): Promise<void> {
    const enabled = await this.settingsService.getBool(settingsKey, true);
    if (!enabled) return;
    const adminUsers = await this.prisma.user.findMany({
      where: { role: 'ADMIN' },
      select: { id: true },
    });
    const jsonData = data != null ? (data as object) : undefined;
    for (const admin of adminUsers) {
      await this.prisma.notification.create({
        data: {
          userId: admin.id,
          type: NotificationType.SYSTEM,
          title,
          body,
          data: jsonData,
        },
      });
    }
    this.logger.log(`Admin alert [${settingsKey}]: ${title} -> ${adminUsers.length} admin(s)`);
  }

  /**
   * Queue a push notification to be sent
   */
  async sendPushNotification(data: NotificationJobData) {
    try {
      this.logger.log(`[NotificationsService] Queueing push notification for user ${data.userId}, type: ${data.type}`);
      await this.notificationQueue.add(NOTIFICATION_JOBS.SEND_PUSH, data, {
        attempts: 3,
        backoff: {
          type: 'exponential',
          delay: 1000,
        },
        removeOnComplete: true,
        removeOnFail: false,
      });
      this.logger.log(`[NotificationsService] Successfully queued push notification for user ${data.userId}`);
    } catch (error: any) {
      this.lastPushError = `Queue add failed: ${error?.message ?? String(error)}`;
      this.lastPushErrorAt = new Date();
      this.logger.error(`[NotificationsService] Failed to queue notification: ${error.message}`);
    }
  }

  /**
   * Send notification immediately (synchronous)
   */
  async sendNotification(data: {
    userId: string;
    type: NotificationType;
    title: string;
    body: string;
    imageUrl?: string;
    actionType?: string;
    actionId?: string;
    data?: any;
    sendPush?: boolean;
    saveToDb?: boolean;
  }) {
    const shouldSaveToDb = data.saveToDb !== false;
    this.logger.log(`[NotificationsService] sendNotification called for user ${data.userId}, type: ${data.type}, sendPush: ${data.sendPush !== false}, saveToDb: ${shouldSaveToDb}`);

    let notification: any = null;

    // Create in database (skip for CHAT — messages have their own history)
    if (shouldSaveToDb) {
      notification = await this.prisma.notification.create({
        data: {
          userId: data.userId,
          type: data.type,
          title: data.title,
          body: data.body,
          imageUrl: data.imageUrl,
          actionType: data.actionType,
          actionId: data.actionId,
          data: data.data,
        },
      });
      this.logger.log(`[NotificationsService] Notification saved to DB with id: ${notification.id}`);
    }

    // Queue push notification if requested
    if (data.sendPush !== false) {
      await this.sendPushNotification({
        ...data,
        saveToDb: false, // Already saved (or skipped)
        sendPush: true,
        notificationId: notification?.id,
      });
    }

    return notification;
  }


  async getNotifications(userId: string, query: QueryNotificationsDto) {
    const { page = 1, limit = 20, isRead, type } = query;
    const skip = (page - 1) * limit;

    const where: any = {
      userId,
      // Exclude CHAT notifications — messages have their own chat history
      type: { not: NotificationType.CHAT },
    };

    if (isRead !== undefined) {
      where.isRead = isRead;
    }

    if (type) {
      where.type = type;
    }

    const [notifications, total, unreadCount] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.notification.count({ where }),
      this.prisma.notification.count({
        where: { userId, isRead: false, type: { not: NotificationType.CHAT } },
      }),
    ]);

    return {
      data: notifications.map((n) => ({
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        imageUrl: n.imageUrl,
        actionType: n.actionType,
        actionId: n.actionId,
        data: n.data,
        isRead: n.isRead,
        readAt: n.readAt,
        createdAt: n.createdAt,
      })),
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        unreadCount,
      },
    };
  }

  async getUnreadCount(userId: string) {
    const count = await this.prisma.notification.count({
      where: {
        userId,
        isRead: false,
        // Exclude CHAT — messages have their own unread count
        type: { not: NotificationType.CHAT },
      },
    });

    return { unreadCount: count };
  }

  async markAsRead(userId: string, notificationId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id: notificationId, userId },
    });

    if (!notification) {
      return { success: false, message: 'Notification not found' };
    }

    await this.prisma.notification.update({
      where: { id: notificationId },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });

    return { success: true };
  }

  async markAllAsRead(userId: string, ids?: string[]) {
    const where: any = { userId, isRead: false };

    if (ids && ids.length > 0) {
      where.id = { in: ids };
    }

    const result = await this.prisma.notification.updateMany({
      where,
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });

    return {
      success: true,
      updatedCount: result.count,
    };
  }

  async deleteNotification(userId: string, notificationId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id: notificationId, userId },
    });

    if (!notification) {
      return { success: false, message: 'Notification not found' };
    }

    await this.prisma.notification.delete({
      where: { id: notificationId },
    });

    return { success: true };
  }

  async deleteAllRead(userId: string) {
    const result = await this.prisma.notification.deleteMany({
      where: { userId, isRead: true },
    });

    return {
      success: true,
      deletedCount: result.count,
    };
  }

  // Helper method to create notifications (used by other services)
  async createNotification(data: {
    userId: string;
    type: NotificationType;
    title: string;
    body: string;
    imageUrl?: string;
    actionType?: string;
    actionId?: string;
    data?: any;
  }) {
    return this.prisma.notification.create({
      data: {
        userId: data.userId,
        type: data.type,
        title: data.title,
        body: data.body,
        imageUrl: data.imageUrl,
        actionType: data.actionType,
        actionId: data.actionId,
        data: data.data,
      },
    });
  }

  // Create booking notification
  async createBookingNotification(
    userId: string,
    title: string,
    body: string,
    bookingId: string,
  ) {
    return this.createNotification({
      userId,
      type: NotificationType.BOOKING,
      title,
      body,
      actionType: 'booking',
      actionId: bookingId,
    });
  }

  // Create chat notification
  async createChatNotification(
    userId: string,
    title: string,
    body: string,
    chatId: string,
    senderAvatar?: string,
  ) {
    return this.createNotification({
      userId,
      type: NotificationType.CHAT,
      title,
      body,
      imageUrl: senderAvatar,
      actionType: 'chat',
      actionId: chatId,
    });
  }

  // Create payment notification
  async createPaymentNotification(
    userId: string,
    title: string,
    body: string,
    transactionId?: string,
  ) {
    return this.createNotification({
      userId,
      type: NotificationType.PAYMENT,
      title,
      body,
      actionType: 'wallet',
      actionId: transactionId,
    });
  }

  // Create system notification
  async createSystemNotification(userId: string, title: string, body: string) {
    return this.createNotification({
      userId,
      type: NotificationType.SYSTEM,
      title,
      body,
    });
  }

  // Create review notification
  async createReviewNotification(
    userId: string,
    title: string,
    body: string,
    reviewId: string,
    reviewerAvatar?: string,
  ) {
    return this.createNotification({
      userId,
      type: NotificationType.REVIEW,
      title,
      body,
      imageUrl: reviewerAvatar,
      actionType: 'review',
      actionId: reviewId,
    });
  }

  // ==================== ADMIN METHODS ====================

  async adminGetStats(): Promise<NotificationStats> {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const weekStart = new Date(todayStart);
    weekStart.setDate(weekStart.getDate() - 7);
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const [total, unread, read, byTypeRaw, today, thisWeek, thisMonth, pushQueue] =
      await Promise.all([
        this.prisma.notification.count(),
        this.prisma.notification.count({ where: { isRead: false } }),
        this.prisma.notification.count({ where: { isRead: true } }),
        this.prisma.notification.groupBy({
          by: ['type'],
          _count: { type: true },
        }),
        this.prisma.notification.count({
          where: { createdAt: { gte: todayStart } },
        }),
        this.prisma.notification.count({
          where: { createdAt: { gte: weekStart } },
        }),
        this.prisma.notification.count({
          where: { createdAt: { gte: monthStart } },
        }),
        this.getPushQueueStatus(),
      ]);

    const byType = byTypeRaw.map((item) => ({
      type: item.type,
      count: item._count.type,
    }));

    return {
      total,
      unread,
      read,
      byType,
      today,
      thisWeek,
      thisMonth,
      pushQueue,
    };
  }

  async adminGetNotifications(query: AdminQueryNotificationsDto) {
    const { page = 1, limit = 20, search, type, userId, isRead, sortBy = 'createdAt', sortOrder = 'desc' } = query;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (type) {
      where.type = type;
    }

    if (userId) {
      where.userId = userId;
    }

    if (isRead !== undefined) {
      where.isRead = isRead;
    }

    if (search) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { body: { contains: search, mode: 'insensitive' } },
        { user: { email: { contains: search, mode: 'insensitive' } } },
        { user: { profile: { fullName: { contains: search, mode: 'insensitive' } } } },
      ];
    }

    const [notifications, total] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        include: {
          user: {
            select: {
              id: true,
              email: true,
              profile: {
                select: {
                  fullName: true,
                  avatarUrl: true,
                },
              },
            },
          },
        },
        orderBy: { [sortBy]: sortOrder },
        skip,
        take: limit,
      }),
      this.prisma.notification.count({ where }),
    ]);

    return {
      data: notifications,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async adminSendNotification(dto: AdminSendNotificationDto) {
    const { userIds, title, body, type = NotificationType.SYSTEM, imageUrl, actionType, actionId, data, sendPush = true } = dto;

    if (!userIds || userIds.length === 0) {
      return { success: false, message: 'No user IDs provided' };
    }

    // Verify users exist
    const existingUsers = await this.prisma.user.findMany({
      where: { id: { in: userIds } },
      select: { id: true },
    });

    const existingUserIds = existingUsers.map((u) => u.id);

    // Create notifications
    const notifications = await Promise.all(
      existingUserIds.map((userId) =>
        this.sendNotification({
          userId,
          type,
          title,
          body,
          imageUrl,
          actionType,
          actionId,
          data,
          sendPush,
        }),
      ),
    );

    return {
      success: true,
      sentCount: notifications.length,
      skippedCount: userIds.length - existingUserIds.length,
    };
  }

  async adminBroadcastNotification(dto: AdminSendNotificationDto) {
    const { title, body, type = NotificationType.SYSTEM, imageUrl, actionType, actionId, data, sendPush = true } = dto;

    // Get all active users
    const users = await this.prisma.user.findMany({
      where: { status: 'ACTIVE' },
      select: { id: true },
    });

    const userIds = users.map((u) => u.id);

    // Create notifications in batches
    const batchSize = 100;
    let sentCount = 0;

    for (let i = 0; i < userIds.length; i += batchSize) {
      const batch = userIds.slice(i, i + batchSize);
      await Promise.all(
        batch.map((userId) =>
          this.sendNotification({
            userId,
            type,
            title,
            body,
            imageUrl,
            actionType,
            actionId,
            data,
            sendPush,
          }),
        ),
      );
      sentCount += batch.length;
    }

    return {
      success: true,
      sentCount,
      message: `Broadcast sent to ${sentCount} users`,
    };
  }

  async adminDeleteNotification(notificationId: string) {
    const notification = await this.prisma.notification.findUnique({
      where: { id: notificationId },
    });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }

    await this.prisma.notification.delete({
      where: { id: notificationId },
    });

    return { success: true, message: 'Notification deleted' };
  }
}
