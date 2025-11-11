import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Service to check and listen for the current user's Pro status.
class ProStatusService {
  final _authService = AuthService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- DEVELOPER OVERRIDE ---
  // To enable Pro status for a specific developer account, add the email here.
  // This is useful for testing without making real purchases.
  static const List<String> _devEmails = ['hotcupofjoe2013@gmail.com'];

  /// Returns a stream of whether the current user is Pro.
  Stream<bool> isProStream() {
    final user = _authService.currentUser;
    if (user == null) return Stream.value(false);

    // Developer override check
    if (_devEmails.contains(user.email)) {
      debugPrint('Pro status: true (developer override for ${user.email})');
      return Stream.value(true);
    }

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      final isPro = (doc.data()?['isPro'] ?? false) as bool;
      debugPrint('Pro status from Firestore: $isPro for user ${user.email}');
      return isPro;
    });
  }

  /// Returns a Future of whether the current user is Pro.
  Future<bool> isPro() async {
    final user = _authService.currentUser;
    if (user == null) {
      debugPrint('Pro status check: false (no authenticated user)');
      return false;
    }

    // Developer override check
    if (_devEmails.contains(user.email)) {
      debugPrint('Pro status: true (developer override for ${user.email})');
      return true;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final isPro = (doc.data()?['isPro'] ?? false) as bool;
    debugPrint('Pro status from Firestore: $isPro for user ${user.email}');
    return isPro;
  }
}
