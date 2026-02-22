# IAP (In-App Purchase) Setup Guide

## 📋 Tổng Quan

Soulmate sử dụng **Auto-renewable Subscriptions** qua:
- **iOS**: Apple App Store In-App Purchase
- **Android**: Google Play Billing

---

## 💰 Chiến Lược Pricing

### ⚠️ Nguyên Tắc Quan Trọng

```
┌─────────────────────────────────────────────────────────────────┐
│              CÙNG TÍNH NĂNG - KHÁC GIÁ                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ❌ SAI: Chia VIP 1 – VIP 2 – VIP 3 với tính năng khác nhau      │
│  ❌ SAI: Gói tuần ít tính năng, gói năm có thêm đặc biệt         │
│                                                                  │
│  ✅ ĐÚNG: TẤT CẢ GÓI = CÙNG TÍNH NĂNG PREMIUM                   │
│  ✅ ĐÚNG: CHỈ KHÁC VỀ GIÁ VÀ THỜI GIAN                          │
│                                                                  │
│  Lý do:                                                          │
│  • UX đơn giản, dễ hiểu                                          │
│  • Conversion cao hơn                                            │
│  • Apple/Google review dễ dàng hơn                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Tính Năng Premium (Áp dụng cho TẤT CẢ các gói)

| Tính năng | FREE | PREMIUM |
|-----------|------|---------|
| 💬 Nhắn tin | 5 tin/ngày | ∞ Không giới hạn |
| 👀 Xem ai quan tâm | ❌ | ✅ |
| 📍 Ưu tiên hiển thị | ❌ | ✅ |
| 🏷️ Badge Premium | ❌ | ✅ |
| 🎯 Bộ lọc nâng cao | Cơ bản | ✅ Full |

### Bảng Giá Subscription Plans

| Code | Duration | Price (VND) | Per Day | Savings | Role |
|------|----------|-------------|---------|---------|------|
| `premium_1w` | 7 days | 39,000₫ | 5,571₫ | - | Decoy |
| `premium_1m` | 1 month | 99,000₫ | 3,300₫ | Baseline | Anchor |
| `premium_3m` | 3 months | 249,000₫ | 2,767₫ | **16%** | 🔥 Popular |
| `premium_12m` | 12 months | 699,000₫ | 1,916₫ | **41%** | 💎 Best |

### Chiến Lược Tâm Lý Giá

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRICING PSYCHOLOGY                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1 TUẦN (39k) → DECOY EFFECT                                     │
│     • Giá/ngày cao nhất → làm 1 tháng hấp dẫn hơn                │
│     • Expected: ~5% conversion                                   │
│                                                                  │
│  1 THÁNG (99k) → ANCHOR PRICE                                    │
│     • Baseline so sánh cho các gói khác                          │
│     • Expected: ~25% conversion                                  │
│                                                                  │
│  3 THÁNG (249k) → SWEET SPOT 🔥                                  │
│     • Highlight "Phổ biến nhất" / "Most Popular"                 │
│     • Expected: ~50% conversion (target)                         │
│                                                                  │
│  12 THÁNG (699k) → BEST VALUE 💎                                 │
│     • Highlight "Tiết kiệm nhất" / "Best Value"                  │
│     • Expected: ~20% conversion                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### App Store Tier Mapping

| Plan | iOS Tier | iOS Price | Android Price |
|------|----------|-----------|---------------|
| 1 Tuần | Tier 2 | $1.99 | 39,000₫ |
| 1 Tháng | Tier 4 | $3.99 | 99,000₫ |
| 3 Tháng | Tier 10 | $9.99 | 249,000₫ |
| 12 Tháng | Tier 27 | $27.99 | 699,000₫ |

---

## 🍎 iOS Setup (App Store Connect)

### 1. Tạo App trong App Store Connect
1. Truy cập [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps → `+` → New App
3. Điền thông tin app

### 2. Tạo In-App Purchases
1. Vào app → Features → In-App Purchases
2. Click `+` → **Auto-Renewable Subscription**
3. Tạo **Subscription Group**: `premium`
4. Tạo 4 subscriptions:

#### Product 1: Premium 1 Week
- **Reference Name**: Premium 1 Week
- **Product ID**: `com.soulmate.premium.weekly` 
- **Duration**: 1 week
- **Price**: Tier 2 ($1.99)
- **Localizations**: 
  - Display Name: `Premium 1 Tuần`
  - Description: `Dùng thử Premium - Nhắn tin không giới hạn`

#### Product 2: Premium 1 Month
- **Reference Name**: Premium 1 Month
- **Product ID**: `com.soulmate.premium.monthly` 
- **Duration**: 1 month
- **Price**: Tier 4 ($3.99)
- **Localizations**: 
  - Display Name: `Premium 1 Tháng`
  - Description: `Nhắn tin không giới hạn, ưu tiên ghép cặp, xem ai đã quan tâm`

#### Product 3: Premium 3 Months (Popular)
- **Reference Name**: Premium 3 Months
- **Product ID**: `com.soulmate.premium.quarterly`
- **Duration**: 3 months  
- **Price**: Tier 10 ($9.99)
- **Localizations**: 
  - Display Name: `Premium 3 Tháng`
  - Description: `Tiết kiệm 16% - Gói phổ biến nhất`

#### Product 4: Premium 12 Months (Best Value)
- **Reference Name**: Premium 12 Months
- **Product ID**: `com.soulmate.premium.yearly`
- **Duration**: 12 months
- **Price**: Tier 27 ($27.99)
- **Localizations**: 
  - Display Name: `Premium 12 Tháng`
  - Description: `Tiết kiệm 41% - Gói tiết kiệm nhất`

### 3. Cấu hình Sandbox Testing
1. App Store Connect → Users and Access → Sandbox → Testers
2. Thêm email test (tạo email mới, không dùng Apple ID thật)
3. Trên iPhone: Settings → App Store → Sandbox Account → đăng nhập email test

### 4. Cập nhật Xcode
```xml
<!-- ios/Runner/Info.plist - không cần thêm gì -->
```

In-app purchases tự động được bật khi bạn có Signing & Capabilities với đúng Team.

---

## 🤖 Android Setup (Google Play Console)

### 1. Tạo App trong Google Play Console
1. Truy cập [Google Play Console](https://play.google.com/console)
2. Create app → điền thông tin

### 2. Tạo Subscriptions
1. Monetize → Products → Subscriptions
2. Create subscription

#### Subscription 1: Premium Weekly
- **Product ID**: `premium_weekly`
- **Name**: Premium 1 Tuần
- **Description**: Dùng thử Premium - Nhắn tin không giới hạn
- **Grace period**: 3 days
- **Base Plan**:
  - Billing period: 1 week
  - Price: 39,000 VND (~$1.99)
  - Trial: None (weekly is already trial-like)

#### Subscription 2: Premium Monthly
- **Product ID**: `premium_monthly`
- **Name**: Premium 1 Tháng
- **Description**: Nhắn tin không giới hạn, ưu tiên ghép cặp
- **Grace period**: 7 days
- **Base Plan**:
  - Billing period: 1 month
  - Price: 99,000 VND (~$3.99)
  - Trial: 3 days (optional)

#### Subscription 3: Premium Quarterly (Popular)
- **Product ID**: `premium_quarterly`
- **Name**: Premium 3 Tháng
- **Description**: Tiết kiệm 16% - Gói phổ biến nhất
- **Grace period**: 7 days
- **Base Plan**:
  - Billing period: 3 months
  - Price: 249,000 VND (~$9.99)

#### Subscription 4: Premium Yearly (Best Value)
- **Product ID**: `premium_yearly`
- **Name**: Premium 12 Tháng
- **Description**: Tiết kiệm 41% - Gói tiết kiệm nhất
- **Grace period**: 14 days
- **Base Plan**:
  - Billing period: 12 months
  - Price: 699,000 VND (~$27.99)

### 3. Cấu hình License Testing
1. Play Console → Settings → License testing
2. Thêm email của bạn
3. License response: `RESPOND_NORMALLY`

### 4. Android Configuration
```kotlin
// android/app/build.gradle.kts
android {
    defaultConfig {
        // ...
    }
    
    // Đảm bảo có billing permission (tự động từ package)
}
```

---

## 🔧 Backend Configuration

### 1. Cập nhật Product IDs trong Database
```sql
-- Chạy seed mới hoặc update manual:
-- Gói 1 tuần (mới)
INSERT INTO subscription_plans (id, code, name, name_vi, duration_months, duration_days, price_vnd, apple_product_id, google_product_id, sort_order, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), 'premium_1w', 'Premium 1 Week', 'Premium 1 tuần', 0, 7, 39000, 'com.soulmate.premium.weekly', 'premium_weekly', 1, true, now(), now())
ON CONFLICT (code) DO UPDATE SET
  apple_product_id = EXCLUDED.apple_product_id,
  google_product_id = EXCLUDED.google_product_id,
  price_vnd = EXCLUDED.price_vnd;

