import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../shared/data/models/master_data_models.dart';
import '../models/service_category_data.dart';

/// Horizontal scrollable service categories section
class ServiceCategoriesSection extends StatelessWidget {
  final String? selectedService;
  final ValueChanged<String> onServiceTap;
  final List<ServiceTypeModel> serviceTypes;

  const ServiceCategoriesSection({
    super.key,
    required this.selectedService,
    required this.onServiceTap,
    this.serviceTypes = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Use backend service types if available, otherwise fall back to hardcoded
    final categories = serviceTypes.isNotEmpty
        ? serviceTypes
              .map((s) => ServiceCategoryData.fromServiceType(s))
              .toList()
        : serviceCategories;

    return Container(
      color: context.appColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              'Hoạt động',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: MasonryGridView.count(
              scrollDirection: Axis.horizontal,
              crossAxisCount: 1,
              mainAxisSpacing: 10,
              crossAxisSpacing: 20,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              itemCount: categories.length,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedService == cat.code;
                return GestureDetector(
                      onTap: () => onServiceTap(cat.code),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cat.color
                                    : cat.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(color: cat.color, width: 2)
                                    : null,
                              ),
                              child: Icon(
                                cat.icon,
                                color: isSelected ? Colors.white : cat.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cat.label,
                              textAlign: TextAlign.center,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? cat.color
                                    : context.appColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
