import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../database/prisma/prisma.service';
import { NotificationType, TransactionStatus, TransactionType } from '../../generated/prisma/client';
import { NotificationsService } from '../notifications';
import {
    CREDIT_TO_VND_RATE,
    MINIMUM_WITHDRAWAL_CREDITS,
    calculatePlatformFee,
    creditsToVnd,
} from './credits.constants';
import { CreateCreditPackageDto, UpdateBankInfoDto, UpdateCreditPackageDto, VerifyCreditPurchaseDto, WithdrawCreditsDto } from './dto';

@Injectable()
export class CreditsService {
  private readonly logger = new Logger(CreditsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ==================== Public APIs ====================

  /**
   * Get all available credit packages
   */
  async getPackages() {
    return this.prisma.creditPackage.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
    });
  }

  /**
   * Get user's wallet (credits balance)
   */
  async getWallet(userId: string) {
    const wallet = await this.getOrCreateWallet(userId);
    
    return {
      id: wallet.id,
      balance: wallet.balance,
      pendingBalance: wallet.pendingBalance,
      totalEarnings: wallet.totalEarnings,
      totalSpent: wallet.totalSpent,
      bankInfo: wallet.bankName ? {
        bankName: wallet.bankName,
        bankAccountNo: wallet.bankAccountNo,
        bankAccountName: wallet.bankAccountName,
      } : null,
      exchangeRate: CREDIT_TO_VND_RATE,
      balanceInVnd: creditsToVnd(wallet.balance),
    };
  }

  /**
   * Get transaction history
   */
  async getTransactions(userId: string, page = 1, limit = 20) {
    const wallet = await this.getOrCreateWallet(userId);

    const [transactions, total] = await Promise.all([
      this.prisma.transaction.findMany({
        where: { walletId: wallet.id },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.transaction.count({
        where: { walletId: wallet.id },
      }),
    ]);

    return {
      data: transactions.map(tx => ({
        id: tx.id,
        code: tx.transactionCode,
        type: tx.type,
        amount: tx.amount,
        status: tx.status,
        description: tx.description,
        balanceBefore: tx.balanceBefore,
        balanceAfter: tx.balanceAfter,
        createdAt: tx.createdAt,
      })),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Verify credit purchase via IAP and add credits to wallet
   */
  async verifyCreditPurchase(userId: string, dto: VerifyCreditPurchaseDto) {
    // Find the package
    const creditPackage = await this.prisma.creditPackage.findFirst({
      where: dto.platform === 'ios'
        ? { appleProductId: dto.productId }
        : { googleProductId: dto.productId },
    });

    if (!creditPackage) {
      throw new BadRequestException('Unknown product ID');
    }

    // Check for duplicate transaction
    const existingPurchase = await this.prisma.creditPurchase.findFirst({
      where: { transactionId: dto.transactionId },
    });

    if (existingPurchase) {
      this.logger.warn(`Duplicate purchase attempt: ${dto.transactionId}`);
      throw new BadRequestException('This purchase has already been processed');
    }

    // Verify receipt with Apple/Google
    const verificationResult = await this.verifyReceipt(dto);

    if (!verificationResult.isValid) {
      throw new BadRequestException('Invalid purchase receipt');
    }

    // Calculate total credits
    const totalCredits = creditPackage.creditAmount + creditPackage.bonusCredits;

    // Process purchase in transaction
    const result = await this.prisma.$transaction(async (tx) => {
      // Create purchase record
      const purchase = await tx.creditPurchase.create({
        data: {
          userId,
          packageId: creditPackage.id,
          creditsReceived: totalCredits,
          platform: dto.platform,
          transactionId: dto.transactionId,
          receiptData: dto.receiptData,
          status: TransactionStatus.COMPLETED,
          verifiedAt: new Date(),
        },
      });

      // Add credits to wallet
      const wallet = await this.addCredits(
        tx,
        userId,
        totalCredits,
        TransactionType.CREDIT_PURCHASE,
        `Mua ${totalCredits} credits`,
      );

      return { purchase, wallet };
    });

    // Send notification
    await this.notificationsService.sendNotification({
      userId,
      type: NotificationType.PAYMENT,
      title: 'Mua Credits thành công',
      body: `Bạn đã nhận ${totalCredits} credits vào tài khoản`,
      data: { purchaseId: result.purchase.id },
    }).catch((err) => this.logger.warn(`Failed to send purchase notification: ${err?.message}`));

    return {
      success: true,
      creditsReceived: totalCredits,
      newBalance: result.wallet.balance,
    };
  }

  /**
   * Request withdrawal (convert credits to VND)
   */
  async requestWithdrawal(userId: string, dto: WithdrawCreditsDto) {
    const wallet = await this.getOrCreateWallet(userId);

    // Validate
    if (dto.amount < MINIMUM_WITHDRAWAL_CREDITS) {
      throw new BadRequestException(`Minimum withdrawal is ${MINIMUM_WITHDRAWAL_CREDITS} credits`);
    }

    if (wallet.balance < dto.amount) {
      throw new BadRequestException('Insufficient balance');
    }

    if (!wallet.bankName || !wallet.bankAccountNo) {
      throw new BadRequestException('Please add bank account information first');
    }

    // Calculate VND amount
    const vndAmount = creditsToVnd(dto.amount);

    // Create withdrawal transaction
    const result = await this.prisma.$transaction(async (tx) => {
      const balanceBefore = wallet.balance;
      const balanceAfter = balanceBefore - dto.amount;

      // Deduct credits
      await tx.wallet.update({
        where: { id: wallet.id },
        data: { balance: balanceAfter },
      });

      // Create transaction
      const transaction = await tx.transaction.create({
        data: {
          transactionCode: await this.generateTransactionCode(tx),
          walletId: wallet.id,
          type: TransactionType.WITHDRAWAL,
          amount: dto.amount,
          balanceBefore,
          balanceAfter,
          status: TransactionStatus.PENDING,
          description: `Rút ${dto.amount} credits = ${vndAmount.toLocaleString()}đ`,
          metadata: {
            vndAmount,
            bankName: wallet.bankName,
            bankAccountNo: wallet.bankAccountNo,
            bankAccountName: wallet.bankAccountName,
            note: dto.note,
          },
        },
      });

      return transaction;
    });

    // Notify admins about withdrawal request
    this.logger.log(`Withdrawal request: User ${userId}, ${dto.amount} credits = ${vndAmount}đ`);

    return {
      success: true,
      transactionId: result.id,
      amount: dto.amount,
      vndAmount,
      status: 'PENDING',
      message: 'Yêu cầu rút tiền đã được gửi. Vui lòng chờ xử lý trong 1-3 ngày làm việc.',
    };
  }

  /**
   * Update bank account info
   */
  async updateBankInfo(userId: string, dto: UpdateBankInfoDto) {
    const wallet = await this.getOrCreateWallet(userId);

    await this.prisma.wallet.update({
      where: { id: wallet.id },
      data: {
        bankName: dto.bankName,
        bankAccountNo: dto.bankAccountNo,
        bankAccountName: dto.bankAccountName,
      },
    });

    return { success: true };
  }

  // ==================== Booking Payment APIs ====================

  /**
   * Check if user has enough credits for booking
   */
  async checkBalance(userId: string, requiredAmount: number): Promise<boolean> {
    const wallet = await this.getOrCreateWallet(userId);
    return wallet.balance >= requiredAmount;
  }

  /**
   * Pay for a booking (move credits to escrow)
   */
  async payBooking(bookingId: string, userId: string, partnerId: string, amount: number) {
    const wallet = await this.getOrCreateWallet(userId);

    if (wallet.balance < amount) {
      throw new BadRequestException('Số dư credits không đủ');
    }

    const platformFee = calculatePlatformFee(amount);
    const partnerAmount = amount - platformFee;

    return this.prisma.$transaction(async (tx) => {
      const balanceBefore = wallet.balance;
      const balanceAfter = balanceBefore - amount;

      // Deduct from user wallet
      await tx.wallet.update({
        where: { id: wallet.id },
        data: {
          balance: balanceAfter,
          totalSpent: { increment: amount },
        },
      });

      // Create transaction
      await tx.transaction.create({
        data: {
          transactionCode: await this.generateTransactionCode(tx),
          walletId: wallet.id,
          bookingId,
          type: TransactionType.BOOKING_PAYMENT,
          amount,
          fee: platformFee,
          balanceBefore,
          balanceAfter,
          status: TransactionStatus.COMPLETED,
          description: `Thanh toán booking ${bookingId}`,
        },
      });

      // Create escrow holding
      const escrow = await tx.escrowHolding.create({
        data: {
          bookingId,
          payerId: userId,
          payeeId: partnerId,
          amount: partnerAmount,
          platformFee,
          totalAmount: amount,
        },
      });

      return escrow;
    });
  }

  /**
   * Release escrow to partner (after booking completion)
   */
  async releaseEscrow(bookingId: string) {
    const escrow = await this.prisma.escrowHolding.findUnique({
      where: { bookingId },
    });

    if (!escrow || escrow.status !== 'HELD') {
      throw new BadRequestException('No valid escrow found for this booking');
    }

    return this.prisma.$transaction(async (tx) => {
      // Update escrow status
      await tx.escrowHolding.update({
        where: { id: escrow.id },
        data: {
          status: 'RELEASED',
          releasedAt: new Date(),
        },
      });

      // Add credits to partner wallet
      const partnerWallet = await this.getOrCreateWallet(escrow.payeeId, tx);
      const balanceBefore = partnerWallet.balance;
      const balanceAfter = balanceBefore + escrow.amount;

      await tx.wallet.update({
        where: { id: partnerWallet.id },
        data: {
          balance: balanceAfter,
          totalEarnings: { increment: escrow.amount },
        },
      });

      // Create transaction for partner
      await tx.transaction.create({
        data: {
          transactionCode: await this.generateTransactionCode(tx),
          walletId: partnerWallet.id,
          bookingId,
          type: TransactionType.PARTNER_EARNING,
          amount: escrow.amount,
          balanceBefore,
          balanceAfter,
          status: TransactionStatus.COMPLETED,
          description: `Thu nhập từ booking ${bookingId}`,
        },
      });

      // Notify partner
      await this.notificationsService.sendNotification({
        userId: escrow.payeeId,
        type: NotificationType.PAYMENT,
        title: 'Nhận thanh toán',
        body: `Bạn đã nhận ${escrow.amount} credits từ booking hoàn thành`,
        data: { bookingId },
      }).catch((err) => this.logger.warn(`Failed to send release notification: ${err?.message}`));

      return { success: true };
    });
  }

  /**
   * Refund escrow to user (booking cancelled)
   */
  async refundEscrow(bookingId: string) {
    const escrow = await this.prisma.escrowHolding.findUnique({
      where: { bookingId },
    });

    if (!escrow || escrow.status !== 'HELD') {
      return { success: true, message: 'No escrow to refund' };
    }

    return this.prisma.$transaction(async (tx) => {
      // Update escrow status
      await tx.escrowHolding.update({
        where: { id: escrow.id },
        data: {
          status: 'REFUNDED',
          refundedAt: new Date(),
        },
      });

      // Refund credits to user
      const userWallet = await this.getOrCreateWallet(escrow.payerId, tx);
      const balanceBefore = userWallet.balance;
      const balanceAfter = balanceBefore + escrow.totalAmount;

      await tx.wallet.update({
        where: { id: userWallet.id },
        data: {
          balance: balanceAfter,
          totalSpent: { decrement: escrow.totalAmount },
        },
      });

      // Create refund transaction
      await tx.transaction.create({
        data: {
          transactionCode: await this.generateTransactionCode(tx),
          walletId: userWallet.id,
          bookingId,
          type: TransactionType.ESCROW_REFUND,
          amount: escrow.totalAmount,
          balanceBefore,
          balanceAfter,
          status: TransactionStatus.COMPLETED,
          description: `Hoàn tiền booking ${bookingId}`,
        },
      });

      // Notify user
      await this.notificationsService.sendNotification({
        userId: escrow.payerId,
        type: NotificationType.PAYMENT,
        title: 'Hoàn tiền',
        body: `Bạn đã được hoàn ${escrow.totalAmount} credits do booking bị hủy`,
        data: { bookingId },
      }).catch((err) => this.logger.warn(`Failed to send refund notification: ${err?.message}`));

      return { success: true };
    });
  }

  // ==================== Internal Methods ====================

  /**
   * Get or create wallet for user
   */
  private async getOrCreateWallet(userId: string, tx?: any) {
    const prisma = tx || this.prisma;

    let wallet = await prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      wallet = await prisma.wallet.create({
        data: { userId },
      });
    }

    return wallet;
  }

  /**
   * Add credits to wallet (internal)
   */
  private async addCredits(
    tx: any,
    userId: string,
    amount: number,
    type: TransactionType,
    description: string,
  ) {
    const wallet = await this.getOrCreateWallet(userId, tx);
    const balanceBefore = wallet.balance;
    const balanceAfter = balanceBefore + amount;

    await tx.wallet.update({
      where: { id: wallet.id },
      data: { balance: balanceAfter },
    });

    await tx.transaction.create({
      data: {
        transactionCode: await this.generateTransactionCode(tx),
        walletId: wallet.id,
        type,
        amount,
        balanceBefore,
        balanceAfter,
        status: TransactionStatus.COMPLETED,
        description,
      },
    });

    return { ...wallet, balance: balanceAfter };
  }

  /**
   * Generate unique transaction code
   */
  private async generateTransactionCode(tx?: any): Promise<string> {
    const prisma = tx || this.prisma;
    const date = new Date();
    const prefix = `TXN-${date.getFullYear()}${(date.getMonth() + 1).toString().padStart(2, '0')}`;
    
    const count = await prisma.transaction.count({
      where: {
        transactionCode: { startsWith: prefix },
      },
    });

    return `${prefix}-${(count + 1).toString().padStart(6, '0')}`;
  }

  /**
   * Verify IAP receipt with Apple/Google
   */
  private async verifyReceipt(dto: VerifyCreditPurchaseDto): Promise<{ isValid: boolean }> {
    // TODO: Implement actual receipt verification with Apple/Google servers
    // For now, return valid for development
    this.logger.log(`Verifying receipt for ${dto.platform}: ${dto.transactionId}`);
    return { isValid: true };
  }

  // ==================== Admin Credit Package Management ====================

  /**
   * Create a new credit package (Admin)
   */
  async createPackage(dto: CreateCreditPackageDto) {
    return this.prisma.creditPackage.create({
      data: {
        code: dto.code,
        name: dto.name,
        nameVi: dto.nameVi,
        description: dto.description,
        creditAmount: dto.creditAmount,
        bonusCredits: dto.bonusCredits ?? 0,
        priceVnd: dto.priceVnd,
        appleProductId: dto.appleProductId,
        googleProductId: dto.googleProductId,
        originalPrice: dto.originalPrice,
        discountPercent: dto.discountPercent,
        isActive: dto.isActive ?? true,
        isBestValue: dto.isBestValue ?? false,
        sortOrder: dto.sortOrder ?? 0,
      },
    });
  }

  /**
   * Update a credit package (Admin)
   */
  async updatePackage(id: string, dto: UpdateCreditPackageDto) {
    const existing = await this.prisma.creditPackage.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new BadRequestException('Credit package not found');
    }

    return this.prisma.creditPackage.update({
      where: { id },
      data: {
        ...(dto.code !== undefined && { code: dto.code }),
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.nameVi !== undefined && { nameVi: dto.nameVi }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.creditAmount !== undefined && { creditAmount: dto.creditAmount }),
        ...(dto.bonusCredits !== undefined && { bonusCredits: dto.bonusCredits }),
        ...(dto.priceVnd !== undefined && { priceVnd: dto.priceVnd }),
        ...(dto.appleProductId !== undefined && { appleProductId: dto.appleProductId }),
        ...(dto.googleProductId !== undefined && { googleProductId: dto.googleProductId }),
        ...(dto.originalPrice !== undefined && { originalPrice: dto.originalPrice }),
        ...(dto.discountPercent !== undefined && { discountPercent: dto.discountPercent }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
        ...(dto.isBestValue !== undefined && { isBestValue: dto.isBestValue }),
        ...(dto.sortOrder !== undefined && { sortOrder: dto.sortOrder }),
      },
    });
  }

  /**
   * Delete a credit package (Admin)
   */
  async deletePackage(id: string) {
    const existing = await this.prisma.creditPackage.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new BadRequestException('Credit package not found');
    }

    // Check if there are any purchases using this package
    const purchaseCount = await this.prisma.creditPurchase.count({
      where: { packageId: id },
    });

    if (purchaseCount > 0) {
      // Soft delete by marking as inactive
      return this.prisma.creditPackage.update({
        where: { id },
        data: { isActive: false },
      });
    }

    // Hard delete if no purchases
    return this.prisma.creditPackage.delete({
      where: { id },
    });
  }
}
