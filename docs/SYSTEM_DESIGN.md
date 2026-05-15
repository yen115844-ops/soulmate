# MATE SOCIAL - System Design Document

## 📌 Tổng quan

**Mate Social** là nền tảng kết nối người dùng tìm bạn đồng hành (Companion/Partner) cho các sự kiện và trải nghiệm xã hội như: đi dạo, xem phim, dự tiệc, tham gia sự kiện, du lịch, v.v.

### Stakeholders
- **User (Khách hàng)**: Người tìm kiếm bạn đồng hành
- **Partner (Người đồng hành)**: Người cung cấp dịch vụ đồng hành
- **Admin**: Quản trị viên hệ thống
- **Support Team**: Đội ngũ hỗ trợ khẩn cấp

---

## ✨ Chức năng chính của app (đã có trong code)

Phần này tổng hợp từ code `mobile` + `backend` hiện tại để team dùng làm tài liệu social/growth, tập trung vào những gì đã triển khai thực tế.

### 1) Discovery & Kết nối ban đầu
- Tìm kiếm danh sách partner theo bộ lọc (khu vực, dịch vụ, điều kiện phù hợp).
- Home có trải nghiệm duyệt nhanh theo kiểu swipe/tab để giảm friction khi khám phá.
- Người dùng có thể lưu favorites để quay lại profile tiềm năng.

### 2) Booking workflow end-to-end
- Luồng booking đầy đủ: tạo yêu cầu -> xác nhận -> thanh toán -> bắt đầu -> hoàn thành/hủy.
- Trạng thái booking rõ ràng giúp đồng bộ giữa user, partner và hệ thống.
- Đây là trục chuyển đổi chính từ "xem profile" sang "hành động thật".

### 3) Chat realtime sau khi có intent
- Có conversation, gửi tin nhắn, unread count, trạng thái online.
- Chat tạo cầu nối trước/sau booking và tăng tỷ lệ quay lại app mỗi ngày.
- Realtime layer đã sẵn sàng để mở rộng thêm social hooks (gợi ý tương tác, prompts, v.v.).

### 4) Notification & Re-engagement
- Push notification (FCM), token management, unread/mark-read đã có.
- Có thể dùng cho nhiều trigger tăng retention: booking updates, tin nhắn mới, admirers, ưu đãi premium.
- Nền tảng notification hiện tại đủ để làm lifecycle campaigns cơ bản.

### 5) Trust/Safety cho social ngoài đời thật
- Verification (KYC/liveness flow) giúp tăng độ tin cậy profile.
- Safety module có SOS/emergency contacts/location logs.
- Reviews sau tương tác giúp tạo social proof và giảm rủi ro khi kết nối.

### 6) Monetization hỗ trợ growth
- Subscription premium + credit wallet/package/transaction đã triển khai.
- Feature "admirers" tạo nhu cầu nâng cấp premium tự nhiên.
- Credits có thể dùng để tối ưu ARPU mà không phá trải nghiệm core.

### 7) Những điểm "hay" để đẩy social ngay
- Engagement loop đã hình thành rõ: **Discovery -> Booking -> Chat -> Review/Favorite -> Notification -> Quay lại Discovery**.
- Có đủ nền để triển khai growth experiments nhanh: nhắc quay lại theo sự kiện, ưu đãi theo hành vi, unlock social visibility bằng premium.
- Ưu thế khác biệt là social có lớp an toàn/verification đi kèm, phù hợp các tương tác ngoài đời thực.

### 8) Gợi ý roadmap social (ưu tiên gần)
- **Ngắn hạn (1-2 sprint):** tăng trigger notification theo hành vi chat/booking/favorite, tối ưu onboarding để chạm "first chat" sớm hơn.
- **Trung hạn:** thêm social graph nhẹ (mutual interest, gợi ý kết nối theo hành vi tương đồng), ranking discovery theo tín hiệu engagement.
- **Dài hạn:** cân nhắc social feed/community layer nếu muốn mở use case ngoài booking.

---

## 🛠️ Technology Stack

### Frontend - Flutter

| Layer | Technology | Mục đích |
|-------|------------|----------|
| **Framework** | Flutter 3.x | Cross-platform iOS + Android + Web |
| **State Management** | flutter_bloc | Predictable state, Easy testing |
| **Navigation** | go_router | Declarative routing, Deep linking |
| **HTTP Client** | dio | Interceptors, Retry, Cancel tokens |
| **WebSocket** | socket_io_client | Real-time chat |
| **Local Storage** | hive / shared_preferences | Offline data |
| **Secure Storage** | flutter_secure_storage | Token storage |
| **Maps** | google_maps_flutter | GPS, Location |
| **DI** | get_it + injectable | Dependency injection |

### Backend - NestJS

| Layer | Technology | Mục đích |
|-------|------------|----------|
| **Framework** | NestJS 10.x | TypeScript, Modular, Enterprise-ready |
| **ORM** | Prisma | Type-safe, Auto migrations |
| **Validation** | class-validator | DTO validation |
| **Auth** | @nestjs/passport + JWT | Authentication |
| **WebSocket** | @nestjs/websockets + Socket.io | Real-time |
| **Queue** | @nestjs/bull + Redis | Background jobs |
| **File Upload** | @nestjs/platform-express + Multer | File handling |
| **API Docs** | @nestjs/swagger | Auto-generated docs |

### Database & Infrastructure

| Component | Technology | Use Case |
|-----------|------------|----------|
| **Primary DB** | PostgreSQL 15 | All structured data |
| **Cache** | Redis 7 | Session, Cache, Queue, Pub/Sub |
| **Object Storage** | AWS S3 / MinIO | Images, Videos, Documents |
| **Search** | PostgreSQL Full-text (MVP) → Elasticsearch (Scale) | Partner search |

### External Services

| Service | Provider | Purpose |
|---------|----------|---------|
| **Push Notifications** | Firebase Cloud Messaging | Mobile notifications |
| **SMS** | Twilio / Stringee | OTP verification |
| **Email** | SendGrid / AWS SES | Transactional emails |
| **eKYC** | VNPT eKYC / FPT.AI | Identity verification |
| **Payment** | VNPay, MoMo, ZaloPay | Payment processing |
| **Maps** | Google Maps Platform | Geocoding, Distance |

---

## 🏗️ High-Level Architecture

### Phase 1: Modular Monolith (MVP - Fast Development)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────┐              ┌──────────────────────────┐ │
│  │        Flutter App           │              │      Flutter Web         │ │
│  │     (User + Partner)         │              │     (Admin Panel)        │ │
│  │  • iOS  • Android  • Web     │              │                          │ │
│  └──────────────────────────────┘              └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        NESTJS MODULAR MONOLITH                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                         API Gateway Layer                               │ │
│  │  • Rate Limiting  • JWT Auth  • Request Validation  • Logging         │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                      │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                         Application Modules                             │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │ │
│  │  │   Auth   │ │   User   │ │ Partner  │ │ Booking  │ │  Search  │     │ │
│  │  │  Module  │ │  Module  │ │  Module  │ │  Module  │ │  Module  │     │ │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘     │ │
│  │                                                                        │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │ │
│  │  │   Chat   │ │ Payment  │ │  Safety  │ │  Rating  │ │   KYC    │     │ │
│  │  │  Module  │ │  Module  │ │  Module  │ │  Module  │ │  Module  │     │ │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘     │ │
│  │                                                                        │ │
│  │  ┌──────────┐ ┌──────────┐                                            │ │
│  │  │Blacklist │ │Notificat.│                                            │ │
│  │  │  Module  │ │  Module  │                                            │ │
│  │  └──────────┘ └──────────┘                                            │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                      │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                         Shared Infrastructure                           │ │
│  │  • Prisma ORM  • Redis Cache  • Bull Queue  • Socket.io Gateway       │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DATA LAYER                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐    │
│  │    PostgreSQL      │  │       Redis        │  │    S3 / MinIO      │    │
│  │    (Main DB)       │  │  (Cache + Queue)   │  │     (Files)        │    │
│  └────────────────────┘  └────────────────────┘  └────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          EXTERNAL SERVICES                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ │
│  │  Firebase  │ │   VNPay    │ │   Twilio   │ │  eKYC API  │ │Google Maps │ │
│  │   (FCM)    │ │   MoMo     │ │  Stringee  │ │ (Identity) │ │   (GPS)    │ │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘ └────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Phase 2: Microservices (Scale - When Needed)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────┐              ┌──────────────────────────┐ │
│  │        Flutter App           │              │      Flutter Web         │ │
│  │     (User + Partner)         │              │     (Admin Panel)        │ │
│  └──────────────────────────────┘              └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           API GATEWAY (Kong)                                 │
│       • Rate Limiting  • Authentication  • Load Balancing  • SSL/TLS        │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        MICROSERVICES (NestJS)                                │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ │
│  │   Auth     │ │   User     │ │  Partner   │ │  Booking   │ │   Chat     │ │
│  │  Service   │ │  Service   │ │  Service   │ │  Service   │ │  Service   │ │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘ └────────────┘ │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ │
│  │  Payment   │ │   Safety   │ │   Rating   │ │   Search   │ │Notification│ │
│  │  Service   │ │  Service   │ │  Service   │ │  Service   │ │  Service   │ │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘ └────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                      ┌───────────────┼───────────────┐
                      ▼               ▼               ▼
              ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
              │ PostgreSQL  │ │   Redis     │ │Elasticsearch│
              │  Cluster    │ │   Cluster   │ │   Cluster   │
              └─────────────┘ └─────────────┘ └─────────────┘