-- Update các gói hiện có
UPDATE subscription_plans 
SET 
  apple_product_id = 'com.soulmate.premium.monthly',
  google_product_id = 'premium_monthly',
  sort_order = 2
WHERE code = 'premium_1m';

UPDATE subscription_plans 
SET 
  apple_product_id = 'com.soulmate.premium.quarterly',
  google_product_id = 'premium_quarterly',
  sort_order = 3
WHERE code = 'premium_3m';

UPDATE subscription_plans 
SET 
  apple_product_id = 'com.soulmate.premium.yearly',
  google_product_id = 'premium_yearly',
  price_vnd = 699000,
  discount_percent = 41,
  sort_order = 4
WHERE code = 'premium_12m';
```

Hoặc chạy seed lại:

```bash
cd backend
npx prisma migrate dev --name add_iap_product_ids
```

### 2. Environment Variables
```bash
# .env
# Apple
APPLE_SHARED_SECRET=your_shared_secret_from_app_store_connect
APPLE_VERIFY_RECEIPT_URL=https://buy.itunes.apple.com/verifyReceipt
APPLE_VERIFY_RECEIPT_SANDBOX_URL=https://sandbox.itunes.apple.com/verifyReceipt

# Google
GOOGLE_SERVICE_ACCOUNT_KEY_PATH=./google-service-account.json
GOOGLE_PACKAGE_NAME=com.yourcompany.soulmate
```

### 3. Implement Receipt Verification (Production)

Cập nhật `subscriptions.service.ts`:

```typescript
// backend/src/modules/subscriptions/subscriptions.service.ts

