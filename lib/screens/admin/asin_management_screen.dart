// lib/screens/admin/asin_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_book.dart';
// user_library_service not required here; removed unused field

/// Admin screen for managing ASINs across all books in the developer's library
/// Only accessible to the developer account (hotcupofjoe2013@gmail.com)
class AsinManagementScreen extends StatefulWidget {
  const AsinManagementScreen({super.key});

  @override
  State<AsinManagementScreen> createState() => _AsinManagementScreenState();
}

class _AsinManagementScreenState extends State<AsinManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<UserBook> _allBooks = [];
  List<UserBook> _filteredBooks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showOnlyMissingASIN = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  /// Verify this is the developer account
  void _checkAdminAccess() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != 'hotcupofjoe2013@gmail.com') {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin access required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _loadBooks();
  }

  /// Load all books from the developer's library
  Future<void> _loadBooks() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('library')
          .get();

      final books = snapshot.docs
          .map((doc) => UserBook.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      books.sort((a, b) => a.title.compareTo(b.title));

      setState(() {
        _allBooks = books;
        _filteredBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading books: $e')));
    }
  }

  /// Filter books based on search query and ASIN status
  void _filterBooks() {
    setState(() {
      _filteredBooks = _allBooks.where((book) {
        // Search filter
        final matchesSearch =
            _searchQuery.isEmpty ||
            book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            book.authors.any(
              (author) =>
                  author.toLowerCase().contains(_searchQuery.toLowerCase()),
            );

        // ASIN filter
        final matchesASINFilter =
            !_showOnlyMissingASIN || (book.asin == null || book.asin!.isEmpty);

        return matchesSearch && matchesASINFilter;
      }).toList();
    });
  }

  /// Update ASIN for a specific book
  Future<void> _updateASIN(UserBook book, String asin) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('library')
          .doc(book.id)
          .update({'asin': asin.trim().isEmpty ? null : asin.trim()});

      // Update local state
      setState(() {
        final index = _allBooks.indexWhere((b) => b.id == book.id);
        if (index != -1) {
          _allBooks[index] = book.copyWith(
            asin: asin.trim().isEmpty ? null : asin.trim(),
          );
        }
      });

      _filterBooks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated ASIN for "${book.title}"')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating ASIN: $e')));
    }
  }

  /// Show dialog to edit ASIN
  Future<void> _showEditASINDialog(UserBook book) async {
    final controller = TextEditingController(text: book.asin ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ASIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              book.authors.join(', '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Amazon ASIN',
                hintText: 'e.g., B08XYZ1234',
                helperText: 'Amazon Standard Identification Number',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateASIN(book, controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('ASIN Management (${_filteredBooks.length} books)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBooks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search books',
                    hintText: 'Title or author...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _filterBooks();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _showOnlyMissingASIN,
                      onChanged: (value) {
                        setState(() => _showOnlyMissingASIN = value ?? false);
                        _filterBooks();
                      },
                    ),
                    const Text('Show only books without ASIN'),
                  ],
                ),
              ],
            ),
          ),

          // Books list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBooks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_books,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _showOnlyMissingASIN
                              ? 'No books match your filters'
                              : 'No books in library',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];
                      final hasASIN =
                          book.asin != null && book.asin!.isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: book.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    book.imageUrl!,
                                    width: 40,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) =>
                                        Container(
                                          width: 40,
                                          height: 60,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.book),
                                        ),
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.book),
                                ),
                          title: Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.authors.join(', '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    hasASIN
                                        ? Icons.check_circle
                                        : Icons.help_outline,
                                    size: 16,
                                    color: hasASIN
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hasASIN ? 'ASIN: ${book.asin}' : 'No ASIN',
                                    style: TextStyle(
                                      color: hasASIN
                                          ? Colors.green
                                          : Colors.orange,
                                      fontFamily: hasASIN ? 'monospace' : null,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditASINDialog(book),
                            tooltip: 'Edit ASIN',
                          ),
                          onTap: () => _showEditASINDialog(book),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Summary FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSummaryDialog,
        icon: const Icon(Icons.analytics),
        label: const Text('Summary'),
      ),
    );
  }

  /// Show ASIN summary statistics
  void _showSummaryDialog() {
    final totalBooks = _allBooks.length;
    final booksWithASIN = _allBooks
        .where((book) => book.asin != null && book.asin!.isNotEmpty)
        .length;
    final booksWithoutASIN = totalBooks - booksWithASIN;
    final percentageComplete = totalBooks > 0
        ? (booksWithASIN / totalBooks * 100).toStringAsFixed(1)
        : '0';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ASIN Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Books:', totalBooks.toString()),
            _buildStatRow('Books with ASIN:', booksWithASIN.toString()),
            _buildStatRow('Books without ASIN:', booksWithoutASIN.toString()),
            _buildStatRow('Completion:', '$percentageComplete%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
