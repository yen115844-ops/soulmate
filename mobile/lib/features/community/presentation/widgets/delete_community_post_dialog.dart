import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// [Dialog] xác nhận xóa bài (không dùng [AlertDialog]) — nền và chữ theo theme rõ ràng.
Future<bool?> showDeleteCommunityPostDialog(
  BuildContext context, {
  String message = 'Bài đăng sẽ không còn hiển thị trên cộng đồng.',
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final colors = dialogContext.appColors;
      final scheme = Theme.of(dialogContext).colorScheme;
      final textTheme = Theme.of(dialogContext).textTheme;

      return Dialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.14)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Xóa bài?',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.35,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.55),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Xóa'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
