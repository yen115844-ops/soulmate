# Soft Verification & Premium Subscription Strategy

## Phần 1: SOFT VERIFICATION (Selfie + Liveness)

### 1.1 Mục tiêu
- ✅ Selfie + Liveness detection (không cần CCCD)
- ✅ Tick xanh cho user đã xác thực
- ✅ Không lưu giấy tờ cá nhân (chỉ selfie + liveness score)
- ✅ CMS duyệt manual nếu cần

### 1.2 Flow xác thực

```
User chụp selfie → App gửi lên server → Liveness check (AI) → 
  IF score >= 0.85 → Auto verify → Tick xanh
  IF score >= 0.70 → Pending review → CMS duyệt
  ELSE → Rejected → User thử lại
```

### 1.3 Backend Changes

#### Database Schema (prisma/schema.prisma)

```prisma
// Đổi tên và cấu trúc KycVerification → SoftVerification
model SoftVerification {
  id              String   @id @default(uuid())
  userId          String   @unique @map("user_id")
  user            User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  // Selfie verification (NO ID CARD)
  selfieUrl       String?  @map("selfie_url")
  
  // Liveness check results
  livenessScore   Decimal? @map("liveness_score") @db.Decimal(5, 4)
  livenessCheckId String?  @map("liveness_check_id") // External provider ID
  
  // Status
  status          KycStatus @default(PENDING)
  rejectionReason String?  @map("rejection_reason") @db.Text
  
  // Auto vs manual verification
  isAutoVerified  Boolean  @default(false) @map("is_auto_verified")
  verifiedAt      DateTime? @map("verified_at")
  verifiedBy      String?  @map("verified_by") // Admin ID (null if auto)
  
  // Metadata
  submittedAt     DateTime? @map("submitted_at")
  reviewNote      String?  @map("review_note") @db.Text
  deviceInfo      String?  @map("device_info") // Device fingerprint
  
  createdAt       DateTime @default(now()) @map("created_at")
  updatedAt       DateTime @updatedAt @map("updated_at")
  
  @@map("soft_verifications")
}
```

#### API Endpoints

```
POST /api/verification/submit-selfie
  - Upload selfie image
  - Run liveness check
  - Auto-approve if score >= 0.85
  
GET /api/verification/status
  - Get current verification status
  
POST /api/admin/verification/:id/review
  - Approve/reject pending verifications (CMS)
```

#### Service Logic

```typescript
// verification.service.ts
async submitSelfie(userId: string, selfieFile: Express.Multer.File) {
  // 1. Upload selfie to storage
  const selfieUrl = await this.uploadService.upload(selfieFile);
  
  // 2. Call liveness check API (e.g., AWS Rekognition, FPT.AI)
  const livenessResult = await this.livenessService.check(selfieUrl);
  
  // 3. Determine status based on score
  const AUTO_APPROVE_THRESHOLD = 0.85;
  const MANUAL_REVIEW_THRESHOLD = 0.70;
  
  let status: KycStatus;
  let isAutoVerified = false;
  
  if (livenessResult.score >= AUTO_APPROVE_THRESHOLD) {
    status = KycStatus.VERIFIED;
    isAutoVerified = true;
  } else if (livenessResult.score >= MANUAL_REVIEW_THRESHOLD) {
    status = KycStatus.PENDING;
  } else {
    status = KycStatus.REJECTED;
  }
  
  // 4. Save verification
  const verification = await this.prisma.softVerification.upsert({
    where: { userId },
    create: {
      userId,
      selfieUrl,
      livenessScore: livenessResult.score,
      livenessCheckId: livenessResult.checkId,
      status,
      isAutoVerified,
      submittedAt: new Date(),
      verifiedAt: isAutoVerified ? new Date() : null,
    },
    update: {
      selfieUrl,
      livenessScore: livenessResult.score,
      status,
      isAutoVerified,
      submittedAt: new Date(),
      verifiedAt: isAutoVerified ? new Date() : null,
    },
  });
  
  // 5. Update user kycStatus
  if (status === KycStatus.VERIFIED) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { kycStatus: KycStatus.VERIFIED },
    });
  }
  
  return verification;
}
```

### 1.4 Mobile Changes

#### Domain Layer
```dart
// lib/features/verification/domain/entities/verification_entity.dart
class VerificationEntity {
  final String id;
  final String userId;
  final String? selfieUrl;
  final double? livenessScore;
  final VerificationStatus status;
  final bool isAutoVerified;
  final DateTime? verifiedAt;
}
```

