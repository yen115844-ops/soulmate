import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../data/partner_repository.dart';

class BankAccountSettingsPage extends StatefulWidget {
  const BankAccountSettingsPage({super.key});

  @override
  State<BankAccountSettingsPage> createState() => _BankAccountSettingsPageState();
}

class _BankAccountSettingsPageState extends State<BankAccountSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _accountNameController = TextEditingController();

  late final PartnerRepository _partnerRepository;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Popular Vietnamese banks
  final List<String> _popularBanks = [
    'Vietcombank',
    'VietinBank',
    'BIDV',
    'Techcombank',
    'MB Bank',
    'ACB',
    'VPBank',
    'Sacombank',
    'TPBank',
    'HDBank',
    'VIB',
    'SHB',
    'MSB',
    'SeABank',
    'OCB',
    'LienVietPostBank',
    'Eximbank',
    'Nam A Bank',
    'Bac A Bank',
    'PVcomBank',
  ];

  @override
  void initState() {
    super.initState();
    _partnerRepository = getIt<PartnerRepository>();
    _loadBankInfo();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNoController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _loadBankInfo() async {
    try {
      final bankInfo = await _partnerRepository.getBankAccountInfo();
      if (bankInfo != null && mounted) {
        _bankNameController.text = bankInfo.bankName;
        _accountNoController.text = bankInfo.bankAccountNo;
        _accountNameController.text = bankInfo.bankAccountName;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải thông tin ngân hàng';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveBankInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _partnerRepository.updateBankInfo(
        bankName: _bankNameController.text.trim(),
        bankAccountNo: _accountNoController.text.trim(),
        bankAccountName: _accountNameController.text.trim().toUpperCase(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu thông tin ngân hàng'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể lưu thông tin. Vui lòng thử lại.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra. Vui lòng thử lại.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showBankPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Chọn ngân hàng',
                style: AppTypography.headlineSmall,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _popularBanks.length,
                itemBuilder: (context, index) {
                  final bank = _popularBanks[index];
                  final isSelected = _bankNameController.text == bank;
                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Ionicons.business_outline,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      bank,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Ionicons.checkmark_circle_outline, color: AppColors.primary)
                        : null,
                    onTap: () {
                      _bankNameController.text = bank;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Tài khoản ngân hàng'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Ionicons.information_circle_outline, color: AppColors.info),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Thông tin ngân hàng sẽ được sử dụng để nhận tiền rút về.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bank name field
                    Text(
                      'Tên ngân hàng',
                      style: AppTypography.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bankNameController,
                      readOnly: true,
                      onTap: _showBankPicker,
                      decoration: InputDecoration(
                        hintText: 'Chọn ngân hàng',
                        prefixIcon: const Icon(Ionicons.business_outline),
                        suffixIcon: const Icon(Ionicons.chevron_down_outline),
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn ngân hàng';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Account number field
                    Text(
                      'Số tài khoản',
                      style: AppTypography.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _accountNoController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(20),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Nhập số tài khoản',
                        prefixIcon: const Icon(Ionicons.card_outline),
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số tài khoản';
                        }
                        if (value.length < 8) {
                          return 'Số tài khoản phải có ít nhất 8 chữ số';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Account name field
                    Text(
                      'Tên chủ tài khoản',
                      style: AppTypography.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _accountNameController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return TextEditingValue(
                            text: newValue.text.toUpperCase(),
                            selection: newValue.selection,
                          );
                        }),
                      ],
                      decoration: InputDecoration(
                        hintText: 'VD: NGUYEN VAN A',
                        prefixIcon: const Icon(Ionicons.person_outline),
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên chủ tài khoản';
                        }
                        if (value.length < 3) {
                          return 'Tên phải có ít nhất 3 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tên phải trùng khớp với tên đăng ký trên ngân hàng',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Ionicons.alert_circle_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        onPressed: _isSaving ? null : _saveBankInfo,
                        text: _isSaving ? 'Đang lưu...' : 'Lưu thông tin',
                        icon: _isSaving ? null : Ionicons.checkmark_circle_outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
