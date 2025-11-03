// lib/screens/home/home_dashboard.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/book_model.dart';
import '../../models/user_book.dart';
import '../../services/community_data_service.dart';
import '../../services/user_library_service.dart';
import '../../widgets/compact_spice_rating.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final UserLibraryService userLibraryService = UserLibraryService();
  Set<String> _filteredUserBookIds = <String>{};
  bool _isComputingFilters = false;
  bool _showFiltered = false;

  // Hard stops and kink filters (populated by services elsewhere in the app)
  final bool _hardStopsEnabled = false;
  final List<String> _hardStops = [];
  final bool _kinkFilterEnabled = false;
  final List<String> _kinkFilters = [];

  bool _isBookFiltered(RomanceBook? doc, UserBook ub) {
    if (doc == null) return false;

    if (_hardStopsEnabled && _hardStops.isNotEmpty) {
      for (final w in doc.topWarnings) {
        for (final h in _hardStops) {
          if (w.toLowerCase().contains(h.toLowerCase()) ||
              h.toLowerCase().contains(w.toLowerCase())) {
            return true;
          }
        }
      }

      for (final t in doc.communityTropes) {
        for (final h in _hardStops) {
          if (t.toLowerCase().contains(h.toLowerCase()) ||
              h.toLowerCase().contains(t.toLowerCase())) {
            return true;
          }
        }
      }
    }

    if (_kinkFilterEnabled && _kinkFilters.isNotEmpty) {
      for (final tp in doc.communityTropes) {
        for (final k in _kinkFilters) {
          if (tp.toLowerCase().contains(k.toLowerCase()) ||
              k.toLowerCase().contains(tp.toLowerCase())) {
            return true;
          }
        }
      }

      for (final w in doc.topWarnings) {
        for (final k in _kinkFilters) {
          if (w.toLowerCase().contains(k.toLowerCase()) ||
              k.toLowerCase().contains(w.toLowerCase())) {
            return true;
          }
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    String displayName = user?.displayName ?? user?.email ?? 'Reader';
    if (displayName.startsWith('\\')) {
      displayName = displayName.substring(1);
    }

    return StreamBuilder<List<UserBook>>(
      stream: userLibraryService.getUserLibraryStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final books = snapshot.data ?? [];
        // Compute filtered ids (and visible set) using cached fields when possible.
        return FutureBuilder<List<UserBook>>(
          future: _filterLibraryLists(books),
          builder: (context, snap2) {
            if (snap2.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final visible = snap2.data ?? books;
            final wantToRead = visible
                .where((b) => b.status == ReadingStatus.wantToRead)
                .toList();
            final currentlyReading = visible
                .where((b) => b.status == ReadingStatus.reading)
                .toList();
            final finished = visible
                .where((b) => b.status == ReadingStatus.finished)
                .toList();
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $displayName!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withAlpha(102),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 12),
                  // Hidden count + toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${_filteredUserBookIds.length} hidden by filters',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatCard(
                        label: 'Want to Read',
                        count: wantToRead.length,
                        color: Colors.blue,
                      ),
                      _StatCard(
                        label: 'Reading',
                        count: currentlyReading.length,
                        color: Colors.purple,
                      ),
                      _StatCard(
                        label: 'Finished',
                        count: finished.length,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (currentlyReading.isNotEmpty) ...[
                    Text(
                      'Currently Reading',
                      style: theme.textTheme.titleLarge,
                    ),
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
                    Text(
                      'No books are currently being read.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<UserBook>> _filterLibraryLists(List<UserBook> books) async {
    final community = CommunityDataService();
    final out = <UserBook>[];
    final filtered = <String>{};
    _isComputingFilters = true;
    try {
      final futures = books.map((ub) async {
        if (ub.ignoreFilters) return;
        // Prefer cached fields
        final cachedWarnings = ub.cachedTopWarnings;
        final cachedTropes = ub.cachedTropes;
        RomanceBook? doc;
        bool matched = false;
        if (cachedWarnings.isNotEmpty || cachedTropes.isNotEmpty) {
          // Create a lightweight RomanceBook-like object for matching
          doc = RomanceBook(
            id: ub.bookId,
            isbn: '',
            title: '',
            authors: const [],
            description: '',
            imageUrl: null,
            genre: '',
            subgenres: const [],
            communityTropes: cachedTropes,
            topWarnings: cachedWarnings,
            avgSpiceOnPage: 0.0,
            avgEmotionalIntensity: 0.0,
            totalUserRatings: 0,
          );
          matched = _isBookFiltered(doc, ub);
        } else {
          doc = await community.getCommunityBookData(ub.bookId);
          matched = _isBookFiltered(doc, ub);
        }
        if (matched) filtered.add(ub.id);
        return;
      });

      await Future.wait(futures);
    } finally {
      _filteredUserBookIds = filtered;
      _isComputingFilters = false;
    }

    for (final ub in books) {
      if (!_filteredUserBookIds.contains(ub.id) || _showFiltered) out.add(ub);
    }
    return out;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
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
              '$count',
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
    final userLib = UserLibraryService();
    final communityDataService = CommunityDataService();

    return FutureBuilder<RomanceBook?>(
      future: communityDataService.getCommunityBookData(userBook.bookId),
      builder: (context, snapshot) {
        final romanceBook = snapshot.data;

        return SizedBox(
          width: 160,
          child: Card(
            elevation: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Icon(Icons.book, size: 64, color: Colors.grey[400]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userBook.id,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      // Spice rating
                      if (romanceBook != null)
                        CompactSpiceRating(
                          rating: romanceBook.avgSpiceOnPage,
                          ratingCount: romanceBook.totalUserRatings,
                          size: 12,
                        ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            tooltip: 'Resume',
                            onPressed: () {
                              // Navigate to book detail page for resume
                              context.push('/book/${userBook.bookId}');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Remove',
                            onPressed: () async {
                              final backup = userBook;
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Remove book'),
                                  content: const Text(
                                    'Remove this book from your library?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm != true) return;

                              try {
                                await userLib.removeBook(userBook.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Book removed'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () async {
                                        // restore
                                        await userLib.setBook(backup);
                                      },
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to remove: $e'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
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
}
