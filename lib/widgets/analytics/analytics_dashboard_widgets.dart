// lib/widgets/analytics/analytics_dashboard_widgets.dart
import 'package:flutter/material.dart';
import '../../services/reading_analytics_service.dart';
import '../../models/user_book.dart';

/// Main analytics dashboard widget for home screen
class AnalyticsDashboard extends StatelessWidget {
  final ReadingStats stats;

  const AnalyticsDashboard({super.key, required this.stats});

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

        // Top stats row
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              StatsCard(
                title: 'Books Read',
                value: stats.totalBooksRead.toString(),
                icon: Icons.library_books,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              StatsCard(
                title: 'Pages Read',
                value: stats.formattedTotalPages,
                icon: Icons.menu_book,
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              StatsCard(
                title: 'Avg Spice',
                value: stats.averageSpiceRating.toStringAsFixed(1),
                icon: Icons.local_fire_department,
                color: Colors.red,
              ),
              const SizedBox(width: 12),
              StatsCard(
                title: 'Reading Streak',
                value: '${stats.currentStreak} days',
                icon: Icons.whatshot,
                color: Colors.orange,
              ),
              if (stats.totalAudiobookMinutes > 0) ...[
                const SizedBox(width: 12),
                StatsCard(
                  title: 'Audiobook Time',
                  value: stats.formattedAudiobookTime,
                  icon: Icons.headphones,
                  color: Colors.purple,
                ),
              ],
            ],
          ),
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

        // Top tropes
        if (stats.topTropes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TopTropesWidget(tropes: stats.topTropes),
          ),
          const SizedBox(height: 24),
        ],

        // Format breakdown chart
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FormatBreakdownWidget(breakdown: stats.formatBreakdown),
        ),
      ],
    );
  }
}

/// Individual stats card widget
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
            ).textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8)),
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
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
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
            }).toList(),
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
            }).toList(),
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
