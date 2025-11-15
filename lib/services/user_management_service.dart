// lib/services/user_management_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for developer-only user management operations
/// Only accessible to the developer account (hotcupofjoe2013@gmail.com)
class UserManagementService {
  static const String _developerEmail = 'hotcupofjoe2013@gmail.com';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Note: Cloud Functions have been removed. All operations now use Firestore directly.
  // This helper is kept for backwards compatibility but will not be used.

  /// Check if current user is the developer
  bool get isDeveloper {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email == _developerEmail;
  }

  /// Get user by email address
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    if (!isDeveloper) throw Exception('Access denied');
    try {
      final usersQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        final doc = usersQuery.docs.first;
        return {
          'uid': doc.id,
          'email': doc.data()['email'],
          'displayName': doc.data()['displayName'],
          'createdAt': doc.data()['createdAt'],
          'proStatus': doc.data()['proStatus'] ?? false,
          'librarian': doc.data()['librarian'] ?? false,
        };
      }
      return null;
    } catch (fe) {
      if (fe is FirebaseException && fe.code == 'permission-denied') {
        throw Exception(
          'Permission denied when reading user profiles. Ensure you are signed in as the developer.',
        );
      }
      throw Exception('Failed to find user: $fe');
    }
  }

  /// Set Pro status for a user
  Future<void> setProStatus(String uid, bool isPro) async {
    if (!isDeveloper) throw Exception('Access denied');
    try {
      await _firestore.collection('users').doc(uid).update({
        'proStatus': isPro,
        'proStatusUpdatedAt': FieldValue.serverTimestamp(),
        'proStatusUpdatedBy': _developerEmail,
      });
    } catch (fe) {
      if (fe is FirebaseException && fe.code == 'permission-denied') {
        throw Exception(
          'Permission denied when updating Pro status. Ensure you are signed in as the developer.',
        );
      }
      throw Exception('Failed to update Pro status: $fe');
    }
  }

  /// Set Librarian status for a user
  Future<void> setLibrarianStatus(String uid, bool isLibrarian) async {
    if (!isDeveloper) throw Exception('Access denied');
    try {
      await _firestore.collection('users').doc(uid).update({
        'librarian': isLibrarian,
        'librarianStatusUpdatedAt': FieldValue.serverTimestamp(),
        'librarianStatusUpdatedBy': _developerEmail,
      });
    } catch (fe) {
      if (fe is FirebaseException && fe.code == 'permission-denied') {
        throw Exception(
          'Permission denied when updating Librarian status. Ensure you are signed in as the developer.',
        );
      }
      throw Exception('Failed to update Librarian status: $fe');
    }
  }

  /// Get all Pro users (for admin overview)
  Future<List<Map<String, dynamic>>> getProUsers() async {
    if (!isDeveloper) throw Exception('Access denied');
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('proStatus', isEqualTo: true)
          .get();
      return snapshot.docs
          .map(
            (doc) => {
              'uid': doc.id,
              'email': doc.data()['email'],
              'displayName': doc.data()['displayName'],
              'proStatusUpdatedAt': doc.data()['proStatusUpdatedAt'],
            },
          )
          .toList();
    } catch (fe) {
      if (fe is FirebaseException && fe.code == 'permission-denied') {
        throw Exception(
          'Permission denied when reading Pro users. Ensure you are signed in as the developer.',
        );
      }
      throw Exception('Failed to get Pro users: $fe');
    }
  }

  /// Debug helper: call a callable function and return raw data (no casting).
  /// Useful for debugging mismatches between the callable response and client-side parsing.
  Future<dynamic> callRawCallable(
    String name, [
    Map<String, dynamic>? params,
  ]) async {
    if (!isDeveloper) throw Exception('Access denied');
    try {
      final res = await _functions.httpsCallable(name).call(params ?? {});
      return res.data;
    } on FirebaseFunctionsException catch (ffe) {
      throw Exception('Cloud Function $name failed: ${ffe.message}');
    } catch (e) {
      throw Exception('Cloud Function $name error: $e');
    }
  }

  /// Get all Librarian users (for admin overview)
  Future<List<Map<String, dynamic>>> getLibrarians() async {
    if (!isDeveloper) throw Exception('Access denied');
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('librarian', isEqualTo: true)
          .get();
      return snapshot.docs
          .map(
            (doc) => {
              'uid': doc.id,
              'email': doc.data()['email'],
              'displayName': doc.data()['displayName'],
              'librarianStatusUpdatedAt': doc
                  .data()['librarianStatusUpdatedAt'],
            },
          )
          .toList();
    } catch (fe) {
      if (fe is FirebaseException && fe.code == 'permission-denied') {
        throw Exception(
          'Permission denied when reading Librarians. Ensure you are signed in as the developer.',
        );
      }
      throw Exception('Failed to get Librarians: $fe');
    }
  }

  /// Search users by email pattern (for admin tools)
  Future<List<Map<String, dynamic>>> searchUsers(String emailPattern) async {
    if (!isDeveloper) throw Exception('Access denied');
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: emailPattern.toLowerCase())
          .where('email', isLessThan: '${emailPattern.toLowerCase()}\\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .map(
            (doc) => {
              'uid': doc.id,
              'email': doc.data()['email'],
              'displayName': doc.data()['displayName'],
              'proStatus': doc.data()['proStatus'] ?? false,
              'librarian': doc.data()['librarian'] ?? false,
              'createdAt': doc.data()['createdAt'],
            },
          )
          .toList();
    } catch (fe) {
      if (fe is FirebaseException && fe.code == 'permission-denied') {
        throw Exception(
          'Permission denied when searching users. Ensure you are signed in as the developer.',
        );
      }
      throw Exception('Failed to search users: $fe');
    }
  }

  /// Lightweight check to validate developer access
  Future<Map<String, dynamic>> pingAdmin() async {
    if (!isDeveloper) throw Exception('Access denied');
    return {
      'ok': true,
      'isDeveloper': true,
      'now': DateTime.now().millisecondsSinceEpoch,
    };
  }
}
