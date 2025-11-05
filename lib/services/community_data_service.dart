// lib/services/community_data_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/book_model.dart';
import 'google_books_service.dart';

class CommunityDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<RomanceBook?> getCommunityBookData(String bookId) async {
    // This service is now a placeholder as we are not using community data directly.
    return null;
  }

  Future<List<RomanceBook>> getBooksBySeries(String seriesName) async {
    // This service is now a placeholder as we are not using community data directly.
    return [];
  }

  /// Updates community book aggregates when a user rates a book
  Future<void> updateBookAggregates({
    required String bookId,
    required String userId,
    double? spiceOverall,
    double? emotionalArc,
    List<String>? genres,
    List<String>? tropes,
    List<String>? warnings,
    // Optional: caller can provide whether this is a new rating and the
    // previous numeric values to avoid a race condition when the caller has
    // already written the rating document.
    bool? isNewRating,
    double? previousSpice,
    double? previousEmotional,
    // When true, force the client to perform aggregation (fallback). By
    // default this method returns early because aggregation runs server-side.
    bool forceClientUpdate = false,
  }) async {
    final aggregateRef = _firestore.collection('book_aggregates').doc(bookId);
    if (!forceClientUpdate) {
      debugPrint(
        'NOTE: Server-side aggregation is recommended. Skipping client-side update for $bookId.',
      );
      return;
    }
    try {
      debugPrint('Updating book aggregates for book: $bookId');

      // Get current aggregate data
      final currentDoc = await aggregateRef.get();
      final currentData = currentDoc.data() ?? {};

      // Calculate new averages and counts
      // Normalize numeric types safely (Firestore may store ints or doubles)
      final currentTotalRatings = (currentData['totalUserRatings'] ?? 0) is int
          ? (currentData['totalUserRatings'] as int)
          : (currentData['totalUserRatings'] is num
                ? (currentData['totalUserRatings'] as num).toInt()
                : 0);

      double toDoubleSafe(dynamic v) {
        if (v == null) return 0.0;
        if (v is double) return v;
        if (v is int) return v.toDouble();
        if (v is num) return v.toDouble();
        return 0.0;
      }

      final currentAvgSpice = toDoubleSafe(currentData['avgSpiceOnPage']);
      final currentAvgEmotional = toDoubleSafe(currentData['avgEmotionalArc']);

      // Determine whether this is a new rating. Prefer caller-provided
      // information to avoid the race where the caller has already written
      // the rating document. If not supplied, read the ratings doc.
      bool isNew = isNewRating ?? false;
      double previousSpiceLocal = previousSpice ?? 0.0;
      double previousEmotionalLocal = previousEmotional ?? 0.0;
      if (isNewRating == null) {
        final existingRatingRef = _firestore
            .collection('ratings')
            .doc('${userId}_$bookId');
        final existingRating = await existingRatingRef.get();
        isNew = !existingRating.exists;
        if (existingRating.exists) {
          previousSpiceLocal = existingRating.data()?['spiceOverall'] is num
              ? (existingRating.data()?['spiceOverall'] as num).toDouble()
              : 0.0;
          previousEmotionalLocal = existingRating.data()?['emotionalArc'] is num
              ? (existingRating.data()?['emotionalArc'] as num).toDouble()
              : 0.0;
        }
      }

      final int newTotalRatings = isNew
          ? currentTotalRatings + 1
          : currentTotalRatings;

      // Calculate new averages only if we have new spice/emotional data
      double newAvgSpice = currentAvgSpice;
      double newAvgEmotional = currentAvgEmotional;

      if (spiceOverall != null && newTotalRatings > 0) {
        final oldSpice = previousSpiceLocal;
        if (isNew) {
          newAvgSpice =
              ((currentAvgSpice * currentTotalRatings) + spiceOverall) /
              newTotalRatings;
        } else {
          if (currentTotalRatings > 0) {
            newAvgSpice =
                ((currentAvgSpice * currentTotalRatings) -
                    oldSpice +
                    spiceOverall) /
                currentTotalRatings;
          } else {
            newAvgSpice = spiceOverall;
          }
        }
      }

      if (emotionalArc != null && newTotalRatings > 0) {
        final oldEmotional = previousEmotionalLocal;
        if (isNew) {
          newAvgEmotional =
              ((currentAvgEmotional * currentTotalRatings) + emotionalArc) /
              newTotalRatings;
        } else {
          if (currentTotalRatings > 0) {
            newAvgEmotional =
                ((currentAvgEmotional * currentTotalRatings) -
                    oldEmotional +
                    emotionalArc) /
                currentTotalRatings;
          } else {
            newAvgEmotional = emotionalArc;
          }
        }
      }

      // Merge genre, trope, and warning lists
      final currentGenres = List<String>.from(
        currentData['genres'] ?? <dynamic>[],
      ).map((e) => e.toString()).toList();
      final currentTropes = List<String>.from(
        currentData['tropes'] ?? <dynamic>[],
      ).map((e) => e.toString()).toList();
      final currentWarnings = List<String>.from(
        currentData['warnings'] ?? <dynamic>[],
      ).map((e) => e.toString()).toList();

      final updatedGenres = {...currentGenres, ...(genres ?? [])}.toList();
      final updatedTropes = {...currentTropes, ...(tropes ?? [])}.toList();
      final updatedWarnings = {
        ...currentWarnings,
        ...(warnings ?? []),
      }.toList();

      // Update the aggregate document
      debugPrint(
        'Writing aggregates to doc: ${aggregateRef.path} -> total:$newTotalRatings avgSpice:$newAvgSpice avgEmotional:$newAvgEmotional',
      );
      await aggregateRef.set({
        'totalUserRatings': newTotalRatings,
        'avgSpiceOnPage': newAvgSpice,
        'avgEmotionalArc': newAvgEmotional,
        'genres': updatedGenres,
        'tropes': updatedTropes,
        'warnings': updatedWarnings,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Successfully updated book aggregates for book: $bookId');
    } catch (e) {
      debugPrint('Error updating book aggregates: $e');
      // Fallback: try a conservative atomic update so the aggregates reflect activity
      try {
        debugPrint('Attempting fallback aggregate write for $bookId');
        final Map<String, dynamic> fallback = {
          'totalUserRatings': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        };
        if (spiceOverall != null) fallback['lastSpiceOnPage'] = spiceOverall;
        if (emotionalArc != null) fallback['lastEmotionalArc'] = emotionalArc;
        if (genres != null && genres.isNotEmpty) {
          fallback['genres'] = FieldValue.arrayUnion(genres);
        }
        if (tropes != null && tropes.isNotEmpty) {
          fallback['tropes'] = FieldValue.arrayUnion(tropes);
        }
        if (warnings != null && warnings.isNotEmpty) {
          fallback['warnings'] = FieldValue.arrayUnion(warnings);
        }

        await aggregateRef.set(fallback, SetOptions(merge: true));
        debugPrint('Fallback aggregate write succeeded for $bookId');
      } catch (e2) {
        debugPrint('Fallback aggregate write failed for $bookId: $e2');
      }
      // Don't throw - aggregates are nice-to-have, not critical
    }
  }

  /// Returns a list of top tropes across all book aggregates, sorted by frequency.
  /// This is used for autocomplete suggestions in the Deep Trope Search UI.
  Future<List<String>> getTopTropes({int limit = 50}) async {
    try {
      final snaps = await _firestore.collection('book_aggregates').get();
      final Map<String, int> counts = {};
      for (final doc in snaps.docs) {
        final data = doc.data();
        final tropes = List.from(
          data['tropes'] ?? <dynamic>[],
        ).map((e) => e.toString()).toList();
        for (final t in tropes) {
          final key = t.trim();
          if (key.isEmpty) continue;
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
      final sorted = counts.keys.toList()
        ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
      return sorted.take(limit).toList();
    } catch (e) {
      debugPrint('getTopTropes failed: $e');
      return <String>[];
    }
  }

  /// Search for books that have the given trope in their community aggregates.
  /// It will read `book_aggregates` and, when available, merge data from `books` collection.
  Future<List<RomanceBook>> searchBooksByTrope(
    String trope, {
    int limit = 50,
  }) async {
    final results = <RomanceBook>[];
    try {
      final aggQuery = await _firestore
          .collection('book_aggregates')
          .where('tropes', arrayContains: trope)
          .limit(limit)
          .get();

      final List<String> missingBookIds = [];
      final Map<String, int> missingIndexMap = {};
      for (final doc in aggQuery.docs) {
        final data = doc.data();
        // Attempt to fetch book metadata from `books/{bookId}` if present
        final bookId = doc.id;
        final bookDoc = await _firestore.collection('books').doc(bookId).get();
        if (bookDoc.exists) {
          final bookData = bookDoc.data()!;
          debugPrint('searchBooksByTrope: found cached book doc for $bookId');
          final book = RomanceBook(
            id: bookId,
            isbn: bookData['isbn']?.toString() ?? '',
            title: bookData['title']?.toString() ?? bookId,
            authors: List<String>.from(
              bookData['authors'] ?? <dynamic>[],
            ).map((e) => e.toString()).toList(),
            imageUrl: bookData['imageUrl']?.toString(),
            description: bookData['description']?.toString(),
            publishedDate: bookData['publishedDate']?.toString(),
            pageCount: bookData['pageCount'] is int
                ? bookData['pageCount'] as int
                : null,
          );
          results.add(book);
        } else {
          debugPrint(
            'searchBooksByTrope: no cached book doc for $bookId; using aggregate fallback and scheduling Google Books lookup',
          );
          // Defer Google Books lookups for missing docs; record aggregate fallback for now
          // We'll attempt to fetch metadata in batches below to avoid serial network calls.
          final aggFallback = RomanceBook(
            id: bookId,
            isbn: '',
            title: data['title']?.toString() ?? bookId,
            authors: List<String>.from(
              data['authors'] ?? <dynamic>[],
            ).map((e) => e.toString()).toList(),
            imageUrl: data['imageUrl']?.toString(),
            description: data['description']?.toString(),
            publishedDate: null,
            pageCount: null,
          );
          results.add(aggFallback);
          // Mark this index for later enrichment
          missingBookIds.add(bookId);
          missingIndexMap[bookId] = results.length - 1;
        }
      }

      // If we have missing metadata, fetch from Google Books in bounded parallel batches
      if (missingBookIds.isNotEmpty) {
        const int concurrency = 6;
        for (var i = 0; i < missingBookIds.length; i += concurrency) {
          final chunk = missingBookIds.sublist(
            i,
            (i + concurrency) > missingBookIds.length
                ? missingBookIds.length
                : i + concurrency,
          );
          final futures = chunk.map(
            (id) => GoogleBooksService().getBookById(id),
          );
          final responses = await Future.wait(futures);
          for (var j = 0; j < chunk.length; j++) {
            final id = chunk[j];
            final googleBook = responses[j];
            if (googleBook != null) {
              debugPrint(
                'searchBooksByTrope: GoogleBooks returned metadata for $id -> ${googleBook.title}',
              );
              try {
                // Replace the placeholder in results with the richer GoogleBook
                final idx = missingIndexMap[id]!;
                results[idx] = googleBook;
                // Cache merged metadata to `books/{id}` for future speed
                final bookRef = _firestore.collection('books').doc(id);
                await bookRef.set({
                  'title': googleBook.title,
                  'authors': googleBook.authors,
                  'imageUrl': googleBook.imageUrl,
                  'description': googleBook.description,
                  'publishedDate': googleBook.publishedDate,
                  'pageCount': googleBook.pageCount,
                  'isbn': googleBook.isbn,
                }, SetOptions(merge: true));
                debugPrint(
                  'searchBooksByTrope: cached GoogleBooks metadata for $id',
                );
              } catch (e) {
                debugPrint('Failed to cache Google book $id: $e');
              }
            } else {
              debugPrint(
                'searchBooksByTrope: GoogleBooks lookup returned no result for $id',
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('searchBooksByTrope failed: $e');
    }
    return results;
  }
}
