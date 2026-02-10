import 'package:equatable/equatable.dart';

/// Settings Events for SettingsBloc
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load settings
class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

/// Update push notifications setting
class SettingsPushNotificationsChanged extends SettingsEvent {
  final bool enabled;

  const SettingsPushNotificationsChanged({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

/// Update message notifications setting
class SettingsMessageNotificationsChanged extends SettingsEvent {
  final bool enabled;

  const SettingsMessageNotificationsChanged({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

/// Update sound setting
class SettingsSoundChanged extends SettingsEvent {
  final bool enabled;

  const SettingsSoundChanged({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

/// Update dark mode setting
class SettingsDarkModeChanged extends SettingsEvent {
  final bool enabled;

  const SettingsDarkModeChanged({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

/// Update use system theme setting
class SettingsUseSystemThemeChanged extends SettingsEvent {
  final bool enabled;

  const SettingsUseSystemThemeChanged({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

/// Update language setting
class SettingsLanguageChanged extends SettingsEvent {
  final String language;

  const SettingsLanguageChanged({required this.language});

  @override
  List<Object?> get props => [language];
}

/// Update location setting
class SettingsLocationChanged extends SettingsEvent {
  final bool enabled;

  const SettingsLocationChanged({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

/// Update show online status setting
class SettingsShowOnlineStatusChanged extends SettingsEvent {
  final bool enabled;

  const SettingsShowOnlineStatusChanged({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

/// Update allow messages from setting
class SettingsAllowMessagesFromChanged extends SettingsEvent {
  final String value;

  const SettingsAllowMessagesFromChanged({required this.value});

  @override
  List<Object?> get props => [value];
}
