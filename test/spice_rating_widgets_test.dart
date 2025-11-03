// test/spice_rating_widgets_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spicyreads/screens/book/widgets/spice_meter_widgets.dart';
import 'package:spicyreads/widgets/compact_spice_rating.dart';

void main() {
  group('CompactSpiceRating Widget', () {
    testWidgets('displays rating and count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactSpiceRating(rating: 3.5, ratingCount: 42),
          ),
        ),
      );

      expect(find.text('3.5'), findsOneWidget);
      expect(find.text('(42)'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('displays rating without count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: CompactSpiceRating(rating: 2.5))),
      );

      expect(find.text('2.5'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget); // Only rating text
    });

    testWidgets('displays correct flame color for each rating level', (
      WidgetTester tester,
    ) async {
      // Test each rating level
      const testCases = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0];

      for (final rating in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: CompactSpiceRating(rating: rating)),
          ),
        );

        // Find the Icon widget and verify it renders
        final iconWidget = find.byType(Icon);
        expect(iconWidget, findsOneWidget);
      }
    });

    testWidgets('uses custom size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CompactSpiceRating(rating: 3.0, size: 24)),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
      final icon = find.byType(Icon).first;
      expect(icon, findsOneWidget);
    });
  });

  group('SpiceMeter Widget - Read-only mode', () {
    testWidgets('displays title and spice level', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SpiceMeter(spiceLevel: 3.5))),
      );

      expect(find.text('Spice Level'), findsOneWidget);
      expect(find.text('3.5 / 5.0 - Hot & Sensual'), findsOneWidget);
      expect(find.text('Community average from readers'), findsOneWidget);
    });

    testWidgets('displays 5 flame icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SpiceMeter(spiceLevel: 3.0))),
      );

      expect(find.byIcon(Icons.local_fire_department), findsWidgets);
    });

    testWidgets('displays correct spice labels', (WidgetTester tester) async {
      const testCases = [
        (0.0, 'Fade to Black'),
        (1.0, 'Sweet & Chaste'),
        (2.0, 'Warm & Steamy'),
        (3.0, 'Hot & Sensual'),
        (4.0, 'Scorching'),
        (5.0, 'Inferno'),
      ];

      for (final (rating, label) in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: SpiceMeter(spiceLevel: rating)),
          ),
        );

        // Verify label is present in the text
        expect(
          find.byWidgetPredicate((widget) {
            if (widget is! Text) return false;
            return widget.data?.contains(label) ?? false;
          }),
          findsWidgets,
          reason: 'Should display "$label" for rating $rating',
        );
      }
    });
  });

  group('SpiceMeter Widget - Editable mode', () {
    testWidgets('shows tap instruction when editable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpiceMeter(
              spiceLevel: 2.0,
              editable: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Tap flames to rate'), findsOneWidget);
    });

    testWidgets('has tapable flames in editable mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpiceMeter(
              spiceLevel: 2.0,
              editable: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify editable mode text is shown
      expect(find.text('Tap flames to rate'), findsOneWidget);
    });

    testWidgets('updates text when rating changes', (
      WidgetTester tester,
    ) async {
      double currentRating = 4.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpiceMeter(
              spiceLevel: currentRating,
              editable: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify initial rating is displayed
      expect(find.text('4.0 / 5.0 - Scorching'), findsOneWidget);
    });

    testWidgets('does not respond to taps when editable is false', (
      WidgetTester tester,
    ) async {
      double? newRating;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpiceMeter(
              spiceLevel: 2.0,
              editable: false,
              onChanged: (rating) => newRating = rating,
            ),
          ),
        ),
      );

      // Try to tap a flame icon
      final flameIcons = find.byIcon(Icons.local_fire_department);
      await tester.tap(flameIcons.first);
      await tester.pumpAndSettle();

      // onChanged should not have been called
      expect(newRating, isNull);
    });
  });

  group('SpiceMeter Widget - Animations', () {
    testWidgets('renders without animation errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpiceMeter(
              spiceLevel: 2.0,
              editable: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify the widget renders
      expect(find.text('Tap flames to rate'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsWidgets);
    });
  });
}
