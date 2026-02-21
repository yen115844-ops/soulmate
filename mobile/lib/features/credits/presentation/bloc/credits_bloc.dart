import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/services/iap_service.dart';
import '../../data/credits_repository.dart';
import '../../data/models/credits_models.dart';
import 'credits_event.dart';
import 'credits_state.dart';

class CreditsBloc extends Bloc<CreditsEvent, CreditsState> {
  final CreditsRepository _repository;
  
  CreditWallet? _wallet;
  List<CreditPackage> _packages = [];
  
  // Track pending purchase for callback
  CreditPackage? _pendingPackage;
  Completer<void>? _purchaseCompleter;

  CreditsBloc({required CreditsRepository repository})
      : _repository = repository,
        super(const CreditsInitial()) {
    on<LoadCredits>(_onLoadCredits);
    on<LoadTransactions>(_onLoadTransactions);
    on<PurchaseCredits>(_onPurchaseCredits);
    on<VerifyPurchase>(_onVerifyPurchase);
    on<RequestWithdrawal>(_onRequestWithdrawal);
    on<UpdateBankInfo>(_onUpdateBankInfo);
    on<RefreshWallet>(_onRefreshWallet);
    on<IAPPurchaseCompleted>(_onIAPPurchaseCompleted);
    on<IAPPurchaseFailed>(_onIAPPurchaseFailed);
    on<IAPPurchaseCancelled>(_onIAPPurchaseCancelled);
    
    // Setup IAP callbacks
    _setupIAPCallbacks();
  }
  
  void _setupIAPCallbacks() {
    IAPService.instance.onPurchaseSuccess = _handlePurchaseSuccess;
    IAPService.instance.onPurchaseError = _handlePurchaseError;
    IAPService.instance.onPurchaseCancelled = _handlePurchaseCancelled;
  }
  
  void _handlePurchaseSuccess(PurchaseDetails purchase) async {
    debugPrint('Purchase success callback: ${purchase.productID}');
    
    final package = _pendingPackage;
    if (package == null) {
      debugPrint('Warning: No pending package found');
      return;
    }
    
    // Verify with backend
    final platform = Platform.isIOS ? 'ios' : 'android';
    final receiptData = IAPService.instance.getReceiptData(purchase);
    final transactionId = IAPService.instance.getTransactionId(purchase);
    
    try {
      final verifyResult = await _repository.purchaseCredits(
        platform: platform,
        productId: purchase.productID,
        transactionId: transactionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        receiptData: receiptData ?? '',
      );

      if (verifyResult.success) {
        add(IAPPurchaseCompleted(
          creditsReceived: verifyResult.creditsReceived,
          newBalance: verifyResult.newBalance,
        ));
      } else {
        // IAP succeeded but backend failed - still show success with expected credits
        add(IAPPurchaseCompleted(
          creditsReceived: package.totalCredits,
          newBalance: (_wallet?.balance ?? 0) + package.totalCredits,
        ));
      }
    } catch (e) {
      debugPrint('Backend verification failed: $e');
      // Show success anyway - backend webhook should handle it
      add(IAPPurchaseCompleted(
        creditsReceived: package.totalCredits,
        newBalance: (_wallet?.balance ?? 0) + package.totalCredits,
      ));
    }
    
    _pendingPackage = null;
    _purchaseCompleter?.complete();
  }
  
  void _handlePurchaseError(String error) {
    debugPrint('Purchase error callback: $error');
    add(IAPPurchaseFailed(error: error));
    _pendingPackage = null;
    _purchaseCompleter?.complete();
  }
  
  void _handlePurchaseCancelled() {
    debugPrint('Purchase cancelled callback');
    add(const IAPPurchaseCancelled());
    _pendingPackage = null;
    _purchaseCompleter?.complete();
  }
  
  // Internal IAP event handlers
  Future<void> _onIAPPurchaseCompleted(
    IAPPurchaseCompleted event,
    Emitter<CreditsState> emit,
  ) async {
    emit(CreditsPurchaseSuccess(
      creditsReceived: event.creditsReceived,
      newBalance: event.newBalance,
    ));
    add(const RefreshWallet());
  }
  
  Future<void> _onIAPPurchaseFailed(
    IAPPurchaseFailed event,
    Emitter<CreditsState> emit,
  ) async {
    // Emit error with wallet data so UI can still show content
    emit(CreditsError(
      message: event.error,
      wallet: _wallet,
      packages: _packages,
    ));
  }
  
  Future<void> _onIAPPurchaseCancelled(
    IAPPurchaseCancelled event,
    Emitter<CreditsState> emit,
  ) async {
    if (_wallet != null) {
      emit(CreditsLoaded(wallet: _wallet!, packages: _packages));
    }
  }

  /// Current wallet balance
  int get balance => _wallet?.balance ?? 0;

