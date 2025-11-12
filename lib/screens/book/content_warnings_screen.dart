// lib/screens/book/content_warnings_screen.dart
import 'package:flutter/material.dart';
import '../../constants/content_warnings.dart';

class ContentWarningsScreen extends StatefulWidget {
  final List<String> initialWarnings;
  const ContentWarningsScreen({super.key, required this.initialWarnings});

  @override
  State<ContentWarningsScreen> createState() => _ContentWarningsScreenState();
}

class _ContentWarningsScreenState extends State<ContentWarningsScreen> {
  late Set<String> _selectedWarnings;
  final List<String> _customWarnings = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selectedWarnings = Set.from(widget.initialWarnings);
    // Separate custom warnings from standard ones
    for (var w in _selectedWarnings) {
      if (!commonContentWarnings.contains(w)) {
        _customWarnings.add(w);
      }
    }
  }

  void _toggleWarning(String warning) {
    setState(() {
      if (_selectedWarnings.contains(warning)) {
        _selectedWarnings.remove(warning);
      } else {
        _selectedWarnings.add(warning);
      }
    });
  }

  Future<void> _showAddCustomDialog() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add Custom Content Warning'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g., Custom warning'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(c, text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty) {
      setState(() {
        _customWarnings.add(value);
        _selectedWarnings.add(value);
      });
    }
  }

  void _removeCustomWarning(String warning) {
    setState(() {
      _customWarnings.remove(warning);
      _selectedWarnings.remove(warning);
    });
  }

  List<String> _getFilteredWarnings() {
    if (_search.isEmpty) {
      return commonContentWarnings;
    }
    return commonContentWarnings
        .where((w) => w.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredWarnings();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Content Warnings'), elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (val) => setState(() => _search = val),
                decoration: InputDecoration(
                  hintText: 'Search content warnings',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _search = ''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (filtered.isNotEmpty)
                    ...filtered.map(
                      (warning) => CheckboxListTile(
                        title: Text(warning),
                        value: _selectedWarnings.contains(warning),
                        onChanged: (val) => _toggleWarning(warning),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (_customWarnings.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Custom Warnings',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._customWarnings.map(
                      (warning) => ListTile(
                        title: Text(warning),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeCustomWarning(warning),
                        ),
                        selected: _selectedWarnings.contains(warning),
                        onTap: () => _toggleWarning(warning),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddCustomDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Custom Warning'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, _selectedWarnings.toList());
        },
        tooltip: 'Save Selection',
        child: const Icon(Icons.check),
      ),
    );
  }
}
