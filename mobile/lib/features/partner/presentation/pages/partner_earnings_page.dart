import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/partner_repository.dart'; // for PartnerEarningsData model
import '../bloc/partner_earnings_bloc.dart';
import '../bloc/partner_earnings_event.dart';
import '../bloc/partner_earnings_state.dart';

class PartnerEarningsPage extends StatelessWidget {
  const PartnerEarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PartnerEarningsBloc>()
        ..add(const PartnerEarningsLoadRequested()),
      child: const _PartnerEarningsContent(),
    );
  }
}

class _PartnerEarningsContent extends StatelessWidget {
  const _PartnerEarningsContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         title:   Text('Thống kê hoạt động', style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.theme.colorScheme.onSurface,
            ),),
      ),
      body: BlocConsumer<PartnerEarningsBloc, PartnerEarningsState>(
        listener: (context, state) {
          if (state is PartnerEarningsError) {
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

          if (state is PartnerEarningsLoaded) {
            earningsData = state.earningsData;
          } else if (state is PartnerEarningsWithdrawInProgress) {
            earningsData = state.earningsData;
          } else if (state is PartnerEarningsWithdrawSuccess) {
            earningsData = state.earningsData;
          }

          if (earningsData == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          final stats = earningsData.stats;

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
                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Ionicons.checkmark_done_outline,
                            label: 'Hoàn thành',
                            value: '${stats.completed}',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Ionicons.time_outline,
                            label: 'Đang chờ',
                            value: '${stats.pending}',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Ionicons.close_outline,
                            label: 'Đã hủy',
                            value: '${stats.cancelled}',
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
                            label: 'Tổng hoạt động',
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
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
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
        padding: ResponsiveLayout.pagePadding(context),
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

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
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
          style: AppTypography.bodyMedium.copyWith(
            color: valueColor ?? context.appColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
