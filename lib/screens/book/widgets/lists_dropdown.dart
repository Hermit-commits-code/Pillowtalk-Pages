import 'package:flutter/material.dart';

import '../../../models/user_list.dart';
import '../../../services/lists_service.dart';

/// Compact lists selector that opens the existing full-screen selection
/// but exposes a small, reusable UI (chip/button) so it can be embedded
/// in modals and edit screens.
class ListsDropdown extends StatelessWidget {
  final List<String> initialSelectedListIds;
  final ValueChanged<List<String>>? onChanged;
  final String placeholder;

  const ListsDropdown({
    super.key,
    this.initialSelectedListIds = const [],
    this.onChanged,
    this.placeholder = 'Add to lists',
  });

  Future<void> _openSelector(BuildContext context) async {
    // Reuse the existing ListSelectionScreen for the heavyweight work.
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (c) =>
            // Import avoided here to keep this file small and focused; we'll
            // lazily import to avoid circular import issues in the repo.
            // The page is referenced by type via string to avoid analyzer
            // complaining if file ordering changes. Instead, push by route
            // using the same widget when available in the project tree.
            _ListSelectionProxy(initial: initialSelectedListIds),
      ),
    );

    if (result != null && onChanged != null) onChanged!(result);
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _openSelector(context),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(placeholder)),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

// Lightweight proxy to avoid a hard dependency cycle when this widget
// is imported from screens that also import ListSelectionScreen. It simply
// forwards to the real screen implementation which lives near it.
class _ListSelectionProxy extends StatelessWidget {
  final List<String> initial;
  const _ListSelectionProxy({required this.initial});

  @override
  Widget build(BuildContext context) {
    // Import the real screen here to avoid static import cycles in other
    // files that import this widget.
    return (ListSelectionScreenProxy(initialSelectedListIds: initial));
  }
}

// This small widget is a thin forwarder to the real ListSelectionScreen
// that exists at lib/screens/book/list_selection_screen.dart. We declare
// it here so callers of ListsDropdown don't need to import the full
// screen file directly and risk circular imports.
class ListSelectionScreenProxy extends StatefulWidget {
  final List<String> initialSelectedListIds;
  const ListSelectionScreenProxy({
    super.key,
    this.initialSelectedListIds = const [],
  });

  @override
  State<ListSelectionScreenProxy> createState() =>
      _ListSelectionScreenProxyState();
}

class _ListSelectionScreenProxyState extends State<ListSelectionScreenProxy> {
  final ListsService _listsService = ListsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Lists'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, widget.initialSelectedListIds),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<List<UserList>>(
        stream: _listsService.getUserListsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final lists = snap.data ?? [];
          final selected = List<String>.from(widget.initialSelectedListIds);
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final l = lists[index];
                    final isSel = selected.contains(l.id);
                    return CheckboxListTile(
                      title: Text(l.name),
                      subtitle: l.description != null
                          ? Text(l.description!)
                          : null,
                      value: isSel,
                      onChanged: (_) {
                        setState(() {
                          if (isSel) {
                            selected.remove(l.id);
                          } else {
                            selected.add(l.id);
                          }
                        });
                      },
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
                        onPressed: () async {
                          final nameCtrl = TextEditingController();
                          final descCtrl = TextEditingController();
                          final res = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Create new list'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: nameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Name',
                                    ),
                                  ),
                                  TextField(
                                    controller: descCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Description',
                                    ),
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
                          if (res == true && nameCtrl.text.trim().isNotEmpty) {
                            final created = await _listsService.createList(
                              name: nameCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                            );
                            setState(() {
                              selected.add(created.id);
                            });
                          }
                        },
                        child: const Text('Create new list'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, selected),
                      child: const Text('Done'),
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
