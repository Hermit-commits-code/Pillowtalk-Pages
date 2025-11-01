// lib/screens/book/add_book_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      final userBook = UserBook(
        id: book.id,
        userId: user.uid,
        bookId: book.id,
        status: ReadingStatus.wantToRead,
        dateAdded: DateTime.now(),
        userSelectedTropes: const [],
        userContentWarnings: const [],
      );
      await _userLibraryService.addBook(userBook);
      setState(() {
        _success = 'Book added to your library!';
      });
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
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Search for a book',
                      labelStyle: theme.textTheme.bodyMedium,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchBooks(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchBooks,
                  child: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
    super.dispose();
  }
}
