// lib/models/book_model.dart

/// The core book model for Spicy Reads.
///
/// Combines public metadata from Google Books with proprietary, community-driven fields
/// that form the technical MOAT (tropes, spice, warnings, ratings).
class RomanceBook {
  /// Book genre (e.g., 'Contemporary', 'Historical', 'Paranormal')
  final String genre;

  /// List of subgenres (e.g., ['Romantic Suspense', 'Sports'])
  final List<String> subgenres;
  // --- Standard Data (From Google Books API) ---

  /// Unique book ID (Google Books volume ID)
  final String id;

  /// ISBN-13 or ISBN-10 if available, else blank
  final String isbn;

  /// Book title
  final String title;

  /// List of author names
  final List<String> authors;

  /// Cover image URL (may be null)
  final String? imageUrl;

  /// Book description/summary (may be null)
  final String? description;

  /// Publication date (may be null)
  final String? publishedDate;

  /// Number of pages (may be null)
  final int? pageCount;

  // --- Proprietary MOAT Data (Aggregated from /ratings collection) ---

  /// Community-validated tropes (e.g., ['Grumpy Sunshine', 'Mutual Pining'])
  ///
  /// These are aggregated from user ratings and only shown if consensus is reached.
  final List<String> communityTropes;

  /// Average Spice Meter rating (0.0 - 5.0), calculated from user input
  final double avgSpiceOnPage;

  /// Average Emotional Intensity rating (0.0 - 5.0), calculated from user input
  final double avgEmotionalIntensity;

  /// Top content warnings (e.g., ['Dubcon', 'Violence'])
  final List<String> topWarnings;

  /// Optional series name this book belongs to (e.g., "The Dragonriders of Pern")
  final String? seriesName;

  /// Normalized (lower-cased, trimmed) series name for case-insensitive searches
  final String? seriesNameNormalized;

  /// Optional index/number within the series (1-based)
  final int? seriesIndex;

  /// Total number of unique user ratings for this book
  final int totalUserRatings;

  const RomanceBook({
    required this.id,
    required this.isbn,
    required this.title,
    required this.authors,
    this.imageUrl,
    this.description,
    this.publishedDate,
    this.pageCount,
    this.genre = '',
    this.subgenres = const [],
    this.communityTropes = const [],
    this.avgSpiceOnPage = 0.0,
    this.avgEmotionalIntensity = 0.0,
    this.topWarnings = const [],
    this.seriesName,
    this.seriesNameNormalized,
    this.seriesIndex,
    this.totalUserRatings = 0,
  });

  factory RomanceBook.fromJson(Map<String, dynamic> json) {
    return RomanceBook(
      id: json['id'] as String? ?? '',
      isbn: json['isbn'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown Title',
      authors: List<String>.from(json['authors'] ?? []),
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      publishedDate: json['publishedDate'] as String?,
      pageCount: json['pageCount'] as int?,
      genre: json['genre'] as String? ?? '',
      subgenres: List<String>.from(json['subgenres'] ?? []),
      communityTropes: List<String>.from(json['communityTropes'] ?? []),
      avgSpiceOnPage: (json['avgSpiceOnPage'] as num?)?.toDouble() ?? 0.0,
      avgEmotionalIntensity:
          (json['avgEmotionalIntensity'] as num?)?.toDouble() ?? 0.0,
      topWarnings: List<String>.from(json['topWarnings'] ?? []),
      seriesName: json['seriesName'] as String?,
      seriesNameNormalized: json['seriesName_normalized'] as String?,
      seriesIndex: json['seriesIndex'] as int?,
      totalUserRatings: json['totalUserRatings'] as int? ?? 0,
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
      'genre': genre,
      'subgenres': subgenres,
      'communityTropes': communityTropes,
      'avgSpiceOnPage': avgSpiceOnPage,
      'avgEmotionalIntensity': avgEmotionalIntensity,
      'topWarnings': topWarnings,
      'seriesName': seriesName,
      'seriesName_normalized': seriesNameNormalized,
      'seriesIndex': seriesIndex,
      'totalUserRatings': totalUserRatings,
    };
  }

  RomanceBook copyWith({
    String? id,
    String? isbn,
    String? title,
    List<String>? authors,
    String? imageUrl,
    String? description,
    String? publishedDate,
    int? pageCount,
    String? genre,
    List<String>? subgenres,
    List<String>? communityTropes,
    double? avgSpiceOnPage,
    double? avgEmotionalIntensity,
    List<String>? topWarnings,
    String? seriesName,
    String? seriesNameNormalized,
    int? seriesIndex,
    int? totalUserRatings,
  }) {
    return RomanceBook(
      id: id ?? this.id,
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      publishedDate: publishedDate ?? this.publishedDate,
      pageCount: pageCount ?? this.pageCount,
      genre: genre ?? this.genre,
      subgenres: subgenres ?? this.subgenres,
      communityTropes: communityTropes ?? this.communityTropes,
      avgSpiceOnPage: avgSpiceOnPage ?? this.avgSpiceOnPage,
      avgEmotionalIntensity:
          avgEmotionalIntensity ?? this.avgEmotionalIntensity,
      topWarnings: topWarnings ?? this.topWarnings,
      seriesName: seriesName ?? this.seriesName,
      seriesNameNormalized: seriesNameNormalized ?? this.seriesNameNormalized,
      seriesIndex: seriesIndex ?? this.seriesIndex,
      totalUserRatings: totalUserRatings ?? this.totalUserRatings,
    );
  }
}
