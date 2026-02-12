import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/constants/service_type_emoji.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../favorites/data/favorites_repository.dart';
import '../../../home/data/home_repository.dart';
import '../../domain/entities/partner_entity.dart';

/// Trang chi tiết Partner - Modern UI Design 2026
/// Không dùng SliverAppBar, hiển thị gallery rõ ràng hơn
class PartnerDetailPage extends StatefulWidget {
  final String partnerId;

  const PartnerDetailPage({super.key, required this.partnerId});

  @override
  State<PartnerDetailPage> createState() => _PartnerDetailPageState();
}

class _PartnerDetailPageState extends State<PartnerDetailPage>
    with TickerProviderStateMixin {
  PartnerEntity? _partner;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isFavoriteLoading = false;
  String? _currentUserId;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _selectedAboutTab = 0;
  int _currentGalleryIndex = 0;
  late PageController _galleryController;

  bool get _isOwnProfile =>
      _currentUserId != null && _currentUserId == widget.partnerId;

  @override
  void initState() {
    super.initState();
    _currentUserId = LocalStorageService.instance.userId;
    _galleryController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _loadPartner();
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _galleryController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final repository = getIt<FavoritesRepository>();
      final isFav = await repository.isFavorite(widget.partnerId);
      if (mounted) setState(() => _isFavorite = isFav);
    } catch (e) {
      debugPrint('Check favorite error: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavoriteLoading) return;
    HapticFeedback.mediumImpact();
    setState(() => _isFavoriteLoading = true);
    try {
      final repository = getIt<FavoritesRepository>();
      if (_isFavorite) {
        await repository.removeFavorite(widget.partnerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đã xóa khỏi danh sách yêu thích'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        await repository.addFavorite(widget.partnerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đã thêm vào danh sách yêu thích'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFavoriteLoading = false);
    }
  }

  Future<void> _loadPartner() async {
    setState(() => _isLoading = true);
    try {
      final repository = getIt<HomeRepository>();
      _partner = await repository.getPartnerById(widget.partnerId);
      _fadeController.forward();
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Không thể tải thông tin';
        if (e is DioException && e.response?.statusCode == 403) {
          errorMessage = e.response?.data?['message'] ??
              'Không thể xem hồ sơ người dùng này';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
            ),
          );
          context.pop();
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errorMessage: $e')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: _isLoading
          ? _buildLoading()
          : _partner == null
              ? _buildErrorState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadPartner();
                      await _checkFavoriteStatus();
                    },
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildImageGalleryHeader(),
                          _buildProfileCard(),
                          _buildContent(),
                        ],
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar:
          _partner != null && !_isLoading ? _buildModernBottomBar() : null,
    );
  }

  /// Header với gallery ảnh có thể vuốt
  Widget _buildImageGalleryHeader() {
    final gallery = _partner!.gallery.isNotEmpty
        ? _partner!.gallery
        : [_partner!.avatarUrl];

    return Stack(
      children: [
        // Gallery PageView
        SizedBox(
          height: 420,
          child: PageView.builder(
            controller: _galleryController,
            onPageChanged: (index) {
              setState(() => _currentGalleryIndex = index);
            },
            itemCount: gallery.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImageViewer(gallery, index),
                child: CachedNetworkImage(
                  imageUrl: ImageUtils.buildImageUrl(gallery[index]),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceDark,
                    child: const Icon(
                      Ionicons.image_outline,
                      size: 48,
                      color: Colors.white24,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Gradient overlay at top for status bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Back and action buttons
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGlassButton(
                icon: Ionicons.chevron_back_outline,
                onTap: () => context.pop(),
              ),
              Row(
                children: [
                  _buildGlassButton(
                    icon: Ionicons.share_social_outline,
                    onTap: _showShareSheet,
                  ),
                  const SizedBox(width: 12),
                  _buildGlassButton(
                    icon: _isFavorite ? Icons.favorite : Ionicons.heart_outline,
                    onTap: _isFavoriteLoading ? null : _toggleFavorite,
                    isActive: _isFavorite,
                    isLoading: _isFavoriteLoading,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Premium badge
        if (_partner!.isPremium)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Ionicons.diamond, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Premium',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Gallery indicator and counter
        if (gallery.length > 1)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Photo counter
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.appColors.textPrimary.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Ionicons.images_outline,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '${_currentGalleryIndex + 1} / ${gallery.length}',
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    gallery.length,
                    (index) => GestureDetector(
                      onTap: () {
                        _galleryController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _currentGalleryIndex == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: _currentGalleryIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: context.appColors.textPrimary.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Thumbnail strip at bottom
        if (gallery.length > 1)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: gallery.length,
                itemBuilder: (context, index) {
                  final isSelected = _currentGalleryIndex == index;
                  return GestureDetector(
                    onTap: () {
                      _galleryController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: ImageUtils.buildImageUrl(gallery[index]),
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: context.appColors.textPrimary,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: context.appColors.textPrimary,
                            child: const Icon(Icons.error,
                                size: 16, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    VoidCallback? onTap,
    bool isActive = false,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.error.withOpacity(0.9)
                  : Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: 20,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }

  /// Profile card nằm dưới gallery
  Widget _buildProfileCard() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: context.appColors.textPrimary.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar with online status
                Stack(
                  children: [
                    Hero(
                      tag: 'partner_${_partner!.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.surfaceDark,
                          backgroundImage: CachedNetworkImageProvider(
                            _partner!.avatarUrl.startsWith('http')
                                ? _partner!.avatarUrl
                                : ImageUtils.buildImageUrl(_partner!.avatarUrl),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color:
                              _partner!.isOnline ? AppColors.success : context.appColors.textHint,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.appColors.surface, width: 3),
                          boxShadow: _partner!.isOnline
                              ? [
                                  BoxShadow(
                                    color: AppColors.success.withOpacity(0.5),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Name and info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _partner!.name,
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.appColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_partner!.isVerified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.info,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildMiniTag(
                            '${_partner!.age} tuổi',
                            Ionicons.person_outline,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.appColors.textHint,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _partner!.isOnline
                                ? 'Đang online'
                                : _partner!.onlineStatusText,
                            style: AppTypography.labelSmall.copyWith(
                              color: _partner!.isOnline
                                  ? AppColors.success
                                  : context.appColors.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (_partner!.location != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Ionicons.location_outline,
                                size: 14, color: context.appColors.textHint),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _partner!.location!,
                                style: AppTypography.labelSmall.copyWith(
                                  color: context.appColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_partner!.distance != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _partner!.formattedDistance,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTag(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.appColors.textHint),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.labelSmall.copyWith(
            color: context.appColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStats(),
          const SizedBox(height: 20),
          _buildPricingCard(),
          const SizedBox(height: 20),
          _buildServicesSection(),
          const SizedBox(height: 20),
          _buildAboutSection(),
          const SizedBox(height: 20),
          _buildReviewsSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.appColors.textPrimary.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildStatItem(
              icon: Ionicons.star,
              value: _partner!.rating.toStringAsFixed(1),
              label: 'Đánh giá',
              color: const Color(0xFFF59E0B),
              iconBgColor: const Color(0xFFFEF3C7),
            ),
            _buildStatDivider(),
            _buildStatItem(
              icon: Ionicons.chatbubble,
              value: '${_partner!.reviewCount}',
              label: 'Reviews',
              color: const Color(0xFF3B82F6),
              iconBgColor: const Color(0xFFDBEAFE),
            ),
            _buildStatDivider(),
            _buildStatItem(
              icon: Ionicons.calendar,
              value: '${_partner!.completedBookings}',
              label: 'Đặt lịch',
              color: const Color(0xFF10B981),
              iconBgColor: const Color(0xFFD1FAE5),
            ),
            _buildStatDivider(),
            _buildStatItem(
              icon: Ionicons.flash,
              value: '${_partner!.responseRate}%',
              label: 'Phản hồi',
              color: const Color(0xFF8B5CF6),
              iconBgColor: const Color(0xFFEDE9FE),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color iconBgColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: context.appColors.textHint,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: context.appColors.border.withOpacity(0.5),
    );
  }

  Widget _buildPricingCard() {
    final currency = _partner!.currency ?? 'VND';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giá dịch vụ',
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _partner!.formattedHourlyRate,
                            style: AppTypography.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$currency/giờ',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_partner!.workingHours != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.appColors.surface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Ionicons.time_outline,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _partner!.workingHours!,
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (_partner!.minimumHours != null ||
                _partner!.experienceYears != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appColors.surface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    if (_partner!.minimumHours != null &&
                        _partner!.minimumHours! > 0)
                      _buildPricingInfo(
                        Ionicons.hourglass_outline,
                        'Tối thiểu ${_partner!.minimumHours}h',
                      ),
                    if (_partner!.experienceYears != null &&
                        _partner!.experienceYears! > 0) ...[
                      if (_partner!.minimumHours != null) _buildInfoDot(),
                      _buildPricingInfo(
                        Ionicons.ribbon_outline,
                        '${_partner!.experienceYears} năm KN',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingInfo(IconData icon, String text) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDot() {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: context.appColors.surface.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildServicesSection() {
    final serviceList = _partner!.serviceTypesDetail ?? _partner!.services;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Dịch vụ', Ionicons.grid_outline),
        const SizedBox(height: 12),
        if (serviceList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.appColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'Chưa cập nhật dịch vụ',
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.appColors.textHint,
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: serviceList.length,
              itemBuilder: (context, index) {
                final item = serviceList[index];
                final nameVi = item is Map<String, dynamic>
                    ? (item['nameVi'] ?? item['name'] ?? '').toString()
                    : ServiceTypeEmoji.get(item.toString()).nameVi;
                final emoji = item is Map<String, dynamic>
                    ? (item['icon'] ?? '➕').toString()
                    : ServiceTypeEmoji.get(item.toString()).emoji;

                final gradientColors = _getServiceGradient(index);

                return Container(
                  width: 110,
                  margin: EdgeInsets.only(
                      right: index < serviceList.length - 1 ? 12 : 0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.appColors.surface.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          nameVi,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  List<Color> _getServiceGradient(int index) {
    final gradients = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFFF59E0B), const Color(0xFFF97316)],
      [const Color(0xFF10B981), const Color(0xFF14B8A6)],
      [const Color(0xFFEC4899), const Color(0xFFF43F5E)],
      [const Color(0xFF3B82F6), const Color(0xFF0EA5E9)],
      [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
    ];
    return gradients[index % gradients.length];
  }

  Widget _buildAboutSection() {
    final tabs = <String>['Giới thiệu', 'Sở thích', 'Ngôn ngữ'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Về tôi', Ionicons.information_circle_outline),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: context.appColors.textPrimary.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: tabs.asMap().entries.map((entry) {
                      final isSelected = _selectedAboutTab == entry.key;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedAboutTab = entry.key);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: context.appColors.textPrimary.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              entry.value,
                              textAlign: TextAlign.center,
                              style: AppTypography.labelMedium.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : context.appColors.textHint,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    key: ValueKey(_selectedAboutTab),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    child: _buildAboutTabContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutTabContent() {
    switch (_selectedAboutTab) {
      case 0:
        return _buildBioContent();
      case 1:
        return _buildInterestsContent();
      case 2:
        return _buildLanguagesContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBioContent() {
    final bio = _partner!.bio;
    final talents = _partner!.talentsDetail ?? _partner!.talents;

    if ((bio == null || bio.isEmpty) && talents.isEmpty) {
      return _buildEmptyState('Chưa có thông tin giới thiệu');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bio != null && bio.isNotEmpty) ...[
          Text(
            bio,
            style: AppTypography.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
              height: 1.6,
            ),
          ),
          if (talents.isNotEmpty) const SizedBox(height: 20),
        ],
        if (talents.isNotEmpty) ...[
          Text(
            'Tài năng',
            style: AppTypography.labelMedium.copyWith(
              color: context.appColors.textHint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_partner!.talentsDetail ??
                    _partner!.talents
                        .map((e) => <String, dynamic>{'nameVi': e, 'icon': null})
                        .toList())
                .map<Widget>((e) {
              final label = (e['nameVi'] ?? e['name'] ?? '').toString();
              final icon = e['icon'] as String?;
              return _buildTag(label, icon, const Color(0xFF8B5CF6));
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildInterestsContent() {
    final interests = _partner!.interestsDetail ?? _partner!.interests;

    if (interests.isEmpty) {
      return _buildEmptyState('Chưa cập nhật sở thích');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: (_partner!.interestsDetail ??
              _partner!.interests
                  .map((e) => <String, dynamic>{'nameVi': e, 'icon': null})
                  .toList())
          .map<Widget>((e) {
        final label = (e['nameVi'] ?? e['name'] ?? '').toString();
        final icon = e['icon'] as String?;
        return _buildTag(label, icon, AppColors.primary);
      }).toList(),
    );
  }

  Widget _buildLanguagesContent() {
    final languages = _partner!.languages;

    if (languages.isEmpty) {
      return _buildEmptyState('Chưa cập nhật ngôn ngữ');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: languages
          .map((e) => _buildTag(e, '🌐', const Color(0xFF3B82F6)))
          .toList(),
    );
  }

  Widget _buildTag(String label, String? icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Ionicons.document_text_outline,
            size: 40,
            color: context.appColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: context.appColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Đánh giá',
          Ionicons.star_outline,
          trailing: '${_partner!.reviewCount} reviews',
          onTap: () {
            HapticFeedback.mediumImpact();
            context.push('/partner/${_partner!.id}/reviews');
          },
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: context.appColors.textPrimary.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildRatingOverview(),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                if (_partner!.reviews.isNotEmpty)
                  _buildSampleReview(_partner!.reviews.first)
                else
                  _buildEmptyState('Chưa có đánh giá nào'),
                if (_partner!.reviews.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.push('/partner/${_partner!.id}/reviews');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side:
                            BorderSide(color: AppColors.primary.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Xem tất cả đánh giá',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingOverview() {
    return Row(
      children: [
        Column(
          children: [
            Text(
              _partner!.rating.toStringAsFixed(1),
              style: AppTypography.headlineLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: context.appColors.textPrimary,
                fontSize: 48,
              ),
            ),
            Row(
              children: List.generate(5, (i) {
                final filled = i < _partner!.rating.floor();
                final partial =
                    i == _partner!.rating.floor() && _partner!.rating % 1 > 0;
                return Icon(
                  filled || partial
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 20,
                  color: const Color(0xFFF59E0B),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              '${_partner!.reviewCount} đánh giá',
              style: AppTypography.labelSmall.copyWith(
                color: context.appColors.textHint,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [5, 4, 3, 2, 1].map((star) {
              final percent = star == 5
                  ? 0.7
                  : star == 4
                      ? 0.2
                      : star == 3
                          ? 0.07
                          : star == 2
                              ? 0.02
                              : 0.01;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(
                      '$star',
                      style: AppTypography.labelSmall.copyWith(
                        color: context.appColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded,
                        size: 12, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: context.appColors.background,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: percent,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSampleReview(ReviewEntity review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: review.userAvatar != null
                      ? CachedNetworkImageProvider(
                          ImageUtils.buildImageUrl(review.userAvatar!),
                        )
                      : null,
                  child: review.userAvatar == null
                      ? Icon(Ionicons.person_outline,
                          size: 18, color: AppColors.primary)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    Text(
                      review.timeAgo,
                      style: AppTypography.labelSmall.copyWith(
                        color: context.appColors.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              review.comment,
              style: AppTypography.bodySmall.copyWith(
                color: context.appColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon,
      {String? trailing, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: context.appColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (trailing != null || onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  if (trailing != null)
                    Text(
                      trailing,
                      style: AppTypography.labelMedium.copyWith(
                        color: context.appColors.textHint,
                      ),
                    ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Ionicons.chevron_forward_outline,
                      size: 16,
                      color: context.appColors.textHint,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        boxShadow: [
          BoxShadow(
            color: context.appColors.textPrimary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!_isOwnProfile) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: () => context
                    .push('/chat/user/${_partner!.userId ?? _partner!.id}'),
                icon: const Icon(Ionicons.chatbubble_outline),
                color: AppColors.primary,
                iconSize: 24,
                padding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: _isOwnProfile
                ? Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.appColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Ionicons.person_outline,
                          size: 20,
                          color: context.appColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Đây là hồ sơ của bạn',
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context
                              .push('/booking/create?partnerId=${_partner!.id}');
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Ionicons.calendar_outline,
                              size: 22,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Đặt lịch ngay',
                              style: AppTypography.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang tải hồ sơ...',
            style: AppTypography.bodyMedium.copyWith(
              color: context.appColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IconButton(
                onPressed: () => context.pop(),
                style: IconButton.styleFrom(
                  backgroundColor: context.appColors.background,
                ),
                icon: const Icon(Ionicons.chevron_back_outline),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Ionicons.person_remove_outline,
                        size: 56,
                        color: AppColors.error.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Không thể tải hồ sơ',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hồ sơ không khả dụng hoặc bạn không có quyền xem.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.appColors.textHint,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => context.pop(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Ionicons.chevron_back_outline),
                      label: const Text('Quay lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration:   BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chia sẻ hồ sơ',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareOption(
                    Ionicons.copy_outline, 'Sao chép', const Color(0xFF6366F1)),
                _shareOption(Ionicons.chatbubble_outline, 'Tin nhắn',
                    const Color(0xFF10B981)),
                _shareOption(Icons.facebook, 'Facebook', const Color(0xFF1877F2)),
                _shareOption(Icons.share, 'Khác', const Color(0xFF64748B)),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _shareOption(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: context.appColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showImageViewer(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: context.appColors.textPrimary,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenGallery(
            images: images,
            initialIndex: initialIndex,
            partnerId: _partner!.id,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String partnerId;

  const _FullScreenGallery({
    required this.images,
    required this.initialIndex,
    required this.partnerId,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.appColors.surface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: context.appColors.surface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_currentIndex + 1} / ${widget.images.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: ImageUtils.buildImageUrl(widget.images[index]),
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 48),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.images.length > 1
          ? Container(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