```

---

## 📁 Project Structure

### Flutter App Structure

```
mate_social_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/                          # Core utilities
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── api_endpoints.dart
│   │   │   └── storage_keys.dart
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── network/
│   │   │   ├── dio_client.dart
│   │   │   ├── api_interceptor.dart
│   │   │   └── network_info.dart
│   │   ├── utils/
│   │   │   ├── validators.dart
│   │   │   ├── formatters.dart
│   │   │   └── helpers.dart
│   │   └── theme/
│   │       ├── app_theme.dart
│   │       ├── app_colors.dart
│   │       └── app_typography.dart
│   │
│   ├── config/                        # App configuration
│   │   ├── routes/
│   │   │   ├── app_router.dart
│   │   │   └── route_names.dart
│   │   ├── injection/
│   │   │   ├── injection.dart
│   │   │   └── injection.config.dart
│   │   └── env/
│   │       └── env_config.dart
│   │
│   ├── features/                      # Feature modules
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   │   └── auth_local_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── user_model.dart
│   │   │   │   │   └── token_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── user.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── login_usecase.dart
│   │   │   │       ├── register_usecase.dart
│   │   │   │       └── logout_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── auth_bloc.dart
│   │   │       │   ├── auth_event.dart
│   │   │       │   └── auth_state.dart
│   │   │       ├── pages/
│   │   │       │   ├── login_page.dart
│   │   │       │   ├── register_page.dart
│   │   │       │   └── otp_verification_page.dart
│   │   │       └── widgets/
│   │   │           └── auth_form.dart
│   │   │
│   │   ├── user/                      # User profile module
│   │   ├── partner/                   # Partner module
│   │   ├── search/                    # Search & discovery
│   │   ├── booking/                   # Booking flow
│   │   ├── chat/                      # Real-time chat
│   │   ├── payment/                   # Wallet & payments
│   │   ├── rating/                    # Reviews & ratings
│   │   ├── kyc/                       # KYC verification
│   │   ├── safety/                    # SOS & safety
│   │   └── notification/              # Push notifications
│   │
│   └── shared/                        # Shared components
│       ├── widgets/
│       │   ├── buttons/
│       │   ├── inputs/
│       │   ├── cards/
│       │   ├── dialogs/
│       │   └── loading/
│       ├── extensions/
│       └── mixins/
│
├── assets/
│   ├── images/
│   ├── icons/
│   ├── fonts/
│   └── animations/
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
└── pubspec.yaml
```

### NestJS Backend Structure

```
mate_social_api/
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   │
│   ├── common/                        # Shared utilities
│   │   ├── decorators/
│   │   │   ├── current-user.decorator.ts
│   │   │   ├── roles.decorator.ts
│   │   │   └── public.decorator.ts
│   │   ├── guards/
│   │   │   ├── jwt-auth.guard.ts
│   │   │   ├── roles.guard.ts
│   │   │   └── throttle.guard.ts
│   │   ├── interceptors/
│   │   │   ├── transform.interceptor.ts
│   │   │   ├── logging.interceptor.ts
│   │   │   └── timeout.interceptor.ts
│   │   ├── filters/
│   │   │   ├── http-exception.filter.ts
│   │   │   └── prisma-exception.filter.ts
│   │   ├── pipes/
│   │   │   └── validation.pipe.ts
│   │   ├── dto/
│   │   │   ├── pagination.dto.ts
│   │   │   └── api-response.dto.ts
│   │   └── utils/
│   │       ├── hash.util.ts
│   │       ├── token.util.ts
│   │       └── date.util.ts
│   │
│   ├── config/                        # Configuration
│   │   ├── app.config.ts
│   │   ├── database.config.ts
│   │   ├── jwt.config.ts
│   │   ├── redis.config.ts
│   │   └── s3.config.ts
│   │
│   ├── modules/                       # Feature modules
│   │   ├── auth/
│   │   │   ├── auth.module.ts
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── strategies/
│   │   │   │   ├── jwt.strategy.ts
│   │   │   │   └── refresh-token.strategy.ts
│   │   │   └── dto/
│   │   │       ├── login.dto.ts
│   │   │       ├── register.dto.ts
│   │   │       └── tokens.dto.ts
│   │   │
│   │   ├── user/
│   │   │   ├── user.module.ts
│   │   │   ├── user.controller.ts
│   │   │   ├── user.service.ts
│   │   │   ├── dto/
│   │   │   │   ├── create-user.dto.ts
│   │   │   │   └── update-user.dto.ts
│   │   │   └── entities/
│   │   │       └── user.entity.ts
│   │   │
│   │   ├── partner/                   # Partner management
│   │   ├── booking/                   # Booking system
│   │   ├── chat/                      # Real-time chat (WebSocket)
│   │   ├── payment/                   # Payment & wallet
│   │   ├── search/                    # Search service
│   │   ├── rating/                    # Rating & reviews
│   │   ├── kyc/                       # KYC verification
│   │   ├── safety/                    # SOS & emergency
│   │   ├── blacklist/                 # Blacklist management
│   │   ├── notification/              # Push notifications
│   │   └── upload/                    # File upload
│   │
│   ├── database/                      # Database
│   │   └── prisma/
│   │       ├── prisma.module.ts
│   │       ├── prisma.service.ts
│   │       └── migrations/
│   │
│   ├── cache/                         # Redis cache
│   │   ├── cache.module.ts
│   │   └── cache.service.ts
│   │
│   ├── queue/                         # Bull queue
│   │   ├── queue.module.ts
│   │   └── processors/
│   │       ├── email.processor.ts
│   │       ├── notification.processor.ts
│   │       └── escrow.processor.ts
│   │
│   └── websocket/                     # WebSocket gateway
│       ├── websocket.module.ts
│       ├── websocket.gateway.ts
│       └── websocket.adapter.ts
│
├── prisma/
│   ├── schema.prisma
│   ├── seed.ts
│   └── migrations/
│
├── test/
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── docker-compose.yml
├── Dockerfile
├── .env.example
├── nest-cli.json
├── tsconfig.json
└── package.json
```

---

## 📊 Database Schema (Prisma)

### Prisma Schema

```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ==================== ENUMS ====================

enum UserRole {
  USER
  PARTNER
  ADMIN
}

enum UserStatus {
  PENDING
  ACTIVE
  SUSPENDED
  BANNED
}

enum KycStatus {
  NONE
  PENDING
  VERIFIED
  REJECTED
}

enum Gender {
  MALE
  FEMALE
  OTHER
}

enum BookingStatus {
  PENDING
  CONFIRMED
  PAID
  IN_PROGRESS
  COMPLETED
  CANCELLED
  DISPUTED
}

enum TransactionType {
  DEPOSIT
  WITHDRAWAL
  ESCROW_HOLD
  ESCROW_RELEASE
  ESCROW_REFUND
  SERVICE_FEE
}

enum TransactionStatus {
  PENDING
  PROCESSING
  COMPLETED
  FAILED
  REFUNDED
}

enum EscrowStatus {
  HELD
  RELEASED
  REFUNDED
  DISPUTED
}

enum MessageType {
  TEXT
  IMAGE
  VOICE
  LOCATION
  SYSTEM
}

enum SosStatus {
  TRIGGERED
  RESPONDING
  RESOLVED
  FALSE_ALARM
}

// ==================== MODELS ====================

// Users
model User {
  id           String     @id @default(uuid())
  email        String     @unique
  phone        String?    @unique
  passwordHash String     @map("password_hash")
  role         UserRole   @default(USER)
  status       UserStatus @default(PENDING)
  kycStatus    KycStatus  @default(NONE) @map("kyc_status")
  
  createdAt    DateTime   @default(now()) @map("created_at")
  updatedAt    DateTime   @updatedAt @map("updated_at")
  
  // Relations
  profile           Profile?
  partnerProfile    PartnerProfile?
  kycVerification   KycVerification?
  wallet            Wallet?
  
  bookingsAsUser    Booking[]     @relation("UserBookings")
  bookingsAsPartner Booking[]     @relation("PartnerBookings")
  
  reviewsGiven      Review[]      @relation("ReviewsGiven")
  reviewsReceived   Review[]      @relation("ReviewsReceived")
  
  conversations     ConversationParticipant[]
  messagesSent      Message[]
  
  blockedUsers      UserBlacklist[] @relation("BlockerUser")
  blockedByUsers    UserBlacklist[] @relation("BlockedUser")
  
  emergencyContacts EmergencyContact[]
  sosEvents         SosEvent[]
  
  refreshTokens     RefreshToken[]
  
  @@map("users")
}

// Profiles
model Profile {
  id            String   @id @default(uuid())
  userId        String   @unique @map("user_id")
  user          User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  fullName      String   @map("full_name")
  displayName   String?  @map("display_name")
  avatarUrl     String?  @map("avatar_url")
  coverPhotoUrl String?  @map("cover_photo_url")
  bio           String?
  
  gender        Gender?
  dateOfBirth   DateTime? @map("date_of_birth")
  heightCm      Int?     @map("height_cm")
  weightKg      Int?     @map("weight_kg")
  
  // Location
  currentLat    Decimal? @map("current_lat") @db.Decimal(10, 8)
  currentLng    Decimal? @map("current_lng") @db.Decimal(11, 8)
  city          String?
  district      String?
  
  // JSON fields
  languages     Json?    @default("[]") // ["Vietnamese", "English"]
  interests     Json?    @default("[]") // ["movies", "travel"]
  talents       Json?    @default("[]") // ["singing", "dancing"]
  
  createdAt     DateTime @default(now()) @map("created_at")
  updatedAt     DateTime @updatedAt @map("updated_at")
  
  @@map("profiles")
}

