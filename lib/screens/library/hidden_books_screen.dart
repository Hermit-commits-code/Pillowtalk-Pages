// lib/screens/library/hidden_books_screen.dart
import 'package:flutter/material.dart';

// removed unused imports
import '../../models/book_model.dart';
import '../../models/user_book.dart';
import '../../services/community_data_service.dart';
import '../../services/hard_stops_service.dart';
import '../../services/kink_filter_service.dart';
import '../../services/user_library_service.dart';

class HiddenBooksScreen extends StatefulWidget {
  const HiddenBooksScreen({super.key});

  @override
  State<HiddenBooksScreen> createState() => _HiddenBooksScreenState();
}

class _HiddenBooksScreenState extends State<HiddenBooksScreen> {
  final UserLibraryService _library = UserLibraryService();
  final HardStopsService _hard = HardStopsService();
  final KinkFilterService _kink = KinkFilterService();

  List<String> _hardStops = [];
  bool _hardEnabled = true;
  List<String> _kinks = [];
  bool _kinkEnabled = true;

  final Set<String> _selected = {};
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _hard.hardStopsStream().listen(
      (s) => setState(() {
        _hardStops = s;
      }),
    );
    _hard.hardStopsEnabledStream().listen(
      (v) => setState(() {
        _hardEnabled = v;
      }),
    );
    _kink.kinkFilterStream().listen(
      (s) => setState(() {
        _kinks = s;
      }),
    );
    _kink.kinkFilterEnabledStream().listen(
      (v) => setState(() {
        _kinkEnabled = v;
      }),
    );
  }

  bool _matchesFilters(UserBook ub) {
    if (ub.ignoreFilters) return false;
    final warns = ub.cachedTopWarnings;
    final tropes = ub.cachedTropes;
    if ((_hardEnabled && _hardStops.isNotEmpty)) {
      for (final h in _hardStops) {
        for (final w in warns) {
          if (w.toLowerCase().contains(h.toLowerCase()) ||
              h.toLowerCase().contains(w.toLowerCase())) {
            return true;
          }
        }
        for (final t in tropes) {
          if (t.toLowerCase().contains(h.toLowerCase()) ||
              h.toLowerCase().contains(t.toLowerCase())) {
            return true;
          }
        }
      }
    }
    if ((_kinkEnabled && _kinks.isNotEmpty)) {
      for (final k in _kinks) {
        for (final t in tropes) {
          if (t.toLowerCase().contains(k.toLowerCase()) ||
              k.toLowerCase().contains(t.toLowerCase())) {
            return true;
          }
        }
        for (final w in warns) {
          if (w.toLowerCase().contains(k.toLowerCase()) ||
              k.toLowerCase().contains(w.toLowerCase())) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> _bulkUnhide() async {
    if (_selected.isEmpty) return;
    setState(() => _isWorking = true);
    try {
      for (final id in _selected) {
        await _library.setIgnoreFilters(id, true);
      }
      if (!mounted) return;
      setState(() {
        _selected.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selected books unhidden.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _bulkRemove() async {
    if (_selected.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Remove ${_selected.length} books?'),
        content: const Text(
          'This will remove the selected books from your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isWorking = true);
    try {
      for (final id in _selected) {
        await _library.removeBook(id);
      }
      if (!mounted) return;
      setState(() => _selected.clear());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selected books removed.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _unhideAll() async {
    setState(() => _isWorking = true);
    try {
      final all = await _library.getUserLibraryStream().first;
      final hidden = all.where(_matchesFilters).toList();
      for (final ub in hidden) {
        await _library.setIgnoreFilters(ub.id, true);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unhid ${hidden.length} books')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hidden books'),
        actions: [
          IconButton(
            tooltip: 'Unhide all',
            onPressed: _isWorking ? null : _unhideAll,
            icon: const Icon(Icons.visibility_outlined),
          ),
          IconButton(
            tooltip: 'Unhide selected',
            onPressed: _isWorking ? null : _bulkUnhide,
            icon: _isWorking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.visibility_off_outlined),
          ),
          IconButton(
            tooltip: 'Remove selected',
            onPressed: _isWorking ? null : _bulkRemove,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
      body: StreamBuilder<List<UserBook>>(
        stream: _library.getUserLibraryStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final books = snap.data ?? [];
          final hidden = books.where(_matchesFilters).toList();
          if (hidden.isEmpty) {
            return Center(
              child: Text(
                'No hidden books found.',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: hidden.length,
            separatorBuilder: (context, index) => const Divider(height: 12),
            itemBuilder: (context, idx) {
              final ub = hidden[idx];
              return FutureBuilder<RomanceBook?>(
                future: CommunityDataService().getCommunityBookData(ub.bookId),
                builder: (context, snapBook) {
                  final book = snapBook.data;
                  return ListTile(
                    leading: Checkbox(
                      value: _selected.contains(ub.id),
                      onChanged: (v) => setState(
                        () => v == true
                            ? _selected.add(ub.id)
                            : _selected.remove(ub.id),
                      ),
                    ),
                    title: Row(
                      children: [
                        if (book?.imageUrl != null)
                          Container(
                            width: 44,
                            height: 60,
                            margin: const EdgeInsets.only(right: 8),
                            child: Image.network(
                              book!.imageUrl!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        Expanded(child: Text(book?.title ?? ub.bookId)),
                      ],
                    ),
                    subtitle: Text(
                      book != null
                          ? (book.authors.isNotEmpty
                                ? book.authors.join(', ')
                                : (ub.genre.isNotEmpty ? ub.genre : 'Unknown'))
                          : (ub.genre.isNotEmpty ? ub.genre : 'Unknown genre'),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (s) async {
                        if (s == 'unhide') {
                          await _library.setIgnoreFilters(ub.id, true);
                        }
                        if (s == 'remove') {
                          await _library.removeBook(ub.id);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'unhide',
                          child: Text('Unhide'),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text(
                            'Remove',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
