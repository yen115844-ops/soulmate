import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/image_utils.dart';
import 'app_image_cache_manager.dart';

/// Preloads critical images so first feed render appears immediately.
class ImageWarmupService {
  ImageWarmupService._();

  static final ImageWarmupService instance = ImageWarmupService._();

  /// Tracks URLs already warmed to avoid redundant work.
  final Set<String> _warmedUrls = {};

  Future<void> warmupImages({
    required BuildContext context,
    required List<String> imageUrls,
    int maxImages = 16,
    int targetWidth = 800,
  }) async {
    if (imageUrls.isEmpty || maxImages <= 0) return;

    final distinctUrls = imageUrls
        .where((url) => url.trim().isNotEmpty)
        .map(ImageUtils.buildImageUrl)
        .where((url) => !_warmedUrls.contains(url))
        .toSet()
        .take(maxImages)
        .toList(growable: false);

    if (distinctUrls.isEmpty) return;

    _warmedUrls.addAll(distinctUrls);

    // Chỉ precache (một lần tải + decode). Tránh song song downloadFile + precache
    // cùng URL — gây tranh băng thông và decode trùng khi lướt home.
    final futures = <Future<void>>[];
    for (final url in distinctUrls) {
      final imageProvider = ResizeImage.resizeIfNeeded(
        targetWidth,
        null,
        CachedNetworkImageProvider(
          url,
          cacheManager: AppImageCacheManager.instance,
        ),
      );
      futures.add(precacheImage(imageProvider, context).catchError((_) {}));
    }

    unawaited(Future.wait(futures));
  }

  /// Preload a specific partner's gallery images for instant detail page render.
  /// Call this when user taps a partner card - starts downloading while
  /// the route transition animates (~300ms window).
  Future<void> warmupPartnerGallery({
    required BuildContext context,
    required List<String> galleryUrls,
    String? avatarUrl,
  }) async {
    final urls = <String>[
      ...galleryUrls,
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty) avatarUrl,
    ];

    return warmupImages(
      context: context,
      imageUrls: urls,
      maxImages: 10,
      targetWidth: 1080,
    );
  }
}
