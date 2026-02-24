import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/common/loading_overlay.dart';
import '../../data/credits_repository.dart';
import '../../data/models/credits_models.dart';
import '../bloc/credits_bloc.dart';
import '../bloc/credits_event.dart';
import '../bloc/credits_state.dart';

class CreditsPage extends StatefulWidget {
  const CreditsPage({super.key});

  @override
  State<CreditsPage> createState() => _CreditsPageState();
}

class _CreditsPageState extends State<CreditsPage> {
  late final CreditsBloc _bloc;
  CreditWallet? _cachedWallet;
  List<CreditPackage> _cachedPackages = [];

  @override
  void initState() {
    super.initState();
    _bloc = CreditsBloc(repository: getIt<CreditsRepository>());
    _bloc.add(const LoadCredits());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<CreditsBloc, CreditsState>(
        listener: (context, state) {
          // Cache data from states that carry wallet/packages
          if (state is CreditsLoaded) {
            _cachedWallet = state.wallet;
            _cachedPackages = state.packages;
          } else if (state is CreditsError && state.wallet != null) {
            _cachedWallet = state.wallet;
            _cachedPackages = state.packages;
          }

          if (state is CreditsPurchaseSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Đã nhận ${state.creditsReceived} xu!',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is CreditsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state is CreditsLoading || state is CreditsPurchasing,
            child: Scaffold(
              backgroundColor: context.appColors.background,
              appBar: AppBar(
                leadingWidth: 56,
                leading: const AppBackButton(),
                title: Text(
                  'Xu',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Ionicons.time_outline),
                    onPressed: () => context.push('/credits/history'),
                    tooltip: 'Lịch sử giao dịch',
                  ),
                ],
              ),
              body: _buildBody(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CreditsState state) {
    // Use data directly from CreditsLoaded state
    if (state is CreditsLoaded) {
      return _buildContent(context, state.wallet, state.packages);
    }

    // For intermediate states (loading, purchasing), show cached content
    if (_cachedWallet != null) {
      return _buildContent(context, _cachedWallet!, _cachedPackages);
    }

    // Error without any cached data (initial load failed)
    if (state is CreditsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.warning_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(state.message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            AppButton(
              text: 'Thử lại',
              onPressed: () => _bloc.add(const LoadCredits()),
              isOutlined: true,
            ),
          ],
        ),
      );
    }

    // Initial loading - no cached data yet, LoadingOverlay shows indicator
    return const SizedBox.shrink();
  }

  Widget _buildContent(
    BuildContext context,
    CreditWallet wallet,
    List<CreditPackage> packages,
  ) {
    return CustomScrollView(
      slivers: [
        // Balance Card
        SliverToBoxAdapter(
          child: Container(
            margin: ResponsiveLayout.pagePadding(context),
            padding: ResponsiveLayout.pagePadding(context),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Số dư hiện tại',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Ionicons.diamond,
                      color: Colors.amber,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${wallet.balance}',
                      style: AppTypography.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' xu',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '≈ ${_formatCurrency(wallet.balanceInVnd)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white54,
                  ),
                ),
                if (wallet.pendingBalance > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${wallet.pendingBalance} xu đang giữ (escrow)',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Section Title
        SliverToBoxAdapter(
          child: Padding(
            padding: ResponsiveLayout.pagePadding(context).copyWith(top: 8, bottom: 16),
            child: Text(
              'Mua Xu',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Credit Packages
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: ResponsiveLayout.horizontalPadding(context)),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildPackageCard(context, packages[index]),
              childCount: packages.length,
            ),
          ),
        ),

        // Exchange Rate Info
        SliverToBoxAdapter(
          child: Padding(
            padding: ResponsiveLayout.pagePadding(context),
            child: Container(
              padding: EdgeInsets.all(ResponsiveLayout.horizontalPadding(context)),
              decoration: BoxDecoration(
                color: context.appColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Ionicons.information_circle_outline,
                    color: context.appColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '1 Xu = ${_formatCurrency(creditToVndRate)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildPackageCard(BuildContext context, CreditPackage package) {
    return GestureDetector(
      onTap: () => _purchasePackage(package),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: package.isBestValue ? AppColors.primary : context.appColors.border,
            width: package.isBestValue ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Credits icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Ionicons.diamond,
                color: Colors.amber,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Package info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${package.totalCredits} Xu',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (package.bonusCredits > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${package.bonusCredits} bonus',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (package.isBestValue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Hot',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (package.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      package.description!,
                      style: AppTypography.bodySmall.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(package.priceVnd.toInt()),
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                if (package.discountPercent != null && package.discountPercent! > 0)
                  Text(
                    '-${package.discountPercent}%',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _purchasePackage(CreditPackage package) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PurchaseConfirmSheet(
        package: package,
        onConfirm: () {
          Navigator.of(ctx).pop();
          _bloc.add(PurchaseCredits(packageId: package.id));
        },
      ),
    );
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M đ';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K đ';
    }
    return '$amount đ';
  }
}

class _PurchaseConfirmSheet extends StatelessWidget {
  final CreditPackage package;
  final VoidCallback onConfirm;

  const _PurchaseConfirmSheet({
    required this.package,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(ResponsiveLayout.horizontalPadding(context), 12, ResponsiveLayout.horizontalPadding(context), 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
    
            // Title
            Text(
              'Xác nhận mua Xu',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
    
            // Package icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Ionicons.diamond,
                color: Colors.amber,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
    
            // Package name
            Text(
              '${package.totalCredits} Xu',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (package.bonusCredits > 0) ...[
              const SizedBox(height: 4),
              Text(
                '(${package.creditAmount} + ${package.bonusCredits} bonus)',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 20),
    
            // Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    'Gói',
                    package.nameVi,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    'Giá',
                    _formatPrice(package.priceVnd.toInt()),
                    valueColor: AppColors.primary,
                    valueBold: true,
                  ),
                  if (package.discountPercent != null &&
                      package.discountPercent! > 0) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      context,
                      'Giảm giá',
                      '-${package.discountPercent}%',
                      valueColor: AppColors.success,
                    ),
                  ],
                  if (package.description != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(context, 'Mô tả', package.description!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
    
            // Confirm button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Xác nhận mua - ${_formatPrice(package.priceVnd.toInt())}',
                onPressed: onConfirm,
              ),
            ),
            const SizedBox(height: 12),
    
            // Cancel
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Hủy',
                onPressed: () => Navigator.of(context).pop(),
                isOutlined: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor,
              fontWeight: valueBold ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatPrice(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M đ';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K đ';
    }
    return '$amount đ';
  }
}
