import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';

/// Message types supported
class MessageType {
  static const String text = 'text';
  static const String image = 'image';
  static const String voice = 'voice';
  static const String location = 'location';
  static const String system = 'system';
}

/// Chat Repository - Handles chat and messaging
class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get all conversations for current user
  Future<ConversationsResponse> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/chat/conversations',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return ConversationsResponse.fromJson(_extractData(response.data));
    } catch (e) {
      debugPrint('Get conversations error: $e');
      rethrow;
    }
  }

  /// Find existing conversation with a user (does NOT create new one)
  /// Returns virtual conversation info if no conversation exists
  Future<ConversationEntity> findConversation({
    required String participantId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/chat/conversations/find/$participantId',
      );

      return ConversationEntity.fromJson(_extractData(response.data));
    } catch (e) {
      debugPrint('Find conversation error: $e');
      rethrow;
    }
  }

  /// Get or create conversation with another user
  /// NOTE: Only creates new conversation if initialMessage is provided
  Future<ConversationEntity> getOrCreateConversation({
    required String participantId,
    String? initialMessage,
  }) async {
    try {
      final response = await _apiClient.post(
        '/chat/conversations',
        data: {
          'participantId': participantId,
          if (initialMessage != null) 'initialMessage': initialMessage,
        },
      );

      return ConversationEntity.fromJson(_extractData(response.data));
    } catch (e) {
      debugPrint('Get or create conversation error: $e');
      rethrow;
    }
  }

  /// Send first message to a user (creates conversation if needed)
  /// This is the preferred method when starting a new chat
  Future<SendFirstMessageResponse> sendFirstMessage({
    required String participantId,
    required String message,
  }) async {
    try {
      final response = await _apiClient.post(
        '/chat/conversations/send-first',
        data: {
          'participantId': participantId,
          'message': message,
        },
      );

      return SendFirstMessageResponse.fromJson(_extractData(response.data));
    } catch (e) {
      debugPrint('Send first message error: $e');
      rethrow;
    }
  }

  /// Xoá cuộc trò chuyện khỏi danh sách
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _apiClient.delete('/chat/conversations/$conversationId');
    } catch (e) {
      debugPrint('Delete conversation error: $e');
      rethrow;
    }
  }

  /// Get conversation by ID
  Future<ConversationEntity> getConversationById(String conversationId) async {
    try {
      final response = await _apiClient.get(
        '/chat/conversations/$conversationId',
      );

      return ConversationEntity.fromJson(_extractData(response.data));
    } catch (e) {
      debugPrint('Get conversation by ID error: $e');
      rethrow;
    }
  }

  /// Get messages for a conversation
  Future<MessagesResponse> getMessages({
    required String conversationId,
    int page = 1,
    int limit = 50,
    String? before,
  }) async {
    try {
      final response = await _apiClient.get(
        '/chat/conversations/$conversationId/messages',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (before != null) 'before': before,
        },
      );

      return MessagesResponse.fromJson(_extractData(response.data));
    } catch (e) {
      debugPrint('Get messages error: $e');
      rethrow;
    }
  }

  /// Send message in conversation
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
  }) async {
    try {
      final response = await _apiClient.post(
        '/chat/conversations/$conversationId/messages',
        data: {
          'content': content,
          'type': type,
        },
      );

      return MessageEntity.fromJson(_extractData(response.data));
    } catch (e) {
      debugPrint('Send message error: $e');
      rethrow;
    }
  }

  /// Send image message
  Future<MessageEntity> sendImageMessage({
    required String conversationId,
    required File imageFile,
  }) async {
    try {
      // 1. Upload image first
      final imageUrl = await _uploadImage(imageFile);
      
      // 2. Send message with image URL
      final response = await _apiClient.post(
        '/chat/conversations/$conversationId/messages',
        data: {
          'content': imageUrl,
          'type': MessageType.image,
        },
      );

      return MessageEntity.fromJson(_extractData(response.data));
    } catch (e) {
      debugPrint('Send image message error: $e');
      rethrow;
    }
  }

  /// Send location message
  Future<MessageEntity> sendLocationMessage({
    required String conversationId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final locationData = {
        'lat': latitude,
        'lng': longitude,
        if (address != null) 'address': address,
      };
      
      final response = await _apiClient.post(
        '/chat/conversations/$conversationId/messages',
        data: {
          'content': locationData.toString(),
          'type': MessageType.location,
        },
      );

      return MessageEntity.fromJson(_extractData(response.data));
    } catch (e) {
      debugPrint('Send location message error: $e');
      rethrow;
    }
  }

  /// Upload image to server
  Future<String> _uploadImage(File imageFile) async {
    final formData = FormData.fromMap({
      'files': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
    });

    final response = await _apiClient.post('/upload/images', data: formData);
    final data = _extractData(response.data);
    
    if (data['urls'] != null && (data['urls'] as List).isNotEmpty) {
      return (data['urls'] as List).first;
    }
    
    throw Exception('Failed to upload image');
  }

  /// Mute/Unmute conversation
  Future<void> toggleMuteConversation({
    required String conversationId,
    required bool mute,
  }) async {
    try {
      await _apiClient.put(
        '/chat/conversations/$conversationId/mute',
        data: {'muted': mute},
      );
    } catch (e) {
      debugPrint('Toggle mute error: $e');
      rethrow;
    }
  }

  /// Search messages in conversation
  Future<MessagesResponse> searchMessages({
    required String conversationId,
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/chat/conversations/$conversationId/messages/search',
        queryParameters: {
          'query': query,
          'page': page,
          'limit': limit,
        },
      );

      return MessagesResponse.fromJson(_extractData(response.data));
    } catch (e) {
      debugPrint('Search messages error: $e');
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    try {
      await _apiClient.post('/chat/conversations/$conversationId/read');
    } catch (e) {
      debugPrint('Mark as read error: $e');
      rethrow;
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('/chat/unread-count');
      final data = _extractData(response.data);
      return data['unreadCount'] ?? 0;
    } catch (e) {
      debugPrint('Get unread count error: $e');
      return 0;
    }
  }

  /// Block a user
  Future<void> blockUser(String userId) async {
    try {
      await _apiClient.post('/users/block/$userId');
    } catch (e) {
      debugPrint('Block user error: $e');
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    try {
      await _apiClient.delete('/users/block/$userId');
    } catch (e) {
      debugPrint('Unblock user error: $e');
      rethrow;
    }
  }

  /// Get list of blocked users
  Future<List<BlockedUserEntity>> getBlockedUsers() async {
    try {
      final response = await _apiClient.get('/users/blocked/list');
      final data = _extractData(response.data);
      
      // Handle both formats: {data: [...]} or direct array
      List<dynamic> list;
      if (data is Map && data['data'] != null) {
        list = data['data'] as List;
      } else if (data is List) {
        list = data;
      } else {
        return [];
      }
      
      return list.map((e) => BlockedUserEntity.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Get blocked users error: $e');
      rethrow;
    }
  }

  /// Get online status for multiple users
  Future<Map<String, bool>> getOnlineStatus(List<String> userIds) async {
    try {
      final response = await _apiClient.get(
        '/chat/online-status',
        queryParameters: {
          'userIds': userIds.join(','),
        },
      );
      final data = _extractData(response.data);
      return Map<String, bool>.from(data ?? {});
    } catch (e) {
      debugPrint('Get online status error: $e');
      return {};
    }
  }

  dynamic _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data')) {
        return responseData['data'];
      }
    }
    return responseData;
  }
}

