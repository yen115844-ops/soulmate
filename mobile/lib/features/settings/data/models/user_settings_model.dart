import 'package:equatable/equatable.dart';

/// User Settings Model
class UserSettingsModel extends Equatable {
  final String id;
  final String userId;
  
  // Notifications
  final bool pushNotificationsEnabled;
  final bool messageNotificationsEnabled;
  final bool soundEnabled;
  
  // Appearance
  final bool darkModeEnabled;
  final bool useSystemTheme;
  final String language;
  
  // Privacy
  final bool locationEnabled;
  final bool showOnlineStatus;
  final String allowMessagesFrom;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserSettingsModel({
    required this.id,
    required this.userId,
    this.pushNotificationsEnabled = true,
    this.messageNotificationsEnabled = true,
    this.soundEnabled = true,
    this.darkModeEnabled = false,
    this.useSystemTheme = true,
    this.language = 'vi',
    this.locationEnabled = true,
    this.showOnlineStatus = true,
    this.allowMessagesFrom = 'everyone',
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      pushNotificationsEnabled: json['pushNotificationsEnabled'] as bool? ?? true,
      messageNotificationsEnabled: json['messageNotificationsEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      darkModeEnabled: json['darkModeEnabled'] as bool? ?? false,
      useSystemTheme: json['useSystemTheme'] as bool? ?? true,
      language: json['language'] as String? ?? 'vi',
      locationEnabled: json['locationEnabled'] as bool? ?? true,
      showOnlineStatus: json['showOnlineStatus'] as bool? ?? true,
      allowMessagesFrom: json['allowMessagesFrom'] as String? ?? 'everyone',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'messageNotificationsEnabled': messageNotificationsEnabled,
      'soundEnabled': soundEnabled,
      'darkModeEnabled': darkModeEnabled,
      'useSystemTheme': useSystemTheme,
      'language': language,
      'locationEnabled': locationEnabled,
      'showOnlineStatus': showOnlineStatus,
      'allowMessagesFrom': allowMessagesFrom,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserSettingsModel copyWith({
    String? id,
    String? userId,
    bool? pushNotificationsEnabled,
    bool? messageNotificationsEnabled,
    bool? soundEnabled,
    bool? darkModeEnabled,
    bool? useSystemTheme,
    String? language,
    bool? locationEnabled,
    bool? showOnlineStatus,
    String? allowMessagesFrom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      messageNotificationsEnabled: messageNotificationsEnabled ?? this.messageNotificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      language: language ?? this.language,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowMessagesFrom: allowMessagesFrom ?? this.allowMessagesFrom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get language display name
  String get languageDisplayName {
    switch (language) {
      case 'vi':
        return 'Tiếng Việt';
      case 'en':
        return 'English';
      default:
        return 'Tiếng Việt';
    }
  }

  /// Get allow messages from display name
  String get allowMessagesFromDisplayName {
    switch (allowMessagesFrom) {
      case 'everyone':
        return 'Mọi người';
      case 'verified':
        return 'Người đã xác minh';
      case 'none':
        return 'Không ai';
      default:
        return 'Mọi người';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        pushNotificationsEnabled,
        messageNotificationsEnabled,
        soundEnabled,
        darkModeEnabled,
        useSystemTheme,
        language,
        locationEnabled,
        showOnlineStatus,
        allowMessagesFrom,
        createdAt,
        updatedAt,
      ];
}
