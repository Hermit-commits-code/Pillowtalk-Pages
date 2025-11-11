// lib/screens/book/trope_dropdown_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/tropes_categorized.dart';

class TropeDropdownScreen extends StatefulWidget {
  final List<String> initialTropes;
  const TropeDropdownScreen({super.key, required this.initialTropes});

  @override
  State<TropeDropdownScreen> createState() => _TropeDropdownScreenState();
}

class _TropeDropdownScreenState extends State<TropeDropdownScreen> {
  late Set<String> _selectedTropes;
  final List<String> _customTropes = [];
  bool _isPro = false;
  bool _isLoading = true;
  String? _activeCategory;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selectedTropes = Set.from(widget.initialTropes);
    for (var t in _selectedTropes) {
      if (!romanceTropesCategorized.contains(t)) _customTropes.add(t);
    }
    _checkProStatus();
    _activeCategory = tropeCategories.keys.isNotEmpty
        ? tropeCategories.keys.first
        : null;
  }

  Future<void> _checkProStatus() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted) {
          setState(() {
            _isPro = doc.data()?['isPro'] ?? false;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleTrope(String trope) {
    setState(() {
      if (_selectedTropes.contains(trope)) {
        _selectedTropes.remove(trope);
      } else {
        if (!_isPro && _selectedTropes.length >= 2) {
          _showProUpgradeMessage();
          return;
        }
        _selectedTropes.add(trope);
      }
    });
  }

  void _showProUpgradeMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Free users can select up to 2 tropes. Upgrade to Pro for unlimited selections!',
        ),
        action: SnackBarAction(
          label: 'Upgrade',
          onPressed: () => Navigator.of(context).pushNamed('/pro-club'),
        ),
      ),
    );
  }

  Future<void> _showAddCustomDialog() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add Custom Trope'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., Fish out of water',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(
              controller.text.trim().isEmpty ? null : controller.text.trim(),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (value != null) {
      setState(() {
        if (!_customTropes.contains(value)) _customTropes.add(value);
        if (!_isPro && _selectedTropes.length >= 2) {
          _showProUpgradeMessage();
        } else {
          _selectedTropes.add(value);
        }
      });
    }
  }

  List<String> _filteredForCategory(String? category) {
    final base = category == null
        ? <String>[]
        : (tropeCategories[category] ?? []);
    if (_search.trim().isEmpty) return base;
    final q = _search.toLowerCase();
    return base.where((t) => t.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Tropes')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final categories = tropeCategories.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Tropes ${_isPro ? '' : '(2 max)'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () =>
                Navigator.of(context).pop(_selectedTropes.toList()),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search tropes or categories',
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              Expanded(
                child: isNarrow
                    ? ListView(
                        children: [
                          ...categories.map((cat) {
                            final items = _filteredForCategory(cat);
                            if (items.isEmpty && _search.trim().isNotEmpty)
                              return const SizedBox.shrink();
                            return ExpansionTile(
                              title: Text(cat),
                              initiallyExpanded: cat == _activeCategory,
                              children: [
                                CheckboxListTile(
                                  title: Text('All $cat'),
                                  value:
                                      (tropeCategories[cat] ?? []).every(
                                        (i) => _selectedTropes.contains(i),
                                      ) &&
                                      (tropeCategories[cat] ?? []).isNotEmpty,
                                  onChanged: (sel) {
                                    setState(() {
                                      final items = tropeCategories[cat] ?? [];
                                      if (sel == true) {
                                        _selectedTropes.addAll(items);
                                      } else {
                                        for (final i in items)
                                          _selectedTropes.remove(i);
                                      }
                                    });
                                  },
                                ),
                                ...items
                                    .map(
                                      (t) => CheckboxListTile(
                                        title: Text(t),
                                        value: _selectedTropes.contains(t),
                                        onChanged: (_) => _toggleTrope(t),
                                      ),
                                    )
                                    .toList(),
                              ],
                            );
                          }).toList(),
                          ListTile(
                            leading: const Icon(Icons.add),
                            title: const Text('Add custom trope...'),
                            onTap: _showAddCustomDialog,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          // Left: categories
                          Container(
                            width: 220,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                            ),
                            child: ListView.builder(
                              itemCount: categories.length,
                              itemBuilder: (context, idx) {
                                final cat = categories[idx];
                                final selected = cat == _activeCategory;
                                return ListTile(
                                  selected: selected,
                                  title: Text(cat),
                                  onTap: () =>
                                      setState(() => _activeCategory = cat),
                                );
                              },
                            ),
                          ),
                          // Right: tropes for active category
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: _selectedTropes
                                        .map(
                                          (t) => Chip(
                                            label: Text(t),
                                            onDeleted: () => _toggleTrope(t),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: ListView(
                                      children: [
                                        CheckboxListTile(
                                          title: Text(
                                            'All ${_activeCategory ?? ''}',
                                          ),
                                          value:
                                              (tropeCategories[_activeCategory] ??
                                                      [])
                                                  .every(
                                                    (i) => _selectedTropes
                                                        .contains(i),
                                                  ) &&
                                              (tropeCategories[_activeCategory] ??
                                                      [])
                                                  .isNotEmpty,
                                          onChanged: (sel) {
                                            setState(() {
                                              final items =
                                                  tropeCategories[_activeCategory] ??
                                                  [];
                                              if (sel == true) {
                                                _selectedTropes.addAll(items);
                                              } else {
                                                for (final i in items)
                                                  _selectedTropes.remove(i);
                                              }
                                            });
                                          },
                                        ),
                                        ..._filteredForCategory(_activeCategory)
                                            .map(
                                              (t) => CheckboxListTile(
                                                title: Text(t),
                                                value: _selectedTropes.contains(
                                                  t,
                                                ),
                                                onChanged: (_) =>
                                                    _toggleTrope(t),
                                              ),
                                            )
                                            .toList(),
                                        const SizedBox(height: 8),
                                        ListTile(
                                          leading: const Icon(Icons.add),
                                          title: const Text(
                                            'Add custom trope...',
                                          ),
                                          onTap: _showAddCustomDialog,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
