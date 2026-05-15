import 'package:equatable/equatable.dart';

/// Author snippet embedded in posts & comments from API (`author`).
class CommunityAuthor extends Equatable {
  final String userId;
  final String displayName;
  final String? avatarUrl;

  const CommunityAuthor({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  factory CommunityAuthor.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const CommunityAuthor(userId: '', displayName: 'Thành viên');
    }
    return CommunityAuthor(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Thành viên',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [userId, displayName, avatarUrl];
}

class CommunityPost extends Equatable {
  final String id;
  final String authorId;
  final CommunityAuthor author;
  final String body;
  final List<String> mediaUrls;
  final int likeCount;
  final int commentCount;
  final String createdAt;
  final bool likedByMe;

  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.author,
    required this.body,
    required this.mediaUrls,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.likedByMe,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final mediaRaw = json['mediaUrls'];
    final mediaUrls = <String>[
      if (mediaRaw is List) ...mediaRaw.whereType<String>(),
    ];
    final a = CommunityAuthor.fromJson(
      json['author'] as Map<String, dynamic>?,
    );
    final authorId = json['authorId'] as String? ?? a.userId;
    final author =
        CommunityAuthor(
          userId: authorId,
          displayName: a.displayName,
          avatarUrl: a.avatarUrl,
        );

    return CommunityPost(
      id: json['id'] as String? ?? '',
      authorId: authorId,
      author: author,
      body: json['body'] as String? ?? '',
      mediaUrls: mediaUrls,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      likedByMe: json['likedByMe'] as bool? ?? false,
    );
  }

  CommunityPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
  }) {
    return CommunityPost(
      id: id,
      authorId: authorId,
      author: author,
      body: body,
      mediaUrls: mediaUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  @override
  List<Object?> get props => [
    id,
    authorId,
    author,
    body,
    mediaUrls,
    likeCount,
    commentCount,
    createdAt,
    likedByMe,
  ];
}

class CommunityComment extends Equatable {
  final String id;
  final String postId;
  final CommunityAuthor author;
  final String body;
  final String createdAt;

  const CommunityComment({
    required this.id,
    required this.postId,
    required this.author,
    required this.body,
    required this.createdAt,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      author: CommunityAuthor.fromJson(
        json['author'] as Map<String, dynamic>?,
      ),
      body: json['body'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, postId, author, body, createdAt];
}

class CommunityFeedResult extends Equatable {
  final List<CommunityPost> items;
  final String? nextCursor;

  const CommunityFeedResult({
    required this.items,
    this.nextCursor,
  });

  @override
  List<Object?> get props => [items, nextCursor];
}
