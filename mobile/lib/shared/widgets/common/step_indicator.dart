import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ionicons/ionicons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Step Indicator for multi-step flows (Booking, KYC, etc.)
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final bool showLabels;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels = const [],
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isOdd) {
              // Connector line
              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex < currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            } else {
              // Step circle
              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex < currentStep;
              final isCurrent = stepIndex == currentStep;

              return _StepCircle(
                stepNumber: stepIndex + 1,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
              );
            }
          }),
        ),
        if (showLabels && stepLabels.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final isActive = index <= currentStep;
              return Expanded(
                child: Text(
                  stepLabels.length > index ? stepLabels[index] : '',
                  style: AppTypography.labelSmall.copyWith(
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int stepNumber;
  final bool isCompleted;
  final bool isCurrent;

  const _StepCircle({
    required this.stepNumber,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? AppColors.primary
            : isCurrent
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surface,
        border: Border.all(
          color: isCompleted || isCurrent
              ? AppColors.primary
              : AppColors.border,
          width: 2,
        ),
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Ionicons.checkmark_circle_outline,
                color: Colors.white,
                size: 20,
              ).animate().scale(duration: 200.ms)
            : Text(
                '$stepNumber',
                style: AppTypography.labelLarge.copyWith(
                  color: isCurrent
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Progress Step Indicator (Linear)
class LinearStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final double height;

  const LinearStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: constraints.maxWidth * (currentStep + 1) / totalSteps,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          );
        },
      ),
    );
  }
}

/// Step Card - Used in booking flow
class StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;
  final VoidCallback? onTap;
  final Widget? trailing;

  const StepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    this.subtitle,
    required this.icon,
    this.isCompleted = false,
    this.isActive = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : isCompleted
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.border,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Step Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success.withOpacity(0.1)
                    : isActive
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(
                        Ionicons.checkmark_circle_outline,
                        color: AppColors.success,
                        size: 24,
                      )
                    : Icon(
                        icon,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Bước $stepNumber',
                        style: AppTypography.labelSmall.copyWith(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Hoàn thành',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              Icon(
                Ionicons.chevron_forward_outline,
                color: AppColors.textHint,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
