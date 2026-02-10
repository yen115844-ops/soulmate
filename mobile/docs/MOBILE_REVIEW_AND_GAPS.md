# Đánh giá code mobile & những gì thiếu / cần bổ sung

**Cập nhật:** Các mục dưới đây đã được bổ sung hoàn thiện (auth redirect, DI, deep link, local notification tap, forgot/reset password, booking confirmation/payment, locale, error page, linter).

## 1. Kiến trúc & luồng tổng quan

- **Splash** → kiểm tra onboarding + đăng nhập → **Onboarding** / **Login** / **Home**
- **Auth**: Login, Register, OTP, Change Password, **Forgot Password, Reset Password**. Có refresh token, FCM đăng ký/hủy khi login/logout.
- **Router**: GoRouter, có route đầy đủ; **redirect (auth guard) đã bật** → bảo vệ route theo trạng thái đăng nhập.

---

## 2. Những gì đang thiếu hoặc cần bổ sung

### 2.1 Bảo vệ route (Auth redirect) ✅

- **Đã bổ sung**: Trong `app_router.dart`, `redirect` dùng AuthBloc từ GetIt. Chưa đăng nhập + không phải route công khai → login; đã đăng nhập + đang ở login/register → home. Route công khai gồm: splash, onboarding, login, register, otp, forgot-password, reset-password.

### 2.2 Dependency Injection không nhất quán ✅

- **Đã bổ sung**: SearchPage, CreateBookingPage, BookingDetailPage đều dùng `getIt<PartnerRepository>()`, `getIt<BookingRepository>()` (getter), không tự tạo ApiClient nữa.

### 2.3 Deep link ✅

- **Đã bổ sung**: `DeepLinkService._navigateToSafety()` đổi thành `router.push('/sos')`.

### 2.4 Tap vào local notification (foreground) ✅

- **Đã bổ sung**: Trong `App`, listen `LocalNotificationService.onNotificationTap`; khi tap, parse payload JSON và gọi `DeepLinkService().handleNotificationNavigation(data)`. Payload khi show local notification đã đổi sang `jsonEncode(message.data)` trong `PushNotificationService._onForegroundMessage`.

### 2.5 Route & trang chưa có ✅

- **Đã bổ sung**: ForgotPasswordPage, ResetPasswordPage (auth repository: requestForgotPassword, resetPassword); BookingConfirmationPage, BookingPaymentPage. Route và link từ Login "Quên mật khẩu?" → forgot password. Sau khi tạo booking thành công → navigate tới booking confirmation (bookingId, bookingCode).

### 2.6 Cấu hình API

- **Hai nơi định nghĩa endpoint**: `core/network/api_config.dart` (dùng bởi ApiClient) và `core/constants/api_endpoints.dart` (cấu trúc khác, có `apiVersion`). Dễ lệch khi đổi backend.
- **Cần**: Thống nhất dùng một nguồn (ví dụ `api_config.dart` + các class *Endpoints trong đó); hoặc bỏ `api_endpoints.dart` nếu không dùng, tránh nhầm lẫn.

### 2.7 Locale ✅

- **Đã bổ sung**: `localeResolutionCallback` ưu tiên match theo languageCode, mặc định `Locale('vi', 'VN')`. `supportedLocales` thêm `Locale('vi', 'VN')` đầu danh sách.

### 2.8 Error page của router ✅

- **Đã bổ sung**: errorBuilder kiểm tra auth; nếu đã đăng nhập → nút "Về trang chủ", chưa đăng nhập → nút "Về đăng nhập". Text "Không tìm thấy trang".

---

## 3. Những gì đã ổn

- Splash: Kiểm tra onboarding, login, user status (active/pending/suspended/banned) và điều hướng đúng.
- Auth: Login, register, OTP, refresh token, logout, FCM register/unregister trong AuthBloc.
- ApiClient: Interceptor 401 + refresh token, onAuthFailed, xử lý lỗi chuẩn.
- Các feature chính (Home, Bookings, Profile, Partner, Wallet, Chat, Notifications, Safety, KYC, Settings…) đã có route và trang; nhiều trang dùng Bloc + getIt đúng cách.
- Deep link từ FCM (background/terminated) đã dùng DeepLinkService; chỉ cần sửa safety path và bổ sung xử lý tap local notification (foreground).

---

## 4. Thứ tự ưu tiên đề xuất

1. **Cao**: Auth redirect trong router + dùng getIt cho SearchPage, CreateBookingPage, BookingDetailPage.
2. **Cao**: Sửa deep link safety `/safety` → `/sos`.
3. **Trung bình**: Listen tap local notification (foreground) + payload JSON cho DeepLink.
4. **Trung bình**: Forgot/Reset password (nếu product yêu cầu); Booking Confirmation/Payment (nếu có luồng riêng).
5. **Thấp**: Thống nhất API config; localeResolutionCallback; error page redirect theo auth.

Sau khi bổ sung các mục trên, luồng đăng nhập, bảo vệ route và trải nghiệm notification/deep link sẽ đồng bộ và an toàn hơn.

---

## 5. Logic trạng thái "online" (đã chỉnh)

- **Yêu cầu**: Online của một người dùng phải tính từ lúc đăng nhập (có hoạt động trong khoảng thời gian N phút).
- **Đã sửa**:
  - **Home** (`home_repository.dart`): `isOnline` không còn lấy từ `isAvailable` (toggle sẵn sàng của partner). Dùng **lastActiveAt** từ API: online = `lastActiveAt` trong vòng **15 phút** (`AppConstants.onlineThresholdMinutes`).
  - **Favorites** (`favorite_model.dart`): Cùng chuẩn: online = `lastActiveAt` trong vòng 15 phút (trước đây 5 phút).
  - Hằng số `AppConstants.onlineThresholdMinutes = 15` trong `core/constants/app_constants.dart`.
- **Lưu ý backend**: Cần cập nhật **lastActiveAt** khi user đăng nhập và khi có hoạt động (heartbeat/presence) để trạng thái "online" hiển thị đúng.
