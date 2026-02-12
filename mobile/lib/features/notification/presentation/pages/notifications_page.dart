import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../shared/data/models/notification_models.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../bloc/notification_bloc.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<NotificationBloc>()..add(const LoadNotifications()),
      child: const _NotificationsPageContent(),
    );
  }
}

class _NotificationsPageContent extends StatelessWidget {
  const _NotificationsPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Thông báo'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                          const MarkAllNotificationsAsRead(),
                        );
                  },
                  child: Text(
                    'Đọc tất cả',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                context
                    .read<NotificationBloc>()
                    .add(const LoadNotifications(refresh: true));
              },
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return const _EmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<NotificationBloc>()
                    .add(const LoadNotifications(refresh: true));
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollEndNotification &&
                      notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 200 &&
                      state.hasMore &&
                      !state.isLoadingMore) {
                    context
                        .read<NotificationBloc>()
                        .add(const LoadMoreNotifications());
                  }
                  return false;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.notifications.length +
                      (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index >= state.notifications.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    final notification = state.notifications[index];
                    return _NotificationItem(
                      notification: notification,
                      onTap: () {
                        // Mark as read
                        if (!notification.isRead) {
                          context.read<NotificationBloc>().add(
                                MarkNotificationAsRead(notification.id),
                              );
                        }

                        // Navigate based on action type
                        _handleNotificationTap(context, notification);
                      },
                      onDismiss: () {
                        context.read<NotificationBloc>().add(
                              DeleteNotification(notification.id),
                            );
                      },
                    );
                  },
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) {
    switch (notification.actionType) {
      case 'booking':
        if (notification.actionId != null &&
            notification.actionId!.isNotEmpty) {
          context.push('/booking/${notification.actionId}');
        }
        break;
      case 'chat':
        if (notification.actionId != null &&
            notification.actionId!.isNotEmpty) {
          context.push('/chat/${notification.actionId}');
        }
        break;
      case 'wallet':
        context.push('/wallet');
        break;
      case 'profile':
        if (notification.actionId != null &&
            notification.actionId!.isNotEmpty) {
          context.push('/partner/${notification.actionId}');
        }
        break;
      case 'review':
        if (notification.actionId != null &&
            notification.actionId!.isNotEmpty) {
          context.push('/booking/${notification.actionId}/review');
        }
        break;
      case 'safety':
        context.push('/sos');
        break;
      default:
        // Do nothing
        break;
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _NotificationItem({
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.booking:
        return Ionicons.calendar_outline;
      case NotificationType.chat:
        return Ionicons.chatbubble_outline;
      case NotificationType.payment:
        return Ionicons.wallet_outline;
      case NotificationType.system:
        return Ionicons.notifications_outline;
      case NotificationType.safety:
        return Ionicons.shield_checkmark_outline;
      case NotificationType.review:
        return Ionicons.star_outline;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.booking:
        return AppColors.success;
      case NotificationType.chat:
        return AppColors.primary;
      case NotificationType.payment:
        return AppColors.secondary;
      case NotificationType.system:
        return AppColors.textSecondary;
      case NotificationType.safety:
        return AppColors.error;
      case NotificationType.review:
        return AppColors.starFilled;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon();
    final iconColor = _getIconColor();

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss?.call(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead
              ? Colors.transparent
              : AppColors.primary.withAlpha(10),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar or Icon
              if (notification.imageUrl != null)
                CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      CachedNetworkImageProvider(notification.imageUrl!),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
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
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification.createdAt),
                      style: AppTypography.labelSmall.copyWith(
                        color: context.appColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Ionicons.notifications_outline,
              size: 48,
              color: context.appColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có thông báo',
            style: AppTypography.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn sẽ nhận được thông báo ở đây',
            style: AppTypography.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Ionicons.alert_circle_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: context.appColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
