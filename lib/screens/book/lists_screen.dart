import 'package:flutter/material.dart';

import '../../models/user_list.dart';
import '../../services/lists_service.dart';
import 'list_detail_screen.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final ListsService _listsService = ListsService();

  Future<void> _createOrEdit({UserList? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descController = TextEditingController(
      text: existing?.description ?? '',
    );
    var isPrivate = existing?.isPrivate ?? true;

    final res = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(existing == null ? 'Create list' : 'Edit list'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            Row(
              children: [
                const Text('Private'),
                const Spacer(),
                Switch(value: isPrivate, onChanged: (v) => isPrivate = v),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (res != true) return;
    final name = nameController.text.trim();
    final desc = descController.text.trim();
    if (name.isEmpty) return;

    if (existing == null) {
      await _listsService.createList(
        name: name,
        description: desc,
        isPrivate: isPrivate,
      );
    } else {
      final updated = existing.copyWith(
        name: name,
        description: desc,
        isPrivate: isPrivate,
      );
      await _listsService.updateList(updated);
    }
  }

  Future<void> _deleteList(UserList list) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete list'),
        content: Text('Delete "${list.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await _listsService.deleteList(list.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lists')),
      body: StreamBuilder<List<UserList>>(
        stream: _listsService.getUserListsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lists = snapshot.data ?? [];
          if (lists.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No lists yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _createOrEdit(),
                      child: const Text('Create your first list'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final l = lists[index];
              return ListTile(
                title: Text(l.name),
                subtitle: Text(
                  '${l.bookIds.length} book${l.bookIds.length == 1 ? '' : 's'}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') await _createOrEdit(existing: l);
                    if (v == 'delete') await _deleteList(l);
                  },
                  itemBuilder: (c) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListDetailScreen(userList: l),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrEdit(),
        tooltip: 'Create list',
        child: const Icon(Icons.add),
      ),
    );
  }
}
