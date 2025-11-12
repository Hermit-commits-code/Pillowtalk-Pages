// lib/widgets/content_warnings_dropdown_tile.dart
import 'package:flutter/material.dart';
import '../screens/book/content_warnings_screen.dart';

class ContentWarningsDropdownTile extends StatelessWidget {
  final List<String> selectedWarnings;
  final ValueChanged<List<String>> onChanged;
  final String title;
  final String placeholder;

  const ContentWarningsDropdownTile({
    super.key,
    required this.selectedWarnings,
    required this.onChanged,
    this.title = 'Content Warnings',
    this.placeholder = 'Tap to select content warnings',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(title),
      subtitle: selectedWarnings.isNotEmpty
          ? Text(selectedWarnings.join(', '))
          : Text(placeholder),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final result = await Navigator.push<List<String>>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ContentWarningsScreen(initialWarnings: selectedWarnings),
          ),
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
