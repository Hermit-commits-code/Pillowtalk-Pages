// lib/models/user_book.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ReadingStatus {
  wantToRead,
  reading,
  finished,
}

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
  });

  factory UserBook.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is String) return DateTime.tryParse(field);
      return null;
    }

    return UserBook(
      id: json['id'] as String,
      userId: json['userId'] as String,
      bookId: json['bookId'] as String,
      title: json['title'] as String? ?? 'Unknown Title',
      authors: List<String>.from(json['authors'] ?? []),
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      status: ReadingStatus.values.byName(json['status'] as String? ?? 'wantToRead'),
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
    );
  }
}
