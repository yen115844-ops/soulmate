import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profileBloc = getIt<ProfileBloc>();
    if (profileBloc.state is ProfileInitial) {
      profileBloc.add(const ProfileLoadRequested());
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<SettingsBloc>()..add(const SettingsLoadRequested()),
        ),
        BlocProvider.value(value: profileBloc),
      ],
      child: const _SettingsPageContent(),
    );
  }
}

class _SettingsPageContent extends StatefulWidget {
  const _SettingsPageContent();

  @override
  State<_SettingsPageContent> createState() => _SettingsPageContentState();
}

class _SettingsPageContentState extends State<_SettingsPageContent> {
  bool _hasSyncedThemeFromApi = false;

  void _syncThemeFromSettings(dynamic settings) {
    final themeCubit = getIt<ThemeCubit>();
    if (settings.useSystemTheme == true) {
      themeCubit.setThemeMode(ThemeMode.system);
    } else {
      themeCubit.setThemeMode(
        settings.darkModeEnabled == true ? ThemeMode.dark : ThemeMode.light,
      );
    }
  }

  void _showAvatarPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Ionicons.camera_outline),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                Navigator.pop(bottomSheetContext);
                try {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 80,
                  );
                  if (image != null && context.mounted) {
                    context.read<ProfileBloc>().add(
                          ProfileAvatarUpdateRequested(imagePath: image.path),
                        );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Không thể truy cập camera. Vui lòng kiểm tra quyền truy cập.'),
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Ionicons.image_outline),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(bottomSheetContext);
                try {
                  final List<AssetEntity>? assets = await AssetPicker.pickAssets(
                    context,
                    pickerConfig: AssetPickerConfig(
                      maxAssets: 1,
                      requestType: RequestType.image,
                      themeColor: AppColors.primary,
                      textDelegate: const VietnameseAssetPickerTextDelegate(),
                    ),
                  );
                  if (assets != null && assets.isNotEmpty && context.mounted) {
                    final file = await assets.first.file;
                    if (file != null && context.mounted) {
                      context.read<ProfileBloc>().add(
                            ProfileAvatarUpdateRequested(imagePath: file.path),
                          );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Không thể truy cập thư viện ảnh. Vui lòng kiểm tra quyền truy cập.'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: const Text('Cài đặt')),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SettingsError && state.previousSettings == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      Icon(Ionicons.alert_circle_outline, size: 64, color: context.appColors.textHint),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<SettingsBloc>().add(const SettingsLoadRequested());
                      },
                      icon: const Icon(Ionicons.refresh_outline),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is SettingsLoaded) {
            if (!_hasSyncedThemeFromApi) {
              _hasSyncedThemeFromApi = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _syncThemeFromSettings(state.settings);
              });
            }
            return BlocListener<ProfileBloc, ProfileState>(
              listener: (context, profileState) {
                if (profileState is ProfileError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(profileState.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                } else if (profileState is ProfileAvatarUpdateSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã cập nhật ảnh đại diện'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: _SettingsContent(
                settings: state.settings,
                onAvatarTap: () => _showAvatarPicker(context),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  final dynamic settings;
  final VoidCallback? onAvatarTap;

  const _SettingsContent({
    required this.settings,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SettingsBloc>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Section
          _SectionHeader(title: 'Tài khoản'),
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, profileState) {
              final avatarUrl = profileState is ProfileLoaded
                  ? profileState.avatarUrl
                  : null;
              final displayName = profileState is ProfileLoaded
                  ? profileState.displayName
                  : 'Đang tải...';
              final isUpdating = profileState is ProfileUpdating;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isUpdating ? null : onAvatarTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.appColors.card,
                                border: Border.all(
                                  color: context.appColors.border,
                                ),
                              ),
                              child: ClipOval(
                                child: avatarUrl != null && avatarUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: ImageUtils.buildImageUrl(
                                          avatarUrl,
                                        ),
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          color: context.appColors.shimmerBase,
                                        ),
                                        errorWidget: (_, __, ___) =>
                                            _AvatarPlaceholder(),
                                      )
                                    : const _AvatarPlaceholder(),
                              ),
                            ),
                            if (isUpdating)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: context.appColors.textPrimary.withAlpha(128),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.textWhite,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayName,
                                style: AppTypography.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Thay đổi ảnh đại diện',
                                style: AppTypography.bodySmall.copyWith(
                                  color: context.appColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                          Icon(
                          Ionicons.camera_outline,
                          color: context.appColors.textHint,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 92),

          // Notifications Section
          _SectionHeader(title: 'Thông báo'),
          _SettingsTile(
            icon: Ionicons.notifications_outline,
            title: 'Thông báo đẩy',
            subtitle: 'Nhận thông báo về lịch hẹn, tin nhắn',
            trailing: Switch(
              value: settings.pushNotificationsEnabled,
              onChanged: (value) {
                bloc.add(SettingsPushNotificationsChanged(enabled: value));
              },
              activeColor: AppColors.primary,
            ),
          ),
          const Divider(height: 1, indent: 72),
          _SettingsTile(
            icon: Ionicons.chatbubble_outline,
            title: 'Thông báo tin nhắn',
            subtitle: 'Hiển thị nội dung tin nhắn',
            trailing: Switch(
              value: settings.messageNotificationsEnabled,
              onChanged: (value) {
                bloc.add(SettingsMessageNotificationsChanged(enabled: value));
              },
              activeColor: AppColors.primary,
            ),
          ),
          const Divider(height: 1, indent: 72),
          _SettingsTile(
            icon: Ionicons.volume_high_outline,
            title: 'Âm thanh thông báo',
            subtitle: 'Phát âm thanh khi có thông báo',
            trailing: Switch(
              value: settings.soundEnabled,
              onChanged: (value) {
                bloc.add(SettingsSoundChanged(enabled: value));
              },
              activeColor: AppColors.primary,
            ),
          ),

          // Appearance Section
          _SectionHeader(title: 'Giao diện'),
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return _SettingsTile(
                icon: Ionicons.moon_outline,
                title: 'Chế độ tối',
                subtitle: 'Sử dụng giao diện tối',
                trailing: Switch(
                  value: themeState.isDarkMode,
                  onChanged: (value) {
                    context.read<ThemeCubit>().setDarkMode(value);
                    bloc.add(SettingsDarkModeChanged(enabled: value));
                  },
                  activeColor: AppColors.primary,
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 72),
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return _SettingsTile(
                icon: Ionicons.phone_portrait_outline,
                title: 'Theo hệ thống',
                subtitle: 'Tự động chuyển theo cài đặt thiết bị',
                trailing: Switch(
                  value: themeState.isSystemMode,
                  onChanged: (value) {
                    if (value) {
                      context.read<ThemeCubit>().setThemeMode(ThemeMode.system);
                    } else {
                      context.read<ThemeCubit>().setThemeMode(ThemeMode.light);
                    }
                    bloc.add(SettingsUseSystemThemeChanged(enabled: value));
                  },
                  activeColor: AppColors.primary,
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 72),
          _SettingsTile(
            icon: Ionicons.globe_outline,
            title: 'Ngôn ngữ',
            subtitle: settings.languageDisplayName,
            onTap: () => _showLanguageDialog(context, bloc, settings.language),
            trailing:   Icon(
              Ionicons.chevron_forward_outline,
              color: context.appColors.textHint,
              size: 18,
            ),
          ),

          // Privacy Section
          _SectionHeader(title: 'Quyền riêng tư'),
          _SettingsTile(
            icon: Ionicons.location_outline,
            title: 'Vị trí',
            subtitle: 'Cho phép truy cập vị trí của bạn',
            trailing: Switch(
              value: settings.locationEnabled,
              onChanged: (value) {
                bloc.add(SettingsLocationChanged(enabled: value));
              },
              activeColor: AppColors.primary,
            ),
          ),
          const Divider(height: 1, indent: 72),
          _SettingsTile(
            icon: Ionicons.eye_outline,
            title: 'Trạng thái online',
            subtitle: 'Hiển thị khi bạn đang online',
            trailing: Switch(
              value: settings.showOnlineStatus,
              onChanged: (value) {
                bloc.add(SettingsShowOnlineStatusChanged(enabled: value));
              },
              activeColor: AppColors.primary,
            ),
          ),
          const Divider(height: 1, indent: 72),
          _SettingsTile(
            icon: Ionicons.people_outline,
            title: 'Ai có thể nhắn tin cho tôi',
            subtitle: settings.allowMessagesFromDisplayName,
            onTap: () => _showAllowMessagesDialog(context, bloc, settings.allowMessagesFrom),
            trailing:   Icon(
              Ionicons.chevron_forward_outline,
              color: context.appColors.textHint,
              size: 18,
            ),
          ),
          const Divider(height: 1, indent: 72),
          _SettingsTile(
            icon: Ionicons.person_remove_outline,
            title: 'Người dùng đã chặn',
            subtitle: 'Quản lý danh sách người bị chặn',
            onTap: () => context.push(RouteNames.blockedUsers),
            trailing:   Icon(
              Ionicons.chevron_forward_outline,
              color: context.appColors.textHint,
              size: 18,
            ),
          ),

          // Data Section
          _SectionHeader(title: 'Dữ liệu'),
          
          _SettingsTile(
            icon: Ionicons.trash_outline,
            title: 'Xóa bộ nhớ cache',
            subtitle: 'Giải phóng dung lượng',
            onTap: () => _showClearCacheDialog(context),
            trailing:   Icon(
              Ionicons.chevron_forward_outline,
              color: context.appColors.textHint,
              size: 18,
            ),
          ),

          // Destructive actions
          _SectionHeader(title: 'Hành động nguy hiểm'),
          _SettingsTile(
            icon: Ionicons.trash_bin_outline,
            title: 'Xóa tài khoản',
            subtitle: 'Xóa vĩnh viễn tài khoản và mọi dữ liệu',
            titleColor: AppColors.error,
            onTap: () => _showDeleteAccountDialog(context),
            trailing:   Icon(
              Ionicons.chevron_forward_outline,
              color: context.appColors.textHint,
              size: 18,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsBloc bloc, String currentLanguage) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              title: 'Tiếng Việt',
              isSelected: currentLanguage == 'vi',
              onTap: () {
                bloc.add(const SettingsLanguageChanged(language: 'vi'));
                Navigator.pop(dialogContext);
              },
            ),
            _LanguageOption(
              title: 'English',
              isSelected: currentLanguage == 'en',
              onTap: () {
                bloc.add(const SettingsLanguageChanged(language: 'en'));
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAllowMessagesDialog(BuildContext context, SettingsBloc bloc, String currentValue) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ai có thể nhắn tin cho tôi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              title: 'Mọi người',
              isSelected: currentValue == 'everyone',
              onTap: () {
                bloc.add(const SettingsAllowMessagesFromChanged(value: 'everyone'));
                Navigator.pop(dialogContext);
              },
            ),
            _LanguageOption(
              title: 'Người đã xác minh',
              isSelected: currentValue == 'verified',
              onTap: () {
                bloc.add(const SettingsAllowMessagesFromChanged(value: 'verified'));
                Navigator.pop(dialogContext);
              },
            ),
            _LanguageOption(
              title: 'Không ai',
              isSelected: currentValue == 'none',
              onTap: () {
                bloc.add(const SettingsAllowMessagesFromChanged(value: 'none'));
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    try {
      await DefaultCacheManager().emptyCache();
      if (context.mounted) {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa bộ nhớ cache'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xóa cache: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa bộ nhớ cache?'),
        content: const Text(
          'Hành động này sẽ xóa ảnh và dữ liệu tạm thời được lưu trên thiết bị để giải phóng dung lượng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _clearCache(context);
            },
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: authBloc,
        child: _DeleteAccountDialog(parentContext: context),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final BuildContext parentContext;

  const _DeleteAccountDialog({required this.parentContext});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authBloc = context.read<AuthBloc>();

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAccountDeleted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            const SnackBar(
              content: Text('Tài khoản đã được xóa thành công'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is AuthError) {
          setState(() {
            _isLoading = false;
            _errorMessage = state.message;
          });
        } else if (state is AuthDeletingAccount) {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });
        }
      },
      child: AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Text(
              'Hành động này không thể hoàn tác. Tất cả dữ liệu của bạn sẽ bị xóa vĩnh viễn.',
              style: TextStyle(color: context.appColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Nhập mật khẩu để xác nhận',
                errorText: _errorMessage,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Ionicons.eye_off_outline : Ionicons.eye_outline,
                    color: context.appColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              enabled: !_isLoading,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_passwordController.text.isEmpty) {
                      setState(() => _errorMessage = 'Vui lòng nhập mật khẩu');
                      return;
                    }
                    authBloc.add(
                      AuthDeleteAccountRequested(password: _passwordController.text),
                    );
                  },
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.background,
      child:   Icon(
        Ionicons.person_outline,
        size: 28,
        color: context.appColors.textHint,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          color: context.appColors.textSecondary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: titleColor ?? colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: titleColor ?? colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Ionicons.checkmark_circle_outline, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
