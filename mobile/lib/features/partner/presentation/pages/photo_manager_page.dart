import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../data/partner_repository.dart';

class PhotoManagerPage extends StatefulWidget {
  final List<String> initialPhotos;

  const PhotoManagerPage({
    super.key,
    required this.initialPhotos,
  });

  @override
  State<PhotoManagerPage> createState() => _PhotoManagerPageState();
}

class _PhotoManagerPageState extends State<PhotoManagerPage> {
  late final PartnerRepository _partnerRepository;
  late List<String> _photos;
  final List<File> _newPhotos = [];
  final Set<String> _photosToRemove = {};
  bool _isLoading = false;
  bool _hasChanges = false;

  static const int maxPhotos = 10;

  /// Get full URL for photo (adds base URL if relative path)
  String _getFullPhotoUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Remove /api suffix from base URL for static files
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$baseUrl$url';
  }

  @override
  void initState() {
    super.initState();
    _partnerRepository = getIt<PartnerRepository>();
    _photos = List.from(widget.initialPhotos);
  }

  int get _totalPhotos => _photos.length - _photosToRemove.length + _newPhotos.length;
  bool get _canAddMore => _totalPhotos < maxPhotos;

  Future<void> _pickImages() async {
    if (!_canAddMore) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn đã đạt tối đa $maxPhotos ảnh'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final remainingSlots = maxPhotos - _totalPhotos;

    try {
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFiles.isNotEmpty) {
        final filesToAdd = pickedFiles.take(remainingSlots).map((xFile) => File(xFile.path)).toList();
        
        setState(() {
          _newPhotos.addAll(filesToAdd);
          _hasChanges = true;
        });

        if (pickedFiles.length > remainingSlots) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Chỉ thêm được $remainingSlots ảnh. Đã đạt tối đa $maxPhotos ảnh.'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể chọn ảnh'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeExistingPhoto(String url) {
    setState(() {
      _photosToRemove.add(url);
      _hasChanges = true;
    });
  }

  void _restorePhoto(String url) {
    setState(() {
      _photosToRemove.remove(url);
      _hasChanges = _photosToRemove.isNotEmpty || _newPhotos.isNotEmpty;
    });
  }

  void _removeNewPhoto(int index) {
    setState(() {
      _newPhotos.removeAt(index);
      _hasChanges = _photosToRemove.isNotEmpty || _newPhotos.isNotEmpty;
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Remove photos first
      if (_photosToRemove.isNotEmpty) {
        await _partnerRepository.removePhotos(_photosToRemove.toList());
      }

      // Add new photos
      if (_newPhotos.isNotEmpty) {
        await _partnerRepository.addPhotos(_newPhotos);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật ảnh thành công'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật ảnh. Vui lòng thử lại.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Huỷ thay đổi?'),
        content: const Text('Bạn có thay đổi chưa lưu. Bạn có chắc muốn thoát?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Get visible existing photos (excluding those marked for removal)
    final visibleExistingPhotos = _photos.where((p) => !_photosToRemove.contains(p)).toList();
    
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Quản lý ảnh'),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu'),
              ),
          ],
        ),
        body: Column(
          children: [
            // Header info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.backgroundLight,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Ionicons.image_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_totalPhotos / $maxPhotos ảnh',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Thêm ảnh để hồ sơ hấp dẫn hơn',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Photos grid
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Existing photos
                    if (visibleExistingPhotos.isNotEmpty) ...[
                      Text(
                        'Ảnh hiện tại',
                        style: AppTypography.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      _buildPhotoGrid(
                        items: visibleExistingPhotos,
                        isExisting: true,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Photos to remove (shown as faded)
                    if (_photosToRemove.isNotEmpty) ...[
                      Text(
                        'Ảnh sẽ bị xoá',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPhotoGrid(
                        items: _photosToRemove.toList(),
                        isExisting: true,
                        isMarkedForRemoval: true,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // New photos to add
                    if (_newPhotos.isNotEmpty) ...[
                      Text(
                        'Ảnh mới',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNewPhotoGrid(),
                      const SizedBox(height: 24),
                    ],

                    // Add photo button
                    if (_canAddMore)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Ionicons.add_circle_outline),
                          label: const Text('Thêm ảnh'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom action bar
            if (_hasChanges)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      text: _isLoading ? 'Đang lưu...' : 'Lưu thay đổi',
                      icon: Ionicons.checkmark_circle_outline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid({
    required List<String> items,
    required bool isExisting,
    bool isMarkedForRemoval = false,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final url = items[index];
        return _PhotoItem(
          imageUrl: _getFullPhotoUrl(url),
          isMarkedForRemoval: isMarkedForRemoval,
          onRemove: isMarkedForRemoval
              ? () => _restorePhoto(url)
              : () => _removeExistingPhoto(url),
          actionIcon: isMarkedForRemoval ? Ionicons.refresh_outline : Ionicons.trash_outline,
        );
      },
    );
  }

  Widget _buildNewPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _newPhotos.length,
      itemBuilder: (context, index) {
        return _PhotoItem(
          file: _newPhotos[index],
          isNew: true,
          onRemove: () => _removeNewPhoto(index),
        );
      },
    );
  }
}

class _PhotoItem extends StatelessWidget {
  final String? imageUrl;
  final File? file;
  final bool isMarkedForRemoval;
  final bool isNew;
  final VoidCallback onRemove;
  final IconData actionIcon;

  const _PhotoItem({
    this.imageUrl,
    this.file,
    this.isMarkedForRemoval = false,
    this.isNew = false,
    required this.onRemove,
    this.actionIcon = Ionicons.trash_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null)
                  Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Ionicons.image_outline, color: AppColors.textHint),
                    ),
                  )
                else if (file != null)
                  Image.file(
                    file!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Ionicons.image_outline, color: AppColors.textHint),
                    ),
                  ),
                // Overlay for marked items
                if (isMarkedForRemoval)
                  Container(
                    color: Colors.red.withOpacity(0.3),
                    child: const Center(
                      child: Icon(
                        Ionicons.trash_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                if (isNew)
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Mới',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Action button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isMarkedForRemoval ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                actionIcon,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
