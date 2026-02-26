# Apple App Store Review – Giải thích & Chiến lược xử lý

Tài liệu này giải thích từng issue Apple đưa ra và chiến lược (đã làm / cần làm) để pass review.

---

## 1. Guideline 3.1.2 – Business – Payments – Subscriptions

### Giải thích
App có gói auto-renewable subscription (Premium) nên **bắt buộc** phải:
- **Trong app**: Link hoạt động tới **Điều khoản sử dụng (EULA)** và **Chính sách bảo mật**, và thông tin gói (tên, thời hạn, giá). Có thể dùng `SubscriptionStoreView` (iOS) để gom đủ thông tin.
- **Trong App Store metadata**: Link tới Privacy Policy (trường Privacy Policy) và EULA (trong App Description hoặc EULA trong App Store Connect).

### Đã làm trong code
- **Premium page**: Nút "Điều khoản sử dụng (EULA)" và "Chính sách bảo mật" trong footer màn Premium đã được gắn `context.push(RouteNames.termsOfService)` và `context.push(RouteNames.privacyPolicy)` (trước đó `onPressed: () {}` nên không hoạt động).
- Trong app đã có màn Terms of Service và Privacy Policy (trong Profile/Cài đặt và khi đăng ký).

### Bạn cần làm thêm (metadata & nội dung)
1. **App Store Connect**  
   - Điền **Privacy Policy URL** (ví dụ: `https://gomate-cms.vercel.app/terms-of-service` hoặc URL chính sách bảo mật thực tế).  
   - Nếu dùng EULA tùy chỉnh: thêm trong mục EULA. Nếu dùng EULA mặc định của Apple: ghi rõ trong **App Description** link tới Điều khoản sử dụng (EULA).
2. Đảm bảo **Terms of Service / EULA** và **Privacy Policy** load đúng (API hoặc WebView) và link từ app mở được, không lỗi.

---

## 2. Guideline 5.1.1 – Legal – Privacy – Data Collection

### Giải thích
Apple yêu cầu **chỉ bắt buộc** thu thập thông tin **cần thiết cho chức năng cốt lõi**. Số điện thoại không thuộc nhóm đó với app dating/social nên **không được bắt buộc**.

### Đã làm trong code
- **Đăng ký**: Ô "Số điện thoại" đã chuyển thành **không bắt buộc** (bỏ validator "Vui lòng nhập số điện thoại"; vẫn validate định dạng nếu user có nhập).
- **RegisterRequest**: Chỉ gửi `phone` lên backend khi user có nhập (nếu để trống thì không gửi key `phone`).

### Backend
- Backend đã dùng `phone?: string` và `if (dto.phone)` nên không bắt buộc. Nếu có chỗ nào `phone` required trong DTO/validation thì cần sửa cho tương thích.

---

## 3. Guideline 2.3.10 – Performance – Accurate Metadata

### Giải thích
Trên App Store (iOS), metadata và nội dung trong app **không được** nhắc tới nền tảng khác (Google Play) vì không liên quan trải nghiệm trên iOS.

### Đã làm trong code
- **Trung tâm trợ giúp (Help Center)**: Hai câu hỏi về đăng ký/hủy Premium đã dùng **Platform.isIOS**:
  - **iOS**: Chỉ nói "App Store" / "Cài đặt > [Apple ID] > Đăng ký", **không** nhắc Google Play.
  - **Android**: Giữ nguyên "App Store hoặc Google Play" cho phù hợp.

### Bạn cần kiểm tra
- Tìm toàn bộ chỗ trong **binary iOS** (string, FAQ, màn hình) còn nhắc "Google Play" hoặc "play.google.com" và xóa/chỉ hiển thị trên Android.

---

## 4. Guideline 2.1 – Performance – App Completeness (IAP lỗi)

### Giải thích
Reviewer báo **lỗi khi mua gói VIP Premium** (ví dụ trên iPad Air 11-inch, iPadOS 26.3). IAP trong sandbox không cần duyệt sản phẩm trước, nhưng app phải mua được ổn định.

### Cần làm (không chỉ code, còn cấu hình)
1. **App Store Connect**
   - **Paid Apps Agreement**: Account Holder phải ký **Paid Apps Agreement** (Business).
   - **In-App Purchase**: Kiểm tra sản phẩm subscription (product id, pricing, availability) đã đủ và khớp với code (ví dụ `appleProductId` trong plans).