// Partner Profiles
model PartnerProfile {
  id               String   @id @default(uuid())
  userId           String   @unique @map("user_id")
  user             User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  hourlyRate       Decimal  @map("hourly_rate") @db.Decimal(10, 2)
  minimumHours     Int      @default(3) @map("minimum_hours")
  
  serviceTypes     Json     @default("[]") @map("service_types") // ["walking", "movie", "party"]
  
  // Stats
  totalBookings     Int     @default(0) @map("total_bookings")
  completedBookings Int     @default(0) @map("completed_bookings")
  averageRating     Decimal @default(0) @map("average_rating") @db.Decimal(3, 2)
  totalReviews      Int     @default(0) @map("total_reviews")
  
  // Verification
  isVerified        Boolean @default(false) @map("is_verified")
  verificationBadge String? @map("verification_badge")
  
  // Status
  isAvailable       Boolean  @default(true) @map("is_available")
  lastActiveAt      DateTime? @map("last_active_at")
  
  createdAt         DateTime @default(now()) @map("created_at")
  updatedAt         DateTime @updatedAt @map("updated_at")
  
  // Relations
  availabilitySlots AvailabilitySlot[]
  
  @@map("partner_profiles")
}

// Availability Slots
model AvailabilitySlot {
  id          String   @id @default(uuid())
  partnerId   String   @map("partner_id")
  partner     PartnerProfile @relation(fields: [partnerId], references: [id], onDelete: Cascade)
  
  date        DateTime @db.Date
  startTime   DateTime @map("start_time") @db.Time()
  endTime     DateTime @map("end_time") @db.Time()
  
  status      String   @default("available") // available, booked, blocked
  bookingId   String?  @map("booking_id")
  
  createdAt   DateTime @default(now()) @map("created_at")
  
  @@unique([partnerId, date, startTime])
  @@map("availability_slots")
}

// KYC Verification
model KycVerification {
  id              String   @id @default(uuid())
  userId          String   @unique @map("user_id")
  user            User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  idCardFrontUrl  String?  @map("id_card_front_url")
  idCardBackUrl   String?  @map("id_card_back_url")
  idCardNumber    String?  @map("id_card_number")
  idCardName      String?  @map("id_card_name")
  idCardDob       DateTime? @map("id_card_dob")
  
  videoUrl        String?  @map("video_url")
  
  status          String   @default("pending") // pending, processing, verified, rejected
  rejectionReason String?  @map("rejection_reason")
  
  livenessScore   Decimal? @map("liveness_score") @db.Decimal(5, 4)
  faceMatchScore  Decimal? @map("face_match_score") @db.Decimal(5, 4)
  
  verifiedAt      DateTime? @map("verified_at")
  verifiedBy      String?  @map("verified_by")
  
  createdAt       DateTime @default(now()) @map("created_at")
  updatedAt       DateTime @updatedAt @map("updated_at")
  
  @@map("kyc_verifications")
}

// Bookings
model Booking {
  id            String        @id @default(uuid())
  bookingCode   String        @unique @map("booking_code")
  
  userId        String        @map("user_id")
  user          User          @relation("UserBookings", fields: [userId], references: [id])
  
  partnerId     String        @map("partner_id")
  partner       User          @relation("PartnerBookings", fields: [partnerId], references: [id])
  
  serviceType   String        @map("service_type")
  date          DateTime      @db.Date
  startTime     DateTime      @map("start_time") @db.Time()
  endTime       DateTime      @map("end_time") @db.Time()
  durationHours Decimal       @map("duration_hours") @db.Decimal(4, 2)
  
  // Location
  meetingLocation String?     @map("meeting_location")
  meetingLat      Decimal?    @map("meeting_lat") @db.Decimal(10, 8)
  meetingLng      Decimal?    @map("meeting_lng") @db.Decimal(11, 8)
  
  // Pricing
  hourlyRate      Decimal     @map("hourly_rate") @db.Decimal(10, 2)
  totalHours      Decimal     @map("total_hours") @db.Decimal(4, 2)
  subtotal        Decimal     @db.Decimal(12, 2)
  serviceFee      Decimal     @map("service_fee") @db.Decimal(12, 2)
  totalAmount     Decimal     @map("total_amount") @db.Decimal(12, 2)
  
  status          BookingStatus @default(PENDING)
  
  userNote        String?     @map("user_note")
  partnerNote     String?     @map("partner_note")
  cancellationReason String?  @map("cancellation_reason")
  cancelledBy     String?     @map("cancelled_by")
  
  createdAt       DateTime    @default(now()) @map("created_at")
  updatedAt       DateTime    @updatedAt @map("updated_at")
  confirmedAt     DateTime?   @map("confirmed_at")
  startedAt       DateTime?   @map("started_at")
  completedAt     DateTime?   @map("completed_at")
  
  // Relations
  statusHistory   BookingStatusHistory[]
  escrow          EscrowHolding?
  reviews         Review[]
  conversation    Conversation?
  sosEvents       SosEvent[]
  
  @@map("bookings")
}

// Booking Status History
model BookingStatusHistory {
  id          String   @id @default(uuid())
  bookingId   String   @map("booking_id")
  booking     Booking  @relation(fields: [bookingId], references: [id], onDelete: Cascade)
  
  fromStatus  String?  @map("from_status")
  toStatus    String   @map("to_status")
  changedBy   String?  @map("changed_by")
  reason      String?
  
  createdAt   DateTime @default(now()) @map("created_at")
  
  @@map("booking_status_history")
}

// Wallet
model Wallet {
  id             String   @id @default(uuid())
  userId         String   @unique @map("user_id")
  user           User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  balance        Decimal  @default(0) @db.Decimal(15, 2)
  pendingBalance Decimal  @default(0) @map("pending_balance") @db.Decimal(15, 2)
  currency       String   @default("VND")
  
  createdAt      DateTime @default(now()) @map("created_at")
  updatedAt      DateTime @updatedAt @map("updated_at")
  
  // Relations
  transactions   Transaction[]
  
  @@map("wallets")
}

// Transaction
model Transaction {
  id               String            @id @default(uuid())
  transactionCode  String            @unique @map("transaction_code")
  
  walletId         String            @map("wallet_id")
  wallet           Wallet            @relation(fields: [walletId], references: [id])
  
  bookingId        String?           @map("booking_id")
  
  type             TransactionType
  amount           Decimal           @db.Decimal(15, 2)
  fee              Decimal           @default(0) @db.Decimal(15, 2)
  
  status           TransactionStatus @default(PENDING)
  
  paymentMethod    String?           @map("payment_method") // vnpay, momo, bank_transfer
  externalTxId     String?           @map("external_transaction_id")
  
  description      String?
  metadata         Json?
  
  createdAt        DateTime          @default(now()) @map("created_at")
  completedAt      DateTime?         @map("completed_at")
  
  @@map("transactions")
}

// Escrow Holding
model EscrowHolding {
  id                  String       @id @default(uuid())
  bookingId           String       @unique @map("booking_id")
  booking             Booking      @relation(fields: [bookingId], references: [id], onDelete: Cascade)
  
  payerId             String       @map("payer_id")
  payeeId             String       @map("payee_id")
  
  amount              Decimal      @db.Decimal(15, 2)
  platformFee         Decimal      @map("platform_fee") @db.Decimal(15, 2)
  
  status              EscrowStatus @default(HELD)
  
  releaseScheduledAt  DateTime?    @map("release_scheduled_at")
  releasedAt          DateTime?    @map("released_at")
  
  createdAt           DateTime     @default(now()) @map("created_at")
  
  @@map("escrow_holdings")
}

// Conversations
model Conversation {
  id           String   @id @default(uuid())
  
  bookingId    String?  @unique @map("booking_id")
  booking      Booking? @relation(fields: [bookingId], references: [id])
  
  isPhoneHidden Boolean @default(true) @map("is_phone_hidden")
  status       String   @default("active") // active, archived, blocked
  
  createdAt    DateTime @default(now()) @map("created_at")
  updatedAt    DateTime @updatedAt @map("updated_at")
  
  // Relations
  participants ConversationParticipant[]
  messages     Message[]
  
  @@map("conversations")
}

// Conversation Participants
model ConversationParticipant {
  id             String       @id @default(uuid())
  conversationId String       @map("conversation_id")
  conversation   Conversation @relation(fields: [conversationId], references: [id], onDelete: Cascade)
  
  userId         String       @map("user_id")
  user           User         @relation(fields: [userId], references: [id])
  
  role           String       // user, partner
  joinedAt       DateTime     @default(now()) @map("joined_at")
  lastReadAt     DateTime?    @map("last_read_at")
  
  @@unique([conversationId, userId])
  @@map("conversation_participants")
}

