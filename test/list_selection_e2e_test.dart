import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spicyreads/screens/book/edit_book_modal.dart';
import 'package:spicyreads/models/user_book.dart';
import 'test_helpers/fakes.dart';

void main() {
  testWidgets('Open selector, create list, return selection, save persists', (
    WidgetTester tester,
  ) async {
    final fakeLib = FakeUserLibraryService2();
    final fakeLists = RecordingFakeListsService();

    // Emit an initial empty list set so the selector's StreamBuilder doesn't
    // stay in ConnectionState.waiting and show a continuously animating
    // CircularProgressIndicator (which would make pumpAndSettle never finish).
    fakeLists.emit([]);

    final sample = UserBook(
      id: 'ub_e2e',
      userId: 'user_1',
      bookId: 'b_e2e',
      title: 'E2E Sample',
      authors: const ['A'],
      status: ReadingStatus.reading,
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

    // Open the selector via the ListsDropdown button
    expect(find.text('Add to lists'), findsOneWidget);
    // Open selector
    await tester.tap(find.text('Add to lists'));
    // Allow the navigation to begin and the new route to subscribe to the
    // fake lists stream. Pump a frame, then emit an initial empty list so the
    // StreamBuilder in the selector doesn't stay in ConnectionState.waiting
    // (which would show an animating CircularProgressIndicator and cause
    // pumpAndSettle to never finish).
    await tester.pump();
    fakeLists.emit([]);
    // Allow navigation animations to complete. Use a longer timeout here to
    // avoid flakes in CI where animations can be slower.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // We should be on the selection screen. Create a new list via the dialog.
    final createBtn = find.widgetWithText(ElevatedButton, 'Create new list');
    expect(createBtn, findsOneWidget);
    await tester.tap(createBtn);
    await tester.tap(createBtn);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Enter name and create
    final nameField = find.byType(TextField).first;
    await tester.enterText(nameField, 'E2E List');
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // The created list should appear in the list view
    expect(find.text('E2E List'), findsOneWidget);

    // Press Done to return the selection
    await tester.tap(find.widgetWithText(ElevatedButton, 'Done'));
    await tester.pumpAndSettle();

    // Back in the modal, the chip for the created list should be visible
    expect(find.text('E2E List'), findsOneWidget);

    // Trigger save deterministically via the state's save() to avoid hit-test issues
    final stateObj = tester.state(find.byType(EditBookModal)) as dynamic;
    await stateObj.save();
    await tester.pumpAndSettle();

    expect(fakeLib.called, isTrue);
    expect(fakeLists.added, isNotEmpty);
    expect(fakeLists.added.first['userBookId'], sample.id);

    fakeLists.dispose();
  });
}
