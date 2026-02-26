# Test IAP (Premium) khi sản phẩm chưa duyệt trên App Store

Khi tạo app mới hoặc thêm gói Premium, sản phẩm In-App Purchase trên App Store Connect có thể **chưa được duyệt**. App gọi `queryProductDetails` sẽ nhận **product not found** → màn Premium báo "Không tìm thấy sản phẩm" và không mua được.

**Cách test mà không cần chờ duyệt:** dùng **StoreKit Configuration** trong Xcode. StoreKit sẽ trả về sản phẩm ảo local, không cần kết nối App Store thật.

---

## Bước 1: Product ID phải khớp

- Backend (subscription plans) trả về `appleProductId` cho từng gói (ví dụ `com.yourapp.premium.weekly`, `com.yourapp.premium.monthly`).
- File StoreKit Configuration **bắt buộc** dùng đúng các **product ID** này thì app mới query được và mua được.

Kiểm tra product ID hiện tại: gọi API `GET /subscriptions/plans` và xem field `appleProductId` của từng plan.

---

## Bước 2: Tạo / chỉnh file StoreKit Configuration

### Cách A: Dùng file mẫu trong repo

- Trong Xcode: **File → New → File…** → chọn **StoreKit Configuration File**.
- Đặt tên ví dụ `Configuration.storekit`, lưu vào thư mục `ios/` của project Flutter (để dễ tìm).
- Mở file `.storekit` trong Xcode, thêm **Subscription Group** (ví dụ tên "Premium"), sau đó thêm từng **Subscription** với:
  - **Product ID** = đúng `appleProductId` từ backend (ví dụ `com.yourapp.premium.weekly`).
  - **Reference Name**, **Price**, **Display Name** tùy bạn (chỉ để test).

### Cách B: Copy file mẫu có sẵn

- Trong repo có file mẫu `ios/Configuration.storekit` (nếu đã tạo).
- Mở bằng Xcode, sửa **Product ID** của từng subscription cho **khớp hệt** với `appleProductId` trong API plans.

---

## Bước 3: Bật StoreKit Configuration khi chạy app

1. Mở **ios/Runner.xcworkspace** bằng Xcode.
2. Menu **Product → Scheme → Edit Scheme…** (hoặc ⌘<).
3. Chọn **Run** ở cột trái → tab **Options**.
4. Mục **StoreKit Configuration** chọn file **Configuration.storekit** (hoặc tên file bạn tạo).
5. Đóng scheme, chạy app từ Xcode (**Run** hoặc ⌘R).

Khi chạy với Scheme này, StoreKit dùng file cấu hình local → app sẽ “thấy” các product và mua được mà **không cần** sản phẩm đã duyệt trên App Store.

---

## Bước 4: Test luồng mua

1. Chạy app từ Xcode (đã bật StoreKit Configuration như trên).
2. Vào màn **Premium** → chọn gói → bấm **Đăng ký ngay**.
3. StoreKit sẽ hiện hộp thoại thanh toán ảo (local).
4. Hoàn tất mua → app gửi receipt lên backend. **Lưu ý:** Backend verify receipt với Apple có thể **fail** nếu receipt từ StoreKit local (không phải sandbox thật). Để test full luồng verify, sau khi sản phẩm đã có trên App Store Connect (dù chưa duyệt), dùng **Sandbox Tester** và chạy app **không** chọn StoreKit Configuration (kết nối store thật).

---

## Trong app (đã làm sẵn)

- **Debug mode:** Khi không tìm thấy sản phẩm, SnackBar hiển thị **product ID** và gợi ý dùng StoreKit Configuration.
- **Debug mode:** Trên màn Premium, nếu có plans nhưng không fetch được sản phẩm từ store, có banner gợi ý dev bật StoreKit Configuration trong Xcode.

---

## Tóm tắt

| Mục | Nội dung |
|-----|----------|
| **Khi nào dùng** | Sản phẩm IAP chưa duyệt / chưa có trên App Store, cần test màn Premium và luồng mua trên máy/simulator. |
| **Điều kiện** | Product ID trong file .storekit **phải trùng** với `appleProductId` trong API `/subscriptions/plans`. |
| **Cách bật** | Xcode → Edit Scheme → Run → Options → StoreKit Configuration → chọn file .storekit. |
| **Chạy app** | Chạy từ Xcode (Run) để StoreKit Configuration có hiệu lực; chạy bằng `flutter run` không dùng được file .storekit. |

Sau khi sản phẩm đã được cấu hình và (nếu cần) duyệt trên App Store Connect, bạn có thể tắt StoreKit Configuration và test với Sandbox Tester như bình thường.
