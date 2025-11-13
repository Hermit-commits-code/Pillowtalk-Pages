// lib/models/user_book.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ReadingStatus { wantToRead, reading, finished }

enum BookOwnership { none, physical, digital, both, kindleUnlimited }

enum BookFormat { paperback, hardcover, ebook, audiobook }

class UserBook {
  final String id;
  final String userId;
  final String bookId;
  final String title;
  final List<String> authors;
  final String? imageUrl;
  final String? description;
  final ReadingStatus status;
  final List<String> genres;
  final DateTime? dateAdded;
  final DateTime? dateStarted;
  final DateTime? dateFinished;
  final double? spiceOverall;
  final String? spiceIntensity;
  final double? emotionalArc;
  final List<String> userSelectedTropes;
  final List<String> userContentWarnings;
  final String? userNotes;
  final String? seriesName;
  final int? seriesIndex;
  final List<String> cachedTopWarnings;
  final List<String> cachedTropes;
  final bool ignoreFilters;
  final BookOwnership ownership;
  final int? personalStars; // 1-5 user-only personal rating
  final int? pageCount;
  final DateTime? publishedDate;
  final String? publisher;
  final BookFormat format;
  final String? narrator; // For audiobooks
  final int? runtimeMinutes; // Total audiobook runtime in minutes
  final int? listeningProgressMinutes; // Minutes listened so far

  const UserBook({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.title,
    required this.authors,
    this.imageUrl,
    this.description,
    required this.status,
    this.genres = const [],
    this.ignoreFilters = false,
    this.dateAdded,
    this.dateStarted,
    this.dateFinished,
    this.spiceOverall,
    this.spiceIntensity,
    this.emotionalArc,
    this.userSelectedTropes = const [],
    this.userContentWarnings = const [],
    this.userNotes,
    this.seriesName,
    this.seriesIndex,
    this.cachedTopWarnings = const [],
    this.cachedTropes = const [],
    this.ownership = BookOwnership.none,
    this.personalStars,
    this.pageCount,
    this.publishedDate,
    this.publisher,
    this.format = BookFormat.paperback,
    this.narrator,
    this.runtimeMinutes,
    this.listeningProgressMinutes,
  });

