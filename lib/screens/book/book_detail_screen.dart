// lib/screens/book/book_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/ratings_service.dart';
import '../../services/user_library_service.dart';
import '../../widgets/icon_rating_bar.dart';
import 'genre_selection_screen.dart';
import 'widgets/editable_tropes_section.dart';
import '../../config/affiliate.dart';

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

    final ratingsService = RatingsService();
    final userLib = UserLibraryService();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saving changes...')));

    try {
      if (widget.bookId != null && widget.bookId!.isNotEmpty) {
        await ratingsService.submitRating(
          bookId: widget.bookId!,
          spiceOverall: _spiceOverall,
          spiceIntensity: _spiceIntensity,
          emotionalArc: _emotionalArc,
          tropes: _userTropes,
          warnings: _userWarnings,
          genres: _selectedGenres,
        );
      }

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
      // TODO: Consider using a proper logging framework instead of print
      debugPrint('Error saving book details: $e\n$st');
    }
  }

  Future<void> _launchAmazon() async {
    final uri = buildAmazonSearchUrl(widget.title, widget.author, kAmazonAffiliateTag);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Amazon.')),
      );
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
              Center(child: Image.network(widget.coverUrl!, height: 180)),
            const SizedBox(height: 16),
            Center(
              child: Text(
                widget.title,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'by ${widget.author}',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // --- VETTED SPICE METER ---
            Text('Your Spice Rating', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconRatingBar(
                      title: 'Overall Spice',
                      rating: _spiceOverall,
                      onRatingUpdate: (val) =>
                          setState(() => _spiceOverall = val),
                      filledIcon: Icons.local_fire_department,
                      emptyIcon: Icons.local_fire_department_outlined,
                      color: Colors.orange,
                    ),
                    const Text(
                      'How much explicit, on-page spice is there?',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    IconRatingBar(
                      title: 'Emotional Arc',
                      rating: _emotionalArc,
                      onRatingUpdate: (val) =>
                          setState(() => _emotionalArc = val),
                      filledIcon: Icons.favorite,
                      emptyIcon: Icons.favorite_border,
                      color: Colors.pink,
                    ),
                    const Text(
                      'How central is the romantic relationship to the plot?',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Buy on Amazon button and disclosure
                    ElevatedButton.icon(
                      onPressed: _launchAmazon,
                      icon: const Icon(Icons.shopping_bag),
                      label: const Text('Buy on Amazon'),
                    ),
                    const SizedBox(height: 8),
                    if (kAffiliateDisclosure.isNotEmpty)
                      Text(
                        kAffiliateDisclosure,
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),
                    // Center the Primary Intensity Driver title and helper to match the IconRatingBar headings
                    Center(
                      child: Text(
                        'Primary Intensity Driver',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'What is the main driver of the book\'s intensity?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
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
              ),
            ),
            const SizedBox(height: 24),

            // --- GENRE TAGS ---
            Text('Your Genre Tags', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: _selectedGenres.isNotEmpty
                    ? Text(_selectedGenres.join(', '))
                    : const Text('No genres selected'),
                trailing: const Icon(Icons.edit),
                onTap: _selectGenres,
              ),
            ),
            const SizedBox(height: 24),

            // --- TROPES AND WARNINGS ---
            EditableTropesSection(
              tropes: _userTropes,
              availableTropes: const [], // Replace with actual available tropes
              onTropesChanged: _onTropesChanged,
              label: 'Your Tropes',
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
