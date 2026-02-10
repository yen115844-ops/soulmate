/**
 * Enums được export từ Prisma Client
 * File này re-export để sử dụng trong application code
 */

// Re-export tất cả enums từ Prisma
export {
    BookingStatus, ConversationStatus, EscrowStatus, Gender, KycStatus, MessageStatus, MessageType, NotificationType, SlotStatus, SosStatus, TransactionStatus, TransactionType, UserRole,
    UserStatus
} from '@prisma/client';

// Additional enums không có trong Prisma schema

/**
 * Loại review
 */
export enum ReviewType {
  USER_TO_PARTNER = 'user_to_partner',
  PARTNER_TO_USER = 'partner_to_user',
}

/**
 * Phương thức thanh toán
 */
export enum PaymentMethod {
  WALLET = 'wallet',
  VNPAY = 'vnpay',
  MOMO = 'momo',
  ZALOPAY = 'zalopay',
  BANK_TRANSFER = 'bank_transfer',
}

/**
 * Loại thiết bị
 */
export enum DevicePlatform {
  IOS = 'ios',
  ANDROID = 'android',
  WEB = 'web',
}

/**
 * Mục đích OTP
 */
export enum OtpPurpose {
  REGISTER = 'register',
  LOGIN = 'login',
  RESET_PASSWORD = 'reset_password',
  VERIFY_PHONE = 'verify_phone',
  VERIFY_EMAIL = 'verify_email',
}

/**
 * Loại báo cáo
 */
export enum ReportType {
  USER = 'user',
  REVIEW = 'review',
  MESSAGE = 'message',
  BOOKING = 'booking',
}

/**
 * Trạng thái báo cáo
 */
export enum ReportStatus {
  PENDING = 'pending',
  REVIEWING = 'reviewing',
  RESOLVED = 'resolved',
  REJECTED = 'rejected',
}

/**
 * Loại quan hệ liên hệ khẩn cấp
 */
export enum EmergencyContactRelationship {
  PARENT = 'parent',
  SPOUSE = 'spouse',
  SIBLING = 'sibling',
  FRIEND = 'friend',
  OTHER = 'other',
}

/**
 * Vai trò trong conversation
 */
export enum ConversationRole {
  USER = 'user',
  PARTNER = 'partner',
}

/**
 * Loại action cho notification deep link
 */
export enum NotificationActionType {
  BOOKING = 'booking',
  CHAT = 'chat',
  PROFILE = 'profile',
  REVIEW = 'review',
  WALLET = 'wallet',
  KYC = 'kyc',
  SOS = 'sos',
}

/**
 * Service types codes
 */
export enum ServiceTypeCode {
  WALKING = 'walking',
  MOVIE = 'movie',
  PARTY = 'party',
  EVENT = 'event',
  TRAVEL = 'travel',
  COFFEE = 'coffee',
  DINNER = 'dinner',
  SHOPPING = 'shopping',
  GYM = 'gym',
  OTHER = 'other',
}

/**
 * Verification badge levels
 */
export enum VerificationBadge {
  BRONZE = 'bronze',
  SILVER = 'silver',
  GOLD = 'gold',
}
