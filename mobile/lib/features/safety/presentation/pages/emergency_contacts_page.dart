import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../data/models/emergency_contact_model.dart';
import '../bloc/emergency_contacts_bloc.dart';
import '../bloc/emergency_contacts_event.dart';
import '../bloc/emergency_contacts_state.dart';

class EmergencyContactsPage extends StatelessWidget {
  const EmergencyContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<EmergencyContactsBloc>()
            ..add(const EmergencyContactsLoadRequested()),
      child: const _EmergencyContactsView(),
    );
  }
}

class _EmergencyContactsView extends StatelessWidget {
  const _EmergencyContactsView();

  void _addContact(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRelationship = 'Gia đình';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration:   BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thêm liên hệ khẩn cấp', style: AppTypography.titleLarge),
            const SizedBox(height: 24),
            AppTextField(
              controller: nameController,
              label: 'Tên liên hệ',
              hint: 'Nhập tên',
              prefixIcon: Ionicons.person_outline,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: phoneController,
              label: 'Số điện thoại',
              hint: 'Nhập số điện thoại',
              keyboardType: TextInputType.phone,
              prefixIcon: Ionicons.call_outline,
            ),
            const SizedBox(height: 16),
            Text('Mối quan hệ', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setLocalState) => Wrap(
                spacing: 8,
                children: ['Gia đình', 'Bạn bè', 'Người yêu', 'Khác'].map((
                  relationship,
                ) {
                  final isSelected = selectedRelationship == relationship;
                  return GestureDetector(
                    onTap: () => setLocalState(
                      () => selectedRelationship = relationship,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : context.appColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : context.appColors.border,
                        ),
                      ),
                      child: Text(
                        relationship,
                        style: AppTypography.labelMedium.copyWith(
                          color: isSelected
                              ? AppColors.textWhite
                              : context.appColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Thêm liên hệ',
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty) {
                  context.read<EmergencyContactsBloc>().add(
                    EmergencyContactCreateRequested(
                      name: nameController.text,
                      phone: phoneController.text,
                      relationship: selectedRelationship,
                    ),
                  );
                  Navigator.pop(sheetContext);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteContact(BuildContext context, EmergencyContactModel contact) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa liên hệ?'),
        content: Text('Bạn có chắc muốn xóa ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              context.read<EmergencyContactsBloc>().add(
                EmergencyContactDeleteRequested(contact.id),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Liên hệ khẩn cấp'),
        actions: [
          BlocBuilder<EmergencyContactsBloc, EmergencyContactsState>(
            builder: (context, state) {
              return IconButton(
                icon: state.status == EmergencyContactsStatus.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Ionicons.refresh_outline),
                onPressed: state.status == EmergencyContactsStatus.loading
                    ? null
                    : () {
                        context.read<EmergencyContactsBloc>().add(
                          const EmergencyContactsRefreshRequested(),
                        );
                      },
                tooltip: 'Làm mới',
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<EmergencyContactsBloc, EmergencyContactsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == EmergencyContactsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Info Banner
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Icon(Ionicons.information_circle_outline, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Liên hệ khẩn cấp sẽ được thông báo khi bạn nhấn nút SOS trong lúc gặp sự cố.',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contact List
              Expanded(
                child: state.contacts.isEmpty
                    ? _EmptyState(onAdd: () => _addContact(context))
                    : RefreshIndicator(
                        onRefresh: () async {
                          context.read<EmergencyContactsBloc>().add(
                            const EmergencyContactsRefreshRequested(),
                          );
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: state.contacts.length,
                          itemBuilder: (context, index) {
                            final contact = state.contacts[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: context.appColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.appColors.border),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      contact.name.isNotEmpty
                                          ? contact.name[0].toUpperCase()
                                          : '?',
                                      style: AppTypography.titleLarge.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      contact.name,
                                      style: AppTypography.titleMedium,
                                    ),
                                    if (contact.isPrimary) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Chính',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                color: AppColors.textWhite,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      contact.phone,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: context.appColors.textSecondary,
                                      ),
                                    ),
                                    if (contact.relationship != null) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.appColors.background,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          contact.relationship!,
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                color: context.appColors.textHint,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Ionicons.trash_outline,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () =>
                                      _deleteContact(context, contact),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton:
          BlocBuilder<EmergencyContactsBloc, EmergencyContactsState>(
            builder: (context, state) {
              if (state.contacts.isNotEmpty) {
                return FloatingActionButton.extended(
                  onPressed: () => _addContact(context),
                  icon: const Icon(Ionicons.add_outline),
                  label: const Text('Thêm liên hệ'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.appColors.background,
              shape: BoxShape.circle,
            ),
            child:   Icon(
              Ionicons.call_outline,
              size: 48,
              color: context.appColors.textHint,
            ),
          ),
          const SizedBox(height: 24),
          Text('Chưa có liên hệ khẩn cấp', style: AppTypography.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Thêm liên hệ để được hỗ trợ khi cần',
            style: AppTypography.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child:  AppButton(
            text: 'Thêm liên hệ đầu tiên',
            icon: Ionicons.add_outline,
            onPressed: onAdd,
          ),),
         
        ],
      ),
    );
  }
}
