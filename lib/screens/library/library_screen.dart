// lib/screens/library/library_screen.dart

import 'package:flutter/material.dart';

import '../../models/book_model.dart';
import '../../models/user_book.dart';
import '../../services/community_data_service.dart';
import '../../services/hard_stops_service.dart';
import '../../services/kink_filter_service.dart';
import '../../services/user_library_service.dart';
import '../../widgets/compact_spice_rating.dart';
import '../book/book_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isCleaning = false;
  // Hard stops state
  final HardStopsService _hardStopsService = HardStopsService();
  List<String> _hardStops = [];
  bool _hardStopsEnabled = true;
  // Kink filters
  final KinkFilterService _kinkFilterService = KinkFilterService();
  List<String> _kinkFilters = [];
  bool _kinkFilterEnabled = true;
  Set<String> _filteredUserBookIds = {};
  bool _isComputingFilters = false;
  bool _showFiltered = false;

  @override
  void initState() {
    super.initState();
    // Listen for changes to hard stops and recompute when they change
    _hardStopsService.hardStopsStream().listen((stops) {
      _hardStops = stops;
      // recompute will be triggered when stream builder receives books
      // but we proactively mark filtered set empty to force recompute
      setState(() {
        _filteredUserBookIds = {};
      });
    });
    _hardStopsService.hardStopsEnabledStream().listen((enabled) {
      setState(() => _hardStopsEnabled = enabled);
    });
    // Kink filter listeners
    _kinkFilterService.kinkFilterStream().listen((filters) {
      _kinkFilters = filters;
      setState(() => _filteredUserBookIds = {});
    });
    _kinkFilterService.kinkFilterEnabledStream().listen((enabled) {
      setState(() => _kinkFilterEnabled = enabled);
    });
  }

  Future<void> _cleanOrphans(UserLibraryService userLibraryService) async {
    if (!mounted) return;
    setState(() => _isCleaning = true);
    final community = CommunityDataService();
    try {
      final books = await userLibraryService.getUserLibraryStream().first;
      final orphanIds = <String>[];
      for (final ub in books) {
        final doc = await community.getCommunityBookData(ub.bookId);
        if (doc == null) orphanIds.add(ub.id);
      }

      if (orphanIds.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No orphaned library entries found.')),
        );
        return;
      }

      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Remove ${orphanIds.length} orphaned entries?'),
          content: const Text(
            'Some library entries reference community books that no longer exist. Remove them from your library?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (confirm == true) {
        for (final id in orphanIds) {
          await userLibraryService.removeBook(id);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed ${orphanIds.length} entries.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to clean library: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCleaning = false);
    }
  }

  /// Group books by genre to render Netflix-style shelves per genre.
  Map<String, List<UserBook>> _groupBooksByGenre(List<UserBook> books) {
    final Map<String, List<UserBook>> grouped = {};
    for (final book in books) {
      final genre = (book.genre.isNotEmpty) ? book.genre : 'Uncategorized';
      grouped.putIfAbsent(genre, () => []).add(book);
    }
    return grouped;
  }

  Future<void> _computeFilteredUserBooks(List<UserBook> books) async {
    final filtersEnabled =
        (_hardStopsEnabled && _hardStops.isNotEmpty) ||
        (_kinkFilterEnabled && _kinkFilters.isNotEmpty);
    if (!filtersEnabled) {
      if (_filteredUserBookIds.isNotEmpty) {
        setState(() => _filteredUserBookIds = {});
      }
      return;
    }
    if (_isComputingFilters) return;
    _isComputingFilters = true;
    final Set<String> filtered = {};
    final community = CommunityDataService();
    try {
      final futures = books.map((ub) async {
        if (ub.ignoreFilters) return;
        final doc = await community.getCommunityBookData(ub.bookId);
        if (doc != null) {
          final topWarnings = doc.topWarnings;
          final tropes = doc.communityTropes;

          // Hard stops match topWarnings OR tropes
          for (final w in topWarnings) {
            for (final h in _hardStops) {
              if (w.toLowerCase().contains(h.toLowerCase()) ||
                  h.toLowerCase().contains(w.toLowerCase())) {
                filtered.add(ub.id);
                return;
              }
            }
          }

          for (final t in tropes) {
            for (final h in _hardStops) {
              if (t.toLowerCase().contains(h.toLowerCase()) ||
                  h.toLowerCase().contains(t.toLowerCase())) {
                filtered.add(ub.id);
                return;
              }
            }
          }

          // Kink filters primarily match tropes (but also warnings as fallback)
          for (final tp in tropes) {
            for (final k in _kinkFilters) {
              if (tp.toLowerCase().contains(k.toLowerCase()) ||
                  k.toLowerCase().contains(tp.toLowerCase())) {
                filtered.add(ub.id);
                return;
              }
            }
          }
          for (final w in topWarnings) {
            for (final k in _kinkFilters) {
              if (w.toLowerCase().contains(k.toLowerCase()) ||
                  k.toLowerCase().contains(w.toLowerCase())) {
                filtered.add(ub.id);
                return;
              }
            }
          }
        }
      });

      await Future.wait(futures);
    } catch (_) {
      // ignore errors per-book
    } finally {
      if (mounted) setState(() => _filteredUserBookIds = filtered);
      _isComputingFilters = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserLibraryService userLibraryService = UserLibraryService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Library', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        actions: [
          IconButton(
            tooltip: 'Clean orphaned entries',
            onPressed: _isCleaning
                ? null
                : () => _cleanOrphans(userLibraryService),
            icon: _isCleaning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cleaning_services_outlined),
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
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            );
          }
          final books = snapshot.data ?? [];
          // Compute filtered set based on community warnings and user's hard stops
          _computeFilteredUserBooks(books);
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 80,
                    color: theme.colorScheme.onSurface.withAlpha(
                      (0.3 * 255).round(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your library is empty.',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start adding books to track your reading!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(
                        (0.7 * 255).round(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Group books by genre into shelves
          final groupedBooks = _groupBooksByGenre(books);

          final genres = groupedBooks.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${_filteredUserBookIds.length} hidden by your content filters',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (_isComputingFilters) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Show filtered'),
                        Switch(
                          value: _showFiltered,
                          onChanged: (v) => setState(() => _showFiltered = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              for (final genre in genres)
                if (groupedBooks[genre]!.isNotEmpty)
                  _BookCarousel(
                    title: genre,
                    books: groupedBooks[genre]!,
                    userLibraryService: userLibraryService,
                    filteredUserBookIds: _filteredUserBookIds,
                    showFiltered: _showFiltered,
                  ),
            ],
          );
        },
      ),
    );
  }
}

