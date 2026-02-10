import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../partner/domain/entities/partner_entity.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../domain/home_filter.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

/// Trang Home - Hiển thị danh sách partner cards vô tận
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Load profile if not already loaded
    final profileBloc = getIt<ProfileBloc>();
    if (profileBloc.state is ProfileInitial) {
      profileBloc.add(const ProfileLoadRequested());
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<HomeBloc>()..add(const HomeLoadPartners()),
        ),
        BlocProvider.value(value: profileBloc),
      ],
      child: const _HomePageView(),
    );
  }
}

class _HomePageView extends StatefulWidget {
  const _HomePageView();

  @override
  State<_HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<_HomePageView>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final bloc = context.read<HomeBloc>();
      if (bloc.state.hasMore && !bloc.state.isLoadingMore) {
        bloc.add(const HomeLoadMore());
      }
    }
  }

  void _onPartnerTap(PartnerEntity partner) {
    HapticFeedback.mediumImpact();
    context.push('/partner/${partner.id}');
  }

  void _showFilter(BuildContext context) {
    final currentFilter = context.read<HomeBloc>().state.filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<HomeBloc>(),
        child: _FilterBottomSheet(currentFilter: currentFilter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state.hasError && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Background gradient
              _buildBackground(),

              // Main Content
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // App Bar
                    _buildAppBar(context),

                    // Cards Area
                    Expanded(
                      child: state.isLoading
                          ? _buildLoading()
                          : _buildCardsView(state.partners),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFF6B6B).withOpacity(0.12),
              const Color(0xFFFF8E53).withOpacity(0.08),
              const Color(0xFFF8F9FA),
              const Color(0xFFF8F9FA),
            ],
            stops: const [0.0, 0.2, 0.4, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Avatar - Using ProfileBloc for current user avatar
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, profileState) {
              String? avatarUrl;
              if (profileState is ProfileLoaded) {
                avatarUrl = profileState.avatarUrl;
              }

              return GestureDetector(
                onTap: () => context.push(RouteNames.profile),
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: ClipOval(
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: ImageUtils.buildImageUrl(avatarUrl),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.surface,
                                child: Icon(
                                  Ionicons.person_outline,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.surface,
                                child: Icon(
                                  Ionicons.person_outline,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                            )
                          : Icon(
                              Ionicons.person_outline,
                              color: AppColors.primary,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              );
            },
          ),

          const Spacer(),

          // Logo
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
            ).createShader(bounds),
            child: Text(
              'Mate',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const Spacer(),

          // Action buttons
          _AppBarButton(
            icon: Ionicons.people_outline,
            onTap: () => context.push(RouteNames.favorites),
          ),
          const SizedBox(width: 10),
          _AppBarButton(
            icon: Ionicons.chatbubble_outline,
            onTap: () => context.push(RouteNames.chat),
          ),
          const SizedBox(width: 10),
          _AppBarButton(
            icon: Ionicons.options_outline,
            onTap: () => _showFilter(context),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) => Transform.scale(
              scale: 1 + (_pulseController.value * 0.1),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Icon(
                  Ionicons.heart_outline,
                  size: 48,
                  color: AppColors.primary.withOpacity(
                    0.4 + (_pulseController.value * 0.6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang tìm partner...',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsView(List<PartnerEntity> partners) {
    if (partners.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<HomeBloc>().add(const HomeLoadPartners(refresh: true));
      },
      color: AppColors.primary,
      child: MasonryGridView.count(
        controller: _scrollController,
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount:
            partners.length +
            (context.read<HomeBloc>().state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at the bottom
          if (index >= partners.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final partner = partners[index];
          // Tạo chiều cao ngẫu nhiên cho hiệu ứng staggered
          final heights = [200.0, 250.0, 280.0, 220.0, 260.0];
          final height = heights[index % heights.length];

          return GestureDetector(
                onTap: () => _onPartnerTap(partner),
                child: _PartnerGridCard(partner: partner, height: height),
              )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 50 * (index % 10)),
                duration: const Duration(milliseconds: 300),
              )
              .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Ionicons.search_outline,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Không tìm thấy partner',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Hãy thử điều chỉnh bộ lọc',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _showFilter(context),
              icon: const Icon(Ionicons.options_outline, size: 20),
              label: const Text('Mở bộ lọc'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AppBar Button Widget
class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final int? badge;
  final VoidCallback onTap;

  const _AppBarButton({required this.icon, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: AppColors.textPrimary, size: 21)),
            if (badge != null && badge! > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge! > 9 ? '9+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Filter Bottom Sheet
class _FilterBottomSheet extends StatefulWidget {
  final HomeFilter currentFilter;

  const _FilterBottomSheet({required this.currentFilter});

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late double _distance;
  late RangeValues _ageRange;
  late Set<String> _selectedServices;
  late bool _verifiedOnly;
  late bool _onlineOnly;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    // Initialize from current filter
    final filter = widget.currentFilter;
    _distance = filter.radius?.toDouble() ?? 10;
    _ageRange = RangeValues(
      filter.minAge?.toDouble() ?? 18,
      filter.maxAge?.toDouble() ?? 35,
    );
    _selectedServices = filter.serviceType != null ? {filter.serviceType!} : {};
    _verifiedOnly = filter.verifiedOnly;
    _onlineOnly = filter.availableNow;
    _sortBy = filter.sortBy;
  }

  final List<String> _services = [
    'Cà phê',
    'Xem phim',
    'Ăn tối',
    'Đi dạo',
    'Dự tiệc',
    'Du lịch',
    'Shopping',
    'Thể thao',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
            child: Row(
              children: [
                Text(
                  'Bộ lọc',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Đặt lại',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filters
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distance
                  _buildSection(
                    title: 'Khoảng cách',
                    value: '${_distance.round()} km',
                    child: SliderTheme(
                      data: _sliderTheme,
                      child: Slider(
                        value: _distance,
                        min: 1,
                        max: 50,
                        onChanged: (v) => setState(() => _distance = v),
                      ),
                    ),
                  ),

                  // Age Range
                  _buildSection(
                    title: 'Độ tuổi',
                    value:
                        '${_ageRange.start.round()} - ${_ageRange.end.round()}',
                    child: SliderTheme(
                      data: _sliderTheme,
                      child: RangeSlider(
                        values: _ageRange,
                        min: 18,
                        max: 50,
                        onChanged: (v) => setState(() => _ageRange = v),
                      ),
                    ),
                  ),

                  // Services
                  _buildSection(
                    title: 'Dịch vụ',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _services.map((s) {
                        final selected = _selectedServices.contains(s);
                        return _ServiceChip(
                          label: s,
                          selected: selected,
                          onTap: () => _toggleService(s),
                        );
                      }).toList(),
                    ),
                  ),

                  // Verified Only
                  _buildSection(
                    title: 'Chỉ hiện đã xác minh',
                    trailing: Switch(
                      value: _verifiedOnly,
                      onChanged: (v) => setState(() => _verifiedOnly = v),
                      activeColor: AppColors.primary,
                    ),
                    child: const SizedBox.shrink(),
                  ),

                  // Online Only
                  _buildSection(
                    title: 'Chỉ hiện online',
                    trailing: Switch(
                      value: _onlineOnly,
                      onChanged: (v) => setState(() => _onlineOnly = v),
                      activeColor: AppColors.primary,
                    ),
                    child: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // Apply Button
          _buildApplyButton(),
        ],
      ),
    );
  }

  SliderThemeData get _sliderTheme => SliderTheme.of(context).copyWith(
    activeTrackColor: AppColors.primary,
    inactiveTrackColor: AppColors.primary.withOpacity(0.2),
    thumbColor: AppColors.primary,
    overlayColor: AppColors.primary.withOpacity(0.1),
    trackHeight: 4,
  );

  void _resetFilters() {
    setState(() {
      _distance = 10;
      _ageRange = const RangeValues(18, 35);
      _selectedServices = {};
      _verifiedOnly = false;
      _onlineOnly = false;
      _sortBy = 'rating';
    });
  }

  void _toggleService(String service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  Widget _buildSection({
    required String title,
    String? value,
    Widget? trailing,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 10),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (trailing != null) ...[const Spacer(), trailing],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _applyFilter,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Áp dụng bộ lọc',
              style: AppTypography.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _applyFilter() {
    final filter = HomeFilter(
      radius: _distance.round(),
      minAge: _ageRange.start.round(),
      maxAge: _ageRange.end.round(),
      serviceType: _selectedServices.isNotEmpty
          ? _selectedServices.first
          : null,
      verifiedOnly: _verifiedOnly,
      availableNow: _onlineOnly,
      sortBy: _sortBy,
    );

    context.read<HomeBloc>().add(HomeApplyFilter(filter));
    Navigator.pop(context);
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Partner Grid Card Widget - Dành cho Staggered Grid View
class _PartnerGridCard extends StatelessWidget {
  final PartnerEntity partner;
  final double height;

  const _PartnerGridCard({required this.partner, required this.height});

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Hero(
              tag: 'partner_${partner.id}',
              child: CachedNetworkImage(
                imageUrl: ImageUtils.buildImageUrl(
                  partner.gallery.isNotEmpty
                      ? partner.gallery.first
                      : partner.avatarUrl,
                ),
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 40, color: Colors.grey),
                ),
              ),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),

            // Top Badges
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  // Online Badge
                  if (partner.isOnline)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D26A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Online',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Premium Badge
                  if (partner.isPremium) ...[
                    if (partner.isOnline) const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Ionicons.ribbon,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Verified Badge
                  if (partner.isVerified)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name & Age
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${partner.name}, ${partner.age}',
                            style: AppTypography.titleSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Rating
                    Row(
                      children: [
                        const Icon(
                          Ionicons.star,
                          size: 12,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          partner.rating.toStringAsFixed(1),
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' (${partner.reviewCount})',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${priceFormat.format(partner.hourlyRate)}/h',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
