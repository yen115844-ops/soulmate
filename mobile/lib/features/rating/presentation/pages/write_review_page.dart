import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../data/reviews_repository.dart';

class WriteReviewPage extends StatefulWidget {
  final String bookingId;

  const WriteReviewPage({super.key, required this.bookingId});

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  final _commentController = TextEditingController();
  int _overallRating = 0;
  int _punctualityRating = 0;
  int _communicationRating = 0;
  int _attitudeRating = 0;
  int _serviceQualityRating = 0;
  bool _isAnonymous = false;
  bool _isLoading = false;
  bool _isLoadingBooking = true;
  BookingEntity? _booking;
  String? _errorMessage;

  final List<String> _selectedTags = [];
  final List<String> _availableTags = [
    'Đúng giờ',
    'Thân thiện',
    'Chuyên nghiệp',
    'Hài hước',
    'Lịch sự',
    'Giao tiếp tốt',
    'Nhiệt tình',
    'Chu đáo',
  ];

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    try {
      final booking = await getIt<BookingRepository>().getBookingById(
        widget.bookingId,
      );
      setState(() {
        _booking = booking;
        _isLoadingBooking = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải thông tin đặt lịch';
        _isLoadingBooking = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đánh giá tổng thể'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await getIt<ReviewsRepository>().createReview(
        bookingId: widget.bookingId,
        overallRating: _overallRating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        punctualityRating: _punctualityRating > 0 ? _punctualityRating : null,
        communicationRating: _communicationRating > 0
            ? _communicationRating
            : null,
        attitudeRating: _attitudeRating > 0 ? _attitudeRating : null,
        serviceQualityRating: _serviceQualityRating > 0
            ? _serviceQualityRating
            : null,
        tags: _selectedTags.isEmpty ? null : _selectedTags,
        isAnonymous: _isAnonymous,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đánh giá thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi đánh giá: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Đánh giá Partner'),
      ),
      body: _isLoadingBooking
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Partner Info Card
                  if (_booking != null) _buildPartnerCard(),
                  const SizedBox(height: 24),

                  // Overall Rating
                  _buildRatingSection(
                    title: 'Đánh giá tổng thể',
                    rating: _overallRating,
                    onRatingChanged: (rating) =>
                        setState(() => _overallRating = rating),
                    isRequired: true,
                  ),
                  const SizedBox(height: 20),

                  // Detailed Ratings
                  Text(
                    'Đánh giá chi tiết (tuỳ chọn)',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildRatingSection(
                    title: 'Đúng giờ',
                    rating: _punctualityRating,
                    onRatingChanged: (rating) =>
                        setState(() => _punctualityRating = rating),
                    small: true,
                  ),
                  _buildRatingSection(
                    title: 'Giao tiếp',
                    rating: _communicationRating,
                    onRatingChanged: (rating) =>
                        setState(() => _communicationRating = rating),
                    small: true,
                  ),
                  _buildRatingSection(
                    title: 'Thái độ',
                    rating: _attitudeRating,
                    onRatingChanged: (rating) =>
                        setState(() => _attitudeRating = rating),
                    small: true,
                  ),
                  _buildRatingSection(
                    title: 'Chất lượng dịch vụ',
                    rating: _serviceQualityRating,
                    onRatingChanged: (rating) =>
                        setState(() => _serviceQualityRating = rating),
                    small: true,
                  ),

                  const SizedBox(height: 24),

                  // Tags
                  Text(
                    'Điểm nổi bật',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : context.appColors.textSecondary,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Comment
                  Text(
                    'Nhận xét',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _commentController,
                    hint: 'Chia sẻ trải nghiệm của bạn...',
                    maxLines: 4,
                  ),

                  const SizedBox(height: 24),

                  // Anonymous Option
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.appColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đánh giá ẩn danh',
                                style: AppTypography.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tên của bạn sẽ không hiển thị công khai',
                                style: AppTypography.bodySmall.copyWith(
                                  color: context.appColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isAnonymous,
                          onChanged: (value) =>
                              setState(() => _isAnonymous = value),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AppButton(
            text: _isLoading ? 'Đang gửi...' : 'Gửi đánh giá',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _submitReview,
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: _booking?.partnerAvatar != null
                ? NetworkImage(_booking!.partnerAvatar!)
                : null,
            child: _booking?.partnerAvatar == null
                ? Icon(Ionicons.person_outline, color: context.appColors.textSecondary)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _booking?.partnerName ?? 'Partner',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _booking?.serviceType ?? '',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection({
    required String title,
    required int rating,
    required ValueChanged<int> onRatingChanged,
    bool isRequired = false,
    bool small = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: small ? 12 : 0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: small
                      ? AppTypography.bodyMedium
                      : AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                ),
                if (isRequired)
                  Text(
                    ' *',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => onRatingChanged(index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: index < rating
                        ? AppColors.warning
                        : context.appColors.textHint,
                    size: small ? 24 : 32,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
