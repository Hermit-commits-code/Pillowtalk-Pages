import '../services/auth_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';

import '../models/book_model.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/book/add_book_screen.dart';
import '../screens/book/book_detail_screen.dart';
import '../screens/home/home_dashboard.dart';
import '../screens/home/home_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/search/deep_trope_search_screen.dart';
import '../screens/pro/pro_club_screen.dart';
import '../screens/dev/dev_qa_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final user = AuthService.instance.currentUser;
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (user == null && !isAuthRoute) {
      return '/login';
    } else if (user != null && isAuthRoute) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/onboarding/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'] ?? '';
        return OnboardingScreen(userId: userId);
      },
    ),
    ShellRoute(
      builder: (context, state, child) => HomeScreen(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeDashboard(),
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) => const DeepTropeSearchScreen(),
        ),
        // Backwards-compatible alias: some parts of the app (or older
        // installs) may navigate to `/home`. Keep a short redirect so
        // those navigations don't throw a GoException.
        GoRoute(path: '/home', redirect: (context, state) => '/'),
        GoRoute(
          path: '/pro-club',
          name: 'pro-club',
          builder: (context, state) => const ProClubScreen(),
        ),
        GoRoute(
          path: '/library',
          name: 'library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/book/:id',
      builder: (context, state) {
        final bookId = state.pathParameters['id'] ?? '';
        // This is a placeholder, in a real app you'd fetch this from a service
        final book = RomanceBook(
          id: bookId,
          isbn: '',
          title: 'Book Title',
          authors: ['Author Name'],
          description: 'Description for $bookId',
        );
        return BookDetailScreen(
          title: book.title,
          author: book.authors.join(', '),
          coverUrl: book.imageUrl,
          description: book.description,
          bookId: bookId,
        );
      },
    ),
    GoRoute(
      path: '/add-book',
      builder: (context, state) => const AddBookScreen(),
    ),
    if (kDebugMode)
      GoRoute(
        path: '/dev-qa',
        builder: (context, state) => const DevQAScreen(),
      ),
    // Pro club route removed for single-user builds
  ],
);
