// lib/services/user_preferences_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_preferences.dart';
import 'auth_service.dart';

class UserPreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _authService = AuthService.instance;

  String get _userId => _authService.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>> get _userPrefsDoc => _firestore
      .collection('users')
      .doc(_userId)
      .collection('preferences')
      .doc('settings');

  /// Stream of user preferences
  Stream<UserPreferences?> userPreferencesStream() {
    return _userPrefsDoc.snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return UserPreferences.fromJson({...data, 'userId': _userId});
    });
  }

  /// Get user preferences once
  Future<UserPreferences?> getUserPreferencesOnce() async {
    final snap = await _userPrefsDoc.get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return UserPreferences.fromJson({...data, 'userId': _userId});
  }

  /// Save user preferences
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    await _userPrefsDoc.set(preferences.toJson(), SetOptions(merge: true));
  }

  /// Create default preferences for a new user
  Future<void> createDefaultPreferences() async {
    final defaultPrefs = UserPreferences(userId: _userId);
    await saveUserPreferences(defaultPrefs);
  }
}
