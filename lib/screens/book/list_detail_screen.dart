import 'package:flutter/material.dart';

import '../../models/user_list.dart';
import '../../services/lists_service.dart';
import '../../services/user_library_service.dart';
import '../../models/user_book.dart';

class ListDetailScreen extends StatefulWidget {
  final UserList userList;

  const ListDetailScreen({super.key, required this.userList});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final ListsService _listsService = ListsService();
  final UserLibraryService _libraryService = UserLibraryService();

  Future<List<UserBook>> _fetchBooks() async {
    final ids = widget.userList.bookIds;
    final results = <UserBook>[];
    for (final id in ids) {
      try {
        final ub = await _libraryService.getUserBook(id);
        if (ub != null) {
          results.add(ub);
        }
      } catch (_) {
        // ignore individual failures
      }
    }
    return results;
  }

  Future<void> _remove(UserBook book) async {
    await _listsService.removeBookFromList(widget.userList.id, book.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.userList.name)),
      body: FutureBuilder<List<UserBook>>(
        future: _fetchBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final books = snapshot.data ?? [];
          if (books.isEmpty) {
            return const Center(child: Text('No books in this list'));
          }
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final b = books[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: b.imageUrl != null
                      ? Image.network(b.imageUrl!, width: 40, fit: BoxFit.cover)
                      : const Icon(Icons.book),
                  title: Text(b.title),
                  subtitle: Text(b.authors.join(', ')),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                    ),
                    onPressed: () => _remove(b),
                    tooltip: 'Remove from list',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
