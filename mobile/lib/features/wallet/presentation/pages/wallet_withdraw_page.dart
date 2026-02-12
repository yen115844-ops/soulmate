import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../data/wallet_repository.dart';
import '../bloc/wallet_bloc.dart';

class WalletWithdrawPage extends StatefulWidget {
  const WalletWithdrawPage({super.key});

  @override
  State<WalletWithdrawPage> createState() => _WalletWithdrawPageState();
}

class _WalletWithdrawPageState extends State<WalletWithdrawPage> {
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  bool _isProcessing = false;

  final int _availableBalance = 2000000;

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          WalletBloc(repository: getIt<WalletRepository>())
            ..add(const LoadWallet()),
      child: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is WithdrawLoading) {
            setState(() => _isProcessing = true);
          } else if (state is WithdrawSuccess) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message.isNotEmpty
                      ? state.message
                      : 'Yêu cầu rút tiền thành công!',
                ),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop(true); // Return success to refresh wallet
          } else if (state is WithdrawError) {
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
          // Get balance from state if loaded
          final availableBalance = state is WalletLoaded
              ? state.wallet.balance.toInt()
              : _availableBalance;

          return Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(),
              title: const Text('Rút tiền'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Available Balance
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(50),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Ionicons.wallet_outline,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Số dư có thể rút',
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${availableBalance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Amount Input
                  Text('Số tiền muốn rút', style: AppTypography.titleMedium),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _amountController,
                    hint: 'Nhập số tiền',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    suffix: Text(
                      'đ',
                      style: AppTypography.titleMedium.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Số tiền tối thiểu: 100.000đ',
                    style: AppTypography.labelSmall.copyWith(
                      color: context.appColors.textHint,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bank Information
                  Text('Thông tin ngân hàng', style: AppTypography.titleLarge),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _bankNameController,
                    label: 'Tên ngân hàng',
                    hint: 'VD: Vietcombank',
                    prefixIcon: Ionicons.business_outline,
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _accountNumberController,
                    label: 'Số tài khoản',
                    hint: 'Nhập số tài khoản',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    prefixIcon: Ionicons.card_outline,
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _accountNameController,
                    label: 'Tên chủ tài khoản',
                    hint: 'Nhập tên chủ tài khoản',
                    prefixIcon: Ionicons.person_outline,
                  ),

                  const SizedBox(height: 24),

                  // Note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withAlpha(50),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Ionicons.information_circle_outline,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lưu ý',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Thời gian xử lý: 1-3 ngày làm việc\n• Phí rút tiền: 0đ (miễn phí)\n• Vui lòng kiểm tra kỹ thông tin ngân hàng',
                                style: AppTypography.bodySmall.copyWith(
                                  color: context.appColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AppButton(
                  text: _isProcessing ? 'Đang xử lý...' : 'Yêu cầu rút tiền',
                  isLoading: _isProcessing,
                  onPressed: _isProcessing
                      ? null
                      : () {
                          final amount =
                              double.tryParse(_amountController.text) ?? 0;
                          final bankName = _bankNameController.text.trim();
                          final accountNumber = _accountNumberController.text
                              .trim();
                          final accountName = _accountNameController.text
                              .trim();

                          // Validate inputs
                          if (amount < 100000) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Số tiền tối thiểu là 100.000đ'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          if (amount > availableBalance) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Số tiền vượt quá số dư khả dụng',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          if (bankName.isEmpty ||
                              accountNumber.isEmpty ||
                              accountName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Vui lòng nhập đầy đủ thông tin ngân hàng',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          // Dispatch withdraw event
                          context.read<WalletBloc>().add(
                            RequestWithdraw(
                              amount: amount,
                              bankName: bankName,
                              bankAccountNo: accountNumber,
                              bankAccountName: accountName,
                            ),
                          );
                        },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
