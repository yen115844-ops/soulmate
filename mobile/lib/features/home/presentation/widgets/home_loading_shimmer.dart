import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme_context.dart';

/// Shimmer loading placeholder for partner list
class HomeLoadingShimmer extends StatelessWidget {
  const HomeLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (index) {
          return Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 220,
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                  duration: 1200.ms, color: context.appColors.border);
        }),
      ),
    );
  }
}
