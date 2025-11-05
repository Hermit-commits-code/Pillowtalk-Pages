import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to check and listen for the current user's Pro status.
class ProStatusService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- DEVELOPER OVERRIDE ---
  // To enable Pro status for a specific developer account, add the email here.
  // This is useful for testing without making real purchases.
  static const List<String> _devEmails = ['hotcupofjoe2013@gmail.com'];

  /// Returns a stream of whether the current user is Pro.
  Stream<bool> isProStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    // Developer override check
    if (_devEmails.contains(user.email)) {
      return Stream.value(true);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => (doc.data()?['isPro'] ?? false) as bool);
  }

  /// Returns a Future of whether the current user is Pro.
  Future<bool> isPro() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Developer override check
    if (_devEmails.contains(user.email)) {
      return true;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return (doc.data()?['isPro'] ?? false) as bool;
  }
}
