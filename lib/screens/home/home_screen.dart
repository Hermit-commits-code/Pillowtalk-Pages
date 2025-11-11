// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final Widget? child;
  const HomeScreen({super.key, this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    String displayName = user?.displayName ?? user?.email ?? 'Reader';
    if (displayName.startsWith('\\')) {
      displayName = displayName.substring(1);
    }
    final isHome = _getCurrentNavIndex(context) == 0;

    return Scaffold(
      appBar: isHome
          ? AppBar(
              title: Text('Welcome back, $displayName!'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => context.push('/add-book'),
                  tooltip: 'Add a new book',
                ),
              ],
            )
          : null, // No AppBar on nested screens, they provide their own.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getCurrentNavIndex(context),
        onDestinationSelected: (int index) {
          switch (index) {
            case 0:
              context.goNamed('home');
              break;
            case 1:
              context.goNamed('search');
              break;
            case 2:
              context.goNamed('library');
              break;
            case 3:
              context.goNamed('profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      body: widget.child,
    );
  }

  int _getCurrentNavIndex(BuildContext context) {
    final uri = GoRouter.of(context).routeInformationProvider.value.uri;
    final location = uri.path;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/library')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // home
  }
}
