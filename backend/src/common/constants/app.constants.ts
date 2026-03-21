/**
 * Application constants
 */

// OTP settings
export const OTP_LENGTH = 6;

// Pagination defaults
export const DEFAULT_PAGE_SIZE = 20;
export const MAX_PAGE_SIZE = 100;

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
