import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../data/models/kyc_model.dart';
import '../bloc/kyc_bloc.dart';
import '../bloc/kyc_event.dart';
import '../bloc/kyc_state.dart';

class KycPage extends StatelessWidget {
  const KycPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<KycBloc>()..add(const KycStatusLoadRequested()),
      child: const _KycPageContent(),
    );
  }
}

class _KycPageContent extends StatelessWidget {
  const _KycPageContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KycBloc, KycState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }

        if (state.status == KycPageStatus.success) {
          _showSuccessDialog(context);
        }
      },
      builder: (context, state) {
        // Check existing KYC status
        if (state.status == KycPageStatus.loading) {
          return Scaffold(
            appBar: AppBar(leading: const AppBackButton(), title: const Text('Xác minh danh tính')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // If already verified or pending
        if (state.kycStatus != null &&
            state.kycStatus!.status != KycStatus.none) {
          return _ExistingKycStatusPage(status: state.kycStatus!);
        }

        return const _KycWizard();
      },
    );
  }

  void _showSuccessDialog(BuildContext context) {
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
              'Gửi yêu cầu thành công!',
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Chúng tôi sẽ xác minh thông tin của bạn trong vòng 24 giờ. Bạn sẽ nhận được thông báo khi hoàn tất.',
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
}

class _ExistingKycStatusPage extends StatelessWidget {
  final KycStatusModel status;

  const _ExistingKycStatusPage({required this.status});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Xác minh danh tính')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _getStatusColor().withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _getStatusTitle(),
                style: AppTypography.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _getStatusMessage(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (status.status == KycStatus.rejected &&
                  status.rejectionReason != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Ionicons.information_circle_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          status.rejectionReason!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status.status) {
      case KycStatus.pending:
        return AppColors.warning;
      case KycStatus.verified:
        return AppColors.success;
      case KycStatus.rejected:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (status.status) {
      case KycStatus.pending:
        return Ionicons.time_outline;
      case KycStatus.verified:
        return Ionicons.shield_checkmark_outline;
      case KycStatus.rejected:
        return Ionicons.close_circle_outline;
      default:
        return Ionicons.shield_checkmark_outline;
    }
  }

  String _getStatusTitle() {
    switch (status.status) {
      case KycStatus.pending:
        return 'Đang chờ xác minh';
      case KycStatus.verified:
        return 'Đã xác minh';
      case KycStatus.rejected:
        return 'Xác minh thất bại';
      default:
        return 'Chưa xác minh';
    }
  }

  String _getStatusMessage() {
    switch (status.status) {
      case KycStatus.pending:
        return 'Yêu cầu của bạn đang được xử lý. Vui lòng chờ trong vòng 24 giờ.';
      case KycStatus.verified:
        return 'Danh tính của bạn đã được xác minh thành công.';
      case KycStatus.rejected:
        return 'Yêu cầu xác minh không được chấp nhận. Vui lòng thử lại.';
      default:
        return 'Hoàn tất xác minh để mở khóa đầy đủ tính năng.';
    }
  }
}

class _KycWizard extends StatelessWidget {
  const _KycWizard();

  static const List<Map<String, dynamic>> _steps = [
    {
      'title': 'Chụp mặt trước CMND/CCCD',
      'icon': Ionicons.card_outline,
      'description': 'Đặt giấy tờ trên nền phẳng, đảm bảo đủ ánh sáng',
    },
    {
      'title': 'Chụp mặt sau CMND/CCCD',
      'icon': Ionicons.card_outline,
      'description': 'Chụp rõ ràng, không bị mờ hay cắt xén',
    },
    {
      'title': 'Chụp ảnh selfie',
      'icon': Ionicons.person_outline,
      'description': 'Giữ khuôn mặt trong khung hình, không đeo kính',
    },
    {
      'title': 'Xác nhận thông tin',
      'icon': Ionicons.checkmark_circle_outline,
      'description': 'Kiểm tra và xác nhận thông tin của bạn',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KycBloc, KycState>(
      builder: (context, state) {
        final currentStep = state.currentStep;

        return Scaffold(
          appBar: AppBar(leading: const AppBackButton(), title: const Text('Xác minh danh tính')),
          body: Column(
            children: [
              // Progress Indicator
              _KycProgressIndicator(
                currentStep: currentStep,
                totalSteps: _steps.length,
              ),

              // Step Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildStepContent(context, state),
                ),
              ),

              // Bottom Actions
              _buildBottomActions(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepContent(BuildContext context, KycState state) {
    final step = _steps[state.currentStep];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Title
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(step['icon'] as IconData, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bước ${state.currentStep + 1}/${_steps.length}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step['title'] as String,
                    style: AppTypography.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          step['description'] as String,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 32),

        // Step Specific Content
        _buildStepSpecificContent(context, state),
      ],
    );
  }

  Widget _buildStepSpecificContent(BuildContext context, KycState state) {
    switch (state.currentStep) {
      case 0:
        return _ImageCaptureWidget(
          image: state.frontImage,
          isUploading:
              state.status == KycPageStatus.uploading &&
              state.frontImage != null &&
              state.frontImageUrl == null,
          label: 'Mặt trước CMND/CCCD',
          onTap: () => _showImageSourceDialog(context, 'front'),
        );
      case 1:
        return _ImageCaptureWidget(
          image: state.backImage,
          isUploading:
              state.status == KycPageStatus.uploading &&
              state.backImage != null &&
              state.backImageUrl == null,
          label: 'Mặt sau CMND/CCCD',
          onTap: () => _showImageSourceDialog(context, 'back'),
        );
      case 2:
        return _ImageCaptureWidget(
          image: state.selfieImage,
          isUploading:
              state.status == KycPageStatus.uploading &&
              state.selfieImage != null &&
              state.selfieImageUrl == null,
          label: 'Ảnh selfie của bạn',
          onTap: () => _showImageSourceDialog(context, 'selfie'),
          isCircle: true,
        );
      case 3:
        return _ConfirmationStep(
          frontImage: state.frontImage,
          backImage: state.backImage,
          selfieImage: state.selfieImage,
        );
      default:
        return const SizedBox();
    }
  }

  void _showImageSourceDialog(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            Text('Chọn nguồn ảnh', style: AppTypography.titleLarge),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ImageSourceOption(
                  icon: Ionicons.camera_outline,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(bottomContext);
                    _pickImage(context, ImageSource.camera, type);
                  },
                ),
                _ImageSourceOption(
                  icon: Ionicons.image_outline,
                  label: 'Thư viện',
                  onTap: () {
                    Navigator.pop(bottomContext);
                    _pickImage(context, ImageSource.gallery, type);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    ImageSource source,
    String type,
  ) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null && context.mounted) {
        final file = File(pickedFile.path);
        final bloc = context.read<KycBloc>();

        switch (type) {
          case 'front':
            bloc.add(KycFrontImageSelected(file));
            break;
          case 'back':
            bloc.add(KycBackImageSelected(file));
            break;
          case 'selfie':
            bloc.add(KycSelfieSelected(file));
            break;
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera 
                ? 'Không thể truy cập camera. Vui lòng kiểm tra quyền truy cập.'
                : 'Không thể truy cập thư viện ảnh. Vui lòng kiểm tra quyền truy cập.',
            ),
          ),
        );
      }
    }
  }

  bool _canProceed(KycState state) {
    switch (state.currentStep) {
      case 0:
        return state.frontImageUrl != null;
      case 1:
        return state.backImageUrl != null;
      case 2:
        return state.selfieImageUrl != null;
      case 3:
        return true;
      default:
        return false;
    }
  }

  Widget _buildBottomActions(BuildContext context, KycState state) {
    final isSubmitting = state.status == KycPageStatus.submitting;
    final isUploading = state.status == KycPageStatus.uploading;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (state.currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting || isUploading
                      ? null
                      : () => context.read<KycBloc>().add(
                          KycStepChanged(state.currentStep - 1),
                        ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Quay lại'),
                ),
              ),
            if (state.currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: state.currentStep > 0 ? 1 : 2,
              child: AppButton(
                text: state.currentStep == _steps.length - 1
                    ? 'Gửi xác minh'
                    : 'Tiếp tục',
                onPressed: _canProceed(state) && !isUploading
                    ? () {
                        if (state.currentStep == _steps.length - 1) {
                          context.read<KycBloc>().add(
                            const KycSubmitRequested(),
                          );
                        } else {
                          context.read<KycBloc>().add(
                            KycStepChanged(state.currentStep + 1),
                          );
                        }
                      }
                    : null,
                isLoading: isSubmitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KycProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _KycProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          } else {
            // Step indicator
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            final isCurrent = stepIndex == currentStep;

            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? AppColors.primary
                    : AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted || isCurrent
                      ? AppColors.primary
                      : AppColors.border,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: AppColors.textWhite,
                        size: 16,
                      )
                    : Text(
                        '${stepIndex + 1}',
                        style: AppTypography.labelMedium.copyWith(
                          color: isCurrent
                              ? AppColors.textWhite
                              : AppColors.textSecondary,
                        ),
                      ),
              ),
            );
          }
        }),
      ),
    );
  }
}