2. **Sandbox**
   - Tạo/lấy **Sandbox Tester** và test **trên thiết bị thật** (đặc biệt iPad) toàn bộ luồng: chọn gói → mua → hoàn tất / restore.
3. **Code**
   - Đảm bảo **chỉ dùng `appleProductId`** trên iOS (không dùng `googleProductId`).
   - Xử lý lỗi IAP rõ ràng (message người dùng, không crash).
   - Nếu dùng StoreKit 1 (in_app_purchase): kiểm tra **finishTransaction** và **completePurchase** đúng, tránh pending transaction gây lỗi lần sau.

Nếu sau khi làm đủ vẫn lỗi, có thể reply trong App Review với thông tin: thiết bị, bước thao tác, screenshot/screen record và mô tả đã test sandbox thế nào.

**Test IAP khi sản phẩm chưa duyệt:** Nếu gói Premium chưa được duyệt trên App Store Connect, app sẽ báo "Không tìm thấy sản phẩm". Để test local không cần chờ duyệt, dùng **StoreKit Configuration** trong Xcode: xem hướng dẫn chi tiết tại [docs/IAP_TEST_STOREKIT.md](IAP_TEST_STOREKIT.md). File mẫu `mobile/ios/Configuration.storekit` cần sửa các `productID` cho khớp với `appleProductId` trong API plans.

### In-App Purchase Key (Integrations) – Đã tạo key thì đúng chưa?
**Đúng.** Tạo key trong **App Store Connect → Users and Access → Integrations → In-App Purchase** là bước cần thiết để backend gọi **App Store Server API**. Key không hết hạn nhưng file .p8 chỉ tải được **một lần**.

**Backend đã tích hợp:** Xác minh Apple IAP dùng **nội dung key trong .env** (không dùng file .p8). Cấu hình trong `.env`:

- `APPLE_IAP_KEY_ID` = Key ID (từ App Store Connect)
- `APPLE_IAP_ISSUER_ID` = Issuer ID (trang Keys)
- `APPLE_IAP_PRIVATE_KEY` = **toàn bộ nội dung file .p8** (dán vào .env; dùng `\n` cho xuống dòng, ví dụ: `"-----BEGIN PRIVATE KEY-----\nMIGT...\n-----END PRIVATE KEY-----\n"`)
- `APPLE_BUNDLE_ID` = Bundle ID của app (ví dụ `com.yourapp.soulmate`)

Khi có `transactionId` (app gửi kèm) và đủ các biến trên, backend dùng **App Store Server API** (JWT ký bởi key). Nếu không có key hoặc không có transactionId, backend fallback sang **legacy verifyReceipt** (cần `APPLE_SHARED_SECRET`). App Flutter đã gửi kèm `purchaseID` làm `transactionId` khi verify.

---

## 5. Guideline 1.2 – Safety – User-Generated Content

### Giải thích
App có nội dung do người dùng tạo (tin nhắn, đánh giá, profile, v.v.) nên phải:
- **EULA/Điều khoản**: User phải đồng ý điều khoản, trong đó **nêu rõ không chấp nhận nội dung phản cảm và hành vi lạm dụng**.
- **Cơ chế báo cáo**: Có cách để user **báo cáo (flag) nội dung phản cảm**.

### Đã có trong app
- Đăng ký đã có checkbox đồng ý Điều khoản sử dụng & Chính sách bảo mật.
- Trong **Booking detail** đã có mục "Báo cáo".
- Help Center mô tả: "Vào trang hồ sơ người dùng > ... > Chọn Báo cáo".

