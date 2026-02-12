import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../network/api_config.dart';
import '../services/local_storage_service.dart';

/// Chat Socket Events from Server
class ChatServerEvents {
  static const String authenticated = 'chat:authenticated';
  static const String error = 'chat:error';
  static const String joinedConversation = 'chat:joined_conversation';
  static const String leftConversation = 'chat:left_conversation';
  static const String newMessage = 'chat:new_message';
  static const String messageSent = 'chat:message_sent';
  static const String messageDelivered = 'chat:message_delivered';
  static const String userTyping = 'chat:user_typing';
  static const String userStoppedTyping = 'chat:user_stopped_typing';
  static const String messageRead = 'chat:message_read';
  static const String messagesRead = 'chat:messages_read';
  static const String userOnline = 'chat:user_online';
  static const String userOffline = 'chat:user_offline';
  static const String onlineStatus = 'chat:online_status';
  static const String conversationUpdated = 'chat:conversation_updated';
  static const String userBlocked = 'chat:user_blocked';
  static const String userUnblocked = 'chat:user_unblocked';
}

/// Chat Socket Events to Server
class ChatClientEvents {
  static const String authenticate = 'chat:authenticate';
  static const String joinConversation = 'chat:join_conversation';
  static const String leaveConversation = 'chat:leave_conversation';
  static const String sendMessage = 'chat:send_message';
  static const String typingStart = 'chat:typing_start';
  static const String typingStop = 'chat:typing_stop';
  static const String markRead = 'chat:mark_read';
  static const String getOnlineStatus = 'chat:get_online_status';
}

/// Socket Message Data
class SocketMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final Map<String, dynamic>? sender;
  final String content;
  final String type;
  final String status;
  final String? mediaUrl;
  final DateTime createdAt;
  final String? tempId;

  SocketMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.sender,
    required this.content,
    required this.type,
    required this.status,
    this.mediaUrl,
    required this.createdAt,
    this.tempId,
  });

  factory SocketMessage.fromJson(Map<String, dynamic> json) {
    return SocketMessage(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      sender: json['sender'] as Map<String, dynamic>?,
      content: json['content'] ?? '',
      type: json['type'] ?? 'TEXT',
      status: json['status'] ?? 'SENT',
      mediaUrl: json['mediaUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      tempId: json['tempId'],
    );
  }
}

/// Typing Event Data
class TypingEvent {
  final String conversationId;
  final String userId;
  final DateTime timestamp;

