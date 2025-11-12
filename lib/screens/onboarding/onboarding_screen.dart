import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/welcome_screen.dart';
import 'screens/hard_stops_screen.dart';
import 'screens/kink_filters_screen.dart';
import 'screens/favorites_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String userId;

  const OnboardingScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      // Navigate to home - onboarding is now complete
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing onboarding: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (page) {
            setState(() => _currentPage = page);
          },
          children: [
            WelcomeScreen(onNext: _nextPage),
            HardStopsScreen(
              userId: widget.userId,
              onNext: _nextPage,
              onPrevious: _previousPage,
            ),
            KinkFiltersScreen(
              userId: widget.userId,
              onNext: _nextPage,
              onPrevious: _previousPage,
            ),
            FavoritesScreen(
              userId: widget.userId,
              onNext: _nextPage,
              onPrevious: _previousPage,
            ),
            FavoritesScreen(
              userId: widget.userId,
              onNext: _completeOnboarding,
              onPrevious: _previousPage,
            ),
          ],
        ),
      ),
    );
  }
}
