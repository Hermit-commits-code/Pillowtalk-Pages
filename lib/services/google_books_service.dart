// lib/services/google_books_service.dart

import 'package:dio/dio.dart';

import '../models/book_model.dart';

/// Service for searching and fetching book data from the Google Books API.
///
/// This service normalizes Google Books data into the proprietary RomanceBook model.
class GoogleBooksService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://www.googleapis.com/books/v1',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  /// Searches for books matching the given query string.
  /// Returns a list of RomanceBook objects with public metadata only.
  Future<List<RomanceBook>> searchBooks(String query) async {
    try {
      final response = await _dio.get(
        '/volumes',
        queryParameters: {'q': query, 'maxResults': 20, 'printType': 'books'},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        return items.map((item) => _parseBookFromGoogleBooks(item)).toList();
      } else {
        throw Exception('Failed to search books: [${response.statusCode}]');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  /// Fetches a single book by its Google Books volume ID.
  /// Returns a RomanceBook or null if not found.
  Future<RomanceBook?> getBookById(String googleBooksId) async {
    try {
      final response = await _dio.get('/volumes/$googleBooksId');
      if (response.statusCode == 200) {
        return _parseBookFromGoogleBooks(response.data);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  /// Helper to parse a Google Books API item into a RomanceBook.
  RomanceBook _parseBookFromGoogleBooks(Map<String, dynamic> item) {
    final volumeInfo = item['volumeInfo'] as Map<String, dynamic>? ?? {};
    final industryIdentifiers =
        volumeInfo['industryIdentifiers'] as List<dynamic>? ?? [];
    // Extract ISBN
    String isbn = '';
    for (final identifier in industryIdentifiers) {
      if (identifier['type'] == 'ISBN_13' || identifier['type'] == 'ISBN_10') {
        isbn = identifier['identifier'] as String;
        break;
      }
    }
    // Extract image URL (prefer high resolution)
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>? ?? {};
    String? imageUrl =
        imageLinks['extraLarge'] as String? ??
        imageLinks['large'] as String? ??
        imageLinks['medium'] as String? ??
        imageLinks['thumbnail'] as String?;
    // Convert HTTP to HTTPS for image URLs
    if (imageUrl != null && imageUrl.startsWith('http:')) {
      imageUrl = imageUrl.replaceFirst('http:', 'https:');
    }
    return RomanceBook(
      id: item['id'] as String,
      isbn: isbn,
      title: volumeInfo['title'] as String? ?? 'Unknown Title',
      authors: List<String>.from(volumeInfo['authors'] ?? ['Unknown Author']),
      imageUrl: imageUrl,
      description: volumeInfo['description'] as String?,
      publishedDate: volumeInfo['publishedDate'] as String?,
      pageCount: volumeInfo['pageCount'] as int?,
      // MOAT fields are initialized as empty - will be populated from Firestore
      communityTropes: const [],
      avgSpiceOnPage: 0.0,
      avgEmotionalIntensity: 0.0,
      topWarnings: const [],
      totalUserRatings: 0,
    );
  }
}
