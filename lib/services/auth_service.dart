import 'package:firebase_auth/firebase_auth.dart';

/// Small wrapper around `FirebaseAuth` to make auth calls injectable and
/// mockable in widget tests.
class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService([FirebaseAuth? firebaseAuth])
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static final AuthService instance = AuthService();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Create a new user with email/password.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in anonymously (useful for QA/dev flows).
  Future<UserCredential> signInAnonymously() {
    return _firebaseAuth.signInAnonymously();
  }

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<void> signOut() => _firebaseAuth.signOut();
}
