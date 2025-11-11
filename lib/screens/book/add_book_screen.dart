// lib/screens/book/add_book_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

import '../../models/book_model.dart';
import '../../models/user_book.dart';
import '../../services/google_books_service.dart';
import '../../services/user_library_service.dart';
import '../../services/pro_exceptions.dart';
import '../../services/lists_service.dart';
import '../../services/analytics_service.dart';
import '../../services/kink_filter_service.dart';
import '../../services/hard_stops_service.dart';
import 'widgets/lists_dropdown.dart';
import '../../widgets/trope_dropdown_tile.dart';
import '../../models/user_list.dart';
import 'genre_selection_screen.dart';

class AddBookScreen extends StatefulWidget {
  /// Optional initial tropes (useful for tests) and optional injectable
  /// services to avoid direct Firestore/Firebase access in widget tests.
  const AddBookScreen({
    super.key,
    this.initialSelectedTropes,
    this.kinkFilterService,
    this.hardStopsService,
    this.userLibraryService,
    this.listsService,
  });

  final List<String>? initialSelectedTropes;
  final dynamic kinkFilterService; // KinkFilterService or test double
  final dynamic hardStopsService; // HardStopsService or test double
  final dynamic
  userLibraryService; // Optional test double for UserLibraryService
  final dynamic listsService; // Optional test double for ListsService

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _seriesNameController = TextEditingController();
  final TextEditingController _seriesIndexController = TextEditingController();

  final GoogleBooksService _googleBooksService = GoogleBooksService();
  // Defer creating UserLibraryService until actually needed so tests that
  // pump this widget don't instantiate Firestore/Firebase. Use
  // `widget.userLibraryService` if provided (test injection).

  bool _isLoading = false;
  String? _error;

  List<String> _selectedGenres = [];
  List<String> _selectedTropes = [];
  List<String> _selectedListIds = [];
  Map<String, String> _availableListNames = {};
  StreamSubscription<List<UserList>>? _listsSub;
  BookOwnership _selectedOwnership =
      BookOwnership.digital; // Default to digital

  List<RomanceBook> _searchResults = [];
  bool _searchPerformed = false;