class _ImageCaptureWidget extends StatelessWidget {
  final File? image;
  final String label;
  final VoidCallback onTap;
  final bool isCircle;
  final bool isUploading;

  const _ImageCaptureWidget({
    required this.image,
    required this.label,
    required this.onTap,
    this.isCircle = false,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: isCircle ? 280 : 200,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(isCircle ? 140 : 16),
          border: Border.all(
            color: image != null ? AppColors.primary : AppColors.border,
            width: 2,
            style: image != null ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(isCircle ? 140 : 14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(image!, fit: BoxFit.cover),
                    if (isUploading)
                      Container(
                        color: Colors.black.withAlpha(128),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.textWhite,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Đang tải lên...',
                                style: TextStyle(color: AppColors.textWhite),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Ionicons.create_outline,
                            color: AppColors.textWhite,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isCircle ? 140 : 16),
                  border: Border.all(
                    color: AppColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Ionicons.camera_outline,
                        color: AppColors.textHint,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nhấn để chụp hoặc chọn ảnh',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}

class _ConfirmationStep extends StatelessWidget {
  final File? frontImage;
  final File? backImage;
  final File? selfieImage;

  const _ConfirmationStep({
    required this.frontImage,
    required this.backImage,
    required this.selfieImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tài liệu đã tải lên', style: AppTypography.titleSmall),
              const SizedBox(height: 16),
              _DocumentPreview(label: 'CMND/CCCD mặt trước', image: frontImage),
              const Divider(height: 24),
              _DocumentPreview(label: 'CMND/CCCD mặt sau', image: backImage),
              const Divider(height: 24),
              _DocumentPreview(
                label: 'Ảnh selfie',
                image: selfieImage,
                isCircle: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Terms
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withAlpha(50)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Ionicons.information_circle_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bằng việc gửi xác minh, bạn đồng ý cho phép chúng tôi xử lý dữ liệu cá nhân của bạn theo Chính sách bảo mật.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  final String label;
  final File? image;
  final bool isCircle;

  const _DocumentPreview({
    required this.label,
    required this.image,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(isCircle ? 30 : 8),
          ),
          child: image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(isCircle ? 30 : 8),
                  child: Image.file(image!, fit: BoxFit.cover),
                )
              : Icon(Ionicons.document_text_outline, color: AppColors.textHint),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.bodyMedium),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    image != null ? Ionicons.checkmark_circle_outline : Ionicons.close_circle_outline,
                    size: 16,
                    color: image != null ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    image != null ? 'Đã tải lên' : 'Chưa có',
                    style: AppTypography.labelSmall.copyWith(
                      color: image != null
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
