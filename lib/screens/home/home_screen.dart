// lib/screens/home/home_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// import removed: '../../services/iap_service.dart';
import '../../widgets/free_trial_widgets.dart';

class HomeScreen extends StatefulWidget {
  final Widget? child;
  const HomeScreen({super.key, this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool isOnFreeTrial = false;
  int trialDaysLeft = 0;
  // Removed unused _iapService field

  static const List<String> _routes = [
    '/home',
    '/search',
    '/library',
    '/profile',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.toString();
    final idx = _routes.indexWhere((r) => location.startsWith(r));
    if (idx != -1 && idx != _selectedIndex) {
      setState(() {
        _selectedIndex = idx;
      });
    }
    // Example: fetch real trial state from IAPService (replace with real logic)
    // setState(() {
    // Removed unused _iapService usages
    // });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          if (isOnFreeTrial)
            FreeTrialBanner(
              daysLeft: trialDaysLeft,
              onManage: () {
                // Navigate to Pro Club screen for subscription management
                context.push('/pro-club');
              },
              onDismiss: () {
                setState(() => isOnFreeTrial = false);
              },
            ),
          Expanded(child: widget.child ?? const SizedBox.shrink()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.cardTheme.color,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withAlpha(153),
        currentIndex: _selectedIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (_selectedIndex != index) {
            setState(() {
              _selectedIndex = index;
            });
            context.go(_routes[index]);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    // Remove stray backslash if present in displayName
    String displayName = user?.displayName ?? user?.email ?? 'Reader';
    if (displayName.startsWith('\\')) {
      displayName = displayName.substring(1);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Sanctuary', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/add-book'),
            color: Theme.of(
              context,
            ).colorScheme.secondary, // Use gold for contrast
            tooltip: 'Add Book',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome back, $displayName!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(102), // 40%
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Ready to dive into your next romantic adventure?',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary.withAlpha(217),
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black.withAlpha(77), // 30%
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
