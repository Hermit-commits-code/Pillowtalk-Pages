// lib/screens/book/book_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/user_library_service.dart';
import 'edit_book_modal.dart';
import '../../services/lists_service.dart';
import '../../config/affiliate.dart';
import '../../models/user_book.dart';
import '../../models/user_list.dart';
import '../../widgets/icon_rating_bar.dart';

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
  // Display-only state (refreshed from modal saves)
  late List<String> _displayGenres;
  late List<String> _displayTropes;
  late List<String> _displayWarnings;
  late String _displayNotes;

  // Vetted Spice Meter Display Values
  late double _displaySpiceOverall;
  late String _displaySpiceIntensity;
  late double _displayEmotionalArc;

  // Personal 1-5 star rating (private to the user)
  int? _displayPersonalStars;

  BookOwnership _displayOwnership = BookOwnership.none;

  final Map<String, IconData> _intensityOptions = {
    'Emotional': Icons.favorite,
    'Physical': Icons.local_fire_department,
    'Psychological': Icons.psychology,
  };

  @override
  void initState() {
    super.initState();
    _displayGenres = List.from(widget.genres ?? []);
    _displayTropes = List.from(widget.userSelectedTropes ?? []);
    _displayWarnings = List.from(widget.userContentWarnings ?? []);
    _displayNotes = widget.userNotes ?? '';

    _displaySpiceOverall = widget.spiceOverall ?? 0.0;
    _displaySpiceIntensity =
        widget.spiceIntensity ?? _intensityOptions.keys.first;
    _displayEmotionalArc = widget.emotionalArc ?? 0.0;

    // Load existing userBook to obtain ownership and personalStars if available
    if (widget.userBookId != null && widget.userBookId!.isNotEmpty) {
      UserLibraryService()
          .getUserBook(widget.userBookId!)
          .then((ub) {
            if (ub == null) return;
            if (!mounted) return;
            setState(() {
              _displayOwnership = ub.ownership;
              _displayPersonalStars = ub.personalStars;
            });
          })
          .catchError((e) {
            debugPrint('Failed to load userBook in detail screen: $e');
          });
    }
  }

  Future<void> _openEditModal() async {
    // If there's no userBookId, offer to save this book to the user's library
    // and then open the editor for that newly created userBook.
    if (widget.userBookId == null || widget.userBookId!.isEmpty) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Save to Library?'),
          content: const Text(
            'You don\'t have a personal copy of this book. Save it to your library so you can edit it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save & Edit'),
            ),
          ],
        ),
      );

      if (shouldSave != true) return;

      // Attempt to save to library; on success, load the new userBook and open editor.
      final saved = await _saveToLibrary();
      if (!saved) return;

      try {
        final ub = await UserLibraryService().getUserBook(widget.bookId!);
        if (ub == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to load book for editing')),
          );
          return;
        }

        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => EditBookModal(userBook: ub)),
        );

        if (result == true) {
          final updated = await UserLibraryService().getUserBook(
            widget.bookId!,
          );
          if (updated != null && mounted) {
            setState(() {
              _displayGenres = List.from(updated.genres);
              _displayTropes = List.from(updated.userSelectedTropes);
              _displayWarnings = List.from(updated.userContentWarnings);
              _displayNotes = updated.userNotes ?? '';
              _displaySpiceOverall =
                  updated.spiceOverall ?? _displaySpiceOverall;
              _displaySpiceIntensity =
                  updated.spiceIntensity ?? _displaySpiceIntensity;
              _displayEmotionalArc =
                  updated.emotionalArc ?? _displayEmotionalArc;
              _displayOwnership = updated.ownership;
              _displayPersonalStars = updated.personalStars;
            });
          }
        }
      } catch (e) {
        debugPrint('Error opening edit modal after save: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open editor: $e')));
      }

      return;
    }

    // Existing flow when userBookId is present
    try {
      final ub = await UserLibraryService().getUserBook(widget.userBookId!);
      if (ub == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load book for editing')),
        );
        return;
      }

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => EditBookModal(userBook: ub)),
      );

      if (result == true) {
        // Refresh display state from the updated userBook so the detail
        // screen shows chips and other edits made in the modal.
        final updated = await UserLibraryService().getUserBook(
          widget.userBookId!,
        );
        if (updated != null && mounted) {
          setState(() {
            _displayGenres = List.from(updated.genres);
            _displayTropes = List.from(updated.userSelectedTropes);
            _displayWarnings = List.from(updated.userContentWarnings);
            _displayNotes = updated.userNotes ?? '';
            _displaySpiceOverall = updated.spiceOverall ?? _displaySpiceOverall;
            _displaySpiceIntensity =
                updated.spiceIntensity ?? _displaySpiceIntensity;
            _displayEmotionalArc = updated.emotionalArc ?? _displayEmotionalArc;
            _displayOwnership = updated.ownership;
            _displayPersonalStars = updated.personalStars;
          });
        }
      }
    } catch (e) {
      debugPrint('Error opening edit modal: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open editor: $e')));
    }
  }

  @override
  void dispose() {
    super.dispose();
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

  Future<bool> _saveToLibrary() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to save books.')),
        );
        return false;
      }

      // Get the pre-seeded book data from Firestore
      final bookDoc = await FirebaseFirestore.instance
          .collection('books')
          .doc(widget.bookId)
          .get();

      if (!bookDoc.exists) {
        if (!mounted) return false;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Book not found.')));
        return false;
      }

      final bookData = bookDoc.data() as Map<String, dynamic>;

      // Create a user book entry in the user's library
      final userLibrary = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('library')
          .doc(widget.bookId);

      await userLibrary.set({
        'title': bookData['title'] ?? widget.title,
        'authors': bookData['authors'] ?? [widget.author],
        'isbn': bookData['isbn'] ?? '',
        'imageUrl': bookData['imageUrl'] ?? widget.coverUrl,
        'description': bookData['description'] ?? widget.description,
        'genres': bookData['genres'] ?? [],
        'isPreSeeded': true,
        'dateAdded': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book saved to your library!')),
      );
      return true;
    } catch (e) {
      debugPrint('Error saving book to library: $e');
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save book: $e')));
      return false;
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
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Save to Library',
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: _saveToLibrary,
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit),
            onPressed: _openEditModal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image with ownership indicator
            if (widget.coverUrl != null)
              Stack(
                children: [
                  Center(child: Image.network(widget.coverUrl!, height: 180)),
                  if (_displayOwnership != BookOwnership.none)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Chip(
                        label: Text(
                          _displayOwnership == BookOwnership.physical
                              ? 'Physical'
                              : _displayOwnership == BookOwnership.digital
                              ? 'Digital'
                              : _displayOwnership == BookOwnership.both
                              ? 'Owned Both'
                              : _displayOwnership ==
                                    BookOwnership.kindleUnlimited
                              ? 'Borrowed on Kindle'
                              : '',
                        ),
                        backgroundColor: _ownershipColor(_displayOwnership),
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 24),

            // --- GENRE TAGS (read-only display) ---
            Text('Your Genre Tags', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _displayGenres.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _displayGenres
                            .map((g) => Chip(label: Text(g)))
                            .toList(),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No genres selected'),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // --- LIST MEMBERSHIP (read-only display) ---
            Text('Your Lists', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: StreamBuilder<List<UserList>>(
                  stream: ListsService().getUserListsStream(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      final errorMsg = snap.error.toString();
                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              errorMsg.contains('permission')
                                  ? 'Unable to load your lists. Check Firestore permissions.'
                                  : 'Error loading lists',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }
                    final lists = snap.data ?? [];
                    if (snap.connectionState == ConnectionState.waiting &&
                        lists.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final current = lists
                        .where(
                          (l) =>
                              widget.userBookId != null &&
                              widget.userBookId!.isNotEmpty &&
                              l.bookIds.contains(widget.userBookId),
                        )
                        .toList();

                    return current.isNotEmpty
                        ? Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: current
                                .map((l) => Chip(label: Text(l.name)))
                                .toList(),
                          )
                        : const Text('No lists selected');
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- TROPES (read-only display) ---
            Text('Your Tropes', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _displayTropes.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _displayTropes
                            .map((t) => Chip(label: Text(t)))
                            .toList(),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No tropes selected'),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // --- CONTENT WARNINGS (read-only display) ---
            Text('Content Warnings', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _displayWarnings.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _displayWarnings
                            .map((w) => Chip(label: Text(w)))
                            .toList(),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No warnings selected'),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // --- VETTED SPICE METER (read-only display) ---
            Text('Your Spice Rating', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Spice',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How much explicit, on-page spice is there?',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconRatingBar(
                      title: '',
                      rating: _displaySpiceOverall,
                      onRatingUpdate: (_) {}, // Read-only
                      filledIcon: Icons.local_fire_department,
                      emptyIcon: Icons.local_fire_department_outlined,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Emotional Arc',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How central is the romantic relationship to the plot?',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconRatingBar(
                      title: '',
                      rating: _displayEmotionalArc,
                      onRatingUpdate: (_) {}, // Read-only
                      filledIcon: Icons.favorite,
                      emptyIcon: Icons.favorite_border,
                      color: Colors.pink,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Primary Intensity Driver',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'What is the main driver of the book\'s intensity?',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _displaySpiceIntensity,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- PERSONAL 1-5 STAR RATING (read-only display) ---
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
                      rating: (_displayPersonalStars ?? 0).toDouble(),
                      onRatingUpdate: (_) {}, // Read-only
                      filledIcon: Icons.star,
                      emptyIcon: Icons.star_border,
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- AMAZON BUTTON ---
            ElevatedButton.icon(
              onPressed: (_displayOwnership == BookOwnership.both)
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

            // --- DESCRIPTION ---
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

            // --- PERSONAL NOTES (read-only display) ---
            Text(
              'Personal Notes (Private)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  _displayNotes.isNotEmpty ? _displayNotes : 'No notes added',
                  style: _displayNotes.isEmpty
                      ? theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
