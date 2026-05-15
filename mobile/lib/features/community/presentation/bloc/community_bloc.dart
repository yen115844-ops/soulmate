import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/community_repository.dart';
import '../../data/models/community_models.dart';
import 'community_event.dart';
import 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository _repository;

  CommunityBloc(this._repository) : super(const CommunityState()) {
    on<CommunityFeedLoad>(_onLoad);
    on<CommunityFeedRefresh>(_onRefresh);
    on<CommunityFeedLoadMore>(_onLoadMore);
    on<CommunityToggleLike>(_onToggleLike);
    on<CommunityPostCreated>(_onPostCreated);
    on<CommunityPostDeleted>(_onPostDeleted);
    on<CommunityCommentAdded>(_onCommentAdded);
    on<CommunityLoggedOut>(_onLoggedOut);
  }

  void _onLoggedOut(
    CommunityLoggedOut event,
    Emitter<CommunityState> emit,
  ) {
    emit(const CommunityState());
  }

  Future<void> _onLoad(
    CommunityFeedLoad event,
    Emitter<CommunityState> emit,
  ) async {
    emit(state.copyWith(status: CommunityStatus.loading, clearError: true));
    try {
      final result = await _repository.fetchFeed(limit: 20);
      emit(
        state.copyWith(
          status: CommunityStatus.success,
          posts: result.items,
          nextCursor: result.nextCursor,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CommunityStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefresh(
    CommunityFeedRefresh event,
    Emitter<CommunityState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CommunityStatus.refreshing,
        clearError: true,
      ),
    );
    try {
      final result = await _repository.fetchFeed(limit: 20);
      emit(
        state.copyWith(
          status: CommunityStatus.success,
          posts: result.items,
          nextCursor: result.nextCursor,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CommunityStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadMore(
    CommunityFeedLoadMore event,
    Emitter<CommunityState> emit,
  ) async {
    final cursor = state.nextCursor;
    if (cursor == null || cursor.isEmpty) return;
    if (state.status == CommunityStatus.loadingMore) return;

    emit(
      state.copyWith(
        status: CommunityStatus.loadingMore,
        clearError: true,
      ),
    );
    try {
      final result = await _repository.fetchFeed(cursor: cursor, limit: 20);
      emit(
        state.copyWith(
          status: CommunityStatus.success,
          posts: [...state.posts, ...result.items],
          nextCursor: result.nextCursor,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CommunityStatus.success,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onToggleLike(
    CommunityToggleLike event,
    Emitter<CommunityState> emit,
  ) async {
    final idx = state.posts.indexWhere((p) => p.id == event.postId);
    if (idx < 0) return;
    final before = state.posts[idx];

    final optimistic = before.copyWith(
      likedByMe: !before.likedByMe,
      likeCount: before.likedByMe ? before.likeCount - 1 : before.likeCount + 1,
    );
    var posts = List<CommunityPost>.from(state.posts);
    posts[idx] = optimistic;
    emit(state.copyWith(posts: posts));

    try {
      final server = await _repository.toggleLike(event.postId);
      posts = List<CommunityPost>.from(state.posts);
      posts[idx] = optimistic.copyWith(
        likedByMe: server.liked,
        likeCount: server.likeCount,
      );
      emit(state.copyWith(posts: posts));
    } catch (_) {
      posts = List<CommunityPost>.from(state.posts);
      posts[idx] = before;
      emit(state.copyWith(posts: posts));
    }
  }

  Future<void> _onPostCreated(
    CommunityPostCreated event,
    Emitter<CommunityState> emit,
  ) async {
    add(const CommunityFeedRefresh());
  }

  void _onPostDeleted(
    CommunityPostDeleted event,
    Emitter<CommunityState> emit,
  ) {
    emit(
      state.copyWith(
        posts: state.posts.where((p) => p.id != event.postId).toList(),
      ),
    );
  }

  void _onCommentAdded(
    CommunityCommentAdded event,
    Emitter<CommunityState> emit,
  ) {
    final idx = state.posts.indexWhere((p) => p.id == event.postId);
    if (idx < 0) return;
    final posts = List<CommunityPost>.from(state.posts);
    final p = posts[idx];
    posts[idx] = p.copyWith(commentCount: p.commentCount + 1);
    emit(state.copyWith(posts: posts));
  }
}
