import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/chat_socket_service.dart';
import '../../data/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// Chat BLoC - Manages chat conversations and messages
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;
  final ChatSocketService _socketService;

  // Socket subscriptions
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _newMessageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _stoppedTypingSubscription;
  StreamSubscription? _onlineStatusSubscription;
  StreamSubscription? _readReceiptSubscription;
  StreamSubscription? _errorSubscription;
  StreamSubscription? _userBlockedSubscription;
  StreamSubscription? _userUnblockedSubscription;

  ChatBloc({
    required ChatRepository repository,
    ChatSocketService? socketService,
  }) : _repository = repository,
       _socketService = socketService ?? ChatSocketService.instance,
       super(ChatState.initial()) {
    on<ChatLoadConversations>(_onLoadConversations);
    on<ChatLoadMessages>(_onLoadMessages);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatSendFirstMessage>(_onSendFirstMessage);
    on<ChatSendImage>(_onSendImage);
    on<ChatSendLocation>(_onSendLocation);
    on<ChatOpenConversation>(_onOpenConversation);
    on<ChatMarkAsRead>(_onMarkAsRead);
    on<ChatLoadUnreadCount>(_onLoadUnreadCount);
    on<ChatToggleMute>(_onToggleMute);
    on<ChatSearchMessages>(_onSearchMessages);
    on<ChatClearSearch>(_onClearSearch);
    on<ChatBlockUser>(_onBlockUser);

    // Socket events
    on<ChatConnectSocket>(_onConnectSocket);
    on<ChatDisconnectSocket>(_onDisconnectSocket);
    on<ChatJoinRoom>(_onJoinRoom);
    on<ChatLeaveRoom>(_onLeaveRoom);
    on<ChatStartTyping>(_onStartTyping);
    on<ChatStopTyping>(_onStopTyping);
    on<ChatNewMessageReceived>(_onNewMessageReceived);
    on<ChatUserTypingChanged>(_onUserTypingChanged);
    on<ChatUserOnlineChanged>(_onUserOnlineChanged);
    on<ChatMessagesReadReceived>(_onMessagesReadReceived);
    on<ChatSetVirtualConversation>(_onSetVirtualConversation);
    on<ChatSocketError>(_onSocketError);
    on<ChatUserBlockedReceived>(_onUserBlockedReceived);
    on<ChatUserUnblockedReceived>(_onUserUnblockedReceived);
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    _newMessageSubscription?.cancel();
    _typingSubscription?.cancel();
    _stoppedTypingSubscription?.cancel();
    _onlineStatusSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _errorSubscription?.cancel();
    _userBlockedSubscription?.cancel();
    _userUnblockedSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadConversations(
    ChatLoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    try {
      if (event.refresh || state.status == ChatStatus.initial) {
        emit(state.copyWith(status: ChatStatus.loading));
      }

      final response = await _repository.getConversations();

      emit(
        state.copyWith(
          status: ChatStatus.success,
          conversations: response.conversations,
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('ChatBloc: Load conversations error: $e');
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: _getErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onLoadMessages(
    ChatLoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final response = await _repository.getMessages(
        conversationId: event.conversationId,
      );

      final newMessagesMap = Map<String, List<MessageEntity>>.from(
        state.messagesByConversation,
      );
      newMessagesMap[event.conversationId] = response.messages;

      emit(
        state.copyWith(
          status: ChatStatus.success,
          messagesByConversation: newMessagesMap,
          activeConversationId: event.conversationId,
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('ChatBloc: Load messages error: $e');
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: _getErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ChatStatus.sending));

      final message = await _repository.sendMessage(
        conversationId: event.conversationId,
        content: event.content,
      );

      // Add message to local state
      final newMessagesMap = Map<String, List<MessageEntity>>.from(
        state.messagesByConversation,
      );
      final currentMessages =
          newMessagesMap[event.conversationId] ?? <MessageEntity>[];
      newMessagesMap[event.conversationId] = [...currentMessages, message];

      emit(
        state.copyWith(
          status: ChatStatus.success,
          messagesByConversation: newMessagesMap,
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('ChatBloc: Send message error: $e');
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: _getErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onOpenConversation(
    ChatOpenConversation event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ChatStatus.loading));

      final conversation = await _repository.getOrCreateConversation(
        participantId: event.participantId,
        initialMessage: event.initialMessage,
      );

      // Check if conversation already exists in list
      final existingIndex = state.conversations.indexWhere(
        (c) => c.id == conversation.id,
      );

      List<ConversationEntity> updatedConversations;
      if (existingIndex >= 0) {
        updatedConversations = List.from(state.conversations);
        updatedConversations[existingIndex] = conversation;
      } else {
        updatedConversations = [conversation, ...state.conversations];
      }

      emit(
        state.copyWith(
          status: ChatStatus.success,
          conversations: updatedConversations,
          activeConversationId: conversation.id,
          errorMessage: null,
        ),
      );

      // Load messages for this conversation
      if (conversation.id != null) {
        add(ChatLoadMessages(conversationId: conversation.id!));
      }
    } catch (e) {
      debugPrint('ChatBloc: Open conversation error: $e');
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: _getErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _onMarkAsRead(
    ChatMarkAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // Gọi API mark as read
      await _repository.markAsRead(event.conversationId);

      // Emit socket event để người gửi nhận được read receipt ngay lập tức
      _socketService.markAsRead(event.conversationId);

      // Cập nhật local state - đánh dấu tin nhắn của người khác là đã đọc (bởi mình)
      final newMessagesMap = Map<String, List<MessageEntity>>.from(
        state.messagesByConversation,
      );
      final messages = newMessagesMap[event.conversationId];
      final currentUserId = _socketService.currentUserId;
      final readAt = DateTime.now();
      
      if (messages != null && currentUserId != null) {
        // Cập nhật tin nhắn của người khác (không phải của mình) thành đã đọc
        final updatedMessages = messages.map((msg) {
          if (msg.senderId != currentUserId && !msg.isRead) {
            return msg.copyWith(readAt: readAt, status: 'READ');
          }
          return msg;
        }).toList();
        newMessagesMap[event.conversationId] = updatedMessages;
        emit(state.copyWith(messagesByConversation: newMessagesMap));
      }

      // Reload unread count
      add(const ChatLoadUnreadCount());
    } catch (e) {
      debugPrint('ChatBloc: Mark as read error: $e');
    }
  }

  Future<void> _onLoadUnreadCount(
    ChatLoadUnreadCount event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final count = await _repository.getUnreadCount();
      emit(state.copyWith(unreadCount: count));
    } catch (e) {
      debugPrint('ChatBloc: Load unread count error: $e');
    }
  }

  Future<void> _onSendImage(
    ChatSendImage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ChatStatus.uploading));

      final message = await _repository.sendImageMessage(
        conversationId: event.conversationId,
        imageFile: event.imageFile,
      );

      // Add message to local state
      final newMessagesMap = Map<String, List<MessageEntity>>.from(
        state.messagesByConversation,
      );
      final currentMessages =
          newMessagesMap[event.conversationId] ?? <MessageEntity>[];
      newMessagesMap[event.conversationId] = [...currentMessages, message];

      emit(
        state.copyWith(
          status: ChatStatus.success,
          messagesByConversation: newMessagesMap,
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('ChatBloc: Send image error: $e');
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: 'Không thể gửi ảnh. Vui lòng thử lại.',
        ),
      );
    }
  }

  Future<void> _onSendLocation(
    ChatSendLocation event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ChatStatus.sending));

      final message = await _repository.sendLocationMessage(
        conversationId: event.conversationId,
        latitude: event.latitude,
        longitude: event.longitude,
        address: event.address,
      );

      // Add message to local state
      final newMessagesMap = Map<String, List<MessageEntity>>.from(
        state.messagesByConversation,
      );
      final currentMessages =
          newMessagesMap[event.conversationId] ?? <MessageEntity>[];
      newMessagesMap[event.conversationId] = [...currentMessages, message];

      emit(
        state.copyWith(
          status: ChatStatus.success,
          messagesByConversation: newMessagesMap,
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('ChatBloc: Send location error: $e');
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: 'Không thể gửi vị trí. Vui lòng thử lại.',
        ),
      );
    }
  }

  Future<void> _onToggleMute(
    ChatToggleMute event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _repository.toggleMuteConversation(
        conversationId: event.conversationId,
        mute: event.mute,
      );

      // Update local conversation state
      final updatedConversations = state.conversations.map((conv) {
        if (conv.id == event.conversationId) {
          return ConversationEntity(
            id: conv.id,
            lastMessageAt: conv.lastMessageAt,
            lastMessagePreview: conv.lastMessagePreview,
            createdAt: conv.createdAt,
            otherUser: conv.otherUser,
            unreadCount: conv.unreadCount,
            isMuted: event.mute,
          );
        }
        return conv;
      }).toList();

      emit(state.copyWith(conversations: updatedConversations));
    } catch (e) {
      debugPrint('ChatBloc: Toggle mute error: $e');
      emit(
        state.copyWith(errorMessage: 'Không thể thay đổi cài đặt thông báo.'),
      );
    }
  }

  Future<void> _onSearchMessages(
    ChatSearchMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(isSearching: true, searchQuery: event.query));

      final response = await _repository.searchMessages(
        conversationId: event.conversationId,
        query: event.query,
      );

      emit(
        state.copyWith(isSearching: false, searchResults: response.messages),
      );
    } catch (e) {
      debugPrint('ChatBloc: Search messages error: $e');
      emit(state.copyWith(isSearching: false, searchResults: []));
    }
  }

  void _onClearSearch(ChatClearSearch event, Emitter<ChatState> emit) {
    emit(
      state.copyWith(searchResults: [], searchQuery: null, isSearching: false),
    );
  }

  Future<void> _onBlockUser(
    ChatBlockUser event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _repository.blockUser(event.userId);

      // Remove conversations with blocked user from list
      final updatedConversations = state.conversations
          .where((c) => c.otherUser?.id != event.userId)
          .toList();

      emit(
        state.copyWith(
          conversations: updatedConversations,
          status: ChatStatus.success,
        ),
      );
    } catch (e) {
      debugPrint('ChatBloc: Block user error: $e');
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: 'Không thể chặn người dùng. Vui lòng thử lại.',
        ),
      );
    }
  }

  // ==================== Socket Event Handlers ====================

  Future<void> _onConnectSocket(
    ChatConnectSocket event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _socketService.connect();
      _setupSocketListeners();
      emit(state.copyWith(isSocketConnected: true));
    } catch (e) {
      debugPrint('ChatBloc: Connect socket error: $e');
    }
  }

  void _onDisconnectSocket(
    ChatDisconnectSocket event,
    Emitter<ChatState> emit,
  ) {
    _socketService.disconnect();
    emit(state.copyWith(isSocketConnected: false));
  }

  void _onJoinRoom(ChatJoinRoom event, Emitter<ChatState> emit) {
    _socketService.joinConversation(event.conversationId);
  }

  void _onLeaveRoom(ChatLeaveRoom event, Emitter<ChatState> emit) {
    _socketService.leaveConversation(event.conversationId);
  }

  void _onStartTyping(ChatStartTyping event, Emitter<ChatState> emit) {
    _socketService.startTyping(event.conversationId);
  }

  void _onStopTyping(ChatStopTyping event, Emitter<ChatState> emit) {
    _socketService.stopTyping(event.conversationId);
  }

  void _onNewMessageReceived(
    ChatNewMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final message = event.message;
    final conversationId = message.conversationId;

    // Skip if this message was sent by current user
    // (they already have it from the API response)
    if (message.senderId == _socketService.currentUserId) {
      debugPrint('ChatBloc: Skipping own message from socket');
      return;
    }

    // Add message to local state
    final newMessagesMap = Map<String, List<MessageEntity>>.from(
      state.messagesByConversation,
    );
    final currentMessages = newMessagesMap[conversationId] ?? <MessageEntity>[];

    // Avoid duplicates
    if (!currentMessages.any((m) => m.id == message.id)) {
      newMessagesMap[conversationId] = [...currentMessages, message];

      emit(state.copyWith(messagesByConversation: newMessagesMap));
    }
  }

  void _onUserTypingChanged(
    ChatUserTypingChanged event,
    Emitter<ChatState> emit,
  ) {
    final newTypingUsers = Map<String, Set<String>>.from(state.typingUsers);
    final conversationTyping = Set<String>.from(
      newTypingUsers[event.conversationId] ?? {},
    );

    if (event.isTyping) {
      conversationTyping.add(event.userId);
    } else {
      conversationTyping.remove(event.userId);
    }

    newTypingUsers[event.conversationId] = conversationTyping;
    emit(state.copyWith(typingUsers: newTypingUsers));
  }

  void _onUserOnlineChanged(
    ChatUserOnlineChanged event,
    Emitter<ChatState> emit,
  ) {
    final newOnlineUsers = Map<String, bool>.from(state.onlineUsers);
    newOnlineUsers[event.userId] = event.isOnline;

    // Update conversations list with new online status
    final updatedConversations = state.conversations.map((conv) {
      if (conv.otherUser?.id == event.userId) {
        return conv.copyWith(
          otherUser: conv.otherUser?.copyWith(isOnline: event.isOnline),
        );
      }
      return conv;
    }).toList();

    emit(
      state.copyWith(
        onlineUsers: newOnlineUsers,
        conversations: updatedConversations,
      ),
    );
  }

  void _onMessagesReadReceived(
    ChatMessagesReadReceived event,
    Emitter<ChatState> emit,
  ) {
    // Update message statuses to READ for the conversation
    final newMessagesMap = Map<String, List<MessageEntity>>.from(
      state.messagesByConversation,
    );
    final messages = newMessagesMap[event.conversationId];

    if (messages != null && messages.isNotEmpty) {
      // Người đọc (readBy) là người khác, không phải mình
      // Cập nhật readAt cho tất cả tin nhắn của mình (senderId != readBy)
      final currentUserId = _socketService.currentUserId;
      final readAt = event.readAt ?? DateTime.now();

      final updatedMessages = messages.map((msg) {
        // Chỉ cập nhật tin nhắn của mình mà chưa được đọc
        if (msg.senderId == currentUserId && !msg.isRead) {
          return msg.copyWith(readAt: readAt, status: 'READ');
        }
        return msg;
      }).toList();

      newMessagesMap[event.conversationId] = updatedMessages;
      
      debugPrint('ChatBloc: Messages read by ${event.readBy}, updated messages with readAt');
      emit(state.copyWith(
        messagesByConversation: newMessagesMap,
        status: ChatStatus.success,
      ));
    }
  }

  void _onSetVirtualConversation(
    ChatSetVirtualConversation event,
    Emitter<ChatState> emit,
  ) {
    emit(
      state.copyWith(
        virtualParticipantId: event.participantId,
        virtualParticipantName: event.participantName,
        virtualParticipantAvatar: event.participantAvatar,
        clearActiveConversation: true,
        status: ChatStatus.success,
      ),
    );
  }

  /// Send first message to create conversation
  Future<void> _onSendFirstMessage(
    ChatSendFirstMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ChatStatus.sending));

      final response = await _repository.sendFirstMessage(
        participantId: event.participantId,
        message: event.content,
      );

      // Add message to local state
      final newMessagesMap = Map<String, List<MessageEntity>>.from(
        state.messagesByConversation,
      );
      newMessagesMap[response.conversation.id!] = [response.message];

      // Add conversation to list if new
      List<ConversationEntity> updatedConversations;
      if (response.isNew) {
        updatedConversations = [response.conversation, ...state.conversations];
      } else {
        // Update existing conversation
        final existingIndex = state.conversations.indexWhere(
          (c) => c.id == response.conversation.id,
        );
        if (existingIndex >= 0) {
          updatedConversations = List.from(state.conversations);
          updatedConversations[existingIndex] = response.conversation;
        } else {
          updatedConversations = [
            response.conversation,
            ...state.conversations,
          ];
        }
      }

      emit(
        state.copyWith(
          status: ChatStatus.success,
          conversations: updatedConversations,
          messagesByConversation: newMessagesMap,
          activeConversationId: response.conversation.id,
          clearVirtualParticipant: true,
          errorMessage: null,
        ),
      );

      // Join socket room for new conversation
      if (response.conversation.id != null) {
        _socketService.joinConversation(response.conversation.id!);
      }
    } catch (e) {
      debugPrint('ChatBloc: Send first message error: $e');
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: _getErrorMessage(e),
        ),
      );
    }
  }

  void _onSocketError(ChatSocketError event, Emitter<ChatState> emit) {
    debugPrint('ChatBloc: Socket error: ${event.error}');
    // Only show user-facing error messages for block-related errors
    if (event.error.contains('Không thể nhắn tin') ||
        event.error.contains('Không thể gửi') ||
        event.error.contains('chặn') ||
        event.error.contains('blocked') ||
        event.error.contains('người dùng này')) {
      emit(state.copyWith(status: ChatStatus.error, errorMessage: event.error));
    }
  }

  void _onUserBlockedReceived(
    ChatUserBlockedReceived event,
    Emitter<ChatState> emit,
  ) {
    debugPrint('ChatBloc: User blocked event: ${event.data}');

    // The data can be:
    // - { blockedUserId: "..." } - when current user blocked someone
    // - { blockedBy: "..." } - when current user was blocked by someone
    final blockedUserId = event.data['blockedUserId'] as String?;
    final blockedBy = event.data['blockedBy'] as String?;

    // Remove conversation with the blocked user from the list
    final userIdToRemove = blockedUserId ?? blockedBy;
    if (userIdToRemove != null) {
      final updatedConversations = state.conversations.where((conv) {
        return conv.otherUser?.id != userIdToRemove;
      }).toList();

      // Add to blocked users set
      final updatedBlockedUsers = Set<String>.from(state.blockedUserIds)
        ..add(userIdToRemove);

      emit(
        state.copyWith(
          conversations: updatedConversations,
          blockedUserIds: updatedBlockedUsers,
        ),
      );

      debugPrint(
        'ChatBloc: Removed conversation with user $userIdToRemove and added to blocked list',
      );
    }
  }

  void _onUserUnblockedReceived(
    ChatUserUnblockedReceived event,
    Emitter<ChatState> emit,
  ) {
    debugPrint('ChatBloc: User unblocked event: ${event.data}');
    // When a user is unblocked, we can optionally refresh conversations
    // For now, we just log it - conversations will appear when user refreshes
  }

  void _setupSocketListeners() {
    // Cancel existing subscriptions
    _connectionSubscription?.cancel();
    _newMessageSubscription?.cancel();
    _typingSubscription?.cancel();
    _stoppedTypingSubscription?.cancel();
    _onlineStatusSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _errorSubscription?.cancel();
    _userBlockedSubscription?.cancel();
    _userUnblockedSubscription?.cancel();

    // Connection status
    _connectionSubscription = _socketService.onConnectionChanged.listen((
      connected,
    ) {
      add(connected ? const ChatConnectSocket() : const ChatDisconnectSocket());
    });

    // New messages
    _newMessageSubscription = _socketService.onNewMessage.listen((
      socketMessage,
    ) {
      final message = MessageEntity(
        id: socketMessage.id,
        conversationId: socketMessage.conversationId,
        senderId: socketMessage.senderId,
        type: socketMessage.type,
        content: socketMessage.content,
        status: socketMessage.status,
        createdAt: socketMessage.createdAt,
        sender: socketMessage.sender != null
            ? MessageSender.fromJson(socketMessage.sender!)
            : null,
      );
      add(ChatNewMessageReceived(message));
    });

    // Typing indicators
    _typingSubscription = _socketService.onUserTyping.listen((event) {
      add(
        ChatUserTypingChanged(
          conversationId: event.conversationId,
          userId: event.userId,
          isTyping: true,
        ),
      );
    });

    _stoppedTypingSubscription = _socketService.onUserStoppedTyping.listen((
      event,
    ) {
      add(
        ChatUserTypingChanged(
          conversationId: event.conversationId,
          userId: event.userId,
          isTyping: false,
        ),
      );
    });

    // Online status
    _onlineStatusSubscription = _socketService.onOnlineStatusChanged.listen((
      event,
    ) {
      add(
        ChatUserOnlineChanged(userId: event.userId, isOnline: event.isOnline),
      );
    });

    // Read receipts
    _readReceiptSubscription = _socketService.onMessagesRead.listen((event) {
      add(
        ChatMessagesReadReceived(
          conversationId: event.conversationId,
          readBy: event.readBy,
          readAt: event.readAt,
          lastReadMessageId: event.lastReadMessageId,
        ),
      );
    });

    // Socket errors
    _errorSubscription = _socketService.onError.listen((error) {
      add(ChatSocketError(error));
    });

    // User blocked events
    _userBlockedSubscription = _socketService.onUserBlocked.listen((data) {
      add(ChatUserBlockedReceived(data));
    });

    // User unblocked events
    _userUnblockedSubscription = _socketService.onUserUnblocked.listen((data) {
      add(ChatUserUnblockedReceived(data));
    });
  }

  String _getErrorMessage(dynamic error) {
    // Handle Dio errors with server response
    if (error is DioException) {
      final response = error.response;
      if (response != null) {
        final data = response.data;
        if (data is Map && data['message'] != null) {
          // Return server message directly (e.g., "Không thể nhắn tin với người dùng này")
          return data['message'].toString();
        }
      }

      // Handle connection errors
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown) {
        return 'Không có kết nối mạng. Vui lòng kiểm tra và thử lại.';
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Kết nối quá chậm. Vui lòng thử lại.';
      }
    }

    // Handle custom API exceptions
    if (error.toString().contains('Không thể nhắn tin')) {
      return error.toString();
    }

    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection')) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra và thử lại.';
    }
    if (error.toString().contains('TimeoutException')) {
      return 'Kết nối quá chậm. Vui lòng thử lại.';
    }
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }
}
