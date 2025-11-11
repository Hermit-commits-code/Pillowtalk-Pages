import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_book.dart';
import '../../services/user_library_service.dart';
import '../book/genre_selection_screen.dart';
import '../book/trope_selection_screen.dart';

class DeepTropeSearchScreen extends StatefulWidget {
  const DeepTropeSearchScreen({super.key});

  @override
  State<DeepTropeSearchScreen> createState() => _DeepTropeSearchScreenState();
}

class _DeepTropeSearchScreenState extends State<DeepTropeSearchScreen> {
  List<UserBook> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<String> _selectedGenres = [];
  List<String> _selectedTropes = [];
  ReadingStatus? _selectedStatus;
  BookOwnership? _selectedOwnership;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await UserLibraryService().searchLibraryByFilters(
        genres: _selectedGenres,
        tropes: _selectedTropes,
        status: _selectedStatus,
        ownership: _selectedOwnership,
      );
      setState(() {
        _searchResults = results;
        if (_searchResults.isEmpty) {
          _error = 'No books found with those filters.';
        }
      });
    } catch (e) {
      setState(() => _error = 'Filter search failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickGenres() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => GenreSelectionScreen(initialGenres: _selectedGenres),
      ),
    );
    if (result != null) setState(() => _selectedGenres = result);
  }

  Future<void> _pickTropes() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => TropeSelectionScreen(initialTropes: _selectedTropes),
      ),
    );
    if (result != null) setState(() => _selectedTropes = result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Filters', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Genres'),
                  subtitle: _selectedGenres.isNotEmpty
                      ? Text(_selectedGenres.join(', '))
                      : const Text('Tap to select genres'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickGenres,
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Tropes'),
                  subtitle: _selectedTropes.isNotEmpty
                      ? Text(_selectedTropes.join(', '))
                      : const Text('Tap to select tropes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickTropes,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ReadingStatus?>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Reading status',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Any'),
                          ),
                          ...ReadingStatus.values.map(
                            (s) =>
                                DropdownMenuItem(value: s, child: Text(s.name)),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedStatus = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<BookOwnership?>(
                        initialValue: _selectedOwnership,
                        decoration: const InputDecoration(
                          labelText: 'Ownership',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Any'),
                          ),
                          ...BookOwnership.values.map(
                            (o) =>
                                DropdownMenuItem(value: o, child: Text(o.name)),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedOwnership = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _applyFilters,
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Apply Filters'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedGenres = [];
                          _selectedTropes = [];
                          _selectedStatus = null;
                          _selectedOwnership = null;
                          _searchResults = [];
                          _error = null;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator()
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            )
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final book = _searchResults[index];
                  final personalStars = book.personalStars;
                  final authors = book.authors.join(', ');
                  final subtitlePieces = <String>[];
                  if (authors.isNotEmpty) {
                    subtitlePieces.add(authors);
                  }
                  if (personalStars != null) {
                    subtitlePieces.add('★$personalStars');
                  }
                  final subtitleText = subtitlePieces.join(' • ');

                  return ListTile(
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
                    subtitle: Text(subtitleText),
                    trailing:
                        book.userNotes != null && book.userNotes!.isNotEmpty
                        ? const Icon(Icons.note, size: 18)
                        : null,
                    onTap: () {
                      context.push('/book/${book.bookId}');
                    },
                  );
                },
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text('Select filters and tap Apply to begin.'),
              ),
            ),
        ],
      ),
    );
  }
}
