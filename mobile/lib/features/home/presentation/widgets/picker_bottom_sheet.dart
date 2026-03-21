import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';

/// Picker bottom sheet for selecting from a list (provinces, districts, etc.)
class PickerBottomSheet extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<({String code, String label})> items;
  final String? selectedValue;
  final ValueChanged<String?> onSelect;

  const PickerBottomSheet({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  State<PickerBottomSheet> createState() => _PickerBottomSheetState();
}

class _PickerBottomSheetState extends State<PickerBottomSheet> {
  late TextEditingController _searchController;
  List<({String code, String label})> _filtered = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.items;
      } else {
        _filtered = widget.items
            .where((i) => i.label.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final bottomSafeInset = mediaQuery.padding.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                  child: Row(
                    children: [
                      Icon(widget.icon, size: 22, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        widget.title,
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm...',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: context.appColors.textHint,
                      ),
                      prefixIcon: Icon(
                        Ionicons.search_outline,
                        size: 20,
                        color: context.appColors.textHint,
                      ),
                      filled: true,
                      fillColor: context.appColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: context.appColors.border),
                Expanded(
                  child: _filtered.isEmpty
                      ? ListView(
                          controller: scrollController,
                          padding: EdgeInsets.only(bottom: bottomSafeInset + 24),
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Text(
                                'Không tìm thấy kết quả',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: context.appColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.only(bottom: bottomSafeInset + 8),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final item = _filtered[index];
                            final isSelected = widget.selectedValue == item.code;
                            return ListTile(
                              onTap: () => widget.onSelect(item.code),
                              title: Text(
                                item.label,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : context.textTheme.displayMedium!.color,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Ionicons.checkmark_circle,
                                      color: AppColors.primary,
                                      size: 22,
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
