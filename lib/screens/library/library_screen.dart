// lib/screens/library/library_screen.dart

import 'package:flutter/material.dart';

import '../../models/user_book.dart';
import '../../services/user_library_service.dart';
import '../book/book_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int? _minStarsFilter;
  String? _tropeFilter;

  void _openFilterSheet() async {
    final minStars = _minStarsFilter ?? 0;
    final trope = _tropeFilter ?? '';
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        int selectedStars = minStars;
        final TextEditingController tropeCtrl = TextEditingController(
          text: trope,
        );
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter by minimum personal stars'),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(6, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(i == 0 ? 'Any' : '$i★'),
                          selected: selectedStars == i,
                          onSelected: (_) =>
                              setLocalState(() => selectedStars = i),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  const Text('Trope contains (case-insensitive)'),
                  const SizedBox(height: 8),
                  TextField(controller: tropeCtrl),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop({
                          'minStars': selectedStars == 0 ? null : selectedStars,
                          'trope': tropeCtrl.text.trim().isEmpty
                              ? null
                              : tropeCtrl.text.trim(),
                        }),
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

    if (result != null) {
      setState(() {
        _minStarsFilter = result['minStars'] as int?;
        _tropeFilter = result['trope'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserLibraryService userLibraryService = UserLibraryService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Library', style: theme.appBarTheme.titleTextStyle),
        actions: [
          IconButton(
            tooltip: 'Filter',
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: StreamBuilder<List<UserBook>>(
        stream: userLibraryService.getUserLibraryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final books = snapshot.data ?? [];

          if (books.isEmpty) {
            return const Center(child: Text('Your library is empty.'));
          }

          // Apply client-side filters if any
          final filtered = books.where((book) {
            if (_minStarsFilter != null) {
              final stars = book.personalStars ?? 0;
              if (stars < _minStarsFilter!) return false;
            }
            if (_tropeFilter != null && _tropeFilter!.isNotEmpty) {
              final q = _tropeFilter!.toLowerCase();
              final has = book.userSelectedTropes.any(
                (t) => t.toLowerCase().contains(q),
              );
              if (!has) return false;
            }
            return true;
          }).toList();

          final groupedBooks = filtered.fold<Map<String, List<UserBook>>>({}, (
            map,
            book,
          ) {
            final genres = book.genres.isNotEmpty
                ? book.genres
                : ['Uncategorized'];
            for (var genre in genres) {
              (map[genre] ??= []).add(book);
            }
            return map;
          });

          final genres = groupedBooks.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: genres.map((genre) {
              final booksForGenre = groupedBooks[genre]!;
              return _BookCarousel(
                title: genre,
                books: booksForGenre,
                userLibraryService: userLibraryService,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _BookCarousel extends StatelessWidget {
  final String title;
  final List<UserBook> books;
  final UserLibraryService userLibraryService;

  const _BookCarousel({
    required this.title,
    required this.books,
    required this.userLibraryService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${books.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 290,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final userBook = books[index];
              return _BookCard(
                userBook: userBook,
                userLibraryService: userLibraryService,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _BookCard extends StatelessWidget {
  final UserBook userBook;
  final UserLibraryService userLibraryService;

  const _BookCard({required this.userBook, required this.userLibraryService});

  @override
  Widget build(BuildContext context) {
    // Debug: log ownership to help diagnose why ownership indicator may not show
    // This will print each time the book card is built.
    debugPrint(
      'BookCard render -> id=${userBook.id}, ownership=${userBook.ownership}',
    );
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailScreen(
              title: userBook.title,
              author: userBook.authors.join(', '),
              coverUrl: userBook.imageUrl,
              description: userBook.description,
              genres: userBook.genres,
              seriesName: userBook.seriesName,
              seriesIndex: userBook.seriesIndex,
              userSelectedTropes: userBook.userSelectedTropes,
              userContentWarnings: userBook.userContentWarnings,
              bookId: userBook.bookId,
              userBookId: userBook.id,
              userNotes: userBook.userNotes,
              spiceOverall: userBook.spiceOverall,
              spiceIntensity: userBook.spiceIntensity,
              emotionalArc: userBook.emotionalArc,
            ),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    userBook.imageUrl != null
                        ? Image.network(
                            userBook.imageUrl!,
                            width: 150,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                    // Ownership indicator circle
                    if (userBook.ownership != BookOwnership.none)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _ownershipColor(userBook.ownership),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    if (userBook.seriesIndex != null &&
                        userBook.seriesIndex! > 0)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '#${userBook.seriesIndex}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    userBook.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userBook.authors.join(', '),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 150,
      height: 200,
      color: Colors.grey[300],
      child: const Icon(Icons.book, size: 48),
    );
  }

  Color _ownershipColor(BookOwnership ownership) {
    switch (ownership) {
      case BookOwnership.physical:
        return Colors.brown;
      case BookOwnership.digital:
        return Colors.blue;
      case BookOwnership.both:
        return Colors.green;
      case BookOwnership.kindleUnlimited:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
