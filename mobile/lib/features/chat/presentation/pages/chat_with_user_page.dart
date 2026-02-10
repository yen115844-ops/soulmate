import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/chat_repository.dart';

class ChatWithUserPage extends StatefulWidget {
  final String userId;
  final String? initialMessage;

  const ChatWithUserPage({
    super.key,
    required this.userId,
    this.initialMessage,
  });

  @override
  State<ChatWithUserPage> createState() => _ChatWithUserPageState();
}

class _ChatWithUserPageState extends State<ChatWithUserPage> {
  late ChatRepository _chatRepository;
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initRepository();
    _openConversation();
  }

  void _initRepository() {
    final storage = LocalStorageService.instance;
    final apiClient = ApiClient(storage: storage);
    _chatRepository = ChatRepository(apiClient: apiClient);
    _currentUserId = storage.userId;
  }

  Future<void> _openConversation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Kiểm tra không cho chat với chính mình
      if (_currentUserId == widget.userId) {
        setState(() {
          _isLoading = false;
          _error = 'Bạn không thể chat với chính mình.';
        });
        return;
      }

      // Gọi API để TÌM conversation (KHÔNG tạo mới)
      // Điều này tránh tạo ra conversation rỗng
      final conversation = await _chatRepository.findConversation(
        participantId: widget.userId,
      );

      if (mounted) {
        if (conversation.isReal) {
          // Conversation đã tồn tại -> mở trực tiếp
          context.pushReplacement('/chat/${conversation.id}');
        } else {
          // Conversation chưa tồn tại -> mở với mode "new"
          // Truyền userId qua extra để ChatRoomPage biết đây là chat mới
          context.pushReplacement(
            '/chat/new',
            extra: {
              'participantId': widget.userId,
              'participantName': conversation.otherUser?.name ?? 'User',
              'participantAvatar': conversation.otherUser?.avatarUrl,
              'initialMessage': widget.initialMessage,
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Open conversation error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(e);
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('socketexception') ||
        errorStr.contains('connection')) {
      return 'Không có kết nối mạng. Vui lòng kiểm tra và thử lại.';
    }
    if (errorStr.contains('timeout')) {
      return 'Kết nối quá chậm. Vui lòng thử lại.';
    }
    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return 'Không tìm thấy người dùng này.';
    }
    // Handle block error
    if (errorStr.contains('không thể nhắn tin') ||
        errorStr.contains('chặn') ||
        errorStr.contains('blocked') ||
        errorStr.contains('403')) {
      return 'Không thể nhắn tin với người dùng này.';
    }
    return 'Không thể mở cuộc trò chuyện. Vui lòng thử lại.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Đang mở cuộc trò chuyện...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            : _error != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _openConversation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              )
            : const SizedBox(),
      ),
    );
  }
}
