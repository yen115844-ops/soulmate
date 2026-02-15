import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../shared/bloc/master_data_bloc.dart';
import '../../../../shared/data/models/master_data_models.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  @override
  void initState() {
    super.initState();
    // Dispatch load once (not in build) to avoid jank and duplicate API calls
    final profileBloc = getIt<ProfileBloc>();
    if (profileBloc.state is ProfileInitial) {
      profileBloc.add(const ProfileLoadRequested());
    }
    final masterDataBloc = getIt<MasterDataBloc>();
    if (masterDataBloc.state is MasterDataInitial) {
      masterDataBloc.add(const MasterDataLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ProfileBloc>()),
        BlocProvider.value(value: getIt<MasterDataBloc>()),
        BlocProvider.value(value: getIt<AuthBloc>()),
      ],
      child: const _EditProfileContent(),
    );
  }
}

class _EditProfileContent extends StatefulWidget {
  const _EditProfileContent();

  @override
  State<_EditProfileContent> createState() => _EditProfileContentState();
}

class _EditProfileContentState extends State<_EditProfileContent> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _birthday;
  String? _gender;
  int? _heightCm;
  int? _weightKg;

  // Selected IDs from master data
  String? _selectedProvinceId;
  String? _selectedDistrictId;
  List<String> _selectedLanguageIds = [];
  List<String> _selectedInterestIds = [];
  List<String> _selectedTalentIds = [];

  // Temporary storage for city/district names from profile
  String? _savedCityName;
  String? _savedDistrictName;
  bool _hasInitializedLocation = false;

  bool _isInitialized = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initializeFromUser(UserModel user) {
    if (_isInitialized) return;

    final profile = user.profile;
    if (profile != null) {
      _fullNameController.text = profile.fullName ?? '';
      _displayNameController.text = profile.displayName ?? '';
      _bioController.text = profile.bio ?? '';
      _addressController.text = profile.address ?? '';
      _birthday = profile.dateOfBirth;
      _gender = profile.gender;
      _heightCm = profile.heightCm;
      _weightKg = profile.weightKg;

      // Store city/district names to match with master data later
      _savedCityName = profile.city;
      _savedDistrictName = profile.district;

      // Use provinceId/districtId from profile if available
      if (profile.provinceId != null && profile.provinceId!.isNotEmpty) {
        _selectedProvinceId = profile.provinceId;
      }
      if (profile.districtId != null && profile.districtId!.isNotEmpty) {
        _selectedDistrictId = profile.districtId;
      }

      // These will be populated when master data is loaded
      // For now, store the names as temporary identifiers
      _selectedLanguageIds = List<String>.from(profile.languages);
      _selectedInterestIds = List<String>.from(profile.interests);
      _selectedTalentIds = List<String>.from(profile.talents);
    }
    _isInitialized = true;
  }

  /// Initialize location selection when master data is loaded
  void _initializeLocationFromMasterData(MasterDataLoaded state) {
    if (_hasInitializedLocation) return;
    
    // If we already have provinceId from profile, use it directly
    if (_selectedProvinceId != null && _selectedProvinceId!.isNotEmpty) {
      // Verify it exists in loaded provinces
      final exists = state.provinces.any((p) => p.id == _selectedProvinceId);
      if (exists) {
        // Load districts for this province
        context.read<MasterDataBloc>().add(DistrictsLoadRequested(_selectedProvinceId!));
      } else {
        _selectedProvinceId = null;
      }
    } else if (_savedCityName != null && _savedCityName!.isNotEmpty) {
      // Fallback: find province by name (for backward compatibility)
      final province = state.provinces.firstWhere(
        (p) => p.name == _savedCityName || p.code == _savedCityName,
        orElse: () => ProvinceModel(id: '', code: '', name: ''),
      );
      
      if (province.id.isNotEmpty) {
        _selectedProvinceId = province.id;
        context.read<MasterDataBloc>().add(DistrictsLoadRequested(province.id));
      }
    }
    
    _hasInitializedLocation = true;
  }

  /// Initialize district selection when districts are loaded
  void _initializeDistrictFromMasterData(MasterDataLoaded state) {
    // If we already have a valid districtId from profile, verify it exists
    if (_selectedDistrictId != null && _selectedDistrictId!.isNotEmpty) {
      final exists = state.districts.any((d) => d.id == _selectedDistrictId);
      if (!exists) {
        _selectedDistrictId = null;
      }
      return;
    }
    
    if (_savedDistrictName == null || _savedDistrictName!.isEmpty) return;
    
    // Fallback: find district by name
    final district = state.districts.firstWhere(
      (d) => d.name == _savedDistrictName || d.code == _savedDistrictName,
      orElse: () => DistrictModel(id: '', provinceId: '', code: '', name: ''),
    );
    
    if (district.id.isNotEmpty) {
      setState(() {
        _selectedDistrictId = district.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật hồ sơ thành công'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is ProfileAvatarUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật ảnh đại diện thành công'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading) {
          return Scaffold(
            appBar: AppBar(leading: const AppBackButton(), title: const Text('Chỉnh sửa hồ sơ')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileLoaded) {
          _initializeFromUser(state.user);
          return _buildForm(context, state.user, isUpdating: false);
        }

        if (state is ProfileUpdating) {
          return _buildForm(context, null, isUpdating: true);
        }

        if (state is ProfileError) {
          return Scaffold(
            appBar: AppBar(leading: const AppBackButton(), title: const Text('Chỉnh sửa hồ sơ')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(Ionicons.alert_circle_outline,
                      size: 64, color: context.appColors.textHint),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<ProfileBloc>()
                          .add(const ProfileLoadRequested());
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildForm(BuildContext context, UserModel? user,
      {required bool isUpdating}) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Chỉnh sửa hồ sơ'),
        actions: [
          if (isUpdating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Lưu',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: BlocConsumer<MasterDataBloc, MasterDataState>(
        listener: (context, masterDataState) {
          if (masterDataState is MasterDataLoaded) {
            // Initialize location when provinces are loaded
            _initializeLocationFromMasterData(masterDataState);
            
            // Initialize district when districts are loaded
            if (masterDataState.districts.isNotEmpty) {
              _initializeDistrictFromMasterData(masterDataState);
            }
          }
        },
        builder: (context, masterDataState) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Section
                  _buildAvatarSection(user?.profile?.avatarUrl),
                  const SizedBox(height: 32),

                  // Basic Info
                  _buildSectionTitle('Thông tin cơ bản'),
                  const SizedBox(height: 16),

                  _FormField(
                    label: 'Họ và tên',
                    child: TextFormField(
                      controller: _fullNameController,
                      decoration: _inputDecoration('Nhập họ và tên'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập họ và tên';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  _FormField(
                    label: 'Tên hiển thị',
                    child: TextFormField(
                      controller: _displayNameController,
                      decoration: _inputDecoration('Tên hiển thị công khai'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _FormField(
                    label: 'Ngày sinh',
                    child: _buildDatePicker(),
                  ),
                  const SizedBox(height: 16),

                  _FormField(
                    label: 'Giới tính',
                    child: _buildGenderSelector(),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _FormField(
                          label: 'Chiều cao (cm)',
                          child: TextFormField(
                            initialValue: _heightCm?.toString() ?? '',
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('VD: 170'),
                            onChanged: (value) {
                              _heightCm = int.tryParse(value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _FormField(
                          label: 'Cân nặng (kg)',
                          child: TextFormField(
                            initialValue: _weightKg?.toString() ?? '',
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('VD: 60'),
                            onChanged: (value) {
                              _weightKg = int.tryParse(value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bio
                  _buildSectionTitle('Giới thiệu bản thân'),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration:
                        _inputDecoration('Viết vài dòng về bản thân...')
                            .copyWith(
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location
                  _buildSectionTitle('Địa chỉ'),
                  const SizedBox(height: 16),

                  if (masterDataState is MasterDataLoaded)
                    _buildLocationSection(masterDataState)
                  else if (masterDataState is MasterDataLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildLocationFallback(),

                  const SizedBox(height: 24),

                  // Languages
                  _buildSectionTitle('Ngôn ngữ'),
                  const SizedBox(height: 16),
                  if (masterDataState is MasterDataLoaded)
                    _buildLanguageSelector(masterDataState.languages)
                  else
                    _buildLoadingChips(),
                  const SizedBox(height: 24),

                  // Interests
                  _buildSectionTitle('Sở thích'),
                  const SizedBox(height: 16),
                  if (masterDataState is MasterDataLoaded)
                    _buildInterestSelector(masterDataState.interests)
                  else
                    _buildLoadingChips(),
                  const SizedBox(height: 24),

                  // Talents
                  _buildSectionTitle('Tài năng'),
                  const SizedBox(height: 16),
                  if (masterDataState is MasterDataLoaded)
                    _buildTalentSelector(masterDataState.talents)
                  else
                    _buildLoadingChips(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationSection(MasterDataLoaded state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FormField(
                label: 'Tỉnh/Thành phố',
                child: _buildProvinceDropdown(state.provinces),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FormField(
                label: 'Quận/Huyện',
                child: _buildDistrictDropdown(state.districts),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FormField(
          label: 'Địa chỉ chi tiết',
          child: TextFormField(
            controller: _addressController,
            decoration: _inputDecoration('Số nhà, đường...'),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationFallback() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FormField(
                label: 'Tỉnh/Thành phố',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: context.appColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.appColors.border),
                  ),
                  child: Text(
                    'Đang tải...',
                    style: AppTypography.bodyLarge
                        .copyWith(color: context.appColors.textHint),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FormField(
                label: 'Quận/Huyện',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: context.appColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.appColors.border),
                  ),
                  child: Text(
                    'Đang tải...',
                    style: AppTypography.bodyLarge
                        .copyWith(color: context.appColors.textHint),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FormField(
          label: 'Địa chỉ chi tiết',
          child: TextFormField(
            controller: _addressController,
            decoration: _inputDecoration('Số nhà, đường...'),
          ),
        ),
      ],
    );
  }

  Widget _buildProvinceDropdown(List<ProvinceModel> provinces) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProvinceId,
          isExpanded: true,
          hint: Text(
            'Chọn tỉnh/thành',
            style:
                AppTypography.bodyLarge.copyWith(color: context.appColors.textHint),
          ),
          items: provinces.map((province) {
            return DropdownMenuItem(
              value: province.id,
              child: Text(province.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedProvinceId = value;
              _selectedDistrictId = null;
            });
            if (value != null) {
              context.read<MasterDataBloc>().add(DistrictsLoadRequested(value));
            }
          },
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown(List<DistrictModel> districts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDistrictId,
          isExpanded: true,
          hint: Text(
            _selectedProvinceId == null ? 'Chọn tỉnh trước' : 'Chọn quận/huyện',
            style:
                AppTypography.bodyLarge.copyWith(color: context.appColors.textHint),
          ),
          items: districts.map((district) {
            return DropdownMenuItem(
              value: district.id,
              child: Text(district.name),
            );
          }).toList(),
          onChanged: _selectedProvinceId == null
              ? null
              : (value) {
                  setState(() => _selectedDistrictId = value);
                },
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(List<LanguageModel> languages) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: languages.map((language) {
        final isSelected = _selectedLanguageIds.contains(language.name) ||
            _selectedLanguageIds.contains(language.id);
        return FilterChip(
          label: Text('${language.name} ${language.nativeName != null && language.nativeName != language.name ? "(${language.nativeName})" : ""}'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedLanguageIds.add(language.name);
              } else {
                _selectedLanguageIds.remove(language.name);
                _selectedLanguageIds.remove(language.id);
              }
            });
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : context.appColors.textSecondary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInterestSelector(List<InterestModel> interests) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.map((interest) {
        final isSelected = _selectedInterestIds.contains(interest.name) ||
            _selectedInterestIds.contains(interest.id);
        return FilterChip(
          avatar: interest.icon != null
              ? Text(interest.icon!, style: const TextStyle(fontSize: 14))
              : null,
          label: Text(interest.name),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedInterestIds.add(interest.name);
              } else {
                _selectedInterestIds.remove(interest.name);
                _selectedInterestIds.remove(interest.id);
              }
            });
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : context.appColors.textSecondary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTalentSelector(List<TalentModel> talents) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: talents.map((talent) {
        final isSelected = _selectedTalentIds.contains(talent.name) ||
            _selectedTalentIds.contains(talent.id);
        return FilterChip(
          avatar: talent.icon != null
              ? Text(talent.icon!, style: const TextStyle(fontSize: 14))
              : null,
          label: Text(talent.name),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTalentIds.add(talent.name);
              } else {
                _selectedTalentIds.remove(talent.name);
                _selectedTalentIds.remove(talent.id);
              }
            });
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : context.appColors.textSecondary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        6,
        (index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: context.appColors.shimmerBase,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const SizedBox(width: 60, height: 16),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(String? avatarUrl) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ImageUtils.buildImageUrl(avatarUrl),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: context.appColors.shimmerBase,
                      ),
                      errorWidget: (context, url, error) =>
                          _buildAvatarPlaceholder(),
                    )
                  : _buildAvatarPlaceholder(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.appColors.surface,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Ionicons.camera_outline,
                  color: AppColors.textWhite,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: context.appColors.background,
      child:   Icon(
        Ionicons.person_outline,
        size: 48,
        color: context.appColors.textHint,
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _birthday ?? DateTime(1995),
          firstDate: DateTime(1950),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
        );
        if (date != null) {
          setState(() => _birthday = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.appColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _birthday != null
                  ? '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}'
                  : 'Chọn ngày sinh',
              style: AppTypography.bodyLarge.copyWith(
                color: _birthday != null
                    ? context.appColors.textPrimary
                    : context.appColors.textHint,
              ),
            ),
              Icon(Ionicons.calendar_outline, color: context.appColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    final genders = [
      ('MALE', 'Nam'),
      ('FEMALE', 'Nữ'),
      ('OTHER', 'Khác'),
    ];

    return Row(
      children: genders.map((g) {
        final isSelected = _gender == g.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _gender = g.$1),
            child: Container(
              margin: EdgeInsets.only(
                right: g.$1 != 'OTHER' ? 12 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : context.appColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.appColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  g.$2,
                  style: AppTypography.labelLarge.copyWith(
                    color: isSelected
                        ? AppColors.textWhite
                        : context.appColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyLarge.copyWith(
        color: context.appColors.textHint,
      ),
      filled: true,
      fillColor: context.appColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: context.appColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide(color: context.appColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Future<void> _pickAvatar() async {
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
                  if (image != null && mounted) {
                    context.read<ProfileBloc>().add(
                          ProfileAvatarUpdateRequested(imagePath: image.path),
                        );
                  }
                } catch (e) {
                  if (mounted) {
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
                  if (assets != null && assets.isNotEmpty && mounted) {
                    final file = await assets.first.file;
                    if (file != null && mounted) {
                      context.read<ProfileBloc>().add(
                            ProfileAvatarUpdateRequested(imagePath: file.path),
                          );
                    }
                  }
                } catch (e) {
                  if (mounted) {
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

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    // Get province and district names from master data state
    String? cityName;
    String? districtName;

    final masterDataState = context.read<MasterDataBloc>().state;
    if (masterDataState is MasterDataLoaded) {
      if (_selectedProvinceId != null) {
        final province = masterDataState.provinces
            .firstWhere((p) => p.id == _selectedProvinceId,
                orElse: () => ProvinceModel(id: '', code: '', name: ''));
        cityName = province.name.isNotEmpty ? province.name : null;
      }
      if (_selectedDistrictId != null) {
        final district = masterDataState.districts
            .firstWhere((d) => d.id == _selectedDistrictId,
                orElse: () =>
                    DistrictModel(id: '', provinceId: '', code: '', name: ''));
        districtName = district.name.isNotEmpty ? district.name : null;
      }
    }

    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(
            fullName: _fullNameController.text.trim(),
            displayName: _displayNameController.text.trim().isNotEmpty
                ? _displayNameController.text.trim()
                : null,
            bio: _bioController.text.trim().isNotEmpty
                ? _bioController.text.trim()
                : null,
            gender: _gender,
            dateOfBirth: _birthday,
            heightCm: _heightCm,
            weightKg: _weightKg,
            provinceId: _selectedProvinceId,
            districtId: _selectedDistrictId,
            city: cityName,
            district: districtName,
            address: _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : null,
            languages:
                _selectedLanguageIds.isNotEmpty ? _selectedLanguageIds : null,
            interests:
                _selectedInterestIds.isNotEmpty ? _selectedInterestIds : null,
            talents:
                _selectedTalentIds.isNotEmpty ? _selectedTalentIds : null,
          ),
        );
  }

}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
