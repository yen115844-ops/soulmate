import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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
  bool _isClosing = false;
  double _currentScale = 1.0;
  double _dragOffsetY = 0;

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
    final canDragToDismiss = _currentScale <= 1.02;
    final normalizedDrag = (_dragOffsetY.abs() / 220).clamp(0.0, 1.0);
    final bgOpacity = 1.0 - (normalizedDrag * 0.45);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: canDragToDismiss
            ? (details) {
                setState(() {
                  _dragOffsetY += details.delta.dy;
                });
              }
            : null,
        onVerticalDragEnd: canDragToDismiss
            ? (details) {
                final shouldDismiss =
                    _dragOffsetY.abs() > 120 ||
                    (details.primaryVelocity?.abs() ?? 0) > 900;

                if (shouldDismiss) {
                  _close();
                  return;
                }

                setState(() => _dragOffsetY = 0);
              }
            : null,
        child: Stack(
          children: [
            // Image pages
            Transform.translate(
              offset: Offset(0, _dragOffsetY),
              child: Opacity(
                opacity: bgOpacity,
                child: PhotoViewGallery.builder(
                  pageController: _pageController,
                  itemCount: widget.imageUrls.length,
                  scrollPhysics: const BouncingScrollPhysics(),
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                      _currentScale = 1.0;
                      _dragOffsetY = 0;
                    });
                  },
                  builder: (context, index) {
                    final url =
                        ImageUtils.buildImageUrlNullable(widget.imageUrls[index]);

                    if (url == null || url.isEmpty) {
                      return PhotoViewGalleryPageOptions.customChild(
                        child: const Center(
                          child: Icon(
                            Ionicons.image_outline,
                            color: Colors.white38,
                            size: 64,
                          ),
                        ),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 4,
                        initialScale: PhotoViewComputedScale.contained,
                        scaleStateCycle: _scaleStateCycle,
                        onScaleEnd: (_, __, value) {
                          final scale = value.scale ?? 1.0;
                          setState(() => _currentScale = scale);
                          if (scale < 1.0) _close();
                        },
                      );
                    }

                    return PhotoViewGalleryPageOptions(
                      imageProvider: CachedNetworkImageProvider(url),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 4,
                      initialScale: PhotoViewComputedScale.contained,
                      gestureDetectorBehavior: HitTestBehavior.opaque,
                      heroAttributes: widget.heroTag == null
                          ? null
                          : PhotoViewHeroAttributes(
                              tag: '${widget.heroTag}-$index',
                            ),
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Ionicons.image_outline,
                          color: Colors.white38,
                          size: 64,
                        ),
                      ),
                      scaleStateCycle: _scaleStateCycle,
                      onScaleEnd: (_, __, value) {
                        final scale = value.scale ?? 1.0;
                        setState(() => _currentScale = scale);
                        if (scale < 1.0) _close();
                      },
                    );
                  },
                  loadingBuilder: (_, __) => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
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
                    onTap: _close,
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
      ),
    );
  }

  PhotoViewScaleState _scaleStateCycle(PhotoViewScaleState actual) {
    switch (actual) {
      case PhotoViewScaleState.initial:
      case PhotoViewScaleState.zoomedOut:
        return PhotoViewScaleState.zoomedIn;
      case PhotoViewScaleState.zoomedIn:
      case PhotoViewScaleState.covering:
      case PhotoViewScaleState.originalSize:
        return PhotoViewScaleState.initial;
    }
  }

  void _close() {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    Navigator.of(context).maybePop();
  }
}
