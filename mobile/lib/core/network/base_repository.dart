import 'api_exceptions.dart';
import '../utils/error_utils.dart' as error_utils;

/// Base repository mixin providing common data extraction utilities.
///
/// Most API responses follow the pattern: `{ success: true, data: {...}, meta: {...} }`.
/// This mixin centralizes the extraction logic to avoid duplication across repositories.
mixin BaseRepositoryMixin {
  /// Extract raw `data` field from API response (returns dynamic).
  ///
  /// Use this when the `data` field could be a Map, List, or primitive.
  /// Falls back to the original response if no `data` key is found.
  dynamic extractRawData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data')) {
        return responseData['data'];
      }
      return responseData;
    }
    return responseData;
  }

  /// Extract `data` field as a typed Map from API response.
  ///
  /// Handles both wrapped responses `{ success, data, ... }` and direct data maps.
  /// Returns the original map if no `data` key is found.
  Map<String, dynamic> extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
        return responseData['data'] as Map<String, dynamic>;
      }
      return responseData;
    }
    throw ApiException(message: 'Unexpected response format');
  }

  /// Extract `data` field as a List from API response.
  ///
  /// Handles `{ success, data: [...], meta: {...} }` patterns.
  List<dynamic> extractListData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data') && responseData['data'] is List) {
        return responseData['data'] as List;
      }
    }
    if (responseData is List) {
      return responseData;
    }
    return [];
  }

  /// Extract `meta` field from API response (pagination info, etc.).
  Map<String, dynamic>? extractMeta(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData['meta'] as Map<String, dynamic>?;
    }
    return null;
  }

  /// Get user-friendly error message from exception.
  ///
  /// Delegates to error_utils for a single source of truth.
  String getErrorMessage(dynamic error) => error_utils.getErrorMessage(error);
}
