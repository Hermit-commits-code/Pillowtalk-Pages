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

  /// User's personal spice rating for this book (0.0 - 5.0, may be null)
  final double? userSpiceRating;

  /// User's personal emotional intensity rating (0.0 - 5.0, may be null)
  final double? userEmotionalRating;

  /// User-selected tropes for this book (for personal tracking)
  final List<String> userSelectedTropes;

  /// User-selected content warnings for this book
  final List<String> userContentWarnings;

  /// User's private notes about this book (may be null)
  final String? userNotes;

  /// Creates a new UserBook record for a user's library.
  const UserBook({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.status,
    this.currentPage = 0,
    this.totalPages,
    required this.dateAdded,
    this.dateStarted,
    this.dateFinished,
    this.userSpiceRating,
    this.userEmotionalRating,
    this.userSelectedTropes = const [],
    this.userContentWarnings = const [],
    this.userNotes,
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
      userSpiceRating: (json['userSpiceRating'] as num?)?.toDouble(),
      userEmotionalRating: (json['userEmotionalRating'] as num?)?.toDouble(),
      userSelectedTropes: List<String>.from(json['userSelectedTropes'] ?? []),
      userContentWarnings: List<String>.from(json['userContentWarnings'] ?? []),
      userNotes: json['userNotes'] as String?,
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
      'userSpiceRating': userSpiceRating,
      'userEmotionalRating': userEmotionalRating,
      'userSelectedTropes': userSelectedTropes,
      'userContentWarnings': userContentWarnings,
      'userNotes': userNotes,
    };
  }
}
