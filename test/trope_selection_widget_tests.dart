import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spicyreads/screens/book/trope_selection_screen.dart';

void main() {
  group('TropeSelectionScreen Widget Tests', () {
    /// Test 1: Free user can select max 2 tropes
    testWidgets('free user can select up to 2 tropes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TropeSelectionScreen(
            initialTropes: [],
            proCheck: () async => false, // Free user
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand a category to get tropes
      expect(find.text('Relationship Dynamics'), findsOneWidget);
      await tester.tap(find.text('Relationship Dynamics'));
      await tester.pumpAndSettle();

      // Select first trope
      final firstTrope = 'Friends to Lovers';
      expect(find.text(firstTrope), findsWidgets);
      await tester.tap(find.text(firstTrope).first);
      await tester.pumpAndSettle();

      // Verify it's selected
      expect(find.byIcon(Icons.check_box), findsOneWidget);

      // Select second trope
      final secondTrope = 'Enemies to Lovers';
      await tester.tap(find.text(secondTrope).first);
      await tester.pumpAndSettle();

      // Verify we have 2 selected
      expect(find.byIcon(Icons.check_box), findsWidgets);

      // Try to select third trope — should show pro upgrade message
      final thirdTrope = 'Fake Relationship';
      await tester.tap(find.text(thirdTrope).first);
      await tester.pumpAndSettle();

      // Verify pro upgrade message appears
      expect(find.text('Free users can select up to 2 tropes'), findsOneWidget);

      // Verify only 2 tropes remain selected (not 3)
      expect(find.byIcon(Icons.check_box), findsExactly(2));
    });

    /// Test 2: Pro user can select more than 2 tropes
    testWidgets('pro user can select more than 2 tropes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TropeSelectionScreen(
            initialTropes: [],
            proCheck: () async => true, // Pro user
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand a category
      await tester.tap(find.text('Relationship Dynamics'));
      await tester.pumpAndSettle();

      // Select 5 tropes (more than free limit)
      final tropes = [
        'Friends to Lovers',
        'Enemies to Lovers',
        'Fake Relationship',
        'Forced Proximity',
        'Second Chance Romance',
      ];

      for (final trope in tropes) {
        await tester.tap(find.text(trope).first);
        await tester.pumpAndSettle();
      }

      // Verify all 5 are selected without pro upgrade message
      expect(find.byIcon(Icons.check_box), findsExactly(5));
      expect(
        find.text('Free users can select up to 2 tropes'),
        findsNothing,
        reason: 'Pro user should not see free tier upgrade message',
      );
    });

    /// Test 3: Custom trope creation
    testWidgets('user can add a custom trope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TropeSelectionScreen(
            initialTropes: [],
            proCheck: () async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap "Add a custom trope..." button
      expect(find.text('Add a custom trope...'), findsOneWidget);
      await tester.tap(find.text('Add a custom trope...'));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);

      // Type in the custom trope
      const customTrope = 'Time loop romance';
      await tester.enterText(find.byType(TextField), customTrope);
      await tester.pumpAndSettle();

      // Tap Add button
      await tester.tap(find.text('Add').last);
      await tester.pumpAndSettle();

      // Verify custom trope is selected (1 checkbox)
      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });

    /// Test 4: Pro upgrade button in snackbar
    testWidgets('pro upgrade snackbar shows upgrade button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TropeSelectionScreen(
            initialTropes: [],
            proCheck: () async => false, // Free user
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand a category
      await tester.tap(find.text('Relationship Dynamics'));
      await tester.pumpAndSettle();

      // Select 2 tropes
      await tester.tap(find.text('Friends to Lovers').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enemies to Lovers').first);
      await tester.pumpAndSettle();

      // Try to select a third
      await tester.tap(find.text('Fake Relationship').first);
      await tester.pumpAndSettle();

      // Verify snackbar with upgrade action
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
    });

    /// Test 5: Category expansion and collapse
    testWidgets('categories can be expanded and collapsed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TropeSelectionScreen(
            initialTropes: [],
            proCheck: () async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially, tropes should not be visible
      expect(find.text('Friends to Lovers'), findsNothing);

      // Expand the category
      await tester.tap(find.text('Relationship Dynamics'));
      await tester.pumpAndSettle();

      // Now tropes should be visible
      expect(find.text('Friends to Lovers'), findsOneWidget);

      // Collapse it
      await tester.tap(find.text('Relationship Dynamics'));
      await tester.pumpAndSettle();

      // Tropes should be hidden again
      expect(find.text('Friends to Lovers'), findsNothing);
    });

    /// Test 6: Initial tropes are pre-selected
    testWidgets('initial tropes are pre-selected', (tester) async {
      const initialTropes = ['Friends to Lovers', 'Enemies to Lovers'];

      await tester.pumpWidget(
        MaterialApp(
          home: TropeSelectionScreen(
            initialTropes: initialTropes,
            proCheck: () async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand the category
      await tester.tap(find.text('Relationship Dynamics'));
      await tester.pumpAndSettle();

      // Verify the initial tropes are checked
      final checkboxes = find.byIcon(Icons.check_box);
      expect(checkboxes, findsWidgets);
      // Should have at least 2 checkboxes
      expect(find.byIcon(Icons.check_box), findsAtLeast(2));
    });
  });
}
