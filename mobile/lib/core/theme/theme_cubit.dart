import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/local_storage_service.dart';

/// Theme state
class ThemeState {
  final ThemeMode themeMode;

  const ThemeState({required this.themeMode});

  ThemeState copyWith({ThemeMode? themeMode}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode);
  }

  bool get isDarkMode => themeMode == ThemeMode.dark;
  bool get isLightMode => themeMode == ThemeMode.light;
  bool get isSystemMode => themeMode == ThemeMode.system;
}

/// ThemeCubit - Manages app theme state
class ThemeCubit extends Cubit<ThemeState> {
  final LocalStorageService _storageService;

  ThemeCubit({required LocalStorageService storageService})
    : _storageService = storageService,
      super(const ThemeState(themeMode: ThemeMode.light)) {
    _loadTheme();
  }

  /// Load saved theme from storage
  void _loadTheme() {
    final savedTheme = _storageService.themeMode;
    final themeMode = _parseThemeMode(savedTheme);
    emit(ThemeState(themeMode: themeMode));
  }

  /// Parse string to ThemeMode
  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.light;
    }
  }

  /// Convert ThemeMode to string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    await _storageService.setThemeMode(_themeModeToString(mode));
    emit(ThemeState(themeMode: mode));
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = state.isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Set dark mode
  Future<void> setDarkMode(bool enabled) async {
    await setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }
}
