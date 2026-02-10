import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../data/partner_repository.dart';
import '../bloc/partner_reviews_bloc.dart';
import '../bloc/partner_reviews_event.dart';
import '../bloc/partner_reviews_state.dart';

/// Trang đánh giá Partner
class PartnerReviewsPage extends StatelessWidget {
  final String partnerId;

  const PartnerReviewsPage({super.key, required this.partnerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PartnerReviewsBloc(
        partnerRepository: getIt<PartnerRepository>(),
      )..add(const PartnerReviewsLoadRequested()),
      child: const _PartnerReviewsContent(),
    );
  }
}

class _PartnerReviewsContent extends StatefulWidget {
  const _PartnerReviewsContent();

  @override
  State<_PartnerReviewsContent> createState() => _PartnerReviewsContentState();
}

class _PartnerReviewsContentState extends State<_PartnerReviewsContent> {
  String _selectedFilter = 'all';

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    
    // Trigger API call with new filter
    final minRating = filter == 'all' ? null : filter;
    context.read<PartnerReviewsBloc>().add(
          PartnerReviewsFilterChanged(minRating: minRating),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBackButton(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Ionicons.star_outline, size: 22, color: AppColors.starFilled),
            const SizedBox(width: 8),
            Text(
              'Đánh giá',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<PartnerReviewsBloc, PartnerReviewsState>(
        listener: (context, state) {
          if (state is PartnerReviewsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PartnerReviewsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is PartnerReviewsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Ionicons.alert_circle_outline,
                    size: 64,
                   ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      context
                          .read<PartnerReviewsBloc>()
                          .add(const PartnerReviewsLoadRequested());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is PartnerReviewsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<PartnerReviewsBloc>()
                    .add(const PartnerReviewsRefreshRequested());
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Rating Summary
                  SliverToBoxAdapter(
                    child: _buildRatingSummary(state.stats),
                  ),

                  // Filter Chips
                  SliverToBoxAdapter(child: _buildFilterChips()),

                  // Reviews List: khi đổi filter chỉ load list, giữ nguyên summary
                  if (state.isFiltering)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Đang lọc đánh giá...',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (state.reviews.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.starFilled.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Ionicons.star_outline,
                                size: 48,
                                color: AppColors.starFilled,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Chưa có đánh giá nào',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final review = state.reviews[index];
                            return _buildReviewCard(review, index);
                          },
                          childCount: state.reviews.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildRatingSummary(ReviewStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Big Rating with icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.starFilled.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      stats.averageRating.toStringAsFixed(1),
                      style: AppTypography.displaySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Ionicons.star,
                      color: AppColors.starFilled,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final ratingFloor = stats.averageRating.floor();
                    return Icon(
                      index < ratingFloor
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.starFilled,
                      size: 14,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.totalReviews} đánh giá',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Rating Bars
          Expanded(child: _buildRatingBars(stats)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildRatingBars(ReviewStats stats) {
    final ratings = [5, 4, 3, 2, 1];

    return Column(
      children: List.generate(5, (index) {
        final starCount = ratings[index];
        final percentage = (stats.getPercentage(starCount) * 100).toInt();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  '${ratings[index]}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Icon(
                Icons.star_rounded,
                color: AppColors.starFilled,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.starFilled,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  '$percentage%',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'value': 'all', 'label': 'Tất cả', 'stars': null},
      {'value': '5', 'label': '5', 'stars': 5},
      {'value': '4', 'label': '4', 'stars': 4},
      {'value': '3', 'label': '3', 'stars': 3},
      {'value': '2', 'label': '2', 'stars': 2},
      {'value': '1', 'label': '1', 'stars': 1},
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final value = filter['value'] as String;
          final isSelected = _selectedFilter == value;
          final starCount = filter['stars'] as int?;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _onFilterChanged(value);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter['label'] as String,
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  if (starCount != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.starFilled,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(PartnerReview review, int index) {
    final dateStr = _formatRelativeDate(review.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar, name, date, rating badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                backgroundImage: review.reviewer.avatarUrl != null
                    ? CachedNetworkImageProvider(review.reviewer.avatarUrl!)
                    : null,
                child: review.reviewer.avatarUrl == null
                    ? Icon(Ionicons.person_outline, size: 22, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewer.name,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Ionicons.time_outline, size: 12, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Rating badge with icon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.starFilled.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.starFilled,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${review.overallRating.toInt()}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Comment
          if (review.comment != null && review.comment!.isNotEmpty)
            Text(
              review.comment!,
              style: AppTypography.bodyMedium.copyWith(
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            )
          else
            Row(
              children: [
                Icon(Ionicons.chatbubble_outline, size: 16, color: AppColors.textHint),
                const SizedBox(width: 6),
                Text(
                  'Không có nhận xét',
                  style: AppTypography.bodyMedium.copyWith(
                    height: 1.55,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),

          // Sub-ratings if available
          if (review.punctualityRating != null ||
              review.communicationRating != null ||
              review.personalityRating != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (review.punctualityRating != null)
                  _buildSubRatingChip(Ionicons.time_outline, 'Đúng giờ', review.punctualityRating!),
                if (review.communicationRating != null)
                  _buildSubRatingChip(Ionicons.chatbubbles_outline, 'Giao tiếp', review.communicationRating!),
                if (review.personalityRating != null)
                  _buildSubRatingChip(Ionicons.happy_outline, 'Tính cách', review.personalityRating!),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
  }

  Widget _buildSubRatingChip(IconData icon, String label, double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.star_rounded, size: 12, color: AppColors.starFilled),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks tuần trước';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years năm trước';
    }
  }
}
