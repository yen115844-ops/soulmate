import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../data/models/partner_profile_model.dart';

/// Bottom action bar with Chat & Book buttons
class PartnerDetailBottomBar extends StatelessWidget {
  final PartnerDetailResponse detail;
  final VoidCallback? onChat;
  final VoidCallback? onBook;

  const PartnerDetailBottomBar({
    super.key,
    required this.detail,
    this.onChat,
    this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = detail.profile.isAvailable;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          
          _buildChatButton(context),
          const SizedBox(width: 10),
          // Book button
          Expanded(
            flex: 3,
            child: _buildBookButton(context, isAvailable),
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton(BuildContext context) {
    return GestureDetector(
      onTap: onChat,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: const Icon(
          Ionicons.chatbubble_ellipses_outline,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildBookButton(BuildContext context, bool isAvailable) {
    return GestureDetector(
      onTap: isAvailable ? onBook : null,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: isAvailable ? AppColors.accentGradient : null,
          color: isAvailable ? null : context.appColors.border,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isAvailable
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Ionicons.paper_plane_outline,
                color: isAvailable ? Colors.white : context.appColors.textHint,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isAvailable ? 'Gửi lời mời' : 'Chưa sẵn sàng',
                style: AppTypography.button.copyWith(
                  color:
                      isAvailable ? Colors.white : context.appColors.textHint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
