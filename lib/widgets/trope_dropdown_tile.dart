// lib/widgets/trope_dropdown_tile.dart
import 'package:flutter/material.dart';

import '../screens/book/trope_dropdown_screen.dart';

class TropeDropdownTile extends StatelessWidget {
  final List<String> selectedTropes;
  final ValueChanged<List<String>> onChanged;
  final String title;
  final String placeholder;

  const TropeDropdownTile({
    super.key,
    required this.selectedTropes,
    required this.onChanged,
    this.title = 'Tropes',
    this.placeholder = 'Tap to select tropes',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(title),
      subtitle: selectedTropes.isNotEmpty ? Text(selectedTropes.join(', ')) : Text(placeholder),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final result = await Navigator.push<List<String>>(
          context,
          MaterialPageRoute(builder: (context) => TropeDropdownScreen(initialTropes: selectedTropes)),
        );
        if (result != null) onChanged(result);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
    );
  }
}
