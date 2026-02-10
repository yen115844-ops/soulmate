import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ionicons/ionicons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../buttons/app_button.dart';

/// Empty State Widget - Shown when there's no data
class EmptyStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final String? buttonText;
  final VoidCallback? onAction;
  final IconData? icon;
  final Widget? customIllustration;
  final bool showButton;

  const EmptyStateWidget({
    super.key,
    this.title,
    this.message,
    this.buttonText,
    this.onAction,
    this.icon,
    this.customIllustration,
    this.showButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            customIllustration ??
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon ?? Ionicons.archive_outline,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ).animate().scale(
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    ),

            const SizedBox(height: 24),

            // Title
            Text(
              title ?? 'Không có dữ liệu',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 12),

            // Message
            Text(
              message ?? 'Chưa có nội dung nào ở đây',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),

            if (showButton && onAction != null) ...[
              const SizedBox(height: 32),

              // Action Button
              SizedBox(
                width: 200,
                child: AppButton(
                  text: buttonText ?? 'Khám phá ngay',
                  onPressed: onAction,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            ],
          ],
        ),
      ),
    );
  }
}

/// No Search Results Widget
class NoSearchResultsWidget extends StatelessWidget {
  final String? searchQuery;
  final VoidCallback? onClearSearch;

  const NoSearchResultsWidget({
    super.key,
    this.searchQuery,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Ionicons.search_outline,
      title: 'Không tìm thấy kết quả',
      message: searchQuery != null
          ? 'Không có kết quả cho "$searchQuery". Thử tìm kiếm với từ khóa khác'
          : 'Không tìm thấy kết quả phù hợp. Thử thay đổi bộ lọc',
      buttonText: 'Xóa bộ lọc',
      onAction: onClearSearch,
    );
  }
}

/// No Bookings Widget
class NoBookingsWidget extends StatelessWidget {
  final VoidCallback? onFindPartner;

  const NoBookingsWidget({super.key, this.onFindPartner});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Ionicons.calendar_outline,
      title: 'Chưa có lịch hẹn nào',
      message: 'Bạn chưa có cuộc hẹn nào. Hãy tìm bạn đồng hành và đặt lịch ngay!',
      buttonText: 'Tìm Partner',
      onAction: onFindPartner,
    );
  }
}

/// No Messages Widget
class NoMessagesWidget extends StatelessWidget {
  const NoMessagesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Ionicons.chatbubble_outline,
      title: 'Chưa có tin nhắn',
      message: 'Các cuộc trò chuyện của bạn sẽ xuất hiện ở đây',
      showButton: false,
    );
  }
}

/// No Favorites Widget
class NoFavoritesWidget extends StatelessWidget {
  final VoidCallback? onExplore;

  const NoFavoritesWidget({super.key, this.onExplore});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Ionicons.heart_outline,
      title: 'Chưa có yêu thích',
      message: 'Bạn chưa thêm Partner nào vào danh sách yêu thích',
      buttonText: 'Khám phá ngay',
      onAction: onExplore,
    );
  }
}

/// No Notifications Widget
class NoNotificationsWidget extends StatelessWidget {
  const NoNotificationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Ionicons.notifications_outline,
      title: 'Không có thông báo',
      message: 'Bạn chưa có thông báo mới nào',
      showButton: false,
    );
  }
}

/// No Reviews Widget
class NoReviewsWidget extends StatelessWidget {
  const NoReviewsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Ionicons.star_outline,
      title: 'Chưa có đánh giá',
      message: 'Partner này chưa có đánh giá nào',
      showButton: false,
    );
  }
}

/// No Transactions Widget
class NoTransactionsWidget extends StatelessWidget {
  final VoidCallback? onTopUp;

  const NoTransactionsWidget({super.key, this.onTopUp});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Ionicons.document_text_outline,
      title: 'Chưa có giao dịch',
      message: 'Lịch sử giao dịch của bạn sẽ hiển thị ở đây',
      buttonText: 'Nạp tiền ngay',
      onAction: onTopUp,
    );
  }
}
