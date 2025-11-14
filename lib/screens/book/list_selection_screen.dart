import 'package:flutter/material.dart';

import '../../models/user_list.dart';
import '../../services/lists_service.dart';

class ListSelectionScreen extends StatefulWidget {
  final List<String> initialSelectedListIds;

  const ListSelectionScreen({
    super.key,
    this.initialSelectedListIds = const [],
  });

  @override
  State<ListSelectionScreen> createState() => _ListSelectionScreenState();
}

class _ListSelectionScreenState extends State<ListSelectionScreen> {
  final ListsService _listsService = ListsService();
  late List<String> _selectedIds = [];

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedListIds);
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _createList() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final res = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Create new list'),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (res == true && nameController.text.trim().isNotEmpty) {
      final list = await _listsService.createList(
        name: nameController.text.trim(),
        description: descController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _selectedIds.add(list.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Lists'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedIds),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<List<UserList>>(
        stream: _listsService.getUserListsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lists = snapshot.data ?? [];
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final l = lists[index];
                    final selected = _selectedIds.contains(l.id);
                    return CheckboxListTile(
                      title: Text(l.name),
                      subtitle: l.description != null
                          ? Text(l.description!)
                          : null,
                      value: selected,
                      onChanged: (_) => _toggle(l.id),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _createList,
                        child: const Text('Create new list'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
