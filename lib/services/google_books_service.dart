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
        return items.map((item) => RomanceBook.fromGoogleBooks(item)).toList();
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
        return RomanceBook.fromGoogleBooks(response.data);
      }
      return null;
    } on DioException {
      return null;
    }
  }
}
