// lib/services/community_data_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book_model.dart';

class CommunityDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches the aggregated community data for a book by its ID
  Future<RomanceBook?> getCommunityBookData(String bookId) async {
    try {
      // Prefer reading from `book_aggregates/{bookId}` if present. This
      // decouples aggregated community summaries from the canonical `books/`
      // collection and avoids creating placeholder/partial book docs.
      final aggRef = _firestore.collection('book_aggregates').doc(bookId);
      final aggDoc = await aggRef.get();
      if (aggDoc.exists) {
        final data = aggDoc.data() as Map<String, dynamic>;
        return RomanceBook.fromJson(Map<String, dynamic>.from(data));
      }

      // Fallback to the legacy `books/{bookId}` document if no aggregate doc exists.
      final doc = await _firestore.collection('books').doc(bookId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return RomanceBook.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      // Swallow and return null so callers can handle missing/invalid docs.
      // ignore: avoid_print
      print('Error fetching community book $bookId: $e');
    }
    return null;
  }

  /// Get all books that belong to the given series name (exact match).
  Future<List<RomanceBook>> getBooksBySeries(String seriesName) async {
    if (seriesName.isEmpty) return [];
    // Try exact match first, then fallback to normalized match
    final snaps = <QuerySnapshot>[];
    final qExact = await _firestore
        .collection('books')
        .where('seriesName', isEqualTo: seriesName)
        .orderBy('seriesIndex')
        .get();
    snaps.add(qExact);

    final norm = seriesName.toLowerCase().trim();
    if (norm != seriesName) {
      final qNorm = await _firestore
          .collection('books')
          .where('seriesName_normalized', isEqualTo: norm)
          .orderBy('seriesIndex')
          .get();
      snaps.add(qNorm);
    }

    final seen = <String>{};
    final out = <RomanceBook>[];
    for (final snap in snaps) {
      for (final d in snap.docs) {
        final id = d.id;
        if (seen.add(id)) {
          out.add(
            RomanceBook.fromJson(Map<String, dynamic>.from(d.data() as Map)),
          );
        }
      }
    }
    return out;
  }

  /// Search books by a series name prefix. Performs two prefix queries (original and lower-cased)
  /// and merges results to improve coverage for mixed-case series names.
  Future<List<RomanceBook>> searchBooksBySeriesPrefix(String prefix) async {
    final q = prefix.trim();
    if (q.isEmpty) return [];
    // Use the normalized series name field as the primary prefix match key.
    // The migration tool should populate `seriesName_normalized` for reliable
    // case- and diacritic-insensitive searches. We still include a fallback
    // query on the raw `seriesName` to increase coverage for documents that
    // don't yet have the normalized field.
    final qLower = q.toLowerCase();
    final endLower = '$qLower\uf8ff';

    final futures = <Future<QuerySnapshot>>[
      // Primary: normalized prefix search
      _firestore
          .collection('books')
          .orderBy('seriesName_normalized')
          .startAt([qLower])
          .endAt([endLower])
          .get(),
      // Fallback: try raw seriesName (original casing) prefix search
      _firestore.collection('books').orderBy('seriesName').startAt([q]).endAt([
        '$q\uf8ff',
      ]).get(),
    ];

    final results = await Future.wait(futures);
    final seen = <String>{};
    final out = <RomanceBook>[];
    for (final snap in results) {
      for (final d in snap.docs) {
        final id = d.id;
        if (seen.add(id)) {
          out.add(
            RomanceBook.fromJson(Map<String, dynamic>.from(d.data() as Map)),
          );
        }
      }
    }
    return out;
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
