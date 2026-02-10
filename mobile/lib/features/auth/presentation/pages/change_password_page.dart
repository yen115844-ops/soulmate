import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../bloc/change_password_bloc.dart';
import '../bloc/change_password_event.dart';
import '../bloc/change_password_state.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ChangePasswordBloc>(),
      child: const _ChangePasswordContent(),
    );
  }
}

class _ChangePasswordContent extends StatefulWidget {
  const _ChangePasswordContent();

  @override
  State<_ChangePasswordContent> createState() => _ChangePasswordContentState();
}

class _ChangePasswordContentState extends State<_ChangePasswordContent> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu hiện tại';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới';
    }
    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ hoa';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ thường';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Mật khẩu phải có ít nhất 1 số';
    }
    if (value == _currentPasswordController.text) {
      return 'Mật khẩu mới không được trùng với mật khẩu cũ';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != _newPasswordController.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  void _changePassword() {
    if (!_formKey.currentState!.validate()) return;

    context.read<ChangePasswordBloc>().add(
      ChangePasswordSubmitted(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Ionicons.checkmark_circle_outline,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Đổi mật khẩu thành công!',
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Mật khẩu của bạn đã được cập nhật. Hãy sử dụng mật khẩu mới cho lần đăng nhập tiếp theo.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Hoàn tất',
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
      listener: (context, state) {
        if (state.status == ChangePasswordStatus.success) {
          _showSuccessDialog();
        } else if (state.status == ChangePasswordStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Đổi mật khẩu thất bại'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == ChangePasswordStatus.loading;

        return Scaffold(
          appBar: AppBar(leading: const AppBackButton(), title: const Text('Đổi mật khẩu')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.info.withAlpha(50)),
                    ),
                    child: Row(
                      children: [
                        Icon(Ionicons.information_circle_outline, color: AppColors.info),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mật khẩu mới cần có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường và số.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Current Password
                  AppTextField(
                    controller: _currentPasswordController,
                    label: 'Mật khẩu hiện tại',
                    hint: 'Nhập mật khẩu hiện tại',
                    obscureText: _obscureCurrentPassword,
                    prefixIcon: Ionicons.lock_closed_outline,
                    suffix: IconButton(
                      onPressed: () => setState(
                        () =>
                            _obscureCurrentPassword = !_obscureCurrentPassword,
                      ),
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Ionicons.eye_off_outline
                            : Ionicons.eye_outline,
                        color: AppColors.textHint,
                      ),
                    ),
                    validator: _validateCurrentPassword,
                  ),

                  const SizedBox(height: 20),

                  // New Password
                  AppTextField(
                    controller: _newPasswordController,
                    label: 'Mật khẩu mới',
                    hint: 'Nhập mật khẩu mới',
                    obscureText: _obscureNewPassword,
                    prefixIcon: Ionicons.lock_closed_outline,
                    suffix: IconButton(
                      onPressed: () => setState(
                        () => _obscureNewPassword = !_obscureNewPassword,
                      ),
                      icon: Icon(
                        _obscureNewPassword ? Ionicons.eye_off_outline : Ionicons.eye_outline,
                        color: AppColors.textHint,
                      ),
                    ),
                    validator: _validateNewPassword,
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 12),

                  // Password Strength Indicator
                  _PasswordStrengthIndicator(
                    password: _newPasswordController.text,
                  ),

                  const SizedBox(height: 20),

                  // Confirm Password
                  AppTextField(
                    controller: _confirmPasswordController,
                    label: 'Xác nhận mật khẩu mới',
                    hint: 'Nhập lại mật khẩu mới',
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: Ionicons.lock_closed_outline,
                    suffix: IconButton(
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Ionicons.eye_off_outline
                            : Ionicons.eye_outline,
                        color: AppColors.textHint,
                      ),
                    ),
                    validator: _validateConfirmPassword,
                  ),

                  const SizedBox(height: 40),

                  // Submit Button
                  AppButton(
                    text: 'Đổi mật khẩu',
                    onPressed: isLoading ? null : _changePassword,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 16),

                  // Forgot Password Link
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to forgot password
                      },
                      child: Text(
                        'Quên mật khẩu?',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  int _calculateStrength() {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength;
  }

  String _getStrengthText(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Yếu';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Khá';
      case 4:
      case 5:
        return 'Mạnh';
      default:
        return '';
    }
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.info;
      case 4:
      case 5:
        return AppColors.success;
      default:
        return AppColors.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = _calculateStrength();
    final color = _getStrengthColor(strength);
    final text = _getStrengthText(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (index) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: index < strength ? color : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Độ mạnh mật khẩu:',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
            Text(
              text,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Requirements checklist
        _RequirementItem(text: 'Ít nhất 8 ký tự', isMet: password.length >= 8),
        _RequirementItem(
          text: 'Có chữ hoa (A-Z)',
          isMet: password.contains(RegExp(r'[A-Z]')),
        ),
        _RequirementItem(
          text: 'Có chữ thường (a-z)',
          isMet: password.contains(RegExp(r'[a-z]')),
        ),
        _RequirementItem(
          text: 'Có số (0-9)',
          isMet: password.contains(RegExp(r'[0-9]')),
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String text;
  final bool isMet;

  const _RequirementItem({required this.text, required this.isMet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Ionicons.checkmark_circle_outline : Ionicons.close_circle_outline,
            size: 16,
            color: isMet ? AppColors.success : AppColors.textHint,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: isMet ? AppColors.success : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
