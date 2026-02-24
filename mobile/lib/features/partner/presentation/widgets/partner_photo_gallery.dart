import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/models/partner_profile_model.dart';
import 'fullscreen_image_viewer.dart';

/// Photo gallery section showing partner photos in a grid
class PartnerPhotoGallery extends StatelessWidget {
  final PartnerDetailResponse detail;

  const PartnerPhotoGallery({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    // Combine avatar + photos for a complete gallery
    final allPhotos = <String>[];
    if (detail.avatarUrl != null && detail.avatarUrl!.isNotEmpty) {
      allPhotos.add(detail.avatarUrl!);
    }
    allPhotos.addAll(detail.photos);

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
    const maxVisible = 6;
    final visiblePhotos = photos.take(maxVisible).toList();
    final hasMore = photos.length > maxVisible;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.gridCrossAxisCount(
          context,
          minCellWidth: 90,
          horizontalPadding: 40,
          spacing: 8,
          maxColumns: 6,
        ),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: visiblePhotos.length,
      itemBuilder: (context, index) {
        final isLast = hasMore && index == visiblePhotos.length - 1;
        return _buildPhotoTile(context, photos, index, isLast,
            photos.length - maxVisible);
      },
    );
  }

  Widget _buildPhotoTile(
    BuildContext context,
    List<String> allPhotos,
    int index,
    bool showOverlay,
    int moreCount,
  ) {
    final url = ImageUtils.buildImageUrlNullable(allPhotos[index]);

    return GestureDetector(
      onTap: () {
        FullscreenImageViewer.show(
          context,
          imageUrls: allPhotos,
          initialIndex: index,
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
            if (showOverlay)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Text(
                    '+$moreCount',
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