#### Data Layer
```dart
// lib/features/verification/data/repositories/verification_repository.dart
abstract class VerificationRepository {
  Future<VerificationEntity> submitSelfie(File selfieFile);
  Future<VerificationEntity> getStatus();
}
```

#### Presentation Layer
```dart
// lib/features/verification/presentation/pages/verification_page.dart
// Camera page with liveness detection
// Shows result: verified, pending, rejected
```

### 1.5 CMS Changes

Update KYC page để:
- Chỉ hiển thị selfie (không có CCCD)
- Chỉ hiện PENDING cases cho manual review
- Show liveness score
- Approve/Reject với note

---

## Phần 2: IAP PREMIUM SUBSCRIPTION

### 2.1 Premium Benefits

| Feature | Free User | Premium User |
|---------|-----------|--------------|
| Nhắn tin/ngày | 5 tin | Không giới hạn |
| Ưu tiên ghép cặp | ❌ | ✅ Top of search |
| Tăng hiển thị | ❌ | ✅ 3x visibility boost |
| Xem ai quan tâm | ❌ | ✅ Full list |
| Tick Premium | ❌ | ✅ Gold badge |

### 2.2 Subscription Plans

```
- 1 tháng: 99,000 VND
- 3 tháng: 249,000 VND (tiết kiệm 17%)
- 12 tháng: 799,000 VND (tiết kiệm 33%)
```

### 2.3 Backend Changes

#### Database Schema

```prisma
// Subscription Plans
model SubscriptionPlan {
  id              String   @id @default(uuid())
  code            String   @unique // "premium_1m", "premium_3m", "premium_12m"
  name            String   // "Premium 1 tháng"
  description     String?  @db.Text
  
  durationMonths  Int      @map("duration_months")
  priceVnd        Decimal  @map("price_vnd") @db.Decimal(12, 2)
  
  // IAP identifiers
  appleProductId  String?  @unique @map("apple_product_id")
  googleProductId String?  @unique @map("google_product_id")
  
  isActive        Boolean  @default(true) @map("is_active")
  sortOrder       Int      @default(0) @map("sort_order")
  
  createdAt       DateTime @default(now()) @map("created_at")
  updatedAt       DateTime @updatedAt @map("updated_at")
  
  subscriptions   Subscription[]
  
  @@map("subscription_plans")
}

// User Subscriptions
model Subscription {
  id              String   @id @default(uuid())
  userId          String   @map("user_id")
  user            User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  planId          String   @map("plan_id")
  plan            SubscriptionPlan @relation(fields: [planId], references: [id])
  
  status          SubscriptionStatus @default(ACTIVE)
  
  // Dates
  startDate       DateTime @map("start_date")
  endDate         DateTime @map("end_date")
  
  // IAP info
  platform        String   // "ios", "android"
  originalTxId    String?  @map("original_transaction_id") // Apple/Google original tx
  latestTxId      String?  @map("latest_transaction_id")
  
  // Auto-renewal
  isAutoRenew     Boolean  @default(true) @map("is_auto_renew")
  cancelledAt     DateTime? @map("cancelled_at")
  
  createdAt       DateTime @default(now()) @map("created_at")
  updatedAt       DateTime @updatedAt @map("updated_at")
  
  @@index([userId, status])
  @@index([endDate])
  @@map("subscriptions")
}

enum SubscriptionStatus {
  ACTIVE
  EXPIRED
  CANCELLED
  GRACE_PERIOD
}

// Update User model
model User {
  // ... existing fields
  
  subscriptions     Subscription[]
  
  // Computed/cached field for performance
  isPremium         Boolean  @default(false) @map("is_premium")
  premiumUntil      DateTime? @map("premium_until")
}
```

#### API Endpoints

```
GET /api/subscriptions/plans
  - Get available subscription plans

POST /api/subscriptions/verify-purchase
  - Verify IAP receipt (Apple/Google)
  - Create/extend subscription

GET /api/subscriptions/status
  - Get current subscription status

POST /api/webhooks/apple/subscription
  - Apple Server-to-Server notifications

POST /api/webhooks/google/subscription
  - Google Real-time Developer Notifications
```

### 2.4 Mobile Changes

