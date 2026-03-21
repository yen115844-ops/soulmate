import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/app_deep_link_service.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/image_warmup_service.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';
import '../../../partner/domain/entities/partner_entity.dart';
import '../../../subscription/presentation/widgets/premium_banner.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_empty_state.dart';
import '../widgets/home_loading_shimmer.dart';
import '../widgets/home_partner_card.dart';
import '../widgets/quick_filter_bar.dart';
import '../widgets/service_categories_section.dart';
import '../widgets/sort_bottom_sheet.dart';

/// Trang Home - Modern Mioto-style UI
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeBloc>()
        ..add(const HomeLoadServiceTypes())
        ..add(const HomeDetectLocation())
        ..add(const HomeLoadPartners()),
      child: const _HomePageView(),
    );
  }
}

class _HomePageView extends StatefulWidget {
  const _HomePageView();

  @override
  State<_HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<_HomePageView> {
  late ScrollController _scrollController;
  String? _selectedService;
  String _lastWarmupKey = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    final deepLink = DeepLinkService();
    if (!deepLink.isAppReady) {
      deepLink.markAppReady();
    }
    if (deepLink.hasPendingDeepLink) {
      Future.delayed(const Duration(milliseconds: 300), () {
        deepLink.processPendingDeepLink();
      });
    }

    // Process pending URL-based deep links (App Links / Universal Links)
    Future.delayed(const Duration(milliseconds: 500), () {
      AppDeepLinkService().processPendingDeepLink();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ───────────────────────── Callbacks ─────────────────────────

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final bloc = context.read<HomeBloc>();
      if (bloc.state.hasMore && !bloc.state.isLoadingMore) {
        bloc.add(const HomeLoadMore());
      }
    }
  }

  void _onPartnerTap(PartnerEntity partner) {
    HapticFeedback.mediumImpact();
    context.push('/partner/${partner.id}');
  }

  void _onServiceTap(String code) {
    setState(() {
      final bloc = context.read<HomeBloc>();
      if (_selectedService == code) {
        _selectedService = null;
        bloc.add(
          HomeApplyFilter(bloc.state.filter.clear(clearServiceType: true)),
        );
      } else {
        _selectedService = code;
        bloc.add(
          HomeApplyFilter(bloc.state.filter.copyWith(serviceType: code)),
        );
      }
    });
  }

  void _showFilter() {
    final currentFilter = context.read<HomeBloc>().state.filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<HomeBloc>(),
        child: FilterBottomSheet(currentFilter: currentFilter),
      ),
    );
  }

  void _showSortPicker() {
    final currentSort = context.read<HomeBloc>().state.filter.sortBy;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<HomeBloc>(),
        child: SortBottomSheet(currentSort: currentSort),
      ),
    );
  }

  void _resetFilters() {
    setState(() => _selectedService = null);
    context.read<HomeBloc>().add(const HomeResetFilter());
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state.hasError && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red.shade400,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }

          if (!state.isSuccess || state.partners.isEmpty) return;

          final warmupKey = state.partners.take(6).map((p) => p.id).join('|');
          if (warmupKey.isEmpty || warmupKey == _lastWarmupKey) return;

          _lastWarmupKey = warmupKey;

          final imageUrls = state.partners
              .take(16)
              .map((p) => p.gallery.isNotEmpty ? p.gallery.first : p.avatarUrl)
              .where((url) => url.trim().isNotEmpty)
              .toList(growable: false);

          ImageWarmupService.instance.warmupImages(
            context: context,
            imageUrls: imageUrls,
            maxImages: 16,
            targetWidth: 800,
          );
        },
        builder: (context, state) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Modern App Bar with search
              HomeAppBar(onSearchTap: _showFilter),

              // Service categories horizontal scroll
              SliverToBoxAdapter(
                child: ServiceCategoriesSection(
                  selectedService: _selectedService,
                  onServiceTap: _onServiceTap,
                  serviceTypes: state.serviceTypes,
                ),
              ),

              // Premium banner - promotes Premium subscription
              const SliverToBoxAdapter(child: PremiumBanner()),

              // Quick filter chips
              SliverToBoxAdapter(
                child: QuickFilterBar(
                  state: state,
                  onFilterTap: _showFilter,
                  onSortTap: _showSortPicker,
                ),
              ),

           // sizedbox heigth
              const SliverToBoxAdapter(child: SizedBox(height: 15)),

              // Partner list
              if (state.isLoading)
                const SliverToBoxAdapter(child: HomeLoadingShimmer())
              else if (state.partners.isEmpty)
                SliverToBoxAdapter(
                  child: HomeEmptyState(onResetFilter: _resetFilters),
                )
              else ...[
                _buildPartnerList(state.partners),
                if (state.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
              ],

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPartnerList(List<PartnerEntity> partners) {
    final crossAxisCount = ResponsiveLayout.gridCrossAxisCount(
      context,
      minCellWidth: 320,
      horizontalPadding: ResponsiveLayout.horizontalPadding(context) * 2,
      spacing: 16,
    );
    final padding = ResponsiveLayout.horizontalPadding(context);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(padding, 0, padding, 16),
      sliver: SliverAlignedGrid.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemCount: partners.length,
        itemBuilder: (context, index) {
          final partner = partners[index];
          return GestureDetector(
                onTap: () => _onPartnerTap(partner),
                child: HomePartnerCard(partner: partner),
              )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 60 * (index % 8)),
                duration: 350.ms,
              )
              .slideY(begin: 0.05, end: 0);
        },
      ),
    );
  }
}
