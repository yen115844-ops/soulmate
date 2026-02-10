import { Process, Processor } from '@nestjs/bull';
import { Logger } from '@nestjs/common';
import type { Job } from 'bull';
import { PrismaService } from '../../../database/prisma/prisma.service';
import {
    BatchNotificationJobData,
    NotificationJobData,
} from '../dto/send-notification.dto';
import { FcmService } from '../services/fcm.service';

export const NOTIFICATION_QUEUE = 'notifications';

export const NOTIFICATION_JOBS = {
  SEND_PUSH: 'send-push',
  SEND_BATCH: 'send-batch',
  CLEANUP_TOKENS: 'cleanup-tokens',
};

@Processor(NOTIFICATION_QUEUE)
export class NotificationProcessor {
  private readonly logger = new Logger(NotificationProcessor.name);

  constructor(
    private fcmService: FcmService,
    private prisma: PrismaService,
  ) {}

  /**
   * Process single push notification job
   */
  @Process(NOTIFICATION_JOBS.SEND_PUSH)
  async handleSendPush(job: Job<NotificationJobData>) {
    const {
      userId,
      type,
      title,
      body,
      imageUrl,
      actionType,
      actionId,
      data,
      saveToDb = true,
      sendPush = true,
      notificationId: jobNotificationId,
    } = job.data;

    this.logger.log(`[NotificationProcessor] Processing push notification job for user ${userId}, type: ${type}, sendPush: ${sendPush}`);

    try {
      // Save notification to database if requested
      let notificationId: string | undefined;
      if (saveToDb) {
        const notification = await this.prisma.notification.create({
          data: {
            userId,
            type,
            title,
            body,
            imageUrl,
            actionType,
            actionId,
            data: data || undefined,
          },
        });
        notificationId = notification.id;
      }
      notificationId = notificationId ?? jobNotificationId;

      // Send push notification if requested
      if (sendPush) {
        // Check user's notification settings
        const userSettings = await this.prisma.userSettings.findUnique({
          where: { userId },
          select: {
            pushNotificationsEnabled: true,
            messageNotificationsEnabled: true,
          },
        });

        // Skip if user has disabled push notifications
        if (userSettings && !userSettings.pushNotificationsEnabled) {
          this.logger.debug(
            `Push notifications disabled for user ${userId}, skipping`,
          );
          return { success: true, skipped: true, reason: 'push_disabled' };
        }

        // Skip chat notifications if message notifications are disabled
        if (
          type === 'CHAT' &&
          userSettings &&
          !userSettings.messageNotificationsEnabled
        ) {
          this.logger.debug(
            `Message notifications disabled for user ${userId}, skipping`,
          );
          return { success: true, skipped: true, reason: 'messages_disabled' };
        }

        // Get unread count for badge
        const unreadCount = await this.prisma.notification.count({
          where: { userId, isRead: false },
        });

        // Send via FCM (mọi giá trị trong data phải là string)
        const result = await this.fcmService.sendToUser(userId, {
          title,
          body,
          imageUrl,
          data: {
            type: String(type ?? ''),
            actionType: actionType || '',
            actionId: actionId || '',
            notificationId: notificationId ?? '',
            unreadCount: unreadCount.toString(),
            ...(data ? this.stringifyData(data) : {}),
          },
        });

        this.logger.log(
          `[NotificationProcessor] Push notification sent to user ${userId}: ${result.successCount} success, ${result.failureCount} failures`,
        );

        return {
          notificationId,
          ...result,
        };
      }

      return { success: true, notificationId };
    } catch (error: any) {
      const msg = `[NotificationProcessor] Failed for user ${userId}: ${error?.message ?? String(error)}`;
      this.logger.error(msg, error?.stack ?? '');
      throw error;
    }
  }

  /**
   * Process batch push notification job
   */
  @Process(NOTIFICATION_JOBS.SEND_BATCH)
  async handleBatchSend(job: Job<BatchNotificationJobData>) {
    const {
      userIds,
      type,
      title,
      body,
      imageUrl,
      actionType,
      actionId,
      data,
    } = job.data;

    this.logger.debug(
      `Processing batch notification for ${userIds.length} users`,
    );

    try {
      // Create notifications in database for all users
      await this.prisma.notification.createMany({
        data: userIds.map((userId) => ({
          userId,
          type,
          title,
          body,
          imageUrl,
          actionType,
          actionId,
          data: data || undefined,
        })),
      });

      // Get users with push enabled
      const usersWithPush = await this.prisma.userSettings.findMany({
        where: {
          userId: { in: userIds },
          pushNotificationsEnabled: true,
        },
        select: { userId: true },
      });

      const enabledUserIds = usersWithPush.map((u) => u.userId);

      if (enabledUserIds.length === 0) {
        this.logger.debug('No users with push notifications enabled');
        return { success: true, skipped: true };
      }

      // Send push notifications
      const result = await this.fcmService.sendToUsers(enabledUserIds, {
        title,
        body,
        imageUrl,
        data: {
          type,
          actionType: actionType || '',
          actionId: actionId || '',
          ...(data ? this.stringifyData(data) : {}),
        },
      });

      this.logger.debug(
        `Batch notification: ${result.successCount} success, ${result.failureCount} failures`,
      );

      return { ...result };
    } catch (error: any) {
      this.logger.error(`Failed to process batch notification: ${error.message}`);
      throw error;
    }
  }

  /**
   * Convert object values to strings for FCM data payload
   */
  private stringifyData(data: Record<string, any>): Record<string, string> {
    const result: Record<string, string> = {};
    for (const [key, value] of Object.entries(data)) {
      result[key] = typeof value === 'string' ? value : JSON.stringify(value);
    }
    return result;
  }
}
