
/// User Role enum
enum UserRole {
  user,
  partner,
  admin;

  static UserRole fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PARTNER':
        return UserRole.partner;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'Người dùng';
      case UserRole.partner:
        return 'Đối tác';
      case UserRole.admin:
        return 'Quản trị viên';
    }
  }
}

/// User Status enum
enum UserStatus {
  pending,
  active,
  suspended,
  banned;

  static UserStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'ACTIVE':
        return UserStatus.active;
      case 'SUSPENDED':
        return UserStatus.suspended;
      case 'BANNED':
        return UserStatus.banned;
      default:
        return UserStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case UserStatus.pending:
        return 'Chờ duyệt';
      case UserStatus.active:
        return 'Hoạt động';
      case UserStatus.suspended:
        return 'Tạm khóa';
      case UserStatus.banned:
        return 'Bị cấm';
    }
  }
}

/// KYC Status enum
enum KycStatus {
  notSubmitted,
  pending,
  approved,
  rejected;

  static KycStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'PENDING':
        return KycStatus.pending;
      case 'APPROVED':
        return KycStatus.approved;
      case 'REJECTED':
        return KycStatus.rejected;
      default:
        return KycStatus.notSubmitted;
    }
  }

  String get displayName {
    switch (this) {
      case KycStatus.notSubmitted:
        return 'Chưa xác minh';
      case KycStatus.pending:
        return 'Đang xét duyệt';
      case KycStatus.approved:
        return 'Đã xác minh';
      case KycStatus.rejected:
        return 'Từ chối';
    }
  }
}
