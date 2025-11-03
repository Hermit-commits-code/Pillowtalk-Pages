// lib/screens/search/deep_trope_search_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/book_model.dart';
import '../../services/community_data_service.dart';
import '../../services/hard_stops_service.dart';
import '../../services/kink_filter_service.dart';
import '../book/book_detail_screen.dart';

// A small starter list of common tropes for the Deep Trope search MVP.
// This can be replaced with a dynamic list populated from community data later.
const List<String> _commonTropes = [
  'Enemies to Lovers',
  'Grumpy Sunshine',
  'Mutual Pining',
  'Fake Dating',
  'Second Chance',
  'Friends to Lovers',
  'Secret Baby',
  'Office Romance',
  'Age Gap',
  'Billionaire',
  'Arranged Marriage',
  'Marriage of Convenience',
  'Forced Proximity',
  'Opposites Attract',
];

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
  // Deep-trope selection state
  final List<String> _selectedTropes = [];
  bool _andMode = true; // true = AND semantics, false = OR semantics
  // Filters
  final HardStopsService _hardStopsService = HardStopsService();
  final KinkFilterService _kinkFilterService = KinkFilterService();
  List<String> _hardStops = [];
  bool _hardStopsEnabled = true;
  List<String> _kinkFilters = [];
  bool _kinkFilterEnabled = true;
  late final StreamSubscription _hsSub;
  late final StreamSubscription _kfSub;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _hsSub.cancel();
    _kfSub.cancel();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(q));
  }

  Future<void> _runTropeSearch() async {
    if (_selectedTropes.isEmpty) return _runSearch(_controller.text);
    setState(() {
      _loading = true;
    });

    try {
      final res = await _service.searchBooksByTropes(
        _selectedTropes,
        orMode: !_andMode,
        limit: 100,
      );

      // Apply hard-stops and kink filters (reuse same filter logic as in _runSearch)
      final filtered = res.where((b) {
        if ((_hardStopsEnabled && _hardStops.isNotEmpty)) {
          for (final w in b.topWarnings) {
            for (final h in _hardStops) {
              if (w.toLowerCase().contains(h.toLowerCase()) ||
                  h.toLowerCase().contains(w.toLowerCase())) {
                return false;
              }
            }
          }
          for (final t in b.communityTropes) {
            for (final h in _hardStops) {
              if (t.toLowerCase().contains(h.toLowerCase()) ||
                  h.toLowerCase().contains(t.toLowerCase())) {
                return false;
              }
            }
          }
        }
        if ((_kinkFilterEnabled && _kinkFilters.isNotEmpty)) {
          for (final tp in b.communityTropes) {
            for (final k in _kinkFilters) {
              if (tp.toLowerCase().contains(k.toLowerCase()) ||
                  k.toLowerCase().contains(tp.toLowerCase())) {
                return false;
              }
            }
          }
          for (final w in b.topWarnings) {
            for (final k in _kinkFilters) {
              if (w.toLowerCase().contains(k.toLowerCase()) ||
                  k.toLowerCase().contains(w.toLowerCase())) {
                return false;
              }
            }
          }
        }
        return true;
      }).toList();

      setState(() => _results = filtered);
    } catch (e) {
      // ignore: avoid_print
      print('Trope search failed: $e');
      setState(() => _results = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _runSearch(String q) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) {
      // If user has selected tropes, run trope search instead of clearing
      if (_selectedTropes.isNotEmpty) {
        return _runTropeSearch();
      }
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
      // Apply filters client-side
      final filtered = res.where((b) {
        // Hard stops
        if ((_hardStopsEnabled && _hardStops.isNotEmpty)) {
          for (final w in b.topWarnings) {
            for (final h in _hardStops) {
              if (w.toLowerCase().contains(h.toLowerCase()) ||
                  h.toLowerCase().contains(w.toLowerCase())) {
                return false;
              }
            }
          }
          for (final t in b.communityTropes) {
            for (final h in _hardStops) {
              if (t.toLowerCase().contains(h.toLowerCase()) ||
                  h.toLowerCase().contains(t.toLowerCase())) {
                return false;
              }
            }
          }
        }
        // Kink filters
        if ((_kinkFilterEnabled && _kinkFilters.isNotEmpty)) {
          for (final tp in b.communityTropes) {
            for (final k in _kinkFilters) {
              if (tp.toLowerCase().contains(k.toLowerCase()) ||
                  k.toLowerCase().contains(tp.toLowerCase())) {
                return false;
              }
            }
          }
          for (final w in b.topWarnings) {
            for (final k in _kinkFilters) {
              if (w.toLowerCase().contains(k.toLowerCase()) ||
                  k.toLowerCase().contains(w.toLowerCase())) {
                return false;
              }
            }
          }
        }
        return true;
      }).toList();

      setState(() {
        _results = filtered;
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
  void initState() {
    super.initState();
    _hsSub = _hardStopsService.hardStopsStream().listen((s) {
      setState(() => _hardStops = s);
    });
    _hardStopsService.hardStopsEnabledStream().listen(
      (v) => setState(() => _hardStopsEnabled = v),
    );
    _kfSub = _kinkFilterService.kinkFilterStream().listen((s) {
      setState(() => _kinkFilters = s);
    });
    _kinkFilterService.kinkFilterEnabledStream().listen(
      (v) => setState(() => _kinkFilterEnabled = v),
    );
  }

  void _showProModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upgrade to Pro'),
        content: const Text(
          'Free users can select up to 2 tropes. Upgrade to Pro Club to unlock unlimited trope combinations for advanced searches!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/pro-club');
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
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
            // Tropes selector (MVP)
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _commonTropes.map((t) {
                  final selected = _selectedTropes.contains(t);
                  return ChoiceChip(
                    label: Text(
                      t,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedTropes.add(t);
                          // Check if user exceeded limit (free users max 2 tropes)
                          if (_selectedTropes.length > 2) {
                            _showProModal(context);
                            _selectedTropes.removeLast();
                          }
                        } else {
                          _selectedTropes.remove(t);
                        }
                      });
                      _runTropeSearch();
                    },
                  );
                }).toList(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  const Text('Match mode:'),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('AND'),
                    selected: _andMode,
                    onSelected: (v) {
                      setState(() => _andMode = true);
                      if (_selectedTropes.isNotEmpty) _runTropeSearch();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('OR'),
                    selected: !_andMode,
                    onSelected: (v) {
                      setState(() => _andMode = false);
                      if (_selectedTropes.isNotEmpty) _runTropeSearch();
                    },
                  ),
                  const Spacer(),
                  if (_selectedTropes.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedTropes.clear());
                        _runSearch(_controller.text);
                      },
                      child: const Text('Clear tropes'),
                    ),
                ],
              ),
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
                  : RepaintBoundary(
                      child: ListView.builder(
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
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(vols.length, (j) {
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
                                      height: 120,
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
                                }),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
