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
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$baseUrl$url';
  }

  /// Build full image URL with null safety
  /// 
  /// Returns null if the input URL is null, otherwise calls buildImageUrl
  static String? buildImageUrlNullable(String? url) {
    if (url == null) return null;
    return buildImageUrl(url);
  }
}