  @override
  void dispose() {
    _listsSub?.cancel();
    _searchController.dispose();
    _seriesNameController.dispose();
    _seriesIndexController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedTropes != null) {
      _selectedTropes = List<String>.from(widget.initialSelectedTropes!);
    }
    // Subscribe to lists so we can display human-friendly names for selected
    // list IDs. Use injected service when provided to keep tests hermetic.
    try {
      final ls = widget.listsService ?? ListsService();
      _listsSub = ls.getUserListsStream().listen((lists) {
        setState(() {
          _availableListNames = {for (var l in lists) l.id: l.name};
        });
      });
    } catch (_) {
      // ignore - showing raw ids is acceptable when lists can't be loaded.
    }
  }

  Future<void> _selectGenres() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GenreSelectionScreen(initialGenres: _selectedGenres),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedGenres = result;
      });
    }
  }

  // Trope selection no longer uses the full-screen selector; we use a
  // compact dropdown in the add modal. (Trope engine deprecated.)

  // Lists are selected via the compact ListsDropdown widget below.

  Future<void> _searchBooks() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _error = 'Please enter a search term');
      return;
    }

    setState(() {
      _isLoading = true;
      _searchPerformed = true;
      _error = null;
      _searchResults = [];
    });

    try {
      final results = await _googleBooksService.searchBooks(query);
      setState(() {
        _searchResults = results;
        if (results.isEmpty) {
          _error = 'No books found. Try a different search term.';
        }
      });
    } catch (e) {
      setState(() => _error = 'Search failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Tropes are now selected via the compact TropeDropdownTile (two-pane picker).

  /// Check if any selected tropes conflict with user's kink filters or hard stops.
  /// Returns a map: {'hasConflicts': bool, 'conflictingTropes': List<String>}
  /// Public for tests: check if any selected tropes conflict with user's
  /// kink filters or hard stops. Returns {'hasConflicts': bool, 'conflictingTropes': List<String>}.
  Future<Map<String, dynamic>> checkForTropeConflicts() async {
    if (_selectedTropes.isEmpty) {
      return {'hasConflicts': false, 'conflictingTropes': <String>[]};
    }

    try {
      final kinkService = widget.kinkFilterService ?? KinkFilterService();
      final hardStopsService = widget.hardStopsService ?? HardStopsService();

      final kinkData = await kinkService.getKinkFilterOnce();
      final hardStopsData = await hardStopsService.getHardStopsOnce();

      final kinkEnabled = kinkData['enabled'] as bool? ?? true;
      final hardStopsEnabled = hardStopsData['enabled'] as bool? ?? true;

      final kinkFilters =
          (kinkData['kinkFilter'] as List<String>?) ?? <String>[];
      final hardStops =
          (hardStopsData['hardStops'] as List<String>?) ?? <String>[];

      final conflicts = <String>[];

      if (kinkEnabled) {
        for (final trope in _selectedTropes) {
          if (kinkFilters.contains(trope)) {
            conflicts.add(trope);
          }
        }
      }

      if (hardStopsEnabled) {
        for (final trope in _selectedTropes) {
          if (hardStops.contains(trope) && !conflicts.contains(trope)) {
            conflicts.add(trope);
          }
        }
      }

      return {
        'hasConflicts': conflicts.isNotEmpty,
        'conflictingTropes': conflicts,
      };
    } catch (e) {
      debugPrint('Error checking trope conflicts: $e');
      // On error, allow the user to proceed without conflicts check
      return {'hasConflicts': false, 'conflictingTropes': <String>[]};
    }
  }

  // Conflict confirmation dialog removed: policy is to block saves that
  // contain tropes matching the user's kink filters or hard stops. This
  // keeps the behavior strict: users must remove conflicting tropes or
  // update their profile filters before adding the book.

  Future<void> _addBookToLibrary(RomanceBook book) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add books')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check for kink/hard-stop conflicts before saving. Under the
      // stricter policy we block saves if conflicts are present.
      final conflictCheck = await checkForTropeConflicts();
      if (conflictCheck['hasConflicts'] as bool) {
        setState(() => _isLoading = false);
        final conflicts = List<String>.from(
          conflictCheck['conflictingTropes'] as List,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot add book: selected tropes conflict with your filters/hard stops: ${conflicts.join(', ')}. Update your Profile or remove these tropes.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 6),
          ),
        );
        return;
      }

      final userBook = UserBook(
        id: '${user.uid}_${book.id}',
        bookId: book.id,
        userId: user.uid,
        title: book.title,
        authors: book.authors,
        imageUrl: book.imageUrl,
        description: book.description,
        status: ReadingStatus.wantToRead,
        genres: _selectedGenres,
        userSelectedTropes: _selectedTropes,
        ownership: _selectedOwnership,
        seriesName: _seriesNameController.text.trim().isNotEmpty
            ? _seriesNameController.text.trim()
            : null,
        seriesIndex: int.tryParse(_seriesIndexController.text.trim()),
      );

      final userLib = widget.userLibraryService ?? UserLibraryService();
      await userLib.addBook(userBook);

      // Analytics: record add_book
      try {
        await AnalyticsService.instance.logAddBook(
          userBookId: userBook.id,
          bookId: book.id,
        );
      } catch (e) {
        debugPrint('Analytics logAddBook failed: $e');
      }

      // Add to selected lists (if any)
      if (_selectedListIds.isNotEmpty) {
        try {
          final listsService = widget.listsService ?? ListsService();
          await listsService.addBookToLists(_selectedListIds, userBook.id);
        } catch (e) {
          debugPrint('Failed to add book to lists: $e');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${book.title}" to your library')),
      );
      context.pop();
    } on ProUpgradeRequiredException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'UPGRADE',
            onPressed: () => context.push('/pro-club'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add book: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Book')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search for a book',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _searchBooks(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(56, 56),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _searchBooks,
                      child: const Icon(Icons.search, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Genres'),
                subtitle: _selectedGenres.isNotEmpty
                    ? Text(_selectedGenres.join(', '))
                    : const Text('Tap to select genres'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectGenres,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
              ),
              const SizedBox(height: 16),
              // Tropes: compact categorized dropdown (two-pane picker)
              TropeDropdownTile(
                selectedTropes: _selectedTropes,
                onChanged: (res) => setState(() => _selectedTropes = res),
              ),
              const SizedBox(height: 16),
              // Show selected lists as chips (so users see current choices at a glance)
              if (_selectedListIds.isNotEmpty) ...[
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    children: _selectedListIds.map((id) {
                      final name = _availableListNames[id] ?? id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InputChip(
                          label: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Tooltip(
                              message: name,
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          onDeleted: () =>
                              setState(() => _selectedListIds.remove(id)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Reusable compact lists dropdown used by both Add and Edit flows.
              ListsDropdown(
                initialSelectedListIds: _selectedListIds,
                placeholder: _selectedListIds.isNotEmpty
                    ? '${_selectedListIds.length} selected'
                    : 'Add to one or more lists (optional)',
                onChanged: (ids) {
                  setState(() => _selectedListIds = ids);
                },
                listsService: widget.listsService,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ownership Status',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: BookOwnership.values.map((ownership) {
                        final isSelected = _selectedOwnership == ownership;
                        return FilterChip(
                          label: Text(_ownershipLabel(ownership)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedOwnership = ownership;
                            });
                          },
                          avatar: isSelected
                              ? null
                              : CircleAvatar(
                                  backgroundColor: _ownershipColor(ownership),
                                  radius: 6,
                                ),
                          selectedColor: _ownershipColor(
                            ownership,
                          ).withValues(alpha: 0.3),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              TextField(
                controller: _seriesNameController,
                decoration: const InputDecoration(
                  labelText: 'Series (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _seriesIndexController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Book number in series (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_searchPerformed) _buildSearchResults(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No results found.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return Card(
          child: ListTile(
            leading: book.imageUrl != null
                ? Image.network(
                    book.imageUrl!,
                    width: 48,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.book, size: 48),
            title: Text(
              book.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(book.authors.join(', ')),
            trailing: ElevatedButton(
              onPressed: _isLoading ? null : () => _addBookToLibrary(book),
              child: const Text('Add'),
            ),
          ),
        );
      },
    );
  }

  String _ownershipLabel(BookOwnership ownership) {
    switch (ownership) {
      case BookOwnership.none:
        return 'None';
      case BookOwnership.physical:
        return 'Physical';
      case BookOwnership.digital:
        return 'Digital';
      case BookOwnership.both:
        return 'Both';
      case BookOwnership.kindleUnlimited:
        return 'Borrowed on Kindle';
    }
  }

  Color _ownershipColor(BookOwnership ownership) {
    switch (ownership) {
      case BookOwnership.physical:
        return Colors.brown;
      case BookOwnership.digital:
        return Colors.blue;
      case BookOwnership.both:
        return Colors.green;
      case BookOwnership.kindleUnlimited:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
