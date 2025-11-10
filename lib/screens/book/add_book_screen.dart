// lib/screens/book/add_book_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/book_model.dart';
import '../../models/user_book.dart';
import '../../services/google_books_service.dart';
import '../../services/user_library_service.dart';
import '../../services/pro_exceptions.dart';
import 'genre_selection_screen.dart';
import 'trope_selection_screen.dart';

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

  List<String> _selectedGenres = [];
  List<String> _selectedTropes = [];
  BookOwnership _selectedOwnership =
      BookOwnership.digital; // Default to digital

  List<RomanceBook> _searchResults = [];
  bool _searchPerformed = false;

  @override
  void dispose() {
    _searchController.dispose();
    _seriesNameController.dispose();
    _seriesIndexController.dispose();
    super.dispose();
  }

  Future<void> _selectGenres() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GenreSelectionScreen(initialGenres: _selectedGenres),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedGenres = result;
      });
    }
  }

  Future<void> _selectTropes() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TropeSelectionScreen(initialTropes: _selectedTropes),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTropes = result;
      });
    }
  }

  Future<void> _searchBooks() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'Please enter a search term');
      return;
    }

    setState(() {
      _isLoading = true;
      _searchPerformed = true;
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
      setState(() => _error = 'Search failed: $e');
    } finally {
      setState(() => _isLoading = false);
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
      final userBook = UserBook(
        id: '${user.uid}_${book.id}',
        bookId: book.id,
        userId: user.uid,
        title: book.title,
        authors: book.authors,
        imageUrl: book.imageUrl,
        description: book.description,
        status: ReadingStatus.wantToRead,
        genres: _selectedGenres,
        userSelectedTropes: _selectedTropes,
        ownership: _selectedOwnership,
        seriesName: _seriesNameController.text.trim().isNotEmpty
            ? _seriesNameController.text.trim()
            : null,
        seriesIndex: int.tryParse(_seriesIndexController.text.trim()),
      );

      await _userLibraryService.addBook(userBook);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${book.title}" to your library')),
      );
      context.pop();
    } on ProUpgradeRequiredException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'UPGRADE',
            onPressed: () => context.push('/pro-club'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add book: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
      appBar: AppBar(title: const Text('Add Book')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search for a book',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _searchBooks(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(56, 56),
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
              ListTile(
                title: const Text('Genres'),
                subtitle: _selectedGenres.isNotEmpty
                    ? Text(_selectedGenres.join(', '))
                    : const Text('Tap to select genres'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectGenres,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Tropes'),
                subtitle: _selectedTropes.isNotEmpty
                    ? Text(_selectedTropes.join(', '))
                    : const Text('Tap to select tropes (optional)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectTropes,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ownership Status',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: BookOwnership.values.map((ownership) {
                        final isSelected = _selectedOwnership == ownership;
                        return FilterChip(
                          label: Text(_ownershipLabel(ownership)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedOwnership = ownership;
                            });
                          },
                          avatar: isSelected
                              ? null
                              : CircleAvatar(
                                  backgroundColor: _ownershipColor(ownership),
                                  radius: 6,
                                ),
                          selectedColor: _ownershipColor(
                            ownership,
                          ).withValues(alpha: 0.3),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
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
              if (_searchPerformed) _buildSearchResults(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No results found.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return Card(
          child: ListTile(
            leading: book.imageUrl != null
                ? Image.network(
                    book.imageUrl!,
                    width: 48,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.book, size: 48),
            title: Text(
              book.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(book.authors.join(', ')),
            trailing: ElevatedButton(
              onPressed: _isLoading ? null : () => _addBookToLibrary(book),
              child: const Text('Add'),
            ),
          ),
        );
      },
    );
  }

  String _ownershipLabel(BookOwnership ownership) {
    switch (ownership) {
      case BookOwnership.none:
        return 'None';
      case BookOwnership.physical:
        return 'Physical';
      case BookOwnership.digital:
        return 'Digital';
      case BookOwnership.both:
        return 'Both';
      case BookOwnership.kindleUnlimited:
        return 'Kindle Unlimited';
    }
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
