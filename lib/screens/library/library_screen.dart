// lib/screens/library/library_screen.dart

import 'package:flutter/material.dart';

import '../../models/user_book.dart';
import '../../services/user_library_service.dart';
import '../book/book_detail_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserLibraryService userLibraryService = UserLibraryService();
    return Scaffold(
      appBar: AppBar(title: const Text('My Library')),
      body: StreamBuilder<List<UserBook>>(
        stream: userLibraryService.getUserLibraryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final books = snapshot.data ?? [];
          if (books.isEmpty) {
            return const Center(child: Text('Your library is empty.'));
          }
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final userBook = books[index];
              return Card(
                child: ListTile(
                  title: Text('Book ID: \\${userBook.bookId}'),
                  subtitle: Text('Status: \\${userBook.status.name}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BookDetailScreen(bookId: userBook.bookId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
