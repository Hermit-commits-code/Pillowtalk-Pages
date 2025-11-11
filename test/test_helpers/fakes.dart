import 'dart:async';

import 'package:spicyreads/models/user_book.dart';
import 'package:spicyreads/models/user_list.dart';

// A tiny fake UserLibraryService used for injection in tests.
class FakeUserLibraryService {
  bool called = false;
  UserBook? received;

  Future<void> updateBook(UserBook book) async {
    called = true;
    received = book;
    // complete synchronously in tests to avoid needing to advance timers
    await Future<void>.value();
  }
}

class FakeUserLibraryService2 {
  bool called = false;
  UserBook? received;

  Future<void> updateBook(UserBook book) async {
    called = true;
    received = book;
    await Future<void>.value();
  }
}

// Minimal fake ListsService for widget tests. It exposes a controllable
// stream and returns created lists immediately.
class FakeListsService {
  final _controller = StreamController<List<UserList>>.broadcast();
  int _next = 1;

  Stream<List<UserList>> getUserListsStream() => _controller.stream;

  Future<UserList> createList({
    required String name,
    String? description,
    bool isPrivate = true,
  }) async {
    final id = 'list_${_next++}';
    final created = UserList(
      id: id,
      userId: 'user_1',
      name: name,
      description: description,
      isPrivate: isPrivate,
      bookIds: [],
    );
    _controller.add([created]);
    return created;
  }

  Future<List<UserList>> getListsContainingBook(String userBookId) async => [];
  Future<void> addBookToLists(List<String> listIds, String userBookId) async {}
  Future<void> removeBookFromList(String listId, String userBookId) async {}

  void dispose() => _controller.close();

  /// Emit a list set on the underlying controller (test helper).
  void emit(List<UserList> lists) => _controller.add(lists);
}

class RecordingFakeListsService {
  final _controller = StreamController<List<UserList>>.broadcast();
  int _next = 1;
  final List<Map<String, dynamic>> added = [];

  Stream<List<UserList>> getUserListsStream() => _controller.stream;

  Future<UserList> createList({
    required String name,
    String? description,
    bool isPrivate = true,
  }) async {
    final id = 'list_${_next++}';
    final created = UserList(
      id: id,
      userId: 'user_1',
      name: name,
      description: description,
      isPrivate: isPrivate,
      bookIds: [],
    );
    _controller.add([created]);
    return created;
  }

  Future<List<UserList>> getListsContainingBook(String userBookId) async => [];

  Future<void> addBookToLists(List<String> listIds, String userBookId) async {
    added.add({'listIds': listIds, 'userBookId': userBookId});
  }

  Future<void> removeBookFromList(String listId, String userBookId) async {}

  void dispose() => _controller.close();

  /// Emit a list set on the underlying controller (test helper).
  void emit(List<UserList> lists) => _controller.add(lists);
}
