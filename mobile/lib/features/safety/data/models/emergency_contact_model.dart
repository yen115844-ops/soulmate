/// Emergency Contact Model
class EmergencyContactModel {
  final String id;
  final String name;
  final String phone;
  final String? relationship;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship,
    this.isPrimary = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relationship: json['relationship'],
      isPrimary: json['isPrimary'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    if (relationship != null) 'relationship': relationship,
    'isPrimary': isPrimary,
  };

  EmergencyContactModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Create Emergency Contact Request
class CreateEmergencyContactRequest {
  final String name;
  final String phone;
  final String? relationship;
  final bool isPrimary;

  const CreateEmergencyContactRequest({
    required this.name,
    required this.phone,
    this.relationship,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    if (relationship != null) 'relationship': relationship,
    'isPrimary': isPrimary,
  };
}

/// Update Emergency Contact Request
class UpdateEmergencyContactRequest {
  final String? name;
  final String? phone;
  final String? relationship;
  final bool? isPrimary;

  const UpdateEmergencyContactRequest({
    this.name,
    this.phone,
    this.relationship,
    this.isPrimary,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (relationship != null) data['relationship'] = relationship;
    if (isPrimary != null) data['isPrimary'] = isPrimary;
    return data;
  }
}
