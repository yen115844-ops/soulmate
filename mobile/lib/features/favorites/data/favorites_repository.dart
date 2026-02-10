import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import 'models/favorite_model.dart';

class FavoritesRepository {
  final ApiClient _apiClient;

  FavoritesRepository(this._apiClient);

  /// Get user's favorite partners
  Future<FavoritesResponse> getFavorites({int page = 1, int limit = 20}) async {
    final response = await _apiClient.get(
      UserEndpoints.favorites,
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    return FavoritesResponse.fromJson(data);
  }

  /// Add partner to favorites
  Future<void> addFavorite(String partnerId) async {
    await _apiClient.post('${UserEndpoints.favorites}/$partnerId');
  }

  /// Remove partner from favorites
  Future<void> removeFavorite(String partnerId) async {
    await _apiClient.delete('${UserEndpoints.favorites}/$partnerId');
  }

  /// Check if partner is in favorites
  Future<bool> isFavorite(String partnerId) async {
    try {
      final response = await getFavorites(limit: 100);
      return response.data.any((f) => f.partnerId == partnerId);
    } catch (e) {
      return false;
    }
  }
}
