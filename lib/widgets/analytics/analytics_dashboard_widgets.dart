// lib/widgets/analytics/analytics_dashboard_widgets.dart
import 'package:flutter/material.dart';
import '../../services/reading_analytics_service.dart';
import '../../services/feature_gating_service.dart';
import '../../models/user_book.dart';
import '../../screens/library/status_books_screen.dart';

/// Main analytics dashboard widget for home screen
class AnalyticsDashboard extends StatelessWidget {
  final ReadingStats stats;
  final List<UserBook> userBooks; // Add this to enable navigation
  final bool isPro; // Add Pro status

  const AnalyticsDashboard({
    super.key,
    required this.stats,
    required this.userBooks,
    this.isPro = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Your Reading Analytics',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        // Stats grid (2x2 or 2x3 depending on audiobook data)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildStatsGrid(context),
        ),

        const SizedBox(height: 24),

        // Yearly goal progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: YearlyGoalWidget(progress: stats.yearlyGoalProgress),
        ),

        const SizedBox(height: 24),

        // Favorite genres
        if (stats.favoriteGenres.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FavoriteGenresWidget(genres: stats.favoriteGenres),
          ),
          const SizedBox(height: 24),
        ],

        // Top tropes (Pro feature)
        if (stats.topTropes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: isPro
                ? TopTropesWidget(tropes: stats.topTropes)
                : _buildProFeatureCard(
                    context,
                    title: 'Top Tropes Analysis',
                    description: 'See your most loved tropes and patterns',
                    icon: Icons.favorite,
                  ),
          ),
          const SizedBox(height: 24),
        ],

        // Format breakdown chart (Pro feature)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: isPro
              ? FormatBreakdownWidget(breakdown: stats.formatBreakdown)
              : _buildProFeatureCard(
                  context,
                  title: 'Format Breakdown',
                  description: 'Visual breakdown of your reading formats',
                  icon: Icons.pie_chart,
                ),
        ),
      ],
    );
  }

  /// Build responsive grid of stats cards with navigation
  Widget _buildStatsGrid(BuildContext context) {
    final wantToReadBooks = userBooks
        .where((book) => book.status == ReadingStatus.wantToRead)
        .length;
    final currentlyReading = userBooks
        .where((book) => book.status == ReadingStatus.reading)
        .length;

    return Column(
      children: [
        // First row - Clickable navigation cards
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    _navigateToBooks(context, ReadingStatus.wantToRead),
                child: StatsCard(
                  title: 'Want to Read',
                  value: wantToReadBooks.toString(),
                  icon: Icons.bookmark_outline,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _navigateToBooks(context, ReadingStatus.reading),
                child: StatsCard(
                  title: 'Currently Reading',
                  value: currentlyReading.toString(),
                  icon: Icons.auto_stories,
                  color: Colors.purple,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row - Analytics cards
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Avg Spice',
                value: stats.averageSpiceRating.toStringAsFixed(1),
                icon: Icons.local_fire_department,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                title: isPro ? 'Reading Streak' : 'Books (7 days)',
                value: isPro
                    ? '${stats.currentStreak} days'
                    : '${stats.currentStreak} books',
                subtitle: isPro
                    ? 'Consecutive reading days'
                    : 'Upgrade for streak tracking',
                icon: Icons.whatshot,
                color: Colors.orange,
                isProFeature: !isPro,
              ),
            ),
          ],
        ),
        // Third row - Additional stats (if audiobook data exists)
        if (stats.totalAudiobookMinutes > 0 || stats.totalBooksRead > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _navigateToBooks(context, ReadingStatus.finished),
                  child: StatsCard(
                    title: 'Books Read',
                    value: stats.totalBooksRead.toString(),
                    icon: Icons.library_books,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: stats.totalAudiobookMinutes > 0
                    ? StatsCard(
                        title: 'Audiobook Time',
                        value: stats.formattedAudiobookTime,
                        icon: Icons.headphones,
                        color: Colors.indigo,
                      )
                    : StatsCard(
                        title: 'Total Pages',
                        value: stats.formattedTotalPages,
                        icon: Icons.menu_book,
                        color: Colors.teal,
                      ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Build a card promoting Pro upgrade for advanced features
  Widget _buildProFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary.withAlpha((0.1 * 255).round()),
            theme.colorScheme.secondary.withAlpha((0.05 * 255).round()),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.secondary.withAlpha((0.3 * 255).round()),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.secondary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              Icon(
                Icons.lock,
                color: theme.colorScheme.secondary.withAlpha(
                  (0.7 * 255).round(),
                ),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((0.8 * 255).round()),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                FeatureGatingService().showAdvancedAnalyticsUpgradePrompt(
                  context,
                );
              },
              icon: Icon(
                Icons.star,
                size: 18,
                color: theme.colorScheme.onSecondary,
              ),
              label: Text(
                'Upgrade to Pro',
                style: TextStyle(color: theme.colorScheme.onSecondary),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to status-specific book screen
  void _navigateToBooks(BuildContext context, ReadingStatus status) {
    final statusTitles = {
      ReadingStatus.wantToRead: 'Want to Read',
      ReadingStatus.reading: 'Currently Reading',
      ReadingStatus.finished: 'Finished Books',
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatusBooksScreen(
          status: status,
          title: statusTitles[status] ?? 'Books',
        ),
      ),
    );
  }
}

/// Individual stats card widget
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isProFeature;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.isProFeature = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.2 * 255).round())),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color.withAlpha((0.8 * 255).round())),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Yearly reading goal progress widget
class YearlyGoalWidget extends StatelessWidget {
  final YearlyGoalProgress progress;

