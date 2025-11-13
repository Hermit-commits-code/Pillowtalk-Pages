// lib/screens/onboarding/curated_library.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CuratedLibrary extends StatefulWidget {
  final List<String> hardStops;
  final List<String> kinkFilters;
  final List<String> favorites;

  const CuratedLibrary({
    super.key,
    required this.hardStops,
    required this.kinkFilters,
    required this.favorites,
  });

  @override
  State<CuratedLibrary> createState() => _CuratedLibraryState();
}

class _CuratedLibraryState extends State<CuratedLibrary> {
  bool _loading = true;
  List<Map<String, dynamic>> _books = [];

  @override
  void initState() {
    super.initState();
    _loadCuratedBooks();
  }

  Future<void> _loadCuratedBooks() async {
    setState(() => _loading = true);
    try {
      // Simple matching: fetch books that have any of the favorite tropes.
      // If no favorites provided, fall back to recently added books.
      Query collection = FirebaseFirestore.instance.collection('books');
      if (widget.favorites.isNotEmpty) {
        final vals = widget.favorites.take(10).toList();
        collection = collection.where('cachedTropes', arrayContainsAny: vals);
      } else {
        collection = collection.orderBy('publishedDate', descending: true);
      }

      final snapshot = await collection.limit(50).get();

      final results = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = (doc.data() as Map<String, dynamic>?) ?? {};
        // Client-side filtering: exclude books with warnings matching hardStops
        final cachedWarnings = List<String>.from(
          data['cachedTopWarnings'] ?? [],
        );
        final cachedTropes = List<String>.from(data['cachedTropes'] ?? []);

        final hasHardStop = widget.hardStops.any(
          (hs) => cachedWarnings.any(
            (w) => w.toLowerCase().contains(hs.toLowerCase()),
          ),
        );
        final hasKink = widget.kinkFilters.any(
          (k) => cachedTropes.any(
            (t) => t.toLowerCase().contains(k.toLowerCase()),
          ),
        );

        if (hasHardStop || hasKink) continue;

        final item = Map<String, dynamic>.from(data);
        item['id'] = doc.id;
        results.add(item);
      }

      setState(() {
        _books = results;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Curated Library')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
          ? const Center(child: Text('No curated books found'))
          : ListView.builder(
              itemCount: _books.length,
              itemBuilder: (context, index) {
                final b = _books[index];
                return ListTile(
                  leading: b['imageUrl'] != null
                      ? Image.network(
                          b['imageUrl'],
                          width: 40,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox(width: 40, height: 56),
                  title: Text(b['title'] ?? 'Untitled'),
                  subtitle: Text((b['authors'] as List?)?.join(', ') ?? ''),
                );
              },
            ),
    );
  }
}
