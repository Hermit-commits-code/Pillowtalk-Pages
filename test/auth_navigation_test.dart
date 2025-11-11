import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spicyreads/screens/auth/login_screen.dart';
import 'package:spicyreads/screens/profile/profile_screen.dart';

class _FakeThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  void setTheme(ThemeMode m) {
    themeMode = m;
    notifyListeners();
  }
}

/// Minimal fake user used by the fake auth service in tests.
class _FakeUser {
  final String uid;
  final String? email;
  final String? displayName;
  _FakeUser({required this.uid, this.email, this.displayName});
}

/// A tiny fake auth service with just enough surface for the screens under test.
class FakeAuthService {
  _FakeUser? _user;
  bool signInCalled = false;
  bool signOutCalled = false;

  dynamic get currentUser => _user;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalled = true;
    // Simulate a successful sign-in and populate a minimal user object.
    _user = _FakeUser(uid: 'fake-uid', email: email, displayName: 'Tester');
    return;
  }

  Future<void> signOut() async {
    signOutCalled = true;
    _user = null;
  }
}

void main() {
  testWidgets('login navigates to home on success', (tester) async {
    final fakeAuth = FakeAuthService();

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (c, s) => LoginScreen(authService: fakeAuth),
        ),
        GoRoute(
          path: '/',
          builder: (c, s) => const Scaffold(body: Center(child: Text('Home'))),
        ),
      ],
      redirect: (context, state) {
        final user = fakeAuth.currentUser;
        final isAuthRoute = state.matchedLocation == '/login';
        if (user == null && !isAuthRoute) return '/login';
        if (user != null && isAuthRoute) return '/';
        return null;
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<_FakeThemeProvider>(
        create: (_) => _FakeThemeProvider(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Enter valid email/password
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');

    // Tap Sign In
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Should navigate to Home
    expect(find.text('Home'), findsOneWidget);
    expect(fakeAuth.signInCalled, isTrue);
  });

  testWidgets('logout signs out and navigates to login', (tester) async {
    final fakeAuth = FakeAuthService();
    // Pre-populate a logged-in user
    await fakeAuth.signInWithEmailAndPassword(email: 'a@b.com', password: 'x');

    final fakeTheme = _FakeThemeProvider();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/login',
          builder: (c, s) => LoginScreen(authService: fakeAuth),
        ),
        GoRoute(
          path: '/',
          builder: (c, s) =>
              ProfileScreen(authService: fakeAuth, themeProvider: fakeTheme),
        ),
      ],
      redirect: (context, state) {
        final user = fakeAuth.currentUser;
        final isAuthRoute = state.matchedLocation == '/login';
        if (user == null && !isAuthRoute) return '/login';
        if (user != null && isAuthRoute) return '/';
        return null;
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<_FakeThemeProvider>(
        create: (_) => _FakeThemeProvider(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the Logout button (tap the icon inside the button to be robust)
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    // Confirm logout in dialog
    await tester.tap(find.text('Logout').last);
    await tester.pumpAndSettle();

    // Should navigate to Login
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(fakeAuth.signOutCalled, isTrue);
  });
}
