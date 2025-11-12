import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Small helper to forward purchase tokens to your server and refresh Firebase ID token.
class PurchaseService {
  final String serverVerifyUrl; // e.g. https://your-server/verifyPurchase

  PurchaseService(this.serverVerifyUrl);

  /// Send the purchase token to your server for verification. Returns true on success.
  Future<bool> verifyPurchaseOnServer({
    required String uid,
    required String packageName,
    required String productId,
    required String purchaseToken,
  }) async {
    final resp = await http.post(
      Uri.parse(serverVerifyUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'uid': uid,
        'packageName': packageName,
        'productId': productId,
        'purchaseToken': purchaseToken,
      }),
    );
    if (resp.statusCode == 200) return true;
    return false;
  }

  /// Refresh the current user's ID token so custom claims are picked up.
  Future<void> refreshIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.getIdTokenResult(true);
  }
}