#### Domain Layer
```dart
// lib/features/subscription/domain/entities/subscription_entity.dart
class SubscriptionEntity {
  final String id;
  final SubscriptionPlanEntity plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final bool isAutoRenew;
}

class SubscriptionPlanEntity {
  final String id;
  final String code;
  final String name;
  final int durationMonths;
  final double priceVnd;
  final String? appleProductId;
  final String? googleProductId;
}
```

#### Data Layer
```dart
// lib/features/subscription/data/repositories/subscription_repository.dart
abstract class SubscriptionRepository {
  Future<List<SubscriptionPlanEntity>> getPlans();
  Future<SubscriptionEntity?> getCurrentSubscription();
  Future<SubscriptionEntity> purchasePlan(String planId);
  Future<void> restorePurchases();
}
```

#### IAP Integration
```dart
// lib/features/subscription/data/services/iap_service.dart
// Using in_app_purchase package
class IAPService {
  Future<List<ProductDetails>> fetchProducts(List<String> productIds);
  Future<bool> purchaseProduct(ProductDetails product);
  Stream<PurchaseDetails> get purchaseStream;
}
```

#### Presentation Layer
```dart
// lib/features/subscription/presentation/pages/subscription_page.dart
// Show plans, handle purchase flow

// lib/features/subscription/presentation/bloc/subscription_bloc.dart
// Manage subscription state
```

### 2.5 Premium Feature Enforcement

#### Backend
```typescript
// Chat limit
async canSendMessage(userId: string): Promise<boolean> {
  const user = await this.getUser(userId);
  if (user.isPremium) return true;
  
  const todayMessages = await this.countTodayMessages(userId);
  return todayMessages < FREE_DAILY_MESSAGE_LIMIT; // 5
}

// Search boost
async searchPartners(dto: SearchPartnersDto) {
  // Premium partners appear first
  return this.prisma.partnerProfile.findMany({
    orderBy: [
      { user: { isPremium: 'desc' } },
      { averageRating: 'desc' },
    ],
  });
}

// Who favorited me
async getMyAdmirers(userId: string) {
  const user = await this.getUser(userId);
  if (!user.isPremium) {
    throw new ForbiddenException('Upgrade to Premium to see who favorited you');
  }
  return this.favoriteService.getAdmirers(userId);
}
```

#### Mobile
```dart
// lib/shared/guards/premium_guard.dart
class PremiumGuard {
  static bool isPremium(BuildContext context) {
    return context.read<AuthBloc>().state.user?.isPremium ?? false;
  }
  
  static void requirePremium(BuildContext context, {VoidCallback? onUpgrade}) {
    if (!isPremium(context)) {
      showPremiumDialog(context, onUpgrade: onUpgrade);
    }
  }
}
```

---

## Phần 3: IMPLEMENTATION ORDER

### Phase 1: Backend Foundation
1. Create new Prisma models (SoftVerification, SubscriptionPlan, Subscription)
2. Run migration
3. Create verification module
4. Create subscription module
5. Add seed data for subscription plans

### Phase 2: Mobile Foundation
1. Create verification feature (domain, data, presentation)
2. Create subscription feature (domain, data, presentation)
3. Integrate IAP package
4. Add premium guards

### Phase 3: CMS Updates
1. Update KYC page for Soft Verification
2. Add subscription management page
3. Add user premium status view

### Phase 4: Feature Integration
1. Implement message limits
2. Implement search boost
3. Implement "who favorited me"
4. Update partner cards with verified/premium badges

---

## Phần 4: UI/UX Guidelines

### Verified Badge (Tick xanh)
- Icon: Shield with checkmark
- Color: Blue (#2563EB)
- Show on: Partner cards, profile header, chat

### Premium Badge (Tick vàng)
- Icon: Crown or star
- Color: Gold (#F59E0B)
- Show on: Partner cards, profile header

### Subscription Page
- Clear pricing comparison
- Highlight savings
- Easy purchase flow
- Restore purchases option

---

## Phần 5: Testing Checklist

### Soft Verification
- [ ] Submit selfie → auto-approve (high score)
- [ ] Submit selfie → pending (medium score)
- [ ] Submit selfie → reject (low score)
- [ ] CMS manual approve/reject
- [ ] Verified badge appears

### Premium Subscription
- [ ] View plans
- [ ] Purchase (sandbox)
- [ ] Verify receipt
- [ ] Subscription active
- [ ] Features unlocked
- [ ] Expiry handling
- [ ] Restore purchases
