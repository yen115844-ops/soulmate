import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { PrismaService } from '../../../database/prisma/prisma.service';

export interface FcmMessage {
  title: string;
  body: string;
  imageUrl?: string;
  data?: Record<string, string>;
}

export interface SendResult {
  success: boolean;
  successCount: number;
  failureCount: number;
  failedTokens: string[];
}

@Injectable()
export class FcmService implements OnModuleInit {
  private readonly logger = new Logger(FcmService.name);
  private firebaseApp: admin.app.App | null = null;
  private isInitialized = false;

  constructor(
    private configService: ConfigService,
    private prisma: PrismaService,
  ) {}

  onModuleInit() {
    this.initializeFirebase();
  }

  private initializeFirebase() {
    try {
      const projectId = this.configService.get<string>('firebase.projectId');
      const clientEmail = this.configService.get<string>('firebase.clientEmail');
      const privateKey = this.configService.get<string>('firebase.privateKey');

      if (!projectId || !clientEmail || !privateKey) {
        this.logger.warn(
          'Firebase credentials not configured. Push notifications will be disabled.',
        );
        return;
      }

      // Check if Firebase is already initialized
      if (admin.apps.length > 0) {
        this.firebaseApp = admin.apps[0];
        this.isInitialized = true;
        this.logger.log('Firebase Admin SDK already initialized');
        return;
      }

      this.firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          clientEmail,
          privateKey,
        }),
      });

      this.isInitialized = true;
      this.logger.log('Firebase Admin SDK initialized successfully');
    } catch (error: any) {
      this.logger.error(
        '[FcmService] Failed to initialize Firebase Admin SDK: ' +
          (error?.message ?? String(error)),
        error?.stack ?? '',
      );
    }
  }

  /**
   * Check if FCM is available
   */
  isAvailable(): boolean {
    return this.isInitialized && this.firebaseApp !== null;
  }

  /**
   * Send push notification to a single device
   */
  async sendToDevice(token: string, message: FcmMessage): Promise<boolean> {
    if (!this.isAvailable()) {
      this.logger.warn(
        '[FcmService] FCM not available (Firebase not configured or init failed), skipping push',
      );
      return false;
    }

    try {
      const notification: admin.messaging.Notification = {
        title: message.title,
        body: message.body,
        ...(this.isValidImageUrl(message.imageUrl) && {
          imageUrl: message.imageUrl!,
        }),
      };
      const fcmMessage: admin.messaging.Message = {
        token,
        notification,
        data: message.data,
        android: {
          priority: 'high',
          notification: {
            channelId: this.getChannelId(message.data?.type),
            priority: 'high',
            defaultSound: false,
            sound: 'notification_sound',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: message.title,
                body: message.body,
              },
              sound: 'notification_sound.caf',
              badge: message.data?.unreadCount
                ? parseInt(message.data.unreadCount)
                : undefined,
            },
          },
        },
      };

      const response = await admin.messaging().send(fcmMessage);
      this.logger.debug(`FCM message sent successfully: ${response}`);
      return true;
    } catch (error: any) {
      this.logger.error(`Failed to send FCM message: ${error.message}`);
      
      // Handle invalid token
      if (this.isInvalidTokenError(error)) {
        await this.invalidateToken(token);
      }
      
      return false;
    }
  }

  /**
   * Send push notification to multiple devices
   */
  async sendToDevices(tokens: string[], message: FcmMessage): Promise<SendResult> {
    if (!this.isAvailable()) {
      this.logger.warn(
        '[FcmService] FCM not available (Firebase not configured or init failed), skipping push',
      );
      return {
        success: false,
        successCount: 0,
        failureCount: tokens.length,
        failedTokens: tokens,
      };
    }

    if (tokens.length === 0) {
      return {
        success: true,
        successCount: 0,
        failureCount: 0,
        failedTokens: [],
      };
    }

    try {
      const notification: admin.messaging.Notification = {
        title: message.title,
        body: message.body,
        ...(this.isValidImageUrl(message.imageUrl) && {
          imageUrl: message.imageUrl!,
        }),
      };
      const fcmMessage: admin.messaging.MulticastMessage = {
        tokens,
        notification,
        data: message.data,
        android: {
          priority: 'high',
          notification: {
            channelId: this.getChannelId(message.data?.type),
            priority: 'high',
            defaultSound: false,
            sound: 'notification_sound',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: message.title,
                body: message.body,
              },
              sound: 'notification_sound.caf',
            },
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(fcmMessage);

      const failedTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
          const err = resp.error as any;
          this.logger.warn(
            `[FcmService] FCM failure for token ${tokens[idx].substring(0, 20)}...: code=${err?.code ?? 'unknown'}, message=${err?.message ?? err}`,
          );
          if (resp.error && this.isInvalidTokenError(resp.error)) {
            // Mark token as invalid in background
            this.invalidateToken(tokens[idx]).catch(() => {});
          }
        }
      });

      this.logger.log(
        `[FcmService] FCM multicast: ${response.successCount} success, ${response.failureCount} failures`,
      );

      return {
        success: response.successCount > 0,
        successCount: response.successCount,
        failureCount: response.failureCount,
        failedTokens,
      };
    } catch (error: any) {
      this.logger.error(
        `[FcmService] Failed to send FCM multicast: ${error.message}`,
        error?.stack ?? '',
      );
      return {
        success: false,
        successCount: 0,
        failureCount: tokens.length,
        failedTokens: tokens,
      };
    }
  }

  /**
   * Send push notification to a user (all their devices)
   */
  async sendToUser(userId: string, message: FcmMessage): Promise<SendResult> {
    this.logger.log(
      `[FcmService] Sending to user ${userId}: ${message.title} - ${message.body}`,
    );

    const deviceTokens = await this.prisma.deviceToken.findMany({
      where: {
        userId,
        isActive: true,
      },
      select: { token: true },
    });

    this.logger.log(
      `[FcmService] User ${userId}: ${deviceTokens.length} active device token(s)`,
    );

    if (deviceTokens.length === 0) {
      this.logger.warn(
        `[FcmService] No active device tokens for user ${userId}. Push will not be delivered.`,
      );
      return {
        success: false,
        successCount: 0,
        failureCount: 0,
        failedTokens: [],
      };
    }

    const tokens = deviceTokens.map((dt) => dt.token);
    return this.sendToDevices(tokens, message);
  }

  /**
   * Send push notification to multiple users
   */
  async sendToUsers(userIds: string[], message: FcmMessage): Promise<SendResult> {
    const deviceTokens = await this.prisma.deviceToken.findMany({
      where: {
        userId: { in: userIds },
        isActive: true,
      },
      select: { token: true },
    });

    if (deviceTokens.length === 0) {
      return {
        success: false,
        successCount: 0,
        failureCount: 0,
        failedTokens: [],
      };
    }

    const tokens = deviceTokens.map((dt) => dt.token);
    return this.sendToDevices(tokens, message);
  }

  /**
   * Get Android notification channel ID based on notification type.
   * Phải khớp với channel ID trong app (LocalNotificationService) - dùng _v2 để channel mới có custom sound
   */
  private getChannelId(type?: string): string {
    switch (type?.toUpperCase()) {
      case 'BOOKING':
        return 'mate_social_bookings_v2';
      case 'CHAT':
        return 'mate_social_messages_v2';
      case 'PAYMENT':
        return 'mate_social_reminders_v2';
      case 'SAFETY':
      case 'REVIEW':
        return 'mate_social_social_v2';
      default:
        return 'mate_social_default_v2';
    }
  }

  /**
   * FCM chỉ chấp nhận imageUrl là URL tuyệt đối (http/https). Bỏ qua nếu rỗng hoặc relative path.
   */
  private isValidImageUrl(url: string | undefined): boolean {
    if (!url || typeof url !== 'string') return false;
    const trimmed = url.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  /**
   * Check if error is related to invalid token
   */
  private isInvalidTokenError(error: any): boolean {
    const invalidTokenCodes = [
      'messaging/invalid-registration-token',
      'messaging/registration-token-not-registered',
      'messaging/invalid-argument',
    ];
    return invalidTokenCodes.includes(error.code);
  }

  /**
   * Mark token as inactive in database
   */
  private async invalidateToken(token: string): Promise<void> {
    try {
      await this.prisma.deviceToken.updateMany({
        where: { token },
        data: { isActive: false },
      });
      this.logger.debug(`Invalidated FCM token: ${token.substring(0, 20)}...`);
    } catch (error) {
      this.logger.error('Failed to invalidate token', error);
    }
  }
}
