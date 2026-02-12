import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../domain/home_filter.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../models/service_category_data.dart';
import 'picker_bottom_sheet.dart';

/// Filter Bottom Sheet — Redesigned with all filter options
class FilterBottomSheet extends StatefulWidget {
  final HomeFilter currentFilter;

  const FilterBottomSheet({super.key, required this.currentFilter});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late double _distance;
  late RangeValues _ageRange;
  late RangeValues _priceRange;
  late Set<String> _selectedServices;
  late String? _selectedGender;
  late String? _selectedCity;
  late String? _selectedDistrict;
  late bool _verifiedOnly;
  late bool _onlineOnly;
  late String _sortBy;

  // Loaded from API
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _districts = [];
  bool _loadingLocations = false;

  @override
  void initState() {
    super.initState();
    final filter = widget.currentFilter;
    _distance = filter.radius?.toDouble() ?? 10;
    _ageRange = RangeValues(
      filter.minAge?.toDouble() ?? 18,
      filter.maxAge?.toDouble() ?? 35,
    );
    _priceRange = RangeValues(
      filter.minRate?.toDouble() ?? 100000,
      filter.maxRate?.toDouble() ?? 1000000,
    );
    _selectedServices = filter.serviceType != null ? {filter.serviceType!} : {};
    _selectedGender = filter.gender;
    _selectedCity = filter.city;
    _selectedDistrict = filter.district;
    _verifiedOnly = filter.verifiedOnly;
    _onlineOnly = filter.availableNow;
    _sortBy = filter.sortBy;
    _loadProvinces();
  }

  static const _genders = [
    (code: 'MALE', label: 'Nam', icon: Ionicons.male_outline),
    (code: 'FEMALE', label: 'Nữ', icon: Ionicons.female_outline),
  ];

