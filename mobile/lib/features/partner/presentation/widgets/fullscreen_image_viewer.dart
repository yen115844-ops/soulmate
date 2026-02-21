import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/image_utils.dart';

/// Fullscreen image viewer with swipe navigation
class FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? heroTag;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTag,
  });

  /// Show the viewer as a modal route
  static void show(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String? heroTag,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullscreenImageViewer(
            imageUrls: imageUrls,
            initialIndex: initialIndex,
            heroTag: heroTag,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image pages
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final url =
                  ImageUtils.buildImageUrlNullable(widget.imageUrls[index]);
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: url != null && url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Ionicons.image_outline,
                              color: Colors.white38,
                              size: 64,
                            ),
                          )
                        : const Icon(
                            Ionicons.image_outline,
                            color: Colors.white38,
                            size: 64,
                          ),
                  ),
                ),
              );
            },
          ),

          // Top bar with close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Ionicons.close,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                // Page indicator
                if (widget.imageUrls.length > 1)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom dot indicators
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imageUrls.length, (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
