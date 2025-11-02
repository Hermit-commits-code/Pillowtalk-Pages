import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to check and listen for the current user's Pro status.
class ProStatusService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns a stream of whether the current user is Pro.
  Stream<bool> isProStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
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
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return (doc.data()?['isPro'] ?? false) as bool;
  }
}
