import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/constants/service_type_emoji.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/bloc/master_data_bloc.dart';
import '../../../../shared/data/models/master_data_models.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../bloc/partner_registration_bloc.dart';

class BecomePartnerPage extends StatefulWidget {
  const BecomePartnerPage({super.key});

  @override
  State<BecomePartnerPage> createState() => _BecomePartnerPageState();
}

class _BecomePartnerPageState extends State<BecomePartnerPage> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Basic Info
  final _bioController = TextEditingController();
  final _introController = TextEditingController();

  // Step 2: Services
  final List<String> _selectedServices = [];
  final _hourlyRateController = TextEditingController(text: '300000');

  // Step 3: Photos
  final List<File> _photos = [];

  // Step 4: Bank Account
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();

  // Master data (loaded from API)
  List<ServiceTypeModel> _serviceTypes = [];

  final List<String> _banks = [
    'Vietcombank',
    'BIDV',
    'Techcombank',
    'VPBank',
    'MB Bank',
    'ACB',
    'Sacombank',
    'TPBank',
    'VIB',
    'Agribank',
  ];

  @override
  void initState() {
    super.initState();
    // Dispatch load in initState (not in build) - MasterDataBloc is singleton,
    // we must use BlocProvider.value to avoid disposing it when leaving the page
    getIt<MasterDataBloc>().add(const PartnerMasterDataLoadRequested());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bioController.dispose();
    _introController.dispose();
    _hourlyRateController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  void _nextStep(BuildContext blocContext) {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submitRegistration(blocContext);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _bioController.text.length >= 20 &&
            _introController.text.length >= 50;
      case 1:
        return _selectedServices.isNotEmpty &&
            _hourlyRateController.text.isNotEmpty;
      case 2:
        return _photos.length >= 3;
      case 3:
        return _bankNameController.text.isNotEmpty &&
            _accountNumberController.text.isNotEmpty &&
            _accountHolderController.text.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      setState(() {
        for (var image in images) {
          if (_photos.length < 6) {
            _photos.add(File(image.path));
          }
        }
      });
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _submitRegistration(BuildContext blocContext) {
    // Get service type codes from selected IDs
    final selectedServiceCodes = _serviceTypes
        .where((s) => _selectedServices.contains(s.id))
        .map((s) => s.code)
        .toList();

    blocContext.read<PartnerRegistrationBloc>().add(
      PartnerRegistrationSubmitted(
        serviceTypes: selectedServiceCodes,
        hourlyRate: int.tryParse(_hourlyRateController.text) ?? 300000,
        introduction: _introController.text,
        bio: _bioController.text,
        bankName: _bankNameController.text,
        bankAccountNo: _accountNumberController.text,
        bankAccountName: _accountHolderController.text,
        photos: _photos,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
              'Đăng ký thành công!',
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Hồ sơ của bạn đang được xét duyệt. Chúng tôi sẽ thông báo kết quả trong vòng 24-48 giờ.',
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
                Navigator.pop(context);
                context.go(RouteNames.home);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error, {bool isAlreadyPartner = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (isAlreadyPartner ? AppColors.warning : AppColors.error)
                    .withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAlreadyPartner ? Ionicons.information_circle_outline : Ionicons.close_circle_outline,
                color: isAlreadyPartner ? AppColors.warning : AppColors.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isAlreadyPartner ? 'Đã đăng ký' : 'Đăng ký thất bại',
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
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
              text: isAlreadyPartner ? 'Về trang chủ' : 'Đóng',
              onPressed: () {
                Navigator.pop(context);
                if (isAlreadyPartner) {
                  context.go(RouteNames.home);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Lấy emoji từ API hoặc fallback
  String _getServiceEmoji(ServiceTypeModel service) =>
      (service.icon != null && service.icon!.isNotEmpty)
          ? service.icon!
          : ServiceTypeEmoji.get(service.code).emoji;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // MasterDataBloc is singleton - use .value to avoid dispose (would close it, causing error on re-enter)
        BlocProvider.value(value: getIt<MasterDataBloc>()),
        BlocProvider(create: (_) => getIt<PartnerRegistrationBloc>()),
      ],
      child: BlocListener<PartnerRegistrationBloc, PartnerRegistrationState>(
        listener: (context, state) {
          if (state is PartnerRegistrationLoading) {
            setState(() => _isLoading = true);
          } else if (state is PartnerRegistrationSuccess) {
            setState(() => _isLoading = false);
            _showSuccessDialog();
          } else if (state is PartnerRegistrationFailure) {
            setState(() => _isLoading = false);
            _showErrorDialog(
              state.error,
              isAlreadyPartner: state.isAlreadyPartner,
            );
          }
        },
        child: BlocConsumer<MasterDataBloc, MasterDataState>(
          listener: (context, state) {
            if (state is PartnerMasterDataLoaded) {
              setState(() {
                _serviceTypes = state.serviceTypes;
              });
            }
          },
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(leading: const AppBackButton(), title: const Text('Trở thành Partner')),
              body: _buildBody(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MasterDataState state) {
    if (state is MasterDataLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is MasterDataError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.alert_circle_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Thử lại',
              onPressed: () => context.read<MasterDataBloc>().add(
                const PartnerMasterDataLoadRequested(),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Progress Indicator
        _StepIndicator(
          currentStep: _currentStep,
          steps: const ['Thông tin', 'Dịch vụ', 'Hình ảnh', 'Thanh toán'],
        ),

        // Page Content
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _BasicInfoStep(
                bioController: _bioController,
                introController: _introController,
                onChanged: () => setState(() {}),
              ),
              _ServicesStep(
                serviceTypes: _serviceTypes,
                selectedServices: _selectedServices,
                hourlyRateController: _hourlyRateController,
                getServiceEmoji: _getServiceEmoji,
                onServiceToggle: (serviceId) {
                  setState(() {
                    if (_selectedServices.contains(serviceId)) {
                      _selectedServices.remove(serviceId);
                    } else {
                      _selectedServices.add(serviceId);
                    }
                  });
                },
                onChanged: () => setState(() {}),
              ),
              _PhotosStep(
                photos: _photos,
                onPickPhotos: _pickPhotos,
                onRemovePhoto: _removePhoto,
              ),
              _BankAccountStep(
                banks: _banks,
                bankNameController: _bankNameController,
                accountNumberController: _accountNumberController,
                accountHolderController: _accountHolderController,
                onChanged: () => setState(() {}),
              ),
            ],
          ),
        ),

        // Bottom Actions
        Container(
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
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Quay lại'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: _currentStep > 0 ? 1 : 2,
                  child: AppButton(
                    text: _currentStep == 3 ? 'Hoàn tất đăng ký' : 'Tiếp tục',
                    onPressed: _canProceed() ? () => _nextStep(context) : null,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const _StepIndicator({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
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
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            final isCurrent = stepIndex == currentStep;

            return Column(
              children: [
                Container(
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
                ),
                const SizedBox(height: 4),
                Text(
                  steps[stepIndex],
                  style: AppTypography.labelSmall.copyWith(
                    color: isCurrent || isCompleted
                        ? AppColors.primary
                        : AppColors.textHint,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }
}

class _BasicInfoStep extends StatelessWidget {
  final TextEditingController bioController;
  final TextEditingController introController;
  final VoidCallback onChanged;

  const _BasicInfoStep({
    required this.bioController,
    required this.introController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Giới thiệu về bạn', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Hãy cho mọi người biết về bạn để tăng cơ hội được chọn.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          AppTextField(
            controller: bioController,
            label: 'Tiêu đề ngắn gọn',
            hint: 'VD: Sinh viên năng động, vui vẻ...',
            maxLength: 50,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          Text(
            '${bioController.text.length}/50 ký tự (tối thiểu 20)',
            style: AppTypography.labelSmall.copyWith(
              color: bioController.text.length >= 20
                  ? AppColors.success
                  : AppColors.textHint,
            ),
          ),

          const SizedBox(height: 24),

          AppTextField(
            controller: introController,
            label: 'Mô tả chi tiết',
            hint: 'Kể về sở thích, tính cách, kinh nghiệm của bạn...',
            maxLines: 5,
            maxLength: 500,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          Text(
            '${introController.text.length}/500 ký tự (tối thiểu 50)',
            style: AppTypography.labelSmall.copyWith(
              color: introController.text.length >= 50
                  ? AppColors.success
                  : AppColors.textHint,
            ),
          ),

          const SizedBox(height: 24),

          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Ionicons.flash_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Mẹo viết giới thiệu hay',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TipItem(text: 'Nêu rõ tính cách và sở thích của bạn'),
                _TipItem(text: 'Đề cập các hoạt động bạn giỏi'),
                _TipItem(text: 'Thể hiện sự chân thành và thân thiện'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesStep extends StatelessWidget {
  final List<ServiceTypeModel> serviceTypes;
  final List<String> selectedServices;
  final TextEditingController hourlyRateController;
  final String Function(ServiceTypeModel) getServiceEmoji;
  final Function(String) onServiceToggle;
  final VoidCallback onChanged;

  const _ServicesStep({
    required this.serviceTypes,
    required this.selectedServices,
    required this.hourlyRateController,
    required this.getServiceEmoji,
    required this.onServiceToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chọn dịch vụ của bạn', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Chọn các dịch vụ bạn muốn cung cấp. Bạn có thể thay đổi sau.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Services Grid
          if (serviceTypes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Đang tải danh sách dịch vụ...',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: serviceTypes.length,
              itemBuilder: (context, index) {
                final service = serviceTypes[index];
                final isSelected = selectedServices.contains(service.id);

                return GestureDetector(
                  onTap: () => onServiceToggle(service.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          getServiceEmoji(service),
                          style: TextStyle(
                            fontSize: 20,
                            color: isSelected
                                ? AppColors.textWhite
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            service.displayName,
                            style: AppTypography.labelMedium.copyWith(
                              color: isSelected
                                  ? AppColors.textWhite
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Ionicons.checkmark_circle_outline,
                            color: AppColors.textWhite,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 32),

          // Hourly Rate
          Text('Mức giá theo giờ', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Đặt mức giá phù hợp với dịch vụ của bạn.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          AppTextField(
            controller: hourlyRateController,
            label: 'Giá mỗi giờ (VNĐ)',
            hint: 'Nhập số tiền',
            keyboardType: TextInputType.number,
            prefixIcon: Ionicons.cash_outline,
            onChanged: (_) => onChanged(),
          ),

          const SizedBox(height: 16),

          // Price Suggestions
          Text(
            'Gợi ý mức giá:',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [200000, 300000, 400000, 500000].map((price) {
              return GestureDetector(
                onTap: () {
                  hourlyRateController.text = price.toString();
                  onChanged();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${(price / 1000).toInt()}k/giờ',
                    style: AppTypography.labelMedium,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PhotosStep extends StatelessWidget {
  final List<File> photos;
  final VoidCallback onPickPhotos;
  final Function(int) onRemovePhoto;

  const _PhotosStep({
    required this.photos,
    required this.onPickPhotos,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thêm hình ảnh', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Thêm ít nhất 3 hình ảnh chất lượng cao để hồ sơ thu hút hơn.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Photo Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: photos.length < 6 ? photos.length + 1 : photos.length,
            itemBuilder: (context, index) {
              if (index == photos.length && photos.length < 6) {
                // Add Photo Button
                return GestureDetector(
                  onTap: onPickPhotos,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Ionicons.add_circle_outline,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thêm ảnh',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Photo Item
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      photos[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemovePhoto(index),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.textWhite,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Chính',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Photo Count
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: photos.length >= 3
                  ? AppColors.success.withAlpha(25)
                  : AppColors.warning.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  photos.length >= 3
                      ? Ionicons.checkmark_circle_outline
                      : Ionicons.information_circle_outline,
                  color: photos.length >= 3
                      ? AppColors.success
                      : AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${photos.length}/6 ảnh (tối thiểu 3)',
                  style: AppTypography.labelMedium.copyWith(
                    color: photos.length >= 3
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Ionicons.flash_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Mẹo chọn ảnh',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TipItem(text: 'Chọn ảnh rõ mặt, ánh sáng tốt'),
                _TipItem(text: 'Ảnh đầu tiên sẽ là ảnh đại diện chính'),
                _TipItem(text: 'Thêm ảnh hoạt động để thể hiện cá tính'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BankAccountStep extends StatelessWidget {
  final List<String> banks;
  final TextEditingController bankNameController;
  final TextEditingController accountNumberController;
  final TextEditingController accountHolderController;
  final VoidCallback onChanged;

  const _BankAccountStep({
    required this.banks,
    required this.bankNameController,
    required this.accountNumberController,
    required this.accountHolderController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin thanh toán', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Thêm tài khoản ngân hàng để nhận thanh toán từ các đơn hàng.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Bank Name
          Text('Ngân hàng', style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showBankPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Ionicons.business_outline, color: AppColors.textHint),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bankNameController.text.isEmpty
                          ? 'Chọn ngân hàng'
                          : bankNameController.text,
                      style: AppTypography.bodyLarge.copyWith(
                        color: bankNameController.text.isEmpty
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Ionicons.chevron_down_outline, color: AppColors.textHint),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          AppTextField(
            controller: accountNumberController,
            label: 'Số tài khoản',
            hint: 'Nhập số tài khoản',
            keyboardType: TextInputType.number,
            prefixIcon: Ionicons.card_outline,
            onChanged: (_) => onChanged(),
          ),

          const SizedBox(height: 20),

          AppTextField(
            controller: accountHolderController,
            label: 'Tên chủ tài khoản',
            hint: 'Nhập tên chủ tài khoản (in hoa)',
            prefixIcon: Ionicons.person_outline,
            onChanged: (_) => onChanged(),
          ),

          const SizedBox(height: 24),

          // Security Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Ionicons.shield_checkmark_outline, color: AppColors.success, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bảo mật thông tin',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thông tin tài khoản của bạn được mã hóa và bảo mật. Chúng tôi sẽ không chia sẻ với bất kỳ ai.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Commission Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thông tin hoa hồng', style: AppTypography.titleSmall),
                const SizedBox(height: 12),
                _CommissionItem(
                  label: 'Thu nhập của bạn',
                  value: '80%',
                  color: AppColors.success,
                ),
                const SizedBox(height: 8),
                _CommissionItem(
                  label: 'Phí dịch vụ',
                  value: '20%',
                  color: AppColors.textSecondary,
                ),
                const Divider(height: 24),
                Text(
                  'Tiền sẽ được chuyển vào tài khoản ngân hàng trong vòng 1-3 ngày làm việc sau khi hoàn thành dịch vụ.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBankPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Chọn ngân hàng', style: AppTypography.titleLarge),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: banks.length,
                itemBuilder: (context, index) {
                  final bank = banks[index];
                  final isSelected = bankNameController.text == bank;

                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Ionicons.business_outline,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: Text(bank, style: AppTypography.bodyLarge),
                    trailing: isSelected
                        ? Icon(Ionicons.checkmark_circle_outline, color: AppColors.primary)
                        : null,
                    onTap: () {
                      bankNameController.text = bank;
                      onChanged();
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
}

class _CommissionItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CommissionItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
