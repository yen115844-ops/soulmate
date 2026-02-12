import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Chính sách bảo mật'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chính sách bảo mật Mate Social',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Cập nhật lần cuối: 01/01/2026',
              style: AppTypography.labelSmall.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            _PolicySection(
              title: '1. Giới thiệu',
              content: '''
Mate Social ("chúng tôi", "của chúng tôi") cam kết bảo vệ quyền riêng tư của bạn. Chính sách bảo mật này giải thích cách chúng tôi thu thập, sử dụng, lưu trữ và bảo vệ thông tin cá nhân của bạn khi bạn sử dụng ứng dụng Mate Social.
''',
            ),

            _PolicySection(
              title: '2. Thông tin chúng tôi thu thập',
              content: '''
Chúng tôi thu thập các loại thông tin sau:

a) Thông tin bạn cung cấp:
• Họ tên, ngày sinh, giới tính
• Số điện thoại, email
• Ảnh đại diện, ảnh xác minh danh tính
• Thông tin thanh toán (số tài khoản ngân hàng)
• Nội dung tin nhắn, đánh giá

b) Thông tin tự động thu thập:
• Địa chỉ IP, loại thiết bị
• Vị trí địa lý (với sự đồng ý của bạn)
• Thông tin sử dụng ứng dụng
• Cookies và công nghệ theo dõi tương tự

c) Thông tin từ bên thứ ba:
• Thông tin từ mạng xã hội (nếu bạn đăng nhập qua MXH)
• Thông tin xác minh danh tính
''',
            ),

            _PolicySection(
              title: '3. Mục đích sử dụng thông tin',
              content: '''
Chúng tôi sử dụng thông tin của bạn để:
• Cung cấp và cải thiện dịch vụ
• Xác minh danh tính và bảo mật tài khoản
• Xử lý thanh toán và giao dịch
• Gửi thông báo về dịch vụ
• Hỗ trợ khách hàng
• Phân tích và cải thiện trải nghiệm người dùng
• Phát hiện và ngăn chặn gian lận
• Tuân thủ quy định pháp luật
''',
            ),

            _PolicySection(
              title: '4. Chia sẻ thông tin',
              content: '''
Chúng tôi có thể chia sẻ thông tin của bạn với:

• Partner (người đồng hành): Tên, ảnh đại diện để thực hiện dịch vụ
• Đối tác thanh toán: Thông tin cần thiết để xử lý giao dịch
• Nhà cung cấp dịch vụ: Bên thứ ba hỗ trợ vận hành ứng dụng
• Cơ quan pháp luật: Khi được yêu cầu theo quy định pháp luật

Chúng tôi không bán thông tin cá nhân của bạn cho bên thứ ba.
''',
            ),

            _PolicySection(
              title: '5. Bảo mật thông tin',
              content: '''
Chúng tôi áp dụng các biện pháp bảo mật để bảo vệ thông tin của bạn:
• Mã hóa dữ liệu truyền tải (SSL/TLS)
• Mã hóa dữ liệu lưu trữ
• Xác thực hai yếu tố
• Kiểm soát truy cập nghiêm ngặt
• Giám sát bảo mật 24/7
• Đào tạo nhân viên về bảo mật

Tuy nhiên, không có phương pháp truyền tải qua Internet nào an toàn 100%.
''',
            ),

            _PolicySection(
              title: '6. Quyền của bạn',
              content: '''
Bạn có các quyền sau đối với dữ liệu cá nhân:
• Quyền truy cập: Xem thông tin chúng tôi lưu trữ về bạn
• Quyền chỉnh sửa: Cập nhật thông tin không chính xác
• Quyền xóa: Yêu cầu xóa dữ liệu cá nhân
• Quyền hạn chế xử lý: Giới hạn cách chúng tôi sử dụng dữ liệu
• Quyền di chuyển dữ liệu: Nhận bản sao dữ liệu của bạn
• Quyền phản đối: Từ chối một số hoạt động xử lý dữ liệu

Để thực hiện các quyền này, liên hệ privacy@matesocial.vn
''',
            ),

            _PolicySection(
              title: '7. Lưu trữ dữ liệu',
              content: '''
• Chúng tôi lưu trữ dữ liệu trong thời gian cần thiết để cung cấp dịch vụ
• Sau khi xóa tài khoản, dữ liệu sẽ được xóa trong vòng 30 ngày
• Một số dữ liệu có thể được giữ lại để tuân thủ pháp luật
• Dữ liệu được lưu trữ trên máy chủ tại Việt Nam
''',
            ),

            _PolicySection(
              title: '8. Thông tin trẻ em',
              content: '''
Mate Social không dành cho người dưới 18 tuổi. Chúng tôi không cố ý thu thập thông tin từ trẻ em. Nếu phát hiện đã thu thập thông tin từ người dưới 18 tuổi, chúng tôi sẽ xóa ngay lập tức.
''',
            ),

            _PolicySection(
              title: '9. Cookies và công nghệ theo dõi',
              content: '''
Chúng tôi sử dụng cookies và công nghệ tương tự để:
• Ghi nhớ thông tin đăng nhập
• Hiểu cách bạn sử dụng ứng dụng
• Cải thiện trải nghiệm người dùng
• Cung cấp quảng cáo phù hợp

Bạn có thể quản lý cookies trong cài đặt thiết bị.
''',
            ),

            _PolicySection(
              title: '10. Thay đổi chính sách',
              content: '''
Chúng tôi có thể cập nhật chính sách này định kỳ. Khi có thay đổi quan trọng, chúng tôi sẽ thông báo qua ứng dụng hoặc email. Việc tiếp tục sử dụng dịch vụ sau khi thay đổi đồng nghĩa với việc bạn chấp nhận chính sách mới.
''',
            ),

            _PolicySection(
              title: '11. Liên hệ',
              content: '''
Nếu bạn có câu hỏi về chính sách bảo mật này, vui lòng liên hệ:

Cán bộ bảo vệ dữ liệu (DPO)
Email: privacy@matesocial.vn
Hotline: 1900 1234
Địa chỉ: Tầng 10, Tòa nhà ABC, Quận 1, TP.HCM
''',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.trim(),
            style: AppTypography.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