// Messages
model Message {
  id             String       @id @default(uuid())
  conversationId String       @map("conversation_id")
  conversation   Conversation @relation(fields: [conversationId], references: [id], onDelete: Cascade)
  
  senderId       String       @map("sender_id")
  sender         User         @relation(fields: [senderId], references: [id])
  
  type           MessageType  @default(TEXT)
  content        String?
  
  mediaUrl       String?      @map("media_url")
  mediaType      String?      @map("media_type")
  
  // Location
  locationLat    Decimal?     @map("location_lat") @db.Decimal(10, 8)
  locationLng    Decimal?     @map("location_lng") @db.Decimal(11, 8)
  locationAddress String?     @map("location_address")
  
  status         String       @default("sent") // sent, delivered, read
  deliveredAt    DateTime?    @map("delivered_at")
  readAt         DateTime?    @map("read_at")
  
  isFlagged      Boolean      @default(false) @map("is_flagged")
  flaggedReason  String?      @map("flagged_reason")
  
  createdAt      DateTime     @default(now()) @map("created_at")
  
  @@map("messages")
}

// Reviews
model Review {
  id             String   @id @default(uuid())
  bookingId      String   @map("booking_id")
  booking        Booking  @relation(fields: [bookingId], references: [id], onDelete: Cascade)
  
  reviewerId     String   @map("reviewer_id")
  reviewer       User     @relation("ReviewsGiven", fields: [reviewerId], references: [id])
  
  revieweeId     String   @map("reviewee_id")
  reviewee       User     @relation("ReviewsReceived", fields: [revieweeId], references: [id])
  
  reviewType     String   @map("review_type") // user_to_partner, partner_to_user
  
  overallRating       Int  @map("overall_rating")
  punctualityRating   Int? @map("punctuality_rating")
  communicationRating Int? @map("communication_rating")
  attitudeRating      Int? @map("attitude_rating")
  appearanceRating    Int? @map("appearance_rating")
  serviceQualityRating Int? @map("service_quality_rating")
  
  comment        String?
  photoUrls      Json?    @default("[]") @map("photo_urls")
  
  isVisible      Boolean  @default(true) @map("is_visible")
  isFlagged      Boolean  @default(false) @map("is_flagged")
  
  createdAt      DateTime @default(now()) @map("created_at")
  updatedAt      DateTime @updatedAt @map("updated_at")
  
  // Relations
  response       ReviewResponse?
  
  @@unique([bookingId, reviewerId])
  @@map("reviews")
}

// Review Response
model ReviewResponse {
  id          String   @id @default(uuid())
  reviewId    String   @unique @map("review_id")
  review      Review   @relation(fields: [reviewId], references: [id], onDelete: Cascade)
  
  responderId String   @map("responder_id")
  response    String
  
  createdAt   DateTime @default(now()) @map("created_at")
  
  @@map("review_responses")
}

// User Blacklist
model UserBlacklist {
  id         String   @id @default(uuid())
  
  blockerId  String   @map("blocker_id")
  blocker    User     @relation("BlockerUser", fields: [blockerId], references: [id], onDelete: Cascade)
  
  blockedId  String   @map("blocked_id")
  blocked    User     @relation("BlockedUser", fields: [blockedId], references: [id], onDelete: Cascade)
  
  reason     String?
  
  createdAt  DateTime @default(now()) @map("created_at")
  
  @@unique([blockerId, blockedId])
  @@map("user_blacklist")
}

// System Blacklist
model SystemBlacklist {
  id            String    @id @default(uuid())
  userId        String    @map("user_id")
  
  reason        String
  blacklistedBy String    @map("blacklisted_by")
  
  isPermanent   Boolean   @default(false) @map("is_permanent")
  expiresAt     DateTime? @map("expires_at")
  
  createdAt     DateTime  @default(now()) @map("created_at")
  
  @@map("system_blacklist")
}

// Emergency Contacts
model EmergencyContact {
  id           String   @id @default(uuid())
  userId       String   @map("user_id")
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  name         String
  phone        String
  relationship String?
  isPrimary    Boolean  @default(false) @map("is_primary")
  
  createdAt    DateTime @default(now()) @map("created_at")
  
  @@map("emergency_contacts")
}

// SOS Events
model SosEvent {
  id            String    @id @default(uuid())
  
  userId        String    @map("user_id")
  user          User      @relation(fields: [userId], references: [id])
  
  bookingId     String?   @map("booking_id")
  booking       Booking?  @relation(fields: [bookingId], references: [id])
  
  latitude      Decimal   @db.Decimal(10, 8)
  longitude     Decimal   @db.Decimal(11, 8)
  address       String?
  
  status        SosStatus @default(TRIGGERED)
  
  respondedBy   String?   @map("responded_by")
  respondedAt   DateTime? @map("responded_at")
  resolutionNote String?  @map("resolution_note")
  
  notifiedContacts Json?  @map("notified_contacts")
  notifiedSupport Boolean @default(true) @map("notified_support")
  
  createdAt     DateTime  @default(now()) @map("created_at")
  resolvedAt    DateTime? @map("resolved_at")
  
  @@map("sos_events")
}

// Location Logs (for safety during booking)
model LocationLog {
  id         String   @id @default(uuid())
  userId     String   @map("user_id")
  bookingId  String   @map("booking_id")
  
  latitude   Decimal  @db.Decimal(10, 8)
  longitude  Decimal  @db.Decimal(11, 8)
  accuracy   Decimal? @db.Decimal(6, 2)
  
  recordedAt DateTime @default(now()) @map("recorded_at")
  
  @@index([bookingId, recordedAt])
  @@map("location_logs")
}

// Refresh Tokens
model RefreshToken {
  id           String   @id @default(uuid())
  userId       String   @map("user_id")
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  token        String   @unique
  deviceInfo   String?  @map("device_info")
  
  expiresAt    DateTime @map("expires_at")
  createdAt    DateTime @default(now()) @map("created_at")
  
  @@map("refresh_tokens")
}
```
---

## 🔍 Search & Discovery

### PostgreSQL Full-Text Search (MVP)

```sql
-- Add search columns
ALTER TABLE profiles ADD COLUMN search_vector tsvector;
ALTER TABLE partner_profiles ADD COLUMN search_vector tsvector;

-- Create search index
CREATE INDEX idx_profiles_search ON profiles USING GIN(search_vector);

-- Update search vector trigger
CREATE OR REPLACE FUNCTION update_profile_search_vector()
RETURNS trigger AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('simple', COALESCE(NEW.full_name, '')), 'A') ||
    setweight(to_tsvector('simple', COALESCE(NEW.display_name, '')), 'A') ||
    setweight(to_tsvector('simple', COALESCE(NEW.bio, '')), 'B') ||
    setweight(to_tsvector('simple', COALESCE(NEW.city, '')), 'C');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_search_update
  BEFORE INSERT OR UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_profile_search_vector();
```

### Search Query với GPS Radius

```typescript
// src/modules/search/search.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/database/prisma/prisma.service';

@Injectable()
export class SearchService {
  constructor(private prisma: PrismaService) {}

  async searchPartners(params: SearchPartnersDto) {
    const {
      lat,
      lng,
      radiusKm = 10,
      minRate,
      maxRate,
      serviceTypes,
      minRating,
      gender,
      blockedUserIds = [],
      page = 1,
      limit = 20,
    } = params;

    // Haversine formula for distance calculation
    const partners = await this.prisma.$queryRaw`
      SELECT 
        u.id,
        p.display_name,
        p.avatar_url,
        p.bio,
        p.city,
        pp.hourly_rate,
        pp.average_rating,
        pp.total_reviews,
        pp.completed_bookings,
        pp.is_verified,
        pp.service_types,
        (
          6371 * acos(
            cos(radians(${lat})) * cos(radians(p.current_lat)) *
            cos(radians(p.current_lng) - radians(${lng})) +
            sin(radians(${lat})) * sin(radians(p.current_lat))
          )
        ) AS distance_km
      FROM users u
      JOIN profiles p ON p.user_id = u.id
      JOIN partner_profiles pp ON pp.user_id = u.id
      WHERE 
        u.status = 'ACTIVE'
        AND u.kyc_status = 'VERIFIED'
        AND pp.is_available = true
        AND u.id NOT IN (${Prisma.join(blockedUserIds)})
        ${minRate ? Prisma.sql`AND pp.hourly_rate >= ${minRate}` : Prisma.empty}
        ${maxRate ? Prisma.sql`AND pp.hourly_rate <= ${maxRate}` : Prisma.empty}
        ${minRating ? Prisma.sql`AND pp.average_rating >= ${minRating}` : Prisma.empty}
        ${gender ? Prisma.sql`AND p.gender = ${gender}` : Prisma.empty}
      HAVING distance_km <= ${radiusKm}
      ORDER BY distance_km ASC, pp.average_rating DESC
      LIMIT ${limit}
      OFFSET ${(page - 1) * limit}
    `;

    return partners;
  }
}
```

---

## 💬 Real-time Chat Architecture (NestJS WebSocket)

```
┌─────────────────────────────────────────────────────────────────┐
│                     CHAT ARCHITECTURE                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────┐     ┌──────────────────┐     ┌──────────────┐   │
│   │  Flutter │────▶│    NestJS        │────▶│   Redis      │   │
│   │   App    │◀────│  WebSocket GW    │◀────│   Pub/Sub    │   │
│   └──────────┘     │  (Socket.io)     │     └──────────────┘   │
│                    └──────────────────┘            │            │
│                            │                       │            │
│                            ▼                       ▼            │
│                    ┌──────────────────┐    ┌──────────────┐    │
│                    │   Chat Module    │───▶│  PostgreSQL  │    │
│                    │    (NestJS)      │    │  (Messages)  │    │
│                    └──────────────────┘    └──────────────┘    │
│                            │                                    │
│                            ▼                                    │
│                    ┌──────────────────┐                        │
│                    │  Notification    │                        │
│                    │  Module (FCM)    │                        │
│                    └──────────────────┘                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### WebSocket Gateway

