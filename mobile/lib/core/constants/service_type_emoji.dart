/// Service Type Emoji - đồng bộ với seed/CMS
/// Icon dùng emoji để nhất quán giữa backend và mobile
class ServiceTypeEmoji {
  ServiceTypeEmoji._();

  /// Map code -> {nameVi, emoji} - đồng bộ với seed/CMS
  static const Map<String, ServiceTypeDisplay> _map = {
    'walking': ServiceTypeDisplay(nameVi: 'Đi dạo', emoji: '🚶', color: 0xFF10B981),
    'coffee': ServiceTypeDisplay(nameVi: 'Uống cà phê', emoji: '☕', color: 0xFF92400E),
    'movie': ServiceTypeDisplay(nameVi: 'Xem phim', emoji: '🎬', color: 0xFF2EC4B6),
    'dinner': ServiceTypeDisplay(nameVi: 'Ăn tối', emoji: '🍽️', color: 0xFFDC2626),
    'restaurant': ServiceTypeDisplay(nameVi: 'Ăn tối', emoji: '🍽️', color: 0xFFDC2626),
    'party': ServiceTypeDisplay(nameVi: 'Tiệc tùng', emoji: '🎉', color: 0xFFF72585),
    'event': ServiceTypeDisplay(nameVi: 'Sự kiện', emoji: '📅', color: 0xFFF72585),
    'shopping': ServiceTypeDisplay(nameVi: 'Mua sắm', emoji: '🛍️', color: 0xFFB565D8),
    'gym': ServiceTypeDisplay(nameVi: 'Tập gym', emoji: '💪', color: 0xFF06D6A0),
    'fitness': ServiceTypeDisplay(nameVi: 'Tập gym', emoji: '💪', color: 0xFF06D6A0),
    'sport': ServiceTypeDisplay(nameVi: 'Thể thao', emoji: '⚽', color: 0xFF06D6A0),
    'travel': ServiceTypeDisplay(nameVi: 'Du lịch', emoji: '✈️', color: 0xFF4ECDC4),
    'other': ServiceTypeDisplay(nameVi: 'Khác', emoji: '➕', color: 0xFF667EEA),
    'more': ServiceTypeDisplay(nameVi: 'Khác', emoji: '➕', color: 0xFF667EEA),
    'karaoke': ServiceTypeDisplay(nameVi: 'Karaoke', emoji: '🎤', color: 0xFF2EC4B6),
    'game': ServiceTypeDisplay(nameVi: 'Chơi game', emoji: '🎮', color: 0xFF2EC4B6),
    'camera': ServiceTypeDisplay(nameVi: 'Chụp ảnh', emoji: '📷', color: 0xFF7209B7),
    'book': ServiceTypeDisplay(nameVi: 'Đọc sách', emoji: '📚', color: 0xFF667EEA),
    'pet': ServiceTypeDisplay(nameVi: 'Thú cưng', emoji: '🐕', color: 0xFF10B981),
    'car': ServiceTypeDisplay(nameVi: 'Đi chơi', emoji: '🚗', color: 0xFF4ECDC4),
  };

  static const List<ServiceTypeDisplay> all = [
    ServiceTypeDisplay(nameVi: 'Đi dạo', emoji: '🚶', code: 'walking', color: 0xFF10B981),
    ServiceTypeDisplay(nameVi: 'Uống cà phê', emoji: '☕', code: 'coffee', color: 0xFF92400E),
    ServiceTypeDisplay(nameVi: 'Xem phim', emoji: '🎬', code: 'movie', color: 0xFF2EC4B6),
    ServiceTypeDisplay(nameVi: 'Ăn tối', emoji: '🍽️', code: 'dinner', color: 0xFFDC2626),
    ServiceTypeDisplay(nameVi: 'Tiệc tùng', emoji: '🎉', code: 'party', color: 0xFFF72585),
    ServiceTypeDisplay(nameVi: 'Sự kiện', emoji: '📅', code: 'event', color: 0xFFF72585),
    ServiceTypeDisplay(nameVi: 'Mua sắm', emoji: '🛍️', code: 'shopping', color: 0xFFB565D8),
    ServiceTypeDisplay(nameVi: 'Tập gym', emoji: '💪', code: 'gym', color: 0xFF06D6A0),
    ServiceTypeDisplay(nameVi: 'Du lịch', emoji: '✈️', code: 'travel', color: 0xFF4ECDC4),
    ServiceTypeDisplay(nameVi: 'Karaoke', emoji: '🎤', code: 'karaoke', color: 0xFF2EC4B6),
    ServiceTypeDisplay(nameVi: 'Khác', emoji: '➕', code: 'other', color: 0xFF667EEA),
  ];

  static ServiceTypeDisplay get(String code) {
    final key = code.toString().toLowerCase();
    return _map[key] ?? ServiceTypeDisplay(nameVi: code, emoji: '➕', color: 0xFF667EEA);
  }
}

class ServiceTypeDisplay {
  final String nameVi;
  final String emoji;
  final String? code;
  final int color; // Màu hex 0xAARRGGBB

  const ServiceTypeDisplay({
    required this.nameVi,
    required this.emoji,
    this.code,
    this.color = 0xFF667EEA,
  });
}
