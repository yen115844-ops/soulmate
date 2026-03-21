import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../database/prisma/prisma.service';
import {
  NotificationType,
  SubscriptionStatus,
} from '../../generated/prisma/client';
import { NotificationsService } from '../notifications';
import {
  AppleNotificationPayload,
  AppleNotificationType,
  AppleNotificationV2Dto,
  AppleRenewalInfo,
  AppleTransactionInfo,
  GoogleDeveloperNotification,
  GoogleRTDNDto,
  GoogleSubscriptionNotificationType,
} from './dto/webhook.dto';

@Injectable()
export class SubscriptionWebhookService {
  private readonly logger = new Logger(SubscriptionWebhookService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ==================== Apple App Store Server Notifications V2 ====================

  /**
   * Handle Apple App Store Server Notification V2
   * Apple sends a signed JWS payload containing notification data
   */
  async handleAppleNotification(
    dto: AppleNotificationV2Dto,
    environment: 'Production' | 'Sandbox',
  ): Promise<void> {
    const { signedPayload } = dto;

    if (!signedPayload) {
      this.logger.warn(`[Apple ${environment}] Empty signedPayload received`);
      return;
    }

    // Decode the JWS payload (verify signature in production)
    const payload = await this.decodeAppleJWS<AppleNotificationPayload>(
      signedPayload,
      environment,
    );

    if (!payload) {
      this.logger.error(
        `[Apple ${environment}] Failed to decode notification payload`,
      );
      return;
    }

    this.logger.log(
      `[Apple ${environment}] Notification: type=${payload.notificationType}, subtype=${payload.subtype || 'none'}, uuid=${payload.notificationUUID}`,
    );

    // Handle TEST notifications
    if (payload.notificationType === AppleNotificationType.TEST) {
      this.logger.log(`[Apple ${environment}] Test notification received - OK`);
      return;
    }

    // Decode transaction info
    const transactionInfo = payload.data?.signedTransactionInfo
      ? await this.decodeAppleJWS<AppleTransactionInfo>(
          payload.data.signedTransactionInfo,
          environment,
        )
      : null;

    // Decode renewal info
    const renewalInfo = payload.data?.signedRenewalInfo
      ? await this.decodeAppleJWS<AppleRenewalInfo>(
          payload.data.signedRenewalInfo,
          environment,
        )
      : null;

    if (!transactionInfo) {
      this.logger.warn(
        `[Apple ${environment}] No transaction info in notification ${payload.notificationType}`,
      );
      return;
    }

    this.logger.log(
      `[Apple ${environment}] Transaction: productId=${transactionInfo.productId}, ` +
        `originalTxId=${transactionInfo.originalTransactionId}, txId=${transactionInfo.transactionId}`,
    );

    // Route to appropriate handler
    switch (payload.notificationType) {
      case AppleNotificationType.SUBSCRIBED:
        await this.handleAppleSubscribed(
          transactionInfo,
          renewalInfo,
          environment,
        );
        break;

      case AppleNotificationType.DID_RENEW:
        await this.handleAppleRenewal(
          transactionInfo,
          renewalInfo,
          environment,
        );
        break;

      case AppleNotificationType.DID_CHANGE_RENEWAL_STATUS:
        await this.handleAppleRenewalStatusChange(
          transactionInfo,
          renewalInfo,
          environment,
        );
        break;

      case AppleNotificationType.DID_FAIL_TO_RENEW:
        await this.handleAppleFailedRenewal(
          transactionInfo,
          renewalInfo,
          environment,
        );
        break;

      case AppleNotificationType.EXPIRED:
        await this.handleAppleExpired(transactionInfo, environment);
        break;

      case AppleNotificationType.GRACE_PERIOD_EXPIRED:
        await this.handleAppleGracePeriodExpired(transactionInfo, environment);
        break;

      case AppleNotificationType.REFUND:
        await this.handleAppleRefund(transactionInfo, environment);
        break;

      case AppleNotificationType.REVOKE:
        await this.handleAppleRevoke(transactionInfo, environment);
        break;

      case AppleNotificationType.DID_CHANGE_RENEWAL_PREF:
        await this.handleAppleRenewalPrefChange(
          transactionInfo,
          renewalInfo,
          environment,
        );
        break;

      default:
        this.logger.log(
          `[Apple ${environment}] Unhandled notification type: ${payload.notificationType}`,
        );
    }
  }

  /**
   * SUBSCRIBED — New subscription or resubscribe
   */
  private async handleAppleSubscribed(
    tx: AppleTransactionInfo,
    renewal: AppleRenewalInfo | null,
    env: string,
  ): Promise<void> {
    this.logger.log(`[Apple ${env}] SUBSCRIBED: ${tx.originalTransactionId}`);

    // Find existing subscription by originalTransactionId
    const existing = await this.prisma.subscription.findFirst({
      where: { originalTxId: tx.originalTransactionId },
    });

    if (existing) {
      // Resubscribe — update status
      await this.prisma.subscription.update({
        where: { id: existing.id },
        data: {
          status: SubscriptionStatus.ACTIVE,
          latestTxId: tx.transactionId,
          endDate: tx.expiresDate ? new Date(tx.expiresDate) : existing.endDate,
          isAutoRenew: renewal?.autoRenewStatus === 1,
        },
      });
      await this.updateUserPremiumStatus(existing.userId);
      this.logger.log(`[Apple ${env}] Resubscribed: user=${existing.userId}`);
    } else {
      // New subscription created via client — the subscription should already exist
      // from verifyPurchase(). If not, log a warning.
      this.logger.warn(
        `[Apple ${env}] SUBSCRIBED notification for unknown originalTxId=${tx.originalTransactionId}. ` +
          `The subscription may not have been created via verifyPurchase yet.`,
      );
    }
  }

  /**
   * DID_RENEW — Subscription successfully renewed
   */
  private async handleAppleRenewal(
    tx: AppleTransactionInfo,
    renewal: AppleRenewalInfo | null,
    env: string,
  ): Promise<void> {
    this.logger.log(`[Apple ${env}] DID_RENEW: ${tx.originalTransactionId}`);

    const subscription = await this.findSubscriptionByOriginalTx(
      tx.originalTransactionId,
    );
    if (!subscription) return;

    // Extend subscription
    const newEndDate = tx.expiresDate ? new Date(tx.expiresDate) : null;

    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        status: SubscriptionStatus.ACTIVE,
        latestTxId: tx.transactionId,
        endDate: newEndDate || subscription.endDate,
        isAutoRenew: renewal?.autoRenewStatus === 1,
      },
    });

    await this.updateUserPremiumStatus(subscription.userId);

    // Notify user about successful renewal
    await this.sendNotification(
      subscription.userId,
      '✅ Gia hạn Premium thành công',
      'Gói Premium của bạn đã được tự động gia hạn. Tiếp tục trải nghiệm!',
    );

    this.logger.log(
      `[Apple ${env}] Renewed: user=${subscription.userId}, newEndDate=${newEndDate?.toISOString()}`,
    );
  }

  /**
   * DID_CHANGE_RENEWAL_STATUS — Auto-renew status changed
   */
  private async handleAppleRenewalStatusChange(
    tx: AppleTransactionInfo,
    renewal: AppleRenewalInfo | null,
    env: string,
  ): Promise<void> {
    const autoRenew = renewal?.autoRenewStatus === 1;
    this.logger.log(
      `[Apple ${env}] DID_CHANGE_RENEWAL_STATUS: ${tx.originalTransactionId}, autoRenew=${autoRenew}`,
    );

    const subscription = await this.findSubscriptionByOriginalTx(
      tx.originalTransactionId,
    );
    if (!subscription) return;

    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        isAutoRenew: autoRenew,
        cancelledAt: autoRenew ? null : new Date(),
      },
    });

    if (!autoRenew) {
      await this.sendNotification(
        subscription.userId,
        'Tự động gia hạn đã tắt',
        'Gói Premium sẽ hết hạn và không tự động gia hạn. Bạn vẫn có thể sử dụng đến hết kỳ hiện tại.',
      );
    }
  }

  /**
   * DID_FAIL_TO_RENEW — Billing issue, subscription may enter grace period
   */
  private async handleAppleFailedRenewal(
    tx: AppleTransactionInfo,
    renewal: AppleRenewalInfo | null,
    env: string,
  ): Promise<void> {
    this.logger.log(
      `[Apple ${env}] DID_FAIL_TO_RENEW: ${tx.originalTransactionId}`,
    );

    const subscription = await this.findSubscriptionByOriginalTx(
      tx.originalTransactionId,
    );
    if (!subscription) return;

    const isInGracePeriod = renewal?.gracePeriodExpiresDate
      ? new Date(renewal.gracePeriodExpiresDate) > new Date()
      : false;

    if (isInGracePeriod) {
      await this.prisma.subscription.update({
        where: { id: subscription.id },
        data: { status: SubscriptionStatus.GRACE_PERIOD },
      });

      await this.sendNotification(
        subscription.userId,
        '⚠️ Vấn đề thanh toán',
        'Không thể gia hạn gói Premium. Vui lòng cập nhật phương thức thanh toán để tiếp tục sử dụng.',
      );
    }

    this.logger.log(
      `[Apple ${env}] Failed renewal: user=${subscription.userId}, gracePeriod=${isInGracePeriod}`,
    );
  }

  /**
   * EXPIRED — Subscription expired
   */
  private async handleAppleExpired(
    tx: AppleTransactionInfo,
    env: string,
  ): Promise<void> {
    this.logger.log(`[Apple ${env}] EXPIRED: ${tx.originalTransactionId}`);

    const subscription = await this.findSubscriptionByOriginalTx(
      tx.originalTransactionId,
    );
    if (!subscription) return;

    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: { status: SubscriptionStatus.EXPIRED },
    });

    await this.updateUserPremiumStatus(subscription.userId);

    await this.sendNotification(
      subscription.userId,
      'Gói Premium đã hết hạn',
      'Gói Premium của bạn đã hết hạn. Gia hạn ngay để tiếp tục sử dụng các tính năng độc quyền!',
    );
  }

  /**
   * GRACE_PERIOD_EXPIRED — Grace period ended, subscription expired
   */
  private async handleAppleGracePeriodExpired(
    tx: AppleTransactionInfo,
    env: string,
  ): Promise<void> {
    this.logger.log(
      `[Apple ${env}] GRACE_PERIOD_EXPIRED: ${tx.originalTransactionId}`,
    );

    const subscription = await this.findSubscriptionByOriginalTx(
      tx.originalTransactionId,
    );
    if (!subscription) return;

    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: { status: SubscriptionStatus.EXPIRED },
    });

    await this.updateUserPremiumStatus(subscription.userId);

    await this.sendNotification(
      subscription.userId,
      'Gói Premium đã hết hạn',
      'Thời gian gia hạn thanh toán đã kết thúc. Gia hạn ngay để tiếp tục!',
    );
  }

  /**
   * REFUND — Apple issued a refund
   */
  private async handleAppleRefund(
    tx: AppleTransactionInfo,
    env: string,
  ): Promise<void> {
    this.logger.log(
      `[Apple ${env}] REFUND: ${tx.originalTransactionId}, txId=${tx.transactionId}`,
    );

    const subscription = await this.findSubscriptionByOriginalTx(
      tx.originalTransactionId,
    );
    if (!subscription) return;

    // Revoke premium access on refund
    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        status: SubscriptionStatus.CANCELLED,
        cancelledAt: new Date(),
        isAutoRenew: false,
      },
    });

    await this.updateUserPremiumStatus(subscription.userId);

    this.logger.log(
      `[Apple ${env}] Refund processed: user=${subscription.userId}`,
    );
  }

  /**
   * REVOKE — Family sharing revocation or Ask to Buy declined
   */
  private async handleAppleRevoke(
    tx: AppleTransactionInfo,
    env: string,
  ): Promise<void> {
    this.logger.log(`[Apple ${env}] REVOKE: ${tx.originalTransactionId}`);

    const subscription = await this.findSubscriptionByOriginalTx(
      tx.originalTransactionId,
    );
    if (!subscription) return;

    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        status: SubscriptionStatus.CANCELLED,
        cancelledAt: new Date(),
        isAutoRenew: false,
      },
    });

    await this.updateUserPremiumStatus(subscription.userId);
  }

  /**
   * DID_CHANGE_RENEWAL_PREF — User changed their subscription plan (upgrade/downgrade)
   */
  private async handleAppleRenewalPrefChange(
    tx: AppleTransactionInfo,
    renewal: AppleRenewalInfo | null,
    env: string,
  ): Promise<void> {
    this.logger.log(
      `[Apple ${env}] DID_CHANGE_RENEWAL_PREF: ${tx.originalTransactionId}, ` +
        `newProduct=${renewal?.autoRenewProductId}`,
    );

    // This notification indicates the user changed their renewal product.
    // The actual plan change happens at the next renewal — no immediate action needed.
    // Just log it for analytics.
  }

  // ==================== Google Play RTDN ====================

  /**
   * Handle Google Play Real-time Developer Notification
   * Google sends Pub/Sub messages with base64-encoded notification data
   */
  async handleGoogleNotification(dto: GoogleRTDNDto): Promise<void> {
    if (!dto.message?.data) {
      this.logger.warn('[Google RTDN] Empty message data received');
      return;
    }

    // Decode base64 Pub/Sub message data
    const decodedData = Buffer.from(dto.message.data, 'base64').toString(
      'utf-8',
    );
    let notification: GoogleDeveloperNotification;

    try {
      notification = JSON.parse(decodedData);
    } catch {
      this.logger.error('[Google RTDN] Failed to parse notification data');
      return;
    }

    this.logger.log(
      `[Google RTDN] Package: ${notification.packageName}, ` +
        `eventTime=${notification.eventTimeMillis}`,
    );

    // Handle test notification
    if (notification.testNotification) {
      this.logger.log('[Google RTDN] Test notification received - OK');
      return;
    }

    // Handle subscription notifications
    if (notification.subscriptionNotification) {
      await this.handleGoogleSubscriptionNotification(
        notification.subscriptionNotification,
      );
      return;
    }

    // Handle one-time product notifications (credits)
    if (notification.oneTimeProductNotification) {
      this.logger.log(
        `[Google RTDN] One-time product notification: sku=${notification.oneTimeProductNotification.sku}`,
      );
      // Credits are handled via client-initiated verification
      return;
    }

    this.logger.warn('[Google RTDN] Unknown notification type');
  }

  /**
   * Handle Google Play subscription notification
   */
  private async handleGoogleSubscriptionNotification(notification: {
    notificationType: number;
    purchaseToken: string;
    subscriptionId: string;
  }): Promise<void> {
    const { notificationType, purchaseToken, subscriptionId } = notification;

    this.logger.log(
      `[Google RTDN] Subscription notification: type=${notificationType}, ` +
        `subscriptionId=${subscriptionId}, token=${purchaseToken.substring(0, 20)}...`,
    );

    // Find subscription by purchaseToken (stored as receiptData for Android)
    const subscription = await this.prisma.subscription.findFirst({
      where: {
        platform: 'android',
        receiptData: { contains: purchaseToken },
      },
    });

    if (!subscription) {
      this.logger.warn(
        `[Google RTDN] No subscription found for purchaseToken. ` +
          `It may not have been created via verifyPurchase yet.`,
      );
      return;
    }

    switch (notificationType) {
      case GoogleSubscriptionNotificationType.SUBSCRIPTION_PURCHASED:
        this.logger.log(`[Google RTDN] PURCHASED: user=${subscription.userId}`);
        // Already handled via client verifyPurchase
        break;

      case GoogleSubscriptionNotificationType.SUBSCRIPTION_RENEWED:
        await this.handleGoogleRenewed(subscription);
        break;

      case GoogleSubscriptionNotificationType.SUBSCRIPTION_CANCELED:
        await this.handleGoogleCanceled(subscription);
        break;

      case GoogleSubscriptionNotificationType.SUBSCRIPTION_ON_HOLD:
        await this.handleGoogleOnHold(subscription);
        break;

      case GoogleSubscriptionNotificationType.SUBSCRIPTION_IN_GRACE_PERIOD:
        await this.handleGoogleGracePeriod(subscription);
        break;

      case GoogleSubscriptionNotificationType.SUBSCRIPTION_RECOVERED:
        await this.handleGoogleRecovered(subscription);
        break;

      case GoogleSubscriptionNotificationType.SUBSCRIPTION_REVOKED:
        await this.handleGoogleRevoked(subscription);
        break;

      case GoogleSubscriptionNotificationType.SUBSCRIPTION_EXPIRED:
        await this.handleGoogleExpired(subscription);
        break;

      case GoogleSubscriptionNotificationType.SUBSCRIPTION_RESTARTED:
        await this.handleGoogleRestarted(subscription);
        break;

      default:
        this.logger.log(
          `[Google RTDN] Unhandled subscription notification type: ${notificationType}`,
        );
    }
  }

  private async handleGoogleRenewed(subscription: any): Promise<void> {
    this.logger.log(`[Google RTDN] RENEWED: user=${subscription.userId}`);

    // In production, call Google Play Developer API to get updated expiry date
    // For now, extend by plan duration
    const plan = await this.prisma.subscriptionPlan.findUnique({
      where: { id: subscription.planId },
    });

    const newEndDate = new Date(subscription.endDate);
    if (plan?.durationDays && plan.durationDays > 0) {
      newEndDate.setDate(newEndDate.getDate() + plan.durationDays);
    } else if (plan) {
      newEndDate.setMonth(newEndDate.getMonth() + plan.durationMonths);
    }

    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        status: SubscriptionStatus.ACTIVE,
        endDate: newEndDate,
        isAutoRenew: true,
      },
    });

    await this.updateUserPremiumStatus(subscription.userId);

    await this.sendNotification(
      subscription.userId,
      '✅ Gia hạn Premium thành công',
      'Gói Premium Google Play đã được tự động gia hạn.',
    );
  }

  private async handleGoogleCanceled(subscription: any): Promise<void> {
    this.logger.log(`[Google RTDN] CANCELED: user=${subscription.userId}`);

    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        isAutoRenew: false,
        cancelledAt: new Date(),
      },
    });

    await this.sendNotification(
      subscription.userId,
      'Tự động gia hạn đã tắt',
      'Gói Premium sẽ hết hạn và không tự động gia hạn. Bạn vẫn có thể sử dụng đến hết kỳ hiện tại.',
    );
  }

  private async handleGoogleOnHold(subscription: any): Promise<void> {
    this.logger.log(`[Google RTDN] ON_HOLD: user=${subscription.userId}`);

    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: { status: SubscriptionStatus.GRACE_PERIOD },
    });

    // Revoke premium on hold
    await this.updateUserPremiumStatus(subscription.userId);

    await this.sendNotification(
      subscription.userId,
      '⚠️ Tài khoản tạm giữ',
      'Không thể thanh toán gia hạn Premium. Vui lòng cập nhật phương thức thanh toán trên Google Play.',
    );
  }

  private async handleGoogleGracePeriod(subscription: any): Promise<void> {
    this.logger.log(`[Google RTDN] GRACE_PERIOD: user=${subscription.userId}`);

    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: { status: SubscriptionStatus.GRACE_PERIOD },
    });

    await this.sendNotification(
      subscription.userId,
      '⚠️ Vấn đề thanh toán',
      'Vui lòng cập nhật phương thức thanh toán Google Play để tiếp tục Premium.',
    );
  }

  private async handleGoogleRecovered(subscription: any): Promise<void> {
    this.logger.log(`[Google RTDN] RECOVERED: user=${subscription.userId}`);

    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        status: SubscriptionStatus.ACTIVE,
        isAutoRenew: true,
      },
    });

    await this.updateUserPremiumStatus(subscription.userId);

    await this.sendNotification(
      subscription.userId,
      '✅ Premium đã khôi phục',
      'Gói Premium đã được kích hoạt lại. Chúc bạn trải nghiệm vui vẻ!',
    );
  }

  private async handleGoogleRevoked(subscription: any): Promise<void> {
    this.logger.log(`[Google RTDN] REVOKED: user=${subscription.userId}`);

    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        status: SubscriptionStatus.CANCELLED,
        cancelledAt: new Date(),
        isAutoRenew: false,
      },
    });

    await this.updateUserPremiumStatus(subscription.userId);
  }

  private async handleGoogleExpired(subscription: any): Promise<void> {
    this.logger.log(`[Google RTDN] EXPIRED: user=${subscription.userId}`);

    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: { status: SubscriptionStatus.EXPIRED },
    });

    await this.updateUserPremiumStatus(subscription.userId);

    await this.sendNotification(
      subscription.userId,
      'Gói Premium đã hết hạn',
      'Gói Premium của bạn đã hết hạn. Gia hạn ngay trên Google Play!',
    );
  }

  private async handleGoogleRestarted(subscription: any): Promise<void> {
    this.logger.log(`[Google RTDN] RESTARTED: user=${subscription.userId}`);

    await this.prisma.subscription.update({
      where: { id: subscription.id },
      data: {
        status: SubscriptionStatus.ACTIVE,
        isAutoRenew: true,
      },
    });

    await this.updateUserPremiumStatus(subscription.userId);

    await this.sendNotification(
      subscription.userId,
      '✅ Premium đã kích hoạt lại',
      'Gói Premium đã được kích hoạt lại từ trạng thái tạm dừng.',
    );
  }

  // ==================== Helper Functions ====================

  /**
   * Decode Apple JWS (JSON Web Signature) payload
   * In production, this should verify the signature against Apple's root certificates
   */
  private async decodeAppleJWS<T>(
    jws: string,
    environment: string,
  ): Promise<T | null> {
    try {
      // For production, verify the JWS signature with Apple's certificates
      // For development/sandbox, decode without strict verification
      const isProduction =
        this.configService.get<string>('NODE_ENV') === 'production' &&
        environment === 'Production';

      if (isProduction) {
        // TODO: Implement full JWS verification with Apple root certificates
        // 1. Extract the x5c header from JWS
        // 2. Verify certificate chain against Apple's root CA
        // 3. Verify the JWS signature
        //
        // Example with jose library:
        // const { payload } = await jose.jwtVerify(jws, applePublicKey, {
        //   issuer: 'https://appleid.apple.com',
        // });
        // return payload as T;

        this.logger.warn(
          `[Apple ${environment}] JWS signature verification not yet implemented. Decoding payload without verification.`,
        );
      }

      // Decode JWS payload without verification (for development/sandbox)
      // JWS format: header.payload.signature
      const parts = jws.split('.');
      if (parts.length !== 3) {
        this.logger.error(`[Apple ${environment}] Invalid JWS format`);
        return null;
      }

      const payloadBase64 = parts[1];
      const payloadJson = Buffer.from(payloadBase64, 'base64url').toString(
        'utf-8',
      );
      return JSON.parse(payloadJson) as T;
    } catch (error) {
      this.logger.error(
        `[Apple ${environment}] Error decoding JWS: ${error.message}`,
      );
      return null;
    }
  }

  /**
   * Find subscription by Apple original transaction ID
   */
  private async findSubscriptionByOriginalTx(originalTxId: string) {
    const subscription = await this.prisma.subscription.findFirst({
      where: { originalTxId },
      include: { plan: true },
    });

    if (!subscription) {
      this.logger.warn(
        `Subscription not found for originalTxId=${originalTxId}`,
      );
    }

    return subscription;
  }

  /**
   * Update user's premium status based on active subscriptions
   */
  private async updateUserPremiumStatus(userId: string): Promise<void> {
    const activeSubscription = await this.prisma.subscription.findFirst({
      where: {
        userId,
        status: {
          in: [SubscriptionStatus.ACTIVE, SubscriptionStatus.GRACE_PERIOD],
        },
        endDate: { gte: new Date() },
      },
      orderBy: { endDate: 'desc' },
    });

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        isPremium: !!activeSubscription,
        premiumUntil: activeSubscription?.endDate ?? null,
      },
    });
  }

  /**
   * Send push notification to user
   */
  private async sendNotification(
    userId: string,
    title: string,
    body: string,
  ): Promise<void> {
    try {
      await this.notificationsService.createNotification({
        userId,
        type: NotificationType.PAYMENT,
        title,
        body,
        actionType: 'subscription',
      });
    } catch (error) {
      this.logger.warn(
        `Failed to send notification to user ${userId}: ${error.message}`,
      );
    }
  }
}
