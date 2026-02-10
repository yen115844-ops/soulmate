import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Service Category Chip - Modern styled service chip
class ServiceCategoryChip extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;
  final double? width;
  final bool showShadow;

  const ServiceCategoryChip({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    this.isSelected = false,
    this.onTap,
    this.width,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 0 : 1,
          ),
          boxShadow: showShadow || isSelected
              ? [
                  BoxShadow(
                    color: isSelected
                        ? color.withOpacity(0.3)
                        : AppColors.shadow.withOpacity(0.08),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Service Category Card - Vertical style for grid
class ServiceCategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isCompact;

  const ServiceCategoryCard({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(icon, size: 26, color: color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 28, color: color),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal Services List
class ServicesHorizontalList extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final String? selectedService;
  final Function(String)? onServiceSelected;
  final EdgeInsets padding;
  final bool animate;

  const ServicesHorizontalList({
    super.key,
    required this.services,
    this.selectedService,
    this.onServiceSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          final isSelected = selectedService == service['name'];

          Widget chip = ServiceCategoryChip(
            name: service['name'],
            icon: service['icon'] as IconData,
            color: service['color'] ?? AppColors.primary,
            isSelected: isSelected,
            onTap: () => onServiceSelected?.call(service['name']),
          );

          if (animate) {
            chip = chip.animate().fadeIn(
                  delay: Duration(milliseconds: 30 * index),
                  duration: const Duration(milliseconds: 300),
                );
          }

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: chip,
          );
        },
      ),
    );
  }
}

/// Services Grid
class ServicesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final Function(String)? onServiceSelected;
  final int crossAxisCount;
  final bool isCompact;
  final EdgeInsets padding;

  const ServicesGrid({
    super.key,
    required this.services,
    this.onServiceSelected,
    this.crossAxisCount = 4,
    this.isCompact = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Padding(
        padding: padding,
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.spaceBetween,
          children: services.map((service) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 32 - 48) / 4,
              child: ServiceCategoryCard(
                name: service['name'],
                icon: service['icon'] as IconData,
                color: service['color'] ?? AppColors.primary,
                isCompact: true,
                onTap: () => onServiceSelected?.call(service['name']),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return ServiceCategoryCard(
            name: service['name'],
            icon: service['icon'] as IconData,
            color: service['color'] ?? AppColors.primary,
            onTap: () => onServiceSelected?.call(service['name']),
          ).animate().fadeIn(
                delay: Duration(milliseconds: 50 * index),
                duration: const Duration(milliseconds: 300),
              );
        },
      ),
    );
  }
}
