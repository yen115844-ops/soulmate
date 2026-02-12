import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../models/service_category_data.dart';

/// Horizontal scrollable service categories section
class ServiceCategoriesSection extends StatelessWidget {
  final String? selectedService;
  final ValueChanged<String> onServiceTap;

  const ServiceCategoriesSection({
    super.key,
    required this.selectedService,
    required this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              'Dịch vụ',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: serviceCategories.length,
              itemBuilder: (context, index) {
                final cat = serviceCategories[index];
                final isSelected = selectedService == cat.code;
                return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => onServiceTap(cat.code),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 72,
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cat.color
                                      : cat.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected
                                      ? Border.all(
                                          color: cat.color, width: 2)
                                      : null,
                                ),
                                child: Icon(
                                  cat.icon,
                                  color:
                                      isSelected ? Colors.white : cat.color,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat.label,
                                style: AppTypography.labelSmall.copyWith(
                                  color: isSelected
                                      ? cat.color
                                      : context.appColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 40 * index),
                      duration: 300.ms,
                    )
                    .slideX(begin: 0.2, end: 0);
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
