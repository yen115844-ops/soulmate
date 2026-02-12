import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/theme_context.dart';
import '../../domain/models/partner_schedule.dart';

/// Trang cài đặt lịch làm việc cho Partner
/// - Cài đặt theo tuần (Thứ 2 - CN)
/// - Cài đặt khung giờ cho mỗi ngày
/// - Nghỉ lễ/ngày đặc biệt theo tháng
class ScheduleSettingsPage extends StatefulWidget {
  const ScheduleSettingsPage({super.key});

  @override
  State<ScheduleSettingsPage> createState() => _ScheduleSettingsPageState();
}

class _ScheduleSettingsPageState extends State<ScheduleSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Lịch theo tuần
  Map<DayOfWeek, List<TimeSlot>> _weeklySchedule = {};
  
  // Ngày nghỉ đặc biệt
  final Set<DateTime> _blockedDates = {};
  
  // Ngày được chọn trong calendar
  DateTime _selectedMonth = DateTime.now();
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSchedule() {
    // Mock data - sẽ load từ API
    setState(() {
      _weeklySchedule = {
        DayOfWeek.monday: [
          TimeSlot(
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 12, minute: 0),
          ),
          TimeSlot(
            startTime: const TimeOfDay(hour: 14, minute: 0),
            endTime: const TimeOfDay(hour: 18, minute: 0),
          ),
        ],
        DayOfWeek.tuesday: [
          TimeSlot(
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 17, minute: 0),
          ),
        ],
        DayOfWeek.wednesday: [
          TimeSlot(
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 17, minute: 0),
          ),
        ],
        DayOfWeek.thursday: [
          TimeSlot(
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 17, minute: 0),
          ),
        ],
        DayOfWeek.friday: [
          TimeSlot(
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 17, minute: 0),
          ),
        ],
        DayOfWeek.saturday: [],
        DayOfWeek.sunday: [],
      };
    });
  }

  Future<void> _saveSchedule() async {
    setState(() => _isLoading = true);
    
    // Mock save - sẽ gọi API
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isLoading = false;
      _hasChanges = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Ionicons.checkmark_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Đã lưu lịch làm việc'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _setChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt lịch làm việc'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Ionicons.calendar_outline),
              text: 'Lịch theo tuần',
            ),
            Tab(
              icon: Icon(Ionicons.calendar_outline),
              text: 'Ngày nghỉ',
            ),
          ],
        ),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isLoading ? null : _saveSchedule,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Ionicons.checkmark_circle_outline),
              label: const Text('Lưu'),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWeeklyScheduleTab(theme),
          _buildBlockedDatesTab(theme),
        ],
      ),
    );
  }

  Widget _buildWeeklyScheduleTab(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: DayOfWeek.values.length,
      itemBuilder: (context, index) {
        final day = DayOfWeek.values[index];
        final slots = _weeklySchedule[day] ?? [];
        final isEnabled = slots.isNotEmpty;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              // Header - ngày trong tuần
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: isEnabled 
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  child: Text(
                    day.shortName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: isEnabled 
                          ? theme.colorScheme.primary 
                          : context.appColors.textHint,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  day.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isEnabled 
                      ? '${slots.length} khung giờ'
                      : 'Nghỉ',
                  style: TextStyle(
                    color: isEnabled ? Colors.green : context.appColors.textHint,
                  ),
                ),
                trailing: Switch(
                  value: isEnabled,
                  onChanged: (value) {
                    setState(() {
                      if (value) {
                        _weeklySchedule[day] = [
                          TimeSlot(
                            startTime: const TimeOfDay(hour: 9, minute: 0),
                            endTime: const TimeOfDay(hour: 17, minute: 0),
                          ),
                        ];
                      } else {
                        _weeklySchedule[day] = [];
                      }
                    });
                    _setChanged();
                  },
                ),
              ),
              
              // Time slots
              if (isEnabled) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ...slots.asMap().entries.map((entry) {
                        final slotIndex = entry.key;
                        final slot = entry.value;
                        
                        return _TimeSlotRow(
                          slot: slot,
                          onStartChanged: (time) {
                            setState(() {
                              slots[slotIndex] = TimeSlot(
                                startTime: time,
                                endTime: slot.endTime,
                              );
                            });
                            _setChanged();
                          },
                          onEndChanged: (time) {
                            setState(() {
                              slots[slotIndex] = TimeSlot(
                                startTime: slot.startTime,
                                endTime: time,
                              );
                            });
                            _setChanged();
                          },
                          onRemove: () {
                            setState(() {
                              slots.removeAt(slotIndex);
                              if (slots.isEmpty) {
                                _weeklySchedule[day] = [];
                              }
                            });
                            _setChanged();
                          },
                        );
                      }),
                      
                      // Add slot button
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            slots.add(TimeSlot(
                              startTime: const TimeOfDay(hour: 9, minute: 0),
                              endTime: const TimeOfDay(hour: 17, minute: 0),
                            ));
                          });
                          _setChanged();
                        },
                        icon: const Icon(Ionicons.add_outline, size: 18),
                        label: const Text('Thêm khung giờ'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(36),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(
          delay: Duration(milliseconds: index * 50),
          duration: const Duration(milliseconds: 300),
        );
      },
    );
  }

  Widget _buildBlockedDatesTab(ThemeData theme) {
    return Column(
      children: [
        // Month navigation
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                  });
                },
                icon: const Icon(Ionicons.chevron_back_outline),
              ),
              Text(
                DateFormat('MMMM yyyy', 'vi_VN').format(_selectedMonth),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                  });
                },
                icon: const Icon(Ionicons.chevron_forward_outline),
              ),
            ],
          ),
        ),
        
        // Calendar grid
        Expanded(
          child: _buildCalendarGrid(theme),
        ),
        
        // Legend
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                color: theme.colorScheme.primary,
                label: 'Làm việc',
              ),
              const SizedBox(width: 24),
              _buildLegendItem(
                color: Colors.red,
                label: 'Nghỉ',
              ),
              const SizedBox(width: 24),
              _buildLegendItem(
                color: context.appColors.border,
                label: 'Quá hạn',
              ),
            ],
          ),
        ),
        
        // Tip
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Ionicons.information_circle_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nhấn vào ngày để đánh dấu nghỉ/làm việc',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(ThemeData theme) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    // Weekday headers
    const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    
    return Column(
      children: [
        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      color: context.appColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        
        // Calendar days
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 42, // 6 weeks
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              
              if (dayOffset < 1 || dayOffset > daysInMonth) {
                return const SizedBox.shrink();
              }
              
              final date = DateTime(
                _selectedMonth.year,
                _selectedMonth.month,
                dayOffset,
              );
              final isToday = _isToday(date);
              final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
              final isBlocked = _blockedDates.any((d) => 
                d.year == date.year && d.month == date.month && d.day == date.day);
              
              // Check if this day has schedule based on weekly schedule
              final dayOfWeek = DayOfWeek.values[(date.weekday - 1) % 7];
              final hasSchedule = (_weeklySchedule[dayOfWeek] ?? []).isNotEmpty;
              
              return GestureDetector(
                onTap: isPast ? null : () {
                  setState(() {
                    if (isBlocked) {
                      _blockedDates.removeWhere((d) =>
                        d.year == date.year && d.month == date.month && d.day == date.day);
                    } else {
                      _blockedDates.add(date);
                    }
                  });
                  _setChanged();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isPast
                        ? context.appColors.border
                        : isBlocked
                            ? Colors.red.withOpacity(0.2)
                            : hasSchedule
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : context.appColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        dayOffset.toString(),
                        style: TextStyle(
                          color: isPast
                              ? context.appColors.textHint
                              : isBlocked
                                  ? Colors.red
                                  : hasSchedule
                                      ? theme.colorScheme.primary
                                      : context.appColors.textSecondary,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isBlocked && !isPast)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Icon(
                            Ionicons.close_circle_outline,
                            size: 12,
                            color: Colors.red.shade400,
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
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

/// Widget hiển thị một khung giờ
class _TimeSlotRow extends StatelessWidget {
  final TimeSlot slot;
  final ValueChanged<TimeOfDay> onStartChanged;
  final ValueChanged<TimeOfDay> onEndChanged;
  final VoidCallback onRemove;

  const _TimeSlotRow({
    required this.slot,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TimePickerButton(
              time: slot.startTime,
              label: 'Bắt đầu',
              onChanged: onStartChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Ionicons.chevron_forward_outline,
              size: 20,
              color: context.appColors.textHint,
            ),
          ),
          Expanded(
            child: _TimePickerButton(
              time: slot.endTime,
              label: 'Kết thúc',
              onChanged: onEndChanged,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Ionicons.trash_outline),
            iconSize: 20,
            color: Colors.red,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final TimeOfDay time;
  final String label;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimePickerButton({
    required this.time,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.appColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Ionicons.time_outline,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
