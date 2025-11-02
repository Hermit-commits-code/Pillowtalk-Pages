// lib/screens/book/add_book_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/genres.dart';
import '../../models/book_model.dart';
import '../../models/user_book.dart';
import '../../services/community_data_service.dart';
import '../../services/google_books_service.dart';
import '../../services/user_library_service.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  String? _selectedGenre;
  List<String> _selectedSubgenres = [];
  final TextEditingController _seriesNameController = TextEditingController();
  final TextEditingController _seriesIndexController = TextEditingController();
  final GoogleBooksService _googleBooksService = GoogleBooksService();
  final UserLibraryService _userLibraryService = UserLibraryService();
  final TextEditingController _searchController = TextEditingController();
  List<RomanceBook> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String? _success;

  Future<void> _searchBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    try {
      final results = await _googleBooksService.searchBooks(
        _searchController.text.trim(),
      );
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to search books: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addBookToLibrary(RomanceBook book) async {
    if (_selectedGenre == null || _selectedGenre!.isEmpty) {
      setState(() {
        _error = 'Please select a genre.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'You must be logged in to add books.';
        });
        return;
      }

      // Save book data to Firestore books collection for community access
      // Add genre/subgenres to book for community data
      final seriesName = _seriesNameController.text.trim().isNotEmpty
          ? _seriesNameController.text.trim()
          : null;
      final seriesIndex = int.tryParse(_seriesIndexController.text.trim());

      final bookWithGenre = book.copyWith(
        genre: _selectedGenre!,
        subgenres: _selectedSubgenres,
        seriesName: seriesName,
        seriesNameNormalized: seriesName?.toLowerCase().trim(),
        seriesIndex: seriesIndex,
      );
      await CommunityDataService().updateCommunityBookData(bookWithGenre);

      // Add book to user's library
      final userBook = UserBook(
        id: book.id,
        userId: user.uid,
        bookId: book.id,
        status: ReadingStatus.wantToRead,
        dateAdded: DateTime.now(),
        userSelectedTropes: const [],
        userContentWarnings: const [],
        genre: _selectedGenre!,
        subgenres: _selectedSubgenres,
        seriesName: seriesName,
        seriesNameNormalized: seriesName?.toLowerCase().trim(),
        seriesIndex: seriesIndex,
      );
      await _userLibraryService.addBook(userBook);
      setState(() {
        _success = 'Book added to your library!';
      });
    } on ProUpgradeRequiredException catch (e) {
      setState(() {
        _error = null;
        _success = null;
      });
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: Theme.of(context).cardTheme.shape,
          title: Text(
            'Upgrade to Pro',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            e.message,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Not Now',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Use GoRouter for navigation
                GoRouter.of(context).push('/pro-club');
              },
              child: const Text('Learn More'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to add book: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                      minimumSize: const Size(56, 56), // Make button square
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
            // Genre selection
            DropdownButtonFormField<String>(
              initialValue: _selectedGenre,
              items: romanceGenres
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
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
            // Subgenre selection (multi-select chips)
            if (_selectedGenre != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subgenres', style: theme.textTheme.bodyMedium),
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
            // Series inputs
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
            if (_success != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _success!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        'No results',
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                  : ListView.builder(
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
                                    borderRadius: BorderRadius.circular(6),
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
                              style: theme.textTheme.titleMedium?.copyWith(
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
                              child: Text(
                                'Add',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _seriesNameController.dispose();
    _seriesIndexController.dispose();
    super.dispose();
  }
}
