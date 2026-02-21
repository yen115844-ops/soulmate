import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../shared/data/models/master_data_models.dart';

/// Service category data model for horizontal scroll
class ServiceCategoryData {
  final String code;
  final String label;
  final IconData icon;
  final Color color;

  const ServiceCategoryData({
    required this.code,
    required this.label,
    required this.icon,
    required this.color,
  });

  /// Find label by code
  static String labelForCode(String code) {
    return serviceCategories
            .where((s) => s.code == code)
            .map((s) => s.label)
            .firstOrNull ??
        code;
  }

  /// Create from ServiceTypeModel (from backend)
  factory ServiceCategoryData.fromServiceType(ServiceTypeModel model) {
    return ServiceCategoryData(
      code: model.code,
      label: model.nameVi ?? model.name,
      icon: _iconForCode(model.code),
      color: _colorForCode(model.code),
    );
  }

  /// Map service code to icon
  static IconData _iconForCode(String code) {
    return switch (code) {
      'coffee' => Ionicons.cafe_outline,
      'movie' => Ionicons.film_outline,
      'dinner' => Ionicons.restaurant_outline,
      'walking' => Ionicons.walk_outline,
      'party' => Ionicons.wine_outline,
      'travel' => Ionicons.airplane_outline,
      'shopping' => Ionicons.bag_outline,
      'gym' => Ionicons.fitness_outline,
      'event' => Ionicons.calendar_outline,
      'other' => Ionicons.ellipsis_horizontal_outline,
      _ => Ionicons.sparkles_outline,
    };
  }

  /// Map service code to color
  static Color _colorForCode(String code) {
    return switch (code) {
      'coffee' => const Color(0xFFF59E0B),
      'movie' => const Color(0xFF8B5CF6),
      'dinner' => const Color(0xFFEF4444),
      'walking' => const Color(0xFF10B981),
      'party' => const Color(0xFFEC4899),
      'travel' => const Color(0xFF06B6D4),
      'shopping' => const Color(0xFF3B82F6),
      'gym' => const Color(0xFF84CC16),
      'event' => const Color(0xFFF97316),
      'other' => const Color(0xFF6B7280),
      _ => const Color(0xFF8B5CF6),
    };
  }
}

const serviceCategories = <ServiceCategoryData>[
  ServiceCategoryData(
    code: 'coffee',
    label: 'Cà phê',
    icon: Ionicons.cafe_outline,
    color: Color(0xFFF59E0B),
  ),
  ServiceCategoryData(
    code: 'movie',
    label: 'Xem phim',
    icon: Ionicons.film_outline,
    color: Color(0xFF8B5CF6),
  ),
  ServiceCategoryData(
    code: 'dinner',
    label: 'Ăn tối',
    icon: Ionicons.restaurant_outline,
    color: Color(0xFFEF4444),
  ),
  ServiceCategoryData(
    code: 'walking',
    label: 'Đi dạo',
    icon: Ionicons.walk_outline,
    color: Color(0xFF10B981),
  ),
  ServiceCategoryData(
    code: 'party',
    label: 'Dự tiệc',
    icon: Ionicons.wine_outline,
    color: Color(0xFFEC4899),
  ),
  ServiceCategoryData(
    code: 'travel',
    label: 'Du lịch',
    icon: Ionicons.airplane_outline,
    color: Color(0xFF06B6D4),
  ),
  ServiceCategoryData(
    code: 'shopping',
    label: 'Shopping',
    icon: Ionicons.bag_outline,
    color: Color(0xFF3B82F6),
  ),
  ServiceCategoryData(
    code: 'gym',
    label: 'Thể thao',
    icon: Ionicons.fitness_outline,
    color: Color(0xFF84CC16),
  ),
];
