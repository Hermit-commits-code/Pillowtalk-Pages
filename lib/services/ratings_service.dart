// lib/services/ratings_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_book.dart';

class RatingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Add or update a user's rating for a book
  Future<void> setUserRating(UserBook userBook) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('library')
        .doc(userBook.id)
        .update({
          'userSpiceRating': userBook.userSpiceRating,
          'userEmotionalRating': userBook.userEmotionalRating,
          'userSelectedTropes': userBook.userSelectedTropes,
          'userContentWarnings': userBook.userContentWarnings,
          'userNotes': userBook.userNotes,
        });
    // Optionally, also update a /ratings or /books/{bookId}/ratings collection for aggregation
  }

  /// Get a user's rating for a specific book
  Future<UserBook?> getUserRating(String userBookId) async {
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('library')
        .doc(userBookId)
        .get();
    if (doc.exists) {
      return UserBook.fromJson(doc.data()!);
    }
    return null;
  }
}
