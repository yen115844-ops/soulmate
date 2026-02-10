import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/cards/booking_card.dart';
import '../../../../shared/widgets/common/pull_to_refresh.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../../shared/widgets/states/error_state.dart';
import '../../domain/entities/booking_entity.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<BookingBloc>()..add(const BookingLoadRequested()),
      child: const _BookingsPageContent(),
    );
  }
}

class _BookingsPageContent extends StatefulWidget {
  const _BookingsPageContent();

  @override
  State<_BookingsPageContent> createState() => _BookingsPageContentState();
}

class _BookingsPageContentState extends State<_BookingsPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollControllerUpcoming = ScrollController();
  final ScrollController _scrollControllerPast = ScrollController();

  /// Tháng đang xem trên lịch (tab Lịch sử) — lướt trái/phải đổi tháng
  DateTime _focusedHistoryMonth = DateTime.now();
  /// Ngày được chọn trên lịch — null = chưa chọn, chọn thì mở rộng danh sách
  DateTime? _selectedHistoryDay;

  /// Tab Lịch sử: 1 = danh sách + bộ lọc, 2 = chỉ lịch, chọn ngày mới mở rộng
  bool _historyCalendarView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollControllerUpcoming.addListener(_onUpcomingScroll);
    _scrollControllerPast.addListener(_onPastScroll);
  }

  @override
  void dispose() {
    _scrollControllerUpcoming.removeListener(_onUpcomingScroll);
    _scrollControllerPast.removeListener(_onPastScroll);
    _scrollControllerUpcoming.dispose();
    _scrollControllerPast.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onUpcomingScroll() {
    _checkLoadMore(_scrollControllerUpcoming);
  }

  void _onPastScroll() {
    _checkLoadMore(_scrollControllerPast);
  }

  void _checkLoadMore(ScrollController controller) {
    final bloc = context.read<BookingBloc>();
    final state = bloc.state;
    if (state is! BookingLoaded || state.isLoadingMore || !state.hasMore) return;
    final threshold = 200.0;
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - threshold) {
      bloc.add(const BookingLoadMoreRequested());
    }
  }

  Future<void> _onRefresh() async {
    context.read<BookingBloc>().add(const BookingRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Lịch hẹn của tôi',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Ionicons.filter_outline),
            tooltip: 'Bộ lọc chi tiết',
            onPressed: _showDetailedFilter,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: BlocBuilder<BookingBloc, BookingState>(
            builder: (context, state) {
              final upcomingCount = state is BookingLoaded
                  ? state.upcomingBookings.length
                  : 0;
              return TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sắp tới'),
                        if (upcomingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$upcomingCount',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Lịch sử'),
                ],
              );
            },
          ),
        ),
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BookingError) {
            return ErrorStateWidget(
              onRetry: () =>
                  context.read<BookingBloc>().add(const BookingLoadRequested()),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [_buildUpcomingTab(state), _buildPastTab(state)],
          );
        },
      ),
    );
  }

  Widget _buildUpcomingTab(BookingState state) {
    if (state is BookingLoading || state is BookingInitial) {
      return _buildLoadingShimmer();
    }

    if (state is! BookingLoaded) {
      return const SizedBox.shrink();
    }

    if (state.upcomingBookings.isEmpty) {
      return NoBookingsWidget(
        onFindPartner: () => context.go(RouteNames.home, extra: {'initialPage': 1}),
      );
    }

    return PullToRefresh(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollControllerUpcoming,
        padding: const EdgeInsets.all(16),
        itemCount: state.upcomingBookings.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.upcomingBookings.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final booking = state.upcomingBookings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child:
                BookingCard(
                      id: booking.id,
                      partnerName: booking.partnerName,
                      partnerAvatar: booking.partnerAvatar ?? '',
                      service: booking.serviceType,
                      date: booking.formattedDate,
                      time: booking.formattedTimeRange,
                      status: booking.status.toLowerCase(),
                      totalAmount: booking.totalAmount,
                      onTap: () async {
                        await context.push('/booking/${booking.id}');
                        if (context.mounted) {
                          context.read<BookingBloc>().add(const BookingRefreshRequested());
                        }
                      },
                    )
                    .animate(delay: Duration(milliseconds: 80 * index))
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, duration: 300.ms),
          );
        },
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Tập ngày (chỉ y-m-d) có ít nhất một lịch hẹn đã qua — dùng đánh dấu trên lịch
  static Set<DateTime> _datesWithPastBookings(List<BookingEntity> pastBookings) {
    final set = <DateTime>{};
    for (final b in pastBookings) {
      set.add(DateTime(b.startTime.year, b.startTime.month, b.startTime.day));
    }
    return set;
  }

  Widget _buildPastTab(BookingState state) {
    if (state is BookingLoading || state is BookingInitial) {
      return _buildLoadingShimmer();
    }

    if (state is! BookingLoaded) {
      return const SizedBox.shrink();
    }

    final pastBookings = state.pastBookings;

    return PullToRefresh(
      onRefresh: _onRefresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toggle: Danh sách | Lịch
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _HistoryViewChip(
                    icon: Ionicons.checkbox_outline,
                    label: 'Danh sách',
                    selected: !_historyCalendarView,
                    onTap: () => setState(() {
                      _historyCalendarView = false;
                      _selectedHistoryDay = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HistoryViewChip(
                    icon: Ionicons.calendar_outline,
                    label: 'Lịch',
                    selected: _historyCalendarView,
                    onTap: () => setState(() => _historyCalendarView = true),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _historyCalendarView
                ? _buildPastCalendarView(state, pastBookings)
                : _buildPastListView(state, pastBookings),
          ),
        ],
      ),
    );
  }

  /// View 1: Danh sách tất cả + bộ lọc (filter dùng chung ở app bar)
  Widget _buildPastListView(
    BookingLoaded state,
    List<BookingEntity> pastBookings,
  ) {
    if (pastBookings.isEmpty) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: EmptyStateWidget(
          icon: Ionicons.calendar_outline,
          title: 'Chưa có lịch sử',
          message: 'Các lịch hẹn đã hoàn thành sẽ hiển thị ở đây',
          showButton: false,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollControllerPast,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: pastBookings.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= pastBookings.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final booking = pastBookings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BookingCard(
            id: booking.id,
            partnerName: booking.partnerName,
            partnerAvatar: booking.partnerAvatar ?? '',
            service: booking.serviceType,
            date: booking.formattedDate,
            time: booking.formattedTimeRange,
            status: booking.status.toLowerCase(),
            totalAmount: booking.totalAmount,
            onTap: () async {
              await context.push('/booking/${booking.id}');
              if (context.mounted) {
                context.read<BookingBloc>().add(const BookingRefreshRequested());
              }
            },
          )
              .animate(delay: Duration(milliseconds: 80 * index))
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, duration: 300.ms),
        );
      },
    );
  }

  /// View 2: Chỉ lịch; chọn ngày thì mở rộng danh sách ngày đó
  Widget _buildPastCalendarView(
    BookingLoaded state,
    List<BookingEntity> pastBookings,
  ) {
    final datesWithBookings = _datesWithPastBookings(pastBookings);
    final bookingsForSelectedDay = _selectedHistoryDay == null
        ? <BookingEntity>[]
        : pastBookings
            .where((b) => _isSameDay(b.startTime, _selectedHistoryDay!))
            .toList();

    return SingleChildScrollView(
      controller: _scrollControllerPast,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chỉ lịch tháng
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar<Object?>(
              firstDay: DateTime.now().subtract(const Duration(days: 365 * 2)),
              lastDay: DateTime.now(),
              focusedDay: _focusedHistoryMonth,
              currentDay: DateTime.now(),
              locale: 'vi',
              calendarFormat: CalendarFormat.month,
              eventLoader: (day) {
                final d = DateTime(day.year, day.month, day.day);
                return datesWithBookings.any((x) => _isSameDay(x, d))
                    ? [true]
                    : [];
              },
              selectedDayPredicate: (day) =>
                  _selectedHistoryDay != null &&
                  _isSameDay(day, _selectedHistoryDay!),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _focusedHistoryMonth = focusedDay;
                  if (_selectedHistoryDay != null &&
                      _isSameDay(selectedDay, _selectedHistoryDay!)) {
                    _selectedHistoryDay = null;
                  } else {
                    _selectedHistoryDay = selectedDay;
                  }
                });
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedHistoryMonth = focusedDay);
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) =>
                    DateFormat.yMMMM(locale).format(date),
                titleTextStyle: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                leftChevronIcon: const Icon(
                  Ionicons.chevron_back_outline,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                rightChevronIcon: const Icon(
                  Ionicons.chevron_forward_outline,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                weekendTextStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                markerDecoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                outsideTextStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;
                  return Positioned(
                    bottom: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Mở rộng khi chọn ngày
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: _selectedHistoryDay == null
                ? const SizedBox.shrink()
                : Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(_selectedHistoryDay!),
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Ionicons.close_circle_outline),
                              onPressed: () =>
                                  setState(() => _selectedHistoryDay = null),
                              color: AppColors.textHint,
                              iconSize: 22,
                            ),
                          ],
                        ),
                        if (bookingsForSelectedDay.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Không có lịch hẹn trong ngày này',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          )
                        else
                          ...bookingsForSelectedDay.asMap().entries.map((e) {
                            final booking = e.value;
                            final i = e.key;
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: BookingCard(
                                id: booking.id,
                                partnerName: booking.partnerName,
                                partnerAvatar: booking.partnerAvatar ?? '',
                                service: booking.serviceType,
                                date: booking.formattedDate,
                                time: booking.formattedTimeRange,
                                status: booking.status.toLowerCase(),
                                totalAmount: booking.totalAmount,
                                onTap: () async {
                                  await context.push('/booking/${booking.id}');
                                  if (context.mounted) {
                                    context.read<BookingBloc>().add(const BookingRefreshRequested());
                                  }
                                },
                              )
                                  .animate(delay: Duration(milliseconds: 50 * i))
                                  .fadeIn(duration: 200.ms)
                                  .slideY(begin: 0.05, duration: 200.ms),
                            );
                          }),
                      ],
                    ),
                  ),
          ),
          if (pastBookings.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyStateWidget(
                icon: Ionicons.calendar_outline,
                title: 'Chưa có lịch sử',
                message: 'Các lịch hẹn đã hoàn thành sẽ hiển thị ở đây',
                showButton: false,
              ),
            )
          else if (_selectedHistoryDay == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Chọn một ngày có dấu chấm để xem lịch hẹn',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: BookingCardShimmer(),
      ),
    );
  }

  void _showDetailedFilter() {
    final bloc = context.read<BookingBloc>();
    final currentState = bloc.state;
    String? selectedFilterType = currentState is BookingLoaded
        ? currentState.dateFilterType
        : null;
    String? selectedStatus = currentState is BookingLoaded
        ? currentState.currentFilter
        : null;
    DateTime? customStart = currentState is BookingLoaded
        ? currentState.startDate
        : null;
    DateTime? customEnd = currentState is BookingLoaded
        ? currentState.endDate
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (builderContext, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(builderContext).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bộ lọc chi tiết',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(builderContext),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Trạng thái
                Text(
                  'Trạng thái',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip(
                      label: 'Tất cả',
                      filterType: null,
                      isSelected: selectedStatus == null,
                      onSelected: () {
                        setModalState(() => selectedStatus = null);
                      },
                    ),
                    ..._statusFilterOptions.map((e) => _buildFilterChip(
                          label: e.label,
                          filterType: e.status,
                          isSelected: selectedStatus == e.status,
                          onSelected: () {
                            setModalState(() => selectedStatus = e.status);
                          },
                        )),
                  ],
                ),
                const SizedBox(height: 24),
                // Thời gian
                Text(
                  'Thời gian',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip(
                      label: 'Tất cả',
                      filterType: null,
                      isSelected: selectedFilterType == null,
                      onSelected: () {
                        setModalState(() => selectedFilterType = null);
                      },
                    ),
                    _buildFilterChip(
                      label: 'Hôm nay',
                      filterType: 'today',
                      isSelected: selectedFilterType == 'today',
                      onSelected: () {
                        setModalState(() => selectedFilterType = 'today');
                      },
                    ),
                    _buildFilterChip(
                      label: 'Tuần này',
                      filterType: 'week',
                      isSelected: selectedFilterType == 'week',
                      onSelected: () {
                        setModalState(() => selectedFilterType = 'week');
                      },
                    ),
                    _buildFilterChip(
                      label: 'Tháng này',
                      filterType: 'month',
                      isSelected: selectedFilterType == 'month',
                      onSelected: () {
                        setModalState(() => selectedFilterType = 'month');
                      },
                    ),
                    _buildFilterChip(
                      label: 'Chọn ngày',
                      filterType: 'custom',
                      isSelected: selectedFilterType == 'custom',
                      onSelected: () async {
                        final dateRange = await showDateRangePicker(
                          context: builderContext,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          locale: const Locale('vi', 'VN'),
                        );
                        if (dateRange != null) {
                          setModalState(() {
                            selectedFilterType = 'custom';
                            customStart = dateRange.start;
                            customEnd = dateRange.end;
                          });
                          bloc.add(
                            BookingFilterChanged(
                              status: selectedStatus,
                              dateFilterType: 'custom',
                              startDate: dateRange.start,
                              endDate: dateRange.end,
                            ),
                          );
                          Navigator.pop(builderContext);
                        }
                      },
                    ),
                  ],
                ),
                if (selectedFilterType == 'custom' &&
                    customStart != null &&
                    customEnd != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_formatDate(customStart!)} – ${_formatDate(customEnd!)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(builderContext);
                          bloc.add(const BookingFilterChanged(
                            status: null,
                            dateFilterType: null,
                          ));
                        },
                        child: const Text('Đặt lại'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(builderContext);
                          if (selectedFilterType == null && selectedStatus == null) {
                            bloc.add(const BookingLoadRequested(refresh: true));
                          } else {
                            bloc.add(
                              BookingFilterChanged(
                                status: selectedStatus,
                                dateFilterType: selectedFilterType,
                                startDate: selectedFilterType == 'custom'
                                    ? customStart
                                    : null,
                                endDate: selectedFilterType == 'custom'
                                    ? customEnd
                                    : null,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(builderContext).padding.bottom + 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    return '$day/$month/$year';
  }

  static const List<({String label, String status})> _statusFilterOptions = [
    (label: 'Chờ xác nhận', status: 'PENDING'),
    (label: 'Đã xác nhận', status: 'CONFIRMED'),
    (label: 'Đã thanh toán', status: 'PAID'),
    (label: 'Đang diễn ra', status: 'IN_PROGRESS'),
    (label: 'Hoàn thành', status: 'COMPLETED'),
    (label: 'Đã hủy', status: 'CANCELLED'),
    (label: 'Bị từ chối', status: 'REJECTED'),
  ];

  Widget _buildFilterChip({
    required String label,
    required String? filterType,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

/// Chip chọn view Lịch sử: Danh sách | Lịch
class _HistoryViewChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryViewChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.15)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
