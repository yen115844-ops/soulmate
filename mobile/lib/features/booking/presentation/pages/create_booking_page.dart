import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/constants/service_type_emoji.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/common/step_indicator.dart';
import '../../../partner/data/partner_repository.dart';
import '../../../partner/domain/models/partner_schedule.dart';
import '../../data/booking_repository.dart';

class CreateBookingPage extends StatefulWidget {
  final String partnerId;

  const CreateBookingPage({super.key, required this.partnerId});

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  PartnerRepository get _partnerRepository => getIt<PartnerRepository>();
  BookingRepository get _bookingRepository => getIt<BookingRepository>();

  bool _isLoadingPartner = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Step 1: Service Selection
  String? _selectedService;

  // Step 2: Date & Time
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 14, minute: 0);
  int _duration = 3; // hours

  // Step 3: Location
  final _locationController = TextEditingController();
  String? _selectedLocationType;

  // Step 4: Notes & Confirm
  final _notesController = TextEditingController();

  // Partner data from API
  PartnerDetailResponse? _partner;
  List<String> _partnerServices = [];

  // Mock partner schedule - sẽ load từ API
  late PartnerSchedule _partnerSchedule;

  @override
  void initState() {
    super.initState();
    _loadPartnerData();
    _loadPartnerSchedule();
  }

  Future<void> _loadPartnerData() async {
    setState(() {
      _isLoadingPartner = true;
      _errorMessage = null;
    });

    try {
      final partnerDetail = await _partnerRepository.getPartnerByIdWithUser(
        widget.partnerId,
      );

      if (mounted) {
        setState(() {
          _partner = partnerDetail;
          _partnerServices = partnerDetail.profile.serviceTypes;
          _duration = partnerDetail.profile.minimumHours;
          _isLoadingPartner = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading partner: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải thông tin partner';
          _isLoadingPartner = false;
        });
      }
    }
  }

  void _loadPartnerSchedule() {
    // Mock weekly schedule using DailySchedule
    final weeklySchedule = WeeklySchedule(
      schedule: {
        DayOfWeek.monday: DailySchedule(
          dayOfWeek: DayOfWeek.monday,
          isEnabled: true,
          timeSlots: [
            TimeSlot(
              startTime: const TimeOfDay(hour: 9, minute: 0),
              endTime: const TimeOfDay(hour: 12, minute: 0),
            ),
            TimeSlot(
              startTime: const TimeOfDay(hour: 14, minute: 0),
              endTime: const TimeOfDay(hour: 18, minute: 0),
            ),
          ],
        ),
        DayOfWeek.tuesday: DailySchedule(
          dayOfWeek: DayOfWeek.tuesday,
          isEnabled: true,
          timeSlots: [
            TimeSlot(
              startTime: const TimeOfDay(hour: 9, minute: 0),
              endTime: const TimeOfDay(hour: 17, minute: 0),
            ),
          ],
        ),
        DayOfWeek.wednesday: DailySchedule(
          dayOfWeek: DayOfWeek.wednesday,
          isEnabled: true,
          timeSlots: [
            TimeSlot(
              startTime: const TimeOfDay(hour: 9, minute: 0),
              endTime: const TimeOfDay(hour: 17, minute: 0),
            ),
          ],
        ),
        DayOfWeek.thursday: DailySchedule(
          dayOfWeek: DayOfWeek.thursday,
          isEnabled: true,
          timeSlots: [
            TimeSlot(
              startTime: const TimeOfDay(hour: 9, minute: 0),
              endTime: const TimeOfDay(hour: 17, minute: 0),
            ),
          ],
        ),
        DayOfWeek.friday: DailySchedule(
          dayOfWeek: DayOfWeek.friday,
          isEnabled: true,
          timeSlots: [
            TimeSlot(
              startTime: const TimeOfDay(hour: 9, minute: 0),
              endTime: const TimeOfDay(hour: 17, minute: 0),
            ),
          ],
        ),
        DayOfWeek.saturday: DailySchedule(
          dayOfWeek: DayOfWeek.saturday,
          isEnabled: true,
          timeSlots: [
            TimeSlot(
              startTime: const TimeOfDay(hour: 10, minute: 0),
              endTime: const TimeOfDay(hour: 15, minute: 0),
            ),
          ],
        ),
        DayOfWeek.sunday: DailySchedule(
          dayOfWeek: DayOfWeek.sunday,
          isEnabled: false,
          timeSlots: [],
        ),
      },
    );

    // Mock overrides (blocked dates)
    final overrides = [
      ScheduleOverride(
        date: DateTime(2025, 1, 25),
        isAvailable: false,
        reason: 'Ngày nghỉ cá nhân',
      ),
      ScheduleOverride(
        date: DateTime(2025, 1, 30),
        isAvailable: false,
        reason: 'Tết Nguyên Đán',
      ),
      ScheduleOverride(
        date: DateTime(2025, 2, 1),
        isAvailable: false,
        reason: 'Tết Nguyên Đán',
      ),
    ];

    _partnerSchedule = PartnerSchedule(
      partnerId: widget.partnerId,
      weeklySchedule: weeklySchedule,
      overrides: overrides,
    );
  }

  /// Get available time slots for a date
  List<TimeSlot> _getAvailableSlotsForDate(DateTime date) {
    return _partnerSchedule.getAvailableSlotsForDate(date);
  }

  /// Check if date has any available slots
  bool _isDateAvailable(DateTime date) {
    if (date.isBefore(DateTime.now())) return false;
    return _getAvailableSlotsForDate(date).isNotEmpty;
  }

  /// Service descriptions (bổ sung cho ServiceConstants)
  static const Map<String, String> _serviceDescriptions = {
    'WALKING': 'Đi dạo công viên, phố đi bộ',
    'MOVIE': 'Xem phim tại rạp',
    'COFFEE': 'Ngồi cafe trò chuyện',
    'DINNER': 'Dùng bữa tại nhà hàng',
    'DINING': 'Dùng bữa tại nhà hàng',
    'PARTY': 'Tiệc sinh nhật, công ty',
    'TRAVEL': 'Đi chơi xa, du lịch',
    'SHOPPING': 'Đi mua sắm cùng',
    'SPORTS': 'Hoạt động thể thao',
    'OTHER': 'Dịch vụ khác',
  };

  List<Map<String, dynamic>> get _services {
    return _partnerServices.map((serviceType) {
      final display = ServiceTypeEmoji.get(serviceType);
      final description = _serviceDescriptions[serviceType.toUpperCase()] ??
          serviceType;
      return {
        'type': serviceType,
        'name': display.nameVi,
        'emoji': display.emoji,
        'color': Color(display.color),
        'description': description,
      };
    }).toList();
  }

  int get _hourlyRate => _partner?.profile.hourlyRate.toInt() ?? 0;
  int get _subtotal => _hourlyRate * _duration;
  int get _serviceFee => (_subtotal * 0.15).round();
  int get _totalAmount => _subtotal + _serviceFee;

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedService != null;
      case 1:
        final slots = _getAvailableSlotsForDate(_selectedDate);
        if (slots.isEmpty) return false;
        final isTimeInSlot = slots.any((s) => s.containsTime(_startTime));
        return isTimeInSlot;
      case 2:
        return _selectedLocationType != null;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _confirmBooking() {
    final serviceName = ServiceTypeEmoji.get(_selectedService!).nameVi;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConfirmationBottomSheet(
        partner: _partner,
        service: serviceName,
        date: _selectedDate,
        startTime: _startTime,
        duration: _duration,
        location: _locationController.text.isEmpty
            ? 'Chưa chọn địa điểm'
            : _locationController.text,
        totalAmount: _totalAmount,
        onConfirm: () {
          Navigator.pop(context);
          _submitBooking();
        },
      ),
    );
  }

  Future<void> _submitBooking() async {
    setState(() => _isSubmitting = true);

    try {
      // Calculate start and end time
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDateTime = startDateTime.add(Duration(hours: _duration));

      final booking = await _bookingRepository.createBooking(
        partnerId: widget.partnerId,
        serviceType: _selectedService!,
        startTime: startDateTime,
        endTime: endDateTime,
        note: _notesController.text.isNotEmpty ? _notesController.text : null,
        location: _locationController.text.isNotEmpty
            ? _locationController.text
            : null,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog(bookingId: booking.id, bookingCode: booking.bookingCode);
      }
    } catch (e) {
      debugPrint('Error creating booking: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSuccessDialog({String? bookingId, String? bookingCode}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _SuccessDialog(
        onViewBooking: () {
          Navigator.pop(dialogContext);
          if (bookingId != null && bookingId.isNotEmpty) {
            context.go(RouteNames.bookingConfirmation, extra: {
              'bookingId': bookingId,
              'bookingCode': bookingCode ?? '',
            });
          } else {
            context.go('/home', extra: {'initialPage': 0});
          }
        },
        onBackHome: () {
          Navigator.pop(dialogContext);
          context.go(RouteNames.home);
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoadingPartner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đặt lịch hẹn')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đặt lịch hẹn')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Ionicons.alert_circle_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPartnerData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: AppBackButton(onPressed: _previousStep),
        title: Text(
          'Đặt lịch hẹn',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: StepIndicator(
              currentStep: _currentStep,
              totalSteps: 4,
              stepLabels: const [
                'Dịch vụ',
                'Thời gian',
                'Địa điểm',
                'Xác nhận',
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Partner Info Card
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: ImageUtils.buildImageUrl(
                        _partner?.avatarUrl ?? '',
                      ),
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.backgroundLight),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.backgroundLight,
                        child: const Icon(Ionicons.person_outline),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _partner?.displayName ?? 'Partner',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_partner?.profile.isVerified == true) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Ionicons.checkmark_done_outline,
                              size: 16,
                              color: AppColors.info,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Ionicons.star_outline,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_partner?.profile.averageRating.toStringAsFixed(1) ?? '0'} (${_partner?.profile.totalReviews ?? 0} đánh giá)',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatPrice(_hourlyRate)}đ',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '/giờ',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Page Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildServiceSelection(),
                _buildDateTimeSelection(),
                _buildLocationSelection(),
                _buildConfirmation(),
              ],
            ),
          ),

          // Bottom Action
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Price Summary
                if (_currentStep >= 1) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tổng tiền',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${_formatPrice(_totalAmount)}đ',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                // Action Button
                Expanded(
                  flex: _currentStep >= 1 ? 1 : 2,
                  child: AppButton(
                    text: _currentStep == 3 ? 'Xác nhận đặt lịch' : 'Tiếp tục',
                    onPressed: _isSubmitting || !_canProceed
                        ? null
                        : (_currentStep == 3 ? _confirmBooking : _nextStep),
                    isLoading: _isSubmitting,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn dịch vụ',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn muốn làm gì cùng ${_partner?.displayName ?? 'Partner'}?',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Services Grid
          ...List.generate(_services.length, (index) {
            final service = _services[index];
            final isSelected = _selectedService == service['type'];
            final isAvailable = _partnerServices.contains(service['type']);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: isAvailable
                    ? () => setState(() => _selectedService = service['type'])
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.05)
                        : isAvailable
                        ? AppColors.surface
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : isAvailable
                          ? AppColors.border
                          : AppColors.border.withOpacity(0.5),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        service['emoji'] as String,
                        style: TextStyle(
                          fontSize: 28,
                          color: service['color'] ?? AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['name'],
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isAvailable
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                              ),
                            ),
                            Text(
                              service['description'],
                              style: AppTypography.bodySmall.copyWith(
                                color: isAvailable
                                    ? AppColors.textSecondary
                                    : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Không khả dụng',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        )
                      else if (isSelected)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    final availableSlots = _getAvailableSlotsForDate(_selectedDate);
    final hasSlots = availableSlots.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn ngày & giờ',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tối thiểu ${_partner?.profile.minimumHours ?? 3} giờ cho mỗi lịch hẹn',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Date Selection Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ngày hẹn',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showScheduleInfo(),
                icon: const Icon(Ionicons.information_circle_outline, size: 16),
                label: const Text('Xem lịch'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Calendar Date Picker
          _buildDateCalendar(),

          const SizedBox(height: 24),

          // Available Time Slots
          Text(
            'Khung giờ khả dụng',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasSlots
                ? 'Chọn giờ bắt đầu trong khung giờ ${_partner?.displayName ?? 'Partner'} có thể nhận'
                : 'Không có khung giờ khả dụng trong ngày này',
            style: AppTypography.bodySmall.copyWith(
              color: hasSlots ? AppColors.textSecondary : AppColors.error,
            ),
          ),
          const SizedBox(height: 12),

          // Show available slots
          if (hasSlots)
            _buildAvailableTimeSlots(availableSlots)
          else
            _buildNoSlotsMessage(),

          const SizedBox(height: 24),

          // Time Selection
          Text(
            'Giờ bắt đầu',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: hasSlots ? () => _selectTimeFromSlots(availableSlots) : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasSlots ? AppColors.surface : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasSlots
                      ? AppColors.border
                      : AppColors.border.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasSlots
                          ? AppColors.secondary.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Ionicons.time_outline,
                      color: hasSlots ? AppColors.secondary : Colors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _startTime.format(context),
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: hasSlots
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                  Icon(
                    Ionicons.chevron_forward_outline,
                    color: hasSlots
                        ? AppColors.textHint
                        : Colors.grey.withOpacity(0.5),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Duration Selection
          Text(
            'Thời lượng',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Ionicons.timer_outline,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_duration giờ',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Kết thúc lúc ${_formatEndTime()}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Duration Controls
                Row(
                  children: [
                    _DurationButton(
                      icon: Ionicons.remove_outline,
                      onTap: _duration > (_partner?.profile.minimumHours ?? 3)
                          ? () => setState(() => _duration--)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$_duration',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    _DurationButton(
                      icon: Ionicons.add_outline,
                      onTap: _duration < 12
                          ? () => setState(() => _duration++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Price Breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _PriceRow(
                  label: '${_formatPrice(_hourlyRate)}đ x $_duration giờ',
                  value: '${_formatPrice(_subtotal)}đ',
                ),
                const SizedBox(height: 8),
                _PriceRow(
                  label: 'Phí dịch vụ (15%)',
                  value: '${_formatPrice(_serviceFee)}đ',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                _PriceRow(
                  label: 'Tổng cộng',
                  value: '${_formatPrice(_totalAmount)}đ',
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Địa điểm gặp mặt',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn nơi bạn muốn gặp ${_partner?.displayName ?? 'Partner'}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Location Type
          _LocationOption(
            icon: Ionicons.map_outline,
            title: 'Tôi sẽ chọn địa điểm',
            description: 'Nhập địa chỉ cụ thể nơi gặp mặt',
            isSelected: _selectedLocationType == 'custom',
            onTap: () => setState(() => _selectedLocationType = 'custom'),
          ),
          const SizedBox(height: 12),
          _LocationOption(
            icon: Ionicons.person_outline,
            title: 'Partner gợi ý',
            description:
                'Để ${_partner?.displayName ?? 'Partner'} gợi ý địa điểm',
            isSelected: _selectedLocationType == 'partner',
            onTap: () => setState(() => _selectedLocationType = 'partner'),
          ),
          const SizedBox(height: 12),
          _LocationOption(
            icon: Ionicons.chatbubble_outline,
            title: 'Thảo luận sau',
            description: 'Quyết định sau qua chat',
            isSelected: _selectedLocationType == 'later',
            onTap: () => setState(() => _selectedLocationType = 'later'),
          ),

          if (_selectedLocationType == 'custom') ...[
            const SizedBox(height: 24),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Nhập địa chỉ...',
                prefixIcon: const Icon(Ionicons.location_outline),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xác nhận thông tin',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kiểm tra lại thông tin trước khi đặt lịch',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Ionicons.apps_outline,
                  label: 'Dịch vụ',
                  value: _selectedService != null
                      ? ServiceTypeEmoji.get(_selectedService!).nameVi
                      : '-',
                ),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Ionicons.calendar_outline,
                  label: 'Ngày',
                  value: DateFormat('dd/MM/yyyy').format(_selectedDate),
                ),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Ionicons.time_outline,
                  label: 'Thời gian',
                  value: '${_startTime.format(context)} - ${_formatEndTime()}',
                ),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Ionicons.timer_outline,
                  label: 'Thời lượng',
                  value: '$_duration giờ',
                ),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Ionicons.location_outline,
                  label: 'Địa điểm',
                  value: _getLocationText(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notes
          Text(
            'Ghi chú cho Partner (tùy chọn)',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Mình muốn ngồi chỗ yên tĩnh...',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 24),

          // Price Breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _PriceRow(
                  label: 'Dịch vụ ($_duration giờ)',
                  value: '${_formatPrice(_subtotal)}đ',
                ),
                const SizedBox(height: 8),
                _PriceRow(
                  label: 'Phí dịch vụ',
                  value: '${_formatPrice(_serviceFee)}đ',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                _PriceRow(
                  label: 'Tổng cộng',
                  value: '${_formatPrice(_totalAmount)}đ',
                  isTotal: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Terms
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Ionicons.information_circle_outline,
                size: 16,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bằng việc đặt lịch, bạn đồng ý với Điều khoản sử dụng và Chính sách bảo mật của Mate Social',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatEndTime() {
    final endHour = (_startTime.hour + _duration) % 24;
    return TimeOfDay(hour: endHour, minute: _startTime.minute).format(context);
  }

  String _getLocationText() {
    switch (_selectedLocationType) {
      case 'custom':
        return _locationController.text.isEmpty
            ? 'Chưa nhập địa chỉ'
            : _locationController.text;
      case 'partner':
        return 'Partner gợi ý';
      case 'later':
        return 'Thảo luận sau';
      default:
        return '-';
    }
  }

  /// Build horizontal scrollable date picker
  Widget _buildDateCalendar() {
    final today = DateTime.now();
    final dates = List.generate(
      30,
      (index) => today.add(Duration(days: index + 1)),
    );

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected =
              _selectedDate.year == date.year &&
              _selectedDate.month == date.month &&
              _selectedDate.day == date.day;
          final isAvailable = _isDateAvailable(date);
          final dayOfWeek = DayOfWeek.fromDateTime(date);

          return GestureDetector(
            onTap: isAvailable
                ? () {
                    setState(() {
                      _selectedDate = date;
                      // Auto-select first available time slot
                      final slots = _getAvailableSlotsForDate(date);
                      if (slots.isNotEmpty) {
                        _startTime = slots.first.startTime;
                      }
                    });
                  }
                : null,
            child: Container(
              width: 60,
              margin: EdgeInsets.only(right: 8, left: index == 0 ? 0 : 0),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isAvailable
                    ? AppColors.surface
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : isAvailable
                      ? AppColors.border
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayOfWeek.shortName,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : isAvailable
                          ? AppColors.textSecondary
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : isAvailable
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM', 'vi').format(date),
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : isAvailable
                          ? AppColors.textSecondary
                          : AppColors.textHint,
                    ),
                  ),
                  if (!isAvailable)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 30 * index),
            duration: const Duration(milliseconds: 200),
          );
        },
      ),
    );
  }

  /// Build available time slots chips
  Widget _buildAvailableTimeSlots(List<TimeSlot> slots) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Ionicons.time_outline, size: 14, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                slot.displayString,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build no slots message
  Widget _buildNoSlotsMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Ionicons.calendar_outline, color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_partner?.displayName ?? 'Partner'} không nhận lịch ngày này',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vui lòng chọn ngày khác',
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

  /// Select time from available slots
  Future<void> _selectTimeFromSlots(List<TimeSlot> slots) async {
    // Generate available times from slots
    final availableTimes = <TimeOfDay>[];
    for (final slot in slots) {
      var current = slot.startTime;
      while (current.hour < slot.endTime.hour ||
          (current.hour == slot.endTime.hour &&
              current.minute < slot.endTime.minute)) {
        availableTimes.add(current);
        // Increment by 30 minutes
        final newMinute = current.minute + 30;
        if (newMinute >= 60) {
          current = TimeOfDay(hour: current.hour + 1, minute: 0);
        } else {
          current = TimeOfDay(hour: current.hour, minute: newMinute);
        }
      }
    }

    if (availableTimes.isEmpty) return;

    // Show time selection bottom sheet
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TimeSelectionBottomSheet(
        availableTimes: availableTimes,
        selectedTime: _startTime,
        onSelect: (time) {
          setState(() => _startTime = time);
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Show schedule info dialog
  void _showScheduleInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Ionicons.calendar_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lịch làm việc của ${_partner?.displayName ?? 'Partner'}',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Ionicons.close_circle_outline),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                shrinkWrap: true,
                itemCount: DayOfWeek.values.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final day = DayOfWeek.values[index];
                  final dailySchedule =
                      _partnerSchedule.weeklySchedule.schedule[day];
                  final slots = dailySchedule?.timeSlots ?? [];
                  final hasSlots =
                      dailySchedule?.isEnabled == true && slots.isNotEmpty;

                  return Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          day.displayName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: hasSlots
                            ? Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: slots.map((slot) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      slot.displayString,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.success,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            : Text(
                                'Nghỉ',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element - kept for optional date picker usage
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      selectableDayPredicate: (date) => _isDateAvailable(date),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Auto-select first available time
        final slots = _getAvailableSlotsForDate(picked);
        if (slots.isNotEmpty) {
          _startTime = slots.first.startTime;
        }
      });
    }
  }

  // ignore: unused_element - kept for optional time picker usage
  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }
}

/// Bottom sheet for time selection
class _TimeSelectionBottomSheet extends StatelessWidget {
  final List<TimeOfDay> availableTimes;
  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onSelect;

  const _TimeSelectionBottomSheet({
    required this.availableTimes,
    required this.selectedTime,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Ionicons.time_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Chọn giờ bắt đầu',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: availableTimes.length,
              itemBuilder: (context, index) {
                final time = availableTimes[index];
                final isSelected =
                    time.hour == selectedTime.hour &&
                    time.minute == selectedTime.minute;

                return GestureDetector(
                  onTap: () => onSelect(time),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                        style: AppTypography.labelMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _DurationButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: onTap != null ? Colors.white : AppColors.textHint,
          size: 18,
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)
              : AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
        ),
        Text(
          value,
          style: isTotal
              ? AppTypography.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                )
              : AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _LocationOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _ConfirmationBottomSheet extends StatelessWidget {
  final PartnerDetailResponse? partner;
  final String service;
  final DateTime date;
  final TimeOfDay startTime;
  final int duration;
  final String location;
  final int totalAmount;
  final VoidCallback onConfirm;

  const _ConfirmationBottomSheet({
    required this.partner,
    required this.service,
    required this.date,
    required this.startTime,
    required this.duration,
    required this.location,
    required this.totalAmount,
    required this.onConfirm,
  });

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Ionicons.wallet_outline,
              size: 40,
              color: AppColors.primary,
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),

          const SizedBox(height: 20),

          Text(
            'Xác nhận thanh toán',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Bạn sẽ thanh toán ${_formatPrice(totalAmount)}đ cho lịch hẹn này',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: ImageUtils.buildImageUrl(
                      partner?.avatarUrl ?? '',
                    ),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.backgroundLight),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.backgroundLight,
                      child: const Icon(Ionicons.person_outline),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner?.displayName ?? 'Partner',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$service • $duration giờ',
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

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(text: 'Thanh toán', onPressed: onConfirm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final VoidCallback onViewBooking;
  final VoidCallback onBackHome;

  const _SuccessDialog({required this.onViewBooking, required this.onBackHome});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Ionicons.checkmark_circle_outline,
                size: 56,
                color: AppColors.success,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

            const SizedBox(height: 24),

            Text(
              'Đặt lịch thành công!',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 12),

            Text(
              'Lịch hẹn của bạn đã được gửi đến Partner. Vui lòng chờ xác nhận.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),

            AppButton(
              text: 'Xem lịch hẹn',
              onPressed: onViewBooking,
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 12),

            TextButton(
              onPressed: onBackHome,
              child: Text(
                'Về trang chủ',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
