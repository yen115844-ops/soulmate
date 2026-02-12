import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../data/wallet_repository.dart';
import '../bloc/wallet_bloc.dart';

class WalletTopUpPage extends StatefulWidget {
  const WalletTopUpPage({super.key});

  @override
  State<WalletTopUpPage> createState() => _WalletTopUpPageState();
}

class _WalletTopUpPageState extends State<WalletTopUpPage> {
  int? _selectedAmount;
  String? _selectedPaymentMethod;
  bool _isProcessing = false;

  final List<int> _amounts = [
    100000,
    200000,
    500000,
    1000000,
    2000000,
    5000000,
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'vnpay', 'name': 'VNPay', 'icon': Ionicons.card_outline},
    {'id': 'momo', 'name': 'MoMo', 'icon': Ionicons.wallet_outline},
    {'id': 'zalopay', 'name': 'ZaloPay', 'icon': Ionicons.cash_outline},
    {'id': 'bank', 'name': 'Chuyển khoản ngân hàng', 'icon': Ionicons.business_outline},
  ];

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(0)}tr';
    }
    return '${(amount / 1000).toStringAsFixed(0)}k';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WalletBloc(repository: getIt<WalletRepository>()),
      child: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is TopUpLoading) {
            setState(() => _isProcessing = true);
          } else if (state is TopUpSuccess) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message.isNotEmpty
                      ? state.message
                      : 'Nạp tiền thành công!',
                ),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop(true); // Return success to refresh wallet
          } else if (state is TopUpError) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(),
              title: const Text('Nạp tiền'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Selection
                  Text('Chọn số tiền', style: AppTypography.titleLarge),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _amounts.map((amount) {
                      final isSelected = _selectedAmount == amount;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAmount = amount),
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 64) / 3,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : context.appColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : context.appColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _formatAmount(amount),
                              style: AppTypography.titleMedium.copyWith(
                                color: isSelected
                                    ? AppColors.textWhite
                                    : context.appColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Payment Method Selection
                  Text(
                    'Phương thức thanh toán',
                    style: AppTypography.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: context.appColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.appColors.border),
                    ),
                    child: Column(
                      children: _paymentMethods.asMap().entries.map((entry) {
                        final index = entry.key;
                        final method = entry.value;
                        final isSelected =
                            _selectedPaymentMethod == method['id'];
                        return Column(
                          children: [
                            ListTile(
                              onTap: () => setState(
                                () => _selectedPaymentMethod = method['id'],
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: context.appColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  method['icon'],
                                  color: AppColors.primary,
                                ),
                              ),
                              title: Text(
                                method['name'],
                                style: AppTypography.titleSmall,
                              ),
                              trailing: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : context.appColors.border,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            if (index < _paymentMethods.length - 1)
                              const Divider(height: 1, indent: 72),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Summary
                  if (_selectedAmount != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.appColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Số tiền nạp',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: context.appColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${_selectedAmount!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                                style: AppTypography.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Phí giao dịch',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: context.appColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Miễn phí',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tổng thanh toán',
                                style: AppTypography.titleMedium,
                              ),
                              Text(
                                '${_selectedAmount!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                                style: AppTypography.titleLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AppButton(
                  text: _isProcessing ? 'Đang xử lý...' : 'Tiếp tục',
                  isLoading: _isProcessing,
                  onPressed:
                      (_selectedAmount != null &&
                          _selectedPaymentMethod != null &&
                          !_isProcessing)
                      ? () {
                          context.read<WalletBloc>().add(
                            RequestTopUp(
                              amount: _selectedAmount!.toDouble(),
                              paymentMethod: _selectedPaymentMethod!,
                            ),
                          );
                        }
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
