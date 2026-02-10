import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../auth/data/models/user_enums.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/chat_repository.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class ChatRoomPage extends StatelessWidget {
  final String? conversationId;
  // For new chat (virtual conversation)
  final String? participantId;
  final String? participantName;
  final String? participantAvatar;

  const ChatRoomPage({
    super.key,
    this.conversationId,
    this.participantId,
    this.participantName,
    this.participantAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<ChatBloc>();

        // Load conversations first
        bloc.add(ChatLoadConversations());

        // Connect socket
        bloc.add(const ChatConnectSocket());

        if (conversationId != null) {
          // Existing conversation
          bloc.add(ChatLoadMessages(conversationId: conversationId!));
          bloc.add(ChatJoinRoom(conversationId!));
        } else if (participantId != null) {
          // Virtual conversation (new chat)
          bloc.add(
            ChatSetVirtualConversation(
              participantId: participantId!,
              participantName: participantName ?? 'User',
              participantAvatar: participantAvatar,
            ),
          );
        }

        return bloc;
      },
      child: _ChatRoomContent(
        conversationId: conversationId,
        participantId: participantId,
        participantName: participantName,
        participantAvatar: participantAvatar,
      ),
    );
  }
}

class _ChatRoomContent extends StatefulWidget {
  final String? conversationId;
  final String? participantId;
  final String? participantName;
  final String? participantAvatar;

  const _ChatRoomContent({
    this.conversationId,
    this.participantId,
    this.participantName,
    this.participantAvatar,
  });

  @override
  State<_ChatRoomContent> createState() => _ChatRoomContentState();
}

