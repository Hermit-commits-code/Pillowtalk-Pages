import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:spicyreads/screens/profile/profile_screen.dart';
import 'package:spicyreads/services/theme_provider.dart';

void main() {
  testWidgets('Profile screen renders main sections', (
    WidgetTester tester,
  ) async {
    // Ensure binding; avoid calling Firebase.initializeApp() in widget tests
    // (it may perform real platform/network work and create timers).
    TestWidgetsFlutterBinding.ensureInitialized();

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: MaterialApp(home: ProfileScreen(currentUserGetter: () => null)),
      ),
    );

    // Allow initial async tasks to settle briefly
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Verify core sections render. Some sections depend on async state and
    // feature flags; keep this test resilient by checking primary headings.
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
