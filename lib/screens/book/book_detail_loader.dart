import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'book_detail_screen.dart';

/// Loads a book document from Firestore and shows [BookDetailScreen].
class BookDetailLoader extends StatelessWidget {
  final String bookId;

  const BookDetailLoader({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('books').doc(bookId).get(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Book')),
            body: Center(child: Text('Failed to load book: ${snap.error}')),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Book')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final doc = snap.data;
        if (doc == null || !doc.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Book')),
            body: const Center(child: Text('Book not found.')),
          );
        }

        final data = doc.data() as Map<String, dynamic>;

        final title = data['title'] as String? ?? 'Unknown Title';
        final authors =
            (data['authors'] as List<dynamic>?)?.cast<String>() ?? [];
        final imageUrl = data['imageUrl'] as String?;
        final description = data['description'] as String?;
        final genres = (data['genres'] as List<dynamic>?)?.cast<String>();
        final seriesName = data['seriesName'] as String?;
        final seriesIndex = data['seriesIndex'] as int?;
        final pageCount = data['pageCount'] as int?;
        final publishedDate = data['publishedDate'] != null
            ? DateTime.tryParse(data['publishedDate'] as String)
            : null;
        final publisher = data['publisher'] as String?;

        return BookDetailScreen(
          title: title,
          author: authors.join(', '),
          coverUrl: imageUrl,
          description: description,
          genres: genres,
          seriesName: seriesName,
          seriesIndex: seriesIndex,
          bookId: bookId,
          pageCount: pageCount,
          publishedDate: publishedDate,
          publisher: publisher,
        );
      },
    );
  }
}
