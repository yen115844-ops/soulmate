import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { EscrowStatus, TransactionStatus, TransactionType } from '@prisma/client';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../database/prisma/prisma.service';

@Injectable()
export class WalletService {
  private readonly logger = new Logger(WalletService.name);

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
   * Request withdrawal — uses SELECT FOR UPDATE to prevent race conditions
   */
  async requestWithdraw(
    userId: string,
    amount: number,
    bankInfo?: { bankName: string; bankAccountNo: string; bankAccountName: string },
  ) {
    // Update bank info if provided (outside transaction — non-critical)
    if (bankInfo) {
      await this.prisma.wallet.update({
        where: { userId },
        data: {
          bankName: bankInfo.bankName,
          bankAccountNo: bankInfo.bankAccountNo,
          bankAccountName: bankInfo.bankAccountName,
        },
      });
    }

    const transactionCode = `WD-${Date.now()}-${randomUUID().substring(0, 8).toUpperCase()}`;

    // Use raw query with FOR UPDATE to prevent double-spend
    const transaction = await this.prisma.$transaction(async (tx) => {
      // Lock the wallet row
      const rows = await tx.$queryRawUnsafe<any[]>(
        `SELECT id, balance::numeric as balance, bank_name, bank_account_no, bank_account_name FROM wallets WHERE user_id = $1 FOR UPDATE`,
        userId,
      );
      const wallet = rows[0];

      if (!wallet) {
        throw new BadRequestException('Wallet not found');
      }

      const currentBalance = Number(wallet.balance);
      if (currentBalance < amount) {
        throw new BadRequestException('Insufficient balance');
      }

      const hasBankInfo = wallet.bank_name && wallet.bank_account_no && wallet.bank_account_name;
      if (!hasBankInfo && !bankInfo) {
        throw new BadRequestException('Bank information required for withdrawal');
      }

      const updatedWallet = await tx.wallet.update({
        where: { id: wallet.id },
        data: { balance: { decrement: amount } },
      });

      return await tx.transaction.create({
        data: {
          transactionCode,
          walletId: wallet.id,
          type: TransactionType.WITHDRAWAL,
          amount,
          status: TransactionStatus.PENDING,
          balanceBefore: currentBalance,
          balanceAfter: Number(updatedWallet.balance),
          description: `Yêu cầu rút tiền ${amount.toLocaleString('vi-VN')} VND`,
        },
      });
    });

    this.logger.log(`Withdrawal requested: ${transactionCode} for user ${userId}`);

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
   * Deduct payment from user wallet and create escrow — uses SELECT FOR UPDATE
   */
  async deductPaymentAndCreateEscrow(
    userId: string,
    partnerId: string,
    amount: number,
    serviceFee: number,
    bookingId: string,
  ) {
    const totalAmount = amount + serviceFee;
    const transactionCode = `PAY-${Date.now()}-${randomUUID().substring(0, 8).toUpperCase()}`;

    await this.prisma.$transaction(async (tx) => {
      const rows = await tx.$queryRawUnsafe<any[]>(
        `SELECT id, balance::numeric as balance FROM wallets WHERE user_id = $1 FOR UPDATE`,
        userId,
      );
      const wallet = rows[0];

      if (!wallet) {
        throw new BadRequestException('Wallet not found');
      }

      const currentBalance = Number(wallet.balance);
      if (currentBalance < totalAmount) {
        throw new BadRequestException('Số dư không đủ để thanh toán booking');
      }

      await tx.wallet.update({
        where: { id: wallet.id },
        data: {
          balance: { decrement: totalAmount },
          pendingBalance: { increment: totalAmount },
          totalSpent: { increment: totalAmount },
        },
      });

      await tx.escrowHolding.create({
        data: {
          bookingId,
          payerId: userId,
          payeeId: partnerId,
          amount,
          platformFee: serviceFee,
          totalAmount,
          status: EscrowStatus.HELD,
        },
      });

      await tx.transaction.create({
        data: {
          transactionCode,
          walletId: wallet.id,
          bookingId,
          type: TransactionType.ESCROW_HOLD,
          amount: totalAmount,
          fee: serviceFee,
          status: TransactionStatus.COMPLETED,
          balanceBefore: currentBalance,
          balanceAfter: currentBalance - totalAmount,
          description: `Thanh toán booking #${bookingId.substring(0, 8)}`,
          completedAt: new Date(),
        },
      });
    });

    this.logger.log(`Payment + escrow created: ${transactionCode} for booking ${bookingId}`);
  }

  /**
   * Release escrow to partner after booking completion — uses SELECT FOR UPDATE
   */
  async releaseEscrow(bookingId: string) {
    const escrow = await this.prisma.escrowHolding.findUnique({ where: { bookingId } });

    if (!escrow || escrow.status !== EscrowStatus.HELD) {
      this.logger.warn(`No HELD escrow for booking ${bookingId}`);
      return;
    }

    const partnerAmount = Number(escrow.amount);
    const totalAmount = Number(escrow.totalAmount);
    const transactionCode = `EARN-${Date.now()}-${randomUUID().substring(0, 8).toUpperCase()}`;

    await this.prisma.$transaction(async (tx) => {
      await tx.escrowHolding.update({
        where: { id: escrow.id },
        data: { status: EscrowStatus.RELEASED, releasedAt: new Date() },
      });

      // Reduce pending balance from payer
      await tx.wallet.update({
        where: { userId: escrow.payerId },
        data: { pendingBalance: { decrement: totalAmount } },
      });

      // Lock partner wallet and add earnings
      const partnerRows = await tx.$queryRawUnsafe<any[]>(
        `SELECT id, balance::numeric as balance FROM wallets WHERE user_id = $1 FOR UPDATE`,
        escrow.payeeId,
      );
      let partnerWallet = partnerRows[0];

      if (!partnerWallet) {
        const newWallet = await tx.wallet.create({
          data: { userId: escrow.payeeId, balance: partnerAmount, totalEarnings: partnerAmount },
        });
        await tx.transaction.create({
          data: {
            transactionCode, walletId: newWallet.id, bookingId,
            type: TransactionType.ESCROW_RELEASE, amount: partnerAmount,
            status: TransactionStatus.COMPLETED, balanceBefore: 0, balanceAfter: partnerAmount,
            description: `Thu nhập từ booking #${bookingId.substring(0, 8)}`, completedAt: new Date(),
          },
        });
      } else {
        await tx.wallet.update({
          where: { id: partnerWallet.id },
          data: { balance: { increment: partnerAmount }, totalEarnings: { increment: partnerAmount } },
        });
        await tx.transaction.create({
          data: {
            transactionCode, walletId: partnerWallet.id, bookingId,
            type: TransactionType.ESCROW_RELEASE, amount: partnerAmount,
            status: TransactionStatus.COMPLETED,
            balanceBefore: Number(partnerWallet.balance),
            balanceAfter: Number(partnerWallet.balance) + partnerAmount,
            description: `Thu nhập từ booking #${bookingId.substring(0, 8)}`, completedAt: new Date(),
          },
        });
      }
    });

    this.logger.log(`Escrow released for booking ${bookingId}: ${partnerAmount} to partner`);
  }

  /**
   * Refund escrow to user (for cancelled bookings that were already paid)
   */
  async refundEscrow(bookingId: string) {
    const escrow = await this.prisma.escrowHolding.findUnique({ where: { bookingId } });

    if (!escrow || escrow.status !== EscrowStatus.HELD) {
      this.logger.warn(`No HELD escrow for refund on booking ${bookingId}`);
      return;
    }

    const refundAmount = Number(escrow.totalAmount);
    const transactionCode = `REF-${Date.now()}-${randomUUID().substring(0, 8).toUpperCase()}`;

    await this.prisma.$transaction(async (tx) => {
      await tx.escrowHolding.update({
        where: { id: escrow.id },
        data: { status: EscrowStatus.REFUNDED, refundedAt: new Date() },
      });

      const payerRows = await tx.$queryRawUnsafe<any[]>(
        `SELECT id, balance::numeric as balance FROM wallets WHERE user_id = $1 FOR UPDATE`,
        escrow.payerId,
      );
      const payerWallet = payerRows[0];
      if (!payerWallet) throw new BadRequestException('Payer wallet not found for refund');

      await tx.wallet.update({
        where: { id: payerWallet.id },
        data: {
          balance: { increment: refundAmount },
          pendingBalance: { decrement: refundAmount },
          totalSpent: { decrement: refundAmount },
        },
      });

      await tx.transaction.create({
        data: {
          transactionCode, walletId: payerWallet.id, bookingId,
          type: TransactionType.ESCROW_REFUND, amount: refundAmount,
          status: TransactionStatus.COMPLETED,
          balanceBefore: Number(payerWallet.balance),
          balanceAfter: Number(payerWallet.balance) + refundAmount,
          description: `Hoàn tiền booking #${bookingId.substring(0, 8)}`, completedAt: new Date(),
        },
      });
    });

    this.logger.log(`Escrow refunded for booking ${bookingId}: ${refundAmount} to user`);
  }

  /**
   * Top up wallet (after payment gateway callback) — uses SELECT FOR UPDATE
   */
  async topUp(userId: string, amount: number, paymentMethod: string, externalTxId: string) {
    const transactionCode = `TOP-${Date.now()}-${randomUUID().substring(0, 8).toUpperCase()}`;

    await this.prisma.$transaction(async (tx) => {
      let wallet = await tx.wallet.findUnique({ where: { userId } });
      if (!wallet) wallet = await tx.wallet.create({ data: { userId } });

      const rows = await tx.$queryRawUnsafe<any[]>(
        `SELECT id, balance::numeric as balance FROM wallets WHERE user_id = $1 FOR UPDATE`,
        userId,
      );
      const currentBalance = Number(rows[0]?.balance || 0);

      await tx.wallet.update({ where: { id: wallet.id }, data: { balance: { increment: amount } } });

      await tx.transaction.create({
        data: {
          transactionCode, walletId: wallet.id, type: TransactionType.DEPOSIT, amount,
          status: TransactionStatus.COMPLETED, paymentMethod, externalTxId,
          balanceBefore: currentBalance, balanceAfter: currentBalance + amount,
          description: `Nạp tiền qua ${paymentMethod}`, completedAt: new Date(),
        },
      });
    });

    this.logger.log(`Top up completed: ${transactionCode} for user ${userId}`);
  }

  /** @deprecated Use deductPaymentAndCreateEscrow instead */
  async addEarnings(userId: string, amount: number, bookingId: string) {
    const wallet = await this.getOrCreateWallet(userId);
    const transactionCode = `EARN-${Date.now()}-${randomUUID().substring(0, 8).toUpperCase()}`;
    await this.prisma.$transaction(async (tx) => {
      const rows = await tx.$queryRawUnsafe<any[]>(
        `SELECT id, balance::numeric as balance FROM wallets WHERE id = $1 FOR UPDATE`, wallet.id,
      );
      const currentBalance = Number(rows[0]?.balance || 0);
      await tx.wallet.update({ where: { id: wallet.id }, data: { balance: { increment: amount }, totalEarnings: { increment: amount } } });
      await tx.transaction.create({ data: { transactionCode, walletId: wallet.id, bookingId, type: TransactionType.ESCROW_RELEASE, amount, status: TransactionStatus.COMPLETED, balanceBefore: currentBalance, balanceAfter: currentBalance + amount, description: `Thu nhập từ booking`, completedAt: new Date() } });
    });
  }

  /** @deprecated Use deductPaymentAndCreateEscrow instead */
  async deductPayment(userId: string, amount: number, bookingId: string) {
    const wallet = await this.getOrCreateWallet(userId);
    if (Number(wallet.balance) < amount) throw new BadRequestException('Số dư không đủ');
    const transactionCode = `PAY-${Date.now()}-${randomUUID().substring(0, 8).toUpperCase()}`;
    await this.prisma.$transaction(async (tx) => {
      const rows = await tx.$queryRawUnsafe<any[]>(
        `SELECT id, balance::numeric as balance FROM wallets WHERE id = $1 FOR UPDATE`, wallet.id,
      );
      const currentBalance = Number(rows[0]?.balance || 0);
      if (currentBalance < amount) throw new BadRequestException('Số dư không đủ');
      await tx.wallet.update({ where: { id: wallet.id }, data: { balance: { decrement: amount }, totalSpent: { increment: amount } } });
      await tx.transaction.create({ data: { transactionCode, walletId: wallet.id, bookingId, type: TransactionType.ESCROW_HOLD, amount, status: TransactionStatus.COMPLETED, balanceBefore: currentBalance, balanceAfter: currentBalance - amount, description: `Thanh toán booking`, completedAt: new Date() } });
    });
  }
}
