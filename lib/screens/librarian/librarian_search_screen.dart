// lib/screens/librarian/librarian_search_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/user_book.dart';

/// Lightweight book search for librarians. Performs a prefix search by title
/// and falls back to a limited client-side filter when necessary.
class LibrarianSearchScreen extends StatefulWidget {
  const LibrarianSearchScreen({super.key});

  @override
  State<LibrarianSearchScreen> createState() => _LibrarianSearchScreenState();
}

class _LibrarianSearchScreenState extends State<LibrarianSearchScreen> {
  final TextEditingController _q = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<UserBook> _results = [];

  Future<void> _search() async {
    final query = _q.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _results = [];
    });

    try {
      final pattern = query.toLowerCase();

      // Try server-side prefix query on title (best-effort).
      final titleQ = FirebaseFirestore.instance
          .collection('books')
          .where('title_lower', isGreaterThanOrEqualTo: pattern)
          .where('title_lower', isLessThan: pattern + '\uf8ff')
          .limit(100);
      final snap = await titleQ.get();
      final docs = snap.docs;
      if (docs.isNotEmpty) {
        _results = docs
            .map((d) => UserBook.fromMap({...d.data(), 'id': d.id}))
            .toList();
        setState(() => _isLoading = false);
        return;
      }

      // If no results or index not present, fallback to a limited scan
      // and filter client-side (less efficient but more tolerant).
      final fallbackSnap = await FirebaseFirestore.instance
          .collection('books')
          .limit(200)
          .get();
      final all = fallbackSnap.docs
          .map((d) => UserBook.fromMap({...d.data(), 'id': d.id}))
          .toList();
      _results = all.where((b) {
        final title = b.title.toLowerCase();
        final authors = b.authors.join(', ').toLowerCase();
        return title.contains(pattern) || authors.contains(pattern);
      }).toList();
    } on FirebaseException catch (fe) {
      if (fe.code == 'permission-denied') {
        setState(
          () => _error =
              'Permission denied when searching books. Librarian searches may require server-side privileges or Cloud Functions.',
        );
      } else {
        setState(() => _error = 'Search failed: ${fe.message}');
      }
    } catch (e) {
      setState(() => _error = 'Search failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Librarian — Search Books')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _q,
                    decoration: const InputDecoration(
                      labelText: 'Search by title or author',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _search,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        'No results — try a different query or use Verify ASINs',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final b = _results[index];
                        final hasAsin = b.asin != null && b.asin!.isNotEmpty;
                        return ListTile(
                          title: Text(b.title),
                          subtitle: Text(b.authors.join(', ')),
                          trailing: Text(
                            hasAsin ? 'ASIN: ${b.asin}' : 'No ASIN',
                            style: TextStyle(
                              color: hasAsin ? Colors.green : Colors.orange,
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: Text(b.title),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Authors: ${b.authors.join(', ')}'),
                                    const SizedBox(height: 8),
                                    Text('ASIN: ${b.asin ?? 'None'}'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(c).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
