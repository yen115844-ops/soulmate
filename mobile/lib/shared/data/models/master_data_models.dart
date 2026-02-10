// ==================== Aggregated Master Data ====================

class ProfileMasterData {
  final List<ProvinceModel> provinces;
  final List<InterestModel> interests;
  final List<TalentModel> talents;
  final List<LanguageModel> languages;

  ProfileMasterData({
    required this.provinces,
    required this.interests,
    required this.talents,
    required this.languages,
  });

  factory ProfileMasterData.fromJson(Map<String, dynamic> json) {
    return ProfileMasterData(
      provinces: (json['provinces'] as List?)
              ?.map((e) => ProvinceModel.fromJson(e))
              .toList() ??
          [],
      interests: (json['interests'] as List?)
              ?.map((e) => InterestModel.fromJson(e))
              .toList() ??
          [],
      talents: (json['talents'] as List?)
              ?.map((e) => TalentModel.fromJson(e))
              .toList() ??
          [],
      languages: (json['languages'] as List?)
              ?.map((e) => LanguageModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PartnerMasterData {
  final List<ProvinceModel> provinces;
  final List<ServiceTypeModel> serviceTypes;

  PartnerMasterData({
    required this.provinces,
    required this.serviceTypes,
  });

  factory PartnerMasterData.fromJson(Map<String, dynamic> json) {
    return PartnerMasterData(
      provinces: (json['provinces'] as List?)
              ?.map((e) => ProvinceModel.fromJson(e))
              .toList() ??
          [],
      serviceTypes: (json['serviceTypes'] as List?)
              ?.map((e) => ServiceTypeModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// ==================== Province ====================

class ProvinceModel {
  final String id;
  final String code;
  final String name;
  final String? nameEn;
  final int sortOrder;
  final bool isActive;
  final int? districtCount;
  final List<DistrictModel>? districts;

  ProvinceModel({
    required this.id,
    required this.code,
    required this.name,
    this.nameEn,
    this.sortOrder = 0,
    this.isActive = true,
    this.districtCount,
    this.districts,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['nameEn'],
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      districtCount: json['_count']?['districts'],
      districts: json['districts'] != null
          ? (json['districts'] as List)
              .map((e) => DistrictModel.fromJson(e))
              .toList()
          : null,
    );
  }

  @override
  String toString() => name;
}

// ==================== District ====================

class DistrictModel {
  final String id;
  final String provinceId;
  final String code;
  final String name;
  final String? nameEn;
  final int sortOrder;
  final bool isActive;
  final ProvinceModel? province;

  DistrictModel({
    required this.id,
    required this.provinceId,
    required this.code,
    required this.name,
    this.nameEn,
    this.sortOrder = 0,
    this.isActive = true,
    this.province,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: json['id'] ?? '',
      provinceId: json['provinceId'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['nameEn'],
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      province: json['province'] != null
          ? ProvinceModel.fromJson(json['province'])
          : null,
    );
  }

  @override
  String toString() => name;
}

// ==================== Interest Category ====================

class InterestCategoryModel {
  final String id;
  final String code;
  final String name;
  final String? nameEn;
  final String? icon;
  final String? color;
  final int sortOrder;
  final bool isActive;
  final List<InterestModel>? interests;

  InterestCategoryModel({
    required this.id,
    required this.code,
    required this.name,
    this.nameEn,
    this.icon,
    this.color,
    this.sortOrder = 0,
    this.isActive = true,
    this.interests,
  });

  factory InterestCategoryModel.fromJson(Map<String, dynamic> json) {
    return InterestCategoryModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['nameEn'],
      icon: json['icon'],
      color: json['color'],
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      interests: json['interests'] != null
          ? (json['interests'] as List)
              .map((e) => InterestModel.fromJson(e))
              .toList()
          : null,
    );
  }
}

// ==================== Interest ====================

class InterestModel {
  final String id;
  final String? categoryId;
  final String code;
  final String name;
  final String? nameEn;
  final String? icon;
  final String? color;
  final int sortOrder;
  final bool isActive;
  final InterestCategoryModel? category;

  InterestModel({
    required this.id,
    this.categoryId,
    required this.code,
    required this.name,
    this.nameEn,
    this.icon,
    this.color,
    this.sortOrder = 0,
    this.isActive = true,
    this.category,
  });

  factory InterestModel.fromJson(Map<String, dynamic> json) {
    return InterestModel(
      id: json['id'] ?? '',
      categoryId: json['categoryId'],
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['nameEn'],
      icon: json['icon'],
      color: json['color'],
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      category: json['category'] != null
          ? InterestCategoryModel.fromJson(json['category'])
          : null,
    );
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterestModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ==================== Talent Category ====================

class TalentCategoryModel {
  final String id;
  final String code;
  final String name;
  final String? nameEn;
  final String? icon;
  final int sortOrder;
  final bool isActive;
  final List<TalentModel>? talents;

  TalentCategoryModel({
    required this.id,
    required this.code,
    required this.name,
    this.nameEn,
    this.icon,
    this.sortOrder = 0,
    this.isActive = true,
    this.talents,
  });

  factory TalentCategoryModel.fromJson(Map<String, dynamic> json) {
    return TalentCategoryModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['nameEn'],
      icon: json['icon'],
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      talents: json['talents'] != null
          ? (json['talents'] as List)
              .map((e) => TalentModel.fromJson(e))
              .toList()
          : null,
    );
  }
}

// ==================== Talent ====================

class TalentModel {
  final String id;
  final String? categoryId;
  final String code;
  final String name;
  final String? nameEn;
  final String? icon;
  final int sortOrder;
  final bool isActive;
  final TalentCategoryModel? category;

  TalentModel({
    required this.id,
    this.categoryId,
    required this.code,
    required this.name,
    this.nameEn,
    this.icon,
    this.sortOrder = 0,
    this.isActive = true,
    this.category,
  });

  factory TalentModel.fromJson(Map<String, dynamic> json) {
    return TalentModel(
      id: json['id'] ?? '',
      categoryId: json['categoryId'],
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['nameEn'],
      icon: json['icon'],
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      category: json['category'] != null
          ? TalentCategoryModel.fromJson(json['category'])
          : null,
    );
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TalentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ==================== Language ====================

class LanguageModel {
  final String id;
  final String code;
  final String name;
  final String? nativeName;
  final String? flag;
  final int sortOrder;
  final bool isActive;

  LanguageModel({
    required this.id,
    required this.code,
    required this.name,
    this.nativeName,
    this.flag,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nativeName: json['nativeName'],
      flag: json['flag'],
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ==================== Service Type ====================

class ServiceTypeModel {
  final String id;
  final String code;
  final String name;
  final String? nameVi;
  final String? description;
  final String? icon;
  final bool isActive;
  final int sortOrder;

  ServiceTypeModel({
    required this.id,
    required this.code,
    required this.name,
    this.nameVi,
    this.description,
    this.icon,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) {
    return ServiceTypeModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      nameVi: json['nameVi'],
      description: json['description'],
      icon: json['icon'],
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  /// Get display name (prefer Vietnamese name if available)
  String get displayName => nameVi ?? name;

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceTypeModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
