import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../data/auth_repository.dart';

class ResetPasswordPage extends StatefulWidget {
  /// Email from forgot-password step (from extra or query)
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final repo = getIt<AuthRepository>();
      await repo.resetPassword(
        email: widget.email,
        otp: _otpController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _showSuccessAndGoLogin();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xảy ra lỗi. Vui lòng thử lại.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSuccessAndGoLogin() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Ionicons.checkmark_circle_outline, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            Text('Đặt lại mật khẩu thành công!', style: AppTypography.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Bạn có thể đăng nhập bằng mật khẩu mới.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Đăng nhập',
              onPressed: () {
                Navigator.pop(ctx);
                context.go(RouteNames.login);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Đặt lại mật khẩu')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhập mã xác nhận đã gửi đến ${widget.email} và mật khẩu mới.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _otpController,
                  label: 'Mã xác nhận',
                  hint: 'Nhập mã 6 số',
                  keyboardType: TextInputType.number,
                  prefixIcon: Ionicons.key_outline,
                  maxLength: 6,
                  enabled: !_isLoading,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập mã xác nhận';
                    if (v.length < 4) return 'Mã xác nhận không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _newPasswordController,
                  label: 'Mật khẩu mới',
                  hint: 'Ít nhất 8 ký tự, có chữ hoa, thường và số',
                  obscureText: _obscureNew,
                  prefixIcon: Ionicons.lock_closed_outline,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    icon: Icon(_obscureNew ? Ionicons.eye_off_outline : Ionicons.eye_outline, color: AppColors.textHint),
                  ),
                  enabled: !_isLoading,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                    if (v.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
                    if (!v.contains(RegExp(r'[A-Z]'))) return 'Cần ít nhất 1 chữ hoa';
                    if (!v.contains(RegExp(r'[a-z]'))) return 'Cần ít nhất 1 chữ thường';
                    if (!v.contains(RegExp(r'[0-9]'))) return 'Cần ít nhất 1 số';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Xác nhận mật khẩu',
                  hint: 'Nhập lại mật khẩu mới',
                  obscureText: _obscureConfirm,
                  prefixIcon: Ionicons.lock_closed_outline,
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(_obscureConfirm ? Ionicons.eye_off_outline : Ionicons.eye_outline, color: AppColors.textHint),
                  ),
                  enabled: !_isLoading,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                    if (v != _newPasswordController.text) return 'Mật khẩu không khớp';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: 'Đặt lại mật khẩu',
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
