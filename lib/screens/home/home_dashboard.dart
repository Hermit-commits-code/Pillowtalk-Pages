// lib/screens/home/home_dashboard.dart
import 'package:flutter/material.dart';

import '../../models/user_book.dart';
import '../../services/user_library_service.dart';
import '../../services/reading_analytics_service.dart';
import '../../services/pro_status_service.dart';
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
                  // Analytics Dashboard
                  AnalyticsDashboard(
                    stats: stats,
                    userBooks: books,
                    isPro: isPro,
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
      },
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
