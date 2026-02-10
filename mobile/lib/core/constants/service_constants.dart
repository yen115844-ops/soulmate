import 'package:flutter/material.dart';

/// Service Constants - Định nghĩa các dịch vụ và hiển thị (dùng icon thay emoji)
class ServiceConstants {
  ServiceConstants._();

  static const Map<String, ServiceInfo> services = {
    'CHAT': ServiceInfo(
      name: 'Chat & Tán gẫu',
      icon: Icons.chat_bubble_outline,
      color: 0xFF667EEA,
    ),
    'DATING': ServiceInfo(
      name: 'Hẹn hò',
      icon: Icons.favorite,
      color: 0xFFFF6B6B,
    ),
    'TRAVEL': ServiceInfo(
      name: 'Đi chơi',
      icon: Icons.flight,
      color: 0xFF4ECDC4,
    ),
    'WALKING': ServiceInfo(
      name: 'Đi dạo',
      icon: Icons.directions_walk,
      color: 0xFF10B981,
    ),
    'COFFEE': ServiceInfo(
      name: 'Cà phê',
      icon: Icons.local_cafe,
      color: 0xFF92400E,
    ),
    'DINNER': ServiceInfo(
      name: 'Ăn tối',
      icon: Icons.restaurant,
      color: 0xFFDC2626,
    ),
    'DINING': ServiceInfo(
      name: 'Ăn uống',
      icon: Icons.restaurant,
      color: 0xFFFF8C42,
    ),
    'SHOPPING': ServiceInfo(
      name: 'Mua sắm',
      icon: Icons.shopping_bag_outlined,
      color: 0xFFB565D8,
    ),
    'ENTERTAINMENT': ServiceInfo(
      name: 'Giải trí',
      icon: Icons.movie_outlined,
      color: 0xFF2EC4B6,
    ),
    'MOVIE': ServiceInfo(
      name: 'Xem phim',
      icon: Icons.movie_outlined,
      color: 0xFF2EC4B6,
    ),
    'SPORTS': ServiceInfo(
      name: 'Thể thao',
      icon: Icons.sports_soccer,
      color: 0xFF06D6A0,
    ),
    'EVENT': ServiceInfo(
      name: 'Sự kiện',
      icon: Icons.celebration,
      color: 0xFFF72585,
    ),
    'PARTY': ServiceInfo(
      name: 'Dự tiệc',
      icon: Icons.celebration,
      color: 0xFFF72585,
    ),
    'PHOTOSHOOT': ServiceInfo(
      name: 'Chụp ảnh',
      icon: Icons.camera_alt_outlined,
      color: 0xFF7209B7,
    ),
    'VIRTUAL': ServiceInfo(
      name: 'Online',
      icon: Icons.computer_outlined,
      color: 0xFF4361EE,
    ),
    'OTHER': ServiceInfo(
      name: 'Khác',
      icon: Icons.auto_awesome,
      color: 0xFF667EEA,
    ),
  };

  /// Alias API keys -> map key (e.g. DINNER -> DINING để dùng chung thông tin)
  static const Map<String, String> _serviceAlias = {
    'DINNER': 'DINING',
  };

  /// Get service info by key (API trả về lowercase: travel, walking, coffee, dinner)
  static ServiceInfo getServiceInfo(String key) {
    final upper = key.toString().toUpperCase();
    final resolved = _serviceAlias[upper] ?? upper;
    return services[resolved] ?? services['OTHER']!;
  }

  /// Get service info by name (for backward compatibility)
  static ServiceInfo getServiceInfoByName(String name) {
    // Try to find by exact name match
    for (var entry in services.entries) {
      if (entry.value.name == name) {
        return entry.value;
      }
    }
    // Fallback to OTHER
    return services['OTHER']!;
  }
}

/// Service Information
class ServiceInfo {
  final String name;
  final IconData icon;
  final int color;

  const ServiceInfo({
    required this.name,
    required this.icon,
    required this.color,
  });
}
