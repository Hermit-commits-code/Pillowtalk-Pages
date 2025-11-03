// lib/services/hard_stops_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HardStopsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_userId);

  /// Stream of the user's hard stops list (empty list if not set)
  Stream<List<String>> hardStopsStream() {
    return _userDoc.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return <String>[];
      final raw = data['hardStops'];
      if (raw is List) return List<String>.from(raw.map((e) => e.toString()));
      return <String>[];
    });
  }

  /// Stream of whether hard stops are enabled for the user (defaults to true)
  Stream<bool> hardStopsEnabledStream() {
    return _userDoc.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return true;
      final raw = data['hardStopsEnabled'];
      if (raw is bool) return raw;
      return true;
    });
  }

  Future<void> setHardStops(List<String> stops) async {
    await _userDoc.set({'hardStops': stops}, SetOptions(merge: true));
  }

  Future<void> setHardStopsEnabled(bool enabled) async {
    await _userDoc.set({'hardStopsEnabled': enabled}, SetOptions(merge: true));
  }

  /// Convenience: fetch both values once
  Future<Map<String, dynamic>> getHardStopsOnce() async {
    final snap = await _userDoc.get();
    final data = snap.data() ?? {};
    final stops = (data['hardStops'] is List)
        ? List<String>.from(data['hardStops'].map((e) => e.toString()))
        : <String>[];
    final enabled = data['hardStopsEnabled'] is bool
        ? data['hardStopsEnabled'] as bool
        : true;
    return {'hardStops': stops, 'enabled': enabled};
  }
}