import * as AppleReceiptVerifier from 'node-apple-receipt-verify';
import { google } from 'googleapis';

private async verifyReceipt(dto: {
  platform: 'ios' | 'android';
  receiptData: string;
  productId: string;
}): Promise<{
  isValid: boolean;
  transactionId?: string;
  originalTransactionId?: string;
  expiresAt?: Date;
}> {
  if (dto.platform === 'ios') {
    return this.verifyAppleReceipt(dto.receiptData);
  } else {
    return this.verifyGoogleReceipt(dto.receiptData, dto.productId);
  }
}

private async verifyAppleReceipt(receiptData: string) {
  // Use node-apple-receipt-verify or call Apple's API directly
  // npm install node-apple-receipt-verify
  
  const response = await fetch('https://buy.itunes.apple.com/verifyReceipt', {
    method: 'POST',
    body: JSON.stringify({
      'receipt-data': receiptData,
      'password': process.env.APPLE_SHARED_SECRET,
      'exclude-old-transactions': true,
    }),
  });
  
  const data = await response.json();
  
  // Status 21007 means sandbox receipt, retry with sandbox URL
  if (data.status === 21007) {
    const sandboxResponse = await fetch('https://sandbox.itunes.apple.com/verifyReceipt', {
      method: 'POST',
      body: JSON.stringify({
        'receipt-data': receiptData,
        'password': process.env.APPLE_SHARED_SECRET,
        'exclude-old-transactions': true,
      }),
    });
    return this.parseAppleResponse(await sandboxResponse.json());
  }
  
  return this.parseAppleResponse(data);
}

private parseAppleResponse(data: any) {
  if (data.status !== 0) {
    return { isValid: false };
  }
  
  const latestReceipt = data.latest_receipt_info?.[0];
  if (!latestReceipt) {
    return { isValid: false };
  }
  
  return {
    isValid: true,
    transactionId: latestReceipt.transaction_id,
    originalTransactionId: latestReceipt.original_transaction_id,
    expiresAt: new Date(parseInt(latestReceipt.expires_date_ms)),
  };
}

