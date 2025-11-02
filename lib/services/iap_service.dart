import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

class IAPService {
  static const String proMonthlyId = 'pro_monthly';
  static const String proAnnualId = 'pro_annual';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  IAPService() {
    _subscription = _iap.purchaseStream.listen(_onPurchaseUpdated);
  }

  void dispose() {
    _subscription?.cancel();
  }

  Future<List<ProductDetails>> getProducts() async {
    final response = await _iap.queryProductDetails({
      proMonthlyId,
      proAnnualId,
    });
    return response.productDetails;
  }

  Future<void> buy(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchases) {
    // TODO: Handle purchase updates, verify, and update Firestore
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }
}
