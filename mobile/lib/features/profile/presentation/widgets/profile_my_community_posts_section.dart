import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';
import '../../../community/data/community_repository.dart';
import '../../../community/data/models/community_models.dart';
import '../../../community/presentation/bloc/community_bloc.dart';
import '../../../community/presentation/bloc/community_event.dart';
import '../../../community/presentation/widgets/community_post_card.dart';
import '../../../community/presentation/widgets/delete_community_post_dialog.dart';
import '../../../community/presentation/widgets/post_comments_sheet.dart';

enum _PostsSinceFilter {
  all,
  week,
  month,
}

/// Danh sách bài cộng đồng của user (authorId) + lọc thời gian / tìm + cursor phân trang.
class ProfileMyCommunityPostsSection extends StatefulWidget {
  final String userId;

  const ProfileMyCommunityPostsSection({
    super.key,
    required this.userId,
  });

  @override
  ProfileMyCommunityPostsSectionState createState() =>
      ProfileMyCommunityPostsSectionState();
}

class ProfileMyCommunityPostsSectionState
    extends State<ProfileMyCommunityPostsSection> {
  final CommunityRepository _repo = getIt<CommunityRepository>();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  final List<CommunityPost> _posts = [];
  String? _cursor;
  bool _hasMore = true;
  bool _loadingFirst = false;
  bool _loadingMore = false;
  String? _errorFirst;

  _PostsSinceFilter _since = _PostsSinceFilter.all;

  void _onSearchTyping() => setState(() {});

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchTyping);
    if (widget.userId.isNotEmpty) {
      _reloadFromFilters();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.removeListener(_onSearchTyping);
    _searchCtrl.dispose();
    super.dispose();
  }

  DateTime? get _sinceDate {
    return switch (_since) {
      _PostsSinceFilter.all => null,
      _PostsSinceFilter.week =>
        DateTime.now().subtract(const Duration(days: 7)),
      _PostsSinceFilter.month =>
        DateTime.now().subtract(const Duration(days: 30)),
    };
  }

  Future<void> reload() => _reloadFromFilters();

  void loadMoreIfNeeded() {
    if (widget.userId.isEmpty ||
        !_hasMore ||
        _loadingMore ||
        _loadingFirst ||
        _errorFirst != null && _posts.isEmpty) {
      return;
    }
    _fetchPage(append: true);
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      _reloadFromFilters();
    });
  }

  Future<void> _reloadFromFilters() async {
    if (widget.userId.isEmpty) return;
    _searchDebounce?.cancel();
    setState(() {
      _posts.clear();
      _cursor = null;
      _hasMore = true;
      _errorFirst = null;
      _loadingFirst = true;
    });
    await _fetchPage(append: false);
  }

  Future<void> _fetchPage({required bool append}) async {
    if (widget.userId.isEmpty) return;
    if (append) {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final rawSearch = _searchCtrl.text.trim();
      final result = await _repo.fetchFeed(
        cursor: append ? _cursor : null,
        limit: 15,
        authorId: widget.userId,
        search: rawSearch.isEmpty ? null : rawSearch,
        since: _sinceDate,
      );
      if (!mounted) return;
      setState(() {
        if (!append) {
          _posts.clear();
        }
        _posts.addAll(result.items);
        _cursor = result.nextCursor;
        _hasMore = result.nextCursor != null &&
            result.nextCursor!.trim().isNotEmpty;
        _loadingFirst = false;
        _loadingMore = false;
        _errorFirst = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingFirst = false;
        _loadingMore = false;
        if (!append && _posts.isEmpty) {
          _errorFirst = 'Không tải được bài viết. $e';
        }
      });
    }
  }

  Future<void> _toggleLike(CommunityPost p) async {
    final idx = _posts.indexWhere((x) => x.id == p.id);
    if (idx < 0) return;
    final before = _posts[idx];
    setState(() {
      _posts[idx] = before.copyWith(
        likedByMe: !before.likedByMe,
        likeCount:
            before.likedByMe ? before.likeCount - 1 : before.likeCount + 1,
      );
    });
    try {
      final r = await _repo.toggleLike(p.id);
      if (!mounted) return;
      setState(() {
        _posts[idx] = before.copyWith(
          likedByMe: r.liked,
          likeCount: r.likeCount,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _posts[idx] = before);
    }
  }

  void _bumpCommentCount(String postId) {
    final idx = _posts.indexWhere((x) => x.id == postId);
    if (idx < 0) return;
    final p = _posts[idx];
    setState(() {
      _posts[idx] = p.copyWith(commentCount: p.commentCount + 1);
    });
  }

  Future<void> _confirmDelete(CommunityPost post) async {
    final yes = await showDeleteCommunityPostDialog(context);
    if (yes != true || !mounted) return;
    try {
      await _repo.deletePost(post.id);
      if (!mounted) return;
      setState(() => _posts.removeWhere((x) => x.id == post.id));
      getIt<CommunityBloc>().add(CommunityPostDeleted(post.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xóa được: $e')),
      );
    }
  }

  int _sliverChildCount() {
    var n = 1;
    if (_loadingFirst && _posts.isEmpty) return n + 1;
    if (_errorFirst != null && _posts.isEmpty) return n + 1;
    if (!_loadingFirst &&
        _posts.isEmpty &&
        _errorFirst == null) {
      return n + 1;
    }
    n += _posts.length;
    if (_loadingMore) n += 1;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final hp = ResponsiveLayout.horizontalPadding(context);

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: hp),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return _buildHeaderBlock(context);
            }
            final bi = index - 1;
            if (_loadingFirst && _posts.isEmpty && bi == 0) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (_errorFirst != null && _posts.isEmpty && bi == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Text(
                      _errorFirst!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.appColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _reloadFromFilters,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }
            if (!_loadingFirst &&
                _posts.isEmpty &&
                _errorFirst == null &&
                bi == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Icon(
                      Ionicons.document_text_outline,
                      size: 44,
                      color: context.appColors.textSecondary.withValues(
                        alpha: 0.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Chưa có bài viết phù hợp',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thử đổi bộ lọc hoặc tìm từ khác.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.appColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (bi < _posts.length) {
              final post = _posts[bi];
              return CommunityPostCard(
                post: post,
                onLike: () => _toggleLike(post),
                onComment: () => showPostCommentsSheet(
                  context,
                  post,
                  onCommentPosted: _bumpCommentCount,
                ),
                onViewAuthorProfile: post.authorId.trim().isEmpty
                    ? null
                    : () {
                        final aid = post.authorId.trim();
                        if (aid == widget.userId) {
                          context.push(RouteNames.profile);
                        } else {
                          context.pushNamed(
                            'partner-detail',
                            pathParameters: {'id': aid},
                          );
                        }
                      },
                onDelete: () => _confirmDelete(post),
              );
            }
            if (_loadingMore) {
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
            return const SizedBox.shrink();
          },
          childCount: _sliverChildCount(),
        ),
      ),
    );
  }

  Widget _buildHeaderBlock(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    Widget sinceChip({
      required String label,
      required bool selected,
      required _PostsSinceFilter value,
    }) {
      final borderColor = selected
          ? scheme.primary
          : scheme.outline.withValues(alpha: 0.55);
      return ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.onPrimary : colors.textPrimary,
            letterSpacing: -0.1,
          ),
        ),
        selected: selected,
        showCheckmark: false,
        selectedColor: scheme.primary,
        backgroundColor: scheme.surfaceContainerHighest,
        disabledColor: scheme.surfaceContainerHighest,
        side: BorderSide(color: borderColor, width: selected ? 2 : 1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (_) {
          if (_since == value) return;
          setState(() => _since = value);
          _reloadFromFilters();
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bài viết cộng đồng',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: colors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Các bài bạn đã đăng',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              sinceChip(
                label: 'Tất cả thời gian',
                selected: _since == _PostsSinceFilter.all,
                value: _PostsSinceFilter.all,
              ),
              sinceChip(
                label: '7 ngày',
                selected: _since == _PostsSinceFilter.week,
                value: _PostsSinceFilter.week,
              ),
              sinceChip(
                label: '30 ngày',
                selected: _since == _PostsSinceFilter.month,
                value: _PostsSinceFilter.month,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm trong nội dung bài viết…',
              prefixIcon: const Icon(Ionicons.search_outline, size: 22),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        _reloadFromFilters();
                      },
                    ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
