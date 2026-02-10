import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../data/chat_repository.dart';

/// Chat BLoC Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Load conversations
class ChatLoadConversations extends ChatEvent {
  final bool refresh;

  const ChatLoadConversations({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

/// Load messages for a conversation
class ChatLoadMessages extends ChatEvent {
  final String conversationId;
  final bool refresh;

  const ChatLoadMessages({
    required this.conversationId,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [conversationId, refresh];
}

/// Send message (for existing conversation)
class ChatSendMessage extends ChatEvent {
  final String conversationId;
  final String content;

  const ChatSendMessage({
    required this.conversationId,
    required this.content,
  });

  @override
  List<Object?> get props => [conversationId, content];
}

/// Send first message (creates conversation if needed)
class ChatSendFirstMessage extends ChatEvent {
  final String participantId;
  final String content;

  const ChatSendFirstMessage({
    required this.participantId,
    required this.content,
  });

  @override
  List<Object?> get props => [participantId, content];
}

/// Send image message
class ChatSendImage extends ChatEvent {
  final String conversationId;
  final File imageFile;

  const ChatSendImage({
    required this.conversationId,
    required this.imageFile,
  });

  @override
  List<Object?> get props => [conversationId, imageFile];
}

/// Send location message
class ChatSendLocation extends ChatEvent {
  final String conversationId;
  final double latitude;
  final double longitude;
  final String? address;

  const ChatSendLocation({
    required this.conversationId,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  List<Object?> get props => [conversationId, latitude, longitude, address];
}

/// Create or open conversation
class ChatOpenConversation extends ChatEvent {
  final String participantId;
  final String? initialMessage;

  const ChatOpenConversation({
    required this.participantId,
    this.initialMessage,
  });

  @override
  List<Object?> get props => [participantId, initialMessage];
}

/// Mark conversation as read
class ChatMarkAsRead extends ChatEvent {
  final String conversationId;

  const ChatMarkAsRead(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Load unread count
class ChatLoadUnreadCount extends ChatEvent {
  const ChatLoadUnreadCount();
}

/// Toggle mute conversation
class ChatToggleMute extends ChatEvent {
  final String conversationId;
  final bool mute;

  const ChatToggleMute({
    required this.conversationId,
    required this.mute,
  });

  @override
  List<Object?> get props => [conversationId, mute];
}

/// Search messages in conversation
class ChatSearchMessages extends ChatEvent {
  final String conversationId;
  final String query;

  const ChatSearchMessages({
    required this.conversationId,
    required this.query,
  });

  @override
  List<Object?> get props => [conversationId, query];
}

/// Clear search results
class ChatClearSearch extends ChatEvent {
  const ChatClearSearch();
}

/// Block a user
class ChatBlockUser extends ChatEvent {
  final String userId;

  const ChatBlockUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

// ==================== Socket Events ====================

/// Connect to chat socket
class ChatConnectSocket extends ChatEvent {
  const ChatConnectSocket();
}

/// Disconnect from chat socket
class ChatDisconnectSocket extends ChatEvent {
  const ChatDisconnectSocket();
}

/// Join conversation room (for real-time updates)
class ChatJoinRoom extends ChatEvent {
  final String conversationId;

  const ChatJoinRoom(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Leave conversation room
class ChatLeaveRoom extends ChatEvent {
  final String conversationId;

  const ChatLeaveRoom(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Start typing indicator
class ChatStartTyping extends ChatEvent {
  final String conversationId;

  const ChatStartTyping(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Stop typing indicator
class ChatStopTyping extends ChatEvent {
  final String conversationId;

  const ChatStopTyping(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Received new message from socket
class ChatNewMessageReceived extends ChatEvent {
  final MessageEntity message;

  const ChatNewMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

/// User typing status changed
class ChatUserTypingChanged extends ChatEvent {
  final String conversationId;
  final String userId;
  final bool isTyping;

  const ChatUserTypingChanged({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [conversationId, userId, isTyping];
}

/// User online status changed
class ChatUserOnlineChanged extends ChatEvent {
  final String userId;
  final bool isOnline;

  const ChatUserOnlineChanged({
    required this.userId,
    required this.isOnline,
  });

  @override
  List<Object?> get props => [userId, isOnline];
}

/// Messages read receipt received
class ChatMessagesReadReceived extends ChatEvent {
  final String conversationId;
  final String readBy;
  final DateTime? readAt;
  final String? lastReadMessageId;

  const ChatMessagesReadReceived({
    required this.conversationId,
    required this.readBy,
    this.readAt,
    this.lastReadMessageId,
  });

  @override
  List<Object?> get props => [conversationId, readBy, readAt, lastReadMessageId];
}

/// Set virtual conversation (for new chat before first message)
class ChatSetVirtualConversation extends ChatEvent {
  final String participantId;
  final String participantName;
  final String? participantAvatar;

  const ChatSetVirtualConversation({
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
  });

  @override
  List<Object?> get props => [participantId, participantName, participantAvatar];
}

/// Socket error received
class ChatSocketError extends ChatEvent {
  final String error;

  const ChatSocketError(this.error);

  @override
  List<Object?> get props => [error];
}

/// User blocked event received from socket
class ChatUserBlockedReceived extends ChatEvent {
  final Map<String, dynamic> data;

  const ChatUserBlockedReceived(this.data);

  @override
  List<Object?> get props => [data];
}

/// User unblocked event received from socket
class ChatUserUnblockedReceived extends ChatEvent {
  final Map<String, dynamic> data;

  const ChatUserUnblockedReceived(this.data);

  @override
  List<Object?> get props => [data];
}
