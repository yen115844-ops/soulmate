import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/image_utils.dart';
import 'app_image_cache_manager.dart';

/// Preloads critical images so first feed render appears immediately.
class ImageWarmupService {
  ImageWarmupService._();

  static final ImageWarmupService instance = ImageWarmupService._();

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
        .toSet()
        .take(maxImages)
        .toList(growable: false);

    if (distinctUrls.isEmpty) return;

    final futures = <Future<void>>[];

    for (final url in distinctUrls) {
      futures.add(
        AppImageCacheManager.instance
            .downloadFile(url)
            .then((_) {})
            .catchError((_) {}),
      );

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

    // Run in background; warmup should never block UI thread transitions.
    unawaited(Future.wait(futures));
  }
}
