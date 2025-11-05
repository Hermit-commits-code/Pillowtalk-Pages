import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/book_model.dart';

class DeepTropeSearchScreen extends StatefulWidget {
  const DeepTropeSearchScreen({super.key});

  @override
  State<DeepTropeSearchScreen> createState() => _DeepTropeSearchScreenState();
}

class _DeepTropeSearchScreenState extends State<DeepTropeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<RomanceBook> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      // This method needs to be implemented in CommunityDataService
      // final results = await CommunityDataService().searchBooksByTrope(query);
      // setState(() {
      //   _searchResults = results;
      //   if (_searchResults.isEmpty) {
      //     _error = 'No books found matching that trope.';
      //   }
      // });
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
            child: TextField(
              controller: _searchController,
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
                  return ListTile(
                    leading: book.imageUrl != null
                        ? Image.network(book.imageUrl!, width: 48, height: 72, fit: BoxFit.cover)
                        : const Icon(Icons.book, size: 48),
                    title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(book.authors.join(', ')),
                    onTap: () {
                      context.push('/book/${book.id}');
                    },
                  );
                },
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text('Enter a search term to begin.'),
              ),
            ),
        ],
      ),
    );
  }
}
