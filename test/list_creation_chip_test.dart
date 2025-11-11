import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spicyreads/screens/book/edit_book_modal.dart';
import 'package:spicyreads/models/user_book.dart';
import 'package:spicyreads/screens/book/widgets/lists_dropdown.dart';
import 'test_helpers/fakes.dart';

void main() {
  testWidgets('Create list in selector shows chip and save adds book to list', (
    WidgetTester tester,
  ) async {
    final fakeLib = FakeUserLibraryService2();
    final fakeLists = RecordingFakeListsService();

    final sample = UserBook(
      id: 'ub_2',
      userId: 'user_1',
      bookId: 'b_2',
      title: 'Sample 2',
      authors: const ['A'],
      status: ReadingStatus.wantToRead,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EditBookModal(
          userBook: sample,
          userLibraryService: fakeLib,
          listsService: fakeLists,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Instead of opening the selection screen (which constructs a real
    // ListsService and requires Firebase), create the list via the injected
    // fake and then inject the id into the modal state to simulate the
    // selection flow.
    final created = await fakeLists.createList(name: 'My New List');

    // Call the ListsDropdown's onChanged to simulate the selector returning
    // the created id. This avoids accessing private state fields.
    final dropdown = tester.widget(find.byType(ListsDropdown)) as dynamic;
    dropdown.onChanged(<String>[created.id]);
    await tester.pumpAndSettle();

    // Now the modal should show a chip for the created list
    expect(find.text('My New List'), findsOneWidget);

    // Save changes via the state's public save() method to avoid hit-test
    // / viewport issues in test harness.
    final stateObj = tester.state(find.byType(EditBookModal)) as dynamic;
    await stateObj.save();
    await tester.pumpAndSettle();

    // Verify updateBook called and lists add was invoked
    expect(fakeLib.called, isTrue);
    expect(fakeLists.added, isNotEmpty);
    expect(fakeLists.added.first['userBookId'], sample.id);

    fakeLists.dispose();
  });
}
