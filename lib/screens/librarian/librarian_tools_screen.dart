// lib/screens/librarian/librarian_tools_screen.dart
import 'package:flutter/material.dart';

import 'librarian_asin_screen.dart';

/// Simple librarian tools entry screen. Visible to users with `librarian` flag.
class LibrarianToolsScreen extends StatelessWidget {
  const LibrarianToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Librarian Tools')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Librarian Tools', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text(
              'These tools are intended for librarians. Proceed with caution.',
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('Verify ASINs'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LibrarianAsinScreen()),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Search books (placeholder)'),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Search is a placeholder for now'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
