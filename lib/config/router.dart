import '../services/auth_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:go_router/go_router.dart';

import '../models/user_book.dart';
import '../screens/book/book_detail_loader.dart';
import '../screens/book/book_detail_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/book/add_book_screen.dart';

import '../screens/curated/curated_screen.dart';
import '../screens/curated/curated_collection_screen.dart';
import '../screens/home/home_dashboard.dart';
import '../screens/home/home_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/search/deep_trope_search_screen.dart';
import '../screens/discovery/community_discovery_screen.dart';
import '../screens/pro/pro_club_screen.dart';
import '../screens/dev/dev_qa_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/social/friends_screen.dart';
import '../screens/social/friend_settings_screen.dart';
import '../screens/social/share_links_screen.dart';

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
        GoRoute(
          path: '/discover',
          name: 'discover',
          builder: (context, state) => const CommunityDiscoveryScreen(),
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
        GoRoute(
          path: '/curated',
          name: 'curated',
          builder: (context, state) => const CuratedScreen(),
        ),
        GoRoute(
          path: '/social/friends',
          name: 'social-friends',
          builder: (context, state) => const FriendsScreen(),
        ),
        GoRoute(
          path: '/social/friend-settings/:friendId',
          name: 'social-friend-settings',
          builder: (context, state) {
            final friendId = state.pathParameters['friendId'] ?? '';
            return FriendSettingsScreen(friendId: friendId);
          },
        ),
        GoRoute(
          path: '/social/share-links',
          name: 'social-share-links',
          builder: (context, state) => const ShareLinksScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/curated-collection/:collectionId',
      builder: (context, state) {
        final collectionId = state.pathParameters['collectionId'] ?? '';
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final title = extra['title'] as String? ?? '';
        final bookIds =
            (extra['bookIds'] as List<dynamic>?)?.cast<String>() ?? [];

        return CuratedCollectionScreen(
          collectionId: collectionId,
          title: title,
          bookIds: bookIds,
        );
      },
    ),
    GoRoute(
      path: '/book/:id',
      builder: (context, state) {
        final bookId = state.pathParameters['id'] ?? '';
        final extra = state.extra as Map<String, dynamic>? ?? {};

        // If extra data is provided (from search or library), pass it directly
        if (extra.containsKey('userBook')) {
          final userBook = extra['userBook'] as UserBook;
          return BookDetailScreen(
            title: userBook.title,
            author: userBook.authors.join(', '),
            coverUrl: userBook.imageUrl,
            description: userBook.description,
            genres: userBook.genres,
            seriesName: userBook.seriesName,
            seriesIndex: userBook.seriesIndex,
            userSelectedTropes: userBook.userSelectedTropes,
            userContentWarnings: userBook.userContentWarnings,
            bookId: userBook.bookId,
            userBookId: userBook.id,
            userNotes: userBook.userNotes,
            spiceOverall: userBook.spiceOverall,
            spiceIntensity: userBook.spiceIntensity,
            emotionalArc: userBook.emotionalArc,
            pageCount: userBook.pageCount,
            publishedDate: userBook.publishedDate,
            publisher: userBook.publisher,
          );
        }

        // Otherwise, load from canonical books collection
        return BookDetailLoader(bookId: bookId);
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
