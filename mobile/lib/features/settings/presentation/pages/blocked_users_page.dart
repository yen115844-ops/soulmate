import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../chat/data/chat_repository.dart';

/// Page to display and manage blocked users
class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final ChatRepository _chatRepository = getIt<ChatRepository>();
  
  List<BlockedUserEntity> _blockedUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _chatRepository.getBlockedUsers();
      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách. Vui lòng thử lại.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unblockUser(BlockedUserEntity user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ chặn người dùng'),
        content: Text(
          'Bạn có chắc chắn muốn bỏ chặn ${user.name}? '
          'Người này sẽ có thể nhắn tin và xem hồ sơ của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bỏ chặn'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _chatRepository.unblockUser(user.id);
      
      HapticFeedback.mediumImpact();
      
      if (mounted) {
        setState(() {
          _blockedUsers.removeWhere((u) => u.id == user.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã bỏ chặn ${user.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể bỏ chặn. Vui lòng thử lại.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Người dùng đã chặn'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.alert_circle_outline,
              size: 48,
              color: context.appColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTypography.bodyMedium.copyWith(
                color: context.appColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadBlockedUsers,
              icon: const Icon(Ionicons.refresh_outline),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_blockedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.appColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Ionicons.person_remove_outline,
                size: 48,
                color: context.appColors.textHint,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không có người dùng nào bị chặn',
              style: AppTypography.titleMedium.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Khi bạn chặn ai đó, họ sẽ không thể nhắn tin hoặc xem hồ sơ của bạn.',
                style: AppTypography.bodyMedium.copyWith(
                  color: context.appColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBlockedUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _blockedUsers.length,
        itemBuilder: (context, index) {
          final user = _blockedUsers[index];
          return _buildBlockedUserItem(user);
        },
      ),
    );
  }

  Widget _buildBlockedUserItem(BlockedUserEntity user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.appColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: user.avatarUrl != null
                  ? CachedNetworkImageProvider(ImageUtils.buildImageUrl(user.avatarUrl!))
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Name and date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đã chặn ${_formatDate(user.blockedAt)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: context.appColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            // Unblock button
            OutlinedButton(
              onPressed: () => _unblockUser(user),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Bỏ chặn'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'hôm nay';
    } else if (diff.inDays == 1) {
      return 'hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks tuần trước';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months tháng trước';
    } else {
      final years = (diff.inDays / 365).floor();
      return '$years năm trước';
    }
  }
}
