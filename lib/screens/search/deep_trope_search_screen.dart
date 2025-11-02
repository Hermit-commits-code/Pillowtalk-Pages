// lib/screens/search/deep_trope_search_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/book_model.dart';
import '../../services/community_data_service.dart';
import '../book/book_detail_screen.dart';

class DeepTropeSearchScreen extends StatefulWidget {
  const DeepTropeSearchScreen({super.key});

  @override
  State<DeepTropeSearchScreen> createState() => _DeepTropeSearchScreenState();
}

class _DeepTropeSearchScreenState extends State<DeepTropeSearchScreen> {
  final _controller = TextEditingController();
  final _service = CommunityDataService();
  Timer? _debounce;
  bool _loading = false;
  List<RomanceBook> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      final res = await _service.searchBooksBySeriesPrefix(trimmed);
      setState(() {
        _results = res;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Series search failed: $e');
      setState(() {
        _results = [];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group results by seriesName
    final Map<String, List<RomanceBook>> grouped = {};
    for (final b in _results) {
      final name = (b.seriesName ?? '').trim();
      if (name.isEmpty) continue;
      grouped.putIfAbsent(name, () => []).add(b);
    }

    final seriesNames = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Deep Trope Search',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Search series by name',
                hintText: 'Type a series name prefix',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: _onQueryChanged,
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _loading ? 'Searching...' : 'No series found',
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                  : ListView.builder(
                      itemCount: seriesNames.length,
                      itemBuilder: (context, i) {
                        final name = seriesNames[i];
                        final vols = grouped[name]!;
                        vols.sort((a, b) {
                          final ai = a.seriesIndex ?? 0;
                          final bi = b.seriesIndex ?? 0;
                          return ai.compareTo(bi);
                        });
                        return ExpansionTile(
                          title: Text(name),
                          subtitle: Text('${vols.length} volume(s)'),
                          children: [
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                itemCount: vols.length,
                                itemBuilder: (context, j) {
                                  final vol = vols[j];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BookDetailScreen(
                                                title: vol.title,
                                                author: vol.authors.isNotEmpty
                                                    ? vol.authors.join(', ')
                                                    : 'Unknown',
                                                coverUrl: vol.imageUrl,
                                                description: vol.description,
                                                genre: vol.genre,
                                                subgenres: vol.subgenres,
                                                seriesName: vol.seriesName,
                                                seriesIndex: vol.seriesIndex,
                                                communityTropes:
                                                    vol.communityTropes,
                                                availableTropes:
                                                    vol.communityTropes,
                                                availableWarnings:
                                                    vol.topWarnings,
                                                spiceLevel: vol.avgSpiceOnPage,
                                                bookId: vol.id,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 100,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: vol.imageUrl != null
                                                ? Image.network(
                                                    vol.imageUrl!,
                                                    width: 84,
                                                    height: 64,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, st) =>
                                                        Container(
                                                          width: 84,
                                                          height: 64,
                                                          color: theme
                                                              .colorScheme
                                                              .surfaceContainerHighest,
                                                          child: Icon(
                                                            Icons.book,
                                                            color: theme
                                                                .colorScheme
                                                                .onSurface,
                                                          ),
                                                        ),
                                                  )
                                                : Container(
                                                    width: 84,
                                                    height: 64,
                                                    color: theme
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                    child: Icon(
                                                      Icons.book,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            vol.seriesIndex != null
                                                ? '#${vol.seriesIndex}'
                                                : vol.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
