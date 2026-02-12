import 'package:flutter/material.dart';

/// App Colors - Modern Mioto-inspired Design System
/// Primary: Teal/Green
/// Accent: Deep Teal
class AppColors {
  AppColors._();

  // === Primary Colors ===
  static const Color primary = Color(0xFF00B894);
  static const Color primaryLight = Color(0xFF55EFC4);
  static const Color primaryDark = Color(0xFF009B77);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00B894), Color(0xFF009B77)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === Secondary Colors ===
  static const Color secondary = Color(0xFF0984E3);
  static const Color secondaryLight = Color(0xFF74B9FF);
  static const Color secondaryDark = Color(0xFF0652DD);

  // === Accent Colors ===
  static const Color accent = Color(0xFF6C5CE7);
  static const Color accentLight = Color(0xFFA29BFE);
  static const Color accentDark = Color(0xFF4834D4);

  // === Background Colors ===
  static const Color backgroundLight = Color(0xFFF8F9FE);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF252525);

  // === Text Colors ===
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // === Status Colors ===
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // === Border Colors ===
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color dividerDark = Color(0xFF374151);

  // === Online Status ===
  static const Color online = Color(0xFF10B981);
  static const Color offline = Color(0xFF6B7280);
  static const Color busy = Color(0xFFF59E0B);

  // === Rating Colors ===
  static const Color starFilled = Color(0xFFFBBF24);
  static const Color starEmpty = Color(0xFFE5E7EB);

  // === Social Colors ===
  static const Color facebook = Color(0xFF1877F2);
  static const Color google = Color(0xFFDB4437);
  static const Color apple = Color(0xFF000000);

  // === Shadow Colors ===
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x40000000);

  // === Shimmer Colors ===
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF3F4F6);
  static const Color shimmerBaseDark = Color(0xFF374151);
  static const Color shimmerHighlightDark = Color(0xFF4B5563);

  // === Partner/Service Type Colors ===
  static const Map<String, Color> serviceColors = {
    'walking': Color(0xFF10B981),
    'movie': Color(0xFF8B5CF6),
    'cafe': Color(0xFFF59E0B),
    'dinner': Color(0xFFEF4444),
    'party': Color(0xFFEC4899),
    'shopping': Color(0xFF3B82F6),
    'travel': Color(0xFF06B6D4),
    'event': Color(0xFF6366F1),
    'gym': Color(0xFF84CC16),
    'other': Color(0xFF6B7280),
  };

  // === Helper Methods ===
  static Color getServiceColor(String serviceType) {
    return serviceColors[serviceType] ?? serviceColors['other']!;
  }

  static Color withAlpha(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }
}
