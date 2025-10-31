// lib/screens/book/book_detail_screen.dart

import 'package:flutter/material.dart';

import '../../models/book_model.dart';
import '../../models/user_book.dart';
import '../../services/community_data_service.dart';
import '../../services/ratings_service.dart';
import '../../services/user_library_service.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final CommunityDataService _communityDataService = CommunityDataService();
  final UserLibraryService _userLibraryService = UserLibraryService();
  final RatingsService _ratingsService = RatingsService();

  RomanceBook? _book;
  UserBook? _userBook;
  bool _isLoading = true;
  String? _error;
  double? _userSpiceRating;
  double? _userEmotionalRating;
  String? _userNotes;
  ReadingStatus? _status;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final book = await _communityDataService.getCommunityBookData(
        widget.bookId,
      );
      final userBook = await _userLibraryService.getUserBook(widget.bookId);
      setState(() {
        _book = book;
        _userBook = userBook;
        _userSpiceRating = userBook?.userSpiceRating;
        _userEmotionalRating = userBook?.userEmotionalRating;
        _userNotes = userBook?.userNotes;
        _status = userBook?.status;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load book details: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserRating() async {
    if (_userBook == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final updated = UserBook(
        id: _userBook!.id,
        userId: _userBook!.userId,
        bookId: _userBook!.bookId,
        status: _status ?? _userBook!.status,
        currentPage: _userBook!.currentPage,
        totalPages: _userBook!.totalPages,
        dateAdded: _userBook!.dateAdded,
        dateStarted: _userBook!.dateStarted,
        dateFinished: _userBook!.dateFinished,
        userSpiceRating: _userSpiceRating,
        userEmotionalRating: _userEmotionalRating,
        userSelectedTropes: _userBook!.userSelectedTropes,
        userContentWarnings: _userBook!.userContentWarnings,
        userNotes: _userNotes,
      );
      await _ratingsService.setUserRating(updated);
      setState(() {
        _userBook = updated;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to save rating: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _book == null
          ? const Center(child: Text('Book not found.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _book!.imageUrl != null
                          ? Image.network(
                              _book!.imageUrl!,
                              width: 96,
                              height: 144,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.book, size: 96),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _book!.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              _book!.authors.join(', '),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (_book!.publishedDate != null)
                              Text('Published: ${_book!.publishedDate!}'),
                            if (_book!.pageCount != null)
                              Text('Pages: ${_book!.pageCount!}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_book!.description != null)
                    Text(
                      _book!.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Community Data',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('Tropes: ${_book!.communityTropes.join(', ')}'),
                  Text(
                    'Spice Meter: ${_book!.avgSpiceOnPage.toStringAsFixed(1)}',
                  ),
                  Text(
                    'Emotional Intensity: ${_book!.avgEmotionalIntensity.toStringAsFixed(1)}',
                  ),
                  Text('Warnings: ${_book!.topWarnings.join(', ')}'),
                  Text('Total Ratings: ${_book!.totalUserRatings}'),
                  const Divider(height: 32),
                  if (_userBook != null) ...[
                    Text(
                      'Your Data',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    DropdownButton<ReadingStatus>(
                      value: _status,
                      items: ReadingStatus.values
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _status = val),
                    ),
                    const SizedBox(height: 8),
                    Text('Spice Rating'),
                    Slider(
                      value: _userSpiceRating ?? 0.0,
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      label: (_userSpiceRating ?? 0.0).toStringAsFixed(1),
                      onChanged: (val) =>
                          setState(() => _userSpiceRating = val),
                    ),
                    Text('Emotional Intensity'),
                    Slider(
                      value: _userEmotionalRating ?? 0.0,
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      label: (_userEmotionalRating ?? 0.0).toStringAsFixed(1),
                      onChanged: (val) =>
                          setState(() => _userEmotionalRating = val),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Your Notes',
                      ),
                      minLines: 1,
                      maxLines: 5,
                      controller: TextEditingController(text: _userNotes ?? '')
                        ..selection = TextSelection.collapsed(
                          offset: (_userNotes ?? '').length,
                        ),
                      onChanged: (val) => _userNotes = val,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveUserRating,
                      child: const Text('Save'),
                    ),
                  ] else ...[
                    const Text('This book is not in your library.'),
                  ],
                ],
              ),
            ),
    );
  }
}
