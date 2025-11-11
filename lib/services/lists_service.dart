import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

import '../models/user_list.dart';
import 'analytics_service.dart';
import 'package:flutter/foundation.dart';

/// Service to manage user-created lists (shelves) and book membership.
class ListsService {
  final String? _overrideUserId;
  final FirebaseFirestore _firestore;

  /// Accept an optional overrideUserId and optional firestore instance for testing.
  ListsService([this._overrideUserId, FirebaseFirestore? firestore])
    : _firestore = firestore ?? FirebaseFirestore.instance;

  String get _userId {
    final override = _overrideUserId;
    if (override != null && override.isNotEmpty) return override;
    final user = AuthService.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _listsRef =>
      _firestore.collection('users').doc(_userId).collection('lists');

  Stream<List<UserList>> getUserListsStream() {
    try {
      // Accessing _listsRef will attempt to read the current user id. If the
      // user is not logged in or Firebase isn't initialized yet, that getter
      // throws; catch and return an empty stream so callers (StreamBuilder)
      // can render an empty state instead of waiting indefinitely.
      final ref = _listsRef;
      return ref.snapshots().map(
        (snap) => snap.docs
            .map((d) => UserList.fromJson({...d.data(), 'id': d.id}))
            .toList(),
      );
    } catch (e) {
      // Return an immediate empty list stream to avoid UI hangs.
      return Stream.value(<UserList>[]);
    }
  }

  Future<UserList> createList({
    required String name,
    String? description,
    bool isPrivate = true,
  }) async {
    final docRef = _listsRef.doc();
    final id = docRef.id;
    final payload = {
      'id': id,
      'userId': _userId,
      'name': name,
      'description': description,
      'isPrivate': isPrivate,
      'bookIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(payload);
    final snapshot = await docRef.get();
    // Analytics: record list creation
    try {
      await AnalyticsService.instance.logCreateList(listId: id, name: name);
    } catch (e) {
      if (kDebugMode) debugPrint('Analytics logCreateList failed: $e');
    }
    return UserList.fromJson({...snapshot.data()!, 'id': id});
  }

  Future<void> updateList(UserList list) async {
    final doc = _listsRef.doc(list.id);
    final data = list.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data, SetOptions(merge: true));
  }

  Future<void> deleteList(String listId) async {
    await _listsRef.doc(listId).delete();
  }

  Future<void> addBookToList(String listId, String userBookId) async {
    await _listsRef.doc(listId).set({
      'bookIds': FieldValue.arrayUnion([userBookId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    try {
      await AnalyticsService.instance.logAddBookToList(
        listId: listId,
        userBookId: userBookId,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Analytics logAddBookToList failed: $e');
    }
  }

  Future<void> removeBookFromList(String listId, String userBookId) async {
    await _listsRef.doc(listId).set({
      'bookIds': FieldValue.arrayRemove([userBookId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    try {
      await AnalyticsService.instance.logRemoveBookFromList(
        listId: listId,
        userBookId: userBookId,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Analytics logRemoveBookFromList failed: $e');
    }
  }

  Future<void> addBookToLists(List<String> listIds, String userBookId) async {
    if (listIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in listIds) {
      final ref = _listsRef.doc(id);
      batch.set(ref, {
        'bookIds': FieldValue.arrayUnion([userBookId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