```typescript
// src/websocket/websocket.gateway.ts
import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UseGuards } from '@nestjs/common';
import { WsJwtGuard } from '@/common/guards/ws-jwt.guard';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
  namespace: '/chat',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(
    private chatService: ChatService,
    private redisService: RedisService,
  ) {}

  async handleConnection(client: Socket) {
    const userId = client.handshake.auth.userId;
    if (userId) {
      await this.redisService.setUserOnline(userId, client.id);
      client.join(`user:${userId}`);
    }
  }

  async handleDisconnect(client: Socket) {
    const userId = client.handshake.auth.userId;
    if (userId) {
      await this.redisService.setUserOffline(userId);
    }
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('join_conversation')
  async handleJoinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    client.join(`conversation:${data.conversationId}`);
    return { event: 'joined', data: { conversationId: data.conversationId } };
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: SendMessageDto,
  ) {
    const userId = client.handshake.auth.userId;
    
    // Save message to database
    const message = await this.chatService.createMessage({
      conversationId: data.conversationId,
      senderId: userId,
      type: data.type,
      content: data.content,
      mediaUrl: data.mediaUrl,
      location: data.location,
    });

    // Broadcast to conversation
    this.server
      .to(`conversation:${data.conversationId}`)
      .emit('new_message', message);

    // Send push notification to offline users
    await this.chatService.sendPushToOfflineUsers(
      data.conversationId,
      userId,
      message,
    );

    return { event: 'message_sent', data: message };
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('typing_start')
  async handleTypingStart(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const userId = client.handshake.auth.userId;
    client.to(`conversation:${data.conversationId}`).emit('user_typing', {
      conversationId: data.conversationId,
      userId,
    });
  }

  @UseGuards(WsJwtGuard)
  @SubscribeMessage('mark_read')
  async handleMarkRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; messageId: string },
  ) {
    const userId = client.handshake.auth.userId;
    
    await this.chatService.markAsRead(data.conversationId, userId, data.messageId);
    
    this.server.to(`conversation:${data.conversationId}`).emit('message_read', {
      messageId: data.messageId,
      userId,
      readAt: new Date(),
    });
  }
}
```

### Flutter Socket Client

```dart
// lib/features/chat/data/datasources/chat_socket_datasource.dart
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatSocketDataSource {
  late io.Socket _socket;
  final String baseUrl;
  final String accessToken;

  ChatSocketDataSource({required this.baseUrl, required this.accessToken});

  void connect() {
    _socket = io.io(
      '$baseUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .enableAutoConnect()
          .build(),
    );

    _socket.onConnect((_) {
      print('Connected to chat server');
    });

    _socket.onDisconnect((_) {
      print('Disconnected from chat server');
    });
  }

  void joinConversation(String conversationId) {
    _socket.emit('join_conversation', {'conversationId': conversationId});
  }

  void sendMessage(SendMessageDto message) {
    _socket.emit('send_message', message.toJson());
  }

  void startTyping(String conversationId) {
    _socket.emit('typing_start', {'conversationId': conversationId});
  }

  void markRead(String conversationId, String messageId) {
    _socket.emit('mark_read', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  Stream<Message> get onNewMessage {
    return _socket.on('new_message').map((data) => Message.fromJson(data));
  }

  Stream<TypingEvent> get onUserTyping {
    return _socket.on('user_typing').map((data) => TypingEvent.fromJson(data));
  }

  void disconnect() {
    _socket.disconnect();
  }
}
```

---

## 💰 Payment & Escrow Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         ESCROW PAYMENT FLOW                               │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  1. BOOKING CREATED                                                       │
│  ┌──────┐  Book Partner   ┌──────────┐  Create Booking  ┌──────────────┐ │
│  │ User │ ───────────────▶│ Booking  │ ────────────────▶│   Booking    │ │
│  │      │                 │  Module  │                  │Status:PENDING│ │
│  └──────┘                 └──────────┘                  └──────────────┘ │
│                                                                           │
│  2. PARTNER CONFIRMS                                                      │
│  ┌─────────┐  Accept      ┌──────────┐  Update Status   ┌──────────────┐ │
│  │ Partner │ ────────────▶│ Booking  │ ────────────────▶│   Booking    │ │
│  │         │              │  Module  │                  │Status:CONFIRM│ │
│  └─────────┘              └──────────┘                  └──────────────┘ │
│                                                                           │
│  3. USER PAYS (ESCROW HOLD)                                              │
│  ┌──────┐  Pay           ┌──────────┐  Hold Money      ┌──────────────┐ │
│  │ User │ ──────────────▶│ Payment  │ ────────────────▶│   Escrow     │ │
│  │      │  (VNPay/Momo)  │  Module  │                  │ Status: HELD │ │
│  └──────┘                └──────────┘                  └──────────────┘ │
│                                │                                         │
│                                ▼                                         │
│                         ┌──────────────┐                                │
│                         │   Booking    │                                │
│                         │ Status: PAID │                                │
│                         └──────────────┘                                │
│                                                                           │
│  4. BOOKING COMPLETED                                                    │
│  ┌──────┐  Complete      ┌──────────┐  Mark Complete   ┌──────────────┐ │
│  │ Both │ ──────────────▶│ Booking  │ ────────────────▶│   Booking    │ │
│  │Confirm│               │  Module  │                  │  COMPLETED   │ │
│  └──────┘                └──────────┘                  └──────────────┘ │
│                                                                           │
│  5. RELEASE AFTER 24H (Bull Queue Job)                                   │
│  ┌──────────┐  Scheduled  ┌──────────┐  Release        ┌──────────────┐ │
│  │  Bull    │ ───────────▶│ Payment  │ ───────────────▶│   Partner    │ │
│  │  Queue   │  (24h later)│  Module  │  Escrow         │   Wallet     │ │
│  └──────────┘             └──────────┘                 └──────────────┘ │
│                                                                           │
│  ※ DISPUTE FLOW (if any)                                                 │
│  ┌──────┐  Report Issue  ┌──────────┐  Hold Release    ┌──────────────┐ │
│  │ User │ ──────────────▶│ Support  │ ────────────────▶│   Escrow     │ │
│  │      │                │  Team    │  (Manual Review) │  DISPUTED    │ │
│  └──────┘                └──────────┘                  └──────────────┘ │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

### Payment Service Implementation

```typescript
// src/modules/payment/payment.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/database/prisma/prisma.service';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';

@Injectable()
export class PaymentService {
  constructor(
    private prisma: PrismaService,
    @InjectQueue('escrow') private escrowQueue: Queue,
  ) {}

  // Price Calculation (Quy tắc 3h)
  calculateBookingPrice(hourlyRate: number, requestedHours: number) {
    const MINIMUM_HOURS = 3;
    const PLATFORM_FEE_RATE = 0.15; // 15%
    
    const actualHours = Math.max(requestedHours, MINIMUM_HOURS);
    const subtotal = hourlyRate * actualHours;
    const serviceFee = subtotal * PLATFORM_FEE_RATE;
    const totalAmount = subtotal + serviceFee;
    
    return {
      hourlyRate,
      requestedHours,
      actualHours,
      subtotal,
      serviceFee,
      totalAmount,
      minimumApplied: requestedHours < MINIMUM_HOURS,
    };
  }

  // Create Escrow Hold
  async createEscrowHold(bookingId: string, payerId: string, payeeId: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) throw new NotFoundException('Booking not found');

    // Deduct from user wallet
    await this.prisma.wallet.update({
      where: { userId: payerId },
      data: {
        balance: { decrement: booking.totalAmount },
        pendingBalance: { increment: booking.totalAmount },
      },
    });

    // Create escrow record
    const escrow = await this.prisma.escrowHolding.create({
      data: {
        bookingId,
        payerId,
        payeeId,
        amount: booking.subtotal,
        platformFee: booking.serviceFee,
        status: 'HELD',
      },
    });

    // Create transaction record
    await this.prisma.transaction.create({
      data: {
        transactionCode: `TXN-${Date.now()}`,
        walletId: (await this.prisma.wallet.findUnique({ where: { userId: payerId } })).id,
        bookingId,
        type: 'ESCROW_HOLD',
        amount: booking.totalAmount,
        status: 'COMPLETED',
      },
    });

    return escrow;
  }

  // Schedule Escrow Release (24h after completion)
  async scheduleEscrowRelease(bookingId: string) {
    const RELEASE_DELAY_MS = 24 * 60 * 60 * 1000; // 24 hours
    
    await this.escrowQueue.add(
      'release-escrow',
      { bookingId },
      { delay: RELEASE_DELAY_MS },
    );

    await this.prisma.escrowHolding.update({
      where: { bookingId },
      data: {
        releaseScheduledAt: new Date(Date.now() + RELEASE_DELAY_MS),
      },
    });
  }

  // Release Escrow to Partner
  async releaseEscrow(bookingId: string) {
    const escrow = await this.prisma.escrowHolding.findUnique({
      where: { bookingId },
    });

    if (!escrow || escrow.status !== 'HELD') {
      throw new BadRequestException('Invalid escrow state');
    }

    // Transfer to partner wallet
    await this.prisma.$transaction([
      // Release from payer's pending balance
      this.prisma.wallet.update({
        where: { userId: escrow.payerId },
        data: {
          pendingBalance: { decrement: escrow.amount.add(escrow.platformFee) },
        },
      }),
      // Add to partner wallet
      this.prisma.wallet.update({
        where: { userId: escrow.payeeId },
        data: {
          balance: { increment: escrow.amount },
        },
      }),
      // Update escrow status
      this.prisma.escrowHolding.update({
        where: { bookingId },
        data: {
          status: 'RELEASED',
          releasedAt: new Date(),
        },
      }),
      // Create transaction for partner
      this.prisma.transaction.create({
        data: {
          transactionCode: `TXN-${Date.now()}`,
          walletId: (await this.prisma.wallet.findUnique({ where: { userId: escrow.payeeId } })).id,
          bookingId,
          type: 'ESCROW_RELEASE',
          amount: escrow.amount,
          status: 'COMPLETED',
        },
      }),
    ]);
  }
}
```

