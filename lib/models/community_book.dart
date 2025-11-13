// lib/models/community_book.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a book from the community database (/books collection)
/// These are pre-seeded books that all users can discover and add to their personal library
class CommunityBook {
  final String id;
  final String isbn;
  final String title;
  final List<String> authors;
  final String? imageUrl;
  final String? description;
  final String? publishedDate;
  final int? pageCount;
  final List<String> genres;
  final List<String> cachedTopWarnings;
  final List<String> cachedTropes;
  final double? averageSpice;
  final int ratingCount;
  final bool isPreSeeded;
  final DateTime? createdAt;

  // Community features for discovery
  final double? communityRating; // Average rating from community
  final int? communityRatingCount; // Number of community ratings
  final List<String> trendingTags; // Popular community-added tags
  final double? popularityScore; // Algorithm-generated popularity
  final int? addedToLibrariesCount; // How many users added this book
  final bool isTrending; // Is this book trending this week
  final Map<String, int> tropeVotes; // Community votes on tropes

  const CommunityBook({
    required this.id,
    required this.isbn,
    required this.title,
    required this.authors,
    this.imageUrl,
    this.description,
    this.publishedDate,
    this.pageCount,
    this.genres = const [],
    this.cachedTopWarnings = const [],
    this.cachedTropes = const [],
    this.averageSpice,
    this.ratingCount = 0,
    this.isPreSeeded = false,
    this.createdAt,
    this.communityRating,
    this.communityRatingCount,
    this.trendingTags = const [],
    this.popularityScore,
    this.addedToLibrariesCount,
    this.isTrending = false,
    this.tropeVotes = const {},
  });

  factory CommunityBook.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? parseDate(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is String) return DateTime.tryParse(field);
      return null;
    }

    return CommunityBook(
      id: doc.id,
      isbn: data['isbn'] as String? ?? '',
      title: data['title'] as String? ?? 'Unknown Title',
      authors: List<String>.from(data['authors'] ?? ['Unknown Author']),
      imageUrl: data['imageUrl'] as String?,
      description: data['description'] as String?,
      publishedDate: data['publishedDate'] as String?,
      pageCount: (data['pageCount'] as num?)?.toInt(),
      genres: List<String>.from(data['genres'] ?? []),
      cachedTopWarnings: List<String>.from(data['cachedTopWarnings'] ?? []),
      cachedTropes: List<String>.from(data['cachedTropes'] ?? []),
      averageSpice: (data['averageSpice'] as num?)?.toDouble(),
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      isPreSeeded: data['isPreSeeded'] as bool? ?? false,
      createdAt: parseDate(data['createdAt']),
      // Community features (may not exist in legacy data)
      communityRating: (data['communityRating'] as num?)?.toDouble(),
      communityRatingCount: (data['communityRatingCount'] as num?)?.toInt(),
      trendingTags: List<String>.from(data['trendingTags'] ?? []),
      popularityScore: (data['popularityScore'] as num?)?.toDouble(),
      addedToLibrariesCount: (data['addedToLibrariesCount'] as num?)?.toInt(),
      isTrending: data['isTrending'] as bool? ?? false,
      tropeVotes: Map<String, int>.from(data['tropeVotes'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isbn': isbn,
      'title': title,
      'authors': authors,
      'imageUrl': imageUrl,
      'description': description,
      'publishedDate': publishedDate,
      'pageCount': pageCount,
      'genres': genres,
      'cachedTopWarnings': cachedTopWarnings,
      'cachedTropes': cachedTropes,
      'averageSpice': averageSpice,
      'ratingCount': ratingCount,
      'isPreSeeded': isPreSeeded,
      'createdAt': createdAt?.toIso8601String(),
      'communityRating': communityRating,
      'communityRatingCount': communityRatingCount,
      'trendingTags': trendingTags,
      'popularityScore': popularityScore,
      'addedToLibrariesCount': addedToLibrariesCount,
      'isTrending': isTrending,
      'tropeVotes': tropeVotes,
    };
  }

  /// Social proof text for UI display
  String get socialProofText {
    final List<String> proofs = [];

    if (communityRating != null &&
        communityRatingCount != null &&
        communityRatingCount! > 0) {
      proofs.add(
        '★${communityRating!.toStringAsFixed(1)} ($communityRatingCount reviews)',
      );
    }

    if (addedToLibrariesCount != null && addedToLibrariesCount! > 0) {
      proofs.add('$addedToLibrariesCount readers added this');
    }

    if (isTrending) {
      proofs.add('📈 Trending this week');
    }

    return proofs.join(' • ');
  }

  /// Returns true if this book matches the search query or tropes
  bool matchesSearch(String query, {List<String>? tropeFilter}) {
    final queryLower = query.toLowerCase();

    // Text search
    final titleMatch = title.toLowerCase().contains(queryLower);
    final authorMatch = authors.any(
      (author) => author.toLowerCase().contains(queryLower),
    );
    final genreMatch = genres.any(
      (genre) => genre.toLowerCase().contains(queryLower),
    );
    final tropeMatch = cachedTropes.any(
      (trope) => trope.toLowerCase().contains(queryLower),
    );

    bool textMatches = titleMatch || authorMatch || genreMatch || tropeMatch;

    // Trope filter
    bool tropeMatches = true;
    if (tropeFilter != null && tropeFilter.isNotEmpty) {
      tropeMatches = tropeFilter.any(
        (filterTrope) => cachedTropes.any(
          (bookTrope) =>
              bookTrope.toLowerCase().contains(filterTrope.toLowerCase()),
        ),
      );
    }

    return textMatches && tropeMatches;
  }
}
