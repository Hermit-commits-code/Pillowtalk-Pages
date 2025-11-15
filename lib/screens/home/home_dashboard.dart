// lib/screens/home/home_dashboard.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_book.dart';
import '../../services/user_library_service.dart';
import '../../services/reading_analytics_service.dart';
import '../../services/pro_status_service.dart';
import '../../services/reading_streak_service.dart';
import '../../widgets/analytics/analytics_dashboard_widgets.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final UserLibraryService _userLibraryService = UserLibraryService();
  final ReadingAnalyticsService _analyticsService = ReadingAnalyticsService();
  final ProStatusService _proStatusService = ProStatusService();
  final ReadingStreakService _streakService = ReadingStreakService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<UserBook>>(
      stream: _userLibraryService.getUserLibraryStream(),
      builder: (context, booksSnapshot) {
        if (booksSnapshot.connectionState == ConnectionState.waiting) {
          return const SingleChildScrollView(
            child: AnalyticsDashboardLoading(),
          );
        }
        if (booksSnapshot.hasError) {
          return Center(child: Text('Error: ${booksSnapshot.error}'));
        }

        final books = booksSnapshot.data ?? [];
        return StreamBuilder<bool>(
          stream: _proStatusService.isProStream(),
          builder: (context, proSnapshot) {
            final isPro = proSnapshot.data ?? false;

            // Calculate stats with Pro status for feature gating
            final stats = _analyticsService.calculateReadingStats(
              books,
              isPro: isPro,
            );

            final currentlyReading = books
                .where((b) => b.status == ReadingStatus.reading)
                .toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Currently Reading Section (moved above Analytics)
                  if (currentlyReading.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Continue Reading',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // BIG FEATURED CARD for first currently reading book
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _FeaturedBookCard(
                        userBook: currentlyReading.first,
                      ),
                    ),
                    // Additional currently reading books (if more than 1)
                    if (currentlyReading.length > 1) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: currentlyReading.length - 1,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, idx) {
                            final book = currentlyReading[idx + 1];
                            return _BookCard(userBook: book);
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],

                  // Your Trending Tropes Section
                  _buildTrendingTropes(books, theme),

                  const SizedBox(height: 20),

                  // Reading Streak Tracker
                  _buildStreakTracker(books, theme),

                  const SizedBox(height: 20),

                  // Analytics Dashboard
                  AnalyticsDashboard(
                    stats: stats,
                    userBooks: books,
                    isPro: isPro,
                  ),

                  const SizedBox(height: 24),

                  // Discover New Books Section
                  _DiscoverBooksSection(),

                  const SizedBox(height: 24),

                  // Bottom padding for navigation bar
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the "Your Trending Tropes" section showing tropes from recently read books
  Widget _buildTrendingTropes(List<UserBook> books, ThemeData theme) {
    // Calculate trending tropes from books read/updated in last 60 days
    final now = DateTime.now();
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));

    // Get books finished or updated recently
    final recentBooks = books.where((book) {
      if (book.dateFinished != null &&
          book.dateFinished!.isAfter(sixtyDaysAgo)) {
        return true;
      }
      if (book.dateStarted != null && book.dateStarted!.isAfter(sixtyDaysAgo)) {
        return true;
      }
      return false;
    }).toList();

    // Count trope frequency
    final Map<String, int> tropeCount = {};
    for (final book in recentBooks) {
      for (final trope in book.userSelectedTropes) {
        tropeCount[trope] = (tropeCount[trope] ?? 0) + 1;
      }
    }

    // Sort by frequency and take top 7
    final trendingTropes = tropeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTropes = trendingTropes.take(7).toList();

    if (topTropes.isEmpty) {
      return const SizedBox.shrink(); // Don't show if no trending tropes
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(Icons.trending_up, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Your Trending Tropes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Based on your last 60 days of reading',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topTropes.map((entry) {
              return ActionChip(
                label: Text('${entry.key} (${entry.value})'),
                avatar: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                onPressed: () {
                  // Future enhancement: filter/search by trope
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Showing books with "${entry.key}"'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Builds the Reading Streak Tracker widget
  Widget _buildStreakTracker(List<UserBook> books, ThemeData theme) {
    final currentStreak = _streakService.calculateCurrentStreak(books);
    final bestStreak = _streakService.calculateBestStreak(books);

    if (currentStreak == 0 && bestStreak == 0) {
      return const SizedBox.shrink(); // Don't show if no streak
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 2,
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Fire emoji for streak
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.deepOrange,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reading Streak',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentStreak day${currentStreak != 1 ? 's' : ''} in a row!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (bestStreak > currentStreak) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Best: $bestStreak days',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (currentStreak > 0)
                Column(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: currentStreak >= 7
                          ? Colors.amber
                          : currentStreak >= 3
                          ? Colors.grey.shade400
                          : Colors.brown.shade300,
                      size: 40,
                    ),
                    Text(
                      currentStreak >= 7
                          ? 'On Fire!'
                          : currentStreak >= 3
                          ? 'Keep Going!'
                          : 'Getting Started',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final UserBook userBook;
  const _BookCard({required this.userBook});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: userBook.imageUrl != null
                    ? Image.network(
                        userBook.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.book,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.book,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      userBook.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (userBook.authors.isNotEmpty)
                      Text(
                        userBook.authors.first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    if (userBook.spiceOverall != null)
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            userBook.spiceOverall!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.red[400],
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Discover New Books section widget for home dashboard
class _DiscoverBooksSection extends StatelessWidget {
  const _DiscoverBooksSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover New Books',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Find your next favorite from our community library',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()),
            ),
          ),
          const SizedBox(height: 16),

          // Discovery options
          Row(
            children: [
              Expanded(
                child: _DiscoveryCard(
                  icon: Icons.search,
                  title: 'Mood Search',
                  subtitle: 'Find books by vibe',
                  color: theme.colorScheme.primary,
                  onTap: () => context.go('/discover'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DiscoveryCard(
                  icon: Icons.trending_up,
                  title: 'Trending',
                  subtitle: 'Popular this week',
                  color: theme.colorScheme.secondary,
                  onTap: () => context.go('/discover?tab=trending'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick mood tags
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMoodTag(context, '🐺 Werewolf Romance'),
                const SizedBox(width: 8),
                _buildMoodTag(context, '😈 Enemies to Lovers'),
                const SizedBox(width: 8),
                _buildMoodTag(context, '🔥 Spicy Fantasy'),
                const SizedBox(width: 8),
                _buildMoodTag(context, '+ More'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTag(BuildContext context, String mood) {
    final theme = Theme.of(context);

    return ActionChip(
      label: Text(mood, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        if (mood == '+ More') {
          context.go('/discover');
        } else {
          // Navigate to discovery with pre-filled search
          final searchTerm = mood.replaceFirst(RegExp(r'^[🐺😈🔥]\s+'), '');
          context.go('/discover?search=${Uri.encodeComponent(searchTerm)}');
        }
      },
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Individual discovery card widget
class _DiscoveryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DiscoveryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minHeight: 90, maxHeight: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(
                      (0.7 * 255).round(),
                    ),
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// BIG FEATURED CARD for the primary currently reading book
class _FeaturedBookCard extends StatelessWidget {
  final UserBook userBook;
  const _FeaturedBookCard({required this.userBook});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          // Navigate to book detail using /book/:id route
          context.push(
            '/book/${userBook.bookId}',
            extra: {'userBook': userBook},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover (larger)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: userBook.imageUrl != null
                    ? Image.network(
                        userBook.imageUrl!,
                        width: 120,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 120,
                          height: 180,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.book,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : Container(
                        width: 120,
                        height: 180,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.book,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Book info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userBook.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (userBook.authors.isNotEmpty)
                      Text(
                        userBook.authors.first,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.7 * 255).round(),
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),
                    // Spice level
                    if (userBook.spiceOverall != null)
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 20,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${userBook.spiceOverall!.toStringAsFixed(1)} Spice',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.red[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    // Reading progress (placeholder - could be enhanced)
                    Text(
                      'Currently Reading',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Continue reading button
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push(
                          '/book/${userBook.bookId}',
                          extra: {'userBook': userBook},
                        );
                      },
                      icon: const Icon(Icons.menu_book, size: 18),
                      label: const Text('Continue Reading'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
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
