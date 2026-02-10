import '../../../core/network/api_client.dart';
import '../models/master_data_models.dart';

class MasterDataRepository {
  final ApiClient _apiClient;

  MasterDataRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Extract data from wrapped response {success, data, ...}
  dynamic _extractData(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response['data'] ?? response;
    }
    return response;
  }

  /// Get all master data for profile editing in one call
  Future<ProfileMasterData> getProfileMasterData() async {
    final response = await _apiClient.get('/master-data/profile');
    final data = _extractData(response.data);
    return ProfileMasterData.fromJson(data as Map<String, dynamic>);
  }

  /// Get provinces
  Future<List<ProvinceModel>> getProvinces() async {
    final response = await _apiClient.get('/master-data/provinces');
    final data = _extractData(response.data);
    return (data as List).map((json) => ProvinceModel.fromJson(json)).toList();
  }

  /// Get districts by province
  Future<List<DistrictModel>> getDistrictsByProvince(String provinceId) async {
    final response =
        await _apiClient.get('/master-data/provinces/$provinceId/districts');
    final data = _extractData(response.data);
    return (data as List).map((json) => DistrictModel.fromJson(json)).toList();
  }

  /// Get all interests
  Future<List<InterestModel>> getInterests() async {
    final response = await _apiClient.get('/master-data/interests');
    final data = _extractData(response.data);
    return (data as List).map((json) => InterestModel.fromJson(json)).toList();
  }

  /// Get interest categories with interests
  Future<List<InterestCategoryModel>> getInterestCategories() async {
    final response = await _apiClient.get('/master-data/interest-categories');
    final data = _extractData(response.data);
    return (data as List)
        .map((json) => InterestCategoryModel.fromJson(json))
        .toList();
  }

  /// Get all talents
  Future<List<TalentModel>> getTalents() async {
    final response = await _apiClient.get('/master-data/talents');
    final data = _extractData(response.data);
    return (data as List).map((json) => TalentModel.fromJson(json)).toList();
  }

  /// Get talent categories with talents
  Future<List<TalentCategoryModel>> getTalentCategories() async {
    final response = await _apiClient.get('/master-data/talent-categories');
    final data = _extractData(response.data);
    return (data as List)
        .map((json) => TalentCategoryModel.fromJson(json))
        .toList();
  }

  /// Get all languages
  Future<List<LanguageModel>> getLanguages() async {
    final response = await _apiClient.get('/master-data/languages');
    final data = _extractData(response.data);
    return (data as List).map((json) => LanguageModel.fromJson(json)).toList();
  }

  /// Get all service types
  Future<List<ServiceTypeModel>> getServiceTypes() async {
    final response = await _apiClient.get('/master-data/service-types');
    final data = _extractData(response.data);
    return (data as List)
        .map((json) => ServiceTypeModel.fromJson(json))
        .toList();
  }

  /// Get all master data for partner registration in one call
  Future<PartnerMasterData> getPartnerMasterData() async {
    final response = await _apiClient.get('/master-data/partner');
    final data = _extractData(response.data);
    return PartnerMasterData.fromJson(data as Map<String, dynamic>);
  }
}
