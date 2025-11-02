import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
    for (final purchase in purchases) {
      // Example: verify purchase and update Firestore
      if (purchase.status == PurchaseStatus.purchased) {
        // Verification logic stub
        final isValid = _verifyPurchase(purchase);
        if (isValid) {
          _updateFirestoreWithPurchase(purchase);
        }
      }
    }
  }

  bool _verifyPurchase(PurchaseDetails purchase) {
    // Implement real verification logic with your backend here.
    // For now, assume all purchases are valid.
    // You might send purchase details to your server for validation.
    return true;
  }

  Future<void> _updateFirestoreWithPurchase(PurchaseDetails purchase) async {
    // Implement Firestore update logic here.
    // Example: Save purchase info to Firestore for tracking.
    await FirebaseFirestore.instance.collection('purchases').add({
      'purchaseID': purchase.purchaseID,
      'productID': purchase.productID,
      'status': purchase.status.toString(),
      'transactionDate': purchase.transactionDate,
      'verificationData': purchase.verificationData.serverVerificationData,
      'pendingCompletePurchase': purchase.pendingCompletePurchase,
    });
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }
}