### Cần làm
1. **Nội dung EULA/Terms**
   - Backend đã có **nội dung mặc định** trong `settings.service.ts` (mục 6 – Nội dung do người dùng tạo và hành vi không chấp nhận). Nếu bạn chưa lưu nội dung tùy chỉnh trong CMS, API sẽ trả về bản mặc định này (đã đủ theo Guideline 1.2).
   - Nếu bạn **đã chỉnh Điều khoản sử dụng** trong CMS: vào **CMS → Điều khoản & Điều kiện → tab Điều khoản sử dụng**, thêm một mục tương tự nội dung dưới đây (có thể copy/paste và sửa tên app nếu cần):

   **Đoạn cần có trong Điều khoản sử dụng (EULA):**
   ```markdown
   ## Nội dung do người dùng tạo và hành vi không chấp nhận
   Ứng dụng cho phép người dùng tạo và chia sẻ nội dung (tin nhắn, đánh giá, ảnh, thông tin hồ sơ). Chúng tôi **không dung thứ** mọi nội dung phản cảm, xúc phạm, bạo lực, kỳ thị, quấy rối hoặc vi phạm pháp luật, cũng như mọi hành vi lạm dụng, lừa đảo hoặc gây hại cho người khác.
   - Vi phạm có thể dẫn đến **cảnh cáo, tạm khóa tài khoản hoặc khóa vĩnh viễn** và có thể bị báo cáo cơ quan chức năng khi cần.
   - Nếu bạn phát hiện nội dung/hành vi vi phạm, vui lòng dùng tính năng **Báo cáo** trong app hoặc liên hệ hỗ trợ. Chúng tôi sẽ xem xét và xử lý.
   ```
2. **Cơ chế báo cáo**
   - Đảm bảo **màn hồ sơ partner/người dùng** có nút/menu **Báo cáo** (report user/content), gửi lý do + mô tả lên backend và có phản hồi (ví dụ "Đã gửi báo cáo").
   - Nếu hiện chỉ có "Báo cáo" trong booking: bổ sung báo cáo từ **trang profile/partner** (nơi user xem nội dung người khác) để đủ "mechanism to flag objectionable content".

---

## 6. Guideline 1.5 – Safety (Support URL)

### Giải thích
**Support URL** trong App Store Connect (`https://gomate-cms.vercel.app/support`) phải dẫn tới **một trang web thực sự có thông tin hỗ trợ** (cách liên hệ, câu hỏi thường gặp, v.v.). Reviewer thấy trang không có nội dung hỗ trợ hoặc lỗi.

### Cần làm
1. **Trang support**
   - Mở `https://gomate-cms.vercel.app/support` khi **chưa đăng nhập** và kiểm tra:
     - Trang load được, không 404/500.
     - Luôn hiển thị ít nhất: email hỗ trợ (hoặc form liên hệ), có thể thêm FAQ hoặc link tới Trung tâm trợ giúp.
   - Trang CMS support hiện phụ thuộc API `supportApi.getPublic()`: nếu API lỗi hoặc trả về rỗng thì nội dung không hiện. Cần:
     - **Fallback**: Khi API lỗi/empty vẫn hiển thị **nội dung tĩnh** (email, link help, hoặc text "Liên hệ support: ...").
2. **App Store Connect**
   - Cập nhật **Support URL** nếu bạn đổi sang URL khác (ví dụ trang support chính thức khác) sao cho URL đó **luôn** có thông tin hỗ trợ rõ ràng.

---

## Tóm tắt checklist trước khi resubmit

| Guideline | Việc đã làm trong repo | Việc bạn cần làm (metadata / backend / CMS) |
|-----------|-------------------------|-----------------------------------------------|
| 3.1.2     | Link Điều khoản + Chính sách hoạt động trong màn Premium | Thêm link Privacy + EULA trong App Store Connect / App Description |
| 5.1.1     | Số điện thoại đăng ký không bắt buộc, chỉ gửi khi có nhập | Kiểm tra backend không require phone |
| 2.3.10    | Trên iOS, Help Center không nhắc Google Play | Rà soát toàn app (string, FAQ) còn chỗ nào nhắc Google Play |
| 2.1       | (Code IAP đã có) | Ký Paid Apps Agreement, cấu hình IAP đúng, test sandbox trên iPad |
| 1.2       | Có đồng ý EULA, có Báo cáo trong booking | EULA nêu rõ không dung thứ nội dung phản cảm; thêm Báo cáo trên profile/partner |
| 1.5       | — | Sửa trang support luôn có nội dung (fallback khi API lỗi), cập nhật Support URL nếu cần |

Sau khi hoàn tất các mục trên và test kỹ (đặc biệt IAP trên thiết bị thật), bạn có thể resubmit và nếu cần thì reply App Review với thông tin đã chỉnh (support URL, IAP đã test thế nào, v.v.).
