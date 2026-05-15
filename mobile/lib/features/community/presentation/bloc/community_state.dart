import 'package:equatable/equatable.dart';

import '../../data/models/community_models.dart';

enum CommunityStatus { initial, loading, refreshing, loadingMore, success, failure }

class CommunityState extends Equatable {
  final CommunityStatus status;
  final List<CommunityPost> posts;
  final String? nextCursor;
  final String? errorMessage;

  const CommunityState({
    this.status = CommunityStatus.initial,
    this.posts = const [],
    this.nextCursor,
    this.errorMessage,
  });

  bool get canLoadMore =>
      nextCursor != null &&
      nextCursor!.isNotEmpty &&
      status != CommunityStatus.loadingMore;

  CommunityState copyWith({
    CommunityStatus? status,
    List<CommunityPost>? posts,
    String? nextCursor,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommunityState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      nextCursor: nextCursor ?? this.nextCursor,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, posts, nextCursor, errorMessage];
}
