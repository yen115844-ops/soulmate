import { BadRequestException, ForbiddenException, Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../database/prisma/prisma.service';
import { NotificationType, SubscriptionStatus } from '../../generated/prisma/client';
import { NotificationsService } from '../notifications';
import { VerifyPurchaseDto } from './dto';
 
@Injectable()
export class SubscriptionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ==================== Public APIs ====================

  /**
   * Get all active subscription plans
   */
  async getPlans() {
    return this.prisma.subscriptionPlan.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
    });
  }

  /**
   * Get current subscription status for a user
   */
  async getStatus(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        isPremium: true,
        premiumUntil: true,
      },
    });

    const activeSubscription = await this.prisma.subscription.findFirst({
      where: {
        userId,
        status: SubscriptionStatus.ACTIVE,
        endDate: { gte: new Date() },
      },
      include: {
        plan: true,
      },
      orderBy: { endDate: 'desc' },
    });

    return {
      isPremium: user?.isPremium ?? false,
      premiumUntil: user?.premiumUntil,
      activeSubscription: activeSubscription
        ? {
            id: activeSubscription.id,
            plan: {
              id: activeSubscription.plan.id,
              code: activeSubscription.plan.code,
              name: activeSubscription.plan.name,
              nameVi: activeSubscription.plan.nameVi,
            },
            status: activeSubscription.status,
            startDate: activeSubscription.startDate,
            endDate: activeSubscription.endDate,
            isAutoRenew: activeSubscription.isAutoRenew,
          }
        : null,
    };
  }

  /**
   * Verify IAP purchase and activate subscription
   */
  async verifyPurchase(userId: string, dto: VerifyPurchaseDto) {
    // Verify receipt with Apple/Google
    const verificationResult = await this.verifyReceipt(dto);

    if (!verificationResult.isValid) {
      throw new BadRequestException('Invalid purchase receipt');
    }

    // Find the plan
    const plan = await this.prisma.subscriptionPlan.findFirst({
      where: dto.platform === 'ios'
        ? { appleProductId: dto.productId }
        : { googleProductId: dto.productId },
    });

    if (!plan) {
      throw new BadRequestException('Unknown product ID');
    }

    // Check for duplicate transaction
    const existingSubscription = await this.prisma.subscription.findFirst({
      where: {
        originalTxId: verificationResult.originalTransactionId,
      },
    });

    if (existingSubscription) {
      // This is a restore or duplicate - just return existing
      return this.getStatus(userId);
    }

    // Calculate dates
    const startDate = new Date();
    const endDate = new Date();
    
    // Support both weekly (durationDays) and monthly (durationMonths) plans
    if (plan.durationDays && plan.durationDays > 0) {
      // Weekly plan: use durationDays
      endDate.setDate(endDate.getDate() + plan.durationDays);
    } else {
      // Monthly/yearly plan: use durationMonths
      endDate.setMonth(endDate.getMonth() + plan.durationMonths);
    }

    // Create subscription
    const subscription = await this.prisma.subscription.create({
      data: {
        userId,
        planId: plan.id,
        status: SubscriptionStatus.ACTIVE,
        startDate,
        endDate,
        platform: dto.platform,
        originalTxId: verificationResult.originalTransactionId,
        latestTxId: verificationResult.transactionId,
        receiptData: dto.receiptData,
        isAutoRenew: true,
      },
      include: { plan: true },
    });

    // Update user premium status
    await this.updateUserPremiumStatus(userId);

    // Send notification
    await this.notificationsService.createNotification({
      userId,
      type: NotificationType.PAYMENT,
      title: '🎉 Chúc mừng bạn đã nâng cấp Premium!',
      body: `Gói ${plan.nameVi} đã được kích hoạt. Hãy khám phá các tính năng mới!`,
      actionType: 'subscription',
    });

    return {
      success: true,
      subscription: {
        id: subscription.id,
        plan: {
          id: plan.id,
          code: plan.code,
          name: plan.name,
          nameVi: plan.nameVi,
        },
        startDate: subscription.startDate,
        endDate: subscription.endDate,
      },
    };
  }

  /**
   * Restore purchases (for when user reinstalls app)
   */
  async restorePurchases(userId: string, dto: { platform: string; receiptData: string }) {
    const verificationResult = await this.verifyReceipt({
      platform: dto.platform as 'ios' | 'android',
      receiptData: dto.receiptData,
      productId: '', // Not needed for restore
    });

    if (!verificationResult.isValid) {
      throw new BadRequestException('Invalid receipt for restore');
    }

    // Find existing subscription by original transaction ID
    const existingSubscription = await this.prisma.subscription.findFirst({
      where: {
        originalTxId: verificationResult.originalTransactionId,
      },
      include: { plan: true },
    });

    if (existingSubscription) {
      // Update to current user if different
      if (existingSubscription.userId !== userId) {
        await this.prisma.subscription.update({
          where: { id: existingSubscription.id },
          data: { userId },
        });
      }

      // Update user premium status
      await this.updateUserPremiumStatus(userId);

      return {
        success: true,
        restored: true,
        subscription: {
          id: existingSubscription.id,
          planCode: existingSubscription.plan.code,
          endDate: existingSubscription.endDate,
        },
      };
    }

    return {
      success: true,
      restored: false,
      message: 'No previous purchases found',
    };
  }

  // ==================== Premium Feature Guards ====================

  /**
   * Check if user has premium subscription (required for chat and booking)
   */
  async canSendMessage(userId: string): Promise<{ allowed: boolean; reason?: string }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { isPremium: true },
    });

    if (user?.isPremium) {
      return { allowed: true };
    }

    return {
      allowed: false,
      reason: 'Tính năng chat yêu cầu gói Premium. Vui lòng nâng cấp để tiếp tục.',
    };
  }

  /**
   * Check if user can create bookings (requires Premium)
   */
  async canCreateBooking(userId: string): Promise<{ allowed: boolean; reason?: string }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { isPremium: true },
    });

    if (user?.isPremium) {
      return { allowed: true };
    }

    return {
      allowed: false,
      reason: 'Tính năng booking yêu cầu gói Premium. Vui lòng nâng cấp để tiếp tục.',
    };
  }

  /**
   * Check if user can see who favorited them
   */
  async canSeeAdmirers(userId: string): Promise<{ allowed: boolean; reason?: string }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { isPremium: true },
    });

    if (!user?.isPremium) {
      return {
        allowed: false,
        reason: 'Nâng cấp Premium để xem ai đã quan tâm đến bạn!',
      };
    }

    return { allowed: true };
  }

  /**
   * Get list of users who favorited this user (Premium only)
   */
  async getAdmirers(userId: string) {
    const canSee = await this.canSeeAdmirers(userId);
    if (!canSee.allowed) {
      throw new ForbiddenException(canSee.reason);
    }

    return this.prisma.favorite.findMany({
      where: { partnerId: userId },
      include: {
        user: {
          select: {
            id: true,
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
    });
  }

  // ==================== Internal Functions ====================

  /**
   * Update user's premium status based on active subscriptions
   */
  private async updateUserPremiumStatus(userId: string) {
    const activeSubscription = await this.prisma.subscription.findFirst({
      where: {
        userId,
        status: SubscriptionStatus.ACTIVE,
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
   * Verify receipt with Apple/Google (placeholder for actual implementation)
   */
  private async verifyReceipt(dto: {
    platform: 'ios' | 'android';
    receiptData: string;
    productId: string;
  }): Promise<{
    isValid: boolean;
    transactionId?: string;
    originalTransactionId?: string;
    expiresAt?: Date;
  }> {
    // In production, implement actual verification:
    // iOS: https://developer.apple.com/documentation/storekit/in-app_purchase/original_api_for_in-app_purchase/validating_receipts_with_the_app_store
    // Android: https://developer.android.com/google/play/billing/integrate

    // For development, simulate successful verification
    if (process.env.NODE_ENV !== 'production') {
      return {
        isValid: true,
        transactionId: `txn_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        originalTransactionId: `orig_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      };
    }

    // Production: Call Apple/Google APIs
    if (dto.platform === 'ios') {
      return this.verifyAppleReceipt(dto.receiptData);
    } else {
      return this.verifyGoogleReceipt(dto.receiptData, dto.productId);
    }
  }

  private async verifyAppleReceipt(receiptData: string): Promise<{
    isValid: boolean;
    transactionId?: string;
    originalTransactionId?: string;
    expiresAt?: Date;
  }> {
    // TODO: Implement Apple receipt verification
    // https://developer.apple.com/documentation/appstoreserverapi
    return { isValid: false };
  }

  private async verifyGoogleReceipt(receiptData: string, productId: string): Promise<{
    isValid: boolean;
    transactionId?: string;
    originalTransactionId?: string;
    expiresAt?: Date;
  }> {
    // TODO: Implement Google Play receipt verification
    // https://developer.android.com/google/play/billing/integrate
    return { isValid: false };
  }

  // ==================== Scheduled Jobs ====================

  /**
   * Check and expire subscriptions daily
   */
  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async handleExpiredSubscriptions() {
    const now = new Date();

    // Find expired subscriptions
    const expiredSubscriptions = await this.prisma.subscription.findMany({
      where: {
        status: SubscriptionStatus.ACTIVE,
        endDate: { lt: now },
      },
      include: { user: true },
    });

    for (const subscription of expiredSubscriptions) {
      // Update subscription status
      await this.prisma.subscription.update({
        where: { id: subscription.id },
        data: { status: SubscriptionStatus.EXPIRED },
      });

      // Update user premium status
      await this.updateUserPremiumStatus(subscription.userId);

      // Notify user
      await this.notificationsService.createNotification({
        userId: subscription.userId,
        type: NotificationType.SYSTEM,
        title: 'Gói Premium đã hết hạn',
        body: 'Gói Premium của bạn đã hết hạn. Gia hạn ngay để tiếp tục sử dụng các tính năng độc quyền!',
        actionType: 'subscription',
      });
    }

    console.log(`[Subscription] Expired ${expiredSubscriptions.length} subscriptions`);
  }

  // ==================== Admin Functions ====================

  /**
   * Get subscription stats for admin
   */
  async adminGetStats() {
    const [totalActive, totalExpired, totalRevenue, monthlyRevenue] = await Promise.all([
      this.prisma.subscription.count({ where: { status: SubscriptionStatus.ACTIVE } }),
      this.prisma.subscription.count({ where: { status: SubscriptionStatus.EXPIRED } }),
      this.prisma.subscription.count(), // Placeholder for actual revenue calculation
      this.getMonthlyRevenue(),
    ]);

    return {
      totalActive,
      totalExpired,
      totalSubscriptions: totalActive + totalExpired,
      monthlyRevenue,
    };
  }

  private async getMonthlyRevenue(): Promise<number> {
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const subscriptions = await this.prisma.subscription.findMany({
      where: {
        createdAt: { gte: startOfMonth },
        status: { not: SubscriptionStatus.CANCELLED },
      },
      include: { plan: true },
    });

    return subscriptions.reduce((sum, sub) => sum + Number(sub.plan.priceVnd), 0);
  }

  /**
   * Get all subscriptions with pagination
   */
  async adminGetList(params: {
    page?: number;
    limit?: number;
    status?: SubscriptionStatus;
    search?: string;
  }) {
    const { page = 1, limit = 10, status, search } = params;
    const skip = (page - 1) * limit;

    const where: any = {};
    
    if (status) {
      where.status = status;
    }

    if (search) {
      where.user = {
        OR: [
          { email: { contains: search, mode: 'insensitive' } },
          { profile: { fullName: { contains: search, mode: 'insensitive' } } },
        ],
      };
    }

    const [data, total] = await Promise.all([
      this.prisma.subscription.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
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
          plan: true,
        },
      }),
      this.prisma.subscription.count({ where }),
    ]);

    return {
      data,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }
}
