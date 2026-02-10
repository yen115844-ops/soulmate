/// KYC Status enum
enum KycStatus {
  none,
  pending,
  verified,
  rejected;

  static KycStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING':
        return KycStatus.pending;
      case 'VERIFIED':
        return KycStatus.verified;
      case 'REJECTED':
        return KycStatus.rejected;
      default:
        return KycStatus.none;
    }
  }

  String get displayText {
    switch (this) {
      case KycStatus.none:
        return 'Chưa xác minh';
      case KycStatus.pending:
        return 'Đang chờ duyệt';
      case KycStatus.verified:
        return 'Đã xác minh';
      case KycStatus.rejected:
        return 'Bị từ chối';
    }
  }
}

/// KYC Status Response Model
class KycStatusModel {
  final KycStatus status;
  final String? idCardFrontUrl;
  final String? idCardBackUrl;
  final String? selfieUrl;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;

  const KycStatusModel({
    required this.status,
    this.idCardFrontUrl,
    this.idCardBackUrl,
    this.selfieUrl,
    this.rejectionReason,
    this.submittedAt,
    this.verifiedAt,
  });

  factory KycStatusModel.fromJson(Map<String, dynamic> json) {
    return KycStatusModel(
      status: KycStatus.fromString(json['status']),
      idCardFrontUrl: json['idCardFrontUrl'],
      idCardBackUrl: json['idCardBackUrl'],
      selfieUrl: json['selfieUrl'],
      rejectionReason: json['rejectionReason'],
      submittedAt: json['submittedAt'] != null 
        ? DateTime.tryParse(json['submittedAt']) 
        : null,
      verifiedAt: json['verifiedAt'] != null 
        ? DateTime.tryParse(json['verifiedAt']) 
        : null,
    );
  }

  bool get canResubmit => status == KycStatus.none || status == KycStatus.rejected;
}

/// KYC Submit Request Model
class KycSubmitRequest {
  final String idCardFrontUrl;
  final String idCardBackUrl;
  final String selfieUrl;
  final String? idCardNumber;
  final String? idCardName;

  const KycSubmitRequest({
    required this.idCardFrontUrl,
    required this.idCardBackUrl,
    required this.selfieUrl,
    this.idCardNumber,
    this.idCardName,
  });

  Map<String, dynamic> toJson() => {
    'idCardFrontUrl': idCardFrontUrl,
    'idCardBackUrl': idCardBackUrl,
    'selfieUrl': selfieUrl,
    if (idCardNumber != null) 'idCardNumber': idCardNumber,
    if (idCardName != null) 'idCardName': idCardName,
  };
}
