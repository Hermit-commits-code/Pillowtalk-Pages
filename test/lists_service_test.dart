import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:spicyreads/services/lists_service.dart';
// models imported by ListsService are exercised via Firestore documents; no direct model import required here.

void main() {
  group('ListsService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ListsService listsService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      // Provide an override user id and the fake firestore instance
      listsService = ListsService('test_user', fakeFirestore);
    });

    test('createList creates a document and returns UserList', () async {
      final created = await listsService.createList(
        name: 'Favorites',
        description: 'My favs',
      );
      expect(created.name, 'Favorites');
      final snapshot = await fakeFirestore
          .collection('users')
          .doc('test_user')
          .collection('lists')
          .doc(created.id)
          .get();
      expect(snapshot.exists, isTrue);
      final data = snapshot.data()!;
      expect(data['name'], 'Favorites');
    });

    test('addBookToList and removeBookFromList update bookIds', () async {
      final userList = await listsService.createList(name: 'To Read');
      await listsService.addBookToList(userList.id, 'ub_1');
      var doc = await fakeFirestore
          .collection('users')
          .doc('test_user')
          .collection('lists')
          .doc(userList.id)
          .get();
      expect((doc.data()!['bookIds'] as List).contains('ub_1'), isTrue);

      await listsService.removeBookFromList(userList.id, 'ub_1');
      doc = await fakeFirestore
          .collection('users')
          .doc('test_user')
          .collection('lists')
          .doc(userList.id)
          .get();
      expect((doc.data()!['bookIds'] as List).contains('ub_1'), isFalse);
    });

    test('addBookToLists batch adds across multiple lists', () async {
      final a = await listsService.createList(name: 'A');
      final b = await listsService.createList(name: 'B');
      await listsService.addBookToLists([a.id, b.id], 'ub_batch');
      final da = await fakeFirestore
          .collection('users')
          .doc('test_user')
          .collection('lists')
          .doc(a.id)
          .get();
      final db = await fakeFirestore
          .collection('users')
          .doc('test_user')
          .collection('lists')
          .doc(b.id)
          .get();
      expect((da.data()!['bookIds'] as List).contains('ub_batch'), isTrue);
      expect((db.data()!['bookIds'] as List).contains('ub_batch'), isTrue);
    });
  });
}
