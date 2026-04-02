import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Centralized cache manager for all network images.
///
/// A single shared manager helps avoid fragmented caches and gives
/// predictable cache behavior across screens.
class AppImageCacheManager {
  AppImageCacheManager._();

  static final AppImageCacheManagerImpl instance = AppImageCacheManagerImpl();
}

/// Cache manager specialized for images.
///
/// `CachedNetworkImage` requires an `ImageCacheManager` when using
/// `maxWidthDiskCache`/`maxHeightDiskCache`.
class AppImageCacheManagerImpl extends CacheManager with ImageCacheManager {
  static const String _cacheKey = 'soulmate_images_v1';

  AppImageCacheManagerImpl()
    : super(
        Config(
          _cacheKey,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 800,
        ),
      );
}
