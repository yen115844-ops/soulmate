/**
 * Credits System Constants
 *
 * Credits are the virtual currency used for booking payments.
 * Users purchase credits via IAP consumables.
 * Partners earn credits from completed bookings.
 * Partners can withdraw credits to real VND.
 */

/**
 * Exchange rate: 1 Credit = 1,000 VND (100 credits = 100K)
 */
export const CREDIT_TO_VND_RATE = 1_000;

/**
 * Platform fee percentage for bookings (15%)
 */
export const PLATFORM_FEE_PERCENT = 15;

/**
 * Minimum credits for withdrawal request
 */
export const MINIMUM_WITHDRAWAL_CREDITS = 10;

/**
 * Escrow release delay after booking completion (24 hours)
 */
export const ESCROW_RELEASE_DELAY_HOURS = 24;

/**
 * Convert credits to VND
 */
export function creditsToVnd(credits: number): number {
  return credits * CREDIT_TO_VND_RATE;
}

/**
 * Convert VND to credits (rounded down)
 */
export function vndToCredits(vnd: number): number {
  return Math.floor(vnd / CREDIT_TO_VND_RATE);
}

/**
 * Calculate platform fee in credits
 */
export function calculatePlatformFee(subtotal: number): number {
  return Math.round((subtotal * PLATFORM_FEE_PERCENT) / 100);
}
