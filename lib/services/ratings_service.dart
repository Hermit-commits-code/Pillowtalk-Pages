// lib/services/ratings_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_book.dart';

class RatingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Submit or update the current user's community rating for a book.
  /// Writes a per-user rating doc in `ratings/{userId}_{bookId}` and updates
  /// the book aggregate (`books/{bookId}`) transactionally.
  Future<void> submitRating({
    required String bookId,
    required double spiceLevel,
    List<String>? tropes,
    List<String>? warnings,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not signed in');

    final ratingRef = _firestore.collection('ratings').doc('${uid}_$bookId');
    final bookRef = _firestore.collection('books').doc(bookId);

    await _firestore.runTransaction((tx) async {
      // Read previous rating and book docs first (reads must happen before any writes)
      final ratingSnap = await tx.get(ratingRef);
      final bookSnap = await tx.get(bookRef);

      final prevSpice = ratingSnap.exists
          ? (ratingSnap.data()?['spiceLevel'] as num?)?.toDouble()
          : null;

      // Previous tropes/warnings (if any)
      final prevTropes = ratingSnap.exists
          ? List<String>.from(ratingSnap.data()?['tropes'] ?? [])
          : <String>[];
      final prevWarnings = ratingSnap.exists
          ? List<String>.from(ratingSnap.data()?['warnings'] ?? [])
          : <String>[];

      // Now perform writes (we've completed required reads)
      // Upsert the user's rating doc
      tx.set(ratingRef, {
        'userId': uid,
        'bookId': bookId,
        'spiceLevel': spiceLevel,
        'tropes': tropes ?? [],
        'warnings': warnings ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!bookSnap.exists) {
        // Initialize aggregate including trope/warning counts
        final Map<String, int> initialTropeCounts = {};
        for (final t in tropes ?? []) {
          initialTropeCounts[t] = (initialTropeCounts[t] ?? 0) + 1;
        }
        final Map<String, int> initialWarningCounts = {};
        for (final w in warnings ?? []) {
          initialWarningCounts[w] = (initialWarningCounts[w] ?? 0) + 1;
        }

        // Compute top lists
        List<String> topTropes = initialTropeCounts.keys.toList()
          ..sort(
            (a, b) => initialTropeCounts[b]!.compareTo(initialTropeCounts[a]!),
          );
        List<String> topWarnings = initialWarningCounts.keys.toList()
          ..sort(
            (a, b) =>
                initialWarningCounts[b]!.compareTo(initialWarningCounts[a]!),
          );

        tx.set(bookRef, {
          'avgSpiceOnPage': spiceLevel,
          'totalUserRatings': prevSpice == null ? 1 : 1,
          'tropeCounts': initialTropeCounts,
          'warningCounts': initialWarningCounts,
          'topTropes': topTropes.take(5).toList(),
          'topWarnings': topWarnings.take(5).toList(),
        }, SetOptions(merge: true));
      } else {
        final data = bookSnap.data()!;
        final oldAvg = (data['avgSpiceOnPage'] as num?)?.toDouble() ?? 0.0;
        final count = (data['totalUserRatings'] as int?) ?? 0;
        double newAvg;
        int newCount = count;

        if (prevSpice == null) {
          // New rating
          newAvg = (oldAvg * count + spiceLevel) / (count + 1);
          newCount = count + 1;
        } else {
          // Update existing rating: replace previous value
          if (count == 0) {
            newAvg = spiceLevel;
            newCount = 1;
          } else {
            newAvg = ((oldAvg * count) - prevSpice + spiceLevel) / count;
            newCount = count;
          }
        }

        // Update trope and warning counts atomically:
        final Map<String, dynamic> rawTropeCounts = Map<String, dynamic>.from(
          (data['tropeCounts'] as Map?) ?? {},
        );
        final Map<String, dynamic> rawWarningCounts = Map<String, dynamic>.from(
          (data['warningCounts'] as Map?) ?? {},
        );

        final Map<String, int> tropeCounts = rawTropeCounts.map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        );
        final Map<String, int> warningCounts = rawWarningCounts.map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        );

        // Subtract previous tropes (if user updated their rating)
        for (final t in prevTropes) {
          tropeCounts[t] = (tropeCounts[t] ?? 1) - 1;
          if (tropeCounts[t]! <= 0) tropeCounts.remove(t);
        }
        for (final w in prevWarnings) {
          warningCounts[w] = (warningCounts[w] ?? 1) - 1;
          if (warningCounts[w]! <= 0) warningCounts.remove(w);
        }

        // Add new tropes/warnings
        for (final t in tropes ?? []) {
          tropeCounts[t] = (tropeCounts[t] ?? 0) + 1;
        }
        for (final w in warnings ?? []) {
          warningCounts[w] = (warningCounts[w] ?? 0) + 1;
        }

        // Compute top lists
        final List<String> topTropes = tropeCounts.keys.toList()
          ..sort((a, b) => tropeCounts[b]!.compareTo(tropeCounts[a]!));
        final List<String> topWarnings = warningCounts.keys.toList()
          ..sort((a, b) => warningCounts[b]!.compareTo(warningCounts[a]!));

        tx.update(bookRef, {
          'avgSpiceOnPage': newAvg,
          'totalUserRatings': newCount,
          'tropeCounts': tropeCounts,
          'warningCounts': warningCounts,
          'topTropes': topTropes.take(5).toList(),
          'topWarnings': topWarnings.take(5).toList(),
        });
      }
    });
  }

  /// Update the user's library UserBook document with user-specific fields.
  Future<void> setUserRating(UserBook userBook) async {
    if (_userId.isEmpty) throw Exception('User not signed in');
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('library')
        .doc(userBook.id)
        .update({
          'spiceSensual': userBook.spiceSensual,
          'spicePower': userBook.spicePower,
          'spiceIntensity': userBook.spiceIntensity,
          'spiceConsent': userBook.spiceConsent,
          'spiceEmotional': userBook.spiceEmotional,
          'userSelectedTropes': userBook.userSelectedTropes,
          'userContentWarnings': userBook.userContentWarnings,
          'userNotes': userBook.userNotes,
        });
  }

  /// Read a user's library entry
  Future<UserBook?> getUserRating(String userBookId) async {
    if (_userId.isEmpty) return null;
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('library')
        .doc(userBookId)
        .get();
    if (doc.exists) return UserBook.fromJson(doc.data()!);
    return null;
  }
}
