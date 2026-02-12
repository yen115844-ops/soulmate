import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

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