class _ChatRoomContentState extends State<_ChatRoomContent> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _imagePicker = ImagePicker();
  String? _currentUserId;
  bool _isSearchMode = false;
  bool _showEmojiPicker = false;

  // Typing debounce
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _messageController.addListener(_onTextChanged);
  }

  Future<void> _loadCurrentUserId() async {
    final userId = LocalStorageService.instance.userId;
    if (mounted) {
      setState(() => _currentUserId = userId);
    }
  }

  @override
  void dispose() {
    // Cancel typing timer first
    _typingTimer?.cancel();

    // Remove listeners before disposing controllers
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();

    // Note: Don't access context.read<ChatBloc>() in dispose
    // BlocProvider will automatically close the bloc

    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;

    final conversationId = _getCurrentConversationId();
    if (conversationId == null) return;

    // Start typing
    if (!_isTyping && _messageController.text.isNotEmpty) {
      _isTyping = true;
      context.read<ChatBloc>().add(ChatStartTyping(conversationId));
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _stopTyping();
    });
  }

  void _stopTyping() {
    if (!mounted) return;

    if (_isTyping) {
      _isTyping = false;
      final conversationId = _getCurrentConversationId();
      if (conversationId != null) {
        context.read<ChatBloc>().add(ChatStopTyping(conversationId));
      }
    }
  }

  String? _getCurrentConversationId() {
    if (!mounted) return null;

    // Could be from widget or from bloc state (after first message)
    if (widget.conversationId != null) return widget.conversationId;
    try {
      final state = context.read<ChatBloc>().state;
      return state.activeConversationId;
    } catch (e) {
      return null;
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final state = context.read<ChatBloc>().state;
    final content = _messageController.text.trim();

    // Check if this is a virtual conversation (new chat)
    if (state.isVirtualConversation && state.virtualParticipantId != null) {
      context.read<ChatBloc>().add(
        ChatSendFirstMessage(
          participantId: state.virtualParticipantId!,
          content: content,
        ),
      );
    } else if (widget.conversationId != null) {
      // Existing conversation
      context.read<ChatBloc>().add(
        ChatSendMessage(
          conversationId: widget.conversationId!,
          content: content,
        ),
      );
    } else if (state.activeConversationId != null) {
      // Conversation was created after first message
      context.read<ChatBloc>().add(
        ChatSendMessage(
          conversationId: state.activeConversationId!,
          content: content,
        ),
      );
    }

    _stopTyping();
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null && widget.conversationId != null) {
        context.read<ChatBloc>().add(
          ChatSendImage(
            conversationId: widget.conversationId!,
            imageFile: File(pickedFile.path),
          ),
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn ảnh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        context.read<ChatBloc>().add(const ChatClearSearch());
      }
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty || widget.conversationId == null) return;
    context.read<ChatBloc>().add(
      ChatSearchMessages(
        conversationId: widget.conversationId!,
        query: query.trim(),
      ),
    );
  }

  void _toggleMute(bool currentMuted, [BuildContext? modalContext]) {
    if (widget.conversationId == null) return;
    context.read<ChatBloc>().add(
      ChatToggleMute(
        conversationId: widget.conversationId!,
        mute: !currentMuted,
      ),
    );
    Navigator.pop(modalContext ?? context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(currentMuted ? 'Đã bật thông báo' : 'Đã tắt thông báo'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showBlockUserDialog(String? userId) {
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chặn người dùng'),
        content: const Text(
          'Bạn có chắc chắn muốn chặn người dùng này? '
          'Họ sẽ không thể gửi tin nhắn cho bạn nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ChatBloc>().add(ChatBlockUser(userId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã chặn người dùng'),
                  backgroundColor: AppColors.success,
                ),
              );
              // Go back to chat list
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Chặn'),
          ),
        ],
      ),
    );
  }

  void _toggleEmojiPicker() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    _messageController.text += emoji.emoji;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
    setState(() {});
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (diff.inDays == 1) {
      return 'Hôm qua ${DateFormat('HH:mm').format(dateTime)}';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE HH:mm', 'vi').format(dateTime);
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }

  ConversationEntity? _getConversation(ChatState state) {
    if (widget.conversationId == null) return null;
    try {
      return state.conversations.firstWhere(
        (c) => c.id == widget.conversationId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Lấy currentUserId từ AuthBloc (có ngay) hoặc _currentUserId (load async)
  String? _getCurrentUserId(BuildContext context) {
    if (_currentUserId != null) return _currentUserId;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.user.id;
    if (authState is AuthPendingVerification) return authState.user.id;
    if (authState is AuthNeedsProfileSetup) return authState.user.id;
    if (authState is AuthSuspended) return authState.user.id;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.hasError && state.errorMessage != null) {
          // Check if it's a block-related error
          final isBlockError =
              state.errorMessage!.contains('chặn') ||
              state.errorMessage!.contains('block');

          if (isBlockError) {
            // Show dialog for block errors
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text('Không thể gửi tin nhắn'),
                content: Text(state.errorMessage!),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pop(); // Go back to chat list
                    },
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }

        // Auto scroll when new message arrives
        if (state.status == ChatStatus.success) {
          _scrollToBottom();
        }

        // After first message sent, join the new room
        if (state.activeConversationId != null &&
            widget.conversationId == null) {
          context.read<ChatBloc>().add(
            ChatJoinRoom(state.activeConversationId!),
          );
        }

        // Auto mark as read when new messages arrive while user is in this chat room
        final currentConvId =
            widget.conversationId ?? state.activeConversationId;
        final currentUserId = _getCurrentUserId(context);
        if (currentConvId != null && currentUserId != null) {
          final messages = state.messagesByConversation[currentConvId] ?? [];
          final hasUnreadFromOthers = messages.any(
            (m) => m.senderId != currentUserId && !m.isRead,
          );
          if (hasUnreadFromOthers) {
            // Đánh dấu đã đọc ngay khi đang mở chat
            context.read<ChatBloc>().add(ChatMarkAsRead(currentConvId));
          }
        }
      },
      builder: (context, state) {
        // Get messages from active conversation or virtual
        final conversationId =
            widget.conversationId ?? state.activeConversationId;
        final List<MessageEntity> messages =
            _isSearchMode && state.searchResults.isNotEmpty
            ? state.searchResults
            : (conversationId != null
                  ? (state.messagesByConversation[conversationId] ??
                        <MessageEntity>[])
                  : <MessageEntity>[]);
        final conversation = _getConversation(state);

        // For virtual conversation, use widget params
        final otherUser =
            conversation?.otherUser ??
            (state.isVirtualConversation
                ? OtherUser(
                    id: state.virtualParticipantId!,
                    name: state.virtualParticipantName ?? 'User',
                    avatarUrl: state.virtualParticipantAvatar,
                    isOnline: state.isUserOnline(state.virtualParticipantId!),
                  )
                : null);

        // Get typing status
        final typingUsers = conversationId != null
            ? state.getTypingUsers(conversationId)
            : <String>{};
        final currentUserIdForTyping = _getCurrentUserId(context);
        final isPartnerTyping = typingUsers.isNotEmpty &&
            currentUserIdForTyping != null &&
            !typingUsers.contains(currentUserIdForTyping);

        // Check if the other user is blocked
        final isBlocked =
            otherUser != null && state.isUserBlocked(otherUser.id);

        return GestureDetector(
          onTap: () {
            // Hide emoji picker when tapping outside
            if (_showEmojiPicker) {
              setState(() => _showEmojiPicker = false);
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Column(
              children: [
                _buildHeader(otherUser, isPartnerTyping, state),
                if (_isSearchMode) _buildSearchBar(),
                if (state.isSearching) const LinearProgressIndicator(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.backgroundLight),
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessagesList(
                            context,
                            messages,
                            conversation,
                            isPartnerTyping,
                          ),
                  ),
                ),
                if (!_isSearchMode) _buildInputArea(state, isBlocked),
                // Emoji picker
                if (_showEmojiPicker)
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        top: BorderSide(color: AppColors.border, width: 0.5),
                      ),
                    ),
                    child: EmojiPicker(
                      textEditingController: _messageController,
                      onEmojiSelected: _onEmojiSelected,
                      onBackspacePressed: () {
                        _messageController
                          ..text = _messageController.text.characters.skipLast(1).toString()
                          ..selection = TextSelection.fromPosition(
                              TextPosition(offset: _messageController.text.length));
                        setState(() {});
                      },
                      config: Config(
                        height: 280,
                        checkPlatformCompatibility: true,
                        viewOrderConfig: const ViewOrderConfig(),
                        emojiViewConfig: EmojiViewConfig(
                          columns: 8,
                          emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
                          verticalSpacing: 0,
                          horizontalSpacing: 0,
                          gridPadding: EdgeInsets.zero,
                          backgroundColor: AppColors.surface,
                          recentsLimit: 28,
                          replaceEmojiOnLimitExceed: true,
                          loadingIndicator: const SizedBox.shrink(),
                          buttonMode: ButtonMode.MATERIAL,
                          noRecents: Text(
                            'Chưa có emoji gần đây',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                        categoryViewConfig: CategoryViewConfig(
                          initCategory: Category.RECENT,
                          recentTabBehavior: RecentTabBehavior.RECENT,
                          tabBarHeight: 46,
                          backgroundColor: AppColors.surface,
                          indicatorColor: AppColors.primary,
                          iconColor: AppColors.textHint,
                          iconColorSelected: AppColors.primary,
                          backspaceColor: AppColors.primary,
                          extraTab: CategoryExtraTab.BACKSPACE,
                        ),
                        bottomActionBarConfig: const BottomActionBarConfig(
                          enabled: false,
                        ),
                        skinToneConfig: SkinToneConfig(
                          enabled: true,
                          dialogBackgroundColor: AppColors.surface,
                          indicatorColor: AppColors.textHint,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessagesList(
    BuildContext context,
    List<MessageEntity> messages,
    ConversationEntity? conversation,
    bool isPartnerTyping,
  ) {
    final partnerAvatar = conversation?.otherUser?.avatarUrl ?? '';
    final currentUserId = _getCurrentUserId(context);

    // Tin nhắn đã đọc cuối cùng của tôi (để hiển thị avatar đối phương + animation)
    String? lastReadMessageId;
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      final fromMe = currentUserId != null && m.senderId == currentUserId;
      if (fromMe && (m.isRead || m.status.toUpperCase() == 'READ')) {
        lastReadMessageId = m.id;
        break;
      }
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMe = currentUserId != null && message.senderId == currentUserId;
              final showAvatar =
                  !isMe &&
                  (index == 0 ||
                      messages[index - 1].senderId != message.senderId);
              final isLastReadMessage = isMe &&
                  (message.isRead || message.status.toUpperCase() == 'READ') &&
                  message.id == lastReadMessageId;

              return _MessageBubble(
                key: ValueKey('${message.id}_${message.isRead}'),
                message: message,
                isMe: isMe,
                showAvatar: showAvatar,
                showReadAvatar: isLastReadMessage,
                partnerAvatar: partnerAvatar,
                formattedTime: _formatMessageTime(message.createdAt),
              );
            },
          ),
        ),
        // Typing indicator bubble at bottom of chat
        if (isPartnerTyping) _TypingBubble(avatarUrl: partnerAvatar),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Ionicons.chatbubble_outline, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'Bắt đầu cuộc trò chuyện',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gửi tin nhắn đầu tiên để bắt đầu',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    OtherUser? otherUser,
    bool isPartnerTyping,
    ChatState state,
  ) {
    final name = otherUser?.name ?? widget.participantName ?? 'Partner';
    final avatar = otherUser?.avatarUrl ?? widget.participantAvatar ?? '';

    // Check online status from both otherUser and socket state
    final userId = otherUser?.id ?? widget.participantId;
    final isOnline = userId != null
        ? state.isUserOnline(userId) || (otherUser?.isOnline ?? false)
        : false;

    // Status text
    String statusText;
    Color statusColor;
    if (isPartnerTyping) {
      statusText = 'Đang nhập...';
      statusColor = AppColors.primary;
    } else if (isOnline) {
      statusText = 'Đang hoạt động';
      statusColor = AppColors.online;
    } else {
      statusText = 'Offline';
      statusColor = AppColors.textHint;
    }

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 8,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const AppBackButton(),
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOnline ? AppColors.online : AppColors.border,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: avatar.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ImageUtils.buildImageUrl(avatar),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.backgroundLight,
                            child: const Icon(Ionicons.person_outline),
                          ),
                        )
                      : Container(
                          color: AppColors.backgroundLight,
                          child: const Icon(Ionicons.person_outline),
                        ),
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.online,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    if (isPartnerTyping) ...[
                      _TypingIndicator(),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      statusText,
                      style: AppTypography.labelSmall.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Ionicons.call_outline), onPressed: () {}),
          IconButton(
            icon: const Icon(Ionicons.ellipsis_horizontal_outline),
            onPressed: () => _showOptionsMenu(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatState state, bool isBlocked) {
    // Show blocked UI if user is blocked
    if (isBlocked) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.remove_outline, color: AppColors.textHint, size: 20),
            const SizedBox(width: 8),
            Text(
              'Không thể nhắn tin với người dùng này',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    final isSending = state.status == ChatStatus.sending;

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          GestureDetector(
            onTap: () => _showAttachmentOptions(),
            child: Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Ionicons.add_outline,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _showEmojiPicker ? AppColors.primary : AppColors.border,
                  width: _showEmojiPicker ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !isSending,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        height: 1.4,
                      ),
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      onTap: () {
                        // Hide emoji picker when focusing on text field
                        if (_showEmojiPicker) {
                          setState(() => _showEmojiPicker = false);
                        }
                      },
                      onChanged: (value) {
                        setState(() {});
                      },
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  // Emoji button
                  GestureDetector(
                    onTap: _toggleEmojiPicker,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _showEmojiPicker 
                              ? AppColors.primary.withAlpha(20)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          _showEmojiPicker
                              ? Ionicons.keypad_outline
                              : Ionicons.happy_outline,
                          color: _showEmojiPicker
                              ? AppColors.primary
                              : AppColors.textHint,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button
          GestureDetector(
            onTap: isSending ? null : _sendMessage,
            child: Container(
              width: 46,
              height: 46,
              margin: const EdgeInsets.only(bottom: 1),
              decoration: BoxDecoration(
                gradient: _messageController.text.trim().isEmpty || isSending
                    ? null
                    : LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withAlpha(200),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: _messageController.text.trim().isEmpty || isSending
                    ? AppColors.primary.withAlpha(80)
                    : null,
                shape: BoxShape.circle,
                boxShadow: _messageController.text.trim().isNotEmpty && !isSending
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(60),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Ionicons.send,
                      color: AppColors.textWhite,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    final state = context.read<ChatBloc>().state;
    final conversation = _getConversation(state);
    final otherUserId = conversation?.otherUser?.id;
    final isMuted = conversation?.isMuted ?? false;

    // Ẩn "Đặt lịch hẹn" cho partner - chỉ user mới đặt lịch với partner
    final authState = context.read<AuthBloc>().state;
    bool isCurrentUserPartner = false;
    if (authState is AuthAuthenticated) {
      isCurrentUserPartner = authState.userRole == UserRole.partner;
    } else if (authState is AuthNeedsProfileSetup) {
      isCurrentUserPartner =
          UserRole.fromString(authState.user.role ?? 'USER') == UserRole.partner;
    } else if (authState is AuthPendingVerification) {
      isCurrentUserPartner =
          UserRole.fromString(authState.user.role ?? 'USER') == UserRole.partner;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OptionTile(
                icon: Ionicons.person_outline,
                label: 'Xem hồ sơ',
                onTap: () {
                  Navigator.pop(ctx);
                  if (otherUserId != null) {
                    context.push('/partner/$otherUserId');
                  }
                },
              ),
              // Chỉ hiện "Đặt lịch hẹn" cho user (không phải partner)
              if (!isCurrentUserPartner)
                _OptionTile(
                  icon: Ionicons.calendar_outline,
                  label: 'Đặt lịch hẹn',
                  onTap: () {
                    Navigator.pop(ctx);
                    if (otherUserId != null) {
                      context.push('/booking/create?partnerId=$otherUserId');
                    }
                  },
                ),
              _OptionTile(
                icon: Ionicons.search_outline,
                label: 'Tìm kiếm trong cuộc trò chuyện',
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleSearch();
                },
              ),
              _OptionTile(
                icon: isMuted
                    ? Ionicons.notifications_off_outline
                    : Ionicons.notifications_outline,
                label: isMuted ? 'Bật thông báo' : 'Tắt thông báo',
                onTap: () => _toggleMute(isMuted, ctx),
              ),
              _OptionTile(
                icon: Ionicons.alert_circle_outline,
                label: 'Chặn người dùng',
                onTap: () {
                  Navigator.pop(ctx);
                  _showBlockUserDialog(otherUserId);
                },
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachmentOption(
                    icon: Ionicons.camera_outline,
                    label: 'Camera',
                    color: AppColors.error,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(ImageSource.camera);
                    },
                  ),
                  _AttachmentOption(
                    icon: Ionicons.image_outline,
                    label: 'Thư viện',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tin nhắn...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                prefixIcon: const Icon(Ionicons.search_outline),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: _toggleSearch, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  final bool showAvatar;
  final bool showReadAvatar;
  final String partnerAvatar;
  final String formattedTime;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.showReadAvatar,
    required this.partnerAvatar,
    required this.formattedTime,
  });

  bool get isImageMessage => message.type.toUpperCase() == 'IMAGE';
  bool get isLocationMessage => message.type.toUpperCase() == 'LOCATION';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (showAvatar)
              ClipOval(
                child: partnerAvatar.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ImageUtils.buildImageUrl(partnerAvatar),
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 32,
                          height: 32,
                          color: AppColors.backgroundLight,
                          child: const Icon(Ionicons.person_outline, size: 16),
                        ),
                      )
                    : Container(
                        width: 32,
                        height: 32,
                        color: AppColors.backgroundLight,
                        child: const Icon(Ionicons.person_outline, size: 16),
                      ),
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: isImageMessage
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                border: isMe ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMessageContent(context),
                  const SizedBox(height: 6),
                  Text(
                    formattedTime,
                    style: AppTypography.labelSmall.copyWith(
                      color: isMe
                          ? AppColors.textWhite.withAlpha(200)
                          : AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Avatar đã đọc tách ra ngoài bubble, bên cạnh (bên phải bubble khi isMe)
          if (isMe && showReadAvatar) ...[
            const SizedBox(width: 6),
            _ReadAvatarIndicator(
              partnerAvatar: partnerAvatar,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (isImageMessage) {
      return GestureDetector(
        onTap: () => _showFullImage(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: ImageUtils.buildImageUrl(message.content),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 200,
              height: 200,
              color: AppColors.backgroundLight,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 200,
              height: 200,
              color: AppColors.backgroundLight,
              child: const Icon(Ionicons.image_outline, size: 48),
            ),
          ),
        ),
      );
    }

    if (isLocationMessage) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Ionicons.location_outline,
            color: isMe ? AppColors.textWhite : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Vị trí đã chia sẻ',
            style: AppTypography.bodyLarge.copyWith(
              color: isMe ? AppColors.textWhite : AppColors.textPrimary,
            ),
          ),
        ],
      );
    }

    return Text(
      message.content,
      style: AppTypography.bodyLarge.copyWith(
        color: isMe ? AppColors.textWhite : AppColors.textPrimary,
        height: 1.4,
      ),
      textAlign: isMe ? TextAlign.right : TextAlign.left,
    );
  }

  void _showFullImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: ImageUtils.buildImageUrl(message.content),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar đối phương hiển thị khi tin nhắn đã đọc - có animation trượt xuống như Messenger
class _ReadAvatarIndicator extends StatefulWidget {
  final String partnerAvatar;

  const _ReadAvatarIndicator({required this.partnerAvatar});

  @override
  State<_ReadAvatarIndicator> createState() => _ReadAvatarIndicatorState();
}

class _ReadAvatarIndicatorState extends State<_ReadAvatarIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.textWhite.withAlpha(200),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipOval(
            child: widget.partnerAvatar.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: ImageUtils.buildImageUrl(widget.partnerAvatar),
                    width: 20,
                    height: 20,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 20,
                      height: 20,
                      color: AppColors.card,
                      child: Icon(
                        Ionicons.person_outline,
                        size: 12,
                        color: AppColors.textWhite.withAlpha(200),
                      ),
                    ),
                  )
                : Container(
                    width: 20,
                    height: 20,
                    color: AppColors.card,
                    child: Icon(
                      Ionicons.person_outline,
                      size: 12,
                      color: AppColors.textWhite.withAlpha(200),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.textPrimary,
      ),
      title: Text(
        label,
        style: AppTypography.bodyLarge.copyWith(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Typing bubble - shows when partner is typing at bottom of chat
class _TypingBubble extends StatelessWidget {
  final String avatarUrl;

  const _TypingBubble({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: ClipOval(
              child: avatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ImageUtils.buildImageUrl(avatarUrl),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.backgroundLight,
                        child: const Icon(Ionicons.person_outline, size: 14),
                      ),
                    )
                  : Container(
                      color: AppColors.backgroundLight,
                      child: const Icon(Ionicons.person_outline, size: 14),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          // Typing indicator bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _TypingIndicator(),
          ),
        ],
      ),
    );
  }
}

/// Animated typing indicator (three dots)
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = (index * 0.2);
            final value = (_controller.value + offset) % 1.0;
            final scale = 0.5 + (0.5 * (1 - (2 * value - 1).abs()));
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
