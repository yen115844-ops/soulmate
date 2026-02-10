// ==================== ENUMS ====================
export enum UserRole {
  USER = "USER",
  PARTNER = "PARTNER",
  ADMIN = "ADMIN",
}

export enum UserStatus {
  PENDING = "PENDING",
  ACTIVE = "ACTIVE",
  SUSPENDED = "SUSPENDED",
  BANNED = "BANNED",
}

export enum KycStatus {
  NONE = "NONE",
  PENDING = "PENDING",
  VERIFIED = "VERIFIED",
  REJECTED = "REJECTED",
}

export enum Gender {
  MALE = "MALE",
  FEMALE = "FEMALE",
  OTHER = "OTHER",
}

export enum BookingStatus {
  PENDING = "PENDING",
  CONFIRMED = "CONFIRMED",
  PAID = "PAID",
  IN_PROGRESS = "IN_PROGRESS",
  COMPLETED = "COMPLETED",
  CANCELLED = "CANCELLED",
  DISPUTED = "DISPUTED",
}

export enum NotificationType {
  BOOKING = "BOOKING",
  CHAT = "CHAT",
  PAYMENT = "PAYMENT",
  SYSTEM = "SYSTEM",
  SAFETY = "SAFETY",
  REVIEW = "REVIEW",
}

export enum PartnerStatus {
  PENDING = "PENDING",
  ACTIVE = "ACTIVE",
  SUSPENDED = "SUSPENDED",
  BANNED = "BANNED",
}

// ==================== API RESPONSE ====================
export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
  timestamp?: string;
}

export interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
  hasNextPage?: boolean;
  hasPreviousPage?: boolean;
}

export interface PaginatedData<T> {
  data: T[];
  meta: PaginationMeta;
}

// Wrapped paginated response from backend
export interface PaginatedResponse<T> {
  success?: boolean;
  data: PaginatedData<T> | T[];
  meta?: PaginationMeta;
  timestamp?: string;
}

// ==================== USER ====================
export interface User {
  id: string;
  email: string;
  phone?: string;
  role: UserRole;
  status: UserStatus;
  kycStatus: KycStatus;
  createdAt: string;
  updatedAt: string;
  profile?: Profile;
  partnerProfile?: PartnerProfile;
}

export interface Profile {
  id: string;
  userId: string;
  fullName: string;
  displayName?: string;
  avatarUrl?: string;
  coverPhotoUrl?: string;
  bio?: string;
  gender?: Gender;
  dateOfBirth?: string;
  heightCm?: number;
  weightKg?: number;
  currentLat?: number;
  currentLng?: number;
  city?: string;
  district?: string;
  address?: string;
  languages?: string[];
  interests?: string[];
  talents?: string[];
  photos?: string[];
}

// ==================== PARTNER ====================
export interface PartnerProfile {
  id: string;
  userId: string;
  hourlyRate: number;
  minimumHours: number;
  currency: string;
  serviceTypes: string[];
  totalBookings: number;
  completedBookings: number;
  cancelledBookings: number;
  averageRating: number;
  totalReviews: number;
  responseRate: number;
  responseTime?: number;
  isVerified: boolean;
  verificationBadge?: string;
  isAvailable: boolean;
  status: PartnerStatus;
  lastActiveAt?: string;
  introduction?: string;
  experienceYears?: number;
  createdAt: string;
  updatedAt: string;
  user?: User;
}

// ==================== BOOKING ====================
export interface Booking {
  id: string;
  bookingCode: string;
  userId: string;
  partnerId: string;
  serviceType: string;
  date: string;
  startTime: string;
  endTime: string;
  durationHours: number;
  meetingLocation?: string;
  meetingLat?: number;
  meetingLng?: number;
  hourlyRate: number;
  totalHours: number;
  subtotal: number;
  serviceFee: number;
  totalAmount: number;
  status: BookingStatus;
  userNote?: string;
  partnerNote?: string;
  cancellationReason?: string;
  cancelledBy?: string;
  createdAt: string;
  confirmedAt?: string;
  paidAt?: string;
  startedAt?: string;
  completedAt?: string;
  cancelledAt?: string;
  user?: User;
  partner?: User;
}

// ==================== KYC ====================
export interface KycVerification {
  id: string;
  userId: string;
  idCardFrontUrl?: string;
  idCardBackUrl?: string;
  idCardNumber?: string;
  idCardName?: string;
  idCardDob?: string;
  idCardGender?: Gender;
  idCardAddress?: string;
  idCardExpiry?: string;
  videoUrl?: string;
  selfieUrl?: string;
  status: KycStatus;
  rejectionReason?: string;
  livenessScore?: number;
  faceMatchScore?: number;
  ocrConfidence?: number;
  verifiedAt?: string;
  verifiedBy?: string;
  submittedAt?: string;
  reviewNote?: string;
  createdAt: string;
  user?: User;
}

// ==================== MASTER DATA ====================
export interface ServiceType {
  id: string;
  code: string;
  name: string;
  nameVi?: string;
  description?: string;
  icon?: string; // Emoji
  sortOrder: number;
  isActive: boolean;
}

export interface Province {
  id: string;
  name: string;
  code: string;
  displayOrder: number;
  isActive: boolean;
  districts?: District[];
}

export interface District {
  id: string;
  provinceId: string;
  name: string;
  code: string;
  displayOrder: number;
  isActive: boolean;
}

export interface Interest {
  id: string;
  categoryId?: string;
  name: string;
  icon?: string;
  displayOrder: number;
  isActive: boolean;
  category?: InterestCategory;
}

export interface InterestCategory {
  id: string;
  code: string;
  name: string;
  displayOrder: number;
  isActive: boolean;
}

export interface Talent {
  id: string;
  categoryId?: string;
  name: string;
  icon?: string;
  displayOrder: number;
  isActive: boolean;
  category?: TalentCategory;
}

export interface TalentCategory {
  id: string;
  code: string;
  name: string;
  displayOrder: number;
  isActive: boolean;
}

export interface Language {
  id: string;
  code: string;
  name: string;
  nativeName: string;
  displayOrder: number;
  isActive: boolean;
}

// ==================== AUTH ====================
export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface AdminUser {
  id: string;
  email: string;
  role: UserRole;
  profile?: {
    fullName: string;
    avatarUrl?: string;
  };
}

// ==================== NOTIFICATION ====================
export interface Notification {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  imageUrl?: string;
  actionType?: string;
  actionId?: string;
  data?: any;
  isRead: boolean;
  readAt?: string;
  createdAt: string;
  user?: {
    id: string;
    email: string;
    profile?: {
      fullName: string;
      avatarUrl?: string;
    };
  };
}

export interface PushQueueStatus {
  lastError: string | null;
  lastErrorAt: string | null;
  failedCount: number;
  waitingCount: number;
}

export interface NotificationStats {
  total: number;
  unread: number;
  read: number;
  byType: {
    type: NotificationType;
    count: number;
  }[];
  today: number;
  thisWeek: number;
  thisMonth: number;
  /** Push queue status and last error (e.g. production VPS) */
  pushQueue?: PushQueueStatus;
}

// ==================== DASHBOARD ====================
export interface DashboardStats {
  totalUsers: number;
  totalPartners: number;
  totalBookings: number;
  pendingKyc: number;
  todayBookings: number;
  monthlyRevenue: number;
  newUsersToday: number;
  activePartnersToday: number;
}
