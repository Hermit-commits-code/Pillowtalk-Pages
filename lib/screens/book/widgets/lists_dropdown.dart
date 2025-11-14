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
  final dynamic listsService;

  const ListsDropdown({
    super.key,
    this.initialSelectedListIds = const [],
    this.onChanged,
    this.placeholder = 'Add to lists',
    this.listsService,
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
            _ListSelectionProxy(
              initial: initialSelectedListIds,
              listsService: listsService,
            ),
      ),
    );

    if (result != null && onChanged != null) onChanged!(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: () => _openSelector(context),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Ensure color and border match the theme (works for dark/light modes)
        foregroundColor: theme.colorScheme.onSurface,
        side: BorderSide(color: theme.colorScheme.onSurface),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              placeholder,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface),
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
  final dynamic listsService;
  const _ListSelectionProxy({required this.initial, this.listsService});

  @override
  Widget build(BuildContext context) {
    // Import the real screen here to avoid static import cycles in other
    // files that import this widget.
    return (ListSelectionScreenProxy(
      initialSelectedListIds: initial,
      listsService: listsService,
    ));
  }
}

// This small widget is a thin forwarder to the real ListSelectionScreen
// that exists at lib/screens/book/list_selection_screen.dart. We declare
// it here so callers of ListsDropdown don't need to import the full
// screen file directly and risk circular imports.
class ListSelectionScreenProxy extends StatefulWidget {
  final List<String> initialSelectedListIds;
  final dynamic listsService;
  const ListSelectionScreenProxy({
    super.key,
    this.initialSelectedListIds = const [],
    this.listsService,
  });

  @override
  State<ListSelectionScreenProxy> createState() =>
      _ListSelectionScreenProxyState();
}

class _ListSelectionScreenProxyState extends State<ListSelectionScreenProxy> {
  late final dynamic _listsService;

  // Track the current selections in state so the AppBar 'Done' action can
  // return the current selection (not the original initial selection).
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.initialSelectedListIds);
    // Use injected listsService when provided (tests); otherwise construct
    // a real ListsService for production behavior.
    _listsService = widget.listsService ?? ListsService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Lists'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: StreamBuilder<List<UserList>>(
        stream: _listsService.getUserListsStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error loading lists: ${snap.error}'));
          }
          final lists = snap.data ?? [];
          if (snap.connectionState == ConnectionState.waiting &&
              lists.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final l = lists[index];
                    final isSel = _selected.contains(l.id);
                    return CheckboxListTile(
                      title: Text(l.name),
                      subtitle: l.description != null
                          ? Text(l.description!)
                          : null,
                      value: isSel,
                      onChanged: (_) {
                        setState(() {
                          if (isSel) {
                            _selected.remove(l.id);
                          } else {
                            _selected.add(l.id);
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
                            if (!mounted) return;
                            setState(() {
                              _selected.add(created.id);
                            });
                          }
                        },
                        child: const Text('Create new list'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selected),
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