### Bull Queue Processor

```typescript
// src/queue/processors/escrow.processor.ts
import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { PaymentService } from '@/modules/payment/payment.service';

@Processor('escrow')
export class EscrowProcessor {
  constructor(private paymentService: PaymentService) {}

  @Process('release-escrow')
  async handleEscrowRelease(job: Job<{ bookingId: string }>) {
    const { bookingId } = job.data;
    
    try {
      await this.paymentService.releaseEscrow(bookingId);
      return { success: true };
    } catch (error) {
      throw error; // Bull will retry
    }
  }
}
```

---

## 🚨 Safety & SOS System

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          SOS EMERGENCY FLOW                               │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌──────────────┐                                                        │
│  │ Flutter App  │                                                        │
│  │  ┌────────┐  │                                                        │
│  │  │  SOS   │  │  1. Press & Hold 3s                                   │
│  │  │ Button │──┼─────────────────────────┐                             │
│  │  └────────┘  │                         │                             │
│  └──────────────┘                         ▼                             │
│                                   ┌──────────────┐                      │
│                                   │   Safety     │                      │
│                                   │   Module     │                      │
│                                   └──────────────┘                      │
│                                          │                               │
│                    ┌─────────────────────┼─────────────────────┐        │
│                    │                     │                     │        │
│                    ▼                     ▼                     ▼        │
│           ┌──────────────┐      ┌──────────────┐      ┌──────────────┐ │
│           │  Notify      │      │   Alert      │      │   Log        │ │
│           │  Emergency   │      │   Support    │      │   Location   │ │
│           │  Contacts    │      │   Center     │      │   & Event    │ │
│           └──────────────┘      └──────────────┘      └──────────────┘ │
│                    │                     │                     │        │
│                    ▼                     ▼                     ▼        │
│           ┌──────────────┐      ┌──────────────┐      ┌──────────────┐ │
│           │  SMS/Call    │      │  WebSocket   │      │  PostgreSQL  │ │
│           │  via Twilio  │      │   Alert      │      │   Record     │ │
│           └──────────────┘      └──────────────┘      └──────────────┘ │
│                                                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

### SOS Service Implementation

```typescript
// src/modules/safety/safety.service.ts
import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/database/prisma/prisma.service';
import { NotificationService } from '@/modules/notification/notification.service';
import { SmsService } from '@/modules/notification/sms.service';

@Injectable()
export class SafetyService {
  constructor(
    private prisma: PrismaService,
    private notificationService: NotificationService,
    private smsService: SmsService,
  ) {}

  async triggerSOS(userId: string, data: TriggerSosDto) {
    const { latitude, longitude, bookingId } = data;

    // Get user info
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: true,
        emergencyContacts: true,
      },
    });

    // Reverse geocode to get address
    const address = await this.getAddressFromCoords(latitude, longitude);

    // Create SOS event
    const sosEvent = await this.prisma.sosEvent.create({
      data: {
        userId,
        bookingId,
        latitude,
        longitude,
        address,
        status: 'TRIGGERED',
        notifiedSupport: true,
      },
    });

    // Get booking info if exists
    let partnerInfo = null;
    if (bookingId) {
      const booking = await this.prisma.booking.findUnique({
        where: { id: bookingId },
        include: {
          partner: { include: { profile: true } },
        },
      });
      partnerInfo = booking?.partner?.profile;
    }

    // Build SOS message
    const sosMessage = this.buildSosMessage({
      userName: user.profile.fullName,
      address,
      latitude,
      longitude,
      partnerName: partnerInfo?.fullName,
      timestamp: new Date(),
    });

    // Notify emergency contacts via SMS
    const notifiedContacts = [];
    for (const contact of user.emergencyContacts) {
      await this.smsService.sendSMS(contact.phone, sosMessage);
      notifiedContacts.push({
        name: contact.name,
        phone: contact.phone,
        notifiedAt: new Date(),
      });
    }

    // Update with notified contacts
    await this.prisma.sosEvent.update({
      where: { id: sosEvent.id },
      data: {
        notifiedContacts: notifiedContacts,
      },
    });

    // Alert support team via WebSocket
    await this.notificationService.alertSupportTeam(sosEvent);

    return sosEvent;
  }

  private buildSosMessage(data: {
    userName: string;
    address: string;
    latitude: number;
    longitude: number;
    partnerName?: string;
    timestamp: Date;
  }) {
    const mapsLink = `https://maps.google.com/?q=${data.latitude},${data.longitude}`;
    
    return `
🆘 KHẨN CẤP - MATE SOCIAL

${data.userName} cần trợ giúp!

📍 Vị trí: ${data.address}
🗺️ Bản đồ: ${mapsLink}
⏰ Thời gian: ${data.timestamp.toLocaleString('vi-VN')}
${data.partnerName ? `👤 Đang với: ${data.partnerName}` : ''}

Hotline hỗ trợ: 1900-xxxx
    `.trim();
  }

  async resolveSOS(sosId: string, adminId: string, note: string) {
    return this.prisma.sosEvent.update({
      where: { id: sosId },
      data: {
        status: 'RESOLVED',
        respondedBy: adminId,
        respondedAt: new Date(),
        resolutionNote: note,
        resolvedAt: new Date(),
      },
    });
  }
}
```

### Flutter SOS Widget

```dart
// lib/features/safety/presentation/widgets/sos_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

class SosButton extends StatefulWidget {
  final String? bookingId;
  
  const SosButton({super.key, this.bookingId});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> {
  bool _isLongPressing = false;
  double _progress = 0;
  
  static const _holdDuration = Duration(seconds: 3);

  void _startLongPress() {
    setState(() => _isLongPressing = true);
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!_isLongPressing) return false;
      
      setState(() {
        _progress += 0.05 / 3; // 3 seconds
      });
      
      if (_progress >= 1.0) {
        _triggerSOS();
        return false;
      }
      return true;
    });
  }

  void _cancelLongPress() {
    setState(() {
      _isLongPressing = false;
      _progress = 0;
    });
  }

  Future<void> _triggerSOS() async {
    // Get current location
    final position = await Geolocator.getCurrentPosition();
    
    // Trigger SOS via BLoC
    context.read<SafetyBloc>().add(
      TriggerSosEvent(
        latitude: position.latitude,
        longitude: position.longitude,
        bookingId: widget.bookingId,
      ),
    );

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🆘 Đã gửi tín hiệu khẩn cấp!'),
        backgroundColor: Colors.red,
      ),
    );
    
    _cancelLongPress();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startLongPress(),
      onLongPressEnd: (_) => _cancelLongPress(),
      onLongPressCancel: _cancelLongPress,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress circle
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 4,
              backgroundColor: Colors.red.shade100,
              valueColor: AlwaysStoppedAnimation(Colors.red),
            ),
          ),
          // SOS Button
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: _isLongPressing ? Colors.red.shade700 : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 📱 API Endpoints Design (NestJS Controllers)

### Authentication Module

```typescript
// src/modules/auth/auth.controller.ts
@ApiTags('Auth')
@Controller('api/v1/auth')
export class AuthController {
  @Post('register')           // Đăng ký tài khoản
  @Post('login')              // Đăng nhập
  @Post('refresh')            // Refresh token
  @Post('logout')             // Đăng xuất
  @Post('forgot-password')    // Quên mật khẩu
  @Post('verify-otp')         // Xác thực OTP
  @Post('resend-otp')         // Gửi lại OTP
}
```

### User Module

```typescript
// src/modules/user/user.controller.ts
@ApiTags('Users')
@Controller('api/v1/users')
@UseGuards(JwtAuthGuard)
export class UserController {
  @Get('me')                  // Lấy thông tin user hiện tại
  @Put('me')                  // Cập nhật profile
  @Put('me/location')         // Cập nhật vị trí
  @Put('me/password')         // Đổi mật khẩu
  @Get(':id')                 // Lấy thông tin user khác (public profile)
  @Delete('me')               // Xóa tài khoản
}
```

### KYC Module

```typescript
// src/modules/kyc/kyc.controller.ts
@ApiTags('KYC')
@Controller('api/v1/kyc')
@UseGuards(JwtAuthGuard)
export class KycController {
  @Post('upload-id-card')     // Upload CCCD
  @Post('upload-video')       // Upload video xác thực
  @Get('status')              // Kiểm tra trạng thái KYC
  @Post('submit')             // Submit KYC để review
}
```

### Partner Module

