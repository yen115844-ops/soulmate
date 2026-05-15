import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../data/community_repository.dart';
import '../../data/models/community_models.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import '../widgets/community_post_card.dart';
import '../widgets/delete_community_post_dialog.dart';
import '../widgets/post_comments_sheet.dart';

/// Tab **Cộng đồng** — AppBar có search (mở rộng) + nút đăng / thông báo trong actions.
class CommunityFeedPage extends StatelessWidget {
  const CommunityFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<CommunityBloc>(),
      child: const _CommunityFeedBody(),
    );
  }
}

class _CommunityFeedBody extends StatefulWidget {
  const _CommunityFeedBody();

  @override
  State<_CommunityFeedBody> createState() => _CommunityFeedBodyState();
}

class _CommunityFeedBodyState extends State<_CommunityFeedBody> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _searchMode = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchTyping);
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeLoad());
  }

  void _onSearchTyping() {
    if (_searchMode && mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _primeLoad() {
    if (!mounted || !AuthGuard.isAuthenticated) return;
    final bloc = context.read<CommunityBloc>();
    if (bloc.state.status == CommunityStatus.initial ||
        (bloc.state.posts.isEmpty &&
            bloc.state.status == CommunityStatus.failure)) {
      bloc.add(const CommunityFeedLoad());
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        !_scrollController.position.hasViewportDimension) {
      return;
    }
    if (!AuthGuard.isAuthenticated) return;
    final bloc = context.read<CommunityBloc>();
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200 &&
        bloc.state.canLoadMore) {
      bloc.add(const CommunityFeedLoadMore());
    }
  }

  void _enterSearchMode() {
    setState(() {
      _searchMode = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _exitSearchMode() {
    setState(() {
      _searchMode = false;
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
  }

  List<CommunityPost> _filteredPosts(List<CommunityPost> all) {
    final raw = _searchController.text.trim().toLowerCase();
    if (!_searchMode || raw.isEmpty) return all;
    return all.where((p) {
      return p.body.toLowerCase().contains(raw) ||
          p.author.displayName.toLowerCase().contains(raw);
    }).toList();
  }

  Future<void> _openCompose(BuildContext rootContext) async {
    final posted = await showModalBottomSheet<bool>(
      context: rootContext,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CommunityComposeSheet(
          parentMessenger: ScaffoldMessenger.maybeOf(rootContext),
        );
      },
    );
    if (!rootContext.mounted) return;
    if (posted == true) {
      rootContext.read<CommunityBloc>().add(const CommunityPostCreated());
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, double hp) {
    final bg = context.appColors.background;
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    if (!_searchMode) {
      return AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        backgroundColor: bg,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Cộng đồng',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tìm kiếm',
            icon: const Icon(Ionicons.search_outline),
            onPressed: _enterSearchMode,
          ),
          IconButton(
            tooltip: 'Đăng bài',
            icon: Icon(
              Ionicons.add_outline,
              color: scheme.primary,
              size: 28,
            ),
            onPressed: () => _openCompose(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              tooltip: 'Thông báo',
              icon: const Icon(Ionicons.notifications_outline),
              onPressed: () => context.push(RouteNames.notifications),
            ),
          ),
        ],
      );
    }

    final q = _searchController.text.trim();
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      leading: IconButton(
        tooltip: 'Đóng tìm kiếm',
        icon: Icon(
          Icons.arrow_back_rounded,
          color: scheme.onSurface.withValues(alpha: 0.75),
        ),
        onPressed: _exitSearchMode,
      ),
      backgroundColor: bg,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.only(right: hp > 16 ? hp - 16 : 8),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          cursorColor: scheme.primary,
          decoration: InputDecoration(
            hintText: 'Tìm trong các bài đăng…',
            border: InputBorder.none,
            isDense: false,
            isCollapsed: false,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 10,
            ),
            hintStyle: TextStyle(color: colors.textSecondary),
          ),
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
        ),
      ),
      actions: [
        if (q.isNotEmpty)
          IconButton(
            tooltip: 'Xóa ô tìm',
            icon: const Icon(Icons.cancel_outlined),
            onPressed: () {
              _searchController.clear();
              _searchFocusNode.requestFocus();
              setState(() {});
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthGuard.isAuthenticated) {
      return Scaffold(
        backgroundColor: context.appColors.background,
        body: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveLayout.horizontalPadding(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Ionicons.people_outline,
                size: 48,
                color: context.appColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Đăng nhập để xem bài và tương tác với cộng đồng.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: context.appColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  AuthGuard.requireAuth(
                    context,
                    onAuthenticated: () => setState(_primeLoad),
                    message: 'Đăng nhập để dùng Cộng đồng.',
                  );
                },
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ),
      );
    }

    final hp = ResponsiveLayout.horizontalPadding(context);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: _buildAppBar(context, hp),
      body: BlocBuilder<CommunityBloc, CommunityState>(
        builder: (context, cs) {
          final filtered = _filteredPosts(cs.posts);
          final hasQuery =
              _searchMode && _searchController.text.trim().isNotEmpty;

          return CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  context.read<CommunityBloc>().add(const CommunityFeedRefresh());
                  try {
                    await context.read<CommunityBloc>().stream.firstWhere(
                      (s) => s.status != CommunityStatus.refreshing,
                    ).timeout(const Duration(seconds: 30));
                  } catch (_) {}
                },
              ),
              if ((cs.status == CommunityStatus.loading ||
                      cs.status == CommunityStatus.initial) &&
                  cs.posts.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (cs.posts.isEmpty && cs.status == CommunityStatus.failure)
                SliverFillRemaining(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hp),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cs.errorMessage ?? 'Không tải được feed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context
                              .read<CommunityBloc>()
                              .add(const CommunityFeedLoad()),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (cs.posts.isEmpty &&
                  cs.status == CommunityStatus.success)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Chưa có bài đăng. Hãy là người đầu tiên!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else if (hasQuery && filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hp),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Ionicons.search_outline,
                          size: 52,
                          color: context.appColors.textSecondary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có bài phù hợp.',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thử từ khóa khác hoặc xem toàn bộ feed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._postsSlivers(context, hp, cs, filtered),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _postsSlivers(
    BuildContext context,
    double hp,
    CommunityState cs,
    List<CommunityPost> posts,
  ) {
    final myId = switch (context.watch<ProfileBloc>().state) {
      ProfileLoaded u => u.user.id,
      _ => '',
    };
    final extra = cs.status == CommunityStatus.loadingMore ? 1 : 0;

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(hp, 8, hp, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (c, index) {
              if (index < posts.length) {
                final post = posts[index];
                final isMine = myId.isNotEmpty && post.authorId == myId;
                return CommunityPostCard(
                  post: post,
                  onLike: () => context.read<CommunityBloc>().add(
                    CommunityToggleLike(post.id),
                  ),
                  onComment: () =>
                      showPostCommentsSheet(context, post),
                  onDelete: isMine
                      ? () async {
                          final yes = await showDeleteCommunityPostDialog(
                            context,
                            message:
                                'Bài đăng sẽ không còn hiển thị trên cộng đồng.',
                          );
                          if (yes == true && context.mounted) {
                            try {
                              await getIt<CommunityRepository>()
                                  .deletePost(post.id);
                              if (!context.mounted) return;
                              context.read<CommunityBloc>().add(
                                CommunityPostDeleted(post.id),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        }
                      : null,
                );
              }
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            },
            childCount: posts.length + extra,
          ),
        ),
      ),
    ];
  }
}

class _CommunityComposeSheet extends StatefulWidget {
  final ScaffoldMessengerState? parentMessenger;

  const _CommunityComposeSheet({required this.parentMessenger});

  @override
  State<_CommunityComposeSheet> createState() => _CommunityComposeSheetState();
}

class _CommunityComposeSheetState extends State<_CommunityComposeSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  static const _maxChars = 8000;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await getIt<CommunityRepository>().createPost(body: text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      widget.parentMessenger?.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Đăng thành công')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không đăng được: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    final screenH = MediaQuery.of(context).size.height;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: screenH * 0.92),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest.withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: scheme.outline.withValues(alpha: 0.1))),
          boxShadow: [
            BoxShadow(
              blurRadius: 40,
              offset: const Offset(0, -8),
              color: Colors.black.withValues(alpha: 0.18),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sheetH = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : screenH * 0.92;
            return SizedBox(
              height: sheetH,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color:
                                scheme.primaryContainer.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Ionicons.create_outline,
                              color: scheme.primary,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tạo bài viết',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.8,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Cộng đồng của bạn muốn nghe chia sẻ thật, gần gũi.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.35,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pop(false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: scheme.outline.withValues(alpha: 0.09),
                    height: 1,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        maxLength: _maxChars,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  height: 1.42,
                                ),
                        buildCounter: (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) =>
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colors.background
                                        .withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: scheme.outline
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    child: Text(
                                      '$currentLength / $_maxChars',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        decoration: InputDecoration(
                          hintText: 'Viết điều bạn đang nghĩ…',
                          hintStyle: TextStyle(
                            color:
                                colors.textSecondary.withValues(alpha: 0.75),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colors.background,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: scheme.primary.withValues(alpha: 0.55),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(20),
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: scheme.surface,
                    elevation: 0,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        12 + MediaQuery.of(context).padding.bottom,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: scheme.outline.withValues(alpha: 0.09),
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting
                                  ? null
                                  : () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Để sau'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: _submitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_submitting)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Ionicons.rocket_outline,
                                      size: 20,
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _submitting ? 'Đang đăng…' : 'Đăng bài',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
