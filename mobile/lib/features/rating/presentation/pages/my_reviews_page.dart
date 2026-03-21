import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../data/models/review_model.dart';
import '../bloc/my_reviews_bloc.dart';
import '../bloc/my_reviews_event.dart';
import '../bloc/my_reviews_state.dart';

class MyReviewsPage extends StatelessWidget {
  const MyReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<MyReviewsBloc>()..add(const MyReviewsLoadRequested()),
      child: const _MyReviewsView(),
    );
  }
}

class _MyReviewsView extends StatefulWidget {
  const _MyReviewsView();

  @override
  State<_MyReviewsView> createState() => _MyReviewsViewState();
}

class _MyReviewsViewState extends State<_MyReviewsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Future<void> _onRefresh() async {
    context.read<MyReviewsBloc>().add(const MyReviewsRefreshRequested());
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(
          'Đánh giá của tôi',
          style: AppTypography.titleLarge.copyWith(
            color: context.appColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: context.appColors.background,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTypography.labelLarge,
          unselectedLabelStyle: AppTypography.labelLarge,
          labelColor: context.appColors.textPrimary,
          unselectedLabelColor: context.appColors.textSecondary,
          indicatorColor: context.appColors.primary,
          indicatorWeight: 3,
          dividerColor: context.appColors.divider,
          tabs: const [
            Tab(text: 'Tôi đánh giá'),
            Tab(text: 'Nhận được'),
          ],
        ),
      ),
      body: BlocConsumer<MyReviewsBloc, MyReviewsState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == MyReviewsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == MyReviewsStatus.error &&
              state.givenReviews.isEmpty &&
              state.receivedReviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Ionicons.alert_circle_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(state.errorMessage ?? 'Đã xảy ra lỗi'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MyReviewsBloc>().add(
                        const MyReviewsRefreshRequested(),
                      );
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildReviewsList(state.givenReviews, isGiven: true),
              _buildReviewsList(state.receivedReviews, isGiven: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReviewsList(List<ReviewModel> reviews, {required bool isGiven}) {
    if (reviews.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.62,
              child: _EmptyState(
                icon: Ionicons.star_outline,
                title: 'Chưa có đánh giá',
                subtitle: isGiven
                    ? 'Bạn chưa đánh giá đối tác nào'
                    : 'Bạn chưa nhận được đánh giá nào',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: ResponsiveLayout.pagePadding(context),
        itemCount: reviews.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final review = reviews[index];
          return _ReviewCard(
            name: isGiven
                ? (review.revieweeName ?? 'Đối tác')
                : (review.reviewerName ?? 'Người dùng'),
            avatar: isGiven
                ? (review.revieweeAvatar ?? '')
                : (review.reviewerAvatar ?? ''),
            rating: review.overallRating,
            comment: review.comment ?? '',
            date: review.formattedDate,
            serviceType: review.serviceType ?? '',
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String avatar;
  final int rating;
  final String comment;
  final String date;
  final String serviceType;

  const _ReviewCard({
    required this.name,
    required this.avatar,
    required this.rating,
    required this.comment,
    required this.date,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    final safeRating = rating.clamp(0, 5);
    final hasComment = comment.trim().isNotEmpty;
    final hasServiceType = serviceType.trim().isNotEmpty;
    final initials = name.trim().isEmpty ? '?' : name.trim().characters.first;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.withAlpha(context.appColors.shadow, 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarView(avatar: avatar, initials: initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (hasServiceType)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.withAlpha(
                                  context.appColors.primary,
                                  0.12,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                serviceType,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSmall.copyWith(
                                  color: context.appColors.primaryDark,
                                ),
                              ),
                            ),
                          ),
                        if (hasServiceType) const SizedBox(width: 8),
                        Text(
                          date,
                          style: AppTypography.labelSmall.copyWith(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < safeRating ? Ionicons.star : Ionicons.star_outline,
                color: index < safeRating
                    ? context.appColors.starFilled
                    : context.appColors.starEmpty,
                size: 18,
              );
            }),
          ),
          if (hasComment) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: context.appColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarView extends StatelessWidget {
  final String avatar;
  final String initials;

  const _AvatarView({required this.avatar, required this.initials});

  @override
  Widget build(BuildContext context) {
    final trimmedAvatar = avatar.trim();
    final hasAvatar = trimmedAvatar.isNotEmpty;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.appColors.background,
        border: Border.all(color: context.appColors.border),
      ),
      child: ClipOval(
        child: hasAvatar
            ? CachedNetworkImage(
                imageUrl: trimmedAvatar,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) =>
                    _AvatarFallback(initials: initials),
              )
            : _AvatarFallback(initials: initials),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;

  const _AvatarFallback({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.background,
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: AppTypography.labelLarge.copyWith(
          color: context.appColors.textHint,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.appColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: context.appColors.textHint),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              color: context.appColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
