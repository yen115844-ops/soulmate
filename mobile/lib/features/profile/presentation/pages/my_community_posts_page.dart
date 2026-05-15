import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme_context.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/profile_my_community_posts_section.dart';

/// Danh sách bài cộng đồng của người dùng đang đăng nhập (mở từ mục Cá nhân).
class MyCommunityPostsPage extends StatefulWidget {
  const MyCommunityPostsPage({super.key});

  @override
  State<MyCommunityPostsPage> createState() => _MyCommunityPostsPageState();
}

class _MyCommunityPostsPageState extends State<MyCommunityPostsPage> {
  late final ScrollController _scrollController;
  final GlobalKey<ProfileMyCommunityPostsSectionState> _sectionKey =
      GlobalKey<ProfileMyCommunityPostsSectionState>();

  @override
  void initState() {
    super.initState();
    final pb = getIt<ProfileBloc>();
    if (pb.state is! ProfileLoaded) {
      pb.add(const ProfileLoadRequested());
    }
    _scrollController = ScrollController();
    _scrollController.addListener(_onScrollNearBottom);
  }

  void _onScrollNearBottom() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      _sectionKey.currentState?.loadMoreIfNeeded();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileBloc = getIt<ProfileBloc>();

    return BlocProvider.value(
      value: profileBloc,
      child: BlocBuilder<ProfileBloc, ProfileState>(
        bloc: profileBloc,
        builder: (context, state) {
          final scheme = Theme.of(context).colorScheme;
          final userId = switch (state) {
            ProfileLoaded u => u.user.id,
            _ => '',
          };

          Widget body;
          if (state is ProfileLoading ||
              (userId.isEmpty && state is! ProfileError)) {
            body = const Center(child: CircularProgressIndicator());
          } else if (state is ProfileError && userId.isEmpty) {
            body = Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.appColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          profileBloc.add(const ProfileLoadRequested()),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          } else {
            body = RefreshIndicator(
              onRefresh: () async {
                profileBloc.add(const ProfileRefreshRequested());
                await _sectionKey.currentState?.reload();
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  ProfileMyCommunityPostsSection(
                    key: _sectionKey,
                    userId: userId,
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            );
          }

          return Scaffold(
            backgroundColor: context.appColors.background,
            appBar: AppBar(
              title: const Text('Bài viết cộng đồng'),
              backgroundColor: context.appColors.background,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              foregroundColor: scheme.onSurface,
            ),
            body: body,
          );
        },
      ),
    );
  }
}
