import 'package:flutter_test/flutter_test.dart';

/// Helper to simulate list operations
class MockListStore {
  Map<String, Map<String, dynamic>> lists = {};

  void createList(String listId, Map<String, dynamic> data) {
    lists[listId] = {...data, 'id': listId};
  }

  Map<String, dynamic>? getList(String listId) => lists[listId];

  void updateList(String listId, Map<String, dynamic> updates) {
    if (lists.containsKey(listId)) {
      lists[listId]!.addAll(updates);
    }
  }

  void deleteList(String listId) {
    lists.remove(listId);
  }

  List<Map<String, dynamic>> getAllLists() => lists.values.toList();

  void addBookToList(String listId, String bookId) {
    if (lists.containsKey(listId)) {
      final bookIds = List<String>.from(lists[listId]!['bookIds'] ?? []);
      if (!bookIds.contains(bookId)) {
        bookIds.add(bookId);
        lists[listId]!['bookIds'] = bookIds;
      }
    }
  }

  void removeBookFromList(String listId, String bookId) {
    if (lists.containsKey(listId)) {
      final bookIds = List<String>.from(lists[listId]!['bookIds'] ?? []);
      bookIds.remove(bookId);
      lists[listId]!['bookIds'] = bookIds;
    }
  }

  int listCount() => lists.length;

  int bookCountInList(String listId) {
    final list = lists[listId];
    if (list == null) return 0;
    return (list['bookIds'] as List?)?.length ?? 0;
  }

  void clear() => lists.clear();
}

