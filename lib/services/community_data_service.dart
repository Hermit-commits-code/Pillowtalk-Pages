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

  /// Search books by trope tags.
  ///
  /// - If [orMode] is true, performs an `array-contains-any` style query
  ///   (Firestore limitation: array-contains-any matches ANY of the provided
  ///   values). Otherwise, performs a query for the first tag and filters
  ///   the results locally to ensure all tags are present (AND semantics).
  ///
  /// This is intentionally pragmatic for an MVP. For large datasets you may
  /// want to replace this with a dedicated search index (Algolia/Elasticsearch)
  /// or a Cloud Function that performs server-side joins.
  Future<List<RomanceBook>> searchBooksByTropes(
    List<String> tags, {
    bool orMode = true,
    int limit = 50,
  }) async {
    if (tags.isEmpty) return [];

    final tagNorm = tags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tagNorm.isEmpty) return [];

    try {
      final seen = <String>{};
      final out = <RomanceBook>[];

      // Primary: try aggregated docs collection first (if present)
      final aggCol = _firestore.collection('book_aggregates');
      final booksCol = _firestore.collection('books');

      if (orMode) {
        // Firestore supports array-contains-any for OR semantics (max 10 values).
        final queries = <Future<QuerySnapshot>>[];
        final chunk = tagNorm.length > 10 ? tagNorm.sublist(0, 10) : tagNorm;
        queries.add(
          aggCol
              .where('communityTropes', arrayContainsAny: chunk)
              .limit(limit)
              .get(),
        );
        queries.add(
          booksCol
              .where('communityTropes', arrayContainsAny: chunk)
              .limit(limit)
              .get(),
        );

        final snaps = await Future.wait(queries);
        for (final snap in snaps) {
          for (final d in snap.docs) {
            final id = d.id;
            if (seen.add(id)) {
              out.add(
                RomanceBook.fromJson(
                  Map<String, dynamic>.from(d.data() as Map),
                ),
              );
            }
          }
        }
      } else {
        // AND mode: query for the first tag then filter locally for the rest.
        final first = tagNorm.first;
        final snaps = await Future.wait([
          aggCol
              .where('communityTropes', arrayContains: first)
              .limit(limit)
              .get(),
          booksCol
              .where('communityTropes', arrayContains: first)
              .limit(limit)
              .get(),
        ]);

        for (final snap in snaps) {
          for (final d in snap.docs) {
            final id = d.id;
            if (!seen.add(id)) continue;
            final data = Map<String, dynamic>.from(d.data() as Map);
            final book = RomanceBook.fromJson(data);
            final tropes = book.communityTropes
                .map((t) => t.toLowerCase())
                .toSet();
            var ok = true;
            for (final t in tagNorm) {
              if (!tropes.any(
                (tt) =>
                    tt.contains(t.toLowerCase()) ||
                    t.toLowerCase().contains(tt),
              )) {
                ok = false;
                break;
              }
            }
            if (ok) out.add(book);
          }
        }
      }

      return out;
    } catch (e) {
      // ignore: avoid_print
      print('tropes search failed: $e');
      return [];
    }
  }
}
