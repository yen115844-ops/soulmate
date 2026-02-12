import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/image_utils.dart';

/// Story Ring Widget - Instagram-style story avatar with gradient ring
class StoryRingAvatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  final bool hasStory;
  final bool isOnline;
  final bool isViewed;
  final double size;
  final VoidCallback? onTap;

  const StoryRingAvatar({
    super.key,
    required this.imageUrl,
    required this.name,
    this.hasStory = true,
    this.isOnline = false,
    this.isViewed = false,
    this.size = 72,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with gradient ring
            Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasStory
                    ? (isViewed
                          ? LinearGradient(
                              colors: [
                                context.appColors.border,
                                context.appColors.textHint,
                              ],
                            )
                          : const LinearGradient(
                              colors: [
                                Color(0xFFFF6B6B),
                                Color(0xFFFF8E53),
                                Color(0xFFEC4899),
                                Color(0xFF8B5CF6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ))
                    : null,
                border: !hasStory
                    ? Border.all(color: context.appColors.border, width: 2)
                    : null,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.appColors.surface,
                ),
                child: Stack(
                  children: [
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: ImageUtils.buildImageUrl(imageUrl),
                        width: size - 10,
                        height: size - 10,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: context.appColors.background),
                        errorWidget: (_, __, ___) => Container(
                          color: context.appColors.background,
                          child: const Icon(Icons.person),
                        ),
                      ),
                    ),
                    // Online indicator
                    if (isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: size * 0.22,
                          height: size * 0.22,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.appColors.surface, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Name
            Text(
              name,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 11,
                color: context.appColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated Story Ring - With pulsing animation for live/active stories
class AnimatedStoryRing extends StatefulWidget {
  final String imageUrl;
  final String name;
  final bool isLive;
  final bool isOnline;
  final double size;
  final VoidCallback? onTap;

  const AnimatedStoryRing({
    super.key,
    required this.imageUrl,
    required this.name,
    this.isLive = false,
    this.isOnline = false,
    this.size = 72,
    this.onTap,
  });

  @override
  State<AnimatedStoryRing> createState() => _AnimatedStoryRingState();
}

class _AnimatedStoryRingState extends State<AnimatedStoryRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isLive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size + 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing ring for live
                if (widget.isLive)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        width: widget.size + 8 + (_controller.value * 8),
                        height: widget.size + 8 + (_controller.value * 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.error.withOpacity(
                              1 - _controller.value,
                            ),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                // Avatar with gradient ring
                Container(
                  width: widget.size,
                  height: widget.size,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: widget.isLive
                        ? const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
                          )
                        : const LinearGradient(
                            colors: [
                              Color(0xFFFF6B6B),
                              Color(0xFFFF8E53),
                              Color(0xFFEC4899),
                            ],
                          ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.appColors.surface,
                    ),
                    child: Stack(
                      children: [
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: ImageUtils.buildImageUrl(widget.imageUrl),
                            width: widget.size - 10,
                            height: widget.size - 10,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: context.appColors.background),
                            errorWidget: (_, __, ___) => Container(
                              color: context.appColors.background,
                              child: const Icon(Icons.person),
                            ),
                          ),
                        ),
                        if (widget.isOnline)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: widget.size * 0.22,
                              height: widget.size * 0.22,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: context.appColors.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Live badge
                if (widget.isLive)
                  Positioned(
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        'LIVE',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.name,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 11,
                color: context.appColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Stories Row - Horizontal scrollable list of stories
class StoriesRow extends StatelessWidget {
  final List<Map<String, dynamic>> stories;
  final EdgeInsets padding;
  final void Function(int index)? onStoryTap;

  const StoriesRow({
    super.key,
    required this.stories,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          final bool isLive = story['isLive'] ?? false;

          if (isLive) {
            return AnimatedStoryRing(
              imageUrl: story['avatar'],
              name: story['name'],
              isLive: true,
              isOnline: story['isOnline'] ?? false,
              onTap: () => onStoryTap?.call(index),
            ).animate().fadeIn(
              delay: Duration(milliseconds: 50 * index),
              duration: const Duration(milliseconds: 300),
            );
          }

          return StoryRingAvatar(
            imageUrl: story['avatar'],
            name: story['name'],
            hasStory: story['hasStory'] ?? true,
            isOnline: story['isOnline'] ?? false,
            isViewed: story['isViewed'] ?? false,
            onTap: () => onStoryTap?.call(index),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 50 * index),
            duration: const Duration(milliseconds: 300),
          );
        },
      ),
    );
  }
}
