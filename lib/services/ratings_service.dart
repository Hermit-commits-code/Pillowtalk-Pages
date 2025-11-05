// lib/services/ratings_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
// Community aggregation is now handled server-side by Cloud Function.
// The client no longer directly updates aggregates; server function will run
// whenever a rating document is written.

class RatingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Aggregation is performed server-side via Cloud Function. Keep this
  // service available if we later want a client-side fallback, but we
  // don't call it by default.

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

    debugPrint('Attempting to submit rating for book: $bookId, user: $uid');

    // Prepare the data with required fields
    final ratingData = <String, dynamic>{
      'userId': uid,
      'bookId': bookId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only add optional fields if they have values
    if (spiceOverall != null) ratingData['spiceOverall'] = spiceOverall;
    if (spiceIntensity != null) ratingData['spiceIntensity'] = spiceIntensity;
    if (emotionalArc != null) ratingData['emotionalArc'] = emotionalArc;
    if (tropes != null) ratingData['tropes'] = tropes;
    if (warnings != null) ratingData['warnings'] = warnings;
    if (genres != null) ratingData['genres'] = genres;

    try {
      // Read existing rating to determine if this is a new rating.
      final existing = await ratingRef.get();
      final bool isNewRating = !existing.exists;

      // Save the individual rating
      await ratingRef.set(ratingData, SetOptions(merge: true));
      debugPrint(
        'Successfully submitted rating for book: $bookId (isNew=$isNewRating)',
      );

      // Aggregation is now handled server-side by a Cloud Function that
      // listens for writes to `ratings/{ratingId}` and updates
      // `book_aggregates/{bookId}`. We no longer perform client-side
      // aggregate updates to avoid duplication and to centralize logic.
    } on FirebaseException catch (e) {
      debugPrint('Firebase error submitting rating: ${e.code} - ${e.message}');
      throw Exception('Database Error: ${e.message}');
    } catch (e) {
      debugPrint('General error submitting rating: $e');
      throw Exception(
        'An unexpected error occurred during rating submission. Error: $e',
      );
    }
  }
}
