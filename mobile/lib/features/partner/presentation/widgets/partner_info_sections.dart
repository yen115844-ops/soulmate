import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../data/models/partner_profile_model.dart';

/// Introduction / About section
class PartnerAboutSection extends StatefulWidget {
  final PartnerDetailResponse detail;

  const PartnerAboutSection({super.key, required this.detail});

  @override
  State<PartnerAboutSection> createState() => _PartnerAboutSectionState();
}

class _PartnerAboutSectionState extends State<PartnerAboutSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bio = widget.detail.bio;
    if (bio == null || bio.isEmpty) return const SizedBox.shrink();

    final isLong = bio.length > 150;

    return _SectionContainer(
      title: 'Giới thiệu',
      icon: Ionicons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedCrossFade(
            firstChild: Text(
              bio,
              style: AppTypography.bodyMedium.copyWith(
                color: context.appColors.textSecondary,
                height: 1.6,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            secondChild: Text(
              bio,
              style: AppTypography.bodyMedium.copyWith(
                color: context.appColors.textSecondary,
                height: 1.6,
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          if (isLong) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Text(
                _isExpanded ? 'Thu gọn' : 'Xem thêm',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          // Physical info chips
          if (widget.detail.heightCm != null ||
              widget.detail.weightKg != null ||
              widget.detail.gender != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.detail.gender != null)
                  _buildInfoChip(
                    context,
                    icon: widget.detail.gender == 'FEMALE'
                        ? Ionicons.female
                        : widget.detail.gender == 'MALE'
                        ? Ionicons.male
                        : Ionicons.transgender_outline,
                    label: widget.detail.gender == 'FEMALE'
                        ? 'Nữ'
                        : widget.detail.gender == 'MALE'
                        ? 'Nam'
                        : 'Khác',
                  ),
                if (widget.detail.heightCm != null)
                  _buildInfoChip(
                    context,
                    icon: Ionicons.resize_outline,
                    label: '${widget.detail.heightCm} cm',
                  ),
                if (widget.detail.weightKg != null)
                  _buildInfoChip(
                    context,
                    icon: Ionicons.fitness_outline,
                    label: '${widget.detail.weightKg} kg',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.appColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.appColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Services offered section
class PartnerServicesSection extends StatelessWidget {
  final PartnerDetailResponse detail;

  const PartnerServicesSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final services = detail.serviceTypesDetail;
    if (services.isEmpty) return const SizedBox.shrink();

    return _SectionContainer(
      title: 'Hoạt động',
      icon: Ionicons.briefcase_outline,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: services.map((service) {
          final code = service['code']?.toString() ?? '';
          final nameVi =
              service['displayName']?.toString() ??
              service['nameVi']?.toString() ??
              service['name']?.toString() ??
              code;
          final icon = service['icon']?.toString() ?? '🎯';
          final color = AppColors.getServiceColor(code);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  nameVi,
                  style: AppTypography.labelMedium.copyWith(
                     fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Languages section
class PartnerLanguagesSection extends StatelessWidget {
  final PartnerDetailResponse detail;

  const PartnerLanguagesSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final languages = detail.languages;
    if (languages.isEmpty) return const SizedBox.shrink();

    return _SectionContainer(
      title: 'Ngôn ngữ',
      icon: Ionicons.language_outline,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: languages.map((lang) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Ionicons.globe_outline, size: 16, color: AppColors.info),
                const SizedBox(width: 6),
                Text(
                  lang,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Interests section
class PartnerInterestsSection extends StatelessWidget {
  final PartnerDetailResponse detail;

  const PartnerInterestsSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final interestsDetail = detail.interestsDetail;
    if (interestsDetail.isEmpty) return const SizedBox.shrink();

    return _SectionContainer(
      title: 'Sở thích',
      icon: Ionicons.heart_outline,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: interestsDetail.map((interest) {
          final nameVi =
              interest['displayName']?.toString() ??
              interest['nameVi']?.toString() ??
              interest['name']?.toString() ??
              '';
          final icon = interest['icon']?.toString() ?? '🎯';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  nameVi,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Talents section
class PartnerTalentsSection extends StatelessWidget {
  final PartnerDetailResponse detail;

  const PartnerTalentsSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final talentsDetail = detail.talentsDetail;
    if (talentsDetail.isEmpty) return const SizedBox.shrink();

    return _SectionContainer(
      title: 'Tài năng',
      icon: Ionicons.diamond_outline,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: talentsDetail.map((talent) {
          final nameVi =
              talent['displayName']?.toString() ??
              talent['nameVi']?.toString() ??
              talent['name']?.toString() ??
              '';
          final icon = talent['icon']?.toString() ?? '⭐';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  nameVi,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Reusable section container with title + icon
class _SectionContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionContainer({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
