import 'package:equatable/equatable.dart';

import '../../../../shared/data/models/notification_models.dart';

/// States for NotificationBloc
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class NotificationInitial extends NotificationState {}

/// Loading state
class NotificationLoading extends NotificationState {}

/// Loaded state with notifications data
class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final int totalPages;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
    required this.totalPages,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [
        notifications,
        unreadCount,
        totalPages,
        currentPage,
        hasMore,
        isLoadingMore,
      ];

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    int? totalPages,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Error state
class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
