import '../../shared/data/models/master_data_models.dart';

/// Resolve service type code to display label.
///
/// Priority:
/// 1) Runtime cache seeded from API master data
/// 2) Raw input code
class ServiceTypeDisplayResolver {
  ServiceTypeDisplayResolver._();

  static final Map<String, String> _apiDisplayMap = <String, String>{};

  static void seedFromApi(List<ServiceTypeModel> serviceTypes) {
    for (final item in serviceTypes) {
      final code = item.code.trim().toLowerCase();
      final name = item.displayName.trim();
      if (code.isEmpty || name.isEmpty) continue;
      _apiDisplayMap[code] = name;
    }
  }

  static void seedFromDetail(List<Map<String, dynamic>> details) {
    for (final item in details) {
      final code = (item['code'] ?? '').toString().trim().toLowerCase();
      final name = (item['name'] ?? item['displayName'] ?? item['label'] ?? '')
          .toString()
          .trim();
      if (code.isEmpty || name.isEmpty) continue;
      _apiDisplayMap[code] = name;
    }
  }

  static String resolveName(String code) {
    final normalized = code.trim().toLowerCase();
    if (normalized.isEmpty) return code;

    final fromApi = _apiDisplayMap[normalized];
    if (fromApi != null && fromApi.isNotEmpty) {
      return fromApi;
    }

    return code;
  }
}
