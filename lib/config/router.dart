import 'package:go_router/go_router.dart';

import '../models/book_model.dart';
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
        final bookId = state.pathParameters['id'] ?? '';
        // Replace with actual book lookup logic
        // For now, use a placeholder service call
        // You should replace this with your real data source
        // final book = CommunityDataService().getCommunityBookDataSync(bookId);
        // If no sync method exists, use a dummy RomanceBook for now
        final book = RomanceBook(
          id: bookId,
          isbn: '',
          title: 'Book Title',
          authors: ['Author Name'],
          imageUrl: null,
          description: 'No book found for ID: $bookId',
          genre: 'Unknown',
          subgenres: [],
          communityTropes: [],
          avgSpiceOnPage: 0.0,
        );
        return BookDetailScreen(
          title: book.title,
          author: book.authors.isNotEmpty ? book.authors.join(', ') : 'Unknown',
          coverUrl: book.imageUrl,
          description: book.description,
          genre: book.genre,
          subgenres: book.subgenres,
          seriesName: book.seriesName,
          seriesIndex: book.seriesIndex,
          communityTropes: book.communityTropes,
          availableTropes: book.communityTropes,
          availableWarnings: book.topWarnings,
          userSelectedTropes: const [],
          userContentWarnings: const [],
          spiceLevel: book.avgSpiceOnPage,
          bookId: bookId,
          userBookId: null,
        );
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
