// lib/screens/book/edit_book_modal.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/user_book.dart';
import '../../models/user_list.dart';
import '../../services/user_library_service.dart';
import '../../services/lists_service.dart';
import 'genre_selection_screen.dart';
import 'widgets/lists_dropdown.dart';
import '../../widgets/trope_dropdown_tile.dart';

/// A compact modal for editing an existing UserBook's editable fields.
///
/// This is intentionally a self-contained widget that can be shown via
/// `showModalBottomSheet` or pushed as a route. It accepts an existing
/// [UserBook] instance and an optional [userLibraryService] for test DI.
class EditBookModal extends StatefulWidget {
  final UserBook userBook;
  final dynamic userLibraryService; // UserLibraryService or test double
  final dynamic listsService; // ListsService or test double

  const EditBookModal({
    super.key,
    required this.userBook,
    this.userLibraryService,
    this.listsService,
  });

  @override
  State<EditBookModal> createState() => _EditBookModalState();
}

class _EditBookModalState extends State<EditBookModal> {
  late List<String> _selectedGenres;
  late List<String> _selectedTropes;
  late List<String> _selectedListIds;
  late ReadingStatus _status;
  late TextEditingController _notesController;
  BookOwnership _ownership = BookOwnership.none;

  bool _isSaving = false;
  // Map of listId -> listName for display above the dropdown
  Map<String, String> _availableListNames = {};
  StreamSubscription<List<UserList>>? _listsSub;

  @override
  void initState() {
    super.initState();
    _selectedGenres = List.from(widget.userBook.genres);
    _selectedTropes = List.from(widget.userBook.userSelectedTropes);
    _selectedListIds = [];
    _status = widget.userBook.status;
    _notesController = TextEditingController(
      text: widget.userBook.userNotes ?? '',
    );
    _ownership = widget.userBook.ownership;
    // Subscribe to lists so we can show human-friendly names for selected
    // list IDs. Use injected service when provided (testable), otherwise
    // construct a ListsService for the live app.
    try {
      final ls = widget.listsService ?? ListsService();
      _listsSub = ls.getUserListsStream().listen((lists) {
        setState(() {
          _availableListNames = {for (var l in lists) l.id: l.name};
        });
      });
    } catch (_) {
      // Swallow errors - showing raw ids is acceptable in failure modes.
    }
  }

  @override
  void dispose() {
    _listsSub?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectGenres() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (c) => GenreSelectionScreen(initialGenres: _selectedGenres),
      ),
    );
    if (result != null) setState(() => _selectedGenres = result);
  }

  Future<void> save() async {
    setState(() => _isSaving = true);
    try {
      final lib = widget.userLibraryService ?? UserLibraryService();
      // Compute possible automatic date changes when status transitions
      DateTime? newDateStarted = widget.userBook.dateStarted;
      DateTime? newDateFinished = widget.userBook.dateFinished;

      // If moving to reading and no start date recorded, set it.
      if (_status == ReadingStatus.reading && newDateStarted == null) {
        newDateStarted = DateTime.now();
      }

      // If moving to finished and no finished date recorded, set it.
      if (_status == ReadingStatus.finished && newDateFinished == null) {
        newDateFinished = DateTime.now();
      }

      final updated = widget.userBook.copyWith(
        genres: _selectedGenres,
        userSelectedTropes: _selectedTropes,
        userNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        ownership: _ownership,
        status: _status,
        dateStarted: newDateStarted,
        dateFinished: newDateFinished,
      );
      await lib.updateBook(updated);

      // Update list membership only if we have either an injected listsService
      // or there are selections to persist. Defer constructing a real
      // ListsService to avoid touching platform APIs during widget tests.
      if (widget.listsService != null || _selectedListIds.isNotEmpty) {
        try {
          final listsSvc = widget.listsService ?? ListsService();

          final currentLists = await listsSvc.getListsContainingBook(
            widget.userBook.id,
          );
          final currentIds = currentLists.map((l) => l.id).toSet();
          final targetIds = _selectedListIds.toSet();

          final toAdd = targetIds.difference(currentIds).toList();
          final toRemove = currentIds.difference(targetIds).toList();

          if (toAdd.isNotEmpty) {
            await listsSvc.addBookToLists(toAdd, widget.userBook.id);
          }
          for (final id in toRemove) {
            await listsSvc.removeBookFromList(id, widget.userBook.id);
          }
        } catch (e) {
          // Non-fatal: log and continue
          debugPrint('Failed updating list membership: $e');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Changes saved')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save changes: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : save,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: const Text('Genres'),
                subtitle: _selectedGenres.isNotEmpty
                    ? Text(_selectedGenres.join(', '))
                    : const Text('Tap to select genres'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectGenres,
              ),
              const SizedBox(height: 12),
              TropeDropdownTile(
                selectedTropes: _selectedTropes,
                onChanged: (res) => setState(() => _selectedTropes = res),
                title: 'Your Tropes',
                placeholder: 'Tap to edit tropes',
              ),
              const SizedBox(height: 12),
              // Show selected lists as chips above the dropdown so the user
              // can see what's currently selected and remove items quickly.
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
              ListsDropdown(
                initialSelectedListIds: _selectedListIds,
                placeholder: _selectedListIds.isNotEmpty
                    ? '${_selectedListIds.length} selected'
                    : 'Add to lists',
                onChanged: (ids) => setState(() => _selectedListIds = ids),
                listsService: widget.listsService,
              ),
              const SizedBox(height: 12),
              Text('Reading status', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ReadingStatus.values.map((s) {
                  final label = _readingStatusLabel(s);
                  final isSelected = _status == s;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (sel) =>
                        setState(() => _status = sel ? s : _status),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text('Ownership', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: BookOwnership.values.map((ownership) {
                  final isSelected = _ownership == ownership;
                  return ChoiceChip(
                    label: Text(_ownershipLabel(ownership)),
                    selected: isSelected,
                    onSelected: (sel) => setState(
                      () => _ownership = sel ? ownership : BookOwnership.none,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Personal Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: const Key('edit_book_save_button'),
                onPressed: _isSaving ? null : save,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
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

  String _readingStatusLabel(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.wantToRead:
        return 'Want to Read';
      case ReadingStatus.reading:
        return 'Reading';
      case ReadingStatus.finished:
        return 'Finished';
    }
  }
}
