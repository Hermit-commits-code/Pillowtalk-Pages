// lib/screens/book/book_detail_screen.dart
import 'package:flutter/material.dart';

class BookDetailScreen extends StatelessWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Details')),
      body: Center(child: Text('Book details for ID: $bookId')),
    );
  }
}
