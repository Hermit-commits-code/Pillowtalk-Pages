import 'package:cloud_firestore/cloud_firestore.dart';

/// Friend relationship model
/// Represents a connection between two users
class Friend {
  final String friendId; // UID of the friend
  final String status; // 'pending', 'accepted', 'blocked'
  final DateTime createdAt;
  final DateTime? acceptedAt;

  // Sharing preferences (what this friend can see)
  final bool sharingReadingProgress;
  final bool sharingSpiceRatings;
  final bool sharingHardStops;
  final bool sharingReviews;

  Friend({
    required this.friendId,
    required this.status, // 'pending' | 'accepted' | 'blocked'
    required this.createdAt,
    this.acceptedAt,
    this.sharingReadingProgress = true,
    this.sharingSpiceRatings = true,
    this.sharingHardStops = false, // Hard stops never shared by default
    this.sharingReviews = true,
  });

  /// Convert Firestore document to Friend object
  factory Friend.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friend(
      friendId: doc.id,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      sharingReadingProgress: data['sharing']?['readingProgress'] ?? true,
      sharingSpiceRatings: data['sharing']?['spiceRatings'] ?? true,
      sharingHardStops: data['sharing']?['hardStops'] ?? false,
      sharingReviews: data['sharing']?['reviews'] ?? true,
    );
  }

  /// Convert Friend object to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'sharing': {
        'readingProgress': sharingReadingProgress,
        'spiceRatings': sharingSpiceRatings,
        'hardStops': sharingHardStops,
        'reviews': sharingReviews,
      },
    };
  }

  /// Create a copy with modified fields
  Friend copyWith({
    String? friendId,
    String? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    bool? sharingReadingProgress,
    bool? sharingSpiceRatings,
    bool? sharingHardStops,
    bool? sharingReviews,
  }) {
    return Friend(
      friendId: friendId ?? this.friendId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      sharingReadingProgress:
          sharingReadingProgress ?? this.sharingReadingProgress,
      sharingSpiceRatings: sharingSpiceRatings ?? this.sharingSpiceRatings,
      sharingHardStops: sharingHardStops ?? this.sharingHardStops,
      sharingReviews: sharingReviews ?? this.sharingReviews,
    );
  }
}
