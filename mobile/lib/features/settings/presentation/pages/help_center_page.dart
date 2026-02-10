import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _faqCategories = [
    {
      'icon': Ionicons.person_outline,
      'title': 'Tài khoản',
      'color': AppColors.primary,
      'faqs': [
        {
          'question': 'Làm sao để đăng ký tài khoản?',
          'answer':
              'Bạn có thể đăng ký tài khoản bằng số điện thoại hoặc email. Nhấn vào nút "Đăng ký" ở màn hình đăng nhập và làm theo hướng dẫn.',
        },
        {
          'question': 'Tôi quên mật khẩu, phải làm sao?',
          'answer':
              'Nhấn vào "Quên mật khẩu" ở màn hình đăng nhập. Nhập số điện thoại đã đăng ký và bạn sẽ nhận được mã OTP để đặt lại mật khẩu.',
        },
        {
          'question': 'Làm sao để thay đổi thông tin cá nhân?',
          'answer':
              'Vào Hồ sơ > Chỉnh sửa hồ sơ để cập nhật thông tin cá nhân của bạn như tên, ảnh đại diện, ngày sinh...',
        },
      ],
    },
    {
      'icon': Ionicons.calendar_outline,
      'title': 'Đặt lịch',
      'color': AppColors.secondary,
      'faqs': [
        {
          'question': 'Làm sao để đặt lịch với Partner?',
          'answer':
              'Chọn Partner bạn muốn, nhấn vào nút "Đặt lịch", chọn ngày giờ và dịch vụ, sau đó xác nhận đặt lịch.',
        },
        {
          'question': 'Tôi có thể hủy lịch hẹn không?',
          'answer':
              'Có, bạn có thể hủy lịch hẹn trước 2 giờ so với giờ hẹn. Vào Lịch hẹn > Chọn lịch hẹn > Hủy lịch hẹn. Lưu ý: Việc hủy lịch nhiều lần có thể ảnh hưởng đến điểm đánh giá của bạn.',
        },
        {
          'question': 'Phí hủy lịch hẹn như thế nào?',
          'answer':
              'Hủy trước 24 giờ: Miễn phí\nHủy trước 2-24 giờ: 10% phí dịch vụ\nHủy trong vòng 2 giờ: 50% phí dịch vụ\nKhông đến: 100% phí dịch vụ',
        },
      ],
    },
    {
      'icon': Ionicons.wallet_outline,
      'title': 'Thanh toán & Ví',
      'color': AppColors.accent,
      'faqs': [
        {
          'question': 'Các phương thức thanh toán được hỗ trợ?',
          'answer':
              'Chúng tôi hỗ trợ thanh toán qua: Ví Mate Social, Thẻ ngân hàng (Visa, Mastercard), Chuyển khoản ngân hàng, Ví điện tử (Momo, ZaloPay, VNPay).',
        },
        {
          'question': 'Làm sao để nạp tiền vào ví?',
          'answer':
              'Vào Ví của tôi > Nạp tiền > Chọn phương thức nạp tiền và nhập số tiền muốn nạp.',
        },
        {
          'question': 'Thời gian hoàn tiền là bao lâu?',
          'answer':
              'Tiền hoàn trả sẽ được cộng vào ví Mate Social trong vòng 24 giờ. Nếu bạn muốn rút về tài khoản ngân hàng, thời gian xử lý là 1-3 ngày làm việc.',
        },
      ],
    },
    {
      'icon': Ionicons.shield_checkmark_outline,
      'title': 'Bảo mật & An toàn',
      'color': AppColors.success,
      'faqs': [
        {
          'question': 'Xác minh danh tính (eKYC) là gì?',
          'answer':
              'eKYC giúp xác minh danh tính thật của người dùng, đảm bảo an toàn cho cộng đồng. Người dùng đã xác minh sẽ có huy hiệu xác minh trên hồ sơ.',
        },
        {
          'question': 'Tính năng SOS hoạt động như thế nào?',
          'answer':
              'Khi gặp tình huống khẩn cấp, giữ nút SOS trong 5 giây. Vị trí của bạn sẽ được gửi đến các liên hệ khẩn cấp và đội ngũ hỗ trợ của chúng tôi.',
        },
        {
          'question': 'Làm sao để báo cáo Partner không phù hợp?',
          'answer':
              'Vào trang hồ sơ Partner > Nhấn biểu tượng "..." > Chọn "Báo cáo". Chọn lý do và mô tả chi tiết vấn đề. Chúng tôi sẽ xem xét và phản hồi trong vòng 24 giờ.',
        },
      ],
    },
    {
      'icon': Ionicons.people_outline,
      'title': 'Trở thành Partner',
      'color': AppColors.info,
      'faqs': [
        {
          'question': 'Điều kiện để trở thành Partner?',
          'answer':
              'Để trở thành Partner, bạn cần: Trên 18 tuổi, Đã xác minh danh tính (eKYC), Có tài khoản ngân hàng để nhận thanh toán.',
        },
        {
          'question': 'Phí hoa hồng của Partner là bao nhiêu?',
          'answer':
              'Partner nhận 80% giá trị mỗi đơn hàng. 20% còn lại là phí dịch vụ của nền tảng.',
        },
        {
          'question': 'Làm sao để rút tiền về tài khoản ngân hàng?',
          'answer':
              'Vào Ví của tôi > Rút tiền > Nhập số tiền muốn rút > Xác nhận. Tiền sẽ được chuyển trong 1-3 ngày làm việc.',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> _getFilteredFaqs() {
    if (_searchQuery.isEmpty) return _faqCategories;

    final query = _searchQuery.toLowerCase();
    return _faqCategories.map((category) {
      final filteredFaqs = (category['faqs'] as List<Map<String, String>>)
          .where((faq) =>
              faq['question']!.toLowerCase().contains(query) ||
              faq['answer']!.toLowerCase().contains(query))
          .toList();

      if (filteredFaqs.isEmpty) return null;

      return {...category, 'faqs': filteredFaqs};
    }).whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _contactSupport(String method) async {
    Uri uri;
    switch (method) {
      case 'email':
        uri = Uri(scheme: 'mailto', path: 'support@matesocial.vn');
        break;
      case 'phone':
        uri = Uri(scheme: 'tel', path: '19001234');
        break;
      case 'chat':
        // TODO: Open in-app chat
        return;
      default:
        return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _getFilteredFaqs();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Trung tâm trợ giúp'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào! Bạn cần hỗ trợ gì?',
                    style: AppTypography.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tìm kiếm câu trả lời cho câu hỏi của bạn',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _searchController,
                    hint: 'Tìm kiếm...',
                    prefixIcon: Ionicons.search_outline,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ],
              ),
            ),

            // FAQ Categories
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Câu hỏi thường gặp',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  if (filteredFaqs.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(
                            Ionicons.search_outline,
                            size: 64,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không tìm thấy kết quả',
                            style: AppTypography.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Thử tìm kiếm với từ khóa khác',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredFaqs.map((category) => _FaqCategory(
                          icon: category['icon'] as IconData,
                          title: category['title'] as String,
                          color: category['color'] as Color,
                          faqs: category['faqs'] as List<Map<String, String>>,
                        )),
                ],
              ),
            ),

            // Contact Support Section
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cần hỗ trợ thêm?',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Liên hệ với đội ngũ hỗ trợ của chúng tôi',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _ContactButton(
                          icon: Ionicons.chatbubble_outline,
                          label: 'Chat',
                          onTap: () => _contactSupport('chat'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ContactButton(
                          icon: Ionicons.call_outline,
                          label: 'Gọi điện',
                          onTap: () => _contactSupport('phone'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ContactButton(
                          icon: Ionicons.mail_outline,
                          label: 'Email',
                          onTap: () => _contactSupport('email'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Support Hours
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Ionicons.time_outline,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giờ hỗ trợ',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '8:00 - 22:00, Thứ Hai - Chủ Nhật',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _FaqCategory extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Map<String, String>> faqs;

  const _FaqCategory({
    required this.icon,
    required this.title,
    required this.color,
    required this.faqs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title, style: AppTypography.titleSmall),
          subtitle: Text(
            '${faqs.length} câu hỏi',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
          children: faqs.map((faq) => _FaqItem(faq: faq)).toList(),
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final Map<String, String> faq;

  const _FaqItem({required this.faq});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            faq['question']!,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                faq['answer']!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
