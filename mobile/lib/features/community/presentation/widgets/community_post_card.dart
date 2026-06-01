import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ionicons/ionicons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/theme/theme_context.dart';
import '../../data/models/community_models.dart';

class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback? onDelete;
  /// Mở hồ sơ / chi tiết người đăng (vd. tab Cộng đồng).
  final VoidCallback? onViewAuthorProfile;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    this.onDelete,
    this.onViewAuthorProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final scheme = theme.colorScheme;
    final muted = colors.textSecondary;
    final authorId = post.authorId.trim();
    final canOpenAuthor =
        onViewAuthorProfile != null && authorId.isNotEmpty;
    final showOverflowMenu = onDelete != null || canOpenAuthor;

    final surfaceElevated = scheme.brightness == Brightness.dark
        ? scheme.surfaceContainerHigh
        : colors.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: surfaceElevated,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final header = Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AvatarRing(
                              post: post,
                              colors: colors,
                              scheme: scheme,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      post.author.displayName,
                                      textAlign: TextAlign.left,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scheme.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _shortTime(post.createdAt),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: scheme.primary
                                              .withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                        if (!canOpenAuthor) return header;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onViewAuthorProfile,
                            borderRadius: BorderRadius.circular(14),
                            splashColor:
                                scheme.primary.withValues(alpha: 0.06),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 4,
                                top: 2,
                                bottom: 2,
                              ),
                              child: header,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (showOverflowMenu)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded, color: muted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      onSelected: (v) {
                        if (v == 'view_author') onViewAuthorProfile!();
                        if (v == 'delete') onDelete!();
                      },
                      itemBuilder: (ctx) => [
                        if (canOpenAuthor)
                          PopupMenuItem(
                            value: 'view_author',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Ionicons.person_circle_outline,
                                size: 22,
                                color: scheme.primary,
                              ),
                              title: const Text('Xem chi tiết người dùng'),
                            ),
                          ),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Ionicons.trash_outline,
                                size: 22,
                                color: scheme.error,
                              ),
                              title: Text(
                                'Xóa bài',
                                style: TextStyle(color: scheme.error),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 2),
                child: SelectableText(
                  post.body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.42,
                    color: colors.textPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              if (post.mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: post.mediaUrls.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (ctx, _) => Container(
                        color: colors.background,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: scheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Divider(
                height: 26,
                color: theme.dividerColor.withValues(alpha: 0.08),
              ),
              Row(
                children: [
                  _ActionChip(
                    icon: post.likedByMe
                        ? Ionicons.heart
                        : Ionicons.heart_outline,
                    label: '${post.likeCount}',
                    activeColor: scheme.error.withValues(alpha: 0.9),
                    mutedColor: muted,
                    prominent: post.likedByMe,
                    onTap: onLike,
                  ),
                  _ActionChip(
                    icon: Ionicons.chatbubble_ellipses_outline,
                    label: '${post.commentCount}',
                    mutedColor: muted,
                    prominent: false,
                    onTap: onComment,
                  ),
                  _ActionChip(
                    icon: Ionicons.paper_plane_outline,
                    label: '',
                    showLabel: false,
                    mutedColor: muted,
                    prominent: false,
                    onTap: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: ApiConfig.postShareUrl(post.id),
                          subject: 'Bài đăng cộng đồng',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 260.ms, curve: Curves.easeOutCubic).slideY(
          begin: 0.06,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 260.ms,
        );
  }

  String _shortTime(String iso) {
    try {
      final d = DateTime.tryParse(iso);
      if (d == null) return '';
      final now = DateTime.now();
      final diff = now.difference(d);
      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inHours < 1) return '${diff.inMinutes} phút';
      if (diff.inDays < 1) return '${diff.inHours} giờ';
      if (diff.inDays < 7) return '${diff.inDays} ngày';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }
}

class _AvatarRing extends StatelessWidget {
  final CommunityPost post;
  final AppThemeColors colors;
  final ColorScheme scheme;

  const _AvatarRing({
    required this.post,
    required this.colors,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = post.author.avatarUrl != null &&
        post.author.avatarUrl!.trim().isNotEmpty;
    final letter = _initialLetter(post.author.displayName);

    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.45),
            scheme.tertiary.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage:
            hasAvatar ? CachedNetworkImageProvider(post.author.avatarUrl!) : null,
        child: !hasAvatar
            ? Text(
                letter,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  color: scheme.primary,
                ),
              )
            : null,
      ),
    );
  }

  String _initialLetter(String name) {
    final n = name.trim();
    if (n.isEmpty) return '?';
    return n[0].toUpperCase();
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showLabel;
  final Color mutedColor;
  final Color? activeColor;
  final bool prominent;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.showLabel = true,
    required this.mutedColor,
    this.activeColor,
    required this.prominent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = prominent && activeColor != null ? activeColor! : mutedColor;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: scheme.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: showLabel ? 12 : 10,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: c),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: prominent && activeColor != null
                          ? activeColor
                          : mutedColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
