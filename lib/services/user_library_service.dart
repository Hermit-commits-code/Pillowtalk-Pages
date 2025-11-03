// lib/services/user_library_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/user_book.dart';
import 'community_data_service.dart';
import 'pro_status_service.dart';

class ProUpgradeRequiredException implements Exception {
  final String message;
  ProUpgradeRequiredException(this.message);
  @override
  String toString() => message;
}

class UserLibraryService {
  static const int freeUserBookLimit = 2;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _libraryRef =>
      _firestore.collection('users').doc(_userId).collection('library');

  /// Add a book to the user's library, enforcing free user limit
  Future<void> addBook(UserBook userBook) async {
    final isPro = await ProStatusService().isPro();
    if (!isPro) {
      final count = await _libraryRef.count().get().then(
        (snap) => snap.count ?? 0,
      );
      if (count >= freeUserBookLimit) {
        throw ProUpgradeRequiredException(
          'Free users can only track up to $freeUserBookLimit books. Upgrade to Pro for unlimited tracking.',
        );
      }
    }
    // Cache community fields (topWarnings, communityTropes) on the user library doc
    try {
      final community = CommunityDataService();
      final bookData = await community.getCommunityBookData(userBook.bookId);
      final base = userBook.toJson();
      if (bookData != null) {
        base['cachedTopWarnings'] = bookData.topWarnings;
        base['cachedTropes'] = bookData.communityTropes;
        base['cachedGenre'] = bookData.genre;
      }
      await _libraryRef.doc(userBook.id).set(base);
    } catch (e) {
      debugPrint(
        'Failed to cache community data for userBook ${userBook.id}: $e',
      );
      await _libraryRef.doc(userBook.id).set(userBook.toJson());
    }
  }

  /// Update a book in the user's library
  Future<void> updateBook(UserBook userBook) async {
    await _libraryRef.doc(userBook.id).update(userBook.toJson());
  }

  /// Set (create or overwrite) a user library document without enforcing limits.
  Future<void> setBook(UserBook userBook) async {
    await _libraryRef.doc(userBook.id).set(userBook.toJson());
  }

  /// Set the per-user ignoreFilters flag on a userLibrary doc.
  Future<void> setIgnoreFilters(String userBookId, bool ignore) async {
    await _libraryRef.doc(userBookId).set({
      'ignoreFilters': ignore,
    }, SetOptions(merge: true));
  }

  /// Remove a book from the user's library
  Future<void> removeBook(String userBookId) async {
    debugPrint('UserLibraryService.removeBook called with ID: $userBookId');
    debugPrint('User ID: $_userId');
    debugPrint('Full path: users/$_userId/library/$userBookId');
    try {
      await _libraryRef.doc(userBookId).delete();
      debugPrint('Delete operation completed successfully');
    } catch (e) {
      debugPrint('Error deleting book: $e');
      rethrow;
    }
  }

  /// Get all books in the user's library as a stream
  Stream<List<UserBook>> getUserLibraryStream() {
    return _libraryRef.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => UserBook.fromJson(doc.data())).toList(),
    );
  }

  /// Get a single book from the user's library
  Future<UserBook?> getUserBook(String userBookId) async {
    final doc = await _libraryRef.doc(userBookId).get();
    if (doc.exists) {
      return UserBook.fromJson(doc.data()!);
    }
    return null;
  }

  /// Backfill cached community fields for existing user library entries.
  ///
  /// Scans the user's library and for any entry missing `cachedTopWarnings`
  /// or `cachedTropes`, fetches community data and writes those fields.
  /// Calls [onProgress] with (done, total, updated, failed) to report progress.
  Future<void> backfillCachedCommunityFields({
    int concurrency = 6,
    void Function(int done, int total, int updated, int failed)? onProgress,
  }) async {
    final all = await getUserLibraryStream().first;
    final toProcess = all
        .where(
          (ub) =>
              (ub.cachedTopWarnings.isEmpty && ub.cachedTropes.isEmpty) ||
              (ub.cachedTopWarnings.isEmpty) ||
              (ub.cachedTropes.isEmpty),
        )
        .toList();
    final total = toProcess.length;
    if (total == 0) {
      if (onProgress != null) onProgress(0, 0, 0, 0);
      return;
    }
    int done = 0, updated = 0, failed = 0;
    final community = CommunityDataService();

    // process in batches to bound concurrency
    for (var i = 0; i < toProcess.length; i += concurrency) {
      final batch = toProcess.skip(i).take(concurrency).toList();
      final futures = batch.map((ub) async {
        try {
          final doc = await community.getCommunityBookData(ub.bookId);
          if (doc != null) {
            await _libraryRef.doc(ub.id).set({
              'cachedTopWarnings': doc.topWarnings,
              'cachedTropes': doc.communityTropes,
              'cachedGenre': doc.genre,
            }, SetOptions(merge: true));
            updated++;
          } else {
            // mark as failed to find community doc
            failed++;
          }
        } catch (_) {
          failed++;
        } finally {
          done++;
          if (onProgress != null) onProgress(done, total, updated, failed);
        }
      });
      await Future.wait(futures);
    }
  }
}