/// Netflix-style horizontal scrolling carousel for a category of books
class _BookCarousel extends StatelessWidget {
  final String title;
  final List<UserBook> books;
  final UserLibraryService userLibraryService;
  final Set<String> filteredUserBookIds;
  final bool showFiltered;

  const _BookCarousel({
    required this.title,
    required this.books,
    required this.userLibraryService,
    this.filteredUserBookIds = const {},
    this.showFiltered = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final visibleBooks = books
        .where((b) => !filteredUserBookIds.contains(b.id) || showFiltered)
        .toList();

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
                  '${visibleBooks.length}',
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
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: visibleBooks.length,
            itemBuilder: (context, index) {
              final userBook = visibleBooks[index];
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

/// Individual book card in the carousel
class _BookCard extends StatelessWidget {
  final UserBook userBook;
  final UserLibraryService userLibraryService;

  const _BookCard({required this.userBook, required this.userLibraryService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<RomanceBook?>(
      future: CommunityDataService().getCommunityBookData(userBook.bookId),
      builder: (context, snapshot) {
        final romanceBook = snapshot.data;

        return GestureDetector(
          onTap: () {
            if (romanceBook != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailScreen(
                    title: romanceBook.title,
                    author: romanceBook.authors.isNotEmpty
                        ? romanceBook.authors.join(', ')
                        : 'Unknown',
                    coverUrl: romanceBook.imageUrl,
                    description: romanceBook.description,
                    genre: romanceBook.genre,
                    subgenres: romanceBook.subgenres,
                    seriesName: romanceBook.seriesName,
                    seriesIndex: romanceBook.seriesIndex,
                    communityTropes: romanceBook.communityTropes,
                    availableTropes: romanceBook.communityTropes,
                    availableWarnings: romanceBook.topWarnings,
                    userSelectedTropes: userBook.userSelectedTropes,
                    userContentWarnings: userBook.userContentWarnings,
                    spiceLevel: romanceBook.avgSpiceOnPage,
                    bookId: romanceBook.id,
                    userBookId: userBook.id,
                    userNotes: userBook.userNotes,
                  ),
                ),
              );
            } else {
              // Book doc missing — inform user and offer quick action via long-press options
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'This book is missing community metadata (deleted). Long-press the card to remove it from your library.',
                  ),
                ),
              );
            }
          },
          onLongPress: () {
            _showBookOptions(context, romanceBook);
          },
          child: Container(
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.2 * 255).round()),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        romanceBook?.imageUrl != null
                            ? Image.network(
                                romanceBook!.imageUrl!,
                                width: 140,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholder(theme);
                                },
                              )
                            : _buildPlaceholder(theme),
                        if (romanceBook == null)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withAlpha(
                                (0.4 * 255).round(),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.white70,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Missing',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Book title and author centered
                SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        romanceBook?.title ?? userBook.bookId,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        romanceBook != null && romanceBook.authors.isNotEmpty
                            ? romanceBook.authors.join(', ')
                            : '',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.7 * 255).round(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Spice rating
                      if (romanceBook != null)
                        CompactSpiceRating(
                          rating: romanceBook.avgSpiceOnPage,
                          ratingCount: romanceBook.totalUserRatings,
                          size: 12,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: 140,
      height: 180,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.book, size: 48, color: theme.colorScheme.onSurface),
    );
  }

  void _showBookOptions(BuildContext context, RomanceBook? romanceBook) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  if (romanceBook != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailScreen(
                          title: romanceBook.title,
                          author: romanceBook.authors.isNotEmpty
                              ? romanceBook.authors.join(', ')
                              : 'Unknown',
                          coverUrl: romanceBook.imageUrl,
                          description: romanceBook.description,
                          genre: romanceBook.genre,
                          subgenres: romanceBook.subgenres,
                          seriesName: romanceBook.seriesName,
                          seriesIndex: romanceBook.seriesIndex,
                          communityTropes: romanceBook.communityTropes,
                          availableTropes: romanceBook.communityTropes,
                          availableWarnings: romanceBook.topWarnings,
                          userSelectedTropes: userBook.userSelectedTropes,
                          userContentWarnings: userBook.userContentWarnings,
                          spiceLevel: romanceBook.avgSpiceOnPage,
                          bookId: romanceBook.id,
                          userBookId: userBook.id,
                          userNotes: userBook.userNotes,
                        ),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove from Library'),
                onTap: () async {
                  debugPrint(
                    'DEBUG: Remove from Library tapped for userBook.id: ${userBook.id}',
                  );
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove Book'),
                      content: const Text(
                        'Are you sure you want to remove this book from your library?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );
                  debugPrint('DEBUG: Dialog result for delete: $confirm');
                  if (confirm == true && context.mounted) {
                    debugPrint(
                      'DEBUG: Calling removeBook with id: ${userBook.id}',
                    );
                    try {
                      final backup = userBook;
                      await userLibraryService.removeBook(userBook.id);
                      debugPrint(
                        'DEBUG: removeBook completed for id: ${userBook.id}',
                      );
                      if (context.mounted) {
                        Navigator.pop(context); // Now close the bottom sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Book removed from your library.',
                            ),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () async {
                                try {
                                  await userLibraryService.setBook(backup);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to restore book: $e',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('DEBUG: Exception in removeBook: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error removing book: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ], // <-- Add this closing bracket for children
          ), // <-- Close Column
        ); // <-- Close SafeArea
      }, // <-- Close builder
    ); // <-- Close showModalBottomSheet
  }

  // _showChangeStatusDialog was removed because it was unused. If you need
  // this UI in future, reintroduce it and wire it into the call-sites.
}
