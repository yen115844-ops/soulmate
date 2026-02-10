# Vietnam legal review checklist – Wallet & intermediary payment

Use this checklist to determine whether the current wallet/escrow model falls under regulated activities in Vietnam and what to do next. **This is not legal advice;** have a lawyer (banking / payment regulations) confirm.

References: **Nghị định 52/2024/ND-CP**, **Thông tư 40/2024/TT-NHNN** (effective from 01/10/2024).

---

## 1. Rà soát mô hình hiện tại

| Question | Your answer | Notes |
|----------|-------------|--------|
| App có **nhận tiền** từ user (nạp vào tài khoản/ví trên app) không? | [ ] Yes / [ ] No | Nếu Yes → có thể liên quan ví điện tử / trung gian thanh toán. |
| App có **giữ số dư** (balance) của user trên hệ thống không? | [ ] Yes / [ ] No | Nếu Yes → cần xem có bị coi là “phát hành ví” hoặc “giữ tiền” trung gian. |
| App có **chi trả** cho bên thứ ba (partner) hoặc **rút về** tài khoản ngân hàng user không? | [ ] Yes / [ ] No | Nếu Yes → luồng tiền có thể thuộc dịch vụ trung gian thanh toán. |
| Công ty có **giấy phép** trung gian thanh toán / ví điện tử do NHNN cấp không? | [ ] Yes / [ ] No | Nếu No và mô hình bị coi là ví/trung gian → cần xin phép hoặc dùng đối tác có phép. |

---

## 2. Xác định phạm vi pháp lý (nhờ luật sư xác nhận)

- [ ] **Phát hành ví điện tử:** Có đang “phát hành” ví (tạo ví, lưu số dư) cho khách hàng không? Nếu có, thường cần tổ chức được cấp phép (ngân hàng hoặc tổ chức trung gian thanh toán).
- [ ] **Dịch vụ trung gian thanh toán:** Có đang cung cấp dịch vụ thuộc danh mục trung gian thanh toán (ví dụ chuyển tiền, thu hộ/chi hộ, ví điện tử) không? Tham chiếu Nghị định 52/2024 và Thông tư 40/2024.
- [ ] **E-wallet linkage (Thông tư 40):** Ví điện tử phải liên kết với tài khoản thanh toán hoặc thẻ ghi nợ của **chính khách hàng**; cấm mua bán, cho thuê, cho mượn ví.

---

## 3. Hướng xử lý (chọn một hoặc kết hợp)

### Option A – Xin giấy phép

- [ ] Xác định loại giấy phép cần (trung gian thanh toán / ví điện tử theo quy định hiện hành).
- [ ] Đánh giá điều kiện vốn, hồ sơ, thời gian và chi phí.
- [ ] Lên kế hoạch nộp hồ sơ và bổ sung tài liệu theo hướng dẫn NHNN.

### Option B – Hợp tác đối tác có giấy phép

- [ ] Chọn đối tác (ngân hàng, ví điện tử đã được cấp phép).
- [ ] Thiết kế lại luồng: **tiền nạp/rút và escrow do đối tác xử lý**, app chỉ hiển thị số dư và gọi API đối tác (xem [PASS_THROUGH_ARCHITECTURE.md](PASS_THROUGH_ARCHITECTURE.md)).
- [ ] Ký hợp đồng và đảm bảo điều khoản tuân thủ Nghị định 52/2024, Thông tư 40/2024.

---

## 4. Hành động tiếp theo

1. **Gửi checklist + mô tả kỹ thuật** (wallet, escrow, nạp/rút) cho luật sư chuyên ngân hàng/thanh toán.
2. **Nhận kết luận:** (a) mô hình hiện tại có thuộc phạm vi “ví điện tử” / “trung gian thanh toán” không; (b) nếu có, cần giấy phép loại nào hoặc có thể “pass-through” qua đối tác.
3. **Cập nhật:** Nếu có giấy phép → ghi vào [APP_STORE_REVIEW_NOTES.md](APP_STORE_REVIEW_NOTES.md) khi nộp App Store. Nếu chuyển sang đối tác → triển khai theo [PASS_THROUGH_ARCHITECTURE.md](PASS_THROUGH_ARCHITECTURE.md).
