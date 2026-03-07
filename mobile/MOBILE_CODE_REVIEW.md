# Báo cáo rà soát code Mobile (Flutter) – Soulmate

Rà soát toàn bộ code mobile để tìm **code thừa**, **chưa đúng chuẩn** và **chức năng thiếu / cần hoàn thiện**.

**Cập nhật:** Các hạng mục ưu tiên cao và trung bình đã được xử lý (IAP gộp một service, TODO chức năng, PartnerCard đổi tên rõ ràng, xóa RevenueCat, thêm test).

---

## 1. Tổng quan cấu trúc

- **Kiến trúc**: Feature-first, mỗi feature có `data` / `domain` / `presentation` (BLoC + pages).
- **State**: `flutter_bloc`; DI bằng GetIt trong `core/di/injection.dart`.
- **Mạng**: Dio trong `api_client.dart`, refresh token khi 401, map lỗi qua `api_exceptions.dart`.
- **Định tuyến**: `go_router` với redirect theo auth/onboarding.

---

## 2. Code thừa / trùng lặp

### 2.1 Hai IAP Service (đã xử lý)

- **Đã gộp:** Một IAP duy nhất tại `core/services/iap_service.dart`, hỗ trợ cả consumable (credits) và non-consumable (subscription). Khởi tạo một lần trong `main.dart`, đăng ký GetIt `() => IAPService.instance`. Premium page dùng cùng instance, đặt callbacks khi mở trang. File `features/subscription/data/services/iap_service.dart` đã xóa.

### 2.2 Nhiều widget PartnerCard trùng tên

- `shared/widgets/cards/partner_card.dart` → `PartnerCard` (dùng ở favorites).
- `shared/widgets/cards/app_card.dart` → `PartnerCard` + `PartnerCardCompact`.
- `features/home/presentation/widgets/partner_card.dart` → `PartnerCard` (dùng ở home).

→ Ba chỗ định nghĩa “PartnerCard”, dễ nhầm và khó bảo trì.

**Đề xuất**: Chọn 1–2 widget chuẩn (ví dụ trong `shared/widgets/cards/`), dùng chung cho home và favorites; đổi tên hoặc xóa bản trùng.

### 2.3 Trùng logic thông báo lỗi (đã xử lý)

- Trước: `BaseRepositoryMixin.getErrorMessage()` và `error_utils.getErrorMessage()` gần giống nhau.
- Đã sửa: `BaseRepositoryMixin` gọi `error_utils.getErrorMessage()` để dùng một nguồn duy nhất.

---

## 3. Chưa đúng chuẩn / không nhất quán

### 3.1 Comment lỗi chính tả (đã sửa)

- `api_config.dart`: "deep linkingminlin" → đã đổi thành "deep linking".

### 3.2 TermsBloc không qua DI

- Terms/Privacy tạo `TermsBloc` trực tiếp trong page.
- Các BLoC khác đều đăng ký trong GetIt → không nhất quán nhưng chấp nhận được cho màn một lần.

### 3.3 Dependency không dùng

- `purchases_flutter` và `purchases_ui_flutter` (RevenueCat) có trong `pubspec.yaml` nhưng không thấy dùng trong `lib/`. Nếu không dùng → nên xóa để giảm kích thước và tránh nhầm lẫn.

---

## 4. Chức năng thiếu / cần hoàn thiện

### 4.1 TODO trong code

| File | Nội dung |
|------|----------|
| `api_client.dart` | Thay SHA-256 fingerprint bằng fingerprint thật của server (certificate pinning). |
| `api_config.dart` | Thay URL production/API và Web thật khi lên production. |
| `change_password_page.dart` | "Navigate to forgot password" – chưa có điều hướng tới quên mật khẩu. |
| `help_center_page.dart` | "Open in-app chat" – chưa mở chat trong app. |
| `partner_profile_page.dart` | "Preview public profile" – chưa xem trước profile công khai. |
| `profile_page.dart` | "Invite friends" – chưa triển khai mời bạn. |

Nên: hoặc implement từng mục, hoặc bỏ TODO và ghi rõ “out of scope” để tránh hiểu nhầm.

### 4.2 Hardcode / fallback

- `home_repository.dart`: `_kDefaultAvatarUrl = 'https://via.placeholder.com/400'` – nên dùng asset hoặc URL default thống nhất của app.
- Một số nơi fallback service categories “hardcoded” nếu backend chưa trả – nên ghi chú và sau này đồng bộ với API.

### 4.3 Localization

- `MaterialApp` có `supportedLocales: [vi, en, ko]` nhưng **không** dùng `flutter_localizations` / l10n / ARB.
- Toàn bộ chuỗi hiển thị đang hardcode (chủ yếu tiếng Việt) → app thực tế single-locale.
- Nếu sau này cần đa ngôn ngữ: thêm l10n (ARB + codegen), chuyển toàn bộ chuỗi UI vào file dịch, giữ vi là mặc định.

### 4.4 Test (đã bổ sung)

- **Đã thêm:** `test/core/utils/error_utils_test.dart` – unit test cho `getErrorMessage` (ApiException, NetworkException, Socket/Timeout/Format, unknown).  
- **Đã thêm:** `test/shared/widgets/cards/partner_card_test.dart` – widget test cho `PartnerCard` (build, hiển thị tên, badge online).  
- Vẫn nên bổ sung: unit test repository/BLoC, widget test cho auth/booking/chat khi cần.

---

## 5. Đã chỉnh trong lần rà soát này

1. **api_config.dart**: Sửa comment "deep linkingminlin" → "deep linking".
2. **base_repository.dart**: Bỏ trùng logic `getErrorMessage`; `BaseRepositoryMixin.getErrorMessage()` gọi `error_utils.getErrorMessage()`.
3. **injection.dart**: Thêm comment giải thích có hai IAP (core vs subscription) và đề xuất gộp một service.

---

## 6. Đề xuất ưu tiên

| Ưu tiên | Việc | Lý do |
|--------|------|--------|
| Cao | Gộp hai IAP thành một service, init một lần trong main | Tránh hai listener, dễ lỗi khi mua credits/premium. |
| Cao | Implement hoặc ghi rõ “chưa làm” cho các TODO (forgot password, help chat, preview profile, invite friends) | Tránh hành vi thiếu hoặc gây hiểu nhầm. |
| Trung bình | Gộp PartnerCard về 1–2 widget dùng chung | Dễ bảo trì, UI nhất quán. |
| Trung bình | Xóa `purchases_flutter` / `purchases_ui_flutter` nếu không dùng RevenueCat | Giảm dependency thừa. |
| Thấp | Thêm unit/widget test cho luồng chính | Ổn định khi refactor. |
| Thấp | Khi cần đa ngôn ngữ: thiết lập l10n và chuyển chuỗi ra file dịch | Chuẩn bị cho en/ko. |

Nếu bạn muốn, có thể bắt đầu từ mục “Gộp hai IAP” hoặc “Xử lý từng TODO” và tôi sẽ gợi ý chỉnh từng file cụ thể.