// ==================== Models ====================

/// Response for send first message API
class SendFirstMessageResponse {
  final ConversationEntity conversation;
  final MessageEntity message;
  final bool isNew;

  SendFirstMessageResponse({
    required this.conversation,
    required this.message,
    required this.isNew,
  });

  factory SendFirstMessageResponse.fromJson(Map<String, dynamic> json) {
    return SendFirstMessageResponse(
      conversation: ConversationEntity.fromJson(json['conversation'] ?? {}),
      message: MessageEntity.fromJson(json['message'] ?? {}),
      isNew: json['isNew'] ?? false,
    );
  }
}

// ==================== Models ====================

class ConversationsResponse {
  final List<ConversationEntity> conversations;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  ConversationsResponse({
    required this.conversations,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory ConversationsResponse.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? json;
    final dataList = json['data'] as List? ?? [];

    return ConversationsResponse(
      conversations: dataList
          .map((e) => ConversationEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: meta['total'] ?? 0,
      page: meta['page'] ?? 1,
      limit: meta['limit'] ?? 20,
      totalPages: meta['totalPages'] ?? 1,
    );
  }
}

class ConversationEntity {
  final String? id; // null for virtual conversations (not yet created)
  final bool isVirtual; // true if conversation doesn't exist in DB yet
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final DateTime createdAt;
  final OtherUser? otherUser;
  final int unreadCount;
  final bool isMuted;

  ConversationEntity({
    this.id,
    this.isVirtual = false,
    this.lastMessageAt,
    this.lastMessagePreview,
    required this.createdAt,
    this.otherUser,
    this.unreadCount = 0,
    this.isMuted = false,
  });

  /// Check if this is a real conversation (exists in DB)
  bool get isReal => id != null && !isVirtual;

  factory ConversationEntity.fromJson(Map<String, dynamic> json) {
    return ConversationEntity(
      id: json['id']?.toString(),
      isVirtual: json['isVirtual'] ?? false,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      lastMessagePreview: json['lastMessagePreview']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      otherUser: json['otherUser'] != null
          ? OtherUser.fromJson(json['otherUser'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      isMuted: json['isMuted'] ?? false,
    );
  }

  /// Create a copy with updated values
  ConversationEntity copyWith({
    String? id,
    bool? isVirtual,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    DateTime? createdAt,
    OtherUser? otherUser,
    int? unreadCount,
    bool? isMuted,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      isVirtual: isVirtual ?? this.isVirtual,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      createdAt: createdAt ?? this.createdAt,
      otherUser: otherUser ?? this.otherUser,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class OtherUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;

  OtherUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
  });

  factory OtherUser.fromJson(Map<String, dynamic> json) {
    return OtherUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      avatarUrl: json['avatarUrl']?.toString(),
      isOnline: json['isOnline'] ?? false,
    );
  }

  OtherUser copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isOnline,
  }) {
    return OtherUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class MessagesResponse {
  final List<MessageEntity> messages;
  final int total;
  final bool hasMore;

  MessagesResponse({
    required this.messages,
    required this.total,
    required this.hasMore,
  });

  factory MessagesResponse.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? json;
    final dataList = json['data'] as List? ?? [];

    return MessagesResponse(
      messages: dataList
          .map((e) => MessageEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: meta['total'] ?? 0,
      hasMore: meta['hasMore'] ?? false,
    );
  }
}

class MessageEntity {
  final String id;
  final String conversationId;
  final String senderId;
  final String type;
  final String content;
  final String status;
  final DateTime createdAt;
  final DateTime? readAt;
  final MessageSender? sender;

  MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.sender,
  });

  bool get isRead => readAt != null;

  /// Copy with updated fields
  MessageEntity copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? type,
    String? content,
    String? status,
    DateTime? createdAt,
    DateTime? readAt,
    MessageSender? sender,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      sender: sender ?? this.sender,
    );
  }

  factory MessageEntity.fromJson(Map<String, dynamic> json) {
    return MessageEntity(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'TEXT',
      content: json['content']?.toString() ?? '',
      status: json['status']?.toString() ?? 'SENT',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      sender: json['sender'] != null
          ? MessageSender.fromJson(json['sender'])
          : null,
    );
  }
}

class MessageSender {
  final String id;
  final String name;
  final String? avatarUrl;

  MessageSender({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    return MessageSender(
      id: json['id']?.toString() ?? '',
      name: profile?['displayName']?.toString() ??
          profile?['fullName']?.toString() ??
          json['email']?.toString().split('@').first ??
          'User',
      avatarUrl: profile?['avatarUrl']?.toString(),
    );
  }
}

/// Blocked user entity
class BlockedUserEntity {
  final String id;
  final String name;
  final String? avatarUrl;
  final DateTime blockedAt;

  BlockedUserEntity({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.blockedAt,
  });

  factory BlockedUserEntity.fromJson(Map<String, dynamic> json) {
    return BlockedUserEntity(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      avatarUrl: json['avatarUrl']?.toString(),
      blockedAt: json['blockedAt'] != null 
          ? DateTime.parse(json['blockedAt'].toString())
          : DateTime.now(),
    );
  }
}
