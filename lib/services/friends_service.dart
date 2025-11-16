import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/friend.dart';

class FriendsService {
  static final FriendsService _instance = FriendsService._internal();

  factory FriendsService() {
    return _instance;
  }

  FriendsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  /// Send a friend request (creates pending friend entry)
  Future<void> sendFriendRequest(String targetUserId) async {
    if (_currentUserId.isEmpty) throw Exception('User not authenticated');
    if (targetUserId == _currentUserId) {
      throw Exception('Cannot add yourself as a friend');
    }

    try {
      final friend = Friend(
        friendId: targetUserId,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(targetUserId)
          .set(friend.toFirestore());
    } catch (e) {
      // Log detailed FirebaseException data when available for diagnostics
      if (e is FirebaseException) {
        // ignore: avoid_print
        print('[Friends] FirebaseException code=${e.code} message=${e.message}');
      }
      throw Exception('Failed to send friend request: $e');
    }
  }

  /// Send a friend request to the target user's inbox (creates pending entry
  /// under the target user's `users/{targetUid}/friends/{senderUid}` so the
  /// recipient will see the request in their pending stream).
  Future<void> sendFriendRequestToUser(String targetUserId) async {
    if (_currentUserId.isEmpty) throw Exception('User not authenticated');
    if (targetUserId == _currentUserId) {
      throw Exception('Cannot add yourself as a friend');
    }

    try {
      // Debug: ensure we know who is making the request
      // ignore: avoid_print
      print('[Friends] sendFriendRequestToUser: currentUser=$_currentUserId, target=$targetUserId');
      // ignore: avoid_print
      print('[Friends] auth current user (email): ${_auth.currentUser?.email}');
      final friend = Friend(
        friendId: _currentUserId,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('friends')
          .doc(_currentUserId)
          .set(friend.toFirestore());
    } catch (e) {
      throw Exception('Failed to send friend request: $e');
    }
  }

  /// Accept a pending friend request
  Future<void> acceptFriendRequest(String friendId) async {
    if (_currentUserId.isEmpty) throw Exception('User not authenticated');

    try {
      final friendRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(friendId);

      // Debug: print the path we're going to read
      // ignore: avoid_print
      print('Accepting friend request at: ${friendRef.path}');

      final docSnapshot = await friendRef.get();
      // Debug: dump snapshot existence and raw data for diagnostics
      // ignore: avoid_print
      print('Friend doc exists: ${docSnapshot.exists}');
      // ignore: avoid_print
      print('Friend doc data: ${docSnapshot.data()}');
      if (!docSnapshot.exists) {
        throw Exception('Friend request not found');
      }

      final friend = Friend.fromFirestore(docSnapshot);
      if (friend.status != 'pending') {
        throw Exception('Can only accept pending friend requests');
      }

      // Update the current user's friend doc to accepted and also ensure the
      // other user's friends collection contains a reciprocal accepted entry.
      final batch = _firestore.batch();

      batch.update(friendRef, {
        'status': 'accepted',
        'acceptedAt': Timestamp.now(),
      });

      final otherUserFriendRef = _firestore
          .collection('users')
          .doc(friend.friendId)
          .collection('friends')
          .doc(_currentUserId);

      final reciprocal = Friend(
        friendId: _currentUserId,
        status: 'accepted',
        createdAt: friend.createdAt,
        acceptedAt: DateTime.now(),
      );

      batch.set(
        otherUserFriendRef,
        reciprocal.toFirestore(),
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e, st) {
      // Log full stacktrace for diagnostics
      // ignore: avoid_print
      print('Failed to accept friend request: $e');
      // ignore: avoid_print
      print(st.toString());
      throw Exception('Failed to accept friend request: ${e.toString()}');
    }
  }

  /// Decline a pending friend request
  Future<void> declineFriendRequest(String friendId) async {
    if (_currentUserId.isEmpty) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(friendId)
          .delete();
    } catch (e) {
      throw Exception('Failed to decline friend request: $e');
    }
  }

  /// Remove an accepted friend
  Future<void> removeFriend(String friendId) async {
    if (_currentUserId.isEmpty) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(friendId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }

  /// Block a friend (prevents them from contacting you)
  Future<void> blockFriend(String friendId) async {
    if (_currentUserId.isEmpty) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(friendId)
          .update({'status': 'blocked'});
    } catch (e) {
      throw Exception('Failed to block friend: $e');
    }
  }

  /// Unblock a friend
  Future<void> unblockFriend(String friendId) async {
    if (_currentUserId.isEmpty) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(friendId)
          .update({'status': 'accepted'});
    } catch (e) {
      throw Exception('Failed to unblock friend: $e');
    }
  }

  /// Update sharing preferences with a friend
  Future<void> updateSharingPreferences(
    String friendId, {
    bool? readingProgress,
    bool? spiceRatings,
    bool? hardStops,
    bool? reviews,
  }) async {
    if (_currentUserId.isEmpty) throw Exception('User not authenticated');

    try {
      final updates = <String, dynamic>{};

      if (readingProgress != null) {
        updates['sharing.readingProgress'] = readingProgress;
      }
      if (spiceRatings != null) {
        updates['sharing.spiceRatings'] = spiceRatings;
      }
      if (hardStops != null) {
        updates['sharing.hardStops'] = hardStops;
      }
      if (reviews != null) {
        updates['sharing.reviews'] = reviews;
      }

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(friendId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update sharing preferences: $e');
    }
  }

  /// Get all friends (accepted only)
  Stream<List<Friend>> getAcceptedFriendsStream() {
    if (_currentUserId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
          final friends = snapshot.docs
              .map((doc) => Friend.fromFirestore(doc))
              .toList();
          // Sort in Dart to avoid composite index requirement
          friends.sort((a, b) {
            final aTime = a.acceptedAt ?? DateTime.now();
            final bTime = b.acceptedAt ?? DateTime.now();
            return bTime.compareTo(aTime);
          });
          return friends;
        });
  }

  /// Get pending friend requests
  Stream<List<Friend>> getPendingFriendRequestsStream() {
    if (_currentUserId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('friends')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => Friend.fromFirestore(doc))
              .toList();
          // Sort in Dart to avoid composite index requirement
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  /// Get a specific friend
  Future<Friend?> getFriend(String friendId) async {
    if (_currentUserId.isEmpty) throw Exception('User not authenticated');

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(friendId)
          .get();

      return doc.exists ? Friend.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Failed to get friend: $e');
    }
  }

  /// Check if users are friends
  Future<bool> areFriends(String otherId) async {
    if (_currentUserId.isEmpty) throw Exception('User not authenticated');

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('friends')
          .doc(otherId)
          .get();

      if (!doc.exists) return false;

      final friend = Friend.fromFirestore(doc);
      return friend.status == 'accepted';
    } catch (e) {
      return false;
    }
  }
}
