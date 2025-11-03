// lib/screens/book/add_book_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/genres.dart';
import '../../models/book_model.dart';
import '../../models/user_book.dart';
import '../../services/google_books_service.dart';
import '../../services/user_library_service.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _seriesNameController = TextEditingController();
  final TextEditingController _seriesIndexController = TextEditingController();

  final GoogleBooksService _googleBooksService = GoogleBooksService();
  final UserLibraryService _userLibraryService = UserLibraryService();

  bool _isLoading = false;
  String? _error;

  String? _selectedGenre;
  List<String> _selectedSubgenres = [];

  List<RomanceBook> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    _seriesNameController.dispose();
    _seriesIndexController.dispose();
    super.dispose();
  }

  Future<void> _searchBooks() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _error = 'Please enter a search term';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults = [];
    });

    try {
      final results = await _googleBooksService.searchBooks(query);
      setState(() {
        _searchResults = results;
        if (results.isEmpty) {
          _error = 'No books found. Try a different search term.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addBookToLibrary(RomanceBook book) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add books')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Build UserBook from the search result
      final seriesName = _seriesNameController.text.trim();
      final seriesIndexText = _seriesIndexController.text.trim();
      final seriesIndex = seriesIndexText.isNotEmpty
          ? int.tryParse(seriesIndexText)
          : null;

      final userBook = UserBook(
        id: '${user.uid}_${book.id}',
        bookId: book.id,
        userId: user.uid,
        status: ReadingStatus.wantToRead,
        dateAdded: DateTime.now(),
        seriesName: seriesName.isNotEmpty ? seriesName : null,
        seriesIndex: seriesIndex,
        // Cache community fields if available
        cachedTopWarnings: book.topWarnings,
        cachedTropes: book.communityTropes,
        genre: book.genre,
        subgenres: book.subgenres,
      );

      await _userLibraryService.addBook(userBook);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${book.title}" to your library')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to add book: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add book: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Book', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: 'Search for a book',
                                labelStyle: theme.textTheme.bodyMedium,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onSubmitted: (_) => _searchBooks(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 56, // Match default TextField height
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(
                                  56,
                                  56,
                                ), // Make button square
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isLoading ? null : _searchBooks,
                              child: const Icon(Icons.search, size: 28),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGenre,
                        items: romanceGenres
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedGenre = val;
                            _selectedSubgenres = [];
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Genre',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedGenre != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subgenres',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Wrap(
                              spacing: 6,
                              children: [
                                ...?romanceSubgenres[_selectedGenre!]?.map(
                                  (sub) => FilterChip(
                                    label: Text(sub),
                                    selected: _selectedSubgenres.contains(sub),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedSubgenres.add(sub);
                                        } else {
                                          _selectedSubgenres.remove(sub);
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      if (_isLoading) const LinearProgressIndicator(),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _seriesNameController,
                        decoration: const InputDecoration(
                          labelText: 'Series (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _seriesIndexController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Book number in series (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _searchResults.isEmpty
                            ? Center(
                                child: Text(
                                  'No results',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final book = _searchResults[index];
                                  return Card(
                                    color: theme.cardTheme.color,
                                    shape: theme.cardTheme.shape,
                                    elevation: theme.cardTheme.elevation,
                                    child: ListTile(
                                      leading: book.imageUrl != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Image.network(
                                                book.imageUrl!,
                                                width: 48,
                                                height: 72,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Icon(
                                              Icons.book,
                                              size: 48,
                                              color: theme.colorScheme.primary,
                                            ),
                                      title: Text(
                                        book.title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      subtitle: Text(
                                        book.authors.join(', '),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      trailing: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () => _addBookToLibrary(book),
                                        child: const Text('Add'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
