import { OTP_LENGTH } from '../constants';

/**
 * Generate a random OTP code
 */
export function generateOtp(length: number = OTP_LENGTH): string {
  const digits = '0123456789';
  let otp = '';
  for (let i = 0; i < length; i++) {
    otp += digits[Math.floor(Math.random() * 10)];
  }
  return otp;
}

/**
 * Generate a unique code with prefix
 * Example: BK-ABC123, TXN-XYZ789
 */
export function generateCode(prefix: string, length: number = 6): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < length; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return `${prefix}-${code}`;
}

/**
 * Generate booking code
 */
export function generateBookingCode(): string {
  return generateCode('BK', 8);
}

/**
 * Generate transaction code
 */
export function generateTransactionCode(): string {
  return generateCode('TXN', 10);
}

/**
 * Mask phone number for privacy
 * Example: 0901234567 -> 090****567
 */
export function maskPhoneNumber(phone: string): string {
  if (!phone || phone.length < 7) return phone;
  return phone.replace(/(\d{3})\d{4}(\d+)/, '$1****$2');
}

/**
 * Mask email for privacy
 * Example: example@gmail.com -> exa***@gmail.com
 */
export function maskEmail(email: string): string {
  if (!email) return email;
  const [local, domain] = email.split('@');
  if (local.length <= 3) return `${local[0]}***@${domain}`;
  return `${local.substring(0, 3)}***@${domain}`;
}

/**
 * Calculate distance between two GPS coordinates (Haversine formula)
 * Returns distance in kilometers
 */
export function calculateDistance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const R = 6371; // Earth's radius in km
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg: number): number {
  return deg * (Math.PI / 180);
}

/**
 * Calculate booking price
 */
export function calculateBookingPrice(
  hourlyRate: number,
  requestedHours: number,
  minimumHours: number = 3,
  platformFeeRate: number = 0.15,
) {
  const actualHours = Math.max(requestedHours, minimumHours);
  const subtotal = hourlyRate * actualHours;
  const serviceFee = subtotal * platformFeeRate;
  const totalAmount = subtotal + serviceFee;

  return {
    hourlyRate,
    requestedHours,
    actualHours,
    subtotal: Math.round(subtotal),
    serviceFee: Math.round(serviceFee),
    totalAmount: Math.round(totalAmount),
    minimumApplied: requestedHours < minimumHours,
  };
}

/**
 * Format currency
 */
export function formatCurrency(
  amount: number,
  currency: string = 'VND',
): string {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency,
  }).format(amount);
}

/**
 * Validate Vietnamese phone number
 */
export function isValidVietnamesePhone(phone: string): boolean {
  const regex = /^(0|\+84)(3|5|7|8|9)[0-9]{8}$/;
  return regex.test(phone.replace(/\s/g, ''));
}

/**
 * Normalize Vietnamese phone number to standard format
 * Example: +84901234567 -> 0901234567
 */
export function normalizePhoneNumber(phone: string): string {
  const cleaned = phone.replace(/\s/g, '');
  if (cleaned.startsWith('+84')) {
    return '0' + cleaned.slice(3);
  }
  return cleaned;
}
