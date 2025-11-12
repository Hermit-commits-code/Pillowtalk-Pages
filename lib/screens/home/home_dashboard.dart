// lib/screens/home/home_dashboard.dart
import 'package:flutter/material.dart';

import '../../models/user_book.dart';
import '../library/status_books_screen.dart';
import '../../services/user_library_service.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final UserLibraryService _userLibraryService = UserLibraryService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<UserBook>>(
      stream: _userLibraryService.getUserLibraryStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final books = snapshot.data ?? [];

        final wantToRead = books
            .where((b) => b.status == ReadingStatus.wantToRead)
            .toList();
        final currentlyReading = books
            .where((b) => b.status == ReadingStatus.reading)
            .toList();
        final finished = books
            .where((b) => b.status == ReadingStatus.finished)
            .toList();

        // Calculate aggregate stats
        final totalBooks = books.length;
        final booksWithSpice = books
            .where((b) => b.spiceOverall != null && b.spiceOverall! > 0)
            .toList();
        final avgSpice = booksWithSpice.isEmpty
            ? 0.0
            : booksWithSpice.fold<double>(
                  0,
                  (sum, b) => sum + (b.spiceOverall ?? 0),
                ) /
                booksWithSpice.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top aggregate stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(
                    label: 'Total Books',
                    count: totalBooks,
                    color: Colors.amber,
                  ),
                  _StatCard(
                    label: 'Avg Spice',
                    count: avgSpice.toStringAsFixed(1) as dynamic,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Reading status stats
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
                    child: _StatCard(
                      label: 'Want to Read',
                      count: wantToRead.length,
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
                    child: _StatCard(
                      label: 'Reading',
                      count: currentlyReading.length,
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
                    child: _StatCard(
                      label: 'Finished',
                      count: finished.length,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (currentlyReading.isNotEmpty) ...[
                Text('Currently Reading', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: currentlyReading.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, idx) {
                      final book = currentlyReading[idx];
                      return _BookCard(userBook: book);
                    },
                  ),
                ),
              ] else ...[
                const Text('No books are currently being read.'),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final dynamic count; // int or String
  final Color color;
  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withAlpha((0.1 * 255).round()),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count is int ? '$count' : count.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ],
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
              child: userBook.imageUrl != null
                  ? Image.network(userBook.imageUrl!, fit: BoxFit.cover)
                  : Icon(Icons.book, size: 64, color: Colors.grey[400]),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userBook.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  // This can be restored once the spice meter is re-implemented
                  // if (userBook.spiceOverall != null)
                  //   Padding(
                  //     padding: const EdgeInsets.only(top: 4.0),
                  //     child: CompactSpiceRating(
                  //       rating: userBook.spiceOverall!,
                  //       size: 12,
                  //     ),
                  //   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
