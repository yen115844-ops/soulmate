import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../partner/domain/entities/partner_entity.dart';
import '../../../profile/profile.dart';
import '../../domain/home_filter.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_empty_state.dart';
import '../widgets/home_loading_shimmer.dart';
import '../widgets/partner_card.dart';
import '../widgets/quick_filter_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/service_categories_section.dart';
import '../widgets/sort_bottom_sheet.dart';

/// Trang Home - Modern Mioto-style UI
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profileBloc = getIt<ProfileBloc>();
    if (profileBloc.state is ProfileInitial) {
      profileBloc.add(const ProfileLoadRequested());
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<HomeBloc>()..add(const HomeLoadPartners()),
        ),
        BlocProvider.value(value: profileBloc),
      ],
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
      if (_selectedService == code) {
        _selectedService = null;
        context.read<HomeBloc>().add(const HomeResetFilter());
      } else {
        _selectedService = code;
        context.read<HomeBloc>().add(
              HomeApplyFilter(HomeFilter(serviceType: code)),
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
                ),
              ),

              // Quick filter chips
              SliverToBoxAdapter(
                child: QuickFilterBar(
                  state: state,
                  onFilterTap: _showFilter,
                  onSortTap: _showSortPicker,
                ),
              ),

              // Section header
              SliverToBoxAdapter(
                child: HomeSectionHeader(
                  state: state,
                  selectedService: _selectedService,
                  onClearFilter: _resetFilters,
                ),
              ),

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

  SliverList _buildPartnerList(List<PartnerEntity> partners) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final partner = partners[index];
          return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: GestureDetector(
                  onTap: () => _onPartnerTap(partner),
                  child: PartnerCard(partner: partner),
                ),
              )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 60 * (index % 8)),
                duration: 350.ms,
              )
              .slideY(begin: 0.05, end: 0);
        },
        childCount: partners.length,
      ),
    );
  }
}
