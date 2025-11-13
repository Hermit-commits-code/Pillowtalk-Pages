// lib/models/user_preferences.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentWarningDisplay { showFull, hideAll, onlyHardStops }

enum HardStopsBehavior { autoFilter, showAll, spoilerMode }

enum PrimaryReadFormat { physical, ebook, audiobook, mixed }

class UserPreferences {
  final String userId;

  // Content Warning Display
  final ContentWarningDisplay contentWarningDisplay;

  // Preferred Formats (which formats user wants to see in search/browse)
  final List<String> preferredFormats; // ["physical", "ebook", "audiobook"]

  // Hard Stops Behavior
  final HardStopsBehavior hardStopsBehavior;

  // Review Form Customization (which fields to show when adding books)
  final Map<String, bool>
  reviewFormFields; // e.g., {"spiceRating": true, "tropes": false}

  // Primary Reading Format (for recommendations/analytics)
  final PrimaryReadFormat primaryReadFormat;

  // Privacy Settings
  final bool privacyAllowLibrarianAccess;
  final bool privacyShareTrendingData;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPreferences({
    required this.userId,
    this.contentWarningDisplay = ContentWarningDisplay.showFull,
    this.preferredFormats = const ["physical", "ebook", "audiobook"],
    this.hardStopsBehavior = HardStopsBehavior.autoFilter,
    this.reviewFormFields = const {
      "spiceRating": true,
      "contentWarnings": true,
      "tropes": false,
      "emotionalArc": true,
      "personalNotes": false,
    },
    this.primaryReadFormat = PrimaryReadFormat.mixed,
    this.privacyAllowLibrarianAccess = true,
    this.privacyShareTrendingData = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['userId'] as String? ?? 'unknown',
      contentWarningDisplay: ContentWarningDisplay.values.byName(
        json['contentWarningDisplay'] as String? ?? 'showFull',
      ),
      preferredFormats: List<String>.from(
        json['preferredFormats'] ?? ["physical", "ebook", "audiobook"],
      ),
      hardStopsBehavior: HardStopsBehavior.values.byName(
        json['hardStopsBehavior'] as String? ?? 'autoFilter',
      ),
      reviewFormFields: Map<String, bool>.from(
        json['reviewFormFields'] ?? _defaultReviewFormFields,
      ),
      primaryReadFormat: PrimaryReadFormat.values.byName(
        json['primaryReadFormat'] as String? ?? 'mixed',
      ),
      privacyAllowLibrarianAccess:
          json['privacyAllowLibrarianAccess'] as bool? ?? true,
      privacyShareTrendingData:
          json['privacyShareTrendingData'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'contentWarningDisplay': contentWarningDisplay.name,
      'preferredFormats': preferredFormats,
      'hardStopsBehavior': hardStopsBehavior.name,
      'reviewFormFields': reviewFormFields,
      'primaryReadFormat': primaryReadFormat.name,
      'privacyAllowLibrarianAccess': privacyAllowLibrarianAccess,
      'privacyShareTrendingData': privacyShareTrendingData,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserPreferences copyWith({
    String? userId,
    ContentWarningDisplay? contentWarningDisplay,
    List<String>? preferredFormats,
    HardStopsBehavior? hardStopsBehavior,
    Map<String, bool>? reviewFormFields,
    PrimaryReadFormat? primaryReadFormat,
    bool? privacyAllowLibrarianAccess,
    bool? privacyShareTrendingData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      contentWarningDisplay:
          contentWarningDisplay ?? this.contentWarningDisplay,
      preferredFormats: preferredFormats ?? this.preferredFormats,
      hardStopsBehavior: hardStopsBehavior ?? this.hardStopsBehavior,
      reviewFormFields: reviewFormFields ?? this.reviewFormFields,
      primaryReadFormat: primaryReadFormat ?? this.primaryReadFormat,
      privacyAllowLibrarianAccess:
          privacyAllowLibrarianAccess ?? this.privacyAllowLibrarianAccess,
      privacyShareTrendingData:
          privacyShareTrendingData ?? this.privacyShareTrendingData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const Map<String, bool> _defaultReviewFormFields = {
    "spiceRating": true,
    "contentWarnings": true,
    "tropes": false,
    "emotionalArc": true,
    "personalNotes": false,
  };

  static DateTime? _parseDate(dynamic field) {
    if (field is Timestamp) return field.toDate();
    if (field is String) return DateTime.tryParse(field);
    return null;
  }
}
