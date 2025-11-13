import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../services/hard_stops_service.dart';
import '../../../services/kink_filter_service.dart';

class CuratedLibraryScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const CuratedLibraryScreen({
    Key? key,
    required this.userId,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<CuratedLibraryScreen> createState() => _CuratedLibraryScreenState();
}

class _CuratedLibraryScreenState extends State<CuratedLibraryScreen> {
  List<Map<String, dynamic>> curatedBooks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCuratedBooks();
  }

  Future<void> _loadCuratedBooks() async {
    try {
      // Get user's preferences
      final hardStopsService = Provider.of<HardStopsService>(
        context,
        listen: false,
      );
      final kinkFilterService = Provider.of<KinkFilterService>(
        context,
        listen: false,
      );

      final stopsData = await hardStopsService.getHardStopsOnce();
      final kinksData = await kinkFilterService.getKinkFilterOnce();

      final userStops = stopsData['hardStops'] ?? <String>[];
      final userKinks = kinksData['kinkFilter'] ?? <String>[];

      // Fetch a curated selection of books (limit 15)
      final booksSnapshot = await FirebaseFirestore.instance
          .collection('books')
          .where('isPreSeeded', isEqualTo: true)
          .limit(15)
          .get();

      final books = booksSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Unknown Title',
          'authors': List<String>.from(data['authors'] ?? ['Unknown Author']),
          'imageUrl': data['imageUrl'],
          'description': data['description'],
          'genres': List<String>.from(data['genres'] ?? []),
          'cachedTropes': List<String>.from(data['cachedTropes'] ?? []),
          'cachedTopWarnings': List<String>.from(
            data['cachedTopWarnings'] ?? [],
          ),
        };
      }).toList();

      // Simple filtering: remove books that have hard stops
      final filteredBooks = books.where((book) {
        final warnings = book['cachedTopWarnings'] as List<String>;
        return !warnings.any((w) => userStops.contains(w.toLowerCase()));
      }).toList();

      if (mounted) {
        setState(() {
          curatedBooks = filteredBooks;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading books: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Curated Library',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Books selected based on your preferences',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: curatedBooks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_books_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No curated books available yet',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can still browse and add books manually',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: curatedBooks.length,
                      itemBuilder: (context, index) {
                        final book = curatedBooks[index];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: book['imageUrl'] != null
                                    ? Image.network(
                                        book['imageUrl'],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: Colors.grey[200],
                                                  child: Icon(
                                                    Icons.book,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.book,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book['title'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (book['authors'] as List<String>).first,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'These books are filtered to match your hard stops and preferences. You can explore more books after setup!',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Semantics(
                  button: true,
                  enabled: true,
                  onTap: widget.onPrevious,
                  label: 'Go back to previous step',
                  child: OutlinedButton(
                    onPressed: widget.onPrevious,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(100, 56),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    button: true,
                    enabled: true,
                    onTap: widget.onNext,
                    label: 'Finish setup and enter the app',
                    child: ElevatedButton(
                      onPressed: widget.onNext,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: const Text('Enter App'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