void main() {
  group('ListsService CRUD Operations', () {
    late MockListStore store;

    setUp(() {
      store = MockListStore();
    });

    test('Create a new list', () {
      const listName = 'My Favorites';
      const listDesc = 'Books I love';

      store.createList('list_1', {
        'userId': 'user_1',
        'name': listName,
        'description': listDesc,
        'isPrivate': true,
        'bookIds': [],
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });

      expect(store.listCount(), 1);
      final list = store.getList('list_1');
      expect(list?['name'], listName);
      expect(list?['description'], listDesc);
      expect(list?['isPrivate'], true);
      expect(list?['bookIds'], isEmpty);
    });

    test('Read an existing list', () {
      store.createList('list_1', {
        'userId': 'user_1',
        'name': 'Test List',
        'bookIds': ['book_1', 'book_2'],
      });

      final list = store.getList('list_1');
      expect(list, isNotNull);
      expect(list!['name'], 'Test List');
      expect(list['bookIds'], ['book_1', 'book_2']);
    });

    test('Read non-existent list returns null', () {
      final list = store.getList('list_999');
      expect(list, isNull);
    });

    test('Update a list name', () {
      store.createList('list_1', {'name': 'Old Name', 'bookIds': []});

      store.updateList('list_1', {'name': 'New Name'});

      final list = store.getList('list_1');
      expect(list?['name'], 'New Name');
    });

    test('Update a list description', () {
      store.createList('list_1', {'description': 'Old desc', 'bookIds': []});

      store.updateList('list_1', {'description': 'New desc'});

      final list = store.getList('list_1');
      expect(list?['description'], 'New desc');
    });

    test('Delete a list', () {
      store.createList('list_1', {'name': 'To Delete', 'bookIds': []});
      expect(store.listCount(), 1);

      store.deleteList('list_1');

      expect(store.listCount(), 0);
      expect(store.getList('list_1'), isNull);
    });

    test('Delete non-existent list does not error', () {
      store.deleteList('list_999');
      expect(store.listCount(), 0);
    });

    test('Add book to list', () {
      store.createList('list_1', {'name': 'Test', 'bookIds': []});

      store.addBookToList('list_1', 'book_1');

      final list = store.getList('list_1');
      expect(list?['bookIds'], ['book_1']);
    });

    test('Add multiple books to list', () {
      store.createList('list_1', {'name': 'Test', 'bookIds': []});

      store.addBookToList('list_1', 'book_1');
      store.addBookToList('list_1', 'book_2');
      store.addBookToList('list_1', 'book_3');

      expect(store.bookCountInList('list_1'), 3);
      final list = store.getList('list_1');
      expect(list?['bookIds'], ['book_1', 'book_2', 'book_3']);
    });

    test('Cannot add duplicate book to list', () {
      store.createList('list_1', {'name': 'Test', 'bookIds': []});

      store.addBookToList('list_1', 'book_1');
      store.addBookToList('list_1', 'book_1');

      expect(store.bookCountInList('list_1'), 1);
    });

    test('Remove book from list', () {
      store.createList('list_1', {
        'name': 'Test',
        'bookIds': ['book_1', 'book_2'],
      });

      store.removeBookFromList('list_1', 'book_1');

      final list = store.getList('list_1');
      expect(list?['bookIds'], ['book_2']);
    });

    test('Remove non-existent book from list does not error', () {
      store.createList('list_1', {
        'name': 'Test',
        'bookIds': ['book_1'],
      });

      store.removeBookFromList('list_1', 'book_999');

      final list = store.getList('list_1');
      expect(list?['bookIds'], ['book_1']);
    });

    test('Get all lists for user', () {
      store.createList('list_1', {'userId': 'user_1', 'name': 'List 1'});
      store.createList('list_2', {'userId': 'user_1', 'name': 'List 2'});
      store.createList('list_3', {'userId': 'user_1', 'name': 'List 3'});

      final lists = store.getAllLists();
      expect(lists.length, 3);
      expect(lists[0]['name'], 'List 1');
      expect(lists[1]['name'], 'List 2');
      expect(lists[2]['name'], 'List 3');
    });

    test('Empty list has no books', () {
      store.createList('list_1', {'name': 'Empty', 'bookIds': []});

      expect(store.bookCountInList('list_1'), 0);
    });

    test('List privacy settings preserved on update', () {
      store.createList('list_1', {
        'name': 'Test',
        'isPrivate': true,
        'bookIds': [],
      });

      store.updateList('list_1', {'name': 'Updated'});

      final list = store.getList('list_1');
      expect(list?['isPrivate'], true);
      expect(list?['name'], 'Updated');
    });

    test('Add multiple books to multiple lists', () {
      store.createList('list_1', {'name': 'List 1', 'bookIds': []});
      store.createList('list_2', {'name': 'List 2', 'bookIds': []});

      store.addBookToList('list_1', 'book_1');
      store.addBookToList('list_2', 'book_1');

      expect(store.bookCountInList('list_1'), 1);
      expect(store.bookCountInList('list_2'), 1);
    });

    test('Complex user workflow', () {
      // User creates 2 lists
      store.createList('favorites', {
        'name': 'My Favorites',
        'isPrivate': true,
        'bookIds': [],
      });
      store.createList('to-read', {
        'name': 'To Read',
        'isPrivate': false,
        'bookIds': [],
      });

      expect(store.listCount(), 2);

      // User adds 3 books to favorites
      store.addBookToList('favorites', 'book_1');
      store.addBookToList('favorites', 'book_2');
      store.addBookToList('favorites', 'book_3');

      // User adds 2 books to to-read
      store.addBookToList('to-read', 'book_1');
      store.addBookToList('to-read', 'book_4');

      expect(store.bookCountInList('favorites'), 3);
      expect(store.bookCountInList('to-read'), 2);

      // User removes one book from favorites
      store.removeBookFromList('favorites', 'book_2');

      expect(store.bookCountInList('favorites'), 2);

      // User renames a list
      store.updateList('to-read', {'name': 'Want to Read'});

      final toRead = store.getList('to-read');
      expect(toRead?['name'], 'Want to Read');

      // User deletes favorites list
      store.deleteList('favorites');

      expect(store.listCount(), 1);
    });

    test('List IDs are unique', () {
      store.createList('list_1', {'name': 'List 1', 'bookIds': []});
      store.createList('list_2', {'name': 'List 2', 'bookIds': []});

      expect(store.getList('list_1')?['id'], 'list_1');
      expect(store.getList('list_2')?['id'], 'list_2');
    });

    test('Update timestamps on modifications', () {
      final createdAt = DateTime.now();
      store.createList('list_1', {
        'name': 'Test',
        'createdAt': createdAt,
        'updatedAt': createdAt,
        'bookIds': [],
      });

      final laterTime = DateTime.now().add(const Duration(seconds: 1));
      store.updateList('list_1', {'updatedAt': laterTime});

      final list = store.getList('list_1');
      expect(list?['createdAt'], createdAt);
      expect(list?['updatedAt'], laterTime);
    });

    test('Clear all lists', () {
      store.createList('list_1', {'name': 'List 1', 'bookIds': []});
      store.createList('list_2', {'name': 'List 2', 'bookIds': []});
      store.createList('list_3', {'name': 'List 3', 'bookIds': []});

      expect(store.listCount(), 3);

      store.clear();

      expect(store.listCount(), 0);
    });
  });
}