```typescript
// src/modules/partner/partner.controller.ts
@ApiTags('Partners')
@Controller('api/v1/partners')
@UseGuards(JwtAuthGuard)
export class PartnerController {
  @Post('register')           // Đăng ký làm Partner
  @Get('me')                  // Lấy profile Partner
  @Put('me')                  // Cập nhật profile Partner
  @Put('me/pricing')          // Cập nhật giá
  @Put('me/availability')     // Cập nhật trạng thái online
  @Get(':id')                 // Xem profile Partner (public)

  // Availability Slots
  @Get('me/slots')            // Lấy lịch rảnh
  @Post('me/slots')           // Tạo slot mới
  @Put('me/slots/:id')        // Cập nhật slot
  @Delete('me/slots/:id')     // Xóa slot
  @Post('me/slots/bulk')      // Tạo nhiều slot
}
```

### Search Module

```typescript
// src/modules/search/search.controller.ts
@ApiTags('Search')
@Controller('api/v1/search')
@UseGuards(JwtAuthGuard)
export class SearchController {
  @Post('partners')           // Tìm kiếm Partner với filters
  @Get('nearby')              // Tìm Partner gần đây
  @Get('suggestions')         // Gợi ý Partner
  @Get('trending')            // Partner trending
}
```

### Booking Module

```typescript
// src/modules/booking/booking.controller.ts
@ApiTags('Bookings')
@Controller('api/v1/bookings')
@UseGuards(JwtAuthGuard)
export class BookingController {
  @Post()                     // Tạo booking mới
  @Get()                      // Danh sách booking
  @Get(':id')                 // Chi tiết booking
  @Put(':id/confirm')         // Partner xác nhận (Partner only)
  @Put(':id/reject')          // Partner từ chối (Partner only)
  @Put(':id/cancel')          // Huỷ booking
  @Put(':id/start')           // Bắt đầu booking
  @Put(':id/complete')        // Hoàn thành booking
  @Post(':id/extend')         // Gia hạn thời gian
}
```

### Payment Module

```typescript
// src/modules/payment/payment.controller.ts
@ApiTags('Payments')
@Controller('api/v1')
@UseGuards(JwtAuthGuard)
export class PaymentController {
  // Wallet
  @Get('wallet')              // Lấy thông tin ví
  @Post('wallet/deposit')     // Nạp tiền
  @Post('wallet/withdraw')    // Rút tiền
  
  // Transactions
  @Get('transactions')        // Lịch sử giao dịch
  @Get('transactions/:id')    // Chi tiết giao dịch

  // Payments
  @Post('payments/pay')       // Thanh toán booking
  @Post('payments/callback/vnpay')   // Callback từ VNPay
  @Post('payments/callback/momo')    // Callback từ MoMo
}
```

### Chat Module

```typescript
// src/modules/chat/chat.controller.ts
@ApiTags('Chat')
@Controller('api/v1/conversations')
@UseGuards(JwtAuthGuard)
export class ChatController {
  @Get()                            // Danh sách hội thoại
  @Post()                           // Tạo hội thoại mới
  @Get(':id')                       // Chi tiết hội thoại
  @Get(':id/messages')              // Tin nhắn trong hội thoại
  @Post(':id/messages')             // Gửi tin nhắn (REST fallback)
  @Put(':id/read')                  // Đánh dấu đã đọc
  @Post(':id/media')                // Upload media trong chat
}
```

### Rating Module

```typescript
// src/modules/rating/rating.controller.ts
@ApiTags('Reviews')
@Controller('api/v1/reviews')
@UseGuards(JwtAuthGuard)
export class RatingController {
  @Post()                     // Tạo đánh giá
  @Get('user/:id')            // Đánh giá của user
  @Get('partner/:id')         // Đánh giá của partner
  @Post(':id/response')       // Phản hồi đánh giá
  @Put(':id/report')          // Báo cáo đánh giá vi phạm
}
```

### Safety Module

```typescript
// src/modules/safety/safety.controller.ts
@ApiTags('Safety')
@Controller('api/v1')
@UseGuards(JwtAuthGuard)
export class SafetyController {
  // SOS
  @Post('sos/trigger')              // Kích hoạt SOS
  @Put('sos/:id/resolve')           // Xử lý xong SOS (Admin)
  @Get('sos/history')               // Lịch sử SOS

  // Emergency Contacts
  @Get('emergency-contacts')        // Danh sách liên hệ khẩn cấp
  @Post('emergency-contacts')       // Thêm liên hệ khẩn cấp
  @Put('emergency-contacts/:id')    // Cập nhật liên hệ
  @Delete('emergency-contacts/:id') // Xóa liên hệ khẩn cấp

  // Location tracking
  @Post('location/update')          // Cập nhật vị trí (during booking)
}
```

### Blacklist Module

```typescript
// src/modules/blacklist/blacklist.controller.ts
@ApiTags('Blacklist')
@Controller('api/v1/blacklist')
@UseGuards(JwtAuthGuard)
export class BlacklistController {
  @Get()                      // Danh sách đã chặn
  @Post()                     // Chặn user
  @Delete(':userId')          // Bỏ chặn user
}
```

### Notification Module

```typescript
// src/modules/notification/notification.controller.ts
@ApiTags('Notifications')
@Controller('api/v1/notifications')
@UseGuards(JwtAuthGuard)
export class NotificationController {
  @Get()                      // Danh sách thông báo
  @Put(':id/read')            // Đánh dấu đã đọc
  @Put('read-all')            // Đánh dấu tất cả đã đọc
  @Delete(':id')              // Xóa thông báo
  @Put('settings')            // Cài đặt thông báo
  @Post('fcm-token')          // Đăng ký FCM token
}
```

### Upload Module

```typescript
// src/modules/upload/upload.controller.ts
@ApiTags('Upload')
@Controller('api/v1/upload')
@UseGuards(JwtAuthGuard)
export class UploadController {
  @Post('image')              // Upload ảnh
  @Post('video')              // Upload video
  @Post('avatar')             // Upload avatar
  @Post('kyc-document')       // Upload tài liệu KYC
  @Delete(':key')             // Xóa file
}
```

---

## 🔐 Security Implementation

### JWT Authentication (NestJS)

```typescript
// src/modules/auth/strategies/jwt.strategy.ts
import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get('JWT_SECRET'),
    });
  }

  async validate(payload: JwtPayload) {
    return {
      userId: payload.sub,
      email: payload.email,
      role: payload.role,
      kycVerified: payload.kycVerified,
    };
  }
}

// Token payload structure
interface JwtPayload {
  sub: string;          // user_id
  email: string;
  role: 'USER' | 'PARTNER' | 'ADMIN';
  kycVerified: boolean;
  iat: number;
  exp: number;
}

// Access Token: 15 minutes
// Refresh Token: 7 days (stored in HttpOnly Cookie)
```

### Rate Limiting

```typescript
// src/common/guards/throttle.guard.ts
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';

// app.module.ts
@Module({
  imports: [
    ThrottlerModule.forRoot([
      {
        name: 'short',
        ttl: 1000,   // 1 second
        limit: 3,    // 3 requests
      },
      {
        name: 'medium',
        ttl: 10000,  // 10 seconds
        limit: 20,   // 20 requests
      },
      {
        name: 'long',
        ttl: 60000,  // 1 minute
        limit: 100,  // 100 requests
      },
    ]),
  ],
})

// Custom rate limits for specific endpoints
@Throttle({ short: { limit: 5, ttl: 60000 } })  // Auth endpoints
@Throttle({ short: { limit: 3, ttl: 60000 } })  // SOS endpoint (prevent abuse)
```

### Data Privacy

```typescript
// Phone number masking in chat
function maskPhoneNumber(phone: string): string {
  return phone.replace(/(\d{3})\d{4}(\d{3})/, '$1****$2');
}

// Location privacy - only show distance, not exact location
function calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
  // Haversine formula
  const R = 6371; // Earth's radius in km
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
            Math.sin(dLng/2) * Math.sin(dLng/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}
```

---

## 📈 Caching Strategy (Redis)

```typescript
// src/cache/cache.service.ts
import { Injectable, Inject } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { Cache } from 'cache-manager';

@Injectable()
export class CacheService {
  constructor(@Inject(CACHE_MANAGER) private cacheManager: Cache) {}

  // User Session Cache - TTL: 30 minutes
  async setUserSession(userId: string, data: any) {
    await this.cacheManager.set(`session:${userId}`, data, 30 * 60 * 1000);
  }

  // Partner Profile Cache - TTL: 5 minutes
  async getPartnerProfile(partnerId: string) {
    const cacheKey = `partner:${partnerId}`;
    let profile = await this.cacheManager.get(cacheKey);
    
    if (!profile) {
      profile = await this.prisma.partnerProfile.findUnique({
        where: { userId: partnerId },
        include: { user: { include: { profile: true } } },
      });
      await this.cacheManager.set(cacheKey, profile, 5 * 60 * 1000);
    }
    
    return profile;
  }

  // Search Results Cache - TTL: 1 minute
  async cacheSearchResults(queryHash: string, results: any) {
    await this.cacheManager.set(`search:${queryHash}`, results, 60 * 1000);
  }

  // Availability Slots Cache - TTL: 30 seconds
  async getAvailabilitySlots(partnerId: string, date: string) {
    const cacheKey = `slots:${partnerId}:${date}`;
    return this.cacheManager.get(cacheKey);
  }

  // Invalidate cache on update
  async invalidatePartnerCache(partnerId: string) {
    await this.cacheManager.del(`partner:${partnerId}`);
  }
}
```

