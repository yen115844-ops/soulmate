/**
 * API Response messages
 */

export const MESSAGES = {
  // Auth
  AUTH: {
    LOGIN_SUCCESS: 'Đăng nhập thành công',
    LOGOUT_SUCCESS: 'Đăng xuất thành công',
    REGISTER_SUCCESS: 'Đăng ký thành công',
    INVALID_CREDENTIALS: 'Email hoặc mật khẩu không đúng',
    USER_NOT_FOUND: 'Không tìm thấy người dùng',
    EMAIL_EXISTS: 'Email đã được sử dụng',
    PHONE_EXISTS: 'Số điện thoại đã được sử dụng',
    TOKEN_EXPIRED: 'Token đã hết hạn',
    TOKEN_INVALID: 'Token không hợp lệ',
    ACCOUNT_SUSPENDED: 'Tài khoản đã bị tạm khóa',
    ACCOUNT_BANNED: 'Tài khoản đã bị cấm',
    PASSWORD_CHANGED: 'Đổi mật khẩu thành công',
    PASSWORD_INCORRECT: 'Mật khẩu hiện tại không đúng',
  },

  // OTP
  OTP: {
    SENT: 'Mã OTP đã được gửi',
    VERIFIED: 'Xác thực OTP thành công',
    INVALID: 'Mã OTP không đúng',
    EXPIRED: 'Mã OTP đã hết hạn',
    MAX_ATTEMPTS: 'Đã vượt quá số lần nhập OTP cho phép',
  },

  // User
  USER: {
    PROFILE_UPDATED: 'Cập nhật thông tin thành công',
    LOCATION_UPDATED: 'Cập nhật vị trí thành công',
    ACCOUNT_DELETED: 'Xóa tài khoản thành công',
    NOT_FOUND: 'Không tìm thấy người dùng',
  },

  // Partner
  PARTNER: {
    REGISTERED: 'Đăng ký Partner thành công',
    PROFILE_UPDATED: 'Cập nhật thông tin Partner thành công',
    NOT_VERIFIED: 'Partner chưa được xác thực KYC',
    NOT_FOUND: 'Không tìm thấy Partner',
    AVAILABILITY_UPDATED: 'Cập nhật lịch rảnh thành công',
  },

  // KYC
  KYC: {
    SUBMITTED: 'Đã gửi hồ sơ KYC để xét duyệt',
    VERIFIED: 'Xác thực danh tính thành công',
    REJECTED: 'Xác thực danh tính bị từ chối',
    ALREADY_VERIFIED: 'Tài khoản đã được xác thực',
    PENDING: 'Hồ sơ KYC đang chờ xét duyệt',
  },

  // Booking
  BOOKING: {
    CREATED: 'Đặt lịch thành công',
    CONFIRMED: 'Xác nhận đặt lịch thành công',
    CANCELLED: 'Hủy đặt lịch thành công',
    STARTED: 'Bắt đầu buổi hẹn thành công',
    COMPLETED: 'Hoàn thành buổi hẹn thành công',
    NOT_FOUND: 'Không tìm thấy đặt lịch',
    ALREADY_CONFIRMED: 'Đặt lịch đã được xác nhận',
    ALREADY_CANCELLED: 'Đặt lịch đã bị hủy',
    INVALID_STATUS: 'Trạng thái đặt lịch không hợp lệ',
    SLOT_NOT_AVAILABLE: 'Khung giờ này đã có người đặt',
    INSUFFICIENT_HOURS: 'Thời gian đặt tối thiểu là 3 giờ',
    CANNOT_BOOK_SELF: 'Không thể đặt lịch với chính mình',
  },

  // Payment
  PAYMENT: {
    SUCCESS: 'Thanh toán thành công',
    FAILED: 'Thanh toán thất bại',
    INSUFFICIENT_BALANCE: 'Số dư không đủ',
    DEPOSIT_SUCCESS: 'Nạp tiền thành công',
    WITHDRAWAL_SUCCESS: 'Yêu cầu rút tiền đã được gửi',
    ESCROW_HELD: 'Đã giữ tiền trong escrow',
    ESCROW_RELEASED: 'Đã giải phóng tiền escrow',
    ESCROW_REFUNDED: 'Đã hoàn tiền escrow',
    TRANSACTION_NOT_FOUND: 'Không tìm thấy giao dịch',
  },

  // Chat
  CHAT: {
    CONVERSATION_CREATED: 'Tạo hội thoại thành công',
    MESSAGE_SENT: 'Gửi tin nhắn thành công',
    CONVERSATION_NOT_FOUND: 'Không tìm thấy hội thoại',
    CANNOT_CHAT_SELF: 'Không thể nhắn tin với chính mình',
    BLOCKED: 'Bạn đã bị chặn',
  },

  // Review
  REVIEW: {
    CREATED: 'Đánh giá thành công',
    UPDATED: 'Cập nhật đánh giá thành công',
    DELETED: 'Xóa đánh giá thành công',
    NOT_FOUND: 'Không tìm thấy đánh giá',
    ALREADY_REVIEWED: 'Bạn đã đánh giá đặt lịch này',
    BOOKING_NOT_COMPLETED: 'Chỉ có thể đánh giá sau khi hoàn thành buổi hẹn',
    RESPONSE_ADDED: 'Đã thêm phản hồi đánh giá',
  },

  // Blacklist
  BLACKLIST: {
    BLOCKED: 'Đã chặn người dùng',
    UNBLOCKED: 'Đã bỏ chặn người dùng',
    ALREADY_BLOCKED: 'Người dùng đã bị chặn từ trước',
    NOT_BLOCKED: 'Người dùng chưa bị chặn',
    CANNOT_BLOCK_SELF: 'Không thể tự chặn chính mình',
  },

  // Safety
  SAFETY: {
    SOS_TRIGGERED: 'Đã gửi tín hiệu khẩn cấp',
    SOS_RESOLVED: 'Đã xử lý tình huống khẩn cấp',
    EMERGENCY_CONTACT_ADDED: 'Thêm liên hệ khẩn cấp thành công',
    EMERGENCY_CONTACT_UPDATED: 'Cập nhật liên hệ khẩn cấp thành công',
    EMERGENCY_CONTACT_DELETED: 'Xóa liên hệ khẩn cấp thành công',
  },

  // Notification
  NOTIFICATION: {
    MARKED_READ: 'Đánh dấu đã đọc thành công',
    ALL_MARKED_READ: 'Đánh dấu tất cả đã đọc',
    DELETED: 'Xóa thông báo thành công',
    TOKEN_REGISTERED: 'Đăng ký device token thành công',
  },

  // Upload
  UPLOAD: {
    SUCCESS: 'Upload thành công',
    FAILED: 'Upload thất bại',
    FILE_TOO_LARGE: 'File quá lớn',
    INVALID_TYPE: 'Loại file không được hỗ trợ',
    DELETED: 'Xóa file thành công',
  },

  // Search
  SEARCH: {
    NO_RESULTS: 'Không tìm thấy kết quả',
  },

  // Favorites
  FAVORITE: {
    ADDED: 'Đã thêm vào yêu thích',
    REMOVED: 'Đã xóa khỏi yêu thích',
    ALREADY_ADDED: 'Đã có trong danh sách yêu thích',
  },

  // Common
  COMMON: {
    SUCCESS: 'Thành công',
    ERROR: 'Có lỗi xảy ra',
    NOT_FOUND: 'Không tìm thấy',
    FORBIDDEN: 'Không có quyền truy cập',
    UNAUTHORIZED: 'Chưa đăng nhập',
    BAD_REQUEST: 'Yêu cầu không hợp lệ',
    VALIDATION_ERROR: 'Dữ liệu không hợp lệ',
    SERVER_ERROR: 'Lỗi hệ thống',
  },
};

export default MESSAGES;
