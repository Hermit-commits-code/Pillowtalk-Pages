import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_book.dart';
import '../../services/user_library_service.dart';

class DeepTropeSearchScreen extends StatefulWidget {
  const DeepTropeSearchScreen({super.key});

  @override
  State<DeepTropeSearchScreen> createState() => _DeepTropeSearchScreenState();
}

class _DeepTropeSearchScreenState extends State<DeepTropeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserBook> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  List<String> _suggestions = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load top tropes from the current user's library for autocomplete
    UserLibraryService()
        .getTopTropesFromLibrary(limit: 100)
        .then((list) {
          setState(() => _suggestions = list);
        })
        .catchError((e) {
          // ignore errors - suggestions are optional
        });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await UserLibraryService().searchLibraryByTrope(query);
      setState(() {
        _searchResults = results;
        if (_searchResults.isEmpty) {
          _error = 'No books found matching that trope.';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Trope Search', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final input = textEditingValue.text.trim();
                if (input.isEmpty) return const Iterable<String>.empty();
                final lower = input.toLowerCase();
                return _suggestions.where(
                  (s) => s.toLowerCase().contains(lower),
                );
              },
              onSelected: (selection) {
                _searchController.text = selection;
                _performSearch();
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    controller.text = _searchController.text;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Enter a trope to search for',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _performSearch,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _performSearch(),
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 200,
                        maxWidth: 400,
                      ),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: options
                            .map(
                              (o) => ListTile(
                                title: Text(o),
                                onTap: () => onSelected(o),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                );
              },
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
              child: Center(child: Text('Enter a search term to begin.')),
            ),
        ],
      ),
    );
  }
}
