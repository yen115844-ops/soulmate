import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';

/// Shimmer loading placeholder for partner list (responsive grid)
class HomeLoadingShimmer extends StatelessWidget {
  const HomeLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveLayout.gridCrossAxisCount(
      context,
      minCellWidth: 320,
      horizontalPadding: ResponsiveLayout.horizontalPadding(context) * 2,
      spacing: 16,
    );
    final padding = ResponsiveLayout.horizontalPadding(context);
    const itemCount = 6;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms, color: context.appColors.border),
      ),
    );
  }
}