  Future<void> _onLoadCredits(
    LoadCredits event,
    Emitter<CreditsState> emit,
  ) async {
    emit(const CreditsLoading());
    try {
      final results = await Future.wait([
        _repository.getWallet(),
        _repository.getPackages(),
      ]);
      
      _wallet = results[0] as CreditWallet;
      _packages = results[1] as List<CreditPackage>;

      // Pre-load IAP products
      if (IAPService.instance.isAvailable && _packages.isNotEmpty) {
        final productIds = _packages.map((p) {
          return Platform.isIOS 
              ? (p.appleProductId ?? p.code)
              : (p.googleProductId ?? p.code);
        }).toList();
        await IAPService.instance.loadProducts(productIds);
      }

      emit(CreditsLoaded(wallet: _wallet!, packages: _packages));
    } catch (e) {
      emit(CreditsError(
        message: e.toString(),
        wallet: _wallet,
        packages: _packages,
      ));
    }
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<CreditsState> emit,
  ) async {
    emit(const CreditsLoading());
    try {
      final result = await _repository.getTransactions(page: event.page);
      emit(TransactionsLoaded(
        transactions: result.transactions,
        total: result.total,
        page: event.page,
      ));
    } catch (e) {
      emit(CreditsError(
        message: e.toString(),
        wallet: _wallet,
        packages: _packages,
      ));
    }
  }

  /// Handle IAP purchase flow
  Future<void> _onPurchaseCredits(
    PurchaseCredits event,
    Emitter<CreditsState> emit,
  ) async {
    if (!IAPService.instance.isAvailable) {
      emit(CreditsError(
        message: 'Mua hàng trong ứng dụng không khả dụng trên thiết bị này',
        wallet: _wallet,
        packages: _packages,
      ));
      return;
    }
    
    emit(const CreditsPurchasing());
    
    try {
      // Find the package by unique ID
      final package = _packages.firstWhere(
        (p) => p.id == event.packageId,
        orElse: () => throw Exception('Không tìm thấy gói credits'),
      );

      // Get the correct product ID based on platform
      final productId = Platform.isIOS
          ? package.appleProductId ?? package.code
          : package.googleProductId ?? package.code;

      debugPrint('Purchasing product: $productId');

      // Store pending package for callback
      _pendingPackage = package;
      _purchaseCompleter = Completer<void>();
      
      // Start the purchase (result comes via callback)
      final started = await IAPService.instance.purchaseProduct(productId);
      
      if (!started) {
        emit(CreditsError(
          message: 'Không thể bắt đầu giao dịch',
          wallet: _wallet,
          packages: _packages,
        ));
        _pendingPackage = null;
        return;
      }
      
      // Wait for purchase to complete (via callbacks)
      // The callbacks will emit the appropriate state
    } catch (e) {
      debugPrint('Purchase exception: $e');
      emit(CreditsError(
        message: e.toString(),
        wallet: _wallet,
        packages: _packages,
      ));
      _pendingPackage = null;
    }
  }

  Future<void> _onVerifyPurchase(
    VerifyPurchase event,
    Emitter<CreditsState> emit,
  ) async {
    emit(const CreditsPurchasing());
    try {
      final result = await _repository.purchaseCredits(
        platform: event.platform,
        productId: event.productId,
        transactionId: event.transactionId,
        receiptData: event.receiptData,
      );

      if (result.success) {
        emit(CreditsPurchaseSuccess(
          creditsReceived: result.creditsReceived,
          newBalance: result.newBalance,
        ));
        // Refresh wallet after purchase
        add(const RefreshWallet());
      } else {
        emit(CreditsError(
          message: 'Purchase verification failed',
          wallet: _wallet,
          packages: _packages,
        ));
      }
    } catch (e) {
      emit(CreditsError(
        message: e.toString(),
        wallet: _wallet,
        packages: _packages,
      ));
    }
  }

  Future<void> _onRequestWithdrawal(
    RequestWithdrawal event,
    Emitter<CreditsState> emit,
  ) async {
    emit(const CreditsWithdrawing());
    try {
      final result = await _repository.requestWithdrawal(
        amount: event.amount,
        note: event.note,
      );

      if (result.success) {
        emit(CreditsWithdrawalSuccess(message: result.message));
        add(const RefreshWallet());
      } else {
        emit(CreditsError(
          message: result.message,
          wallet: _wallet,
          packages: _packages,
        ));
      }
    } catch (e) {
      emit(CreditsError(
        message: e.toString(),
        wallet: _wallet,
        packages: _packages,
      ));
    }
  }

  Future<void> _onUpdateBankInfo(
    UpdateBankInfo event,
    Emitter<CreditsState> emit,
  ) async {
    emit(const CreditsLoading());
    try {
      await _repository.updateBankInfo(
        bankName: event.bankName,
        bankAccountNo: event.bankAccountNo,
        bankAccountName: event.bankAccountName,
      );
      emit(const BankInfoUpdated());
      add(const RefreshWallet());
    } catch (e) {
      emit(CreditsError(
        message: e.toString(),
        wallet: _wallet,
        packages: _packages,
      ));
    }
  }

  Future<void> _onRefreshWallet(
    RefreshWallet event,
    Emitter<CreditsState> emit,
  ) async {
    try {
      _wallet = await _repository.getWallet();
    } catch (e) {
      debugPrint('Refresh wallet failed: $e');
    }
    // Always emit CreditsLoaded to dismiss loading overlay
    if (_wallet != null) {
      emit(CreditsLoaded(wallet: _wallet!, packages: _packages));
    }
  }
}
