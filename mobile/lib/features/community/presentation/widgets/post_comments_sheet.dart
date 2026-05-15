import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../data/community_repository.dart';
import '../../data/models/community_models.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';

/// Bottom sheet: list comments + add box.
Future<void> showPostCommentsSheet(
  BuildContext context,
  CommunityPost post, {
  ValueChanged<String>? onCommentPosted,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _PostCommentsSheetBody(
        post: post,
        onCommentPosted: onCommentPosted,
      );
    },
  );
}

class _PostCommentsSheetBody extends StatefulWidget {
  final CommunityPost post;
  final ValueChanged<String>? onCommentPosted;

  const _PostCommentsSheetBody({
    required this.post,
    this.onCommentPosted,
  });

  @override
  State<_PostCommentsSheetBody> createState() => _PostCommentsSheetBodyState();
}

class _PostCommentsSheetBodyState extends State<_PostCommentsSheetBody> {
  late final CommunityRepository _repo = getIt<CommunityRepository>();
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final List<CommunityComment> _items = [];
  String? _nextCursor;
  bool _busy = false;
  bool _listBusy = false;
  String? _listError;

  /// ScrollController do [DraggableScrollableSheet] cấp — không dispose.
  ScrollController? _dragScrollRef;

  static const _maxCommentChars = 2000;

  @override
  void dispose() {
    _inputFocus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _listBusy = true;
      _listError = null;
    });
    try {
      final result = await _repo.fetchComments(
        postId: widget.post.id,
        limit: 50,
      );
      _items
        ..clear()
        ..addAll(result.items);
      _nextCursor = result.nextCursor;
    } catch (e) {
      if (mounted) {
        setState(() => _listError = 'Không tải được bình luận.');
      }
    } finally {
      if (mounted) setState(() => _listBusy = false);
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || cursor.isEmpty || _listBusy) return;
    setState(() => _listBusy = true);
    try {
      final result =
          await _repo.fetchComments(
                postId: widget.post.id,
                cursor: cursor,
              );
      _items.addAll(result.items);
      _nextCursor = result.nextCursor;
    } finally {
      if (mounted) setState(() => _listBusy = false);
    }
  }

  Future<void> _send() async {
    final body = _ctrl.text.trim();
    if (body.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final c = await _repo.addComment(postId: widget.post.id, body: body);
      _ctrl.clear();
      _items.insert(0, c);
      getIt<CommunityBloc>().add(CommunityCommentAdded(widget.post.id));
      widget.onCommentPosted?.call(widget.post.id);
      if (mounted) setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final c = _dragScrollRef;
        if (!mounted || c == null || !c.hasClients) return;
        c.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không gửi được comment: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom = mq.viewInsets.bottom;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: mq.size.height,
        width: double.infinity,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.54,
          minChildSize: 0.26,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            _dragScrollRef = scrollController;
            return Material(
              color: scheme.surfaceContainerLowest.withValues(alpha: 0.98),
              clipBehavior: Clip.antiAlias,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: scheme.outline.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 4, 0),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            'Bình luận',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                  color: colors.textPrimary,
                                ),
                          ),
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          tooltip: 'Đóng',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildCommentList(
                          context,
                          colors,
                          scheme,
                          scrollController,
                          constraints.maxHeight,
                        );
                      },
                    ),
                  ),
                  BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, ps) {
                      if (ps is! ProfileLoaded) {
                        return SizedBox(
                          height: 8 + MediaQuery.of(context).padding.bottom,
                        );
                      }
                      final p = ps;
                      final rawAvatar = p.avatarUrl;
                      final avatarUrl = rawAvatar != null &&
                              rawAvatar.trim().isNotEmpty
                          ? rawAvatar.trim()
                          : null;
                      return Material(
                        color: scheme.surface,
                        child: Container(
                          padding: EdgeInsets.fromLTRB(
                            12,
                            10,
                            10,
                            12 + MediaQuery.of(context).padding.bottom,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: scheme.outline.withValues(alpha: 0.09),
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      scheme.surfaceContainerHighest,
                                  backgroundImage: avatarUrl != null
                                      ? CachedNetworkImageProvider(
                                          avatarUrl,
                                        )
                                      : null,
                                  child: avatarUrl == null
                                      ? Text(
                                          _avatarLetter(p.displayName),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: scheme.primary,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _ctrl,
                                  focusNode: _inputFocus,
                                  enabled: !_busy,
                                  minLines: 1,
                                  maxLines: 5,
                                  maxLength: _maxCommentChars,
                                  textInputAction: TextInputAction.newline,
                                  keyboardType: TextInputType.multiline,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(height: 1.35),
                                  decoration: InputDecoration(
                                    hintText: 'Viết bình luận…',
                                    counterText: '',
                                    filled: true,
                                    fillColor: colors.background,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: scheme.primary.withValues(
                                          alpha: 0.45,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton.filled(
                                tooltip: 'Gửi',
                                onPressed: _busy ? null : _send,
                                icon: _busy
                                    ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: scheme.onPrimary,
                                        ),
                                      )
                                    : const Icon(
                                        Ionicons.send_outline,
                                        size: 20,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _avatarLetter(String displayName) {
    final n = displayName.trim();
    if (n.isEmpty) return '?';
    return n[0].toUpperCase();
  }

  Widget _buildCommentList(
    BuildContext context,
    AppThemeColors colors,
    ColorScheme scheme,
    ScrollController scrollController,
    double viewportHeight,
  ) {
    final minScrollExtent = viewportHeight > 180
        ? (viewportHeight * 0.9).clamp(220.0, viewportHeight)
        : 280.0;

    Widget filler(Widget inner) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: minScrollExtent,
            child: Center(child: inner),
          ),
        ],
      );
    }

    if (_listBusy && _items.isEmpty) {
      return filler(const CircularProgressIndicator());
    }
    if (_listError != null && _items.isEmpty) {
      return filler(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Ionicons.cloud_offline_outline,
                size: 44,
                color: colors.textSecondary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                _listError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _listBusy ? null : _load,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return filler(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Ionicons.chatbubbles_outline,
                size: 48,
                color: colors.textSecondary.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có bình luận',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hãy là người đầu tiên chia sẻ suy nghĩ của bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollUpdateNotification &&
            n.metrics.pixels >= n.metrics.maxScrollExtent - 100) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        itemCount:
            _items.length + ((_listBusy && _items.isNotEmpty) ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }
          final item = _items[i];
          final time = _shortTime(item.createdAt);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CommentAuthorAvatar(author: item.author, scheme: scheme),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              item.author.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (time.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        item.body,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
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

class _CommentAuthorAvatar extends StatelessWidget {
  final CommunityAuthor author;
  final ColorScheme scheme;

  const _CommentAuthorAvatar({
    required this.author,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final raw = author.avatarUrl;
    final url = raw != null && raw.trim().isNotEmpty ? raw.trim() : null;

    return CircleAvatar(
      radius: 19,
      backgroundColor: scheme.surfaceContainerHighest,
      backgroundImage:
          url != null ? CachedNetworkImageProvider(url) : null,
      child: url == null
          ? Text(
              _letter(author.displayName),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            )
          : null,
    );
  }

  static String _letter(String name) {
    final n = name.trim();
    if (n.isEmpty) return '?';
    return n[0].toUpperCase();
  }
}
