import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spicyreads/screens/book/add_book_screen.dart';

class FakeKinkService {
  final List<String> filters;
  final bool enabled;
  FakeKinkService({required this.filters, this.enabled = true});
  Future<Map<String, dynamic>> getKinkFilterOnce() async {
    return {'kinkFilter': filters, 'enabled': enabled};
  }
}

class FakeHardStopsService {
  final List<String> stops;
  final bool enabled;
  FakeHardStopsService({required this.stops, this.enabled = true});
  Future<Map<String, dynamic>> getHardStopsOnce() async {
    return {'hardStops': stops, 'enabled': enabled};
  }
}

void main() {
  testWidgets('AddBook checkForTropeConflicts detects kink conflict (widget)', (
    tester,
  ) async {
    final fakeKink = FakeKinkService(filters: ['BDSM']);
    final fakeHard = FakeHardStopsService(stops: []);

    await tester.pumpWidget(
      MaterialApp(
        home: AddBookScreen(
          initialSelectedTropes: const ['BDSM', 'Friends to Lovers'],
          kinkFilterService: fakeKink,
          hardStopsService: fakeHard,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Access the State and call the exposed checkForTropeConflicts method.
    final state = tester.state(find.byType(AddBookScreen)) as dynamic;
    final result = await state.checkForTropeConflicts();

    expect(result['hasConflicts'] as bool, true);
    final conflicts = List<String>.from(result['conflictingTropes'] as List);
    expect(conflicts, contains('BDSM'));
  });

  testWidgets(
    'AddBook checkForTropeConflicts detects hard-stop conflict (widget)',
    (tester) async {
      final fakeKink = FakeKinkService(filters: []);
      final fakeHard = FakeHardStopsService(stops: ['Non-Consensual']);

      await tester.pumpWidget(
        MaterialApp(
          home: AddBookScreen(
            initialSelectedTropes: const [
              'Non-Consensual',
              'Friends to Lovers',
            ],
            kinkFilterService: fakeKink,
            hardStopsService: fakeHard,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final state = tester.state(find.byType(AddBookScreen)) as dynamic;
      final result = await state.checkForTropeConflicts();

      expect(result['hasConflicts'] as bool, true);
      final conflicts = List<String>.from(result['conflictingTropes'] as List);
      expect(conflicts, contains('Non-Consensual'));
    },
  );
}
