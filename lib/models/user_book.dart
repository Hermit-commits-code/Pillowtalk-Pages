// lib/models/user_book.dart

/// Enum for user reading status
enum ReadingStatus {
  /// User wants to read this book
  wantToRead,

  /// User is currently reading this book
  reading,

  /// User has finished reading this book
  finished,
}

/// User-specific tracking for a book in the user's library.
///
/// Stores reading status, progress, user ratings, notes, and user-selected tropes/warnings.
class UserBook {
  /// Book genre (e.g., 'Contemporary', 'Historical', 'Paranormal')
  final String genre;

  /// List of subgenres (e.g., ['Romantic Suspense', 'Sports'])
  final List<String> subgenres;

  /// Unique ID for this user-book record (e.g., Firestore doc ID)
  final String id;

  /// The user's UID (owner of this record)
  final String userId;

  /// The book's ID (matches RomanceBook.id)
  final String bookId;

  /// Current reading status (want to read, reading, finished)
  final ReadingStatus status;

  /// Current page the user is on (default 0)
  final int currentPage;

  /// Total number of pages in the book (may be null)
  final int? totalPages;

  /// Date this book was added to the user's library
  final DateTime dateAdded;

  /// Date the user started reading (may be null)
  final DateTime? dateStarted;

  /// Date the user finished reading (may be null)
  final DateTime? dateFinished;

  /// S: Sensual Content (On-Page Intimacy)
  final double? spiceSensual;

  /// P: Power/Plot Dynamics
  final double? spicePower;

  /// I: Intensity (Emotional Impact)
  final double? spiceIntensity;

  /// C: Communication/Consent
  final double? spiceConsent;

  /// E: Emotional Resonance
  final double? spiceEmotional;

  /// User-selected tropes for this book (for personal tracking)
  final List<String> userSelectedTropes;

  /// User-selected content warnings for this book
  final List<String> userContentWarnings;

  /// User's private notes about this book (may be null)
  final String? userNotes;

  /// Cached top warnings from the community aggregate (optional)
  final List<String> cachedTopWarnings;

  /// Cached community tropes from the community aggregate (optional)
  final List<String> cachedTropes;

  /// If true, this userBook will ignore global filters and always be shown
  /// in the user's library unless explicitly removed.
  final bool ignoreFilters;

  /// Optional series name for this book in the user's library
  final String? seriesName;

  /// Normalized (lower-cased, trimmed) series name for easier searching
  final String? seriesNameNormalized;

  /// Optional book number in series (1-based)
  final int? seriesIndex;

  /// Creates a new UserBook record for a user's library.
  const UserBook({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    this.ignoreFilters = false,
    this.currentPage = 0,
    this.totalPages,
    required this.dateAdded,
    this.dateStarted,
    this.dateFinished,
    this.spiceSensual,
    this.spicePower,
    this.spiceIntensity,
    this.spiceConsent,
    this.spiceEmotional,
    this.userSelectedTropes = const [],
    this.userContentWarnings = const [],
    this.userNotes,
    this.genre = '',
    this.subgenres = const [],
    this.seriesName,
    this.seriesNameNormalized,
    this.seriesIndex,
    this.cachedTopWarnings = const [],
    this.cachedTropes = const [],
  });

  factory UserBook.fromJson(Map<String, dynamic> json) {
    return UserBook(
      id: json['id'] as String,
      userId: json['userId'] as String,
      bookId: json['bookId'] as String,
      status: ReadingStatus.values.byName(json['status'] as String),
      currentPage: json['currentPage'] as int? ?? 0,
      totalPages: json['totalPages'] as int?,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      dateStarted: json['dateStarted'] != null
          ? DateTime.parse(json['dateStarted'] as String)
          : null,
      dateFinished: json['dateFinished'] != null
          ? DateTime.parse(json['dateFinished'] as String)
          : null,
      spiceSensual: (json['spiceSensual'] as num?)?.toDouble(),
      spicePower: (json['spicePower'] as num?)?.toDouble(),
      spiceIntensity: (json['spiceIntensity'] as num?)?.toDouble(),
      spiceConsent: (json['spiceConsent'] as num?)?.toDouble(),
      spiceEmotional: (json['spiceEmotional'] as num?)?.toDouble(),
      userSelectedTropes: List<String>.from(json['userSelectedTropes'] ?? []),
      userContentWarnings: List<String>.from(json['userContentWarnings'] ?? []),
      userNotes: json['userNotes'] as String?,
      genre: json['genre'] as String? ?? '',
      subgenres: List<String>.from(json['subgenres'] ?? []),
      seriesName: json['seriesName'] as String?,
      seriesIndex: json['seriesIndex'] as int?,
      // support legacy and normalized fields
      seriesNameNormalized: json['seriesName_normalized'] as String?,
      cachedTopWarnings: List<String>.from(json['cachedTopWarnings'] ?? []),
      cachedTropes: List<String>.from(json['cachedTropes'] ?? []),
      ignoreFilters: json['ignoreFilters'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bookId': bookId,
      'status': status.name,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'dateAdded': dateAdded.toIso8601String(),
      'dateStarted': dateStarted?.toIso8601String(),
      'dateFinished': dateFinished?.toIso8601String(),
      'spiceSensual': spiceSensual,
      'spicePower': spicePower,
      'spiceIntensity': spiceIntensity,
      'spiceConsent': spiceConsent,
      'spiceEmotional': spiceEmotional,
      'userSelectedTropes': userSelectedTropes,
      'userContentWarnings': userContentWarnings,
      'userNotes': userNotes,
      'genre': genre,
      'subgenres': subgenres,
      'seriesName': seriesName,
      'seriesName_normalized': seriesNameNormalized,
      'seriesIndex': seriesIndex,
      'cachedTopWarnings': cachedTopWarnings,
      'cachedTropes': cachedTropes,
      'ignoreFilters': ignoreFilters,
    };
  }
}
