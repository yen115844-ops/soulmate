import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Custom Pull to Refresh Wrapper
class PullToRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;

  const PullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.primary,
      backgroundColor: backgroundColor ?? AppColors.surface,
      strokeWidth: 2.5,
      displacement: 40,
      child: child,
    );
  }
}

/// Custom Refresh Indicator with Sliver support
class SliverPullToRefresh extends StatelessWidget {
  final List<Widget> slivers;
  final Future<void> Function() onRefresh;
  final ScrollController? controller;

  const SliverPullToRefresh({
    super.key,
    required this.slivers,
    required this.onRefresh,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      ),
    );
  }
}
