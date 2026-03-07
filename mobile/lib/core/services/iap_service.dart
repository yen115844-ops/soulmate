import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

/// Unified IAP Service for credits (consumable) and subscription (non-consumable).
/// Single instance, initialized once in main.
class IAPService {
  static IAPService? _instance;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  Map<String, ProductDetails> _productsMap = {};
  Set<String> _lastNotFoundIDs = {};

  // Callbacks – credits use onPurchaseSuccess, onPurchaseError(String), onPurchaseCancelled
  void Function(PurchaseDetails purchase)? onPurchaseSuccess;
  void Function(String error)? onPurchaseError;
  void Function()? onPurchaseCancelled;
  // Callbacks – subscription use these too
  void Function(PurchaseDetails purchase)? onPurchasePending;
  void Function(PurchaseDetails purchase)? onPurchaseRestored;
  void Function(PurchaseDetails purchase, String error)? onPurchaseErrorWithDetails;

  IAPService._();

  static IAPService get instance {
    _instance ??= IAPService._();
    return _instance!;
  }

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _productsMap.values.toList();

  /// Product by ID from last load/fetch
  ProductDetails? getProduct(String productId) => _productsMap[productId];

  /// IDs not found in last fetch (e.g. not yet approved on store)
  Set<String> get lastNotFoundIDs => Set.from(_lastNotFoundIDs);

  String get platform => Platform.isIOS ? 'ios' : 'android';

  /// Initialize the IAP service (call once from main).
  Future<bool> initialize() async {
    _isAvailable = await _iap.isAvailable();

    if (!_isAvailable) {
      debugPrint('IAP not available on this device');
      return false;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: _onPurchaseStreamDone,
      onError: _onPurchaseStreamError,
    );

    // iOS: finish any pending transactions from previous session
    if (Platform.isIOS) {
      try {
        final paymentWrapper = SKPaymentQueueWrapper();
        final transactions = await paymentWrapper.transactions();
        for (final transaction in transactions) {
          await paymentWrapper.finishTransaction(transaction);
        }
      } catch (e) {
        debugPrint('IAP iOS finishTransaction: $e');
      }
    }

    debugPrint('IAP Service initialized');
    return true;
  }

  /// Load/fetch products by IDs. Updates _productsMap and _lastNotFoundIDs.
  Future<List<ProductDetails>> loadProducts(List<String> productIds) async {
    if (!_isAvailable) {
      debugPrint('IAP not available');
      return [];
    }
    final set = productIds.toSet();
    final response = await _iap.queryProductDetails(set);
    _lastNotFoundIDs = response.notFoundIDs.toSet();
    if (_lastNotFoundIDs.isNotEmpty) {
      debugPrint('Products not found: $_lastNotFoundIDs');
    }
    if (response.error != null) {
      debugPrint('Error loading products: ${response.error}');
      return [];
    }
    _productsMap = {
      for (final product in response.productDetails) product.id: product,
    };
    debugPrint('Loaded ${_productsMap.length} products: ${_productsMap.keys.toList()}');
    return _productsMap.values.toList();
  }

  /// Alias for subscription: fetch by set, returns list
  Future<List<ProductDetails>> fetchProducts(Set<String> productIds) async {
    return loadProducts(productIds.toList());
  }

  /// Purchase consumable (credits). Use [purchaseNonConsumable] for subscription.
  Future<bool> purchaseProduct(String productId) async {
    return _purchase(productId, consumable: true);
  }

  /// Purchase non-consumable (subscription).
  Future<bool> purchaseNonConsumable(String productId) async {
    return _purchase(productId, consumable: false);
  }

  /// Purchase by ProductDetails (subscription page). Uses product.id.
  Future<bool> purchaseProductDetails(ProductDetails product) async {
    return purchaseNonConsumable(product.id);
  }

  Future<bool> _purchase(String productId, {required bool consumable}) async {
    if (!_isAvailable) {
      onPurchaseError?.call('IAP không khả dụng trên thiết bị này');
      return false;
    }

    final product = _productsMap[productId];
    if (product == null) {
      onPurchaseError?.call('Sản phẩm không tìm thấy: $productId');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      if (consumable) {
        return await _iap.buyConsumable(
          purchaseParam: purchaseParam,
          autoConsume: true,
        );
      } else {
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      debugPrint('Purchase failed: $e');
      onPurchaseError?.call('Không thể thực hiện mua hàng');
      return false;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      _handlePurchase(purchase);
    }
  }

  void _handlePurchase(PurchaseDetails purchase) async {
    debugPrint('Purchase update: ${purchase.productID} - ${purchase.status}');

    switch (purchase.status) {
      case PurchaseStatus.pending:
        onPurchasePending?.call(purchase);
        break;

      case PurchaseStatus.purchased:
        final valid = await _verifyPurchase(purchase);
        if (valid) {
          onPurchaseSuccess?.call(purchase);
        } else {
          final msg = 'Xác thực giao dịch thất bại';
          onPurchaseError?.call(msg);
          onPurchaseErrorWithDetails?.call(purchase, msg);
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;

      case PurchaseStatus.restored:
        onPurchaseRestored?.call(purchase);
        final valid = await _verifyPurchase(purchase);
        if (valid) {
          onPurchaseSuccess?.call(purchase);
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;

      case PurchaseStatus.error:
        final msg = purchase.error?.message ?? 'Có lỗi xảy ra';
        onPurchaseError?.call(msg);
        onPurchaseErrorWithDetails?.call(purchase, msg);
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;

      case PurchaseStatus.canceled:
        onPurchaseCancelled?.call();
        break;
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    return purchase.verificationData.localVerificationData.isNotEmpty ||
        purchase.verificationData.serverVerificationData.isNotEmpty;
  }

  /// Receipt/data for server verification. Prefer serverVerificationData when available.
  String? getReceiptData(PurchaseDetails purchase) {
    final server = purchase.verificationData.serverVerificationData;
    if (server.isNotEmpty) return server;
    if (Platform.isIOS) {
      return purchase.verificationData.localVerificationData;
    }
    return purchase.verificationData.serverVerificationData;
  }

  String? getTransactionId(PurchaseDetails purchase) {
    return purchase.purchaseID;
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    await _iap.restorePurchases();
  }

  void _onPurchaseStreamDone() {
    _subscription?.cancel();
  }

  void _onPurchaseStreamError(dynamic error) {
    debugPrint('Purchase stream error: $error');
  }

  void dispose() {
    _subscription?.cancel();
  }
}

/// Extension for getting product by ID
extension ProductDetailsExtension on List<ProductDetails> {
  ProductDetails? findById(String id) {
    for (final product in this) {
      if (product.id == id) return product;
    }
    return null;
  }
}
