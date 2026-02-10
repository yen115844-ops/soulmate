import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/cards/partner_card.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_event.dart';
import '../bloc/favorites_state.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<FavoritesBloc>()..add(const FavoritesLoadRequested()),
      child: const _FavoritesView(),
    );
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Yêu thích')),
      body: BlocConsumer<FavoritesBloc, FavoritesState>(
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
          if (state.status == FavoritesStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == FavoritesStatus.error &&
              state.favorites.isEmpty) {
            return _ErrorState(
              message: state.errorMessage ?? 'Đã xảy ra lỗi',
              onRetry: () {
                context.read<FavoritesBloc>().add(
                  const FavoritesRefreshRequested(),
                );
              },
            );
          }

          if (state.favorites.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<FavoritesBloc>().add(
                const FavoritesRefreshRequested(),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.favorites.length,
              itemBuilder: (context, index) {
                final favorite = state.favorites[index];
                final partner = favorite.partner;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PartnerCard(
                    id: partner.id,
                    name: partner.name,
                    age: partner.age,
                    avatarUrl: partner.avatarUrl,
                    rating: partner.rating,
                    reviews: partner.reviewCount,
                    hourlyRate: partner.formattedHourlyRate,
                    isOnline: partner.isOnline,
                    isVerified: partner.isVerified,
                    isFavorite: true,
                    onTap: () {
                      context.push('/partner/${partner.id}');
                    },
                    onFavorite: () {
                      context.read<FavoritesBloc>().add(
                        FavoriteRemoveRequested(partner.id),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã xóa khỏi danh sách yêu thích'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            child: const Icon(
              Ionicons.heart_outline,
              size: 48,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          Text('Chưa có yêu thích', style: AppTypography.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu lưu những Partner bạn thích',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Ionicons.alert_circle_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
