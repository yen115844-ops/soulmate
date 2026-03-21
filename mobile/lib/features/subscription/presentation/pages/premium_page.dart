import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/iap_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/buttons/app_back_button.dart';
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
  bool _isFetchingProducts = false;
  String? _iapLoadError;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  bool get _iapInitialized => _iapService.isAvailable;

  Future<void> _initializeIAP() async {
    // IAP already initialized in main; ensure callbacks are set for this page
    if (!_iapService.isAvailable) {
      debugPrint('IAP: Store not available');
      return;
    }

    _iapService.onPurchaseSuccess = _handlePurchaseSuccess;
    _iapService.onPurchaseError = _handleSimplePurchaseError;
    _iapService.onPurchaseErrorWithDetails = _handlePurchaseError;
    _iapService.onPurchasePending = _handlePurchasePending;
    _iapService.onPurchaseRestored = _handlePurchaseRestored;
    _iapService.onPurchaseCancelled = _handlePurchaseCancelled;

    if (!mounted) return;
    setState(() {});
    final plans = context.read<SubscriptionBloc>().state.plans;
    if (plans.isNotEmpty) {
      await _fetchIAPProducts(plans);
    }
  }

  void _handlePurchaseSuccess(PurchaseDetails purchase) {
    final receiptData = _iapService.getReceiptData(purchase);
    if (receiptData != null && mounted) {
      context.read<SubscriptionBloc>().add(
        SubscriptionPurchaseCompleted(
          platform: _iapService.platform,
          productId: purchase.productID,
          receiptData: receiptData,
          transactionId: purchase.purchaseID,
        ),
      );
    }
  }

  void _handleSimplePurchaseError(String error) {
    if (mounted) {
      context.read<SubscriptionBloc>().add(
        const SubscriptionPurchaseCancelled(),
      );
    }
  }

  void _handlePurchaseError(PurchaseDetails purchase, String error) {
    if (mounted) {
      context.read<SubscriptionBloc>().add(
        const SubscriptionPurchaseCancelled(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  void _handlePurchaseCancelled() {
    if (mounted) {
      context.read<SubscriptionBloc>().add(
        const SubscriptionPurchaseCancelled(),
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

    if (mounted) {
      setState(() {
        _isFetchingProducts = true;
        _iapLoadError = null;
      });
    }

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
      if (mounted) {
        setState(() {
          _isFetchingProducts = false;
          _iapLoadError = 'Chưa cấu hình mã sản phẩm IAP.';
        });
      }
      return;
    }

    final products = await _iapService.fetchProducts(productIds);
    if (!mounted) return;

    setState(() {
      _iapProducts = products;
      _isFetchingProducts = false;
      _iapLoadError = products.isEmpty
          ? 'Không thể tải gói từ App Store. Vui lòng kiểm tra Sandbox account và thử lại.'
          : null;
    });
  }

  Future<void> _purchasePlan(SubscriptionPlanEntity plan) async {
    final subscriptionBloc = context.read<SubscriptionBloc>();

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

    ProductDetails? product = _iapService.getProduct(productId);
    if (product == null) {
      await _fetchIAPProducts(subscriptionBloc.state.plans);
      if (!mounted) return;
      product = _iapService.getProduct(productId);
    }

    if (product == null) {
      final notFoundIds = _iapService.lastNotFoundIDs;
      final isNotApproved = notFoundIds.contains(productId);
      String message = 'Không tìm thấy sản phẩm';
      if (kDebugMode) {
        message = 'Không tìm thấy sản phẩm ($productId). ';
        if (isNotApproved) {
          message +=
              'Sản phẩm có thể chưa duyệt trên App Store. Để test: mở project bằng Xcode → Edit Scheme → Run → Options → StoreKit Configuration chọn file .storekit có cùng product ID.';
        } else {
          message +=
              'Kiểm tra appleProductId trong backend khớp với App Store Connect.';
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 6),
          ),
        );
      }
      return;
    }

    // Start purchase
    subscriptionBloc.add(
      SubscriptionPurchaseRequested(planId: plan.id, productId: productId),
    );

    final started = await _iapService.purchaseProductDetails(product);
    if (!started && mounted) {
      subscriptionBloc.add(const SubscriptionPurchaseCancelled());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể bắt đầu giao dịch. Vui lòng thử lại.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
        if (state.plans.isNotEmpty &&
            _iapProducts.isEmpty &&
            _iapInitialized &&
            !_isFetchingProducts) {
          _fetchIAPProducts(state.plans);
        }

        if (state.status == SubscriptionStateStatus.success &&
            state.premiumStatus?.isPremium == true) {
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
          body: ResponsiveCenterWrapper(
            maxContentWidth: 560,
            child: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SubscriptionState state) {
    if (state.status == SubscriptionStateStatus.loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    // Check if user is already Premium
    if (state.premiumStatus?.isPremium == true) {
      return _buildAlreadyPremium(context, state);
    }

    return _buildPremiumOffer(context, state);
  }

  Widget _buildAlreadyPremium(BuildContext context, SubscriptionState state) {
    final premiumUntil = state.premiumStatus?.premiumUntil;
    final activeSubscription = state.premiumStatus?.activeSubscription;
    final activePlan = activeSubscription?.plan;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final daysRemaining = activeSubscription?.daysRemaining ?? 0;

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
              color: AppColors.accentGradient,
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

          // Current plan info card
          _buildCurrentPlanCard(
            context,
            activePlan: activePlan,
            premiumUntil: premiumUntil,
            daysRemaining: daysRemaining,
            dateFormat: dateFormat,
          ),
          const SizedBox(height: 24),

          // Benefits section
          _buildBenefitsCard(context),
          const SizedBox(height: 24),

          // Change plan section
          _buildChangePlanSection(context, state),
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

          // Manage subscription via App Store / Google Play
          TextButton.icon(
            onPressed: _openSubscriptionManagement,
            icon: Icon(
              Platform.isIOS ? Ionicons.logo_apple : Ionicons.logo_google_playstore,
              size: 18,
              color: context.appColors.textSecondary,
            ),
            label: Text(
              Platform.isIOS
                  ? 'Quản lý trong App Store'
                  : 'Quản lý trong Google Play',
              style: AppTypography.bodyMedium.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(
    BuildContext context, {
    required SubscriptionPlanEntity? activePlan,
    required DateTime? premiumUntil,
    required int daysRemaining,
    required DateFormat dateFormat,
  }) {
    final priceFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Ionicons.pricetag, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Gói hiện tại',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Plan name
          if (activePlan != null) ...[
            _buildInfoRow(
              context,
              icon: Ionicons.diamond_outline,
              label: 'Gói',
              value: activePlan.nameVi.isNotEmpty
                  ? activePlan.nameVi
                  : activePlan.name,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              context,
              icon: Ionicons.cash_outline,
              label: 'Giá',
              value: priceFormat.format(activePlan.priceVnd),
            ),
            const SizedBox(height: 10),
          ],

          // Expiry
          if (premiumUntil != null) ...[
            _buildInfoRow(
              context,
              icon: Ionicons.calendar_outline,
              label: 'Hết hạn',
              value: dateFormat.format(premiumUntil),
            ),
            const SizedBox(height: 10),
          ],

          // Days remaining
          if (daysRemaining > 0)
            _buildInfoRow(
              context,
              icon: Ionicons.time_outline,
              label: 'Còn lại',
              value: '$daysRemaining ngày',
              valueColor: daysRemaining <= 7
                  ? AppColors.warning
                  : AppColors.success,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.appColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: AppTypography.bodyMedium.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? context.appColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildChangePlanSection(BuildContext context, SubscriptionState state) {
    final plans = state.plans;
    if (plans.isEmpty) return const SizedBox.shrink();

    final activePlanCode = state.premiumStatus?.activeSubscription?.plan.code;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              Icon(Ionicons.swap_horizontal, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Thay đổi gói',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Nâng cấp hoặc thay đổi gói Premium phù hợp với bạn',
            style: AppTypography.bodySmall.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...plans.map((plan) {
            final isCurrentPlan = plan.code == activePlanCode;
            return _buildChangePlanItem(context, plan, isCurrentPlan);
          }),
        ],
      ),
    );
  }

  Widget _buildChangePlanItem(
    BuildContext context,
    SubscriptionPlanEntity plan,
    bool isCurrentPlan,
  ) {
    final priceFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrentPlan
            ? AppColors.primary.withValues(alpha: 0.08)
            : context.appColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentPlan
              ? AppColors.primary.withValues(alpha: 0.4)
              : context.appColors.border,
          width: isCurrentPlan ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      plan.nameVi.isNotEmpty ? plan.nameVi : plan.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    if (isCurrentPlan) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Hiện tại',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (plan.discountPercent != null && plan.discountPercent! > 0)
                  Text(
                    'Tiết kiệm ${plan.discountPercent}%',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            priceFormat.format(plan.priceVnd),
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: isCurrentPlan
                  ? AppColors.primary
                  : context.appColors.textPrimary,
            ),
          ),
          if (!isCurrentPlan) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _purchasePlan(plan),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Đổi',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openSubscriptionManagement() {
    final uri = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');
    launchUrl(uri, mode: LaunchMode.externalApplication);
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
              Icon(Ionicons.sparkles, color: AppColors.primary, size: 22),
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
          _buildBenefitRow(
            context,
            Ionicons.infinite,
            'Nhắn tin không giới hạn',
          ),
          _buildBenefitRow(context, Ionicons.rocket, 'Ưu tiên ghép cặp'),
          _buildBenefitRow(context, Ionicons.eye, 'Tăng hiển thị profile'),
          _buildBenefitRow(
            context,
            Ionicons.heart_circle,
            'Xem ai đã quan tâm bạn',
          ),
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
          const SizedBox(height: 12),

          // Apple-required: Subscription terms disclosure
          _buildSubscriptionDisclosure(context, state),
          if (_iapLoadError != null) ...[
            const SizedBox(height: 12),
            _buildIAPStatusHint(context),
          ],
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
            color: AppColors.accentGradient,
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

  // ignore: unused_element
  Widget _buildDevIAPHint(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Ionicons.code_slash, color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dev: Sản phẩm IAP chưa trả về từ store. Để test: dùng Xcode → Edit Scheme → Run → Options → StoreKit Configuration → chọn file .storekit (product ID khớp backend).',
              style: AppTypography.bodySmall.copyWith(
                color: context.appColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
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

    final isBestValue = _findBestValuePlan(allPlans)?.id == plan.id;

    // Display name: prefer API nameVi (e.g. "Premium 1 tuần"), fallback to duration-based label
    String durationLabel;
    if (plan.isWeekly) {
      durationLabel = '1 Tuần';
    } else if (plan.durationMonths == 1) {
      durationLabel = '1 Tháng';
    } else {
      durationLabel = '${plan.durationMonths} Tháng';
    }
    final displayName = plan.nameVi.isNotEmpty ? plan.nameVi : durationLabel;

    final cardColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.1)
        : (isBestValue
              ? AppColors.primary.withValues(alpha: 0.05)
              : context.appColors.surface);
    final borderColor = isSelected
        ? AppColors.primary
        : (isBestValue
              ? AppColors.primary.withValues(alpha: 0.4)
              : context.appColors.border);

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
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
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
                  color: isSelected
                      ? AppColors.primary
                      : context.appColors.border,
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
                  Text(
                    displayName,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.appColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  // Show subscription duration (Apple requirement)
                  Text(
                    plan.isWeekly
                        ? 'Tự động gia hạn mỗi tuần'
                        : plan.durationMonths == 1
                        ? 'Tự động gia hạn mỗi tháng'
                        : 'Tự động gia hạn mỗi ${plan.durationMonths} tháng',
                    style: AppTypography.bodySmall.copyWith(
                      color: context.appColors.textSecondary,
                      fontSize: 11,
                    ),
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

            // Price - hiển thị VND từ backend
            Text(
              priceFormat.format(plan.priceVnd),
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.primary
                    : context.appColors.textPrimary,
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
    final selectedProductId = Platform.isIOS
        ? selectedPlan.appleProductId
        : selectedPlan.googleProductId;
    final hasStoreProduct =
        selectedProductId != null &&
        _iapService.getProduct(selectedProductId) != null;
    final isReadyToPurchase = _iapInitialized && hasStoreProduct;
    final isPreparingProducts = !_iapInitialized || _isFetchingProducts;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isProcessing
            ? null
            : isReadyToPurchase
            ? () => _purchasePlan(selectedPlan)
            : (!isPreparingProducts && state.plans.isNotEmpty)
            ? () => _fetchIAPProducts(state.plans)
            : null,
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
            : isPreparingProducts
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Đang tải gói...',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : !isReadyToPurchase
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Ionicons.refresh_outline, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Tải lại gói',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
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

  Widget _buildIAPStatusHint(BuildContext context) {
    if (_iapLoadError == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Text(
        _iapLoadError!,
        style: AppTypography.bodySmall.copyWith(
          color: context.appColors.textSecondary,
          height: 1.3,
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
          SizedBox(height: 16),
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
          _buildFeatureItem(
            context,
            Ionicons.infinite,
            'Nhắn tin không giới hạn',
            'Chat thoải mái mọi lúc',
          ),
          _buildFeatureItem(
            context,
            Ionicons.rocket,
            'Ưu tiên ghép cặp',
            'Được đề xuất nhiều hơn',
          ),
          _buildFeatureItem(
            context,
            Ionicons.eye,
            'Boost hồ sơ',
            'Tăng khả năng hiển thị',
          ),
          _buildFeatureItem(
            context,
            Ionicons.heart_circle,
            'Ai đã quan tâm bạn',
            'Xem danh sách người thích',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
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

  /// Build subscription disclosure text required by Apple (Guideline 3.1.2)
  Widget _buildSubscriptionDisclosure(
    BuildContext context,
    SubscriptionState state,
  ) {
    final selectedPlan = state.plans.isNotEmpty
        ? state.plans.firstWhere(
            (p) => p.id == _selectedPlanId,
            orElse: () => state.plans.first,
          )
        : null;

    if (selectedPlan == null) return const SizedBox.shrink();

    final priceFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final displayPrice = priceFormat.format(selectedPlan.priceVnd);

    // Subscription duration text
    String durationText;
    if (selectedPlan.isWeekly) {
      durationText = '1 tuần';
    } else if (selectedPlan.durationMonths == 1) {
      durationText = '1 tháng';
    } else {
      durationText = '${selectedPlan.durationMonths} tháng';
    }

    // Subscription title
    final subscriptionTitle = selectedPlan.nameVi.isNotEmpty
        ? selectedPlan.nameVi
        : 'Premium $durationText';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Apple-required: Subscription name, duration, and price
          Text(
            'Thông tin đăng ký:',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '• Gói: $subscriptionTitle\n'
            '• Thời hạn: $durationText\n'
            '• Giá: $displayPrice/$durationText',
            style: AppTypography.bodySmall.copyWith(
              color: context.appColors.textSecondary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Platform.isIOS
                ? 'Thanh toán sẽ được tính vào tài khoản iTunes của bạn khi xác nhận mua. '
                      'Đăng ký sẽ tự động gia hạn trừ khi bạn tắt tự động gia hạn ít nhất 24 giờ trước khi hết hạn hiện tại. '
                      'Tài khoản sẽ bị tính phí gia hạn trong vòng 24 giờ trước thời điểm hết hạn. '
                      'Bạn có thể quản lý và hủy đăng ký trong phần Cài đặt tài khoản trên App Store sau khi mua.'
                : 'Thanh toán sẽ được tính vào tài khoản Google Play của bạn khi xác nhận mua. '
                      'Đăng ký sẽ tự động gia hạn trừ khi bạn hủy trước 24 giờ khi hết hạn hiện tại. '
                      'Bạn có thể quản lý và hủy đăng ký trong Google Play Store.',
            textAlign: TextAlign.left,
            style: AppTypography.bodySmall.copyWith(
              color: context.appColors.textHint,
              fontSize: 10,
              height: 1.4,
            ),
          ),
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
              : Icon(
                  Ionicons.refresh_outline,
                  size: 18,
                  color: AppColors.primary,
                ),
          label: Text(
            'Khôi phục mua hàng',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),

        // Required: functional links to Terms of Use (EULA) and Privacy Policy (Guideline 3.1.2)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appColors.border),
          ),
          child: Column(
            children: [
              Text(
                'Bằng việc đăng ký, bạn đồng ý với:',
                style: AppTypography.bodySmall.copyWith(
                  color: context.appColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              // Terms of Use (EULA) link
              InkWell(
                onTap: () => context.push(RouteNames.termsOfService),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Ionicons.document_text_outline,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Điều khoản sử dụng (EULA)',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Privacy Policy link
              InkWell(
                onTap: () => context.push(RouteNames.privacyPolicy),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Ionicons.shield_checkmark_outline,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Chính sách bảo mật',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Apple Standard EULA link (external)
              if (Platform.isIOS)
                InkWell(
                  onTap: () => launchUrl(
                    Uri.parse(
                      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Ionicons.logo_apple,
                          size: 14,
                          color: context.appColors.textHint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Apple Standard EULA',
                          style: AppTypography.bodySmall.copyWith(
                            color: context.appColors.textHint,
                            fontSize: 10,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  SubscriptionPlanEntity? _findBestValuePlan(
    List<SubscriptionPlanEntity> plans,
  ) {
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
      builder: (dialogContext) => Dialog(
        backgroundColor: context.appColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.accentGradient,
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
              Text(
                'Chào mừng VIP!',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentGradient,
                  letterSpacing: 1,
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
              const SizedBox(height: 24),
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
        ),
      ),
    );
  }
}
