import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * Apple App Store Server Notifications V2
 * @see https://developer.apple.com/documentation/appstoreservernotifications/responsebodyv2
 */

// Top-level notification body from Apple
export class AppleNotificationV2Dto {
  @ApiProperty({ description: 'The signed payload in JWS format (signedPayload)' })
  signedPayload: string;
}

// Decoded notification payload
export interface AppleNotificationPayload {
  notificationType: AppleNotificationType;
  subtype?: AppleNotificationSubtype;
  data: {
    appAppleId: number;
    bundleId: string;
    bundleVersion: string;
    environment: 'Sandbox' | 'Production';
    signedTransactionInfo: string; // JWS
    signedRenewalInfo?: string; // JWS
  };
  version: string;
  signedDate: number;
  notificationUUID: string;
}

// Decoded transaction info from JWS
export interface AppleTransactionInfo {
  transactionId: string;
  originalTransactionId: string;
  bundleId: string;
  productId: string;
  purchaseDate: number;
  originalPurchaseDate: number;
  expiresDate?: number;
  type: 'Auto-Renewable Subscription' | 'Non-Consumable' | 'Consumable' | 'Non-Renewing Subscription';
  environment: 'Sandbox' | 'Production';
  storefront: string;
  storefrontId: string;
  revocationDate?: number;
  revocationReason?: number;
}

// Decoded renewal info from JWS
export interface AppleRenewalInfo {
  autoRenewProductId: string;
  autoRenewStatus: 0 | 1; // 0 = off, 1 = on
  environment: 'Sandbox' | 'Production';
  expirationIntent?: number;
  gracePeriodExpiresDate?: number;
  isInBillingRetryPeriod?: boolean;
  originalTransactionId: string;
  priceIncreaseStatus?: number;
  productId: string;
  signedDate: number;
}

/**
 * Apple Notification Types V2
 * @see https://developer.apple.com/documentation/appstoreservernotifications/notificationtype
 */
export enum AppleNotificationType {
  CONSUMPTION_REQUEST = 'CONSUMPTION_REQUEST',
  DID_CHANGE_RENEWAL_PREF = 'DID_CHANGE_RENEWAL_PREF',
  DID_CHANGE_RENEWAL_STATUS = 'DID_CHANGE_RENEWAL_STATUS',
  DID_FAIL_TO_RENEW = 'DID_FAIL_TO_RENEW',
  DID_RENEW = 'DID_RENEW',
  EXPIRED = 'EXPIRED',
  GRACE_PERIOD_EXPIRED = 'GRACE_PERIOD_EXPIRED',
  OFFER_REDEEMED = 'OFFER_REDEEMED',
  PRICE_INCREASE = 'PRICE_INCREASE',
  REFUND = 'REFUND',
  REFUND_DECLINED = 'REFUND_DECLINED',
  REFUND_REVERSED = 'REFUND_REVERSED',
  RENEWAL_EXTENDED = 'RENEWAL_EXTENDED',
  RENEWAL_EXTENSION = 'RENEWAL_EXTENSION',
  REVOKE = 'REVOKE',
  SUBSCRIBED = 'SUBSCRIBED',
  TEST = 'TEST',
}

export enum AppleNotificationSubtype {
  INITIAL_BUY = 'INITIAL_BUY',
  RESUBSCRIBE = 'RESUBSCRIBE',
  DOWNGRADE = 'DOWNGRADE',
  UPGRADE = 'UPGRADE',
  AUTO_RENEW_ENABLED = 'AUTO_RENEW_ENABLED',
  AUTO_RENEW_DISABLED = 'AUTO_RENEW_DISABLED',
  VOLUNTARY = 'VOLUNTARY',
  BILLING_RETRY_PERIOD = 'BILLING_RETRY_PERIOD',
  PRICE_INCREASE = 'PRICE_INCREASE',
  GRACE_PERIOD = 'GRACE_PERIOD',
  PENDING = 'PENDING',
  ACCEPTED = 'ACCEPTED',
  BILLING_RECOVERY = 'BILLING_RECOVERY',
  PRODUCT_NOT_FOR_SALE = 'PRODUCT_NOT_FOR_SALE',
  SUMMARY = 'SUMMARY',
  FAILURE = 'FAILURE',
}

/**
 * Google Play Real-time Developer Notifications (RTDN)
 * @see https://developer.android.com/google/play/billing/rtdn-reference
 */

// Google Cloud Pub/Sub message wrapper
export class GoogleRTDNDto {
  @ApiProperty({ description: 'The Pub/Sub message' })
  message: {
    attributes?: Record<string, string>;
    data: string; // Base64-encoded DeveloperNotification
    messageId: string;
    publishTime: string;
  };

  @ApiPropertyOptional({ description: 'The subscription name' })
  subscription?: string;
}

// Decoded DeveloperNotification
export interface GoogleDeveloperNotification {
  version: string;
  packageName: string;
  eventTimeMillis: string;
  subscriptionNotification?: GoogleSubscriptionNotification;
  oneTimeProductNotification?: GoogleOneTimeProductNotification;
  testNotification?: { version: string };
}

export interface GoogleSubscriptionNotification {
  version: string;
  notificationType: GoogleSubscriptionNotificationType;
  purchaseToken: string;
  subscriptionId: string;
}

export interface GoogleOneTimeProductNotification {
  version: string;
  notificationType: GoogleOneTimeNotificationType;
  purchaseToken: string;
  sku: string;
}

/**
 * Google Subscription Notification Types
 * @see https://developer.android.com/google/play/billing/rtdn-reference#sub
 */
export enum GoogleSubscriptionNotificationType {
  SUBSCRIPTION_RECOVERED = 1,      // Recovered from account hold
  SUBSCRIPTION_RENEWED = 2,        // Active subscription renewed
  SUBSCRIPTION_CANCELED = 3,       // Subscription canceled (voluntary or involuntary)
  SUBSCRIPTION_PURCHASED = 4,      // New subscription purchased
  SUBSCRIPTION_ON_HOLD = 5,        // Subscription entered account hold
  SUBSCRIPTION_IN_GRACE_PERIOD = 6, // Subscription entered grace period
  SUBSCRIPTION_RESTARTED = 7,      // Subscription restored from Paused state
  SUBSCRIPTION_PRICE_CHANGE_CONFIRMED = 8,
  SUBSCRIPTION_DEFERRED = 9,       // Subscription deferred
  SUBSCRIPTION_PAUSED = 10,        // Subscription paused
  SUBSCRIPTION_PAUSE_SCHEDULE_CHANGED = 11,
  SUBSCRIPTION_REVOKED = 12,       // Subscription revoked before expiry
  SUBSCRIPTION_EXPIRED = 13,       // Subscription expired
  SUBSCRIPTION_PENDING_PURCHASE_CANCELED = 20,
}

export enum GoogleOneTimeNotificationType {
  ONE_TIME_PRODUCT_PURCHASED = 1,
  ONE_TIME_PRODUCT_CANCELED = 2,
}
