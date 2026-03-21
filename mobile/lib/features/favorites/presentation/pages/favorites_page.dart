import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';
import '../../../home/presentation/widgets/home_partner_card.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_event.dart';
import '../bloc/favorites_state.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FavoritesView();
  }
}

class _FavoritesView extends StatefulWidget {
  const _FavoritesView();

  @override
  State<_FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<_FavoritesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<FavoritesBloc>();
      if (bloc.state.status == FavoritesStatus.initial ||
          bloc.state.favorites.isEmpty) {
        bloc.add(const FavoritesLoadRequested());
      }
    });
  }

  Future<void> _onRefresh(BuildContext context) async {
    context.read<FavoritesBloc>().add(const FavoritesRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        title: Text(
          'Yêu thích',
          style: AppTypography.titleLarge.copyWith(
            color: context.appColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: context.appColors.background,
      ),
      body: BlocConsumer<FavoritesBloc, FavoritesState>(
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
          if (state.status == FavoritesStatus.initial ||
              state.status == FavoritesStatus.loading) {
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

          final crossAxisCount = ResponsiveLayout.gridCrossAxisCount(
            context,
            minCellWidth: 280,
            horizontalPadding: ResponsiveLayout.horizontalPadding(context) * 2,
            spacing: 16,
          );
          final padding = ResponsiveLayout.pagePadding(context);
          return RefreshIndicator(
            onRefresh: () => _onRefresh(context),
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              cacheExtent: 1200,
              padding: padding.copyWith(
                top: padding.top,
                bottom: padding.bottom + 24,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.67,
              ),
              itemCount: state.favorites.length,
              itemBuilder: (context, index) {
                final favorite = state.favorites[index];
                final partner = favorite.partner;
                return RepaintBoundary(
                  child: GestureDetector(
                    onTap: () {
                      context.push('/partner/${partner.id}');
                    },
                    child: HomePartnerCard(
                      key: ValueKey(partner.id),
                      partner: partner,
                    ),
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
              color: context.appColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Ionicons.heart_outline,
              size: 48,
              color: context.appColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          Text('Chưa có yêu thích', style: AppTypography.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu lưu những Partner bạn thích',
            style: AppTypography.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
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
          const Icon(
            Ionicons.alert_circle_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
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
