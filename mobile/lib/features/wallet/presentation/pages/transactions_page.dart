import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _transactions = const [
    {
      'title': 'Nạp tiền',
      'amount': '+500.000đ',
      'date': '08/01/2026 - 10:30',
      'type': 'deposit',
      'status': 'success',
    },
    {
      'title': 'Thanh toán đặt lịch',
      'amount': '-1.500.000đ',
      'date': '05/01/2026 - 14:20',
      'type': 'payment',
      'status': 'success',
    },
    {
      'title': 'Hoàn tiền',
      'amount': '+350.000đ',
      'date': '03/01/2026 - 09:15',
      'type': 'refund',
      'status': 'success',
    },
    {
      'title': 'Nạp tiền',
      'amount': '+1.000.000đ',
      'date': '01/01/2026 - 18:45',
      'type': 'deposit',
      'status': 'success',
    },
    {
      'title': 'Rút tiền',
      'amount': '-500.000đ',
      'date': '28/12/2025 - 11:00',
      'type': 'withdraw',
      'status': 'success',
    },
    {
      'title': 'Thanh toán đặt lịch',
      'amount': '-1.200.000đ',
      'date': '25/12/2025 - 16:30',
      'type': 'payment',
      'status': 'success',
    },
    {
      'title': 'Nạp tiền',
      'amount': '+2.000.000đ',
      'date': '20/12/2025 - 09:00',
      'type': 'deposit',
      'status': 'success',
    },
  ];

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == 'all') return _transactions;
    return _transactions.where((t) => t['type'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Lịch sử giao dịch'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  isSelected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Nạp tiền',
                  isSelected: _selectedFilter == 'deposit',
                  onTap: () => setState(() => _selectedFilter = 'deposit'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Thanh toán',
                  isSelected: _selectedFilter == 'payment',
                  onTap: () => setState(() => _selectedFilter = 'payment'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Rút tiền',
                  isSelected: _selectedFilter == 'withdraw',
                  onTap: () => setState(() => _selectedFilter = 'withdraw'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Hoàn tiền',
                  isSelected: _selectedFilter == 'refund',
                  onTap: () => setState(() => _selectedFilter = 'refund'),
                ),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: _filteredTransactions.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTransactions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];
                      return _TransactionItem(
                        title: transaction['title'],
                        amount: transaction['amount'],
                        date: transaction['date'],
                        type: transaction['type'],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title;
  final String amount;
  final String date;
  final String type;

  const _TransactionItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
  });

  IconData get _icon {
    switch (type) {
      case 'deposit':
        return Ionicons.swap_horizontal_outline;
      case 'payment':
        return Ionicons.swap_horizontal_outline;
      case 'refund':
        return Ionicons.refresh_outline;
      case 'withdraw':
        return Ionicons.arrow_up_outline;
      default:
        return Ionicons.cash_outline;
    }
  }

  Color get _iconColor {
    switch (type) {
      case 'deposit':
      case 'refund':
        return AppColors.success;
      case 'payment':
      case 'withdraw':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  bool get _isPositive => amount.startsWith('+');

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _iconColor.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_icon, color: _iconColor),
      ),
      title: Text(title, style: AppTypography.titleSmall),
      subtitle: Text(
        date,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textHint,
        ),
      ),
      trailing: Text(
        amount,
        style: AppTypography.titleMedium.copyWith(
          color: _isPositive ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Ionicons.document_text_outline,
              size: 48,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Không có giao dịch',
            style: AppTypography.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có giao dịch nào trong danh mục này',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
