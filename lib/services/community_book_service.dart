// lib/services/community_book_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/community_book.dart';

/// Service for discovering books from the community database
/// Handles querying the shared /books collection for community discovery features
class CommunityBookService {
  static CommunityBookService? _instance;
  static CommunityBookService get instance =>
      _instance ??= CommunityBookService._();

  CommunityBookService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Reference to the shared books collection
  CollectionReference<Map<String, dynamic>> get _booksRef =>
      _firestore.collection('books');

  /// Discover books by mood/search query with advanced filtering
  /// Perfect for "I'm in the mood for werewolf books" workflows
  Future<List<CommunityBook>> discoverBooks({
    String? searchQuery,
    List<String>? genreFilter,
    List<String>? tropeFilter,
    double? minSpice,
    double? maxSpice,
    double? minRating,
    bool trendingOnly = false,
    int limit = 50,
  }) async {
    try {
      Query query = _booksRef.where('isPreSeeded', isEqualTo: true);

      // Apply basic filters at Firestore level when possible
      if (genreFilter != null && genreFilter.isNotEmpty) {
        // Use the first genre for server-side filtering, then client-side filter for others
        query = query.where('genres', arrayContains: genreFilter.first);
      }

      if (tropeFilter != null && tropeFilter.isNotEmpty) {
        // Use the first trope for server-side filtering
        query = query.where('cachedTropes', arrayContains: tropeFilter.first);
      }

      if (minRating != null) {
        query = query.where(
          'communityRating',
          isGreaterThanOrEqualTo: minRating,
        );
      }

      if (trendingOnly) {
        query = query.where('isTrending', isEqualTo: true);
      }

      // Order by popularity/relevance
      query = query.orderBy('popularityScore', descending: true);
      query = query.limit(limit);

      final snapshot = await query.get();
      List<CommunityBook> books = snapshot.docs
          .map((doc) => CommunityBook.fromFirestore(doc))
          .toList();

      // Client-side filtering for complex conditions
      books = books.where((book) {
        // Search query matching
        if (searchQuery != null && searchQuery.isNotEmpty) {
          if (!book.matchesSearch(searchQuery, tropeFilter: tropeFilter)) {
            return false;
          }
        }

        // Genre filtering (if multiple genres)
        if (genreFilter != null && genreFilter.length > 1) {
          bool hasAllGenres = genreFilter.any(
            (genre) => book.genres.any(
              (bookGenre) =>
                  bookGenre.toLowerCase().contains(genre.toLowerCase()),
            ),
          );
          if (!hasAllGenres) return false;
        }

        // Trope filtering (if multiple tropes)
        if (tropeFilter != null && tropeFilter.length > 1) {
          bool hasAllTropes = tropeFilter.any(
            (trope) => book.cachedTropes.any(
              (bookTrope) =>
                  bookTrope.toLowerCase().contains(trope.toLowerCase()),
            ),
          );
          if (!hasAllTropes) return false;
        }

        // Spice level filtering
        if (minSpice != null && (book.averageSpice ?? 0) < minSpice)
          return false;
        if (maxSpice != null && (book.averageSpice ?? 0) > maxSpice)
          return false;

        return true;
      }).toList();

      return books;
    } catch (e) {
      debugPrint('CommunityBookService.discoverBooks failed: $e');
      return [];
    }
  }

  /// Get trending books for the home dashboard
  Future<List<CommunityBook>> getTrendingBooks({int limit = 10}) async {
    return discoverBooks(trendingOnly: true, limit: limit);
  }

  /// Get books by specific trope (perfect for "werewolf books", "enemies to lovers", etc)
  Future<List<CommunityBook>> getBooksByTrope(
    String trope, {
    int limit = 20,
  }) async {
    return discoverBooks(tropeFilter: [trope], limit: limit);
  }

  /// Get highly rated books for discovery
  Future<List<CommunityBook>> getHighlyRatedBooks({
    double minRating = 4.0,
    int limit = 20,
  }) async {
    return discoverBooks(minRating: minRating, limit: limit);
  }

