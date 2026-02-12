import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/partner_repository.dart';
import '../bloc/schedule_settings_bloc.dart';
import '../bloc/schedule_settings_event.dart';
import '../bloc/schedule_settings_state.dart';

/// Trang quản lý lịch rảnh (Availability Slots) cho Partner
/// - Hiển thị calendar view theo tháng
/// - Quản lý các slot khả dụng cho mỗi ngày
/// - Thêm/sửa/xóa slot
class AvailabilitySlotsPage extends StatelessWidget {
  const AvailabilitySlotsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ScheduleSettingsBloc(
        partnerRepository: getIt<PartnerRepository>(),
      )..add(const ScheduleSettingsLoadRequested()),
      child: const _AvailabilitySlotsContent(),
    );
  }
}

class _AvailabilitySlotsContent extends StatefulWidget {
  const _AvailabilitySlotsContent();

  @override
  State<_AvailabilitySlotsContent> createState() =>
      _AvailabilitySlotsContentState();
}

class _AvailabilitySlotsContentState extends State<_AvailabilitySlotsContent> {
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý lịch rảnh'),
        actions: [
          IconButton(
            onPressed: _showHelpDialog,
            icon: const Icon(Ionicons.information_circle_outline),
          ),
        ],
      ),
      body: BlocConsumer<ScheduleSettingsBloc, ScheduleSettingsState>(
        listener: (context, state) {
          if (state is ScheduleSettingsSlotOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is ScheduleSettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ScheduleSettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<AvailabilitySlot> slots = [];
          if (state is ScheduleSettingsLoaded) {
            slots = state.slots;
          } else if (state is ScheduleSettingsSlotOperationInProgress) {
            slots = state.slots;
          } else if (state is ScheduleSettingsSlotOperationSuccess) {
            slots = state.slots;
          } else if (state is ScheduleSettingsError && state.previousSlots != null) {
            slots = state.previousSlots!;
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadSlotsForMonth(_selectedMonth);
            },
            child: Column(
              children: [
                // Month Navigation
                _MonthNavigator(
                  selectedMonth: _selectedMonth,
                  onMonthChanged: (month) {
                    setState(() => _selectedMonth = month);
                    _loadSlotsForMonth(month);
                  },
                ),

                // Calendar View
                Expanded(
                  flex: 2,
                  child: _CalendarView(
                    selectedMonth: _selectedMonth,
                    selectedDate: _selectedDate,
                    slots: slots,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = date);
                    },
                  ),
                ),

                const Divider(height: 1),

                // Slots for selected date
                Expanded(
                  flex: 1,
                  child: _selectedDate != null
                      ? _SlotsListView(
                          date: _selectedDate!,
                          slots: _getSlotsForDate(slots, _selectedDate!),
                          onAddSlot: () => _showAddSlotDialog(_selectedDate!),
                          onDeleteSlot: _deleteSlot,
                        )
                      : const _NoDateSelectedView(),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _selectedDate != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSlotDialog(_selectedDate!),
              icon: const Icon(Ionicons.add_outline),
              label: const Text('Thêm lịch'),
            )
          : null,
    );
  }

  void _loadSlotsForMonth(DateTime month) {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    context.read<ScheduleSettingsBloc>().add(
          ScheduleSettingsGetSlotsRequested(
            startDate: startDate.toIso8601String().split('T').first,
            endDate: endDate.toIso8601String().split('T').first,
          ),
        );
  }

  List<AvailabilitySlot> _getSlotsForDate(
      List<AvailabilitySlot> slots, DateTime date) {
    return slots
        .where((slot) =>
            slot.date.year == date.year &&
            slot.date.month == date.month &&
            slot.date.day == date.day)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void _showAddSlotDialog(DateTime date) {
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thêm khung giờ rảnh',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(date),
                style: AppTypography.bodyMedium.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Time Range
              Row(
                children: [
                  Expanded(
                    child: _TimePickerField(
                      label: 'Bắt đầu',
                      time: startTime,
                      onChanged: (time) {
                        setModalState(() => startTime = time);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Ionicons.chevron_forward_outline, color: context.appColors.textHint),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TimePickerField(
                      label: 'Kết thúc',
                      time: endTime,
                      onChanged: (time) {
                        setModalState(() => endTime = time);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Note
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  hintText: 'Ví dụ: Chỉ nhận cafe date',
                  prefixIcon: const Icon(Ionicons.document_text_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        _createSlot(
                          date: date,
                          startTime: startTime,
                          endTime: endTime,
                          note: noteController.text.isNotEmpty
                              ? noteController.text
                              : null,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Thêm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createSlot({
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? note,
  }) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final startTimeStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    context.read<ScheduleSettingsBloc>().add(
          ScheduleSettingsCreateSlotRequested(
            date: dateStr,
            startTime: startTimeStr,
            endTime: endTimeStr,
            note: note,
          ),
        );
  }

  void _deleteSlot(String slotId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch rảnh'),
        content: const Text('Bạn có chắc muốn xóa khung giờ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ScheduleSettingsBloc>().add(
                    ScheduleSettingsDeleteSlotRequested(slotId: slotId),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Ionicons.information_circle_outline, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Hướng dẫn'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Chọn ngày trên lịch để xem và quản lý lịch rảnh'),
            SizedBox(height: 8),
            Text('• Nhấn nút "Thêm lịch" để thêm khung giờ mới'),
            SizedBox(height: 8),
            Text('• Kéo sang trái để xóa một khung giờ'),
            SizedBox(height: 8),
            Text('• Ngày có lịch rảnh sẽ được đánh dấu màu xanh'),
            SizedBox(height: 8),
            Text('• Khách hàng chỉ có thể đặt lịch trong các khung giờ bạn đã tạo'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}

// ==================== Sub Widgets ====================

class _MonthNavigator extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const _MonthNavigator({
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.appColors.card,
        border: Border(bottom: BorderSide(color: context.appColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              onMonthChanged(
                DateTime(selectedMonth.year, selectedMonth.month - 1),
              );
            },
            icon: const Icon(Ionicons.chevron_back_outline),
          ),
          Text(
            DateFormat('MMMM yyyy', 'vi_VN').format(selectedMonth),
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {
              onMonthChanged(
                DateTime(selectedMonth.year, selectedMonth.month + 1),
              );
            },
            icon: const Icon(Ionicons.chevron_forward_outline),
          ),
        ],
      ),
    );
  }
}

class _CalendarView extends StatelessWidget {
  final DateTime selectedMonth;
  final DateTime? selectedDate;
  final List<AvailabilitySlot> slots;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarView({
    required this.selectedMonth,
    required this.selectedDate,
    required this.slots,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Column(
      children: [
        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: weekdays.map((day) {
              final isWeekend = day == 'T7' || day == 'CN';
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: AppTypography.labelMedium.copyWith(
                      color: isWeekend ? AppColors.error : context.appColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Calendar grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);

              if (dayOffset < 1 || dayOffset > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                selectedMonth.year,
                selectedMonth.month,
                dayOffset,
              );
              final isToday = _isToday(date);
              final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
              final isSelected = selectedDate != null &&
                  date.year == selectedDate!.year &&
                  date.month == selectedDate!.month &&
                  date.day == selectedDate!.day;

              // Check if date has slots
              final hasSlots = slots.any((slot) =>
                  slot.date.year == date.year &&
                  slot.date.month == date.month &&
                  slot.date.day == date.day);

              return GestureDetector(
                onTap: isPast ? null : () => onDateSelected(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : hasSlots
                            ? AppColors.primary.withAlpha(30)
                            : isPast
                                ? context.appColors.shimmerBase
                                : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        dayOffset.toString(),
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.textWhite
                              : isPast
                                  ? context.appColors.textHint
                                  : hasSlots
                                      ? AppColors.primary
                                      : context.appColors.textPrimary,
                          fontWeight: isToday || isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (hasSlots && !isSelected)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _SlotsListView extends StatelessWidget {
  final DateTime date;
  final List<AvailabilitySlot> slots;
  final VoidCallback onAddSlot;
  final ValueChanged<String> onDeleteSlot;

  const _SlotsListView({
    required this.date,
    required this.slots,
    required this.onAddSlot,
    required this.onDeleteSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, dd/MM', 'vi_VN').format(date),
                style: AppTypography.titleSmall,
              ),
              Text(
                '${slots.length} khung giờ',
                style: AppTypography.labelMedium.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: slots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Ionicons.calendar_outline,
                        size: 48,
                        color: context.appColors.textHint,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có lịch rảnh',
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    return Dismissible(
                      key: Key(slot.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Ionicons.trash_outline,
                          color: AppColors.textWhite,
                        ),
                      ),
                      onDismissed: (_) => onDeleteSlot(slot.id),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Xóa lịch rảnh'),
                            content: const Text(
                                'Bạn có chắc muốn xóa khung giờ này?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                ),
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: _SlotCard(slot: slot),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  final AvailabilitySlot slot;

  const _SlotCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: slot.isBooked
            ? AppColors.warning.withAlpha(25)
            : AppColors.success.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: slot.isBooked ? AppColors.warning : AppColors.success,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: slot.isBooked
                  ? AppColors.warning.withAlpha(50)
                  : AppColors.success.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              slot.isBooked ? Ionicons.calendar_outline : Ionicons.time_outline,
              color: slot.isBooked ? AppColors.warning : AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.timeDisplay,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (slot.note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    slot.note!,
                    style: AppTypography.labelSmall.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: slot.isBooked
                  ? AppColors.warning.withAlpha(50)
                  : AppColors.success.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              slot.isBooked ? 'Đã đặt' : 'Rảnh',
              style: AppTypography.labelSmall.copyWith(
                color: slot.isBooked ? AppColors.warning : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoDateSelectedView extends StatelessWidget {
  const _NoDateSelectedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.calendar_outline,
            size: 48,
            color: context.appColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            'Chọn một ngày để xem lịch rảnh',
            style: AppTypography.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimePickerField({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            );
          },
        );
        if (result != null) {
          onChanged(result);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: context.appColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Ionicons.time_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
