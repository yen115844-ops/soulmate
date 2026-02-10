// Notification Types
enum NotificationType {
  booking,
  chat,
  payment,
  system,
  safety,
  review;

  static NotificationType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'BOOKING':
        return NotificationType.booking;
      case 'CHAT':
        return NotificationType.chat;
      case 'PAYMENT':
        return NotificationType.payment;
      case 'SYSTEM':
        return NotificationType.system;
      case 'SAFETY':
        return NotificationType.safety;
      case 'REVIEW':
        return NotificationType.review;
      default:
        return NotificationType.system;
    }
  }

  String get value => name.toUpperCase();
}

// Notification Model
class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? actionType;
  final String? actionId;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionType,
    this.actionId,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      type: NotificationType.fromString(json['type'] ?? 'SYSTEM'),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      imageUrl: json['imageUrl'],
      actionType: json['actionType'],
      actionId: json['actionId'],
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'actionType': actionType,
      'actionId': actionId,
      'data': data,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    String? imageUrl,
    String? actionType,
    String? actionId,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      actionType: actionType ?? this.actionType,
      actionId: actionId ?? this.actionId,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Notifications Response
class NotificationsResponse {
  final List<NotificationModel> data;
  final NotificationMeta meta;

  NotificationsResponse({
    required this.data,
    required this.meta,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      data: (json['data'] as List?)
              ?.map((e) => NotificationModel.fromJson(e))
              .toList() ??
          [],
      meta: NotificationMeta.fromJson(json['meta'] ?? {}),
    );
  }
}

// Notification Meta
class NotificationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final int unreadCount;

  NotificationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.unreadCount,
  });

  factory NotificationMeta.fromJson(Map<String, dynamic> json) {
    return NotificationMeta(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

// Unread Count Response
class UnreadCountResponse {
  final int unreadCount;

  UnreadCountResponse({required this.unreadCount});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
