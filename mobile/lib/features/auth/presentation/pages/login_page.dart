import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthNeedsProfileSetup) {
          // User is active - navigate to home
          context.go(RouteNames.home);
        } else if (state is AuthPendingVerification) {
          // Show pending message but allow access
          _showInfo(
            'Tài khoản đang chờ xác minh. Một số tính năng có thể bị giới hạn.',
          );
          context.go(RouteNames.home);
        } else if (state is AuthSuspended) {
          _showError(
            'Tài khoản của bạn đã bị tạm khóa. Vui lòng liên hệ hỗ trợ.',
          );
        } else if (state is AuthBanned) {
          _showError('Tài khoản của bạn đã bị cấm vĩnh viễn.');
        } else if (state is AuthError) {
          _showError(state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Welcome Text
                    Row(
                      children: [
                        Icon(Icons.waving_hand, size: 28, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Chào mừng trở lại!',
                          style: AppTypography.headlineLarge,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Đăng nhập để tiếp tục kết nối',
                      style: AppTypography.bodyLarge.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Email Field
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Nhập địa chỉ email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Ionicons.mail_outline,
                      textInputAction: TextInputAction.next,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Password Field
                    AppTextField(
                      controller: _passwordController,
                      label: 'Mật khẩu',
                      hint: 'Nhập mật khẩu',
                      obscureText: true,
                      prefixIcon: Ionicons.lock_closed_outline,
                      textInputAction: TextInputAction.done,
                      enabled: !isLoading,
                      onFieldSubmitted: (_) => _login(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < AppConstants.minPasswordLength) {
                          return 'Mật khẩu phải có ít nhất ${AppConstants.minPasswordLength} ký tự';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.push(RouteNames.forgotPassword),
                        child: Text(
                          'Quên mật khẩu?',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Button
                    AppButton(
                      text: 'Đăng nhập',
                      onPressed: isLoading ? null : () => _login(context),
                      isLoading: isLoading,
                    ),

                    const SizedBox(height: 32),

                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'hoặc',
                            style: AppTypography.bodySmall.copyWith(
                              color: context.appColors.textHint,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Social Login Buttons
                    _SocialLoginButton(
                      icon: 'google',
                      text: 'Tiếp tục với Google',
                      onPressed: isLoading
                          ? null
                          : () {
                              // TODO: Google login
                            },
                    ),

                    const SizedBox(height: 12),

                    _SocialLoginButton(
                      icon: 'facebook',
                      text: 'Tiếp tục với Facebook',
                      backgroundColor: AppColors.facebook,
                      textColor: Colors.white,
                      onPressed: isLoading
                          ? null
                          : () {
                              // TODO: Facebook login
                            },
                    ),

                    const SizedBox(height: 40),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Chưa có tài khoản? ',
                          style: AppTypography.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () => context.push(RouteNames.register),
                          child: Text(
                            'Đăng ký ngay',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final String icon;
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const _SocialLoginButton({
    required this.icon,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? context.appColors.surface;
    final fg = textColor ?? context.appColors.textPrimary;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: backgroundColor == null
              ? BorderSide(color: context.appColors.border)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using Icon instead of image for now
            Icon(
              icon.contains('google') ? Ionicons.logo_google : Ionicons.logo_facebook,
              size: 24,
              color: fg,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                style: AppTypography.labelLarge.copyWith(color: fg),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
