// lib/screens/librarian/librarian_asin_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_book.dart';

/// A lightweight ASIN verification list for librarians.
/// This attempts to read from a top-level `books` collection first; if that
/// collection is unavailable or permission-denied, a helpful message is shown.
class LibrarianAsinScreen extends StatefulWidget {
  const LibrarianAsinScreen({super.key});

  @override
  State<LibrarianAsinScreen> createState() => _LibrarianAsinScreenState();
}

class _LibrarianAsinScreenState extends State<LibrarianAsinScreen> {
  bool _isLoading = true;
  String? _error;
  List<UserBook> _books = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _books = [];
    });

    try {
      // Try a top-level `books` collection (app-global catalog) first
      final snapshot = await FirebaseFirestore.instance
          .collection('books')
          .limit(100)
          .get();
      final docs = snapshot.docs;
      _books = docs
          .map((d) => UserBook.fromMap({...d.data(), 'id': d.id}))
          .toList();
      setState(() => _isLoading = false);
    } on FirebaseException catch (fe) {
      if (fe.code == 'permission-denied') {
        setState(() {
          _error =
              'Permission denied when loading global books. Librarian tools may require server-side privileges or Cloud Functions.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load books: ${fe.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load books: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Librarian — ASIN Verification')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Failed to load catalog',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'If you see a permission error, consider running these actions from a secure admin console or a Cloud Function with admin privileges.',
                  ),
                ],
              )
            : _books.isEmpty
            ? const Center(child: Text('No books found'))
            : ListView.builder(
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  final book = _books[index];
                  final hasASIN = book.asin != null && book.asin!.isNotEmpty;
                  return Card(
                    child: ListTile(
                      title: Text(book.title),
                      subtitle: Text(book.authors.join(', ')),
                      trailing: Text(
                        hasASIN ? 'ASIN: ${book.asin}' : 'No ASIN',
                        style: TextStyle(
                          color: hasASIN ? Colors.green : Colors.orange,
                        ),
                      ),
                      onTap: hasASIN
                          ? null
                          : () {
                              // Navigate to book detail screen to allow adding ASIN
                              context.push(
                                '/book/${book.bookId}',
                                extra: {'userBook': book},
                              );
                            },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
