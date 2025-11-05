import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    // Save purchase info to Firestore for tracking.
    final data = {
      'purchaseID': purchase.purchaseID,
      'productID': purchase.productID,
      'status': purchase.status.toString(),
      'transactionDate': purchase.transactionDate,
      'verificationData': purchase.verificationData.serverVerificationData,
      'pendingCompletePurchase': purchase.pendingCompletePurchase,
    };

    await FirebaseFirestore.instance.collection('purchases').add(data);

    // If we have a signed-in user, mark them as Pro (stub verification).
    // NOTE: Replace this stub with server-side verification for production.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'isPro': true,
          'proProductId': purchase.productID,
          'proSince': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        // If marking as Pro fails, we still keep the purchases record.
        // Use debugPrint if available in this file context.
      }
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }
}
