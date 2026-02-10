# App Store Review – FAQ and prepared answers

Use these when App Review asks follow-up questions about wallet, escrow, or payments. Keep answers short and consistent with [APP_STORE_REVIEW_NOTES.md](APP_STORE_REVIEW_NOTES.md).

---

## (a) Mô tả ngắn: Mô hình thanh toán và escrow

**English (for Notes / reply):**

- **What the app does:** Our app is a **booking marketplace** for **real-world services** (e.g. in-person sessions with tutors, coaches, consultants). Users discover partners, book a time slot, and pay for the service.
- **Payment:** Users can pay for a booking using their **in-app balance (wallet)**. The wallet can be topped up via card / bank transfer / third-party payment gateways. We do **not** use in-app purchase for these payments, because the service is consumed **outside the app** (Guideline 3.1.3(e)).
- **Escrow:** When a user pays for a booking, the amount is **held temporarily** (escrow) until the service is completed. After the user confirms completion (or after a timeout), the funds are **released to the service provider (partner)**. This protects both sides and is the same model as Grab, Uber, Airbnb.
- **Withdrawal:** Partners and users can withdraw their balance to their bank account. Withdrawal is processed by our backend (or by a licensed payment partner, if we integrate one).

**Vietnamese (nếu cần):**

- App là **sàn đặt lịch** cho **dịch vụ thực** (gặp mặt partner: gia sư, tư vấn, v.v.). User đặt lịch và thanh toán cho dịch vụ.
- **Thanh toán:** User có thể trả bằng **số dư trong app (ví)**. Ví được nạp qua thẻ / chuyển khoản / cổng thanh toán bên thứ ba. Chúng tôi **không** dùng in-app purchase vì dịch vụ được tiêu thụ **bên ngoài app** (Guideline 3.1.3(e)).
- **Escrow:** Khi user thanh toán đặt lịch, số tiền được **giữ tạm** (escrow) đến khi hoàn thành dịch vụ. Sau khi user xác nhận hoàn thành (hoặc hết thời gian chờ), tiền được **chuyển cho partner**. Rút tiền về tài khoản ngân hàng do backend (hoặc đối tác có giấy phép) xử lý.

---

## (b) Giấy phép (license)

**If you have a license (e.g. Vietnam intermediary payment / e-wallet):**

- “We hold an [intermediary payment / e-wallet] license issued by [State Bank of Vietnam / authority]. License number: [X]. We have attached the license document in App Review attachments / at [URL].”

**If you do not have a license yet:**

- “We are a booking platform for real-world services. Wallet and escrow are used **only** to facilitate payment for these services, not as a standalone financial product. We are [in the process of obtaining / planning to use a licensed partner for] regulatory compliance in Vietnam. We have not positioned the app as a general-purpose e-wallet or investment product (Guideline 3.2.1(viii)).”

(Replace with your actual status; avoid claiming to be a licensed financial institution if you are not.)

---

## (c) Tham chiếu app tương tự đã duyệt

You can cite these so the reviewer can compare the model:

| App | What it does | Why it’s similar |
|-----|----------------|-------------------|
| **GoESCROW** | Escrow for buyer/seller: hold funds until delivery/approval. | Same idea: hold money as intermediary until condition is met. |
| **Grab** | Ride-hailing + food + services; in-app balance; pay for real-world services. | Balance for real-world services; payment outside IAP. |
| **Uber** | Same as above. | Same. |
| **Airbnb** | Book accommodation; payment held until check-in/completion. | Escrow-like hold for real-world service. |

Short line for Notes: “Our payment and escrow model is similar to GoESCROW (escrow) and Grab/Uber/Airbnb (in-app balance for real-world services).”

---

## Quick reference – Guideline mapping

| Topic | Guideline | One-line answer |
|-------|-----------|-----------------|
| Why no IAP for booking payment? | 3.1.3(e) | Payments are for **real-world services consumed outside the app**; we use other payment methods (card, bank, gateway). |
| Is this “money management”? | 3.2.1(viii) | No. Wallet and escrow are **only** for paying for **bookings** on our platform, not for investing or standalone money management. |
| Who holds the money? | — | [We hold it in our system / A licensed partner holds it]. Funds are used only for booking payments and withdrawals to the user’s bank. |

---

## If they ask for “demo account” or “how to test”

Provide in Notes (and keep up to date):

1. **Test account:** email + password (and state if it’s a “demo” or sandbox environment).
2. **Steps to test:** (1) Log in → (2) Open Wallet → (3) Top up (use test card/flow if any) → (4) Create a booking and pay with wallet → (5) Complete booking (or simulate) so escrow releases.
3. **Withdrawal:** If withdrawal is manual/sandbox, say “Withdrawal can be tested by requesting a small amount; processing may be manual in test environment.”

Update this section each time you submit a new build so the reviewer can access a working flow.
