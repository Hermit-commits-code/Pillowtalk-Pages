// lib/services/user_library_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/user_book.dart';
import 'community_data_service.dart';
import 'google_books_service.dart';
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

  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in, cannot access library.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _libraryRef =>
      _firestore.collection('users').doc(_userId).collection('library');

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

    final bookJson = userBook.toJson();
    bookJson['dateAdded'] = FieldValue.serverTimestamp();

    final docRef = _libraryRef.doc(userBook.id);

    try {
      debugPrint('Attempting to write document: ${docRef.path}');
      await docRef.set(bookJson);

      debugPrint('Verifying write by reading back from server...');
      final snapshot = await docRef.get(
        const GetOptions(source: Source.server),
      );

      if (!snapshot.exists) {
        throw Exception(
          'Verification failed: Document does not exist on server after write.',
        );
      }

      debugPrint('SUCCESS: Document verified on server.');
    } on FirebaseException catch (e) {
      debugPrint(
        'FATAL: A FirebaseException occurred during write/verification: ${e.code} - ${e.message}',
      );
      throw Exception('Database Error: ${e.message}');
    } catch (e) {
      debugPrint(
        'FATAL: A general exception occurred during write/verification: $e',
      );
      throw Exception('An unexpected error occurred during save. Error: $e');
    }
  }

  Future<void> updateBook(UserBook userBook) async {
    try {
      debugPrint('Attempting to update book: ${userBook.id}');
      await _libraryRef.doc(userBook.id).update(userBook.toJson());
      debugPrint('Successfully updated book: ${userBook.id}');
    } on FirebaseException catch (e) {
      debugPrint('Firebase error updating book: ${e.code} - ${e.message}');
      throw Exception('Database Error: ${e.message}');
    } catch (e) {
      debugPrint('General error updating book: $e');
      throw Exception('An unexpected error occurred during update. Error: $e');
    }
  }

  Future<void> setBook(UserBook userBook) async {
    await _libraryRef.doc(userBook.id).set(userBook.toJson());
  }

  Future<void> setIgnoreFilters(String userBookId, bool ignore) async {
    await _libraryRef.doc(userBookId).set({
      'ignoreFilters': ignore,
    }, SetOptions(merge: true));
  }

  Future<void> removeBook(String userBookId) async {
    await _libraryRef.doc(userBookId).delete();
  }

  Stream<List<UserBook>> getUserLibraryStream() {
    return _libraryRef.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => UserBook.fromJson(doc.data())).toList(),
    );
  }

  Future<UserBook?> getUserBook(String userBookId) async {
    final doc = await _libraryRef.doc(userBookId).get();
    if (doc.exists) {
      return UserBook.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> backfillCachedCommunityFields({
    int concurrency = 6,
    void Function(int done, int total, int updated, int failed)? onProgress,
  }) async {
    final all = await getUserLibraryStream().first;
    final toProcess = all
        .where((ub) => ub.description == null || ub.description!.isEmpty)
        .toList();
    final total = toProcess.length;
    if (total == 0) {
      if (onProgress != null) onProgress(0, 0, 0, 0);
      return;
    }
    int done = 0, updated = 0, failed = 0;
    final community = CommunityDataService();
    final googleBooks = GoogleBooksService();

    for (var i = 0; i < toProcess.length; i += concurrency) {
      final batch = toProcess.skip(i).take(concurrency).toList();
      final futures = batch.map((ub) async {
        try {
          String? description;
          // First, try to get the description from the community data
          final communityDoc = await community.getCommunityBookData(ub.bookId);
          description = communityDoc?.description;

          // If community data is missing, fall back to Google Books
          if (description == null || description.isEmpty) {
            final googleBook = await googleBooks.getBookById(ub.bookId);
            description = googleBook?.description;
          }

          if (description != null && description.isNotEmpty) {
            await _libraryRef.doc(ub.id).update({'description': description});
            updated++;
          } else {
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
