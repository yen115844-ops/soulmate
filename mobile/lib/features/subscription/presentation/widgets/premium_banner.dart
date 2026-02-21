import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';

/// Premium color palette
class _PremiumColors {
  static const goldLight = Color(0xFFFFE082);
  static const gold = Color(0xFFFFD54F);
  static const goldDark = Color(0xFFFFC107);
  static const amber = Color(0xFFFF8F00);
  static const deepOrange = Color(0xFFFF6D00);
  
  static const gradientPrimary = LinearGradient(
    colors: [goldDark, amber, deepOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Premium Banner Widget - displays on home page to promote Premium
/// Shows different content based on user's premium status
class PremiumBanner extends StatelessWidget {
  const PremiumBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SubscriptionBloc>()
        ..add(const SubscriptionStatusRequested()),
      child: const _PremiumBannerContent(),
    );
  }
}

class _PremiumBannerContent extends StatefulWidget {
  const _PremiumBannerContent();

  @override
  State<_PremiumBannerContent> createState() => _PremiumBannerContentState();
}

class _PremiumBannerContentState extends State<_PremiumBannerContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, state) {
        // Don't show banner if already premium
        if (state.premiumStatus?.isPremium == true) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => context.push('/premium'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _PremiumColors.amber.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Dark gradient background
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1A1A2E),
                          Color(0xFF16213E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Animated diamond icon
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: _PremiumColors.gradientPrimary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _PremiumColors.gold.withValues(alpha: 0.5 + (_animationController.value * 0.2)),
                                    blurRadius: 16 + (_animationController.value * 8),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.diamond_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),

                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Shimmer title
                              AnimatedBuilder(
                                animation: _shimmerAnimation,
                                builder: (context, child) {
                                  return ShaderMask(
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        begin: Alignment(_shimmerAnimation.value - 1, 0),
                                        end: Alignment(_shimmerAnimation.value, 0),
                                        colors: const [
                                          _PremiumColors.gold,
                                          _PremiumColors.goldLight,
                                          _PremiumColors.gold,
                                        ],
                                      ).createShader(bounds);
                                    },
                                    child: Text(
                                      'Trở thành VIP',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Ionicons.infinite,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Chat thoải mái, tăng cơ hội ghép đôi',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // CTA button
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: _PremiumColors.gradientPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Xem',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Decorative elements
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _PremiumColors.gold.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: 50,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _PremiumColors.amber.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Compact Premium Badge - shows in app bar or profile
class PremiumBadge extends StatelessWidget {
  final bool isPremium;
  final VoidCallback? onTap;

  const PremiumBadge({
    super.key,
    required this.isPremium,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Premium',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap ?? () => context.push('/premium'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFFA500)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              color: Color(0xFFFFA500),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Nâng cấp',
              style: AppTypography.labelSmall.copyWith(
                color: const Color(0xFFFFA500),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating Premium Button - can be used as FAB
class PremiumFloatingButton extends StatelessWidget {
  const PremiumFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SubscriptionBloc>()
        ..add(const SubscriptionStatusRequested()),
      child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, state) {
          // Don't show if already premium
          if (state.premiumStatus?.isPremium == true) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => context.push('/premium'),
            backgroundColor: const Color(0xFFFFA500),
            icon: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
            ),
            label: Text(
              'Premium',
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}
