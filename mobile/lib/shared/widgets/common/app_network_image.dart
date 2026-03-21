import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../core/services/app_image_cache_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/image_utils.dart';

/// A reusable network image widget that handles:
/// - Relative URL to absolute URL conversion
/// - Loading placeholder
/// - Error handling with fallback widget
/// - Caching
class AppNetworkImage extends StatelessWidget {
  /// The image URL (can be relative or absolute)
  final String? imageUrl;

  /// How the image should be inscribed into the space
  final BoxFit fit;

  /// Width of the image
  final double? width;

  /// Height of the image
  final double? height;

  /// Border radius for the image
  final BorderRadius? borderRadius;

  /// Whether to show as circular avatar
  final bool isCircular;

  /// Custom placeholder widget
  final Widget? placeholder;

  /// Custom error widget
  final Widget? errorWidget;

  /// Placeholder icon (used if placeholder is null)
  final IconData placeholderIcon;

  /// Error icon (used if errorWidget is null)
  final IconData errorIcon;

  /// Icon size for placeholder/error
  final double iconSize;

  /// Background color for placeholder/error
  final Color? backgroundColor;

  /// Optional memory decode width to reduce jank and memory spikes.
  final int? memCacheWidth;

  /// Optional memory decode height to reduce jank and memory spikes.
  final int? memCacheHeight;

  /// Optional disk cache width for resized file caching.
  final int? maxWidthDiskCache;

  /// Optional disk cache height for resized file caching.
  final int? maxHeightDiskCache;

  const AppNetworkImage({
    super.key,
    this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.isCircular = false,
    this.placeholder,
    this.errorWidget,
    this.placeholderIcon = Ionicons.image_outline,
    this.errorIcon = Ionicons.person_outline,
    this.iconSize = 32,
    this.backgroundColor,
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
  });

  @override
  Widget build(BuildContext context) {
    final fullUrl = ImageUtils.buildImageUrlNullable(imageUrl);
    final bgColor = backgroundColor ?? context.appColors.background;

    // Return placeholder if no URL
    if (fullUrl == null || fullUrl.isEmpty) {
      return _buildFallback(bgColor, errorIcon);
    }

    final useSharedCacheManager = ImageUtils.isBackendHostedUrl(fullUrl);

    Widget image = CachedNetworkImage(
      imageUrl: fullUrl,
      cacheManager: useSharedCacheManager
          ? AppImageCacheManager.instance
          : null,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      fadeInDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      useOldImageOnUrlChange: true,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(bgColor),
      errorWidget: (context, url, error) {
        debugPrint('AppNetworkImage load failed: $url -> $error');
        return errorWidget ?? _buildFallback(bgColor, errorIcon);
      },
    );

    // Apply border radius or circular clip
    if (isCircular) {
      image = ClipOval(child: image);
    } else if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildPlaceholder(Color bgColor) {
    return Container(
      width: width,
      height: height,
      color: bgColor,
      child: Center(
        child: Icon(placeholderIcon, size: iconSize, color: AppColors.textHint),
      ),
    );
  }

  Widget _buildFallback(Color bgColor, IconData icon) {
    return Container(
      width: width,
      height: height,
      color: bgColor,
      child: Center(
        child: Icon(icon, size: iconSize, color: AppColors.textHint),
      ),
    );
  }
}

/// A circular avatar variant of AppNetworkImage
class AppAvatar extends StatelessWidget {
  /// The image URL (can be relative or absolute)
  final String? imageUrl;

  /// Size of the avatar (diameter)
  final double size;

  /// Border color
  final Color? borderColor;

  /// Border width
  final double borderWidth;

  /// Background color when no image
  final Color? backgroundColor;

  /// Fallback text (first letter shown when no image)
  final String? fallbackText;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.size = 48,
    this.borderColor,
    this.borderWidth = 0,
    this.backgroundColor,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    final fullUrl = ImageUtils.buildImageUrlNullable(imageUrl);
    final bgColor = backgroundColor ?? AppColors.primary.withAlpha(25);
    final useSharedCacheManager =
        fullUrl != null && ImageUtils.isBackendHostedUrl(fullUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderWidth > 0 && borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: fullUrl != null && fullUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: fullUrl,
                cacheManager: useSharedCacheManager
                    ? AppImageCacheManager.instance
                    : null,
                fit: BoxFit.cover,
                width: size,
                height: size,
                memCacheWidth: size.toInt(),
                memCacheHeight: size.toInt(),
                maxWidthDiskCache: size.toInt() * 2,
                maxHeightDiskCache: size.toInt() * 2,
                fadeInDuration: Duration.zero,
                placeholderFadeInDuration: Duration.zero,
                useOldImageOnUrlChange: true,
                placeholder: (context, url) => _buildPlaceholder(bgColor),
                errorWidget: (context, url, error) {
                  debugPrint('AppAvatar load failed: $url -> $error');
                  return _buildFallback(bgColor);
                },
              )
            : _buildFallback(bgColor),
      ),
    );
  }

  Widget _buildPlaceholder(Color bgColor) {
    return Container(
      color: bgColor,
      child: Center(
        child: Icon(
          Ionicons.person_outline,
          size: size * 0.4,
          color: AppColors.textHint,
        ),
      ),
    );
  }

  Widget _buildFallback(Color bgColor) {
    return Container(
      color: bgColor,
      child: Center(
        child: fallbackText != null && fallbackText!.isNotEmpty
            ? Text(
                fallbackText![0].toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              )
            : Icon(
                Ionicons.person_outline,
                size: size * 0.4,
                color: AppColors.textHint,
              ),
      ),
    );
  }
}