  /// Search books with mood-based queries
  /// Supports natural language like "spicy werewolf romance", "enemies to lovers fantasy"
  Future<List<CommunityBook>> moodSearch(String moodQuery) async {
    // Parse mood query into components
    final query = moodQuery.toLowerCase();
    List<String> detectedTropes = [];
    List<String> detectedGenres = [];
    double? spiceLevel;

    // Trope detection
    if (query.contains('werewolf') || query.contains('wolf')) {
      detectedTropes.add('werewolf');
    }
    if (query.contains('vampire')) {
      detectedTropes.add('vampire');
    }
    if (query.contains('enemies to lovers') ||
        query.contains('enemies-to-lovers')) {
      detectedTropes.add('enemies to lovers');
    }
    if (query.contains('fake dating') || query.contains('fake relationship')) {
      detectedTropes.add('fake dating');
    }
    if (query.contains('grumpy sunshine') ||
        query.contains('grumpy/sunshine')) {
      detectedTropes.add('grumpy sunshine');
    }
    if (query.contains('age gap')) {
      detectedTropes.add('age gap');
    }
    if (query.contains('forced proximity')) {
      detectedTropes.add('forced proximity');
    }

    // Genre detection
    if (query.contains('contemporary')) {
      detectedGenres.add('contemporary');
    }
    if (query.contains('historical')) {
      detectedGenres.add('historical');
    }
    if (query.contains('fantasy')) {
      detectedGenres.add('fantasy');
    }
    if (query.contains('paranormal')) {
      detectedGenres.add('paranormal');
    }

    // Spice level detection
    if (query.contains('spicy') ||
        query.contains('steamy') ||
        query.contains('hot')) {
      spiceLevel = 3.0; // Look for books with spice level 3+
    }

    return discoverBooks(
      searchQuery: moodQuery,
      genreFilter: detectedGenres.isEmpty ? null : detectedGenres,
      tropeFilter: detectedTropes.isEmpty ? null : detectedTropes,
      minSpice: spiceLevel,
      limit: 30,
    );
  }

  /// Get a random sample of community books for discovery
  Future<List<CommunityBook>> getRandomDiscovery({int limit = 15}) async {
    try {
      // Get a larger sample and randomize client-side
      final query = _booksRef.where('isPreSeeded', isEqualTo: true).limit(100);

      final snapshot = await query.get();
      List<CommunityBook> books = snapshot.docs
          .map((doc) => CommunityBook.fromFirestore(doc))
          .toList();

      // Shuffle and take requested amount
      books.shuffle();
      return books.take(limit).toList();
    } catch (e) {
      debugPrint('CommunityBookService.getRandomDiscovery failed: $e');
      return [];
    }
  }

  /// Convert a CommunityBook to UserBook format for adding to personal library
  Map<String, dynamic> toUserBookData(CommunityBook book, String userId) {
    return {
      'userId': userId,
      'bookId': book.id,
      'title': book.title,
      'authors': book.authors,
      'imageUrl': book.imageUrl,
      'description': book.description,
      'genres': book.genres,
      'cachedTopWarnings': book.cachedTopWarnings,
      'cachedTropes': book.cachedTropes,
      'status': 'wantToRead', // Default to want to read
      'dateAdded': DateTime.now().toIso8601String(),
      'ignoreFilters': false,
      'ownership': 'none',
      'userSelectedTropes': <String>[],
      'userContentWarnings': <String>[],
      'pageCount': book.pageCount,
      'publishedDate': book.publishedDate,
      'format': 'paperback', // Default format
      'asin': null, // Community books don't have ASIN by default
    };
  }

  /// Get books similar to a given book (for recommendation)
  Future<List<CommunityBook>> getSimilarBooks(
    CommunityBook book, {
    int limit = 10,
  }) async {
    try {
      // Find books with similar tropes and genres
      List<CommunityBook> similar = [];

      // Look for books with matching tropes
      if (book.cachedTropes.isNotEmpty) {
        for (final trope in book.cachedTropes.take(2)) {
          // Use top 2 tropes
          final tropeBooks = await getBooksByTrope(trope, limit: 5);
          similar.addAll(tropeBooks.where((b) => b.id != book.id));
        }
      }

      // Look for books with matching genres if not enough trope matches
      if (similar.length < limit && book.genres.isNotEmpty) {
        final genreBooks = await discoverBooks(
          genreFilter: [book.genres.first],
          limit: limit,
        );
        similar.addAll(
          genreBooks.where(
            (b) =>
                b.id != book.id &&
                !similar.any((existing) => existing.id == b.id),
          ),
        );
      }

      // Remove duplicates and limit
      final uniqueBooks = <String, CommunityBook>{};
      for (final b in similar) {
        uniqueBooks[b.id] = b;
      }

      return uniqueBooks.values.take(limit).toList();
    } catch (e) {
      debugPrint('CommunityBookService.getSimilarBooks failed: $e');
      return [];
    }
  }
}
