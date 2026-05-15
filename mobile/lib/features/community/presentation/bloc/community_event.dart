import 'package:equatable/equatable.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();

  @override
  List<Object?> get props => [];
}

class CommunityFeedLoad extends CommunityEvent {
  const CommunityFeedLoad();
}

class CommunityFeedRefresh extends CommunityEvent {
  const CommunityFeedRefresh();
}

class CommunityFeedLoadMore extends CommunityEvent {
  const CommunityFeedLoadMore();
}

class CommunityToggleLike extends CommunityEvent {
  final String postId;

  const CommunityToggleLike(this.postId);

  @override
  List<Object?> get props => [postId];
}

class CommunityPostCreated extends CommunityEvent {
  const CommunityPostCreated();
}

class CommunityPostDeleted extends CommunityEvent {
  final String postId;

  const CommunityPostDeleted(this.postId);

  @override
  List<Object?> get props => [postId];
}

/// Đăng comment thành công trong sheet → cập nhật badge trên thẻ bài trong feed.
class CommunityCommentAdded extends CommunityEvent {
  final String postId;

  const CommunityCommentAdded(this.postId);

  @override
  List<Object?> get props => [postId];
}

/// Xóa cache feed khi phiên đăng nhập kết thúc (tránh lộ bàiUser cũ).
class CommunityLoggedOut extends CommunityEvent {
  const CommunityLoggedOut();
}
