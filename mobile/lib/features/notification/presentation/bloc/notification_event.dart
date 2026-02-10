import 'package:equatable/equatable.dart';

/// Events for NotificationBloc
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load notifications event
class LoadNotifications extends NotificationEvent {
  final bool refresh;

  const LoadNotifications({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

/// Load more notifications event (pagination)
class LoadMoreNotifications extends NotificationEvent {
  const LoadMoreNotifications();
}

/// Mark a single notification as read
class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Mark all notifications as read
class MarkAllNotificationsAsRead extends NotificationEvent {
  const MarkAllNotificationsAsRead();
}

/// Delete a single notification
class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Delete all read notifications
class DeleteAllReadNotifications extends NotificationEvent {
  const DeleteAllReadNotifications();
}

/// Refresh unread count only
class RefreshUnreadCount extends NotificationEvent {
  const RefreshUnreadCount();
}
