import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Điều khoản sử dụng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Điều khoản sử dụng Mate Social',
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

            _TermsSection(
              title: '1. Giới thiệu',
              content: '''
Chào mừng bạn đến với Mate Social. Bằng việc truy cập và sử dụng ứng dụng Mate Social, bạn đồng ý tuân thủ các điều khoản và điều kiện sau đây.

Mate Social là nền tảng kết nối người dùng với các Partner (người đồng hành) để cung cấp các dịch vụ đồng hành xã hội như: cafe, ăn tối, xem phim, đi dạo, tham dự sự kiện, v.v.
''',
            ),

            _TermsSection(
              title: '2. Điều kiện sử dụng',
              content: '''
Để sử dụng Mate Social, bạn cần:
• Từ 18 tuổi trở lên
• Cung cấp thông tin chính xác, đầy đủ khi đăng ký
• Không sử dụng dịch vụ cho mục đích bất hợp pháp
• Không vi phạm quyền của người khác
• Tuân thủ pháp luật Việt Nam

Chúng tôi có quyền từ chối hoặc chấm dứt tài khoản của bạn nếu vi phạm các điều khoản này.
''',
            ),

            _TermsSection(
              title: '3. Tài khoản người dùng',
              content: '''
• Bạn chịu trách nhiệm bảo mật thông tin đăng nhập của mình
• Không được chia sẻ tài khoản với người khác
• Thông báo ngay cho chúng tôi nếu phát hiện truy cập trái phép
• Một người chỉ được sở hữu một tài khoản
• Tài khoản không hoạt động trong 12 tháng có thể bị vô hiệu hóa
''',
            ),

            _TermsSection(
              title: '4. Dịch vụ và thanh toán',
              content: '''
• Giá dịch vụ được hiển thị rõ ràng trước khi đặt lịch
• Thanh toán được thực hiện qua các phương thức được hỗ trợ
• Phí hủy đặt lịch áp dụng theo chính sách được công bố
• Tiền hoàn trả sẽ được xử lý trong vòng 1-3 ngày làm việc
• Mate Social thu phí dịch vụ 20% trên mỗi giao dịch
''',
            ),

            _TermsSection(
              title: '5. Quy tắc ứng xử',
              content: '''
Khi sử dụng Mate Social, bạn cam kết:
• Tôn trọng người khác
• Không có hành vi quấy rối, đe dọa
• Không đăng tải nội dung không phù hợp
• Không yêu cầu hoặc cung cấp dịch vụ bất hợp pháp
• Giữ an toàn cho bản thân và người khác
• Báo cáo các hành vi vi phạm qua kênh hỗ trợ
''',
            ),

            _TermsSection(
              title: '6. Quyền sở hữu trí tuệ',
              content: '''
• Mate Social sở hữu toàn bộ quyền đối với ứng dụng
• Bạn không được sao chép, sửa đổi, phân phối ứng dụng
• Nội dung bạn tạo ra vẫn thuộc quyền sở hữu của bạn
• Bạn cấp cho chúng tôi quyền sử dụng nội dung đó trên nền tảng
''',
            ),

            _TermsSection(
              title: '7. Giới hạn trách nhiệm',
              content: '''
• Mate Social là nền tảng kết nối, không chịu trách nhiệm trực tiếp về chất lượng dịch vụ của Partner
• Chúng tôi không chịu trách nhiệm về thiệt hại gián tiếp
• Trách nhiệm tối đa không vượt quá số tiền bạn đã thanh toán trong 12 tháng gần nhất
''',
            ),

            _TermsSection(
              title: '8. Thay đổi điều khoản',
              content: '''
Chúng tôi có thể thay đổi các điều khoản này bất cứ lúc nào. Các thay đổi sẽ có hiệu lực ngay khi được đăng tải. Việc tiếp tục sử dụng dịch vụ đồng nghĩa với việc bạn chấp nhận các thay đổi.
''',
            ),

            _TermsSection(
              title: '9. Liên hệ',
              content: '''
Nếu bạn có câu hỏi về các điều khoản này, vui lòng liên hệ:
• Email: legal@matesocial.vn
• Hotline: 1900 1234
• Địa chỉ: Tầng 10, Tòa nhà ABC, Quận 1, TP.HCM
''',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermsSection({
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
