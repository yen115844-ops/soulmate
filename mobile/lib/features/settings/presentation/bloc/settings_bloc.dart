import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../data/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// Settings BLoC handles settings-related business logic
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  final PushNotificationService _pushService;

  SettingsBloc({
    required SettingsRepository settingsRepository,
    required PushNotificationService pushNotificationService,
  })  : _settingsRepository = settingsRepository,
        _pushService = pushNotificationService,
        super(const SettingsInitial()) {
    on<SettingsLoadRequested>(_onLoadRequested);
    on<SettingsPushNotificationsChanged>(_onPushNotificationsChanged);
    on<SettingsMessageNotificationsChanged>(_onMessageNotificationsChanged);
    on<SettingsSoundChanged>(_onSoundChanged);
    on<SettingsDarkModeChanged>(_onDarkModeChanged);
    on<SettingsUseSystemThemeChanged>(_onUseSystemThemeChanged);
    on<SettingsLanguageChanged>(_onLanguageChanged);
    on<SettingsLocationChanged>(_onLocationChanged);
    on<SettingsShowOnlineStatusChanged>(_onShowOnlineStatusChanged);
    on<SettingsAllowMessagesFromChanged>(_onAllowMessagesFromChanged);
  }

  /// Load settings
  Future<void> _onLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    try {
      final settings = await _settingsRepository.getSettings();
      emit(SettingsLoaded(settings: settings));
    } on ApiException catch (e) {
      emit(SettingsError(message: e.message));
    } catch (e) {
      debugPrint('Settings load error: $e');
      emit(const SettingsError(message: 'Không thể tải cài đặt. Vui lòng thử lại.'));
    }
  }

  /// Update push notifications (backend + FCM: register/unregister token)
  Future<void> _onPushNotificationsChanged(
    SettingsPushNotificationsChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSetting(
      emit,
      () => _settingsRepository.updateSettings(
        pushNotificationsEnabled: event.enabled,
      ),
    );
    if (state is! SettingsLoaded) return;
    try {
      if (event.enabled) {
        await _pushService.registerTokenWithBackend();
      } else {
        await _pushService.unregisterToken();
      }
    } catch (e) {
      debugPrint('Push notification sync error: $e');
    }
  }

  /// Update message notifications
  Future<void> _onMessageNotificationsChanged(
    SettingsMessageNotificationsChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSetting(
      emit,
      () => _settingsRepository.updateSettings(
        messageNotificationsEnabled: event.enabled,
      ),
    );
  }

  /// Update sound
  Future<void> _onSoundChanged(
    SettingsSoundChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSetting(
      emit,
      () => _settingsRepository.updateSettings(
        soundEnabled: event.enabled,
      ),
    );
  }

  /// Update dark mode
  Future<void> _onDarkModeChanged(
    SettingsDarkModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSetting(
      emit,
      () => _settingsRepository.updateSettings(
        darkModeEnabled: event.enabled,
      ),
    );
  }

  /// Update use system theme
  Future<void> _onUseSystemThemeChanged(
    SettingsUseSystemThemeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSetting(
      emit,
      () => _settingsRepository.updateSettings(
        useSystemTheme: event.enabled,
      ),
    );
  }

  /// Update language
  Future<void> _onLanguageChanged(
    SettingsLanguageChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSetting(
      emit,
      () => _settingsRepository.updateSettings(
        language: event.language,
      ),
    );
  }

  /// Update location
  Future<void> _onLocationChanged(
    SettingsLocationChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSetting(
      emit,
      () => _settingsRepository.updateSettings(
        locationEnabled: event.enabled,
      ),
    );
  }

  /// Update show online status
  Future<void> _onShowOnlineStatusChanged(
    SettingsShowOnlineStatusChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSetting(
      emit,
      () => _settingsRepository.updateSettings(
        showOnlineStatus: event.enabled,
      ),
    );
  }

  /// Update allow messages from
  Future<void> _onAllowMessagesFromChanged(
    SettingsAllowMessagesFromChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _updateSetting(
      emit,
      () => _settingsRepository.updateSettings(
        allowMessagesFrom: event.value,
      ),
    );
  }

  /// Helper method to update setting with optimistic update
  Future<void> _updateSetting(
    Emitter<SettingsState> emit,
    Future<dynamic> Function() updateFn,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    final previousSettings = currentState.settings;

    try {
      final updatedSettings = await updateFn();
      emit(SettingsLoaded(settings: updatedSettings));
    } on ApiException catch (e) {
      emit(SettingsError(
        message: e.message,
        previousSettings: previousSettings,
      ));
      // Restore previous state
      emit(SettingsLoaded(settings: previousSettings));
    } catch (e) {
      debugPrint('Settings update error: $e');
      emit(SettingsError(
        message: 'Không thể cập nhật cài đặt.',
        previousSettings: previousSettings,
      ));
      // Restore previous state
      emit(SettingsLoaded(settings: previousSettings));
    }
  }
}
