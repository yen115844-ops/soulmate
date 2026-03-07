import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../domain/entities/verification_entity.dart';
import '../bloc/verification_bloc.dart';
import '../bloc/verification_event.dart';
import '../bloc/verification_state.dart';

/// Soft Verification Page - Selfie + Liveness check only
/// No personal ID documents required for privacy compliance
class SoftVerificationPage extends StatelessWidget {
  const SoftVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<VerificationBloc>()..add(const VerificationStatusRequested()),
      child: const _SoftVerificationPageContent(),
    );
  }
}

class _SoftVerificationPageContent extends StatefulWidget {
  const _SoftVerificationPageContent();

  @override
  State<_SoftVerificationPageContent> createState() =>
      _SoftVerificationPageContentState();
}

class _SoftVerificationPageContentState
    extends State<_SoftVerificationPageContent> {
  final ImagePicker _picker = ImagePicker();
  File? _selfieImage;
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerificationBloc, VerificationState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.error,
            ),
          );
        }

        if (state.status == VerificationStateStatus.submitted) {
          _showSuccessDialog(context, state);
        }
      },
      builder: (context, state) {
        if (state.status == VerificationStateStatus.loading &&
            state.verification == null) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Already has verification status
        final verification = state.verification;
        if (verification != null && verification.status != VerificationStatus.none) {
          return _buildStatusPage(context, verification);
        }

        // Show verification wizard
        return _buildVerificationWizard(context, state);
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      leading: const AppBackButton(),
      title: const Text('Xác thực danh tính'),
    );
  }

  Widget _buildStatusPage(BuildContext context, VerificationEntity entity) {
    final status = entity.status;
    final isApproved = status == VerificationStatus.verified;
    final isPending = status == VerificationStatus.pending;
    final isRejected = status == VerificationStatus.rejected;

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding: ResponsiveLayout.pagePadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isApproved
                      ? AppColors.success.withOpacity(0.1)
                      : isPending
                          ? AppColors.warning.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isApproved
                      ? Ionicons.checkmark_circle
                      : isPending
                          ? Ionicons.time
                          : Ionicons.close_circle,
                  size: 64,
                  color: isApproved
                      ? AppColors.success
                      : isPending
                          ? AppColors.warning
                          : AppColors.error,
                ),
              ),
              const SizedBox(height: 32),

              // Status text
              Text(
                isApproved
                    ? 'Đã xác thực'
                    : isPending
                        ? 'Đang chờ duyệt'
                        : 'Không được chấp nhận',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isApproved
                      ? AppColors.success
                      : isPending
                          ? AppColors.warning
                          : AppColors.error,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                isApproved
                    ? 'Tài khoản của bạn đã được xác thực. Bạn sẽ có huy hiệu tick xanh trên hồ sơ.'
                    : isPending
                        ? 'Yêu cầu xác thực của bạn đang được xem xét. Thông thường mất khoảng 24-48 giờ.'
                        : 'Yêu cầu xác thực không được chấp nhận. ${entity.rejectionReason ?? "Vui lòng thử lại."}',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Verified badge preview (if approved)
              if (isApproved) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.verified.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.verified.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Ionicons.checkmark_circle,
                        color: AppColors.verified,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đã xác thực',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.verified,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Retry button (if rejected)
              if (isRejected) ...[
                const SizedBox(height: 24),
                AppButton(
                  text: 'Thử lại',
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                      _selfieImage = null;
                    });
                    context.read<VerificationBloc>().add(
                      const VerificationReset(),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationWizard(BuildContext context, VerificationState state) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),

            // Content
            Expanded(
              child: _currentStep == 0
                  ? _buildIntroStep()
                  : _currentStep == 1
                      ? _buildSelfieStep(state)
                      : _buildConfirmStep(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: ResponsiveLayout.pagePadding(context),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : context.appColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIntroStep() {
    return SingleChildScrollView(
      padding: ResponsiveLayout.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.verified.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Ionicons.shield_checkmark,
                size: 48,
                color: AppColors.verified,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Center(
            child: Text(
              'Xác thực danh tính',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Center(
            child: Text(
              'Nhận huy hiệu tick xanh và tăng độ tin cậy với đối tác',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Benefits
          _buildBenefitItem(
            icon: Ionicons.checkmark_circle,
            title: 'Tick xanh',
            description: 'Huy hiệu xác thực hiển thị trên hồ sơ',
          ),
          _buildBenefitItem(
            icon: Ionicons.people,
            title: 'Tăng độ tin cậy',
            description: 'Đối tác dễ dàng tin tưởng bạn hơn',
          ),
          _buildBenefitItem(
            icon: Ionicons.lock_closed,
            title: 'Bảo mật cao',
            description: 'Chỉ cần selfie - không yêu cầu CCCD',
          ),
          _buildBenefitItem(
            icon: Ionicons.flash,
            title: 'Nhanh chóng',
            description: 'Chỉ mất 2 phút để hoàn thành',
          ),

          const SizedBox(height: 32),

          // Process steps
          Text(
            'Quy trình xác thực',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildProcessStep(1, 'Chụp ảnh selfie', 'Chụp ảnh khuôn mặt rõ ràng'),
          _buildProcessStep(2, 'Kiểm tra liveness', 'Xác nhận người thật'),
          _buildProcessStep(3, 'Nhận kết quả', 'Thường trong 24-48 giờ'),

          const SizedBox(height: 40),

          // Continue button
          AppButton(
            text: 'Tiếp tục',
            onPressed: () {
              setState(() {
                _currentStep = 1;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.verified.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.verified, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(int step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieStep(VerificationState state) {
    final isSubmitting = state.status == VerificationStateStatus.submitting;

    return SingleChildScrollView(
      padding: ResponsiveLayout.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          Text(
            'Chụp ảnh selfie',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chụp ảnh khuôn mặt rõ ràng, đủ ánh sáng',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Selfie preview
          GestureDetector(
            onTap: isSubmitting ? null : _takeSelfie,
            child: Container(
              width: 280,
              height: 350,
              decoration: BoxDecoration(
                color: context.appColors.border,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selfieImage != null
                      ? AppColors.success
                      : context.appColors.border,
                  width: 3,
                ),
                image: _selfieImage != null
                    ? DecorationImage(
                        image: FileImage(_selfieImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _selfieImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Ionicons.camera,
                          size: 48,
                          color: context.appColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nhấn để chụp ảnh',
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Ionicons.refresh,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Tips
          Container(
            padding: ResponsiveLayout.pagePadding(context),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Ionicons.information_circle,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hướng dẫn',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTip('Nhìn thẳng vào camera'),
                _buildTip('Đảm bảo đủ ánh sáng'),
                _buildTip('Không đeo khăn che mặt'),
                _buildTip('Tháo kính nếu có thể'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _currentStep = 0;
                          });
                        },
                  child: const Text('Quay lại'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: AppButton(
                  text: 'Tiếp tục',
                  isLoading: isSubmitting,
                  onPressed: _selfieImage != null && !isSubmitting
                      ? () {
                          setState(() {
                            _currentStep = 2;
                          });
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Ionicons.checkmark,
            color: AppColors.info,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStep(VerificationState state) {
    final isSubmitting = state.status == VerificationStateStatus.submitting;

    return SingleChildScrollView(
      padding: ResponsiveLayout.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          Text(
            'Xác nhận gửi',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kiểm tra ảnh trước khi gửi xác thực',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Selfie preview
          if (_selfieImage != null)
            Container(
              width: 200,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success,
                  width: 2,
                ),
                image: DecorationImage(
                  image: FileImage(_selfieImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Checklist
          Container(
            padding: ResponsiveLayout.pagePadding(context),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appColors.border),
            ),
            child: Column(
              children: [
                _buildCheckItem('Khuôn mặt rõ ràng', true),
                _buildCheckItem('Đủ ánh sáng', true),
                _buildCheckItem('Không bị mờ', true),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Privacy notice
          Container(
            padding: ResponsiveLayout.pagePadding(context),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Ionicons.lock_closed,
                  color: AppColors.info,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ảnh chỉ dùng để xác thực và được bảo mật. Không lưu trữ CCCD hay giấy tờ cá nhân.',
                    style: AppTypography.bodySmall.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _currentStep = 1;
                          });
                        },
                  child: const Text('Chụp lại'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: AppButton(
                  text: 'Gửi xác thực',
                  isLoading: isSubmitting,
                  onPressed: isSubmitting ? null : _submitVerification,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            checked ? Ionicons.checkmark_circle : Ionicons.ellipse_outline,
            color: checked ? AppColors.success : context.appColors.textHint,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: checked
                  ? context.appColors.textPrimary
                  : context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takeSelfie() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selfieImage = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chụp ảnh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _submitVerification() {
    if (_selfieImage == null) return;

    context.read<VerificationBloc>().add(
      VerificationSelfieSubmitted(selfieFile: _selfieImage!),
    );
  }

  void _showSuccessDialog(BuildContext context, VerificationState state) {
    final isAutoApproved = state.verification?.isAutoVerified ?? false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: (isAutoApproved ? AppColors.success : AppColors.warning)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAutoApproved
                      ? Ionicons.checkmark_circle
                      : Ionicons.time_outline,
                  color: isAutoApproved ? AppColors.success : AppColors.warning,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isAutoApproved ? 'Xác thực thành công!' : 'Đã gửi yêu cầu!',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isAutoApproved
                    ? 'Tài khoản của bạn đã được xác thực. Huy hiệu tick xanh sẽ hiển thị trên hồ sơ.'
                    : 'Yêu cầu xác thực đang được xem xét. Bạn sẽ nhận được thông báo trong 24-48 giờ.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Đã hiểu',
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
