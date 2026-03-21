import '../network/api_config.dart';

/// Utility class for handling image URLs
class ImageUtils {
  ImageUtils._();

  /// Build full image URL from relative or absolute path
  ///
  /// If the URL already starts with 'http', returns it as is.
  /// Otherwise, prepends the backend base URL.
  ///
  /// Example:
  /// - Input: '/uploads/avatars/123.jpg' → Output: 'http://localhost:3000/uploads/avatars/123.jpg'
  /// - Input: 'http://example.com/image.jpg' → Output: 'http://example.com/image.jpg'
  static String buildImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }

    final baseUrl = _resolveImageBaseUrl(ApiConfig.baseUrl);
    return '$baseUrl$trimmed';
  }

  /// True when [url] is an absolute HTTP(S) URL.
  static bool isAbsoluteHttpUrl(String url) {
    final trimmed = url.trim().toLowerCase();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  /// Returns backend image origin like `http://localhost:3222`.
  static String imageBaseOrigin() => _resolveImageBaseUrl(ApiConfig.baseUrl);

  /// True when [url] points to the same origin as backend image host.
  static bool isBackendHostedUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    final backend = Uri.tryParse(imageBaseOrigin());
    if (uri == null || backend == null) return false;

    return uri.hasScheme && uri.authority == backend.authority;
  }

  /// Build full image URL with null safety
  ///
  /// Returns null if the input URL is null, otherwise calls buildImageUrl
  static String? buildImageUrlNullable(String? url) {
    if (url == null) return null;
    return buildImageUrl(url);
  }

  static String _resolveImageBaseUrl(String apiBaseUrl) {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null) return apiBaseUrl;

    return '${uri.scheme}://${uri.authority}';
  }
}
