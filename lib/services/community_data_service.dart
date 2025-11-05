// lib/services/community_data_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/book_model.dart';

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

      double _toDoubleSafe(dynamic v) {
        if (v == null) return 0.0;
        if (v is double) return v;
        if (v is int) return v.toDouble();
        if (v is num) return v.toDouble();
        return 0.0;
      }

      final currentAvgSpice = _toDoubleSafe(currentData['avgSpiceOnPage']);
      final currentAvgEmotional = _toDoubleSafe(currentData['avgEmotionalArc']);

      // Determine whether this is a new rating. Prefer caller-provided
      // information to avoid the race where the caller has already written
      // the rating document. If not supplied, read the ratings doc.
      bool _isNew = isNewRating ?? false;
      double _previousSpice = previousSpice ?? 0.0;
      double _previousEmotional = previousEmotional ?? 0.0;
      if (isNewRating == null) {
        final existingRatingRef = _firestore
            .collection('ratings')
            .doc('${userId}_$bookId');
        final existingRating = await existingRatingRef.get();
        _isNew = !existingRating.exists;
        if (existingRating.exists) {
          _previousSpice = existingRating.data()?['spiceOverall'] is num
              ? (existingRating.data()?['spiceOverall'] as num).toDouble()
              : 0.0;
          _previousEmotional = existingRating.data()?['emotionalArc'] is num
              ? (existingRating.data()?['emotionalArc'] as num).toDouble()
              : 0.0;
        }
      }

      final int newTotalRatings = _isNew
          ? currentTotalRatings + 1
          : currentTotalRatings;

      // Calculate new averages only if we have new spice/emotional data
      double newAvgSpice = currentAvgSpice;
      double newAvgEmotional = currentAvgEmotional;

      if (spiceOverall != null && newTotalRatings > 0) {
        final oldSpice = _previousSpice;
        if (_isNew) {
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
        final oldEmotional = _previousEmotional;
        if (_isNew) {
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
        if (genres != null && genres.isNotEmpty)
          fallback['genres'] = FieldValue.arrayUnion(genres);
        if (tropes != null && tropes.isNotEmpty)
          fallback['tropes'] = FieldValue.arrayUnion(tropes);
        if (warnings != null && warnings.isNotEmpty)
          fallback['warnings'] = FieldValue.arrayUnion(warnings);

        await aggregateRef.set(fallback, SetOptions(merge: true));
        debugPrint('Fallback aggregate write succeeded for $bookId');
      } catch (e2) {
        debugPrint('Fallback aggregate write failed for $bookId: $e2');
      }
      // Don't throw - aggregates are nice-to-have, not critical
    }
  }
}
