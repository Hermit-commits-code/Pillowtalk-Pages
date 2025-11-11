// lib/screens/book/book_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/user_library_service.dart';
import '../../services/lists_service.dart';
import 'widgets/lists_dropdown.dart';
import '../../widgets/icon_rating_bar.dart';
import 'genre_selection_screen.dart';
import 'widgets/editable_tropes_section.dart';
import '../../widgets/trope_dropdown_tile.dart';
import '../../config/affiliate.dart';
import '../../models/user_book.dart';
import '../../models/user_list.dart';

class BookDetailScreen extends StatefulWidget {
  final String title;
  final String author;
  final String? coverUrl;
  final String? description;
  final List<String>? genres;
  final String? seriesName;
  final int? seriesIndex;
  final List<String>? userSelectedTropes;
  final List<String>? userContentWarnings;
  final String? bookId;
  final String? userBookId;
  final String? userNotes;

  // Vetted Spice Meter Data
  final double? spiceOverall;
  final String? spiceIntensity;
  final double? emotionalArc;

  const BookDetailScreen({
    super.key,
    required this.title,
    required this.author,
    this.coverUrl,
    this.description,
    this.genres,
    this.seriesName,
    this.seriesIndex,
    this.userSelectedTropes,
    this.userContentWarnings,
    this.bookId,
    this.userBookId,
    this.userNotes,
    this.spiceOverall,
    this.spiceIntensity,
    this.emotionalArc,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late List<String> _selectedGenres;
  late List<String> _userTropes;
  late List<String> _userWarnings;
  late TextEditingController _notesController;

  // Vetted Spice Meter State
  late double _spiceOverall;
  late String _spiceIntensity;
  late double _emotionalArc;

  // Personal 1-5 star rating (private to the user)
  int? _personalStars;

  BookOwnership _ownership = BookOwnership.none;

  final Map<String, IconData> _intensityOptions = {
    'Emotional': Icons.favorite,
    'Physical': Icons.local_fire_department,
    'Psychological': Icons.psychology,
  };

  @override
  void initState() {
    super.initState();
    _selectedGenres = List.from(widget.genres ?? []);
    _userTropes = List.from(widget.userSelectedTropes ?? []);
    _userWarnings = List.from(widget.userContentWarnings ?? []);
    _notesController = TextEditingController(text: widget.userNotes ?? '');

    _spiceOverall = widget.spiceOverall ?? 0.0;
    _spiceIntensity = widget.spiceIntensity ?? _intensityOptions.keys.first;
    _emotionalArc = widget.emotionalArc ?? 0.0;

    // Load existing userBook to obtain ownership and personalStars if available
    if (widget.userBookId != null && widget.userBookId!.isNotEmpty) {
      // Fire-and-forget load; if it completes after init it will call setState
      UserLibraryService()
          .getUserBook(widget.userBookId!)
          .then((ub) {
            if (ub == null) return;
            if (!mounted) return;
            setState(() {
              _ownership = ub.ownership;
              _personalStars = ub.personalStars;
            });
          })
          .catchError((e) {
            // ignore; non-fatal if load fails
            debugPrint('Failed to load userBook in detail screen: $e');
          });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
      setState(() => _selectedGenres = result);
    }
  }

  void _onTropesChanged(List<String> updated) {
    setState(() => _userTropes = updated);
  }

  void _onWarningsChanged(List<String> updated) {
    setState(() => _userWarnings = updated);
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;

    final userLib = UserLibraryService();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saving changes...')));

    try {
      // Update user's personal library with all data (spice, tropes, warnings, etc.)
      if (widget.userBookId != null && widget.userBookId!.isNotEmpty) {
        final existing = await userLib.getUserBook(widget.userBookId!);
        if (existing != null) {
          final updated = existing.copyWith(
            userSelectedTropes: _userTropes,
            userContentWarnings: _userWarnings,
            userNotes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
            genres: _selectedGenres,
            spiceOverall: _spiceOverall,
            spiceIntensity: _spiceIntensity,
            emotionalArc: _emotionalArc,
            ownership: _ownership,
            personalStars: _personalStars,
          );
          await userLib.updateBook(updated);

          // Important: Refresh the UI state to show the updated data was saved
          debugPrint('Book updated successfully: ${updated.id}');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully!')),
      );
      // Close this detail screen and return a success flag so calling UI can refresh if needed
      Navigator.of(context).pop(true);
    } catch (e, st) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save changes: $e')));
      // Consider using a proper logging framework instead of print
      debugPrint('Error saving book details: $e\n$st');
    }
  }

  Future<void> _launchAmazon() async {
    final uri = buildAmazonSearchUrl(
      widget.title,
      widget.author,
      kAmazonAffiliateTag,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open Amazon.')));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveChanges,
        label: const Text('Save'),
        icon: const Icon(Icons.save),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.coverUrl != null)
              Stack(
                children: [
                  Center(child: Image.network(widget.coverUrl!, height: 180)),
                  if (_ownership != BookOwnership.none)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Chip(
                        label: Text(
                          _ownership == BookOwnership.physical
                              ? 'Physical'
                              : _ownership == BookOwnership.digital
                              ? 'Digital'
                              : _ownership == BookOwnership.both
                              ? 'Owned Both'
                              : _ownership == BookOwnership.kindleUnlimited
                              ? 'Borrowed on Kindle'
                              : '',
                        ),
                        backgroundColor: _ownershipColor(_ownership),
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            // Ownership selection UI (now scrollable and color-coded)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Physical'),
                    selected: _ownership == BookOwnership.physical,
                    selectedColor: _ownershipColor(BookOwnership.physical),
                    labelStyle: TextStyle(
                      color: _ownership == BookOwnership.physical
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _ownership = selected
                            ? BookOwnership.physical
                            : BookOwnership.none;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Digital'),
                    selected: _ownership == BookOwnership.digital,
                    selectedColor: _ownershipColor(BookOwnership.digital),
                    labelStyle: TextStyle(
                      color: _ownership == BookOwnership.digital
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _ownership = selected
                            ? BookOwnership.digital
                            : BookOwnership.none;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Both'),
                    selected: _ownership == BookOwnership.both,
                    selectedColor: _ownershipColor(BookOwnership.both),
                    labelStyle: TextStyle(
                      color: _ownership == BookOwnership.both
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _ownership = selected
                            ? BookOwnership.both
                            : BookOwnership.none;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Borrowed on Kindle'),
                    selected: _ownership == BookOwnership.kindleUnlimited,
                    selectedColor: _ownershipColor(
                      BookOwnership.kindleUnlimited,
                    ),
                    labelStyle: TextStyle(
                      color: _ownership == BookOwnership.kindleUnlimited
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _ownership = selected
                            ? BookOwnership.kindleUnlimited
                            : BookOwnership.none;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- VETTED SPICE METER ---
            Text('Your Spice Rating', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 28.0,
                  horizontal: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CenteredSection(
                      title: 'Overall Spice',
                      iconBar: IconRatingBar(
                        title: '',
                        rating: _spiceOverall,
                        onRatingUpdate: (val) =>
                            setState(() => _spiceOverall = val),
                        filledIcon: Icons.local_fire_department,
                        emptyIcon: Icons.local_fire_department_outlined,
                        color: Colors.orange,
                      ),
                      helperText: 'How much explicit, on-page spice is there?',
                    ),
                    const SizedBox(height: 32),
                    CenteredSection(
                      title: 'Emotional Arc',
                      iconBar: IconRatingBar(
                        title: '',
                        rating: _emotionalArc,
                        onRatingUpdate: (val) =>
                            setState(() => _emotionalArc = val),
                        filledIcon: Icons.favorite,
                        emptyIcon: Icons.favorite_border,
                        color: Colors.pink,
                      ),
                      helperText:
                          'How central is the romantic relationship to the plot?',
                    ),
                    const SizedBox(height: 32),
                    // --- Primary Intensity Driver ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Primary Intensity Driver',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'What is the main driver of the book\'s intensity?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _intensityOptions.entries.map((entry) {
                            final isSelected = _spiceIntensity == entry.key;
                            return InkWell(
                              onTap: () =>
                                  setState(() => _spiceIntensity = entry.key),
                              child: Column(
                                children: [
                                  Icon(
                                    entry.value,
                                    size: 36,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.disabledColor,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.disabledColor,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // --- PERSONAL 1-5 STAR RATING (PRIVATE) ---
            Text('Your Personal Rating', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rate this book (private)'),
                    const SizedBox(height: 8),
                    IconRatingBar(
                      title: '',
                      rating: (_personalStars ?? 0).toDouble(),
                      onRatingUpdate: (val) =>
                          setState(() => _personalStars = val.toInt()),
                      filledIcon: Icons.star,
                      emptyIcon: Icons.star_border,
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: (_ownership == BookOwnership.both)
                  ? null
                  : _launchAmazon,
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Buy on Amazon'),
            ),
            if (kAffiliateDisclosure.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  kAffiliateDisclosure,
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),

            // --- GENRE TAGS ---
            Text('Your Genre Tags', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: _selectedGenres.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _selectedGenres
                            .map((g) => Chip(label: Text(g)))
                            .toList(),
                      )
                    : const Text('No genres selected'),
                trailing: const Icon(Icons.edit),
                onTap: _selectGenres,
              ),
            ),
            const SizedBox(height: 16),
            // --- LIST MEMBERSHIP ---
            Text('Your Lists', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: StreamBuilder<List<UserList>>(
                  stream: ListsService().getUserListsStream(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final lists = snap.data!;
                    final current = lists
                        .where(
                          (l) =>
                              widget.userBookId != null &&
                              widget.userBookId!.isNotEmpty &&
                              l.bookIds.contains(widget.userBookId),
                        )
                        .map((l) => l.id)
                        .toList();
                    return ListsDropdown(
                      initialSelectedListIds: current,
                      placeholder: current.isNotEmpty
                          ? '${current.length} selected'
                          : 'Add to one or more lists (optional)',
                      onChanged: (newIds) async {
                        final service = ListsService();
                        final added = newIds.where(
                          (id) => !current.contains(id),
                        );
                        final removed = current.where(
                          (id) => !newIds.contains(id),
                        );
                        if (widget.userBookId == null ||
                            widget.userBookId!.isEmpty) {
                          return;
                        }
                        for (final id in added) {
                          await service.addBookToList(id, widget.userBookId!);
                        }
                        for (final id in removed) {
                          await service.removeBookFromList(
                            id,
                            widget.userBookId!,
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- TROPES AND WARNINGS ---
            TropeDropdownTile(
              selectedTropes: _userTropes,
              onChanged: (res) => _onTropesChanged(res),
              title: 'Your Tropes',
              placeholder: 'Tap to edit tropes',
            ),
            const SizedBox(height: 12),
            EditableTropesSection(
              tropes: _userWarnings,
              availableTropes:
                  const [], // Replace with actual available warnings
              onTropesChanged: _onWarningsChanged,
              label: 'Content Warnings',
            ),
            const SizedBox(height: 24),

            // --- DESCRIPTION & NOTES ---
            if (widget.description != null && widget.description!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Html(data: widget.description!),
                  const SizedBox(height: 24),
                ],
              ),
            Text(
              'Personal Notes (Private)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Add your private thoughts about this book...',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// Add this widget at the top (after imports):
class CenteredSection extends StatelessWidget {
  final String title;
  final Widget iconBar;
  final String helperText;
  const CenteredSection({
    super.key,
    required this.title,
    required this.iconBar,
    required this.helperText,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2), // Tighter spacing between title and iconBar
        iconBar,
        const SizedBox(height: 4),
        Text(
          helperText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
