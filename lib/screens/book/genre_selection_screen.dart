// lib/screens/book/genre_selection_screen.dart
import 'package:flutter/material.dart';

import '../../constants/genres.dart';

class GenreSelectionScreen extends StatefulWidget {
  final List<String> initialGenres;
  const GenreSelectionScreen({super.key, required this.initialGenres});

  @override
  State<GenreSelectionScreen> createState() => _GenreSelectionScreenState();
}

class _GenreSelectionScreenState extends State<GenreSelectionScreen> {
  late Set<String> _selectedGenres;
  final List<String> _customGenres = [];

  @override
  void initState() {
    super.initState();
    _selectedGenres = Set.from(widget.initialGenres);
    // Separate custom genres from predefined ones
    for (var genre in _selectedGenres) {
      if (!romanceGenres.contains(genre) && !romanceSubgenres.values.any((list) => list.contains(genre))) {
        _customGenres.add(genre);
      }
    }
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  Future<void> _showAddCustomGenreDialog() async {
    final TextEditingController controller = TextEditingController();
    final newGenre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Genre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g., Sci-Fi Romance'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newGenre != null) {
      setState(() {
        if (!_customGenres.contains(newGenre)) {
          _customGenres.add(newGenre);
        }
        _selectedGenres.add(newGenre);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine predefined and custom genres for display
    final allDisplayGenres = <dynamic>{...romanceGenres, ..._customGenres}.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Genres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () {
              Navigator.of(context).pop(_selectedGenres.toList());
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: allDisplayGenres.length + 1,
        itemBuilder: (context, index) {
          if (index == allDisplayGenres.length) {
            // This is the "Add Custom" button
            return ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add a custom genre...'),
              onTap: _showAddCustomGenreDialog,
            );
          }

          final genre = allDisplayGenres[index];
          final subgenres = romanceSubgenres[genre] ?? [];
          final isCustom = !_customGenres.contains(genre) && subgenres.isEmpty;

          if (isCustom || subgenres.isEmpty) {
             return CheckboxListTile(
                title: Text(genre),
                value: _selectedGenres.contains(genre),
                onChanged: (bool? selected) {
                  _toggleGenre(genre);
                },
              );
          }
          
          return ExpansionTile(
            title: Text(genre),
            initiallyExpanded: _selectedGenres.any((g) => subgenres.contains(g) || g == genre),
            children: <Widget>[
              CheckboxListTile(
                title: Text('All $genre'),
                value: _selectedGenres.contains(genre),
                onChanged: (bool? selected) {
                  _toggleGenre(genre);
                },
              ),
              ...subgenres.map((sub) {
                return CheckboxListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(sub),
                  ),
                  value: _selectedGenres.contains(sub),
                  onChanged: (bool? selected) {
                    _toggleGenre(sub);
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
