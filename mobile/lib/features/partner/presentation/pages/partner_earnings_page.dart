import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../data/partner_repository.dart';
import '../bloc/partner_earnings_bloc.dart';
import '../bloc/partner_earnings_event.dart';
import '../bloc/partner_earnings_state.dart';

class PartnerEarningsPage extends StatelessWidget {
  const PartnerEarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PartnerEarningsBloc(
        partnerRepository: getIt<PartnerRepository>(),
      )..add(const PartnerEarningsLoadRequested()),
      child: const _PartnerEarningsContent(),
    );
  }
}

class _PartnerEarningsContent extends StatelessWidget {
  const _PartnerEarningsContent();

  String _formatCurrency(double amount) {
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatFullCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         title: const Text('Thu nhập'),
      ),
      body: BlocConsumer<PartnerEarningsBloc, PartnerEarningsState>(
        listener: (context, state) {
          if (state is PartnerEarningsWithdrawSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is PartnerEarningsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PartnerEarningsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PartnerEarningsError) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                context.read<PartnerEarningsBloc>().add(
                      const PartnerEarningsLoadRequested(),
                    );
              },
            );
          }

          PartnerEarningsData? earningsData;
          bool isWithdrawing = false;

          if (state is PartnerEarningsLoaded) {
            earningsData = state.earningsData;
          } else if (state is PartnerEarningsWithdrawInProgress) {
            earningsData = state.earningsData;
            isWithdrawing = true;
          } else if (state is PartnerEarningsWithdrawSuccess) {
            earningsData = state.earningsData;
          }

          if (earningsData == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          final stats = earningsData.stats;
          final wallet = earningsData.wallet;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<PartnerEarningsBloc>().add(
                    const PartnerEarningsRefreshRequested(),
                  );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Card
                  _BalanceCard(
                    availableBalance: wallet.balance,
                    totalEarned: stats.totalEarned,
                    isWithdrawing: isWithdrawing,
                    onWithdraw: () => _showWithdrawDialog(context, wallet),
                  ),

                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Ionicons.swap_horizontal_outline,
                            label: 'Tổng thu',
                            value: '${_formatCurrency(stats.totalEarned)}đ',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Ionicons.calendar_outline,
                            label: 'Đơn hoàn thành',
                            value: '${stats.completed}',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Ionicons.timer_outline,
                            label: 'Đang chờ',
                            value: '${stats.pending}',
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Summary Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.appColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.appColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng quan',
                            style: AppTypography.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          _SummaryRow(
                            label: 'Tổng đơn hàng',
                            value: '${stats.total}',
                          ),
                          const Divider(height: 24),
                          _SummaryRow(
                            label: 'Hoàn thành',
                            value: '${stats.completed}',
                            valueColor: AppColors.success,
                          ),
                          const Divider(height: 24),
                          _SummaryRow(
                            label: 'Đã hủy',
                            value: '${stats.cancelled}',
                            valueColor: AppColors.error,
                          ),
                          const Divider(height: 24),
                          _SummaryRow(
                            label: 'Tổng thu nhập',
                            value: '${_formatFullCurrency(stats.totalEarned)}đ',
                            valueColor: AppColors.primary,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bank Account Section
                  if (wallet.bankName != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tài khoản ngân hàng',
                            style: AppTypography.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.appColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.appColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Ionicons.business_outline, color: AppColors.primary),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        wallet.bankName!,
                                        style: AppTypography.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_maskAccountNumber(wallet.bankAccountNo)} - ${wallet.bankAccountName ?? ""}',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: context.appColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Ionicons.checkmark_circle_outline, color: AppColors.success),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _maskAccountNumber(String? accountNo) {
    if (accountNo == null || accountNo.length < 4) return '****';
    return '****${accountNo.substring(accountNo.length - 4)}';
  }

  void _showWithdrawDialog(BuildContext context, PartnerWalletInfo wallet) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => Container(
        decoration:   BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rút tiền',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Số dư khả dụng: ${_formatFullCurrency(wallet.balance)}đ',
              style: AppTypography.bodyMedium.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền rút',
                hintText: 'Nhập số tiền',
                prefixIcon: const Icon(Ionicons.cash_outline),
                suffixText: 'đ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Quick Amount Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [500000.0, 1000000.0, 2000000.0].map((amount) {
                return GestureDetector(
                  onTap: () => amountController.text = amount.toStringAsFixed(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: context.appColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.appColors.border),
                    ),
                    child: Text(
                      '${_formatCurrency(amount)}đ',
                      style: AppTypography.labelMedium,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                hintText: 'Ghi chú cho yêu cầu rút tiền',
                prefixIcon: const Icon(Ionicons.document_text_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Bank Account Info
            if (wallet.bankName != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.appColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.appColors.card,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:   Icon(Ionicons.business_outline, color: context.appColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(wallet.bankName!, style: AppTypography.bodyMedium),
                          Text(
                            '${_maskAccountNumber(wallet.bankAccountNo)} - ${wallet.bankAccountName ?? ""}',
                            style: AppTypography.labelSmall.copyWith(
                              color: context.appColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Ionicons.checkmark_circle_outline, color: AppColors.success),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Xác nhận rút tiền',
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập số tiền hợp lệ'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                if (amount > wallet.balance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Số tiền vượt quá số dư khả dụng'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                context.read<PartnerEarningsBloc>().add(
                      PartnerEarningsWithdrawRequested(
                        amount: amount,
                        note: noteController.text.isNotEmpty
                            ? noteController.text
                            : null,
                      ),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Icon(Ionicons.alert_circle_outline, size: 64, color: context.appColors.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Ionicons.refresh_outline),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double availableBalance;
  final double totalEarned;
  final bool isWithdrawing;
  final VoidCallback onWithdraw;

  const _BalanceCard({
    required this.availableBalance,
    required this.totalEarned,
    this.isWithdrawing = false,
    required this.onWithdraw,
  });

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số dư khả dụng',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textWhite.withAlpha(200),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatCurrency(availableBalance)}đ',
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isWithdrawing ? null : onWithdraw,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appColors.surface,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: isWithdrawing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Ionicons.swap_horizontal_outline),
                  label: Text(isWithdrawing ? 'Đang xử lý...' : 'Rút tiền'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(RouteNames.transactions);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textWhite,
                    side: BorderSide(color: AppColors.textWhite.withAlpha(100)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Ionicons.document_text_outline),
                  label: const Text('Lịch sử'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: context.appColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: (isBold ? AppTypography.titleMedium : AppTypography.bodyMedium).copyWith(
            color: valueColor ?? context.appColors.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
