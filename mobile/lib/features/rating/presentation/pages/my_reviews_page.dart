import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
      create: (_) => getIt<MyReviewsBloc>()
        ..add(const MyReviewsLoadRequested()),
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
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Đánh giá của tôi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tôi đánh giá'),
            Tab(text: 'Nhận được'),
          ],
        ),
      ),
      body: BlocConsumer<MyReviewsBloc, MyReviewsState>(
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
                  const Icon(Ionicons.alert_circle_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.errorMessage ?? 'Đã xảy ra lỗi'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MyReviewsBloc>().add(const MyReviewsRefreshRequested());
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<MyReviewsBloc>().add(const MyReviewsRefreshRequested());
            },
            child: TabBarView(
              controller: _tabController,
              children: [
                // Given Reviews Tab
                _buildReviewsList(state.givenReviews, isGiven: true),
                // Received Reviews Tab
                _buildReviewsList(state.receivedReviews, isGiven: false),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsList(List<ReviewModel> reviews, {required bool isGiven}) {
    if (reviews.isEmpty) {
      return _EmptyState(
        icon: Ionicons.star_outline,
        title: 'Chưa có đánh giá',
        subtitle: isGiven 
          ? 'Bạn chưa đánh giá Partner nào'
          : 'Bạn chưa nhận được đánh giá nào',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ReviewCard(
            name: isGiven ? (review.partnerName ?? 'Partner') : (review.userName ?? 'User'),
            avatar: isGiven ? (review.partnerAvatar ?? '') : (review.userAvatar ?? ''),
            rating: review.overallRating,
            comment: review.comment ?? '',
            date: review.formattedDate,
            serviceType: review.serviceType ?? '',
          ),
        );
      },
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: CachedNetworkImageProvider(avatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            serviceType,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rating Stars
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Ionicons.star_outline : Ionicons.star_outline,
                color: index < rating ? AppColors.starFilled : AppColors.starEmpty,
                size: 20,
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
              color: AppColors.backgroundLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTypography.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
