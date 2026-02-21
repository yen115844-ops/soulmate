import 'package:equatable/equatable.dart';

/// Verification status enum
enum VerificationStatus {
  none,
  pending,
  verified,
  rejected;

  static VerificationStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'VERIFIED':
        return VerificationStatus.verified;
      case 'PENDING':
        return VerificationStatus.pending;
      case 'REJECTED':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.none;
    }
  }
}

/// Verification entity - Domain layer
class VerificationEntity extends Equatable {
  final String? id;
  final VerificationStatus status;
  final double? livenessScore;
  final bool isAutoVerified;
  final DateTime? verifiedAt;
  final DateTime? submittedAt;
  final String? rejectionReason;
  final bool isVerified;

  const VerificationEntity({
    this.id,
    this.status = VerificationStatus.none,
    this.livenessScore,
    this.isAutoVerified = false,
    this.verifiedAt,
    this.submittedAt,
    this.rejectionReason,
    this.isVerified = false,
  });

  /// Create from status check response
  factory VerificationEntity.fromJson(Map<String, dynamic> json) {
    return VerificationEntity(
      id: json['id'] as String?,
      status: VerificationStatus.fromString(json['status'] as String?),
      livenessScore: (json['livenessScore'] as num?)?.toDouble(),
      isAutoVerified: json['isAutoVerified'] == true,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'].toString())
          : null,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      isVerified: json['isVerified'] == true,
    );
  }

  VerificationEntity copyWith({
    String? id,
    VerificationStatus? status,
    double? livenessScore,
    bool? isAutoVerified,
    DateTime? verifiedAt,
    DateTime? submittedAt,
    String? rejectionReason,
    bool? isVerified,
  }) {
    return VerificationEntity(
      id: id ?? this.id,
      status: status ?? this.status,
      livenessScore: livenessScore ?? this.livenessScore,
      isAutoVerified: isAutoVerified ?? this.isAutoVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        livenessScore,
        isAutoVerified,
        verifiedAt,
        submittedAt,
        rejectionReason,
        isVerified,
      ];
}
