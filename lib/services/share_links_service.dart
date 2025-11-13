import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/share_link.dart';

class ShareLinksService {
  static final ShareLinksService _instance = ShareLinksService._internal();

  factory ShareLinksService() {
    return _instance;
  }

  ShareLinksService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  /// Generate a random token for share link
  String _generateToken() {
    const characters =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789';
    final random = Random.secure();
    return List.generate(32, (index) => characters[random.nextInt(characters.length)])
        .join();
  }

  /// Create a new share link
  Future<ShareLink> createShareLink({
    required String type, // 'reading-progress' | 'reading-goal' | 'spicy-tbr'
    int expirationDays = 30,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentUserId.isEmpty) throw Exception('User not authenticated');

    try {
      final token = _generateToken();
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: expirationDays));

      final shareLink = ShareLink(
        shareId: token,
        ownerId: _currentUserId,
        type: type,
        createdAt: now,
        expiresAt: expiresAt,
        metadata: metadata,
      );

      await _firestore.collection('shares').doc(token).set(shareLink.toFirestore());

      return shareLink;
    } catch (e) {
      throw Exception('Failed to create share link: $e');
    }
  }

  /// Get a share link by token
  Future<ShareLink?> getShareLink(String token) async {
    try {
      final doc = await _firestore.collection('shares').doc(token).get();

      if (!doc.exists) {
        return null;
      }

      final shareLink = ShareLink.fromFirestore(doc);

      // Check if link is expired
      if (!shareLink.isValid) {
        return null;
      }

      // Increment access count
      await _firestore
          .collection('shares')
          .doc(token)
          .update({'accessCount': FieldValue.increment(1)});

      return shareLink;
    } catch (e) {
      throw Exception('Failed to get share link: $e');
    }
  }

  /// Revoke a share link (makes it invalid)
  Future<void> revokeShareLink(String token) async {
    if (_currentUserId.isEmpty) throw Exception('User not authenticated');

    try {
      final doc = await _firestore.collection('shares').doc(token).get();

      if (!doc.exists) {
        throw Exception('Share link not found');
      }

      final shareLink = ShareLink.fromFirestore(doc);

      // Verify ownership
      if (shareLink.ownerId != _currentUserId) {
        throw Exception('You can only revoke your own share links');
      }

      await _firestore
          .collection('shares')
          .doc(token)
          .update({'revoked': true});
    } catch (e) {
      throw Exception('Failed to revoke share link: $e');
    }
  }

  /// Get all active share links for current user
  Stream<List<ShareLink>> getMyShareLinksStream() {
    if (_currentUserId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('shares')
        .where('ownerId', isEqualTo: _currentUserId)
        .where('revoked', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => ShareLink.fromFirestore(doc))
          .where((link) => link.expiresAt.isAfter(now))
          .toList();
    });
  }

  /// Delete an expired share link
  Future<void> deleteShareLink(String token) async {
    if (_currentUserId.isEmpty) throw Exception('User not authenticated');

    try {
      final doc = await _firestore.collection('shares').doc(token).get();

      if (!doc.exists) {
        throw Exception('Share link not found');
      }

      final shareLink = ShareLink.fromFirestore(doc);

      // Verify ownership
      if (shareLink.ownerId != _currentUserId) {
        throw Exception('You can only delete your own share links');
      }

      await _firestore.collection('shares').doc(token).delete();
    } catch (e) {
      throw Exception('Failed to delete share link: $e');
    }
  }

  /// Clean up expired share links (can be called periodically)
  Future<void> cleanupExpiredLinks() async {
    try {
      final now = Timestamp.now();
      final query = await _firestore
          .collection('shares')
          .where('expiresAt', isLessThan: now)
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to cleanup expired links: $e');
    }
  }
}
