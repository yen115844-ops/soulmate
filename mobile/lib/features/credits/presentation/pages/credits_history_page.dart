import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../data/credits_repository.dart';
import '../../data/models/credits_models.dart';
import '../bloc/credits_bloc.dart';
import '../bloc/credits_event.dart';
import '../bloc/credits_state.dart';

class CreditsHistoryPage extends StatefulWidget {
  const CreditsHistoryPage({super.key});

  @override
  State<CreditsHistoryPage> createState() => _CreditsHistoryPageState();
}

class _CreditsHistoryPageState extends State<CreditsHistoryPage> {
  late final CreditsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = CreditsBloc(repository: getIt<CreditsRepository>());
    _bloc.add(const LoadTransactions());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: context.appColors.background,
        appBar: AppBar(
          leadingWidth: 56,
          leading: const AppBackButton(),
          title: Text(
            'Lịch sử giao dịch',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<CreditsBloc, CreditsState>(
          builder: (context, state) {
            if (state is CreditsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TransactionsLoaded) {
              return _buildTransactionsList(context, state.transactions);
            }

            if (state is CreditsError) {
              print('CreditsError: ${state.message}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Ionicons.warning_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    AppButton(
                      text: 'Thử lại',
                      onPressed: () => _bloc.add(const LoadTransactions()),
                      isOutlined: true,
                    ),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, List<CreditTransaction> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.receipt_outline,
              size: 64,
              color: context.appColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có giao dịch nào',
              style: AppTypography.bodyLarge.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _buildTransactionItem(context, transactions[index]);
      },
    );
  }

  Widget _buildTransactionItem(BuildContext context, CreditTransaction tx) {
    final isIncome = tx.isIncome;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Ionicons.arrow_down : Ionicons.arrow_up,
              color: isIncome ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.typeText,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(tx.createdAt),
                  style: AppTypography.bodySmall.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
                if (tx.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    tx.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${tx.amount}',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isIncome ? AppColors.success : AppColors.error,
                ),
              ),
              Text(
                'credits',
                style: AppTypography.bodySmall.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
