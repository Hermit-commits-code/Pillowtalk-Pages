// lib/screens/library/finished_books_screen.dart

import 'package:flutter/material.dart';

import '../../models/user_book.dart';
import '../../services/user_library_service.dart';
import '../book/book_detail_screen.dart';

class FinishedBooksScreen extends StatefulWidget {
  const FinishedBooksScreen({super.key});

  @override
  State<FinishedBooksScreen> createState() => _FinishedBooksScreenState();
}

class _FinishedBooksScreenState extends State<FinishedBooksScreen> {
  final UserLibraryService _libraryService = UserLibraryService();
  int? _minStars;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finished Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by stars',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: StreamBuilder<List<UserBook>>(
        stream: _libraryService.getUserLibraryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final books = snapshot.data ?? [];
          final finished = books
              .where((b) => b.status == ReadingStatus.finished)
              .toList();

          final filtered = finished.where((b) {
            if (_minStars != null) {
              final stars = b.personalStars ?? 0;
              return stars >= _minStars!;
            }
            return true;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Text(
                'No finished books${_minStars != null ? ' (>= $_minStars★)' : ''}.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final ub = filtered[index];
              return ListTile(
                leading: ub.imageUrl != null
                    ? Image.network(
                        ub.imageUrl!,
                        width: 48,
                        height: 72,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.book, size: 48),
                title: Text(ub.title),
                subtitle: Text(ub.authors.join(', ')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ub.personalStars != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text('${ub.personalStars}'),
                        ],
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () async {
                  final changed = await Navigator.push<bool?>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookDetailScreen(
                        title: ub.title,
                        author: ub.authors.join(', '),
                        coverUrl: ub.imageUrl,
                        description: ub.description,
                        genres: ub.genres,
                        seriesName: ub.seriesName,
                        seriesIndex: ub.seriesIndex,
                        userSelectedTropes: ub.userSelectedTropes,
                        userContentWarnings: ub.userContentWarnings,
                        bookId: ub.bookId,
                        userBookId: ub.id,
                        userNotes: ub.userNotes,
                        spiceOverall: ub.spiceOverall,
                        spiceIntensity: ub.spiceIntensity,
                        emotionalArc: ub.emotionalArc,
                      ),
                    ),
                  );
                  // If user saved changes in the detail screen (returned true), nothing else required
                  if (changed == true) {
                    // trigger rebuild by setState
                    setState(() {});
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _openFilterSheet() async {
    final result = await showModalBottomSheet<int?>(
      context: context,
      builder: (context) {
        int selected = _minStars ?? 0;
        return StatefulBuilder(
          builder: (context, setLocal) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Minimum personal stars'),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(6, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(i == 0 ? 'Any' : '$i★'),
                            selected: selected == i,
                            onSelected: (_) => setLocal(() => selected = i),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(
                          context,
                          selected == 0 ? null : selected,
                        ),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null || (_minStars != null && result == null)) {
      setState(() {
        _minStars = result;
      });
    }
  }
}
