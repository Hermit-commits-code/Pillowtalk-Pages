// lib/screens/library/library_screen.dart

import 'package:flutter/material.dart';

import '../../models/book_model.dart';
import '../../models/user_book.dart';
import '../../services/community_data_service.dart';
import '../../services/user_library_service.dart';
import '../book/book_detail_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserLibraryService userLibraryService = UserLibraryService();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('My Library', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: StreamBuilder<List<UserBook>>(
        stream: userLibraryService.getUserLibraryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: \\${snapshot.error}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            );
          }
          final books = snapshot.data ?? [];
          if (books.isEmpty) {
            return Center(
              child: Text(
                'Your library is empty.',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final userBook = books[index];
              return FutureBuilder<RomanceBook?>(
                future: CommunityDataService().getCommunityBookData(
                  userBook.bookId,
                ),
                builder: (context, snapshot) {
                  final romanceBook = snapshot.data;
                  return Card(
                    color: theme.cardTheme.color,
                    shape: theme.cardTheme.shape,
                    elevation: theme.cardTheme.elevation,
                    child: ListTile(
                      leading: romanceBook?.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                romanceBook!.imageUrl!,
                                width: 48,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.book,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                      title: Text(
                        romanceBook?.title ?? userBook.bookId,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Status: \\${userBook.status.name}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.secondary,
                      ),
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
          );
        },
      ),
    );
  }
}
