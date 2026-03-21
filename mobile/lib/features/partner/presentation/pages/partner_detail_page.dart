import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../../favorites/presentation/bloc/favorites_event.dart';
import '../../../favorites/presentation/bloc/favorites_state.dart';
import '../../../settings/data/app_config_repository.dart';
import '../../../subscription/presentation/widgets/premium_guard.dart';
import '../../data/partner_repository.dart';
import '../bloc/partner_detail_bloc.dart';
import '../bloc/partner_detail_event.dart';
import '../bloc/partner_detail_state.dart';
import '../widgets/fullscreen_image_viewer.dart';
import '../widgets/partner_detail_bottom_bar.dart';
import '../widgets/partner_detail_header.dart';
import '../widgets/partner_info_sections.dart';
import '../widgets/partner_stats_section.dart';

class PartnerDetailPage extends StatelessWidget {
  const PartnerDetailPage({super.key, required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PartnerDetailBloc(
        partnerRepository: getIt<PartnerRepository>(),
      )..add(LoadPartnerDetail(partnerId: partnerId)),
      child: _PartnerDetailView(partnerId: partnerId),
    );
  }
}

class _PartnerDetailView extends StatelessWidget {
  const _PartnerDetailView({required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: BlocBuilder<PartnerDetailBloc, PartnerDetailState>(
        builder: (context, state) {
          if (state is PartnerDetailLoading) {
            return _buildLoading(context);
          }

          if (state is PartnerDetailError) {
            return _buildError(context, state);
          }

          if (state is PartnerDetailLoaded) {
            return _buildContent(context, state.detail);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildError(BuildContext context, PartnerDetailError state) {
    return SafeArea(
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Ionicons.chevron_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: ResponsiveLayout.pagePadding(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Ionicons.alert_circle_outline,
                      size: 64,
                      color: context.appColors.textHint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: AppTypography.bodyLarge.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<PartnerDetailBloc>()
                            .add(LoadPartnerDetail(partnerId: partnerId));
                      },
                      icon: const Icon(Ionicons.refresh_outline),
                      label: const Text('Thử lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  Widget _buildContent(BuildContext context, PartnerDetailResponse detail) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, favState) {
        final isFavorite =
            favState.favorites.any((f) => f.partnerId == detail.profile.userId);

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                context
                    .read<PartnerDetailBloc>()
                    .add(RefreshPartnerDetail(partnerId: partnerId));
              },
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  PartnerDetailHeader(
                    detail: detail,
                    isFavorite: isFavorite,
                    onBack: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    onShare: () => _sharePartner(context, detail),
                    onFavorite: () =>
                        _toggleFavorite(context, detail, isFavorite),
                    onImageTap: (index) => _openImageViewer(context, detail, index),
                  ),

              // Content sections
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Quick stats
                    PartnerStatsSection(detail: detail),

                    const SizedBox(height: 16),

                

 
                    // About / Introduction
                    PartnerAboutSection(detail: detail),

                    const SizedBox(height: 16),

                    // Services
                    PartnerServicesSection(detail: detail),

                    const SizedBox(height: 16),

                    // Interests
                    PartnerInterestsSection(detail: detail),

                    const SizedBox(height: 16),

                    // Talents
                    PartnerTalentsSection(detail: detail),

                    const SizedBox(height: 16),

                    // Languages
                    PartnerLanguagesSection(detail: detail),

                    const SizedBox(height: 16),

                    // Reviews preview
                    _buildReviewsPreview(context, detail),

                    // Bottom padding for bottom bar
                    SizedBox(
                      height:
                          MediaQuery.of(context).padding.bottom + 80,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom action bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: PartnerDetailBottomBar(
            detail: detail,
            onChat: () => _navigateToChat(context, detail),
            onBook: detail.profile.isAvailable
                ? () => _navigateToBooking(context, detail)
                : null,
          ),
        ),
      ],
    );
      },
    );
  }

  Widget _buildReviewsPreview(
    BuildContext context,
    PartnerDetailResponse detail,
  ) {
    final reviewStats = detail.reviewStats;
    final averageRating = reviewStats?.averageRating ?? detail.profile.averageRating;
    final totalReviews = reviewStats?.totalReviews ?? detail.profile.totalReviews;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveLayout.horizontalPadding(context)),
      padding: ResponsiveLayout.pagePadding(context),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.starFilled.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Ionicons.star, size: 16, color: AppColors.starFilled),
              ),
              const SizedBox(width: 10),
              Text(
                'Đánh giá',
                style: AppTypography.titleMedium.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Navigate to reviews page
                  final reviewUserId = detail.userId ?? detail.profile.userId;
                  context.push('/partner/$reviewUserId/reviews');
                },
                child: Row(
                  children: [
                    Text(
                      'Xem tất cả',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Ionicons.chevron_forward,
                        size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Rating summary
          Row(
            children: [
              Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: AppTypography.displaySmall.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final rating = averageRating;
                      return Icon(
                        starValue <= rating
                            ? Ionicons.star
                            : starValue - 0.5 <= rating
                                ? Ionicons.star_half
                                : Ionicons.star_outline,
                        size: 16,
                        color: starValue <= rating
                            ? AppColors.starFilled
                            : (starValue - 0.5 <= rating
                                ? AppColors.starFilled
                                : AppColors.starEmpty),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviews đánh giá',
                    style: AppTypography.bodySmall.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(context, '5', reviewStats?.getPercentage(5) ?? 0),
                    _buildRatingBar(context, '4', reviewStats?.getPercentage(4) ?? 0),
                    _buildRatingBar(context, '3', reviewStats?.getPercentage(3) ?? 0),
                    _buildRatingBar(context, '2', reviewStats?.getPercentage(2) ?? 0),
                    _buildRatingBar(context, '1', reviewStats?.getPercentage(1) ?? 0),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(BuildContext context, String star, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(
              star,
              style: AppTypography.labelSmall.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: context.appColors.divider,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.starFilled),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(BuildContext context, PartnerDetailResponse detail) {
    final userId = detail.profile.userId;
    context.push('/chat/user/$userId');
  }

  void _navigateToBooking(BuildContext context, PartnerDetailResponse detail) {
    AuthGuard.requireAuth(
      context,
      message: 'Đăng nhập để gửi lời mời.',
      onAuthenticated: () async {
        // Kiểm tra setting có yêu cầu premium cho booking không
        final requirePremium =
            await getIt<AppConfigRepository>().requirePremiumForBooking();

        if (!context.mounted) return;

        if (requirePremium && !PremiumGuard.isPremium(context)) {
          final wantUpgrade = await PremiumGuard.showPremiumDialog(
            context,
            title: 'Cần đăng ký Premium',
            message:
                'Tính năng này yêu cầu gói Premium. Nâng cấp để gửi lời mời!',
          );
          if (wantUpgrade && context.mounted) {
            await context.push('/premium');
          }
          return;
        }

        if (!context.mounted) return;
        context.push(
          RouteNames.createBooking,
          extra: {'partnerId': detail.profile.userId},
        );
      },
    );
  }

  void _sharePartner(BuildContext context, PartnerDetailResponse detail) {
    final shareUrl = ApiConfig.partnerShareUrl(detail.profile.userId);
    final partnerName = detail.userProfile?.fullName ?? 'Partner';
    final shareText = 'Xem hồ sơ của $partnerName trên Mate Social:\n$shareUrl';

    final box = context.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        text: shareText,
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  }

  void _toggleFavorite(
    BuildContext context,
    PartnerDetailResponse detail,
    bool isFavorite,
  ) {
    if (!AuthGuard.isAuthenticated) {
      AuthGuard.requireAuth(
        context,
        message: 'Đăng nhập để thêm yêu thích',
        onAuthenticated: () {},
      );
      return;
    }
    final bloc = context.read<FavoritesBloc>();
    if (isFavorite) {
      bloc.add(FavoriteRemoveRequested(detail.profile.userId));
    } else {
      bloc.add(FavoriteAddRequested(detail.profile.userId));
    }
  }

  void _openImageViewer(
    BuildContext context,
    PartnerDetailResponse detail,
    int initialIndex,
  ) {
    final allPhotos = <String>[];
    allPhotos.addAll(detail.photos);
    if (detail.avatarUrl != null && detail.avatarUrl!.isNotEmpty) {
      allPhotos.add(detail.avatarUrl!);
    }
    final uniquePhotos = allPhotos.toSet().toList();

    if (uniquePhotos.isEmpty) return;

    FullscreenImageViewer.show(
      context,
      imageUrls: uniquePhotos,
      initialIndex: initialIndex.clamp(0, uniquePhotos.length - 1),
    );
  }

}