  factory UserBook.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is String) return DateTime.tryParse(field);
      return null;
    }

    return UserBook(
      id: json['id'] as String? ?? 'unknown_id',
      userId: json['userId'] as String? ?? 'unknown_user',
      bookId: json['bookId'] as String? ?? 'unknown_book',
      title: json['title'] as String? ?? 'Unknown Title',
      authors: List<String>.from(json['authors'] ?? []),
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      status: ReadingStatus.values.byName(
        json['status'] as String? ?? 'wantToRead',
      ),
      genres: List<String>.from(json['genres'] ?? []),
      ignoreFilters: json['ignoreFilters'] as bool? ?? false,
      dateAdded: parseDate(json['dateAdded']),
      dateStarted: parseDate(json['dateStarted']),
      dateFinished: parseDate(json['dateFinished']),
      spiceOverall: (json['spiceOverall'] as num?)?.toDouble(),
      spiceIntensity: json['spiceIntensity'] as String?,
      emotionalArc: (json['emotionalArc'] as num?)?.toDouble(),
      userSelectedTropes: List<String>.from(json['userSelectedTropes'] ?? []),
      userContentWarnings: List<String>.from(json['userContentWarnings'] ?? []),
      userNotes: json['userNotes'] as String?,
      seriesName: json['seriesName'] as String?,
      seriesIndex: json['seriesIndex'] as int?,
      cachedTopWarnings: List<String>.from(json['cachedTopWarnings'] ?? []),
      cachedTropes: List<String>.from(json['cachedTropes'] ?? []),
      ownership: BookOwnership.values.byName(
        json['ownership'] as String? ?? 'none',
      ),
      personalStars: (json['personalStars'] as num?)?.toInt(),
      pageCount: (json['pageCount'] as num?)?.toInt(),
      publishedDate: parseDate(json['publishedDate']),
      publisher: json['publisher'] as String?,
      format: BookFormat.values.byName(
        json['format'] as String? ?? 'paperback',
      ),
      narrator: json['narrator'] as String?,
      runtimeMinutes: (json['runtimeMinutes'] as num?)?.toInt(),
      listeningProgressMinutes: (json['listeningProgressMinutes'] as num?)
          ?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bookId': bookId,
      'title': title,
      'authors': authors,
      'imageUrl': imageUrl,
      'description': description,
      'status': status.name,
      'genres': genres,
      'ignoreFilters': ignoreFilters,
      'dateStarted': dateStarted?.toIso8601String(),
      'dateFinished': dateFinished?.toIso8601String(),
      'spiceOverall': spiceOverall,
      'spiceIntensity': spiceIntensity,
      'emotionalArc': emotionalArc,
      'userSelectedTropes': userSelectedTropes,
      'userContentWarnings': userContentWarnings,
      'userNotes': userNotes,
      'seriesName': seriesName,
      'seriesIndex': seriesIndex,
      'cachedTopWarnings': cachedTopWarnings,
      'cachedTropes': cachedTropes,
      'ownership': ownership.name,
      'personalStars': personalStars,
      'pageCount': pageCount,
      'publishedDate': publishedDate?.toIso8601String(),
      'publisher': publisher,
      'format': format.name,
      'narrator': narrator,
      'runtimeMinutes': runtimeMinutes,
      'listeningProgressMinutes': listeningProgressMinutes,
    };
  }

  UserBook copyWith({
    String? id,
    String? userId,
    String? bookId,
    String? title,
    List<String>? authors,
    String? imageUrl,
    String? description,
    ReadingStatus? status,
    List<String>? genres,
    bool? ignoreFilters,
    DateTime? dateAdded,
    DateTime? dateStarted,
    DateTime? dateFinished,
    double? spiceOverall,
    String? spiceIntensity,
    double? emotionalArc,
    List<String>? userSelectedTropes,
    List<String>? userContentWarnings,
    String? userNotes,
    String? seriesName,
    int? seriesIndex,
    List<String>? cachedTopWarnings,
    List<String>? cachedTropes,
    BookOwnership? ownership,
    int? personalStars,
    int? pageCount,
    DateTime? publishedDate,
    String? publisher,
    BookFormat? format,
    String? narrator,
    int? runtimeMinutes,
    int? listeningProgressMinutes,
  }) {
    return UserBook(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      status: status ?? this.status,
      genres: genres ?? this.genres,
      ignoreFilters: ignoreFilters ?? this.ignoreFilters,
      dateAdded: dateAdded ?? this.dateAdded,
      dateStarted: dateStarted ?? this.dateStarted,
      dateFinished: dateFinished ?? this.dateFinished,
      spiceOverall: spiceOverall ?? this.spiceOverall,
      spiceIntensity: spiceIntensity ?? this.spiceIntensity,
      emotionalArc: emotionalArc ?? this.emotionalArc,
      userSelectedTropes: userSelectedTropes ?? this.userSelectedTropes,
      userContentWarnings: userContentWarnings ?? this.userContentWarnings,
      userNotes: userNotes ?? this.userNotes,
      seriesName: seriesName ?? this.seriesName,
      seriesIndex: seriesIndex ?? this.seriesIndex,
      cachedTopWarnings: cachedTopWarnings ?? this.cachedTopWarnings,
      cachedTropes: cachedTropes ?? this.cachedTropes,
      ownership: ownership ?? this.ownership,
      personalStars: personalStars ?? this.personalStars,
      pageCount: pageCount ?? this.pageCount,
      publishedDate: publishedDate ?? this.publishedDate,
      publisher: publisher ?? this.publisher,
      format: format ?? this.format,
      narrator: narrator ?? this.narrator,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      listeningProgressMinutes:
          listeningProgressMinutes ?? this.listeningProgressMinutes,
    );
  }
}
