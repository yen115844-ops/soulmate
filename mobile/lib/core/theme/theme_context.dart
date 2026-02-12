import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Convenient extensions for accessing theme-aware colors and properties.
///
/// Usage:
/// ```dart
/// // In any widget with BuildContext:
/// final bg = context.appColors.background;      // resolves light/dark
/// final textColor = context.appColors.textPrimary; // resolves light/dark
/// final cs = context.colorScheme;                // ColorScheme shortcut
/// final tt = context.textTheme;                  // TextTheme shortcut
/// ```
extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Theme-aware color accessor – resolves light/dark variants automatically.
  AppThemeColors get appColors => AppThemeColors(isDarkMode);
}

/// Runtime-resolved color palette that picks the right variant for the
/// current brightness.
class AppThemeColors {
  final bool isDark;
  const AppThemeColors(this.isDark);

  // ─── Adaptive colors (change with theme) ───────────────────────────

  Color get background =>
      isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  Color get surface => isDark ? AppColors.surfaceDark : AppColors.surface;
  Color get card => isDark ? AppColors.cardDark : AppColors.card;

  Color get textPrimary =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get textSecondary =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get textHint =>
      isDark ? AppColors.textSecondaryDark : AppColors.textHint;

  Color get border => isDark ? AppColors.borderDark : AppColors.border;
  Color get divider => isDark ? AppColors.dividerDark : AppColors.divider;
  Color get shadow => isDark ? AppColors.shadowDark : AppColors.shadow;

  Color get shimmerBase =>
      isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase;
  Color get shimmerHighlight =>
      isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlight;

  Color get iconColor =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

  // ─── Gradients ─────────────────────────────────────────────────────

  LinearGradient get primaryGradient => AppColors.primaryGradient;
  LinearGradient get accentGradient => AppColors.accentGradient;

  // ─── Non-adaptive colors (same in both modes) ─────────────────────

  Color get primary => AppColors.primary;
  Color get primaryLight => AppColors.primaryLight;
  Color get primaryDark => AppColors.primaryDark;

  Color get secondary => AppColors.secondary;
  Color get secondaryLight => AppColors.secondaryLight;
  Color get secondaryDark => AppColors.secondaryDark;

  Color get accent => AppColors.accent;
  Color get accentLight => AppColors.accentLight;
  Color get accentDark => AppColors.accentDark;

  Color get textWhite => AppColors.textWhite;

  Color get success => AppColors.success;
  Color get successLight => AppColors.successLight;
  Color get warning => AppColors.warning;
  Color get warningLight => AppColors.warningLight;
  Color get error => AppColors.error;
  Color get errorLight => AppColors.errorLight;
  Color get info => AppColors.info;
  Color get infoLight => AppColors.infoLight;

  Color get online => AppColors.online;
  Color get offline => AppColors.offline;
  Color get busy => AppColors.busy;

  Color get starFilled => AppColors.starFilled;
  Color get starEmpty =>
      isDark ? AppColors.borderDark : AppColors.starEmpty;

  Color get facebook => AppColors.facebook;
  Color get google => AppColors.google;
  Color get apple => isDark ? AppColors.textWhite : AppColors.apple;
}
