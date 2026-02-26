import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

/// IAP Service - handles all In-App Purchase operations
class IAPService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  
  // Callbacks
  Function(PurchaseDetails)? onPurchaseSuccess;
  Function(PurchaseDetails, String)? onPurchaseError;
  Function(PurchaseDetails)? onPurchasePending;
  Function(PurchaseDetails)? onPurchaseRestored;
  
  // Cached products
  List<ProductDetails> _products = [];
  /// Product IDs that were requested but not found by the store (e.g. not yet approved).
  Set<String> _lastNotFoundIDs = {};
  bool _isAvailable = false;

  /// Initialize IAP and start listening to purchase updates
  Future<bool> initialize() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    
    if (!_isAvailable) {
      debugPrint('IAP: Store not available');
      return false;
    }

    // Listen to purchase updates
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (error) => debugPrint('IAP Error: $error'),
    );

    // iOS: Complete any pending transactions from previous session
    if (Platform.isIOS) {
      final paymentWrapper = SKPaymentQueueWrapper();
      final transactions = await paymentWrapper.transactions();
      for (final transaction in transactions) {
        await paymentWrapper.finishTransaction(transaction);
      }
    }

    return true;
  }

  /// Fetch products from store
  Future<List<ProductDetails>> fetchProducts(Set<String> productIds) async {
    if (!_isAvailable) {
      debugPrint('IAP: Store not available, cannot fetch products');
      return [];
    }

    final response = await _inAppPurchase.queryProductDetails(productIds);

    _lastNotFoundIDs = response.notFoundIDs.toSet();
    if (_lastNotFoundIDs.isNotEmpty) {
      debugPrint('IAP: Products not found: $_lastNotFoundIDs');
    }

    _products = response.productDetails;
    debugPrint('IAP: Fetched ${_products.length} products');
    
    return _products;
  }

  /// Get cached products
  List<ProductDetails> get products => _products;

  /// Get product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  /// IDs that were not found in the last fetch (e.g. not yet approved on App Store).
  Set<String> get lastNotFoundIDs => Set.from(_lastNotFoundIDs);

  /// Purchase a product (subscription)
  Future<bool> purchaseProduct(ProductDetails product) async {
    if (!_isAvailable) {
      debugPrint('IAP: Store not available');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      // For subscriptions, use buyNonConsumable
      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('IAP: Purchase error: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      debugPrint('IAP: Store not available');
      return;
    }

    await _inAppPurchase.restorePurchases();
  }

  /// Handle purchase updates from stream
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      debugPrint('IAP: Purchase update - ${purchaseDetails.productID}: ${purchaseDetails.status}');
      
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          _handlePending(purchaseDetails);
          break;
        case PurchaseStatus.purchased:
          _handlePurchased(purchaseDetails);
          break;
        case PurchaseStatus.restored:
          _handleRestored(purchaseDetails);
          break;
        case PurchaseStatus.error:
          _handleError(purchaseDetails);
          break;
        case PurchaseStatus.canceled:
          _handleCanceled(purchaseDetails);
          break;
      }
    }
  }

  void _handlePending(PurchaseDetails purchase) {
    onPurchasePending?.call(purchase);
  }

  Future<void> _handlePurchased(PurchaseDetails purchase) async {
    // Deliver product / verify with backend
    onPurchaseSuccess?.call(purchase);
    
    // Complete the purchase
    if (purchase.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchase);
    }
  }

  Future<void> _handleRestored(PurchaseDetails purchase) async {
    onPurchaseRestored?.call(purchase);
    
    if (purchase.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchase);
    }
  }

  Future<void> _handleError(PurchaseDetails purchase) async {
    final error = purchase.error?.message ?? 'Unknown error';
    onPurchaseError?.call(purchase, error);
    
    if (purchase.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchase);
    }
  }

  Future<void> _handleCanceled(PurchaseDetails purchase) async {
    onPurchaseError?.call(purchase, 'Đã hủy mua hàng');
    
    if (purchase.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchase);
    }
  }

  /// Get receipt data for verification
  String? getReceiptData(PurchaseDetails purchase) {
    if (Platform.isIOS) {
      // iOS: verificationData contains the receipt
      return purchase.verificationData.serverVerificationData;
    } else if (Platform.isAndroid) {
      // Android: verificationData contains the purchase token
      return purchase.verificationData.serverVerificationData;
    }
    return null;
  }

  /// Get platform string
  String get platform => Platform.isIOS ? 'ios' : 'android';

  /// Dispose
  void dispose() {
    _purchaseSubscription?.cancel();
  }
}
