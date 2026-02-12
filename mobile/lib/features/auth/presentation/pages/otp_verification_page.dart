import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phone;
  final String? email;
  final bool isRegister;

  const OtpVerificationPage({
    super.key,
    required this.phone,
    this.email,
    this.isRegister = false,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  String _otp = '';
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _resendOtp() {
    if (_resendCountdown == 0 && widget.email != null) {
      context.read<AuthBloc>().add(
        AuthResendOtpRequested(email: widget.email!),
      );
      _startCountdown();
    }
  }

  void _verifyOtp() {
    if (_otp.length == 6 && widget.email != null) {
      context.read<AuthBloc>().add(
        AuthVerifyOtpRequested(email: widget.email!, otp: _otp),
      );
    }
  }

  void _onOtpChanged(String otp) {
    setState(() => _otp = otp);
  }

  void _onOtpCompleted(String otp) {
    _otp = otp;
    _verifyOtp();
  }

  String get _maskedPhone {
    if (widget.phone.length >= 10) {
      return '${widget.phone.substring(0, 3)}****${widget.phone.substring(7)}';
    }
    return widget.phone;
  }

  String get _maskedEmail {
    if (widget.email == null || widget.email!.isEmpty) return '';
    final e = widget.email!;
    final at = e.indexOf('@');
    if (at <= 2) return e;
    return '${e.substring(0, 2)}***${e.substring(at)}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpVerified || state is AuthAuthenticated) {
          context.go(RouteNames.home);
        } else if (state is AuthOtpResent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthOtpVerifying;

        return Scaffold(
          appBar: AppBar(leading: const AppBackButton()),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Ionicons.mail_outline,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text('Xác thực OTP', style: AppTypography.headlineLarge),

                  const SizedBox(height: 8),

                  // Description - show email when verifying email (register), else phone
                  RichText(
                    text: TextSpan(
                      style: AppTypography.bodyLarge.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'Nhập mã 6 số đã gửi đến\n'),
                        TextSpan(
                          text: widget.email != null && widget.email!.isNotEmpty
                              ? _maskedEmail
                              : _maskedPhone,
                          style: AppTypography.bodyLarge.copyWith(
                            color: context.appColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // OTP Input
                  OtpTextField(
                    length: 6,
                    onChanged: _onOtpChanged,
                    onCompleted: _onOtpCompleted,
                  ),

                  const SizedBox(height: 24),

                  // Resend OTP
                  Center(
                    child: _resendCountdown > 0
                        ? RichText(
                            text: TextSpan(
                              style: AppTypography.bodyMedium.copyWith(
                                color: context.appColors.textSecondary,
                              ),
                              children: [
                                const TextSpan(text: 'Gửi lại mã sau '),
                                TextSpan(
                                  text: '${_resendCountdown}s',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : TextButton(
                            onPressed: _resendOtp,
                            child: Text(
                              'Gửi lại mã OTP',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),

                  const Spacer(),

                  // Verify Button
                  AppButton(
                    text: 'Xác nhận',
                    onPressed: _otp.length == 6 ? _verifyOtp : null,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 16),

                  // Change phone/email
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        widget.email != null ? 'Đổi email' : 'Đổi số điện thoại',
                        style: AppTypography.labelLarge.copyWith(
                          color: context.appColors.textSecondary,
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
