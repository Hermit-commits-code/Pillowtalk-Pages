import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spicyreads/screens/book/widgets/editable_tropes_section.dart';

void main() {
  testWidgets('adds trope by typing and tapping add button', (
    WidgetTester tester,
  ) async {
    List<String> tropes = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditableTropesSection(
            tropes: tropes,
            availableTropes: const [],
            onTropesChanged: (updated) => tropes = List.from(updated),
            label: 'Tropes',
          ),
        ),
      ),
    );

    // Enter a new trope and press the add button
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, 'New Trope');
    await tester.pumpAndSettle();

    final addButton = find.widgetWithIcon(IconButton, Icons.add);
    expect(addButton, findsOneWidget);

    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // The chip should be rendered and callback should have been called
    expect(find.text('New Trope'), findsWidgets);
    expect(tropes, contains('New Trope'));
  });

  testWidgets('selects suggestion from autocomplete options', (
    WidgetTester tester,
  ) async {
    List<String> tropes = [];
    const suggestions = ['Enemies to Lovers', 'Fake Date'];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditableTropesSection(
            tropes: tropes,
            availableTropes: suggestions,
            onTropesChanged: (updated) => tropes = List.from(updated),
            label: 'Tropes',
          ),
        ),
      ),
    );

    // Type to trigger autocomplete
    final textField = find.byType(TextField);
    await tester.enterText(textField, 'Enemies');
    await tester.pumpAndSettle();

    // Option should appear
    final option = find.text('Enemies to Lovers');
    expect(option, findsOneWidget);

    await tester.tap(option);
    await tester.pumpAndSettle();

    expect(tropes, contains('Enemies to Lovers'));
    expect(find.text('Enemies to Lovers'), findsWidgets);
  });
}
