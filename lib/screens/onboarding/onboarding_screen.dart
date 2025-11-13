import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/welcome_screen.dart';
import 'screens/hard_stops_screen.dart';
import 'screens/kink_filters_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/curated_library_screen.dart';

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
    if (_currentPage < 5) {
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
      if (mounted) context.go('/');
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
      onWillPop: () async => false, // Prevent back navigation during onboarding
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Top bar: progress indicator and skip
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    // Invisible spacer to keep center alignment
                    const SizedBox(width: 48),
                    Expanded(
                      child: Center(
                        child: Semantics(
                          label: 'Onboarding progress',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(6, (index) {
                              final isActive = index == _currentPage;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: isActive ? 18 : 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.pink
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        // Allow skipping onboarding; mark complete and go home
                        await _completeOnboarding();
                      },
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Page content
              Expanded(
                child: PageView(
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
                    SummaryScreen(onNext: _nextPage, onPrevious: _previousPage),
                    FavoritesScreen(
                      userId: widget.userId,
                      onNext: _nextPage,
                      onPrevious: _previousPage,
                    ),
                    CuratedLibraryScreen(
                      userId: widget.userId,
                      onNext: _completeOnboarding,
                      onPrevious: _previousPage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
