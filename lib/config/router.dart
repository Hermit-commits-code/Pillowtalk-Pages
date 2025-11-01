import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/book/add_book_screen.dart';
import '../screens/book/book_detail_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/pro/pro_club_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/search/deep_trope_search_screen.dart';
import '../screens/splash_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => HomeScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeDashboard(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const DeepTropeSearchScreen(),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/book/:id',
      builder: (context, state) {
        final bookId = state.pathParameters['id']!;
        return BookDetailScreen(bookId: bookId);
      },
    ),
    GoRoute(
      path: '/add-book',
      builder: (context, state) => const AddBookScreen(),
    ),
    GoRoute(
      path: '/pro-club',
      builder: (context, state) => const ProClubScreen(),
    ),
  ],
);
