/**
 * Application constants
 */

// Platform fee rate (15%)
export const PLATFORM_FEE_RATE = 0.15;

// Minimum booking hours
export const MINIMUM_BOOKING_HOURS = 3;

// Escrow release delay (24 hours in milliseconds)
export const ESCROW_RELEASE_DELAY_MS = 24 * 60 * 60 * 1000;

// Token expiration times
export const ACCESS_TOKEN_EXPIRY = '15m'; // 15 minutes
export const REFRESH_TOKEN_EXPIRY = '7d'; // 7 days

// OTP settings
export const OTP_LENGTH = 6;
export const OTP_EXPIRY_MINUTES = 5;
export const OTP_MAX_ATTEMPTS = 5;

// Pagination defaults
export const DEFAULT_PAGE_SIZE = 20;
export const MAX_PAGE_SIZE = 100;

// Search settings
export const DEFAULT_SEARCH_RADIUS_KM = 10;
export const MAX_SEARCH_RADIUS_KM = 100;

// Rating settings
export const MIN_RATING = 1;
export const MAX_RATING = 5;

// File upload limits (in bytes)
export const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
export const MAX_VIDEO_SIZE = 100 * 1024 * 1024; // 100MB
export const MAX_VOICE_SIZE = 10 * 1024 * 1024; // 10MB

// KYC settings
export const KYC_MIN_LIVENESS_SCORE = 0.7;
export const KYC_MIN_FACE_MATCH_SCORE = 0.8;

// SOS settings
export const SOS_HOLD_DURATION_SECONDS = 3;

// Cache TTL (in seconds)
export const CACHE_TTL = {
  USER_SESSION: 30 * 60, // 30 minutes
  PARTNER_PROFILE: 5 * 60, // 5 minutes
  SEARCH_RESULTS: 60, // 1 minute
  AVAILABILITY_SLOTS: 30, // 30 seconds
};

// Rate limiting (áp dụng đồng thời: phải thỏa cả short, medium, long)
// Tracker: đã login → theo userId; chưa login / auth routes → theo IP (xem ThrottlerUserGuard)
// Key: per endpoint per tracker → mỗi endpoint có tối đa limit request trong ttl cho mỗi user/IP
export const RATE_LIMIT = {
  SHORT: { limit: 3, ttl: 1000 }, // 3 req/giây (burst)
  MEDIUM: { limit: 20, ttl: 10000 }, // 20 req/10 giây
  LONG: { limit: 100, ttl: 60000 }, // 100 req/phút
  AUTH: { limit: 5, ttl: 60000 }, // 5 lần thử auth/phút (nên dùng @Throttle cho route login)
  SOS: { limit: 3, ttl: 60000 }, // 3 lần SOS/phút
};

// Booking code prefix
export const BOOKING_CODE_PREFIX = 'BK';

// Transaction code prefix
export const TRANSACTION_CODE_PREFIX = 'TXN';

// Supported currencies
export const SUPPORTED_CURRENCIES = ['VND', 'USD'];

// Default currency
export const DEFAULT_CURRENCY = 'VND';

// Partner stats thresholds
export const PARTNER_STATS = {
  MIN_BOOKINGS_FOR_BADGE: 10,
  MIN_RATING_FOR_SILVER: 4.0,
  MIN_RATING_FOR_GOLD: 4.5,
  MIN_BOOKINGS_FOR_SILVER: 50,
  MIN_BOOKINGS_FOR_GOLD: 100,
};

// Location tracking interval during booking (in milliseconds)
export const LOCATION_TRACKING_INTERVAL_MS = 30 * 1000; // 30 seconds
