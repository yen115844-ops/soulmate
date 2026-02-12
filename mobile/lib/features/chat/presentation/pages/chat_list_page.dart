import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/chat_socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/image_utils.dart';
import '../../data/chat_repository.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late ChatRepository _chatRepository;
  final ChatSocketService _socketService = ChatSocketService.instance;

  bool _isLoading = true;
  List<ConversationEntity> _conversations = [];
  List<ConversationEntity> _filteredConversations = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Socket subscriptions
  StreamSubscription? _newMessageSubscription;
  StreamSubscription? _conversationUpdatedSubscription;
  StreamSubscription? _onlineStatusSubscription;
  StreamSubscription? _userBlockedSubscription;

  @override
  void initState() {
    super.initState();
    _initRepository();
    _loadData();
    _connectSocket();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newMessageSubscription?.cancel();
    _conversationUpdatedSubscription?.cancel();
    _onlineStatusSubscription?.cancel();
    _userBlockedSubscription?.cancel();
    super.dispose();
  }

  void _initRepository() {
    _chatRepository = getIt<ChatRepository>();
  }

  void _connectSocket() {
    // Connect to socket if not connected
    _socketService.connect();

    // Listen for new messages to update conversation preview
    _newMessageSubscription = _socketService.onNewMessage.listen((message) {
      debugPrint(
        'ChatListPage: New message received for conversation ${message.conversationId}',
      );
      _updateConversationWithNewMessage(message);
    });

    // Listen for conversation updates (new conversation created)
    _conversationUpdatedSubscription = _socketService.onConversationUpdated
        .listen((data) {
          debugPrint('ChatListPage: Conversation updated');
          _loadData(); // Reload all conversations
        });

    // Listen for online status changes
    _onlineStatusSubscription = _socketService.onOnlineStatusChanged.listen((
      event,
    ) {
      _updateUserOnlineStatus(event.userId, event.isOnline);
    });

    // Listen for user blocked events - remove conversation with blocked user
    _userBlockedSubscription = _socketService.onUserBlocked.listen((data) {
      debugPrint('ChatListPage: User blocked event: $data');
      final blockedUserId = data['blockedUserId'] as String?;
      final blockedBy = data['blockedBy'] as String?;
      final userIdToRemove = blockedUserId ?? blockedBy;
      if (userIdToRemove != null) {
        _removeConversationWithUser(userIdToRemove);
      }
    });
  }

  void _updateConversationWithNewMessage(SocketMessage message) {
    if (!mounted) return;

    // Refresh từ server để lấy đúng unreadCount, tránh đếm gấp đôi
    _refreshConversationsSilently();
  }

  void _updateUserOnlineStatus(String userId, bool isOnline) {
    if (!mounted) return;

    setState(() {
      for (int i = 0; i < _conversations.length; i++) {
        if (_conversations[i].otherUser?.id == userId) {
          _conversations[i] = _conversations[i].copyWith(
            otherUser: _conversations[i].otherUser?.copyWith(
              isOnline: isOnline,
            ),
          );
        }
      }
      _filterConversations(_searchController.text);
    });
  }

  void _removeConversationWithUser(String userId) {
    if (!mounted) return;

    setState(() {
      _conversations.removeWhere((conv) => conv.otherUser?.id == userId);
      _filterConversations(_searchController.text);
    });

    debugPrint('ChatListPage: Removed conversation with user $userId');
  }

  void _filterConversations(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredConversations = _conversations;
      });
    } else {
      final lowerQuery = query.toLowerCase();
      setState(() {
        _filteredConversations = _conversations.where((conv) {
          final name = (conv.otherUser?.name ?? '').toLowerCase();
          final lastMessage = (conv.lastMessagePreview ?? '').toLowerCase();
          return name.contains(lowerQuery) || lastMessage.contains(lowerQuery);
        }).toList();
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredConversations = _conversations;
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _chatRepository.getConversations(
        page: 1,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _conversations = response.conversations;
          _filteredConversations = response.conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Refresh danh sách từ server không bật loading (dùng khi nhận tin mới qua socket)
  Future<void> _refreshConversationsSilently() async {
    try {
      final response = await _chatRepository.getConversations(
        page: 1,
        limit: 50,
      );

      if (mounted) {
        final query = _searchController.text;
        setState(() {
          _conversations = response.conversations;
          _filteredConversations = query.isEmpty
              ? response.conversations
              : response.conversations.where((conv) {
                  final name = (conv.otherUser?.name ?? '').toLowerCase();
                  final lastMessage = (conv.lastMessagePreview ?? '')
                      .toLowerCase();
                  final lowerQuery = query.toLowerCase();
                  return name.contains(lowerQuery) ||
                      lastMessage.contains(lowerQuery);
                }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error refreshing conversations: $e');
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút';
    if (diff.inDays < 1) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${dateTime.day}/${dateTime.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isSearching ? null : const SizedBox.shrink(),
        leadingWidth: _isSearching ? null : 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm cuộc trò chuyện...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: context.appColors.textHint,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                ),
                style: AppTypography.bodyLarge,
                onChanged: _filterConversations,
              )
            : const Text('Tin nhắn'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Ionicons.search_outline),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
          ? _EmptyState()
          : _filteredConversations.isEmpty
          ? _buildNoResultsState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredConversations.length,
              itemBuilder: (context, index) {
                final conversation = _filteredConversations[index];
                return Dismissible(
                  key: ValueKey(conversation.id ?? 'conv_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Ionicons.trash_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xoá cuộc trò chuyện'),
                        content: Text(
                          'Bạn có chắc muốn xoá cuộc trò chuyện với ${conversation.otherUser?.name ?? 'người này'}? Cuộc trò chuyện sẽ bị ẩn khỏi danh sách.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Huỷ'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Xoá'),
                          ),
                        ],
                      ),
                    );
                    return confirm ?? false;
                  },
                  onDismissed: (direction) async {
                    final convId = conversation.id;
                    if (convId == null || conversation.isVirtual) return;
                    try {
                      await _chatRepository.deleteConversation(convId);
                      if (mounted) {
                        setState(() {
                          _conversations.removeWhere(
                            (c) => c.id == conversation.id,
                          );
                          _filterConversations(_searchController.text);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã xoá cuộc trò chuyện'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        _loadData(); // Reload to restore item
                      }
                    }
                  },
                  child: _ConversationItem(
                    name: conversation.otherUser?.name ?? 'User',
                    avatar: conversation.otherUser?.avatarUrl ?? '',
                    lastMessage: conversation.lastMessagePreview ?? '',
                    time: _formatTime(conversation.lastMessageAt),
                    unreadCount: conversation.unreadCount,
                    isOnline: conversation.otherUser?.isOnline ?? false,
                    onTap: () async {
                      await context.push('/chat/${conversation.id}');
                      if (mounted) _loadData();
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Ionicons.search_outline, size: 64, color: context.appColors.textHint),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả',
            style: AppTypography.titleMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử tìm kiếm với từ khóa khác',
            style: AppTypography.bodyMedium.copyWith(color: context.appColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _ConversationItem extends StatelessWidget {
  final String name;
  final String avatar;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final VoidCallback? onTap;

  const _ConversationItem({
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar with online status
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: context.appColors.background,
                  backgroundImage: avatar.isNotEmpty
                      ? CachedNetworkImageProvider(
                          ImageUtils.buildImageUrl(avatar),
                        )
                      : null,
                  child: avatar.isEmpty
                      ? Icon(
                          Ionicons.person_outline,
                          color: context.appColors.textHint,
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.appColors.surface, width: 3),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      Text(
                        time,
                        style: AppTypography.labelSmall.copyWith(
                          color: unreadCount > 0
                              ? AppColors.primary
                              : context.appColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: AppTypography.bodyMedium.copyWith(
                            color: unreadCount > 0
                                ? context.appColors.textPrimary
                                : context.appColors.textSecondary,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.appColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Ionicons.chatbubble_outline,
              size: 48,
              color: context.appColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          Text('Chưa có tin nhắn', style: AppTypography.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Đặt lịch để bắt đầu trò chuyện',
            style: AppTypography.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
