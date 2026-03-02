import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';
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
      'title': 'Hoạt động',
      'color': AppColors.secondary,
      'faqs': [
        {
          'question': 'Làm sao để tham gia hoạt động?',
          'answer':
              'Duyệt danh sách hoạt động trên trang chủ, chọn hoạt động bạn quan tâm, nhấn "Tham gia" và chờ người tạo xác nhận.',
        },
        {
          'question': 'Tôi có thể hủy tham gia hoạt động không?',
          'answer':
              'Có, bạn có thể hủy tham gia trước 2 giờ so với giờ hẹn. Vào Hoạt động > Chọn hoạt động > Hủy tham gia. Lưu ý: Việc hủy nhiều lần có thể ảnh hưởng đến đánh giá của bạn.',
        },
        {
          'question': 'Làm sao để tạo hoạt động mới?',
          'answer':
              'Nhấn nút "+" trên trang chủ, chọn loại hoạt động, đặt thời gian và địa điểm, sau đó đăng hoạt động để mọi người tham gia.',
        },
      ],
    },
    {
      'icon': Ionicons.diamond_outline,
      'title': 'Premium',
      'color': AppColors.accent,
      'faqs': [
        {
          'question': 'Premium có những tính năng gì?',
          'answer':
              'Premium bao gồm: Nhắn tin không giới hạn, Bộ lọc nâng cao, Badge Premium, Ưu tiên hiển thị, Xem ai quan tâm đến bạn.',
        },
        {
          'question': 'Làm sao để đăng ký Premium?',
          'answer': Platform.isIOS
              ? 'Vào Hồ sơ > Premium > Chọn gói phù hợp và thanh toán qua App Store.'
            : 'Vào Hồ sơ > Premium > Chọn gói phù hợp và thanh toán qua cửa hàng ứng dụng trên thiết bị của bạn.',
        },
        {
          'question': 'Làm sao để hủy Premium?',
          'answer': Platform.isIOS
              ? 'Bạn có thể hủy đăng ký trong Cài đặt > [Apple ID] > Đăng ký. Gói sẽ còn hiệu lực đến hết chu kỳ hiện tại.'
            : 'Bạn có thể hủy đăng ký trong cài đặt tài khoản cửa hàng ứng dụng trên thiết bị. Gói sẽ còn hiệu lực đến hết chu kỳ hiện tại.',
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
          'question': 'Làm sao để báo cáo người dùng không phù hợp?',
          'answer':
              'Vào trang hồ sơ người dùng > Nhấn biểu tượng "..." > Chọn "Báo cáo". Chọn lý do và mô tả chi tiết vấn đề. Chúng tôi sẽ xem xét và phản hồi trong vòng 24 giờ.',
        },
      ],
    },
    {
      'icon': Ionicons.people_outline,
      'title': 'Tạo hoạt động',
      'color': AppColors.info,
      'faqs': [
        {
          'question': 'Ai có thể tạo hoạt động?',
          'answer':
              'Tất cả người dùng đã xác minh danh tính đều có thể tạo hoạt động. Bạn cần trên 18 tuổi và đã hoàn tất xác minh.',
        },
        {
          'question': 'Có những loại hoạt động nào?',
          'answer':
              'Bạn có thể tạo nhiều loại hoạt động: Cà phê, Xem phim, Thể thao, Du lịch, Ăn uống, Mua sắm, Tiệc tùng và nhiều hoạt động khác.',
        },
        {
          'question': 'Hoạt động có mất phí không?',
          'answer':
              'Việc tham gia hoạt động trên nền tảng là miễn phí. Chi phí cá nhân (như đồ uống, vé xem phim...) mỗi người tự chi trả.',
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
        uri = Uri(scheme: 'mailto', path: 'ngocbinhan8888@gmail.com');
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
              padding: ResponsiveLayout.pagePadding(context),
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
                      color: context.appColors.textSecondary,
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
              padding: ResponsiveLayout.pagePadding(context),
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
                            color: context.appColors.textHint,
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
                              color: context.appColors.textSecondary,
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
              margin: ResponsiveLayout.pagePadding(context),
              padding: ResponsiveLayout.pagePadding(context),
              decoration: BoxDecoration(
                color: context.appColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appColors.border),
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
                      color: context.appColors.textSecondary,
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
              padding: ResponsiveLayout.pagePadding(context).copyWith(top: 0, bottom: 20),
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
                              color: context.appColors.textSecondary,
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
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border),
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
              color: context.appColors.textHint,
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
          top: BorderSide(color: context.appColors.border),
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
              padding: EdgeInsets.fromLTRB(ResponsiveLayout.horizontalPadding(context), 0, ResponsiveLayout.horizontalPadding(context), 16),
              child: Text(
                faq['answer']!,
                style: AppTypography.bodySmall.copyWith(
                  color: context.appColors.textSecondary,
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
          color: context.appColors.background,
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
