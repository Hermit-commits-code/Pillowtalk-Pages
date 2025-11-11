import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// No Firebase initialization required; TropeSelectionScreen accepts a proCheck override.

import 'package:spicyreads/screens/book/trope_selection_screen.dart';

void main() {
  testWidgets('selecting a trope returns it on Done', (tester) async {
    // Start a basic app with a Navigator available
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));

    // Push the TropeSelectionScreen and keep the future to await the result.
    // Pass a proCheck override so the screen doesn't attempt to access
    // FirebaseAuth/Firestore during tests.
    final future = navigatorState.push<List<String>>(
      MaterialPageRoute(
        builder: (_) => const TropeSelectionScreen(
          initialTropes: [],
          proCheck: _testProCheck,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Ensure categories are present
    expect(find.text('Relationship Dynamics'), findsOneWidget);

    // Expand the Relationship Dynamics tile
    await tester.tap(find.text('Relationship Dynamics'));
    await tester.pumpAndSettle();

    // Choose a known trope from that category
    const tropeToSelect = 'Friends to Lovers';
    expect(find.text(tropeToSelect), findsWidgets);
    await tester.tap(find.text(tropeToSelect).first);
    await tester.pumpAndSettle();

    // Press Done (AppBar action)
    await tester.tap(find.byIcon(Icons.done));

    // Wait for the route to pop and return the selection
    final result = await future;
    expect(result, isNotNull);
    expect(result!.contains(tropeToSelect), isTrue);
  });
}

// Simple test proCheck function used to bypass Firebase in widget tests.
Future<bool> _testProCheck() async => false;
