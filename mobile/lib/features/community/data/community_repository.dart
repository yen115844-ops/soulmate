import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import 'models/community_models.dart';

class CommunityRepository {
  final ApiClient _apiClient;

  CommunityRepository(this._apiClient);

  Map<String, dynamic> _unwrap(dynamic responseData) {
    final m = responseData as Map<String, dynamic>;
    return (m['data'] as Map<String, dynamic>?) ?? m;
  }

  Future<CommunityFeedResult> fetchFeed({
    String? cursor,
    int limit = 20,
    String? authorId,
    String? search,
    DateTime? since,
  }) async {
    final response = await _apiClient.get(
      CommunityEndpoints.posts,
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
        if (authorId != null) 'authorId': authorId,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (since != null) 'since': since.toUtc().toIso8601String(),
      },
    );
    final data = _unwrap(response.data);
    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
        .toList();
    final nextCursor = data['nextCursor'] as String?;
    return CommunityFeedResult(items: items, nextCursor: nextCursor);
  }

  Future<CommunityPost> createPost({
    required String body,
    List<String>? mediaUrls,
  }) async {
    final response = await _apiClient.post(
      CommunityEndpoints.posts,
      data: {
        'body': body,
        if (mediaUrls != null && mediaUrls.isNotEmpty) 'mediaUrls': mediaUrls,
      },
    );
    final data = _unwrap(response.data);
    return CommunityPost.fromJson(data);
  }

  Future<void> deletePost(String postId) async {
    await _apiClient.delete(CommunityEndpoints.postDetail(postId));
  }

  Future<({bool liked, int likeCount})> toggleLike(String postId) async {
    final response =
        await _apiClient.post(CommunityEndpoints.postLike(postId));
    final data = _unwrap(response.data);
    final liked = data['liked'] as bool? ?? false;
    final likeCount = (data['likeCount'] as num?)?.toInt() ?? 0;
    return (liked: liked, likeCount: likeCount);
  }

  Future<CommunityComment> addComment({
    required String postId,
    required String body,
  }) async {
    final response = await _apiClient.post(
      CommunityEndpoints.postComments(postId),
      data: {'body': body},
    );
    final data = _unwrap(response.data);
    return CommunityComment.fromJson(data);
  }

  Future<({List<CommunityComment> items, String? nextCursor})> fetchComments({
    required String postId,
    String? cursor,
    int limit = 30,
  }) async {
    final response = await _apiClient.get(
      CommunityEndpoints.postComments(postId),
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );
    final data = _unwrap(response.data);
    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .map((e) => CommunityComment.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, nextCursor: data['nextCursor'] as String?);
  }

  Future<CommunityPost?> fetchPost(String postId) async {
    try {
      final response = await _apiClient.get(
        CommunityEndpoints.postDetail(postId),
      );
      final data = _unwrap(response.data);
      return CommunityPost.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
