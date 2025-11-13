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

      final docSnapshot = await friendRef.get();
      if (!docSnapshot.exists) {
        throw Exception('Friend request not found');
      }

      final friend = Friend.fromFirestore(docSnapshot);
      if (friend.status != 'pending') {
        throw Exception('Can only accept pending friend requests');
      }

      await friendRef.update({
        'status': 'accepted',
        'acceptedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to accept friend request: $e');
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
        .orderBy('acceptedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Friend.fromFirestore(doc))
            .toList());
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Friend.fromFirestore(doc))
            .toList());
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
