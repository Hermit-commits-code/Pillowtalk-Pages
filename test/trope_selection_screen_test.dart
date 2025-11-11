import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spicyreads/screens/book/trope_selection_screen.dart';

/// Small host widget that opens TropeSelectionScreen and captures the result.
class _TestHost extends StatefulWidget {
  const _TestHost();

  @override
  State<_TestHost> createState() => _TestHostState();
}

class _TestHostState extends State<_TestHost> {
  List<String>? result;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final res = await Navigator.of(context).push<List<String>>(
                MaterialPageRoute(
                  builder: (_) => const TropeSelectionScreen(initialTropes: []),
                ),
              );
              setState(() => result = res);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('selecting a trope returns it on Done', (tester) async {
    await tester.pumpWidget(const _TestHost());
    await tester.pumpAndSettle();

    // Push the selector route directly via the test's Navigator (more
    // reliable in widget tests than calling Navigator.of from a widget
    // closure in this environment).
    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
    await navigatorState.push<List<String>>(
      MaterialPageRoute(
        builder: (_) => TropeSelectionScreen(
          initialTropes: [],
          // Inject a fast proCheck to avoid touching Firebase/Firestore
          // during widget tests which can hang if plugins aren't available.
          proCheck: () async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Ensure categories are present
    expect(find.textContaining('Relationship Dynamics'), findsOneWidget);

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
    await tester.pumpAndSettle();

    // The host should have received the selected trope
    final state = tester.state<_TestHostState>(find.byType(_TestHost));
    expect(state.result, isNotNull);
    expect(state.result!.contains(tropeToSelect), isTrue);
  });
}
