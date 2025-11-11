// lib/services/kink_filter_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class KinkFilterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _authService = AuthService.instance;

  String get _userId => _authService.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_userId);

  Stream<List<String>> kinkFilterStream() {
    return _userDoc.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return <String>[];
      final raw = data['kinkFilter'];
      if (raw is List) return List<String>.from(raw.map((e) => e.toString()));
      return <String>[];
    });
  }

  Stream<bool> kinkFilterEnabledStream() {
    return _userDoc.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return true;
      final raw = data['kinkFilterEnabled'];
      if (raw is bool) return raw;
      return true;
    });
  }

  Future<void> setKinkFilter(List<String> filters) async {
    await _userDoc.set({'kinkFilter': filters}, SetOptions(merge: true));
  }

  Future<void> setKinkFilterEnabled(bool enabled) async {
    await _userDoc.set({'kinkFilterEnabled': enabled}, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getKinkFilterOnce() async {
    final snap = await _userDoc.get();
    final data = snap.data() ?? {};
    final filters = (data['kinkFilter'] is List)
        ? List<String>.from(data['kinkFilter'].map((e) => e.toString()))
        : <String>[];
    final enabled = data['kinkFilterEnabled'] is bool
        ? data['kinkFilterEnabled'] as bool
        : true;
    return {'kinkFilter': filters, 'enabled': enabled};
  }
}