### Redis Configuration

```typescript
// src/cache/cache.module.ts
import { CacheModule } from '@nestjs/cache-manager';
import * as redisStore from 'cache-manager-redis-store';

@Module({
  imports: [
    CacheModule.register({
      store: redisStore,
      host: process.env.REDIS_HOST,
      port: process.env.REDIS_PORT,
      ttl: 60, // default TTL in seconds
    }),
  ],
})
export class AppCacheModule {}
```

---

## 🚀 Deployment Architecture

### Development Environment (Docker Compose)

```yaml
# docker-compose.yml
version: '3.8'

services:
  # NestJS API
  api:
    build:
      context: ./mate_social_api
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/mate_social
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      - postgres
      - redis
    volumes:
      - ./mate_social_api:/app
      - /app/node_modules

  # PostgreSQL
  postgres:
    image: postgres:15-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: mate_social
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data

  # Redis
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

  # MinIO (S3-compatible storage)
  minio:
    image: minio/minio
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data

  # Adminer (Database GUI)
  adminer:
    image: adminer
    ports:
      - "8080:8080"
    depends_on:
      - postgres

volumes:
  postgres_data:
  redis_data:
  minio_data:
```

### Production Deployment (AWS)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AWS PRODUCTION DEPLOYMENT                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        CloudFront CDN                                │   │
│  │              (Static assets, API caching, SSL/TLS)                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                      │                                      │
│                                      ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Application Load Balancer                         │   │
│  │                    (HTTPS termination, Health checks)               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                      │                                      │
│          ┌───────────────────────────┼───────────────────────────────┐     │
│          │                           │                           │         │
│          ▼                           ▼                           ▼         │
│  ┌───────────────┐          ┌───────────────┐          ┌───────────────┐  │
│  │   ECS Fargate │          │   ECS Fargate │          │   ECS Fargate │  │
│  │   (NestJS)    │          │   (NestJS)    │          │   (NestJS)    │  │
│  │   Zone A      │          │   Zone B      │          │   Zone C      │  │
│  └───────────────┘          └───────────────┘          └───────────────┘  │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         Data Layer                                   │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │   │
│  │  │   RDS    │  │ElastiCache│  │    S3    │  │   SES    │            │   │
│  │  │PostgreSQL│  │  Redis    │  │ (Files)  │  │ (Email)  │            │   │
│  │  │Multi-AZ  │  │  Cluster  │  │          │  │          │            │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Dockerfile for NestJS

```dockerfile
# mate_social_api/Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci
COPY . .
RUN npm run build
RUN npx prisma generate

FROM node:20-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/prisma ./prisma

EXPOSE 3000
CMD ["node", "dist/main.js"]
```

---

## 📊 Monitoring & Logging

```typescript
// src/common/interceptors/logging.interceptor.ts
import { Injectable, NestInterceptor, ExecutionContext, CallHandler, Logger } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url, ip, headers } = request;
    const userAgent = headers['user-agent'] || '';
    const now = Date.now();

    return next.handle().pipe(
      tap(() => {
        const response = context.switchToHttp().getResponse();
        const { statusCode } = response;
        const contentLength = response.get('content-length');
        
        this.logger.log(
          `${method} ${url} ${statusCode} ${contentLength} - ${userAgent} ${ip} +${Date.now() - now}ms`,
        );
      }),
    );
  }
}
```

### Health Check Endpoint

```typescript
// src/modules/health/health.controller.ts
import { Controller, Get } from '@nestjs/common';
import { HealthCheck, HealthCheckService, PrismaHealthIndicator, MemoryHealthIndicator } from '@nestjs/terminus';

@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private prisma: PrismaHealthIndicator,
    private memory: MemoryHealthIndicator,
  ) {}

  @Get()
  @HealthCheck()
  check() {
    return this.health.check([
      () => this.prisma.pingCheck('database'),
      () => this.memory.checkHeap('memory_heap', 150 * 1024 * 1024),
    ]);
  }
}
```

### Key Metrics

```yaml
key_metrics:
  business:
    - Daily Active Users (DAU)
    - Booking conversion rate
    - Average booking value
    - Partner utilization rate
    
  technical:
    - API response time (p50, p95, p99)
    - Error rate
    - Database query time
    - Cache hit rate
    
  safety:
    - SOS trigger count
    - Average response time
    - False alarm rate
```

---

## 📅 Development Phases

### Phase 1: MVP (8-10 tuần)

| Tuần | Module | Tasks |
|------|--------|-------|
| 1-2 | **Setup** | Project structure, Docker, CI/CD, Database schema |
| 3-4 | **Auth** | Register, Login, JWT, OTP, Forgot password |
| 5-6 | **User & Partner** | Profile CRUD, KYC upload, Partner registration |
| 7-8 | **Search & Booking** | GPS search, Filters, Create/Confirm booking |
| 9-10 | **Payment & Chat** | Wallet, Escrow, Basic real-time chat |

**MVP Deliverables:**
- [ ] User Registration & Login (Email/Phone + OTP)
- [ ] User Profile Management
- [ ] Partner Registration & Profile
- [ ] Basic KYC Upload (CCCD)
- [ ] GPS-based Partner Search
- [ ] Simple Booking Flow (Create → Confirm → Pay)
- [ ] Escrow Payment System
- [ ] Basic Real-time Chat
- [ ] Push Notifications

### Phase 2: Core Features (4-6 tuần)

| Tuần | Module | Tasks |
|------|--------|-------|
| 1-2 | **Availability** | Slot booking system, Calendar management |
| 3-4 | **Rating** | 2-way review system, Response feature |
| 5-6 | **Enhanced Search** | Advanced filters, Suggestions, Trending |

**Phase 2 Deliverables:**
- [ ] Availability Slot Management
- [ ] Rating & Review System (2-way)
- [ ] Blacklist Feature
- [ ] Advanced Search & Filters
- [ ] Partner Recommendations

### Phase 3: Safety & Enhancement (4-6 tuần)

| Tuần | Module | Tasks |
|------|--------|-------|
| 1-2 | **Safety** | SOS system, Emergency contacts, Location tracking |
| 3-4 | **Chat** | Media messages, Voice messages, Read receipts |
| 5-6 | **Admin** | Dashboard, KYC review, Reports |

**Phase 3 Deliverables:**
- [ ] SOS Emergency System
- [ ] Real-time Location Tracking (during booking)
- [ ] Enhanced Chat (Images, Voice, Location sharing)
- [ ] Admin Dashboard
- [ ] Analytics & Reporting

### Phase 4: Optimization (Ongoing)

- [ ] Performance Optimization
- [ ] Elasticsearch Integration (for scale)
- [ ] Machine Learning Recommendations
- [ ] Multi-language Support
- [ ] A/B Testing Framework

---

## 📝 Conclusion

### Tech Stack Summary

| Layer | Technology |
|-------|------------|
| **Mobile** | Flutter 3.x + BLoC |
| **Backend** | NestJS 10.x + Prisma |
| **Database** | PostgreSQL 15 |
| **Cache/Queue** | Redis 7 |
| **Storage** | AWS S3 / MinIO |
| **Real-time** | Socket.io |
| **Deployment** | Docker + ECS Fargate |

### Architecture Benefits

1. **Fast Development**: 
   - Flutter cho cả iOS + Android + Web từ 1 codebase
   - NestJS modular architecture dễ maintain và scale
   - Prisma ORM giúp type-safe và auto-migrations

2. **Scalability**: 
   - Monolith trước, tách Microservices khi cần
   - Redis caching giảm load database
   - Stateless API dễ horizontal scaling

3. **Security**: 
   - JWT + Refresh Token
   - KYC verification
   - Escrow payment protection
   - SOS emergency system

4. **Performance**: 
   - Redis caching
   - PostgreSQL với indexing tốt
   - CDN cho static assets
   - Connection pooling

5. **Developer Experience**:
   - TypeScript end-to-end
   - Hot reload cả Flutter và NestJS
   - Docker development environment
   - Swagger API documentation

### Cost Estimation (Monthly)

**MVP Phase (< 1,000 users):**
| Service | Cost |
|---------|------|
| ECS Fargate (1 task) | $30 |
| RDS PostgreSQL (db.t3.micro) | $15 |
| ElastiCache Redis (t3.micro) | $15 |
| S3 + CloudFront | $10 |
| **Total** | **~$70/month** |

**Growth Phase (10,000 users):**
| Service | Cost |
|---------|------|
| ECS Fargate (3 tasks) | $150 |
| RDS PostgreSQL (db.t3.medium, Multi-AZ) | $100 |
| ElastiCache Redis (t3.small) | $50 |
| S3 + CloudFront | $50 |
| Other (ALB, Route53, etc.) | $50 |
| **Total** | **~$400/month** |

---

## 📚 Quick Start Commands

### Backend Setup

```bash
# Clone và setup
cd mate_social_api
npm install

# Setup database
docker-compose up -d postgres redis
npx prisma migrate dev
npx prisma generate

# Run development
npm run start:dev

# API docs: http://localhost:3000/api/docs
```

### Flutter Setup

```bash
# Clone và setup
cd mate_social_app
flutter pub get

# Generate code
flutter pub run build_runner build

# Run development
flutter run
```

### Docker Development

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop all services
docker-compose down
```

---

**Document Version:** 2.0  
**Last Updated:** January 2026  
**Stack:** Flutter + NestJS + PostgreSQL + Redis
