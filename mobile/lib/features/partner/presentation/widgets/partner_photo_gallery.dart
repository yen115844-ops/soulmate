import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/image_utils.dart';
import '../../data/models/partner_profile_model.dart';
import 'fullscreen_image_viewer.dart';

/// Photo gallery section showing partner photos in a grid
class PartnerPhotoGallery extends StatelessWidget {
  final PartnerDetailResponse detail;

  const PartnerPhotoGallery({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    // Start with profile photos so hero image and gallery stay consistent.
    final allPhotos = <String>[];
    allPhotos.addAll(detail.photos);
    if (detail.avatarUrl != null && detail.avatarUrl!.isNotEmpty) {
      allPhotos.add(detail.avatarUrl!);
    }

    // Deduplicate
    final uniquePhotos = allPhotos.toSet().toList();

    if (uniquePhotos.length <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Ionicons.images_outline, size: 16, color: AppColors.accent),
              ),
              const SizedBox(width: 10),
              Text(
                'Ảnh',
                style: AppTypography.titleMedium.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${uniquePhotos.length} ảnh',
                style: AppTypography.bodySmall.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPhotoGrid(context, uniquePhotos),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, List<String> photos) {
    final mainImage = photos.first;
    final smallTiles = photos.skip(1).take(4).toList();
    final moreCount = photos.length - 5;

    if (photos.length == 1) {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: _buildPhotoTile(
          context,
          allPhotos: photos,
          imageUrl: mainImage,
          initialIndex: 0,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final width = constraints.maxWidth;
        final mainWidth = (width - spacing) * 0.58;
        final sideWidth = width - spacing - mainWidth;
        final smallSize = (sideWidth - spacing) / 2;

        return SizedBox(
          height: mainWidth,
          child: Row(
            children: [
              SizedBox(
                width: mainWidth,
                child: _buildPhotoTile(
                  context,
                  allPhotos: photos,
                  imageUrl: mainImage,
                  initialIndex: 0,
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: sideWidth,
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: List.generate(4, (i) {
                    if (i >= smallTiles.length) {
                      return SizedBox(width: smallSize, height: smallSize);
                    }

                    final isOverlayTile = i == 3 && moreCount > 0;
                    return SizedBox(
                      width: smallSize,
                      height: smallSize,
                      child: _buildPhotoTile(
                        context,
                        allPhotos: photos,
                        imageUrl: smallTiles[i],
                        initialIndex: i + 1,
                        overlayText: isOverlayTile ? '+$moreCount' : null,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoTile(
    BuildContext context,
    {
    required List<String> allPhotos,
    required String imageUrl,
    required int initialIndex,
    String? overlayText,
  }
  ) {
    final url = ImageUtils.buildImageUrlNullable(imageUrl);

    return GestureDetector(
      onTap: () {
        FullscreenImageViewer.show(
          context,
          imageUrls: allPhotos,
          initialIndex: initialIndex,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            url != null && url.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: context.appColors.background,
                      child: const Center(
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: context.appColors.background,
                      child: const Icon(Ionicons.image_outline,
                          color: AppColors.textHint),
                    ),
                  )
                : Container(
                    color: context.appColors.background,
                    child: const Icon(Ionicons.image_outline,
                        color: AppColors.textHint),
                  ),
            if (overlayText != null)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Text(
                    overlayText,
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