  const YearlyGoalWidget({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Yearly Reading Goal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  progress.isOnTrack ? Icons.check_circle : Icons.warning,
                  color: progress.isOnTrack ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.completed} of ${progress.goal} books',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              progress.goalDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()),
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                progress.isOnTrack ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.progressPercentage.toStringAsFixed(0)}% complete',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${progress.remaining} remaining',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            if (!progress.isOnTrack)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'You\'re behind schedule - consider picking up the pace!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Favorite genres display widget
class FavoriteGenresWidget extends StatelessWidget {
  final List<GenreCount> genres;

  const FavoriteGenresWidget({super.key, required this.genres});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Favorite Genres',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: genres.map((genreCount) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withAlpha((0.2 * 255).round()),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        genreCount.genre,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          genreCount.count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top tropes display widget
class TopTropesWidget extends StatelessWidget {
  final List<TropeCount> tropes;

  const TopTropesWidget({super.key, required this.tropes});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Favorite Tropes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...tropes.map((tropeCount) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tropeCount.trope,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: tropeCount.count / tropes.first.count,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tropeCount.count.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Format breakdown chart widget
class FormatBreakdownWidget extends StatelessWidget {
  final Map<BookFormat, int> breakdown;

  const FormatBreakdownWidget({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final totalBooks = breakdown.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    if (totalBooks == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Format Breakdown',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...breakdown.entries.where((entry) => entry.value > 0).map((entry) {
              final percentage = (entry.value / totalBooks * 100)
                  .toStringAsFixed(0);
              final format = entry.key;
              final color = _getFormatColor(format);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Icon(_getFormatIcon(format), color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getFormatDisplayName(format),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${entry.value} books',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($percentage%)',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getFormatColor(BookFormat format) {
    switch (format) {
      case BookFormat.paperback:
        return Colors.brown;
      case BookFormat.hardcover:
        return Colors.blue;
      case BookFormat.ebook:
        return Colors.green;
      case BookFormat.audiobook:
        return Colors.purple;
    }
  }

  IconData _getFormatIcon(BookFormat format) {
    switch (format) {
      case BookFormat.paperback:
      case BookFormat.hardcover:
        return Icons.menu_book;
      case BookFormat.ebook:
        return Icons.tablet_android;
      case BookFormat.audiobook:
        return Icons.headphones;
    }
  }

  String _getFormatDisplayName(BookFormat format) {
    switch (format) {
      case BookFormat.paperback:
        return 'Paperback';
      case BookFormat.hardcover:
        return 'Hardcover';
      case BookFormat.ebook:
        return 'E-book';
      case BookFormat.audiobook:
        return 'Audiobook';
    }
  }
}

/// Loading state widget for analytics dashboard
class AnalyticsDashboardLoading extends StatelessWidget {
  const AnalyticsDashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Your Reading Analytics',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < 3 ? 12 : 0),
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(16.0),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ],
    );
  }
}
