// lib/screens/home/home_dashboard.dart
import 'package:flutter/material.dart';

import '../../models/user_book.dart';
import '../library/status_books_screen.dart';
import '../../services/user_library_service.dart';
import '../../services/reading_analytics_service.dart';
import '../../widgets/analytics/analytics_dashboard_widgets.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final UserLibraryService _userLibraryService = UserLibraryService();
  final ReadingAnalyticsService _analyticsService = ReadingAnalyticsService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<UserBook>>(
      stream: _userLibraryService.getUserLibraryStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SingleChildScrollView(
            child: AnalyticsDashboardLoading(),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final books = snapshot.data ?? [];
        final stats = _analyticsService.calculateReadingStats(books);

        final wantToRead = books
            .where((b) => b.status == ReadingStatus.wantToRead)
            .toList();
        final currentlyReading = books
            .where((b) => b.status == ReadingStatus.reading)
            .toList();
        final finished = books
            .where((b) => b.status == ReadingStatus.finished)
            .toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Analytics Dashboard
              AnalyticsDashboard(stats: stats),

              const SizedBox(height: 24),

              // Quick Status Navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Access',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StatusBooksScreen(
                                status: ReadingStatus.wantToRead,
                                title: 'Want to Read',
                              ),
                            ),
                          ),
                          child: _QuickAccessCard(
                            label: 'Want to Read',
                            count: wantToRead.length,
                            icon: Icons.bookmark_outline,
                            color: Colors.blue,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StatusBooksScreen(
                                status: ReadingStatus.reading,
                                title: 'Currently Reading',
                              ),
                            ),
                          ),
                          child: _QuickAccessCard(
                            label: 'Reading',
                            count: currentlyReading.length,
                            icon: Icons.auto_stories,
                            color: Colors.purple,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StatusBooksScreen(
                                status: ReadingStatus.finished,
                                title: 'Finished',
                              ),
                            ),
                          ),
                          child: _QuickAccessCard(
                            label: 'Finished',
                            count: finished.length,
                            icon: Icons.done_all,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Currently Reading Section
              if (currentlyReading.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Continue Reading',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: currentlyReading.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, idx) {
                      final book = currentlyReading[idx];
                      return _BookCard(userBook: book);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Bottom padding for navigation bar
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _QuickAccessCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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
