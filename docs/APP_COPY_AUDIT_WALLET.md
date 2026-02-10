# App copy audit – Wallet (ví đa năng / đầu tư)

**Date:** As per plan implementation.  
**Purpose:** Ensure in-app and metadata copy do not imply "universal wallet" or "investment" (per App Store plan and Guideline 3.2.1(viii)).

---

## Result: No problematic wording found

- **Grep:** No occurrences of "ví đa năng", "đầu tư", "investment", or "universal wallet" in the mobile app codebase.
- **Wallet-related copy** is limited to: "Ví của tôi", "Nạp tiền", "Rút tiền", "Số dư hiện tại", "Có thể rút", "Đang giữ", and similar. None of these imply a general-purpose wallet or investment product.
- **Onboarding:** "Thanh toán an toàn qua ví điện tử. Tiền được giữ escrow đến khi hoàn thành dịch vụ." – Correctly ties wallet/escrow to **service completion**, not standalone finance.
- **Help center:** "Ví Mate Social", "Thanh toán & Ví", nạp/rút instructions – Neutral; no universal wallet or investment claims.

---

## Change made (per plan)

- **Wallet page** ([mobile/lib/features/wallet/presentation/pages/wallet_page.dart](mobile/lib/features/wallet/presentation/pages/wallet_page.dart)): Added a short line below the balance card: **"Số dư dùng để thanh toán đặt lịch trên nền tảng."** so it is explicit that the balance is for **booking payments** on the platform only.

---

## Metadata checklist (when submitting to App Store)

- [ ] App description: Do not use "ví đa năng", "đầu tư", or "universal wallet".
- [ ] Screenshots / previews: Same as above.
- [ ] In-app: Wallet screens now include the booking-payment disclaimer as above.
