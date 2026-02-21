import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// IAP Service for managing in-app purchases
class IAPService {
  static IAPService? _instance;
  
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  bool _isAvailable = false;
  Map<String, ProductDetails> _productsMap = {};
  
  // Callbacks
  void Function(PurchaseDetails purchase)? onPurchaseSuccess;
  void Function(String error)? onPurchaseError;
  void Function()? onPurchaseCancelled;

  IAPService._();

  static IAPService get instance {
    _instance ??= IAPService._();
    return _instance!;
  }

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _productsMap.values.toList();

  /// Initialize the IAP service
  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    
    if (!_isAvailable) {
      debugPrint('IAP not available on this device');
      return;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: _onPurchaseStreamDone,
      onError: _onPurchaseStreamError,
    );

    debugPrint('IAP Service initialized');
  }

  /// Load products by their IDs
  Future<List<ProductDetails>> loadProducts(List<String> productIds) async {
    if (!_isAvailable) {
      debugPrint('IAP not available');
      return [];
    }

    final response = await _iap.queryProductDetails(productIds.toSet());
    
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }

    if (response.error != null) {
      debugPrint('Error loading products: ${response.error}');
      return [];
    }

    // Store products in a map keyed by exact product ID for precise lookup
    _productsMap = {
      for (final product in response.productDetails)
        product.id: product,
    };
    debugPrint('Loaded ${_productsMap.length} products: ${_productsMap.keys.toList()}');
    
    return _productsMap.values.toList();
  }

  /// Purchase a product by ID
  Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      onPurchaseError?.call('IAP không khả dụng trên thiết bị này');
      return false;
    }

    // Find the product by exact ID match using map lookup
    final product = _productsMap[productId];
    if (product == null) {
      final available = _productsMap.keys.toList();
      onPurchaseError?.call(
        'Sản phẩm không tìm thấy: $productId (có sẵn: $available)',
      );
      return false;
    }

    // For consumable products
    final purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      // buyConsumable for credits (one-time purchases that can be bought multiple times)
      final success = await _iap.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: true, // Automatically consume after purchase
      );
      
      return success;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      onPurchaseError?.call('Không thể thực hiện mua hàng');
      return false;
    }
  }

  /// Handle purchase updates from the stream
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      _handlePurchase(purchase);
    }
  }

  void _handlePurchase(PurchaseDetails purchase) async {
    debugPrint('Purchase update: ${purchase.productID} - ${purchase.status}');
    
    switch (purchase.status) {
      case PurchaseStatus.pending:
        // Show loading or pending UI
        debugPrint('Purchase pending...');
        break;
        
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Verify and deliver the purchase
        final valid = await _verifyPurchase(purchase);
        if (valid) {
          onPurchaseSuccess?.call(purchase);
        } else {
          onPurchaseError?.call('Xác thực giao dịch thất bại');
        }
        
        // Complete the purchase
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;
        
      case PurchaseStatus.error:
        onPurchaseError?.call(purchase.error?.message ?? 'Có lỗi xảy ra');
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;
        
      case PurchaseStatus.canceled:
        onPurchaseCancelled?.call();
        break;
    }
  }

  /// Verify purchase (basic verification - should be done on server)
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // Basic verification - in production, verify with your server
    // The server should verify the receipt with Apple/Google
    return purchase.verificationData.localVerificationData.isNotEmpty;
  }

  /// Get purchase receipt data for server verification
  String? getReceiptData(PurchaseDetails purchase) {
    if (Platform.isIOS) {
      return purchase.verificationData.localVerificationData;
    } else if (Platform.isAndroid) {
      return purchase.verificationData.serverVerificationData;
    }
    return null;
  }

  /// Get transaction ID
  String? getTransactionId(PurchaseDetails purchase) {
    return purchase.purchaseID;
  }

  /// Restore purchases (for non-consumables, not needed for credits)
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

  /// Dispose the service
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
