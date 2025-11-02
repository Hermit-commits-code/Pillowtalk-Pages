// lib/screens/book/book_detail_screen.dart

import 'package:flutter/material.dart';

import '../../models/book_model.dart';
import '../../models/user_book.dart';
import '../../services/community_data_service.dart';
import '../../services/ratings_service.dart';
import '../../services/user_library_service.dart';
import 'widgets/editable_tropes_section.dart';
import 'widgets/spice_meter_widgets.dart';
import 'widgets/tropes_chips.dart';

class BookDetailScreen extends StatefulWidget {
  final String title;
  final String author;
  final String? coverUrl;
  final String? description;
  final String? genre;
  final List<String>? subgenres;
  final String? seriesName;
  final int? seriesIndex;

  /// Aggregated community tropes (read-only list shown for context)
  final List<String>? communityTropes;

  /// Initial user-selected tropes (editable)
  final List<String>? userSelectedTropes;

  /// Initial user content warnings (editable)
  final List<String>? userContentWarnings;

  /// Available suggestions to feed the autocomplete (tropes)
  final List<String>? availableTropes;

  /// Available suggestions for warnings
  final List<String>? availableWarnings;
  final double? spiceLevel;

  /// The series name (if known) and optional index in series
  // final String? seriesName;
  // final int? seriesIndex;

  /// The community book id (used to write ratings/aggregates)
  final String? bookId;

  /// The user's library document id (used to update the user's library entry)
  final String? userBookId;

  const BookDetailScreen({
    super.key,
    required this.title,
    required this.author,
    this.coverUrl,
    this.description,
    this.genre,
    this.subgenres,
    this.communityTropes,
    this.userSelectedTropes,
    this.userContentWarnings,
    this.availableTropes,
    this.availableWarnings,
    this.spiceLevel,
    this.seriesName,
    this.seriesIndex,
    this.bookId,
    this.userBookId,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late List<String> _userTropes;
  late List<String> _userWarnings;
  late double _spiceLevel;
  Future<List<RomanceBook>>? _seriesFuture;

  @override
  void initState() {
    super.initState();
    _userTropes = List.from(widget.userSelectedTropes ?? []);
    _userWarnings = List.from(widget.userContentWarnings ?? []);
    _spiceLevel = widget.spiceLevel ?? 0.0;
    if (widget.seriesName != null && widget.seriesName!.isNotEmpty) {
      _seriesFuture = CommunityDataService().getBooksBySeries(
        widget.seriesName!,
      );
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

    final ratingsService = RatingsService();
    final userLib = UserLibraryService();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saving changes...')));

    try {
      // Submit community rating if we have a book id
      if (widget.bookId != null && widget.bookId!.isNotEmpty) {
        await ratingsService.submitRating(
          bookId: widget.bookId!,
          spiceLevel: _spiceLevel,
          tropes: _userTropes,
          warnings: _userWarnings,
        );
      }

      // Update the user's library entry if we have the userBookId
      if (widget.userBookId != null && widget.userBookId!.isNotEmpty) {
        final existing = await userLib.getUserBook(widget.userBookId!);
        if (existing != null) {
          final updated = UserBook(
            id: existing.id,
            userId: existing.userId,
            bookId: existing.bookId,
            status: existing.status,
            currentPage: existing.currentPage,
            totalPages: existing.totalPages,
            dateAdded: existing.dateAdded,
            dateStarted: existing.dateStarted,
            dateFinished: existing.dateFinished,
            // Map the single spiceLevel into the sensual axis for now.
            spiceSensual: _spiceLevel,
            spicePower: existing.spicePower,
            spiceIntensity: existing.spiceIntensity,
            spiceConsent: existing.spiceConsent,
            spiceEmotional: existing.spiceEmotional,
            userSelectedTropes: _userTropes,
            userContentWarnings: _userWarnings,
            userNotes: existing.userNotes,
            genre: existing.genre,
            subgenres: existing.subgenres,
          );
          await userLib.updateBook(updated);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Changes saved.')));
    } catch (e, st) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save changes: $e')));
      // Optionally log the error to console for debugging
      // ignore: avoid_print
      print('Error saving book details: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: theme.textTheme.titleLarge),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveChanges,
        label: const Text('Save'),
        icon: const Icon(Icons.save),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.coverUrl != null)
              Center(child: Image.network(widget.coverUrl!, height: 180)),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'by ${widget.author}',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (widget.seriesName != null && widget.seriesName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  widget.seriesIndex != null
                      ? '${widget.seriesName} • #${widget.seriesIndex}'
                      : widget.seriesName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withAlpha(
                      (0.8 * 255).round(),
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            // Series strip: show other volumes in the same series
            if (widget.seriesName != null && widget.seriesName!.isNotEmpty)
              FutureBuilder<List<RomanceBook>>(
                future: _seriesFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  final series = snap.data ?? [];
                  if (series.length <= 1) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: series.length,
                        itemBuilder: (context, i) {
                          final vol = series[i];
                          final isCurrent =
                              widget.bookId != null && vol.id == widget.bookId;
                          return GestureDetector(
                            onTap: () {
                              if (!isCurrent) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookDetailScreen(
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
                                      communityTropes: vol.communityTropes,
                                      availableTropes: vol.communityTropes,
                                      availableWarnings: vol.topWarnings,
                                      spiceLevel: vol.avgSpiceOnPage,
                                      bookId: vol.id,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              width: 88,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: vol.imageUrl != null
                                        ? Image.network(
                                            vol.imageUrl!,
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, st) =>
                                                Container(
                                                  width: 72,
                                                  height: 72,
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
                                            width: 72,
                                            height: 72,
                                            color: theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            child: Icon(
                                              Icons.book,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          vol.seriesIndex != null
                                              ? '#${vol.seriesIndex}'
                                              : vol.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: isCurrent
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isCurrent
                                                    ? theme.colorScheme.primary
                                                    : theme
                                                          .colorScheme
                                                          .onSurface,
                                              ),
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 6),
                                        Chip(
                                          label: const Text(
                                            'Current',
                                            style: TextStyle(fontSize: 10),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 0,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            if (widget.genre != null && widget.genre!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Genre: ${widget.genre}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            if (widget.subgenres != null && widget.subgenres!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Subgenres: ${widget.subgenres!.join(", ")}',
                  style: theme.textTheme.bodySmall,
                ),
              ),

            // Centered editable spice meter
            const SizedBox(height: 16),
            SpiceMeter(
              spiceLevel: _spiceLevel,
              editable: true,
              onChanged: (val) => setState(() => _spiceLevel = val),
            ),

            const SizedBox(height: 16),

            // Community tropes (read-only) for context
            if (widget.communityTropes != null &&
                widget.communityTropes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Community Tropes'),
                    TropesChips(tropes: widget.communityTropes!),
                  ],
                ),
              ),

            // Editable user tropes with autocomplete
            const SizedBox(height: 12),
            EditableTropesSection(
              tropes: _userTropes,
              availableTropes:
                  widget.availableTropes ?? widget.communityTropes ?? const [],
              onTropesChanged: _onTropesChanged,
              label: 'Your Tropes',
            ),

            const SizedBox(height: 12),

            // Editable content warnings with autocomplete
            EditableTropesSection(
              tropes: _userWarnings,
              availableTropes:
                  widget.availableWarnings ??
                  widget.communityTropes ??
                  const [],
              onTropesChanged: _onWarningsChanged,
              label: 'Content Warnings',
            ),

            const SizedBox(height: 16),
            if (widget.description != null && widget.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(widget.description!),
              ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
