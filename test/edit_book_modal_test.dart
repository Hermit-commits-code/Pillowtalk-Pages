import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spicyreads/screens/book/edit_book_modal.dart';
import 'package:spicyreads/models/user_book.dart';
import 'test_helpers/fakes.dart';

void main() {
  testWidgets('EditBookModal save calls updateBook on injected service', (
    WidgetTester tester,
  ) async {
    final fake = FakeUserLibraryService();

    final sample = UserBook(
      id: 'ub_1',
      userId: 'user_1',
      bookId: 'b_1',
      title: 'Sample',
      authors: const ['A'],
      status: ReadingStatus.wantToRead,
    );

    final fakeLists = FakeListsService();
    await tester.pumpWidget(
      MaterialApp(
        home: EditBookModal(
          userBook: sample,
          userLibraryService: fake,
          listsService: fakeLists,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Ensure modal rendered
    expect(find.text('Edit Book'), findsOneWidget);

    // Trigger the save flow deterministically by calling the state's save().
    final stateObj = tester.state(find.byType(EditBookModal)) as dynamic;
    await stateObj.save();
    await tester.pumpAndSettle();

    fakeLists.dispose();

    // Fake service should have been called
    expect(fake.called, isTrue);
    expect(fake.received, isNotNull);
    expect(fake.received!.id, sample.id);
  });

  testWidgets(
    'EditBookModal sets dateFinished when status changed to finished',
    (WidgetTester tester) async {
      final fake = FakeUserLibraryService();

      final sample = UserBook(
        id: 'ub_2',
        userId: 'user_1',
        bookId: 'b_2',
        title: 'Finish Me',
        authors: const ['B'],
        status: ReadingStatus.wantToRead,
      );

      final fakeLists = FakeListsService();
      await tester.pumpWidget(
        MaterialApp(
          home: EditBookModal(
            userBook: sample,
            userLibraryService: fake,
            listsService: fakeLists,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the 'Finished' chip to change status
      final finishedFinder = find.text('Finished');
      expect(finishedFinder, findsOneWidget);
      await tester.tap(finishedFinder);
      await tester.pumpAndSettle();

      final stateObj = tester.state(find.byType(EditBookModal)) as dynamic;
      await stateObj.save();
      await tester.pumpAndSettle();

      fakeLists.dispose();

      expect(fake.called, isTrue);
      expect(fake.received, isNotNull);
      expect(fake.received!.status, ReadingStatus.finished);
      expect(fake.received!.dateFinished, isNotNull);
    },
  );
}
