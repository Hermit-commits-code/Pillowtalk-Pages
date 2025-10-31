// lib/services/user_library_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_book.dart';

class UserLibraryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _libraryRef =>
      _firestore.collection('users').doc(_userId).collection('library');

  /// Add a book to the user's library
  Future<void> addBook(UserBook userBook) async {
    await _libraryRef.doc(userBook.id).set(userBook.toJson());
  }

  /// Update a book in the user's library
  Future<void> updateBook(UserBook userBook) async {
    await _libraryRef.doc(userBook.id).update(userBook.toJson());
  }

  /// Remove a book from the user's library
  Future<void> removeBook(String userBookId) async {
    await _libraryRef.doc(userBookId).delete();
  }

  /// Get all books in the user's library as a stream
  Stream<List<UserBook>> getUserLibraryStream() {
    return _libraryRef.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => UserBook.fromJson(doc.data())).toList(),
    );
  }

  /// Get a single book from the user's library
  Future<UserBook?> getUserBook(String userBookId) async {
    final doc = await _libraryRef.doc(userBookId).get();
    if (doc.exists) {
      return UserBook.fromJson(doc.data()!);
    }
    return null;
  }
}