  static const _sortOptions = [
    (code: 'rating', label: 'Đánh giá cao', icon: Ionicons.star_outline),
    (
      code: 'price_low',
      label: 'Giá thấp → cao',
      icon: Ionicons.trending_up_outline
    ),
    (
      code: 'price_high',
      label: 'Giá cao → thấp',
      icon: Ionicons.trending_down_outline
    ),
    (code: 'newest', label: 'Mới nhất', icon: Ionicons.time_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.appColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
            child: Row(
              children: [
                Icon(Ionicons.funnel_outline,
                    size: 22, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  'Bộ lọc tìm kiếm',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: Icon(Ionicons.refresh_outline,
                      size: 16, color: AppColors.primary),
                  label: Text(
                    'Đặt lại',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: context.appColors.border),

          // Filters
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Gender ──
                  _buildSection(
                    title: 'Giới tính',
                    icon: Ionicons.people_outline,
                    child: Row(
                      children: [
                        Expanded(
                          child: _GenderChip(
                            label: 'Tất cả',
                            icon: Ionicons.people_outline,
                            selected: _selectedGender == null,
                            onTap: () =>
                                setState(() => _selectedGender = null),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ..._genders.map((g) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: _GenderChip(
                                  label: g.label,
                                  icon: g.icon,
                                  selected: _selectedGender == g.code,
                                  onTap: () => setState(
                                      () => _selectedGender = g.code),
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),

                  // ── Area (Khu vực) ──
                  _buildSection(
                    title: 'Khu vực',
                    icon: Ionicons.map_outline,
                    child: _buildAreaFilter(),
                  ),

                  // ── Distance ──
                  _buildSection(
                    title: 'Khoảng cách',
                    icon: Ionicons.navigate_outline,
                    value: '${_distance.round()} km',
                    child: Column(
                      children: [
                        SliderTheme(
                          data: _sliderTheme,
                          child: Slider(
                            value: _distance,
                            min: 1,
                            max: 50,
                            divisions: 49,
                            label: '${_distance.round()} km',
                            onChanged: (v) =>
                                setState(() => _distance = v),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('1 km',
                                  style:
                                      AppTypography.labelSmall.copyWith(
                                    color:
                                        context.appColors.textSecondary,
                                    fontSize: 11,
                                  )),
                              Text('50 km',
                                  style:
                                      AppTypography.labelSmall.copyWith(
                                    color:
                                        context.appColors.textSecondary,
                                    fontSize: 11,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Age Range ──
                  _buildSection(
                    title: 'Độ tuổi',
                    icon: Ionicons.calendar_outline,
                    value:
                        '${_ageRange.start.round()} - ${_ageRange.end.round()} tuổi',
                    child: Column(
                      children: [
                        SliderTheme(
                          data: _sliderTheme,
                          child: RangeSlider(
                            values: _ageRange,
                            min: 18,
                            max: 50,
                            divisions: 32,
                            labels: RangeLabels(
                              '${_ageRange.start.round()}',
                              '${_ageRange.end.round()}',
                            ),
                            onChanged: (v) =>
                                setState(() => _ageRange = v),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('18 tuổi',
                                  style:
                                      AppTypography.labelSmall.copyWith(
                                    color:
                                        context.appColors.textSecondary,
                                    fontSize: 11,
                                  )),
                              Text('50 tuổi',
                                  style:
                                      AppTypography.labelSmall.copyWith(
                                    color:
                                        context.appColors.textSecondary,
                                    fontSize: 11,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Price Range ──
                  _buildSection(
                    title: 'Mức giá',
                    icon: Ionicons.cash_outline,
                    value:
                        '${priceFormat.format(_priceRange.start.round())} - ${priceFormat.format(_priceRange.end.round())}',
                    child: Column(
                      children: [
                        SliderTheme(
                          data: _sliderTheme,
                          child: RangeSlider(
                            values: _priceRange,
                            min: 50000,
                            max: 2000000,
                            divisions: 39,
                            labels: RangeLabels(
                              priceFormat
                                  .format(_priceRange.start.round()),
                              priceFormat
                                  .format(_priceRange.end.round()),
                            ),
                            onChanged: (v) =>
                                setState(() => _priceRange = v),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('50K',
                                  style:
                                      AppTypography.labelSmall.copyWith(
                                    color:
                                        context.appColors.textSecondary,
                                    fontSize: 11,
                                  )),
                              Text('2.000K',
                                  style:
                                      AppTypography.labelSmall.copyWith(
                                    color:
                                        context.appColors.textSecondary,
                                    fontSize: 11,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Services ──
                  _buildSection(
                    title: 'Dịch vụ',
                    icon: Ionicons.grid_outline,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: serviceCategories.map((s) {
                        final selected =
                            _selectedServices.contains(s.code);
                        return _FilterServiceChip(
                          label: s.label,
                          icon: s.icon,
                          color: s.color,
                          selected: selected,
                          onTap: () => _toggleService(s.code),
                        );
                      }).toList(),
                    ),
                  ),

                  // ── Sort ──
                  _buildSection(
                    title: 'Sắp xếp theo',
                    icon: Ionicons.swap_vertical_outline,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _sortOptions.map((s) {
                        final selected = _sortBy == s.code;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _sortBy = s.code),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : context.appColors.background,
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : context.appColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(s.icon,
                                    size: 16,
                                    color: selected
                                        ? Colors.white
                                        : context.appColors
                                            .textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  s.label,
                                  style: AppTypography.labelMedium
                                      .copyWith(
                                    color: selected
                                        ? Colors.white
                                        : context
                                            .appColors.textPrimary,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // ── Toggles ──
                  _buildToggle(
                    'Chỉ hiện đã xác minh',
                    Ionicons.shield_checkmark_outline,
                    _verifiedOnly,
                    (v) => setState(() => _verifiedOnly = v),
                  ),

                  _buildToggle(
                    'Chỉ hiện đang online',
                    Ionicons.wifi_outline,
                    _onlineOnly,
                    (v) => setState(() => _onlineOnly = v),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Apply + Count
          _buildApplyButton(),
        ],
      ),
    );
  }

  // ───────────────────────── Helper builders ─────────────────────────

  Widget _buildToggle(
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: value
            ? AppColors.primary.withOpacity(0.06)
            : context.appColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? AppColors.primary.withOpacity(0.3)
              : context.appColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: value
                  ? AppColors.primary
                  : context.appColors.textSecondary,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: value ? AppColors.primary : null,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  SliderThemeData get _sliderTheme =>
      SliderTheme.of(context).copyWith(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.primary.withOpacity(0.15),
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.08),
        trackHeight: 4,
        thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 8),
        rangeThumbShape:
            const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
        showValueIndicator: ShowValueIndicator.always,
      );

  void _resetFilters() {
    setState(() {
      _distance = 10;
      _ageRange = const RangeValues(18, 35);
      _priceRange = const RangeValues(100000, 1000000);
      _selectedServices = {};
      _selectedGender = null;
      _selectedCity = null;
      _selectedDistrict = null;
      _districts = [];
      _verifiedOnly = false;
      _onlineOnly = false;
      _sortBy = 'rating';
    });
  }

  void _toggleService(String service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  // ───────────────────────── Location loading ─────────────────────────

  Future<void> _loadProvinces() async {
    if (!mounted) return;
    setState(() => _loadingLocations = true);
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get('/master-data/provinces');
      final rawData = response.data;
      final data = rawData is Map && rawData.containsKey('data')
          ? rawData['data']
          : rawData;
      if (data is List && mounted) {
        _provinces = data.cast<Map<String, dynamic>>();
        if (_selectedCity != null) {
          await _loadDistrictsForCity(_selectedCity!);
        }
      }
    } catch (e) {
      debugPrint('Load provinces error: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingLocations = false);
      }
    }
  }

  Future<void> _loadDistrictsForCity(String cityName) async {
    final province = _provinces.where((p) {
      final name = p['name']?.toString() ?? '';
      return name.toLowerCase().contains(cityName.toLowerCase()) ||
          cityName.toLowerCase().contains(name.toLowerCase());
    }).firstOrNull;

    if (province == null) return;

    try {
      final apiClient = getIt<ApiClient>();
      final provinceId = province['id']?.toString();
      final response = await apiClient.get(
        '/master-data/provinces/$provinceId/districts',
      );
      final rawData = response.data;
      final data = rawData is Map && rawData.containsKey('data')
          ? rawData['data']
          : rawData;
      if (data is List && mounted) {
        setState(() {
          _districts = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Load districts error: $e');
    }
  }

  // ───────────────────────── Area filter ─────────────────────────

  Widget _buildAreaFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown(
          label: 'Tỉnh/Thành phố',
          icon: Ionicons.business_outline,
          value: _selectedCity,
          hint: 'Chọn tỉnh/thành phố',
          isLoading: _loadingLocations,
          items: _provinces.map((p) {
            final name = p['name']?.toString() ?? '';
            return (code: name, label: name);
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCity = value;
              _selectedDistrict = null;
              _districts = [];
            });
            if (value != null) {
              _loadDistrictsForCity(value);
            }
          },
          onClear: () {
            setState(() {
              _selectedCity = null;
              _selectedDistrict = null;
              _districts = [];
            });
          },
        ),
        const SizedBox(height: 12),
        _buildDropdown(
          label: 'Quận/Huyện',
          icon: Ionicons.location_outline,
          value: _selectedDistrict,
          hint: _selectedCity == null
              ? 'Chọn tỉnh/thành trước'
              : 'Chọn quận/huyện',
          enabled: _selectedCity != null,
          items: _districts.map((d) {
            final name = d['name']?.toString() ?? '';
            return (code: name, label: name);
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedDistrict = value);
          },
          onClear: () {
            setState(() => _selectedDistrict = null);
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required String hint,
    required List<({String code, String label})> items,
    required ValueChanged<String?> onChanged,
    VoidCallback? onClear,
    bool enabled = true,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: enabled && !isLoading
          ? () => _showPickerSheet(
                context: context,
                title: label,
                icon: icon,
                items: items,
                selectedValue: value,
                onSelect: onChanged,
              )
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: value != null
              ? AppColors.primary.withOpacity(0.06)
              : context.appColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value != null
                ? AppColors.primary.withOpacity(0.3)
                : context.appColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: value != null
                  ? AppColors.primary
                  : enabled
                      ? context.appColors.textSecondary
                      : context.appColors.textHint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: context.appColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? hint,
                    style: AppTypography.bodyMedium.copyWith(
                      color: value != null
                          ? context.appColors.textPrimary
                          : context.appColors.textHint,
                      fontWeight: value != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (value != null && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Ionicons.close_circle,
                    size: 20, color: AppColors.primary),
              )
            else
              Icon(
                Ionicons.chevron_down_outline,
                size: 18,
                color: enabled
                    ? context.appColors.textSecondary
                    : context.appColors.textHint,
              ),
          ],
        ),
      ),
    );
  }

  void _showPickerSheet({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<({String code, String label})> items,
    required String? selectedValue,
    required ValueChanged<String?> onSelect,
  }) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PickerBottomSheet(
        title: title,
        icon: icon,
        items: items,
        selectedValue: selectedValue,
        onSelect: (value) {
          Navigator.pop(context, value);
        },
      ),
    ).then((value) {
      if (value != null && mounted) {
        onSelect(value);
      }
    });
  }

  // ───────────────────────── Section wrapper ─────────────────────────

  Widget _buildSection({
    required String title,
    required IconData icon,
    String? value,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ───────────────────────── Apply button ─────────────────────────

  int get _activeFilterCount {
    int count = 0;
    if (_selectedGender != null) count++;
    if (_distance != 10) count++;
    if (_ageRange.start != 18 || _ageRange.end != 35) count++;
    if (_priceRange.start != 100000 || _priceRange.end != 1000000) count++;
    if (_selectedServices.isNotEmpty) count++;
    if (_selectedCity != null || _selectedDistrict != null) count++;
    if (_verifiedOnly) count++;
    if (_onlineOnly) count++;
    if (_sortBy != 'rating') count++;
    return count;
  }

  Widget _buildApplyButton() {
    final count = _activeFilterCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        boxShadow: [
          BoxShadow(
            color: context.appColors.textPrimary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (count > 0) ...[
              SizedBox(
                height: 54,
                width: 54,
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child:
                      const Icon(Ionicons.trash_outline, size: 20),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _applyFilter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    count > 0
                        ? 'Áp dụng ($count bộ lọc)'
                        : 'Xem tất cả kết quả',
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilter() {
    final filter = HomeFilter(
      radius: _distance.round() != 10 ? _distance.round() : null,
      minAge:
          _ageRange.start.round() != 18 ? _ageRange.start.round() : null,
      maxAge:
          _ageRange.end.round() != 35 ? _ageRange.end.round() : null,
      minRate: _priceRange.start.round() != 100000
          ? _priceRange.start.round()
          : null,
      maxRate: _priceRange.end.round() != 1000000
          ? _priceRange.end.round()
          : null,
      serviceType: _selectedServices.isNotEmpty
          ? _selectedServices.first
          : null,
      gender: _selectedGender,
      city: _selectedCity,
      district: _selectedDistrict,
      verifiedOnly: _verifiedOnly,
      availableNow: _onlineOnly,
      sortBy: _sortBy,
    );

    context.read<HomeBloc>().add(HomeApplyFilter(filter));
    Navigator.pop(context);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Private helper widgets used only within FilterBottomSheet
// ═══════════════════════════════════════════════════════════════════════

/// Gender selection chip
class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary : context.appColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected ? AppColors.primary : context.appColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : context.appColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: selected
                    ? Colors.white
                    : context.appColors.textPrimary,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Service chip used in the filter bottom sheet
class _FilterServiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterServiceChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
