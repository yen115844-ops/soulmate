import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/error_utils.dart';
import '../../../../shared/data/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

// Re-export events and states for backward compatibility
export 'notification_event.dart';
export 'notification_state.dart';

/// BLoC for notification management
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  static const int _pageSize = 20;

  NotificationBloc({required NotificationRepository repository})
    : _repository = repository,
      super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadMoreNotifications>(_onLoadMoreNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<DeleteAllReadNotifications>(_onDeleteAllReadNotifications);
    on<RefreshUnreadCount>(_onRefreshUnreadCount);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (!event.refresh) {
        emit(NotificationLoading());
      }

      final response = await _repository.getNotifications(
        page: 1,
        limit: _pageSize,
      );

      emit(NotificationLoaded(
        notifications: response.data,
        unreadCount: response.meta.unreadCount,
        totalPages: response.meta.totalPages,
        currentPage: 1,
        hasMore: response.meta.page < response.meta.totalPages,
      ));
    } catch (e) {
      emit(NotificationError(getErrorMessage(e)));
    }
  }

  Future<void> _onLoadMoreNotifications(
    LoadMoreNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    try {
      emit(currentState.copyWith(isLoadingMore: true));

      final nextPage = currentState.currentPage + 1;
      final response = await _repository.getNotifications(
        page: nextPage,
        limit: _pageSize,
      );

      emit(currentState.copyWith(
        notifications: [...currentState.notifications, ...response.data],
        unreadCount: response.meta.unreadCount,
        totalPages: response.meta.totalPages,
        currentPage: nextPage,
        hasMore: nextPage < response.meta.totalPages,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    try {
      await _repository.markAsRead(event.notificationId);

      final updatedNotifications = currentState.notifications.map((n) {
        if (n.id == event.notificationId && !n.isRead) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }
        return n;
      }).toList();

      final wasUnread = currentState.notifications
          .any((n) => n.id == event.notificationId && !n.isRead);

      emit(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount:
            wasUnread ? currentState.unreadCount - 1 : currentState.unreadCount,
      ));
    } catch (e) {
      debugPrint('Mark notification as read failed: $e');
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    try {
      await _repository.markAllAsRead();

      final updatedNotifications = currentState.notifications.map((n) {
        if (!n.isRead) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }
        return n;
      }).toList();

      emit(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      ));
    } catch (e) {
      debugPrint('Mark all notifications as read failed: $e');
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    try {
      await _repository.deleteNotification(event.notificationId);

      final deletedNotification = currentState.notifications
          .firstWhere((n) => n.id == event.notificationId);
      final wasUnread = !deletedNotification.isRead;

      final updatedNotifications = currentState.notifications
          .where((n) => n.id != event.notificationId)
          .toList();

      emit(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount:
            wasUnread ? currentState.unreadCount - 1 : currentState.unreadCount,
      ));
    } catch (e) {
      debugPrint('Delete notification failed: $e');
    }
  }

  Future<void> _onDeleteAllReadNotifications(
    DeleteAllReadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    try {
      await _repository.deleteAllRead();

      final updatedNotifications =
          currentState.notifications.where((n) => !n.isRead).toList();

      emit(currentState.copyWith(
        notifications: updatedNotifications,
      ));
    } catch (e) {
      debugPrint('Delete all read notifications failed: $e');
    }
  }

  Future<void> _onRefreshUnreadCount(
    RefreshUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    try {
      final unreadCount = await _repository.getUnreadCount();
      emit(currentState.copyWith(unreadCount: unreadCount));
    } catch (e) {
      debugPrint('Refresh unread count failed: $e');
    }
  }
}
