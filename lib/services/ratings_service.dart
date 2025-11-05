// lib/services/ratings_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitRating({
    required String bookId,
    double? spiceOverall,
    String? spiceIntensity,
    double? emotionalArc,
    List<String>? tropes,
    List<String>? warnings,
    List<String>? genres,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not signed in');

    final ratingRef = _firestore.collection('ratings').doc('${uid}_$bookId');

    await ratingRef.set({
      'userId': uid,
      'bookId': bookId,
      'spiceOverall': spiceOverall,
      'spiceIntensity': spiceIntensity,
      'emotionalArc': emotionalArc,
      'tropes': tropes ?? [],
      'warnings': warnings ?? [],
      'genres': genres ?? [],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
