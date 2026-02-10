import 'package:equatable/equatable.dart';

import '../../data/chat_repository.dart';

/// Chat BLoC State
class ChatState extends Equatable {
  final ChatStatus status;
  final List<ConversationEntity> conversations;
  final Map<String, List<MessageEntity>> messagesByConversation;
  final String? activeConversationId;
  final int unreadCount;
  final String? errorMessage;
  final List<MessageEntity> searchResults;
  final String? searchQuery;
  final bool isSearching;

  // Socket & Real-time state
  final bool isSocketConnected;
  final Map<String, bool> onlineUsers; // userId -> isOnline
  final Map<String, Set<String>> typingUsers; // conversationId -> Set<userId>

  // Virtual conversation (for new chat before first message)
  final String? virtualParticipantId;
  final String? virtualParticipantName;
  final String? virtualParticipantAvatar;

  // Block status - track blocked users for current chat room
  final Set<String> blockedUserIds;

  const ChatState({
    this.status = ChatStatus.initial,
    this.conversations = const [],
    this.messagesByConversation = const {},
    this.activeConversationId,
    this.unreadCount = 0,
    this.errorMessage,
    this.searchResults = const [],
    this.searchQuery,
    this.isSearching = false,
    this.isSocketConnected = false,
    this.onlineUsers = const {},
    this.typingUsers = const {},
    this.virtualParticipantId,
    this.virtualParticipantName,
    this.virtualParticipantAvatar,
    this.blockedUserIds = const {},
  });

  factory ChatState.initial() => const ChatState();

  bool get isLoading => status == ChatStatus.loading;
  bool get isSuccess => status == ChatStatus.success;
  bool get hasError => status == ChatStatus.error;

  /// Check if this is a virtual/new conversation (not yet created in DB)
  bool get isVirtualConversation =>
      virtualParticipantId != null && activeConversationId == null;

  List<MessageEntity> get activeMessages => activeConversationId != null
      ? messagesByConversation[activeConversationId] ?? []
      : [];

  /// Check if a user is online
  bool isUserOnline(String userId) => onlineUsers[userId] ?? false;

  /// Check if a user is blocked (either blocked by current user or blocked current user)
  bool isUserBlocked(String userId) => blockedUserIds.contains(userId);

  /// Get typing users for a conversation
  Set<String> getTypingUsers(String conversationId) =>
      typingUsers[conversationId] ?? {};

  ChatState copyWith({
    ChatStatus? status,
    List<ConversationEntity>? conversations,
    Map<String, List<MessageEntity>>? messagesByConversation,
    String? activeConversationId,
    bool clearActiveConversation = false,
    int? unreadCount,
    String? errorMessage,
    List<MessageEntity>? searchResults,
    String? searchQuery,
    bool? isSearching,
    bool? isSocketConnected,
    Map<String, bool>? onlineUsers,
    Map<String, Set<String>>? typingUsers,
    String? virtualParticipantId,
    bool clearVirtualParticipant = false,
    String? virtualParticipantName,
    String? virtualParticipantAvatar,
    Set<String>? blockedUserIds,
  }) {
    return ChatState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      messagesByConversation:
          messagesByConversation ?? this.messagesByConversation,
      activeConversationId: clearActiveConversation
          ? null
          : (activeConversationId ?? this.activeConversationId),
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
      searchResults: searchResults ?? this.searchResults,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      typingUsers: typingUsers ?? this.typingUsers,
      virtualParticipantId: clearVirtualParticipant
          ? null
          : (virtualParticipantId ?? this.virtualParticipantId),
      virtualParticipantName: clearVirtualParticipant
          ? null
          : (virtualParticipantName ?? this.virtualParticipantName),
      virtualParticipantAvatar: clearVirtualParticipant
          ? null
          : (virtualParticipantAvatar ?? this.virtualParticipantAvatar),
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
    );
  }

  @override
  List<Object?> get props => [
    status,
    conversations,
    messagesByConversation,
    activeConversationId,
    unreadCount,
    errorMessage,
    searchResults,
    searchQuery,
    isSearching,
    isSocketConnected,
    onlineUsers,
    typingUsers,
    virtualParticipantId,
    virtualParticipantName,
    virtualParticipantAvatar,
    blockedUserIds,
  ];
}

enum ChatStatus { initial, loading, success, error, sending, uploading }
