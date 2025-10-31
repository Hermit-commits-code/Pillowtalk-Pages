// lib/services/community_data_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book_model.dart';

class CommunityDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches the aggregated community data for a book by its ID
  Future<RomanceBook?> getCommunityBookData(String bookId) async {
    final doc = await _firestore.collection('books').doc(bookId).get();
    if (doc.exists) {
      return RomanceBook.fromJson(doc.data()!);
    }
    return null;
  }

  /// Updates the aggregated community data for a book
  Future<void> updateCommunityBookData(RomanceBook book) async {
    await _firestore.collection('books').doc(book.id).set(book.toJson());
  }

  /// Aggregates ratings, tropes, and warnings for a book from all user ratings
  Future<void> aggregateCommunityData(String bookId) async {
    // This is a placeholder for aggregation logic.
    // In production, you would query all user ratings for this book,
    // calculate averages and top tropes/warnings, and update the book doc.
    // This can be implemented as a callable cloud function for scalability.
  }
}
