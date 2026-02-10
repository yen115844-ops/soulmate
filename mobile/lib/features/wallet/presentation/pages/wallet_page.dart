import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../data/models/wallet_models.dart';
import '../bloc/wallet_bloc.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WalletBloc>()..add(const LoadWallet()),
      child: const _WalletPageContent(),
    );
  }
}

class _WalletPageContent extends StatelessWidget {
  const _WalletPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Ví của tôi'),
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state is WalletLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WalletError) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                context.read<WalletBloc>().add(const LoadWallet());
              },
            );
          }

          if (state is WalletLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<WalletBloc>().add(const LoadWallet(refresh: true));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    _BalanceCard(wallet: state.wallet),
                    const SizedBox(height: 8),
                    Text(
                      'Số dư dùng để thanh toán đặt lịch trên nền tảng.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Nạp tiền',
                            icon: Ionicons.add_outline,
                            onPressed: () =>
                                context.push(RouteNames.walletTopUp),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            text: 'Rút tiền',
                            icon: Ionicons.swap_horizontal_outline,
                            isOutlined: true,
                            onPressed: () =>
                                context.push(RouteNames.walletWithdraw),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Transaction History
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lịch sử giao dịch',
                          style: AppTypography.titleLarge,
                        ),
                        if (state.transactions.isNotEmpty)
                          TextButton(
                            onPressed: () =>
                                context.push(RouteNames.transactions),
                            child: Text(
                              'Xem tất cả',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Transaction List
                    if (state.transactions.isEmpty)
                      _EmptyTransactions()
                    else
                      _TransactionList(transactions: state.transactions),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final WalletModel wallet;

  const _BalanceCard({required this.wallet});

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số dư hiện tại',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textWhite.withAlpha(200),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.textWhite.withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Ionicons.shield_checkmark_outline,
                      color: AppColors.textWhite,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Đã xác thực',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_formatCurrency(wallet.balance)}đ',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _BalanceInfo(
                label: 'Đang giữ',
                value: '${_formatCurrency(wallet.pendingBalance)}đ',
                icon: Ionicons.lock_closed_outline,
              ),
              const SizedBox(width: 24),
              _BalanceInfo(
                label: 'Có thể rút',
                value: '${_formatCurrency(wallet.availableBalance)}đ',
                icon: Ionicons.swap_horizontal_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BalanceInfo({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textWhite.withAlpha(200),
          size: 18,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textWhite.withAlpha(180),
              ),
            ),
            Text(
              value,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;

  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Show only first 5 transactions
    final displayTransactions = transactions.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: displayTransactions.asMap().entries.map((entry) {
          final index = entry.key;
          final transaction = entry.value;
          return Column(
            children: [
              _TransactionItem(transaction: transaction),
              if (index < displayTransactions.length - 1)
                const Divider(height: 1, indent: 72),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionItem({required this.transaction});

  IconData get _icon {
    switch (transaction.type) {
      case TransactionType.deposit:
        return Ionicons.swap_horizontal_outline;
      case TransactionType.withdrawal:
        return Ionicons.swap_horizontal_outline;
      case TransactionType.escrowHold:
        return Ionicons.lock_closed_outline;
      case TransactionType.escrowRelease:
        return Ionicons.lock_open_outline;
      case TransactionType.escrowRefund:
        return Ionicons.refresh_outline;
      case TransactionType.serviceFee:
        return Ionicons.document_text_outline;
    }
  }

  Color get _iconColor {
    if (transaction.type.isPositive) {
      return AppColors.success;
    }
    return AppColors.error;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _iconColor.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_icon, color: _iconColor),
      ),
      title: Text(
        transaction.description ?? transaction.type.displayName,
        style: AppTypography.titleSmall,
      ),
      subtitle: Text(
        _formatDate(transaction.createdAt),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textHint,
        ),
      ),
      trailing: Text(
        transaction.displayAmount,
        style: AppTypography.titleMedium.copyWith(
          color: transaction.type.isPositive ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Ionicons.document_text_outline,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có giao dịch nào',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Ionicons.alert_circle_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
