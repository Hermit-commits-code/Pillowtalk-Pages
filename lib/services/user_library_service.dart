// lib/services/user_library_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/user_book.dart';
import 'pro_status_service.dart';
import 'pro_exceptions.dart';

class UserLibraryService {
  /// Optional override for the current user id. Useful for single-user
  /// setups or testing where FirebaseAuth may not be used.
  final String? _overrideUserId;

  UserLibraryService([this._overrideUserId]);
  static const int freeUserBookLimit = 2;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _userId {
    if (_overrideUserId != null && _overrideUserId.isNotEmpty) {
      return _overrideUserId;
    }
    final user = AuthService.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in, cannot access library.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _libraryRef =>
      _firestore.collection('users').doc(_userId).collection('library');

  Future<void> addBook(UserBook userBook) async {
    // Enforce Pro gating for adding books: users who are not Pro may only
    // add up to `freeUserBookLimit` books. They can always read their library.
    final proService = ProStatusService();
    final isPro = await proService.isPro();

    if (!isPro) {
      try {
        final current = await _libraryRef.get();
        if (current.docs.length >= freeUserBookLimit) {
          throw ProUpgradeRequiredException(
            'Upgrade to Pro to add more books. Visit The Connoisseur\'s Club to upgrade.',
          );
        }
      } catch (e) {
        // If it's a firebase exception or other, rethrow so callers can show a message.
        if (e is ProUpgradeRequiredException) rethrow;
        debugPrint('Error checking existing library size: $e');
        // Allow attempt to continue if incidental read failed; downstream
        // write will still surface an error if it fails.
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

  /// Return top tropes from the current user's library (counts both
  /// cachedTropes and userSelectedTropes). Used for personal autocomplete.
  Future<List<String>> getTopTropesFromLibrary({int limit = 50}) async {
    try {
      final snap = await _libraryRef.get();
      final Map<String, int> counts = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final cached = List.from(
          data['cachedTropes'] ?? <dynamic>[],
        ).map((e) => e.toString()).toList();
        final selected = List.from(
          data['userSelectedTropes'] ?? <dynamic>[],
        ).map((e) => e.toString()).toList();
        for (final t in {...cached, ...selected}) {
          final key = t.trim();
          if (key.isEmpty) continue;
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
      final sorted = counts.keys.toList()
        ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
      return sorted.take(limit).toList();
    } catch (e) {
      debugPrint('getTopTropesFromLibrary failed: $e');
      return <String>[];
    }
  }

  /// Search the current user's library for books that include the given
  /// trope in either cachedTropes or userSelectedTropes. Returns a list of
  /// RomanceBook objects (id = bookId) suitable for display/navigation.
  Future<List<UserBook>> searchLibraryByTrope(
    String trope, {
    int limit = 50,
  }) async {
    try {
      final results = <UserBook>[];
      // Query both fields (Firestore doesn't support OR), so run two queries
      final q1 = await _libraryRef
          .where('cachedTropes', arrayContains: trope)
          .limit(limit)
          .get();
      final q2 = await _libraryRef
          .where('userSelectedTropes', arrayContains: trope)
          .limit(limit)
          .get();

      final seen = <String>{};
      void addFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        final data = doc.data();
        final ub = UserBook.fromJson(data);
        final bookId = ub.bookId;
        if (seen.contains(bookId)) return;
        seen.add(bookId);
        results.add(ub);
      }

      for (final d in q1.docs) {
        addFromDoc(d);
      }
      for (final d in q2.docs) {
        addFromDoc(d);
      }

      return results;
    } catch (e) {
      debugPrint('searchLibraryByTrope failed: $e');
      return <UserBook>[];
    }
  }

  Future<UserBook?> getUserBook(String userBookId) async {
    final doc = await _libraryRef.doc(userBookId).get();
    if (doc.exists) {
      return UserBook.fromJson(doc.data()!);
    }
    return null;
  }

  /// Search the current user's library with combined filters.
  ///
  /// Behavior:
  /// - If only `genres` provided: performs an `array-contains-any` on `genres` (OR semantics).
  /// - If only `tropes` provided: performs `array-contains-any` on both `cachedTropes` and
  ///   `userSelectedTropes` and merges results (OR semantics).
  /// - If both provided: queries using the smaller selection (to limit server results) and
  ///   client-side filters to require at least one match from each selected category
  ///   (i.e., OR within a category, AND across categories).
  /// - If `status` or `ownership` provided they are added to the primary server-side query
  ///   when possible to reduce the candidate set.
  Future<List<UserBook>> searchLibraryByFilters({
    List<String>? genres,
    List<String>? tropes,
    ReadingStatus? status,
    BookOwnership? ownership,
    List<String>? hardStops,
    List<String>? kinkFilters,
    bool applyUserFilters = true,
    int limit = 200,
  }) async {
    try {
      // Normalize inputs
      final selGenres = (genres ?? [])
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final selTropes = (tropes ?? [])
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // If nothing provided, return empty
      if (selGenres.isEmpty &&
          selTropes.isEmpty &&
          status == null &&
          ownership == null) {
        return <UserBook>[];
      }

      final results = <UserBook>[];
      final seen = <String>{};

      // Helper to add doc results
      void addFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        final ub = UserBook.fromJson(doc.data());
        if (seen.contains(ub.bookId)) return;
        seen.add(ub.bookId);
        results.add(ub);
      }

      // Build base query with optional status/ownership
      Query<Map<String, dynamic>> baseQuery = _libraryRef;
      if (status != null) {
        baseQuery = baseQuery.where('status', isEqualTo: status.name);
      }
      if (ownership != null) {
        baseQuery = baseQuery.where('ownership', isEqualTo: ownership.name);
      }

      // If only genres
      if (selGenres.isNotEmpty && selTropes.isEmpty) {
        if (selGenres.length <= 10) {
          final q = await baseQuery
              .where('genres', arrayContainsAny: selGenres)
              .limit(limit)
              .get();
          for (final d in q.docs) {
            addFromDoc(d);
          }
        } else {
          // Too many values for array-contains-any: fetch all and filter client-side
          final q = await baseQuery.get();
          for (final d in q.docs) {
            final ub = UserBook.fromJson(d.data());
            if (ub.genres.any((g) => selGenres.contains(g))) {
              addFromDoc(d);
            }
          }
        }
        return results;
      }

      // If only tropes
      if (selTropes.isNotEmpty && selGenres.isEmpty) {
        if (selTropes.length <= 10) {
          final q1 = await baseQuery
              .where('cachedTropes', arrayContainsAny: selTropes)
              .limit(limit)
              .get();
          final q2 = await baseQuery
              .where('userSelectedTropes', arrayContainsAny: selTropes)
              .limit(limit)
              .get();
          for (final d in q1.docs) {
            addFromDoc(d);
          }
          for (final d in q2.docs) {
            addFromDoc(d);
          }
        } else {
          // Fallback: fetch all and filter client-side
          final q = await baseQuery.get();
          for (final d in q.docs) {
            final ub = UserBook.fromJson(d.data());
            final tropesUnion = {
              ...ub.cachedTropes,
              ...ub.userSelectedTropes,
            }.map((t) => t.trim()).toSet();
            if (tropesUnion.any((t) => selTropes.contains(t))) {
              addFromDoc(d);
            }
          }
        }
        return results;
      }

      // Both genres and tropes provided: pick the smaller selector for server query
      final useGenresFirst =
          selGenres.length <= (selTropes.isEmpty ? 9999 : selTropes.length);

      if (useGenresFirst) {
        if (selGenres.length <= 10) {
          final q = await baseQuery
              .where('genres', arrayContainsAny: selGenres)
              .limit(limit)
              .get();
          for (final d in q.docs) {
            addFromDoc(d);
          }
        } else {
          final q = await baseQuery.get();
          for (final d in q.docs) {
            addFromDoc(d);
          }
        }
      } else {
        if (selTropes.length <= 10) {
          final q1 = await baseQuery
              .where('cachedTropes', arrayContainsAny: selTropes)
              .limit(limit)
              .get();
          final q2 = await baseQuery
              .where('userSelectedTropes', arrayContainsAny: selTropes)
              .limit(limit)
              .get();
          for (final d in q1.docs) {
            addFromDoc(d);
          }
          for (final d in q2.docs) {
            addFromDoc(d);
          }
        } else {
          final q = await baseQuery.get();
          for (final d in q.docs) {
            addFromDoc(d);
          }
        }
      }

      // Client-side filter to ensure book matches at least one genre AND at least one trope
      var filtered = results.where((ub) {
        final matchesGenre =
            selGenres.isEmpty || ub.genres.any((g) => selGenres.contains(g));
        final tropesUnion = {
          ...ub.cachedTropes,
          ...ub.userSelectedTropes,
        }.map((t) => t.trim()).toSet();
        final matchesTrope =
            selTropes.isEmpty || tropesUnion.any((t) => selTropes.contains(t));
        return matchesGenre && matchesTrope;
      }).toList();

      // Apply Hard Stops filter if provided and applyUserFilters is true
      if (applyUserFilters && hardStops != null && hardStops.isNotEmpty) {
        filtered = filtered.where((ub) {
          // Skip filtering if book has ignoreFilters flag set
          if (ub.ignoreFilters) return true;
          
          // Check if any warning matches hard stops
          final bookWarnings = {
            ...ub.cachedTopWarnings,
            ...ub.userContentWarnings,
          }.map((w) => w.trim()).toSet();
          
          final hasHardStop = bookWarnings.any((w) => hardStops.contains(w));
          return !hasHardStop; // Return true if NO hard stop match
        }).toList();
      }

      // Apply Kink Filter if provided and applyUserFilters is true
      if (applyUserFilters && kinkFilters != null && kinkFilters.isNotEmpty) {
        filtered = filtered.where((ub) {
          // Skip filtering if book has ignoreFilters flag set
          if (ub.ignoreFilters) return true;
          
          // Check if any trope matches kink filters
          final bookTropes = {
            ...ub.cachedTropes,
            ...ub.userSelectedTropes,
          }.map((t) => t.trim()).toSet();
          
          final hasKinkFilter = bookTropes.any((t) => kinkFilters.contains(t));
          return !hasKinkFilter; // Return true if NO kink filter match
        }).toList();
      }

      return filtered;
    } catch (e) {
      debugPrint('searchLibraryByFilters failed: $e');
      return <UserBook>[];
    }
  }
}
