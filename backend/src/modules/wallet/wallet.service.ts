import { BadRequestException, Injectable } from '@nestjs/common';
import { TransactionStatus, TransactionType } from '@prisma/client';
import { PrismaService } from '../../database/prisma/prisma.service';

@Injectable()
export class WalletService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Get or create wallet for user
   */
  async getOrCreateWallet(userId: string) {
    let wallet = await this.prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      wallet = await this.prisma.wallet.create({
        data: { userId },
      });
    }

    return {
      id: wallet.id,
      balance: Number(wallet.balance),
      pendingBalance: Number(wallet.pendingBalance),
      totalEarnings: Number(wallet.totalEarnings),
      totalSpent: Number(wallet.totalSpent),
      currency: wallet.currency,
      bankName: wallet.bankName,
      bankAccountNo: wallet.bankAccountNo,
      bankAccountName: wallet.bankAccountName,
      createdAt: wallet.createdAt,
      updatedAt: wallet.updatedAt,
    };
  }

  /**
   * Get wallet transactions
   */
  async getTransactions(userId: string, page = 1, limit = 20) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      return { data: [], total: 0, page, limit };
    }

    const skip = (page - 1) * limit;

    const [transactions, total] = await Promise.all([
      this.prisma.transaction.findMany({
        where: { walletId: wallet.id },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.transaction.count({
        where: { walletId: wallet.id },
      }),
    ]);

    return {
      data: transactions.map((t) => ({
        id: t.id,
        transactionCode: t.transactionCode,
        type: t.type,
        amount: Number(t.amount),
        fee: Number(t.fee),
        status: t.status,
        description: t.description,
        paymentMethod: t.paymentMethod,
        createdAt: t.createdAt,
        completedAt: t.completedAt,
      })),
      total,
      page,
      limit,
    };
  }

  /**
   * Request withdrawal
   */
  async requestWithdraw(
    userId: string,
    amount: number,
    bankInfo?: { bankName: string; bankAccountNo: string; bankAccountName: string },
  ) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      throw new BadRequestException('Wallet not found');
    }

    if (Number(wallet.balance) < amount) {
      throw new BadRequestException('Insufficient balance');
    }

    // Update bank info if provided
    if (bankInfo) {
      await this.prisma.wallet.update({
        where: { id: wallet.id },
        data: {
          bankName: bankInfo.bankName,
          bankAccountNo: bankInfo.bankAccountNo,
          bankAccountName: bankInfo.bankAccountName,
        },
      });
    }

    // Check if user has bank info
    const hasBankInfo = wallet.bankName && wallet.bankAccountNo && wallet.bankAccountName;
    if (!hasBankInfo && !bankInfo) {
      throw new BadRequestException('Bank information required for withdrawal');
    }

    // Generate transaction code
    const transactionCode = `WD-${Date.now()}-${Math.random().toString(36).substr(2, 6).toUpperCase()}`;

    // Create withdrawal transaction
    const transaction = await this.prisma.$transaction(async (tx) => {
      // Deduct from balance
      const updatedWallet = await tx.wallet.update({
        where: { id: wallet.id },
        data: {
          balance: { decrement: amount },
        },
      });

      // Create transaction record
      const newTransaction = await tx.transaction.create({
        data: {
          transactionCode,
          walletId: wallet.id,
          type: TransactionType.WITHDRAWAL,
          amount,
          status: TransactionStatus.PENDING,
          balanceBefore: wallet.balance,
          balanceAfter: updatedWallet.balance,
          description: `Yêu cầu rút tiền ${amount.toLocaleString('vi-VN')} VND`,
        },
      });

      return newTransaction;
    });

    return {
      success: true,
      message: 'Yêu cầu rút tiền đã được gửi',
      transaction: {
        id: transaction.id,
        transactionCode: transaction.transactionCode,
        amount: Number(transaction.amount),
        status: transaction.status,
        createdAt: transaction.createdAt,
      },
    };
  }

  /**
   * Add earnings to partner wallet (called after booking completed)
   */
  async addEarnings(userId: string, amount: number, bookingId: string) {
    const wallet = await this.getOrCreateWallet(userId);

    const transactionCode = `EARN-${Date.now()}-${Math.random().toString(36).substr(2, 6).toUpperCase()}`;

    await this.prisma.$transaction(async (tx) => {
      const currentWallet = await tx.wallet.findUnique({
        where: { id: wallet.id },
      });

      await tx.wallet.update({
        where: { id: wallet.id },
        data: {
          balance: { increment: amount },
          totalEarnings: { increment: amount },
        },
      });

      await tx.transaction.create({
        data: {
          transactionCode,
          walletId: wallet.id,
          bookingId,
          type: TransactionType.ESCROW_RELEASE, // Earnings from completed booking
          amount,
          status: TransactionStatus.COMPLETED,
          balanceBefore: currentWallet?.balance,
          balanceAfter: Number(currentWallet?.balance || 0) + amount,
          description: `Thu nhập từ booking`,
          completedAt: new Date(),
        },
      });
    });
  }

  /**
   * Deduct payment from user wallet
   */
  async deductPayment(userId: string, amount: number, bookingId: string) {
    const wallet = await this.getOrCreateWallet(userId);

    if (Number(wallet.balance) < amount) {
      throw new BadRequestException('Số dư không đủ');
    }

    const transactionCode = `PAY-${Date.now()}-${Math.random().toString(36).substr(2, 6).toUpperCase()}`;

    await this.prisma.$transaction(async (tx) => {
      const currentWallet = await tx.wallet.findUnique({
        where: { id: wallet.id },
      });

      await tx.wallet.update({
        where: { id: wallet.id },
        data: {
          balance: { decrement: amount },
          totalSpent: { increment: amount },
        },
      });

      await tx.transaction.create({
        data: {
          transactionCode,
          walletId: wallet.id,
          bookingId,
          type: TransactionType.ESCROW_HOLD, // Payment for booking
          amount,
          status: TransactionStatus.COMPLETED,
          balanceBefore: currentWallet?.balance,
          balanceAfter: Number(currentWallet?.balance || 0) - amount,
          description: `Thanh toán booking`,
          completedAt: new Date(),
        },
      });
    });
  }

  /**
   * Top up wallet (after payment gateway callback)
   */
  async topUp(userId: string, amount: number, paymentMethod: string, externalTxId: string) {
    const wallet = await this.getOrCreateWallet(userId);

    const transactionCode = `TOP-${Date.now()}-${Math.random().toString(36).substr(2, 6).toUpperCase()}`;

    await this.prisma.$transaction(async (tx) => {
      const currentWallet = await tx.wallet.findUnique({
        where: { id: wallet.id },
      });

      await tx.wallet.update({
        where: { id: wallet.id },
        data: {
          balance: { increment: amount },
        },
      });

      await tx.transaction.create({
        data: {
          transactionCode,
          walletId: wallet.id,
          type: TransactionType.DEPOSIT, // Topup wallet
          amount,
          status: TransactionStatus.COMPLETED,
          paymentMethod,
          externalTxId,
          balanceBefore: currentWallet?.balance,
          balanceAfter: Number(currentWallet?.balance || 0) + amount,
          description: `Nạp tiền qua ${paymentMethod}`,
          completedAt: new Date(),
        },
      });
    });
  }
}
