import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pro_status_service.dart';
import 'user_library_service.dart';

/// Central service for managing Pro feature gating and upgrade prompts
class FeatureGatingService {
  static final FeatureGatingService _instance =
      FeatureGatingService._internal();
  factory FeatureGatingService() => _instance;
  FeatureGatingService._internal();

  final ProStatusService _proStatusService = ProStatusService();
  final UserLibraryService _libraryService = UserLibraryService();

  // Feature limits for free users
  static const int freeBookLimit = 100;
  static const int freeTropeLimit = 2;
  static const int freeCustomFilterLimit = 3;

  /// Check if user has Pro access
  Future<bool> isPro() async {
    return await _proStatusService.isPro();
  }

  /// Check if user can add more books
  Future<bool> canAddMoreBooks() async {
    final isPro = await this.isPro();
    if (isPro) return true;

    final bookCount = await _libraryService.getUserBookCount();
    return bookCount < freeBookLimit;
  }

  /// Check if user can select more tropes
  Future<bool> canSelectMoreTropes(int currentTropeCount) async {
    final isPro = await this.isPro();
    if (isPro) return true;

    return currentTropeCount < freeTropeLimit;
  }

  /// Check if user can create more custom filters
  Future<bool> canCreateMoreCustomFilters(int currentFilterCount) async {
    final isPro = await this.isPro();
    if (isPro) return true;

    return currentFilterCount < freeCustomFilterLimit;
  }

  /// Check if user can access advanced analytics
  Future<bool> canAccessAdvancedAnalytics() async {
    return await isPro();
  }

  /// Check if user can access Audible affiliate features
  Future<bool> canAccessAudibleFeatures() async {
    return await isPro();
  }

  /// Show upgrade prompt for book limit
  void showBookLimitUpgradePrompt(BuildContext context) {
    _showUpgradeDialog(
      context,
      title: 'Book Library Full',
      message:
          'Free users can track up to $freeBookLimit books. '
          'Upgrade to Pro for unlimited book tracking!',
      primaryBenefit: 'Unlimited book tracking',
    );
  }

  /// Show upgrade prompt for trope limit
  void showTropeLimitUpgradePrompt(BuildContext context) {
    _showUpgradeDialog(
      context,
      title: 'Trope Selection Limit',
      message:
          'Free users can select up to $freeTropeLimit tropes. '
          'Upgrade to Pro for unlimited trope selections!',
      primaryBenefit: 'Unlimited trope combinations',
    );
  }

  /// Show upgrade prompt for custom filters
  void showCustomFilterLimitUpgradePrompt(BuildContext context) {
    _showUpgradeDialog(
      context,
      title: 'Custom Filter Limit',
      message:
          'Free users can create up to $freeCustomFilterLimit custom filters. '
          'Upgrade to Pro for unlimited saved searches!',
      primaryBenefit: 'Unlimited custom filters',
    );
  }

  /// Show upgrade prompt for advanced analytics
  void showAdvancedAnalyticsUpgradePrompt(BuildContext context) {
    _showUpgradeDialog(
      context,
      title: 'Advanced Analytics',
      message:
          'Advanced reading analytics are a Pro feature. '
          'Upgrade to unlock detailed insights about your reading habits!',
      primaryBenefit: 'Advanced reading analytics',
    );
  }

  /// Show upgrade prompt for Audible features
  void showAudibleUpgradePrompt(BuildContext context) {
    _showUpgradeDialog(
      context,
      title: 'Audible Integration',
      message:
          'Audible affiliate features are exclusive to Pro members. '
          'Upgrade to access audiobook recommendations and affiliate links!',
      primaryBenefit: 'Audible integration & recommendations',
    );
  }

  /// Generic upgrade dialog
  void _showUpgradeDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String primaryBenefit,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.star, color: theme.colorScheme.secondary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withAlpha((0.3 * 255).round()),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pro Features:',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...[
                      primaryBenefit,
                      'Advanced reading analytics',
                      'Ad-free experience',
                      'Priority support',
                    ].map(
                      (benefit) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.secondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                benefit,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe Later',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/pro-club');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
              ),
              child: const Text('Upgrade to Pro'),
            ),
          ],
        );
      },
    );
  }

  /// Show snackbar with upgrade message (alternative to dialog)
  void showUpgradeSnackbar(
    BuildContext context, {
    required String message,
    String actionLabel = 'Upgrade',
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: actionLabel,
          onPressed: () => context.go('/pro-club'),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Get remaining count for free tier features
  Future<Map<String, int>> getFeatureLimitsStatus() async {
    final isPro = await this.isPro();
    if (isPro) {
      return {
        'books': -1, // Unlimited
        'tropes': -1, // Unlimited
        'filters': -1, // Unlimited
      };
    }

    final bookCount = await _libraryService.getUserBookCount();

    return {
      'books': freeBookLimit - bookCount,
      'tropes': freeTropeLimit, // This needs to be checked per context
      'filters': freeCustomFilterLimit, // This needs custom filter tracking
    };
  }

  /// Check and enforce book limit before adding a book
  Future<bool> checkBookLimitAndPrompt(BuildContext context) async {
    final canAdd = await canAddMoreBooks();
    if (!canAdd) {
      if (!context.mounted) return false;
      showBookLimitUpgradePrompt(context);
      return false;
    }
    return true;
  }

  /// Check and enforce trope limit before adding tropes
  Future<bool> checkTropeLimitAndPrompt(
    BuildContext context,
    int currentCount,
  ) async {
    final canAdd = await canSelectMoreTropes(currentCount);
    if (!canAdd) {
      if (!context.mounted) return false;
      showTropeLimitUpgradePrompt(context);
      return false;
    }
    return true;
  }

  /// Check if advanced analytics features should be shown
  Future<bool> shouldShowAdvancedAnalytics() async {
    return await canAccessAdvancedAnalytics();
  }

  /// Check if Audible features should be shown
  Future<bool> shouldShowAudibleFeatures() async {
    return await canAccessAudibleFeatures();
  }
}
