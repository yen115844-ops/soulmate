import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import 'models/emergency_contact_model.dart';

class EmergencyContactsRepository {
  final ApiClient _apiClient;

  EmergencyContactsRepository(this._apiClient);

  /// Get all emergency contacts
  Future<List<EmergencyContactModel>> getContacts() async {
    final response = await _apiClient.get(UserEndpoints.emergencyContacts);
    final responseData = response.data;

    // Handle different response formats
    List<dynamic> dataList;
    if (responseData is List) {
      // API returned a list directly
      dataList = responseData;
    } else if (responseData is Map<String, dynamic>) {
      // Check for nested structure: { success, data: { data: [], total } }
      var data = responseData['data'];

      // Handle nested data.data structure
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        data = data['data'];
      }

      if (data is List) {
        dataList = data;
      } else if (data is Map<String, dynamic>) {
        // Single item wrapped in data
        dataList = [data];
      } else {
        dataList = [];
      }
    } else {
      dataList = [];
    }

    return dataList
        .whereType<Map<String, dynamic>>()
        .map((e) => EmergencyContactModel.fromJson(e))
        .toList();
  }

  /// Create new emergency contact
  Future<EmergencyContactModel> createContact(
    CreateEmergencyContactRequest request,
  ) async {
    final response = await _apiClient.post(
      UserEndpoints.emergencyContacts,
      data: request.toJson(),
    );
    final responseData = response.data as Map<String, dynamic>;
    final contactData = _extractContactData(responseData);
    return EmergencyContactModel.fromJson(contactData);
  }

  /// Update emergency contact
  Future<EmergencyContactModel> updateContact(
    String contactId,
    UpdateEmergencyContactRequest request,
  ) async {
    final response = await _apiClient.put(
      '${UserEndpoints.emergencyContacts}/$contactId',
      data: request.toJson(),
    );
    final responseData = response.data as Map<String, dynamic>;
    final contactData = _extractContactData(responseData);
    return EmergencyContactModel.fromJson(contactData);
  }

  /// Extract contact data from nested API response
  /// Handles: { data: { data: {...} } } or { data: {...} } or {...}
  Map<String, dynamic> _extractContactData(Map<String, dynamic> responseData) {
    var data = responseData['data'];

    // Handle nested data.data structure
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      // Check if this looks like a contact object (has id, name, phone)
      if (data.containsKey('id') && data.containsKey('name')) {
        return data;
      }
    }

    // Fallback to responseData if it looks like a contact
    if (responseData.containsKey('id') && responseData.containsKey('name')) {
      return responseData;
    }

    return data is Map<String, dynamic> ? data : responseData;
  }

  /// Delete emergency contact
  Future<void> deleteContact(String contactId) async {
    await _apiClient.delete('${UserEndpoints.emergencyContacts}/$contactId');
  }
}
