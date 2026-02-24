import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
import '../../data/services/iap_service.dart';
import '../../domain/entities/subscription_entity.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';

/// Premium Subscription Page
/// Displays subscription plans and allows users to purchase Premium
class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SubscriptionBloc>()
        ..add(const SubscriptionPlansRequested())
        ..add(const SubscriptionStatusRequested()),
      child: const _PremiumPageContent(),
    );
  }
}

class _PremiumPageContent extends StatefulWidget {
  const _PremiumPageContent();

  @override
  State<_PremiumPageContent> createState() => _PremiumPageContentState();
}

class _PremiumPageContentState extends State<_PremiumPageContent> {
  String? _selectedPlanId;
  final IAPService _iapService = getIt<IAPService>();
  List<ProductDetails> _iapProducts = [];
  bool _iapInitialized = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    // Initialize IAP service
    final available = await _iapService.initialize();
    if (!available) {
      debugPrint('IAP: Store not available');
      return;
    }

    // Set up callbacks
    _iapService.onPurchaseSuccess = _handlePurchaseSuccess;
    _iapService.onPurchaseError = _handlePurchaseError;
    _iapService.onPurchasePending = _handlePurchasePending;
    _iapService.onPurchaseRestored = _handlePurchaseRestored;

    setState(() {
      _iapInitialized = true;
    });
  }

  void _handlePurchaseSuccess(PurchaseDetails purchase) {
    final receiptData = _iapService.getReceiptData(purchase);
    if (receiptData != null && mounted) {
      context.read<SubscriptionBloc>().add(
        SubscriptionPurchaseCompleted(
          platform: _iapService.platform,
          productId: purchase.productID,
          receiptData: receiptData,
        ),
      );
    }
  }

  void _handlePurchaseError(PurchaseDetails purchase, String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handlePurchasePending(PurchaseDetails purchase) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang xử lý giao dịch...'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  void _handlePurchaseRestored(PurchaseDetails purchase) {
    final receiptData = _iapService.getReceiptData(purchase);
    if (receiptData != null && mounted) {
      context.read<SubscriptionBloc>().add(
        SubscriptionRestoreRequested(
          platform: _iapService.platform,
          receiptData: receiptData,
        ),
      );
    }
  }

  Future<void> _fetchIAPProducts(List<SubscriptionPlanEntity> plans) async {
    if (!_iapInitialized || plans.isEmpty) return;

    // Get product IDs from plans
    final productIds = <String>{};
    for (final plan in plans) {
      final productId = Platform.isIOS
          ? plan.appleProductId
          : plan.googleProductId;
      if (productId != null && productId.isNotEmpty) {
        productIds.add(productId);
      }
    }

    if (productIds.isEmpty) {
      debugPrint('IAP: No product IDs configured');
      return;
    }

    _iapProducts = await _iapService.fetchProducts(productIds);
    if (mounted) setState(() {});
  }

  Future<void> _purchasePlan(SubscriptionPlanEntity plan) async {
    if (!_iapInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cửa hàng không khả dụng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final productId = Platform.isIOS
        ? plan.appleProductId
        : plan.googleProductId;

    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gói này chưa được cấu hình'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final product = _iapService.getProduct(productId);
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy sản phẩm'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Start purchase
    context.read<SubscriptionBloc>().add(
      SubscriptionPurchaseRequested(
        planId: plan.id,
        productId: productId,
      ),
    );

    await _iapService.purchaseProduct(product);
  }

  Future<void> _restorePurchases() async {
    if (!_iapInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cửa hàng không khả dụng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isRestoring = true;
    });

    await _iapService.restorePurchases();

    if (mounted) {
      setState(() {
        _isRestoring = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã khôi phục mua hàng'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state.error != null) {
          debugPrint('IAP Error: ${state.error}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.error,
            ),
          );
        }

        // Fetch IAP products when plans are loaded
        if (state.plans.isNotEmpty && _iapProducts.isEmpty && _iapInitialized) {
          _fetchIAPProducts(state.plans);
        }

        if (state.status == SubscriptionStateStatus.success && state.premiumStatus?.isPremium == true) {
          _showSuccessDialog(context);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.appColors.background,
          appBar: AppBar(
            backgroundColor: context.appColors.background,
            elevation: 0,
            leading: const AppBackButton(),
            title: Text(
              'Premium',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: context.appColors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SubscriptionState state) {
    if (state.status == SubscriptionStateStatus.loading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    // Check if user is already Premium
    if (state.premiumStatus?.isPremium == true) {
      return _buildAlreadyPremium(context, state);
    }

    return _buildPremiumOffer(context, state);
  }

  Widget _buildAlreadyPremium(BuildContext context, SubscriptionState state) {
    final premiumUntil = state.premiumStatus?.premiumUntil;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: ResponsiveLayout.pagePadding(context),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Premium Crown
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.accentGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.diamond_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Bạn là VIP!',
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tận hưởng đặc quyền Premium',
            style: AppTypography.bodyMedium.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Expiry date card
          if (premiumUntil != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Ionicons.calendar_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Hết hạn: ${dateFormat.format(premiumUntil)}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),

          // Benefits section
          _buildBenefitsCard(context),
          const SizedBox(height: 24),

          // Restore purchases
          TextButton.icon(
            onPressed: _isRestoring ? null : _restorePurchases,
            icon: _isRestoring
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(
                    Ionicons.refresh_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
            label: Text(
              'Khôi phục mua hàng',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard(BuildContext context) {
    return Container(
      padding: ResponsiveLayout.pagePadding(context),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Ionicons.sparkles,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Đặc quyền của bạn',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBenefitRow(context, Ionicons.infinite, 'Nhắn tin không giới hạn'),
          _buildBenefitRow(context, Ionicons.rocket, 'Ưu tiên ghép cặp'),
          _buildBenefitRow(context, Ionicons.eye, 'Tăng hiển thị profile'),
          _buildBenefitRow(context, Ionicons.heart_circle, 'Xem ai đã quan tâm bạn'),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(BuildContext context, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
          ),
          Icon(Ionicons.checkmark_circle, color: AppColors.success, size: 20),
        ],
      ),
    );
  }

  Widget _buildPremiumOffer(BuildContext context, SubscriptionState state) {
    return SingleChildScrollView(
      padding: ResponsiveLayout.pagePadding(context),
      child: Column(
        children: [
          // Header
          _buildPremiumHeader(context),
          const SizedBox(height: 24),

          // Plans section FIRST (before features)
          _buildPlansSection(context, state),
          const SizedBox(height: 24),

          // Purchase button
          _buildPurchaseButton(context, state),
          const SizedBox(height: 24),

          // Features section (below plans)
          _buildFeaturesSection(context),
          const SizedBox(height: 24),

          // Footer
          _buildFooter(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Column(
      children: [
        // Crown icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.accentGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(
            Icons.diamond_rounded,
            size: 42,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Title
        Text(
          'Nâng cấp Premium',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mở khóa tất cả tính năng độc quyền',
          style: AppTypography.bodyMedium.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlansSection(BuildContext context, SubscriptionState state) {
    final plans = state.plans;

    if (plans.isEmpty) {
      return const SizedBox.shrink();
    }

    // Set default selected plan (best value)
    _selectedPlanId ??= _findBestValuePlan(plans)?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Ionicons.pricetag, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Chọn gói phù hợp',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: context.appColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Vertical list of plans (no fixed height)
        ...plans.map((plan) => _buildPlanCard(context, plan, plans)),
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    SubscriptionPlanEntity plan,
    List<SubscriptionPlanEntity> allPlans,
  ) {
    final isSelected = _selectedPlanId == plan.id;
    final priceFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    final isPopular = plan.code == 'premium_3m';
    final isBestValue = _findBestValuePlan(allPlans)?.id == plan.id;

    // Calculate duration label
    String durationLabel;
    if (plan.isWeekly) {
      durationLabel = '1 Tuần';
    } else if (plan.durationMonths == 1) {
      durationLabel = '1 Tháng';
    } else {
      durationLabel = '${plan.durationMonths} Tháng';
    }

    // Calculate savings
    final monthlyPlan = allPlans.where((p) => p.code == 'premium_1m').firstOrNull;
    int? savingsPercent;
    if (monthlyPlan != null && plan.durationMonths > 1) {
      final monthlyRate = monthlyPlan.priceVnd;
      final thisMonthlyRate = plan.monthlyPrice;
      savingsPercent = ((1 - (thisMonthlyRate / monthlyRate)) * 100).round();
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanId = plan.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : context.appColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.appColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.appColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),

            // Plan info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        durationLabel,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🔥 Phổ biến',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ] else if (isBestValue && savingsPercent != null && savingsPercent > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '💎 -$savingsPercent%',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (plan.durationMonths > 1)
                    Text(
                      '${priceFormat.format(plan.monthlyPrice.round())}/tháng',
                      style: AppTypography.bodySmall.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            // Price
            Text(
              priceFormat.format(plan.priceVnd),
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : context.appColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(BuildContext context, SubscriptionState state) {
    if (state.plans.isEmpty) {
      return const SizedBox.shrink();
    }

    final isProcessing = state.status == SubscriptionStateStatus.purchasing;
    final selectedPlan = state.plans.firstWhere(
      (p) => p.id == _selectedPlanId,
      orElse: () => state.plans.first,
    );

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isProcessing ? null : () => _purchasePlan(selectedPlan),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isProcessing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.diamond_rounded, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Đăng ký ngay',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      padding: ResponsiveLayout.pagePadding(context),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Ionicons.sparkles, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Quyền lợi Premium',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(context, Ionicons.infinite, 'Nhắn tin không giới hạn', 'Chat thoải mái mọi lúc'),
          _buildFeatureItem(context, Ionicons.rocket, 'Ưu tiên ghép cặp', 'Được đề xuất nhiều hơn'),
          _buildFeatureItem(context, Ionicons.eye, 'Boost hồ sơ', 'Tăng khả năng hiển thị'),
          _buildFeatureItem(context, Ionicons.heart_circle, 'Ai đã quan tâm bạn', 'Xem danh sách người thích'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Ionicons.checkmark_circle, color: AppColors.success, size: 22),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        // Restore purchases
        TextButton.icon(
          onPressed: _isRestoring ? null : _restorePurchases,
          icon: _isRestoring
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Icon(Ionicons.refresh_outline, size: 18, color: AppColors.primary),
          label: Text(
            'Khôi phục mua hàng',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Terms text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Thanh toán sẽ được tính vào tài khoản Apple/Google của bạn. Đăng ký sẽ tự động gia hạn trừ khi bạn hủy trước 24h.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: context.appColors.textHint,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Links
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              child: Text(
                'Điều khoản',
                style: AppTypography.bodySmall.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
            Text('•', style: TextStyle(color: context.appColors.textHint)),
            TextButton(
              onPressed: () {},
              child: Text(
                'Chính sách',
                style: AppTypography.bodySmall.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  SubscriptionPlanEntity? _findBestValuePlan(List<SubscriptionPlanEntity> plans) {
    if (plans.isEmpty) return null;

    SubscriptionPlanEntity? bestPlan;
    double? lowestPricePerMonth;

    for (final plan in plans) {
      if (plan.totalDays <= 0) continue;
      final pricePerMonth = plan.priceVnd / (plan.totalDays / 30);
      if (lowestPricePerMonth == null || pricePerMonth < lowestPricePerMonth) {
        lowestPricePerMonth = pricePerMonth;
        bestPlan = plan;
      }
    }

    return bestPlan ?? plans.firstOrNull;
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.appColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.diamond_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => AppColors.accentGradient.createShader(bounds),
              child: Text(
                'Chào mừng VIP!',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn đã nâng cấp thành công!\nHãy tận hưởng các đặc quyền Premium.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: context.appColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Bắt đầu trải nghiệm',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