private async verifyGoogleReceipt(purchaseToken: string, productId: string) {
  // Use Google Play Developer API
  // npm install googleapis
  
  const auth = new google.auth.GoogleAuth({
    keyFile: process.env.GOOGLE_SERVICE_ACCOUNT_KEY_PATH,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  
  const androidPublisher = google.androidpublisher({ version: 'v3', auth });
  
  try {
    const response = await androidPublisher.purchases.subscriptions.get({
      packageName: process.env.GOOGLE_PACKAGE_NAME,
      subscriptionId: productId,
      token: purchaseToken,
    });
    
    const data = response.data;
    
    return {
      isValid: data.paymentState === 1, // 1 = received
      transactionId: data.orderId,
      originalTransactionId: data.linkedPurchaseToken || data.orderId,
      expiresAt: new Date(parseInt(data.expiryTimeMillis || '0')),
    };
  } catch (error) {
    console.error('Google receipt verification failed:', error);
    return { isValid: false };
  }
}
```

---

## 📱 Mobile Testing

### iOS Sandbox Testing
1. Build app với Development certificate
2. Đăng nhập Sandbox account trên device
3. Mở Premium page và mua subscription
4. Sandbox subscriptions renew nhanh hơn:
   - 1 month → 5 minutes
   - 3 months → 15 minutes
   - 12 months → 1 hour

### Android Testing
1. Upload APK/AAB lên Internal testing track
2. Thêm email test vào License testers
3. Download app từ Play Store (internal)
4. Test purchase flow

---

## � App Store Server Notifications & Google Play RTDN

### Tổng Quan

Apple/Google gửi **server-to-server notifications** cho backend khi có sự kiện liên quan đến subscription:
- Gia hạn thành công
- Gia hạn thất bại (billing issue)
- Hủy subscription
- Hoàn tiền (refund)
- Hết hạn
- Grace period

**Đây là cách duy nhất đáng tin cậy để backend biết trạng thái thực sự của subscription** — không chỉ dựa vào client gửi receipt.

### Apple App Store Server Notifications V2

#### Cấu hình trong App Store Connect

1. Truy cập [App Store Connect](https://appstoreconnect.apple.com)
2. Chọn App → **App Information** (trong General)
3. Scroll xuống phần **App Store Server Notifications**
4. Nhập 2 URL:

| Field | URL |
|-------|-----|
| **Production Server URL** | `https://your-domain.com/api/v1/webhooks/apple/notifications` |
| **Sandbox Server URL** | `https://your-domain.com/api/v1/webhooks/apple/notifications/sandbox` |

5. Chọn **Version 2** cho notifications
6. Click **Save**

> **Lưu ý:** Có thể mất đến 1 giờ để thay đổi có hiệu lực trong sandbox environment.

#### Apple Notification Types được xử lý

| Notification Type | Ý nghĩa | Hành động Backend |
|-------------------|----------|-------------------|
| `TEST` | Test notification | Log OK |
| `SUBSCRIBED` | Đăng ký mới / Tái đăng ký | Activate subscription |
| `DID_RENEW` | Gia hạn thành công | Extend endDate, notify user |
| `DID_CHANGE_RENEWAL_STATUS` | Bật/tắt auto-renew | Update isAutoRenew |
| `DID_FAIL_TO_RENEW` | Billing issue | Set GRACE_PERIOD, notify user |
| `EXPIRED` | Hết hạn | Set EXPIRED, revoke premium |
| `GRACE_PERIOD_EXPIRED` | Grace period kết thúc | Set EXPIRED, revoke premium |
| `REFUND` | Apple hoàn tiền | Set CANCELLED, revoke premium |
| `REVOKE` | Family sharing bị thu hồi | Set CANCELLED, revoke premium |
| `DID_CHANGE_RENEWAL_PREF` | Đổi gói (upgrade/downgrade) | Log for analytics |

#### Cách Apple gửi notification

Apple gửi POST request với body:
```json
{
  "signedPayload": "<JWS signed string>"
}
```

JWS (JSON Web Signature) chứa 3 parts: `header.payload.signature`
- **header**: Certificate chain (x5c) để verify
- **payload**: Notification data (type, transaction info, renewal info)
- **signature**: Chữ ký bởi Apple

### Google Play Real-time Developer Notifications (RTDN)

#### Cấu hình trong Google Play Console

1. Tạo **Cloud Pub/Sub topic** trong Google Cloud Console:
   ```bash
   # Tạo topic
   gcloud pubsub topics create play-subscription-notifications
   
   # Cấp quyền cho Google Play service account
   gcloud pubsub topics add-iam-policy-binding play-subscription-notifications \
     --member="serviceAccount:google-play-developer-notifications@system.gserviceaccount.com" \
     --role="roles/pubsub.publisher"
   ```

2. Tạo **Push subscription** cho topic:
   ```bash
   gcloud pubsub subscriptions create play-subscription-push \
     --topic=play-subscription-notifications \
     --push-endpoint=https://your-domain.com/api/v1/webhooks/google/notifications
   ```

3. Trong **Google Play Console**:
   - Monetization setup → Real-time developer notifications
   - Enable RTDN
   - Topic name: `projects/{project-id}/topics/play-subscription-notifications`

#### Google Notification Types được xử lý

| Type | Ý nghĩa | Hành động Backend |
|------|----------|-------------------|
| `SUBSCRIPTION_PURCHASED` (4) | Mua mới | Already via verifyPurchase |
| `SUBSCRIPTION_RENEWED` (2) | Gia hạn thành công | Extend endDate, notify user |
| `SUBSCRIPTION_CANCELED` (3) | Hủy auto-renew | Update isAutoRenew=false |
| `SUBSCRIPTION_ON_HOLD` (5) | Account hold (billing) | Set GRACE_PERIOD, revoke |
| `SUBSCRIPTION_IN_GRACE_PERIOD` (6) | Grace period | Notify user |
| `SUBSCRIPTION_RECOVERED` (1) | Khôi phục từ hold | Set ACTIVE, restore premium |
| `SUBSCRIPTION_REVOKED` (12) | Thu hồi trước hạn | Set CANCELLED, revoke |
| `SUBSCRIPTION_EXPIRED` (13) | Hết hạn | Set EXPIRED, revoke |
| `SUBSCRIPTION_RESTARTED` (7) | Kích hoạt lại từ pause | Set ACTIVE, restore |

### Backend Implementation

#### Files

| File | Mô tả |
|------|--------|
| `src/modules/subscriptions/webhook.controller.ts` | Controller nhận webhook từ Apple/Google |
| `src/modules/subscriptions/subscription-webhook.service.ts` | Xử lý business logic cho notifications |
| `src/modules/subscriptions/dto/webhook.dto.ts` | DTOs và interfaces cho webhook payloads |

#### Webhook Endpoints

```
POST /api/v1/webhooks/apple/notifications          ← Apple Production
POST /api/v1/webhooks/apple/notifications/sandbox   ← Apple Sandbox
POST /api/v1/webhooks/google/notifications          ← Google Play RTDN
```

> **Quan trọng:** Các endpoint này là **PUBLIC** (không cần JWT auth) vì Apple/Google gọi trực tiếp. Security được đảm bảo bằng cách verify JWS signature (Apple) và Pub/Sub authentication (Google).

#### Environment Variables

```bash
# Apple
APPLE_SHARED_SECRET=your_shared_secret
APPLE_VERIFY_RECEIPT_URL=https://buy.itunes.apple.com/verifyReceipt
APPLE_VERIFY_RECEIPT_SANDBOX_URL=https://sandbox.itunes.apple.com/verifyReceipt
APPLE_BUNDLE_ID=com.yourcompany.soulmate

# Google
GOOGLE_SERVICE_ACCOUNT_KEY_PATH=./google-service-account.json
GOOGLE_PACKAGE_NAME=com.yourcompany.soulmate
```

### Flow Diagram (với Server Notifications)

```
┌──────────────────────────────────────────────────────────────────────┐
│                Server Notification Flow                              │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────┐    Purchase    ┌──────────┐   Verify    ┌─────────┐    │
│  │  Mobile  │ ──────────── │  Backend  │ ──────────│ Apple/   │    │
│  │   App    │   Receipt     │  Server   │   Receipt  │ Google   │    │
│  └─────────┘               └──────────┘            └─────────┘    │
│                                   ▲                       │          │
│                                   │                       │          │
│                                   │  Webhook (async)      │          │
│                                   │                       │          │
│                                   │  • DID_RENEW          │          │
│                                   │  • EXPIRED            │          │
│                                   │  • REFUND             │          │
│                                   │  • DID_FAIL_TO_RENEW  │          │
│                                   │  • etc.               │          │
│                                   │                       │          │
│                                   └───────────────────────┘          │
│                                                                      │
│  → Client-initiated: Purchase & Restore (synchronous)                │
│  → Server-initiated: Renewal, Expiry, Refund (asynchronous webhook)  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Checklist App Store Server Notifications

- [ ] App Store Connect: Production Server URL configured
- [ ] App Store Connect: Sandbox Server URL configured
- [ ] App Store Connect: Version 2 selected
- [ ] Backend: webhook.controller.ts deployed
- [ ] Backend: subscription-webhook.service.ts deployed
- [ ] Backend: Test notification received successfully (send from App Store Connect)
- [ ] Google Play Console: RTDN enabled with Pub/Sub topic
- [ ] Google Cloud: Push subscription pointing to backend webhook URL
- [ ] Backend: Google RTDN test notification received

---

## �🔄 Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          User Flow                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. User opens PremiumPage                                       │
│         │                                                        │
│         ▼                                                        │
│  2. Fetch plans from backend (/subscriptions/plans)              │
│         │                                                        │
│         ▼                                                        │
│  3. Fetch IAP products from Store using appleProductId/          │
│     googleProductId                                              │
│         │                                                        │
│         ▼                                                        │
│  4. User selects plan and taps "Đăng ký"                         │
│         │                                                        │
│         ▼                                                        │
│  5. IAP Service calls InAppPurchase.buyNonConsumable()           │
│         │                                                        │
│         ▼                                                        │
│  6. OS shows payment sheet → User confirms                       │
│         │                                                        │
│         ▼                                                        │
│  7. IAP purchase stream emits PurchaseDetails                    │
│         │                                                        │
│         ▼                                                        │
│  8. Mobile sends receipt to backend                              │
│     POST /subscriptions/verify-purchase                          │
│     { platform, productId, receiptData }                         │
│         │                                                        │
│         ▼                                                        │
│  9. Backend verifies with Apple/Google                           │
│         │                                                        │
│         ▼                                                        │
│  10. Backend creates Subscription record                         │
│      Updates User.isPremium = true                               │
│      Updates User.premiumUntil = endDate                         │
│         │                                                        │
│         ▼                                                        │
│  11. Mobile shows success dialog                                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## ⚠️ Checklist Before Submission

### iOS
- [ ] App Store Connect: In-App Purchases created & submitted for review
- [ ] App Store Connect: Subscription Group configured
- [ ] App Store Connect: Subscription pricing set
- [ ] App Store Connect: Localizations added (Vietnamese)
- [ ] App Store Connect: **Production Server URL** set for App Store Server Notifications
- [ ] App Store Connect: **Sandbox Server URL** set for App Store Server Notifications
- [ ] App Store Connect: **Version 2** selected for notifications
- [ ] Backend: Apple shared secret configured
- [ ] Backend: Receipt verification implemented
- [ ] Backend: Webhook endpoint deployed and accessible
- [ ] Terms of Use and Privacy Policy links in app
- [ ] "Restore Purchases" button visible

### Android
- [ ] Play Console: Subscriptions created & activated
- [ ] Play Console: Service account with API access
- [ ] Play Console: **RTDN enabled** with Pub/Sub topic
- [ ] Google Cloud: Push subscription pointing to webhook URL
- [ ] Backend: Google service account JSON configured
- [ ] Backend: Google receipt verification implemented
- [ ] Backend: Webhook endpoint deployed and accessible
- [ ] Terms of Use and Privacy Policy links in app
- [ ] "Restore Purchases" button visible

### Both Platforms
- [ ] Test purchase flow in sandbox/test mode
- [ ] Test restore purchases
- [ ] Test subscription expiration
- [ ] Test server notification (send test from App Store Connect)
- [ ] Handle edge cases (network errors, canceled, pending)

---

## 🔐 Apple App Store Review Notes

Khi submit app, thêm vào App Review Notes:

```
SUBSCRIPTION INFORMATION:
- Our app offers auto-renewable subscriptions for Premium features
- Premium 1 Week: $1.99/week
- Premium 1 Month: $3.99/month
- Premium 3 Months: $9.99/3 months (16% savings)
- Premium 12 Months: $27.99/year (41% savings)
- Payment will be charged to iTunes Account at confirmation of purchase
- Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period
- Account will be charged for renewal within 24-hours prior to the end of the current period
- Subscriptions may be managed by the user and auto-renewal may be turned off in Account Settings after purchase
- Privacy Policy: [your-url]/privacy
- Terms of Use: [your-url]/terms
```

---

## 📁 Files Modified

### Mobile
- `pubspec.yaml` - Added `in_app_purchase: ^3.2.3`
- `lib/features/subscription/data/services/iap_service.dart` - New IAP service
- `lib/features/subscription/presentation/pages/premium_page.dart` - IAP integration
- `lib/features/subscription/data/repositories/subscription_repository_impl.dart` - Fixed response parsing
- `lib/core/di/injection.dart` - Registered IAPService

### Backend
- `src/modules/subscriptions/subscriptions.service.ts` - Receipt verification (needs production implementation)
- `src/modules/subscriptions/webhook.controller.ts` - **NEW** Apple & Google webhook endpoints
- `src/modules/subscriptions/subscription-webhook.service.ts` - **NEW** Webhook business logic
- `src/modules/subscriptions/dto/webhook.dto.ts` - **NEW** Webhook DTOs & interfaces
- `src/modules/subscriptions/subscriptions.module.ts` - Updated with webhook controller & service
