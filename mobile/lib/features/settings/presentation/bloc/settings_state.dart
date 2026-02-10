import 'package:equatable/equatable.dart';

import '../../data/models/user_settings_model.dart';

/// Settings States for SettingsBloc
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Loading state
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Loaded state with settings data
class SettingsLoaded extends SettingsState {
  final UserSettingsModel settings;

  const SettingsLoaded({required this.settings});

  @override
  List<Object?> get props => [settings];
}

/// Updating state (optimistic update)
class SettingsUpdating extends SettingsState {
  final UserSettingsModel settings;

  const SettingsUpdating({required this.settings});

  @override
  List<Object?> get props => [settings];
}

/// Error state
class SettingsError extends SettingsState {
  final String message;
  final UserSettingsModel? previousSettings;

  const SettingsError({
    required this.message,
    this.previousSettings,
  });

  @override
  List<Object?> get props => [message, previousSettings];
}