  TypingEvent({
    required this.conversationId,
    required this.userId,
    required this.timestamp,
  });

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    return TypingEvent(
      conversationId: json['conversationId'] ?? '',
      userId: json['userId'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Online Status Event
class OnlineStatusEvent {
  final String userId;
  final bool isOnline;
  final DateTime timestamp;

  OnlineStatusEvent({
    required this.userId,
    required this.isOnline,
    required this.timestamp,
  });

  factory OnlineStatusEvent.fromJson(Map<String, dynamic> json, bool online) {
    return OnlineStatusEvent(
      userId: json['userId'] ?? '',
      isOnline: online,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Read Receipt Event
class ReadReceiptEvent {
  final String conversationId;
  final String readBy;
  final String? lastReadMessageId;
  final DateTime readAt;

  ReadReceiptEvent({
    required this.conversationId,
    required this.readBy,
    this.lastReadMessageId,
    required this.readAt,
  });

  factory ReadReceiptEvent.fromJson(Map<String, dynamic> json) {
    return ReadReceiptEvent(
      conversationId: json['conversationId'] ?? '',
      readBy: json['readBy'] ?? '',
      lastReadMessageId: json['lastReadMessageId'],
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'])
          : DateTime.now(),
    );
  }
}

/// Message Delivered Event
class MessageDeliveredEvent {
  final String conversationId;
  final String messageId;
  final List<String> deliveredTo;
  final DateTime deliveredAt;

  MessageDeliveredEvent({
    required this.conversationId,
    required this.messageId,
    required this.deliveredTo,
    required this.deliveredAt,
  });

  factory MessageDeliveredEvent.fromJson(Map<String, dynamic> json) {
    return MessageDeliveredEvent(
      conversationId: json['conversationId'] ?? '',
      messageId: json['messageId'] ?? '',
      deliveredTo: (json['deliveredTo'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : DateTime.now(),
    );
  }
}

/// Chat Socket Service - Manages WebSocket connection for real-time chat
class ChatSocketService {
  static ChatSocketService? _instance;
  static ChatSocketService get instance {
    _instance ??= ChatSocketService._();
    return _instance!;
  }

  ChatSocketService._();

  io.Socket? _socket;
  bool _isConnected = false;
  bool _isAuthenticated = false;
  String? _currentUserId;

  // Stream Controllers
  final _connectionController = StreamController<bool>.broadcast();
  final _newMessageController = StreamController<SocketMessage>.broadcast();
  final _messageSentController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeliveredController = StreamController<MessageDeliveredEvent>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _stoppedTypingController = StreamController<TypingEvent>.broadcast();
  final _messagesReadController = StreamController<ReadReceiptEvent>.broadcast();
  final _onlineStatusController = StreamController<OnlineStatusEvent>.broadcast();
  final _conversationUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _userBlockedController = StreamController<Map<String, dynamic>>.broadcast();
  final _userUnblockedController = StreamController<Map<String, dynamic>>.broadcast();

  // Public Streams
  Stream<bool> get onConnectionChanged => _connectionController.stream;
  Stream<SocketMessage> get onNewMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get onMessageSent => _messageSentController.stream;
  Stream<MessageDeliveredEvent> get onMessageDelivered => _messageDeliveredController.stream;
  Stream<TypingEvent> get onUserTyping => _typingController.stream;
  Stream<TypingEvent> get onUserStoppedTyping => _stoppedTypingController.stream;
  Stream<ReadReceiptEvent> get onMessagesRead => _messagesReadController.stream;
  Stream<OnlineStatusEvent> get onOnlineStatusChanged => _onlineStatusController.stream;
  Stream<Map<String, dynamic>> get onConversationUpdated => _conversationUpdatedController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<Map<String, dynamic>> get onUserBlocked => _userBlockedController.stream;
  Stream<Map<String, dynamic>> get onUserUnblocked => _userUnblockedController.stream;

  // Getters
  bool get isConnected => _isConnected;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;

  /// Get socket URL from API config
  String get _socketUrl {
    // Convert http://localhost:3000/api to ws://localhost:3000
    String baseUrl = ApiConfig.baseUrl;
    baseUrl = baseUrl.replaceAll('/api', '');
    return baseUrl;
  }

  /// Connect to chat socket
  Future<void> connect() async {
    if (_socket != null && _isConnected) {
      debugPrint('ChatSocket: Already connected');
      return;
    }

    try {
      final storage = LocalStorageService.instance;
      final token = storage.accessToken;
      _currentUserId = storage.userId;

      if (token == null || _currentUserId == null) {
        debugPrint('ChatSocket: No token or userId, cannot connect');
        return;
      }

      debugPrint('ChatSocket: Connecting to $_socketUrl/chat');

      _socket = io.io(
        '$_socketUrl/chat',
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setAuth({
              'token': token,
              'userId': _currentUserId,
            })
            .build(),
      );

      _setupEventListeners();
      _socket!.connect();
    } catch (e) {
      debugPrint('ChatSocket: Connection error: $e');
      _errorController.add('Connection error: $e');
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      debugPrint('ChatSocket: Connected');
      _isConnected = true;
      _connectionController.add(true);
      
      // Authenticate after connection
      _authenticate();
    });

    _socket!.onDisconnect((_) {
      debugPrint('ChatSocket: Disconnected');
      _isConnected = false;
      _isAuthenticated = false;
      _connectionController.add(false);
    });

    _socket!.onConnectError((error) {
      debugPrint('ChatSocket: Connection error: $error');
      _isConnected = false;
      _errorController.add('Connection error: $error');
    });

    _socket!.onError((error) {
      debugPrint('ChatSocket: Error: $error');
      _errorController.add('Socket error: $error');
    });

    // Authentication response
    _socket!.on(ChatServerEvents.authenticated, (data) {
      debugPrint('ChatSocket: Authenticated');
      _isAuthenticated = true;
    });

    _socket!.on(ChatServerEvents.error, (data) {
      debugPrint('ChatSocket: Server error: $data');
      _errorController.add(data?['error'] ?? 'Unknown error');
    });

    // Message events
    _socket!.on(ChatServerEvents.newMessage, (data) {
      debugPrint('ChatSocket: New message received');
      if (data != null && data['message'] != null) {
        final message = SocketMessage.fromJson(data['message']);
        _newMessageController.add(message);
      }
    });

    _socket!.on(ChatServerEvents.messageSent, (data) {
      debugPrint('ChatSocket: Message sent confirmed');
      if (data != null) {
        _messageSentController.add(data as Map<String, dynamic>);
      }
    });

    _socket!.on(ChatServerEvents.messageDelivered, (data) {
      debugPrint('ChatSocket: Message delivered');
      if (data != null) {
        final event = MessageDeliveredEvent.fromJson(data);
        _messageDeliveredController.add(event);
      }
    });

    // Typing events
    _socket!.on(ChatServerEvents.userTyping, (data) {
      debugPrint('ChatSocket: User typing');
      if (data != null) {
        final event = TypingEvent.fromJson(data);
        _typingController.add(event);
      }
    });

    _socket!.on(ChatServerEvents.userStoppedTyping, (data) {
      debugPrint('ChatSocket: User stopped typing');
      if (data != null) {
        final event = TypingEvent.fromJson(data);
        _stoppedTypingController.add(event);
      }
    });

    // Read receipt events
    _socket!.on(ChatServerEvents.messagesRead, (data) {
      debugPrint('ChatSocket: Messages read');
      if (data != null) {
        final event = ReadReceiptEvent.fromJson(data);
        _messagesReadController.add(event);
      }
    });

    // Online status events
    _socket!.on(ChatServerEvents.userOnline, (data) {
      debugPrint('ChatSocket: User online');
      if (data != null) {
        final event = OnlineStatusEvent.fromJson(data, true);
        _onlineStatusController.add(event);
      }
    });

    _socket!.on(ChatServerEvents.userOffline, (data) {
      debugPrint('ChatSocket: User offline');
      if (data != null) {
        final event = OnlineStatusEvent.fromJson(data, false);
        _onlineStatusController.add(event);
      }
    });

    _socket!.on(ChatServerEvents.onlineStatus, (data) {
      debugPrint('ChatSocket: Online status response: $data');
      // This contains multiple user statuses from server
      // data format: { onlineUsers: { userId1: true, userId2: true, ... } }
      if (data != null && data['onlineUsers'] != null) {
        final onlineUsers = data['onlineUsers'] as Map<String, dynamic>;
        onlineUsers.forEach((userId, isOnline) {
          if (isOnline == true) {
            final event = OnlineStatusEvent(
              userId: userId,
              isOnline: true,
              timestamp: DateTime.now(),
            );
            _onlineStatusController.add(event);
          }
        });
      }
    });

    // Conversation updates
    _socket!.on(ChatServerEvents.conversationUpdated, (data) {
      debugPrint('ChatSocket: Conversation updated');
      if (data != null) {
        _conversationUpdatedController.add(data as Map<String, dynamic>);
      }
    });

    // User block events
    _socket!.on(ChatServerEvents.userBlocked, (data) {
      debugPrint('ChatSocket: User blocked event: $data');
      if (data != null) {
        _userBlockedController.add(data as Map<String, dynamic>);
      }
    });

    _socket!.on(ChatServerEvents.userUnblocked, (data) {
      debugPrint('ChatSocket: User unblocked event: $data');
      if (data != null) {
        _userUnblockedController.add(data as Map<String, dynamic>);
      }
    });
  }

  void _authenticate() {
    if (_socket == null || !_isConnected) return;

    final storage = LocalStorageService.instance;
    final token = storage.accessToken;
    final userId = storage.userId;

    if (token == null || userId == null) {
      debugPrint('ChatSocket: Cannot authenticate - no token or userId');
      return;
    }

    debugPrint('ChatSocket: Authenticating user $userId');
    _socket!.emitWithAck(ChatClientEvents.authenticate, {
      'token': token,
      'userId': userId,
    }, ack: (response) {
      debugPrint('ChatSocket: Auth response: $response');
      if (response != null && response['success'] == true) {
        _isAuthenticated = true;
      }
    });
  }

  /// Disconnect from socket and notify listeners.
  ///
  /// Stream controllers are NOT closed here because they're broadcast controllers
  /// and will be reused on reconnect. They are only closed in [dispose].
  void disconnect() {
    debugPrint('ChatSocket: Disconnecting');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isAuthenticated = false;
    // Notify listeners that connection is lost
    if (!_connectionController.isClosed) {
      _connectionController.add(false);
    }
  }

  /// Join a conversation room
  void joinConversation(String conversationId) {
    if (!_isConnected || !_isAuthenticated) {
      debugPrint('ChatSocket: Cannot join - not connected or authenticated');
      return;
    }

    debugPrint('ChatSocket: Joining conversation $conversationId');
    _socket?.emitWithAck(ChatClientEvents.joinConversation, {
      'conversationId': conversationId,
    }, ack: (response) {
      debugPrint('ChatSocket: Join response: $response');
    });
  }

  /// Leave a conversation room
  void leaveConversation(String conversationId) {
    if (!_isConnected) return;

    debugPrint('ChatSocket: Leaving conversation $conversationId');
    _socket?.emit(ChatClientEvents.leaveConversation, {
      'conversationId': conversationId,
    });
  }

  /// Send a message through socket
  void sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    String? tempId,
    String? mediaUrl,
    Map<String, dynamic>? location,
  }) {
    if (!_isConnected || !_isAuthenticated) {
      debugPrint('ChatSocket: Cannot send - not connected or authenticated');
      _errorController.add('Not connected');
      return;
    }

    debugPrint('ChatSocket: Sending message to $conversationId');
    _socket?.emitWithAck(ChatClientEvents.sendMessage, {
      'conversationId': conversationId,
      'content': content,
      'type': type,
      if (tempId != null) 'tempId': tempId,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (location != null) 'location': location,
    }, ack: (response) {
      debugPrint('ChatSocket: Send message response: $response');
      if (response != null && response['success'] == true) {
        _messageSentController.add(response['message'] ?? {});
      } else {
        _errorController.add(response?['error'] ?? 'Failed to send message');
      }
    });
  }

  /// Start typing indicator
  void startTyping(String conversationId) {
    if (!_isConnected || !_isAuthenticated) return;

    _socket?.emit(ChatClientEvents.typingStart, {
      'conversationId': conversationId,
    });
  }

  /// Stop typing indicator
  void stopTyping(String conversationId) {
    if (!_isConnected || !_isAuthenticated) return;

    _socket?.emit(ChatClientEvents.typingStop, {
      'conversationId': conversationId,
    });
  }

  /// Mark messages as read
  void markAsRead(String conversationId, {String? messageId}) {
    if (!_isConnected || !_isAuthenticated) return;

    debugPrint('ChatSocket: Marking messages as read in $conversationId');
    _socket?.emit(ChatClientEvents.markRead, {
      'conversationId': conversationId,
      if (messageId != null) 'messageId': messageId,
    });
  }

  /// Get online status for users
  void getOnlineStatus(List<String> userIds) {
    if (!_isConnected || !_isAuthenticated) return;

    _socket?.emitWithAck(ChatClientEvents.getOnlineStatus, {
      'userIds': userIds,
    }, ack: (response) {
      debugPrint('ChatSocket: Online status response: $response');
      if (response != null && response['success'] == true) {
        final Map<String, dynamic> statuses = response['onlineStatus'] ?? {};
        for (final entry in statuses.entries) {
          _onlineStatusController.add(OnlineStatusEvent(
            userId: entry.key,
            isOnline: entry.value == true,
            timestamp: DateTime.now(),
          ));
        }
      }
    });
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _connectionController.close();
    _newMessageController.close();
    _messageSentController.close();
    _messageDeliveredController.close();
    _typingController.close();
    _stoppedTypingController.close();
    _messagesReadController.close();
    _onlineStatusController.close();
    _conversationUpdatedController.close();
    _errorController.close();
    _userBlockedController.close();
    _userUnblockedController.close();
    _instance = null;
  }
}
