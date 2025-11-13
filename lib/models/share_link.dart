import 'package:cloud_firestore/cloud_firestore.dart';

/// Share link for temporary access to user data
/// Token-based, expiring, revocable
class ShareLink {
  final String shareId; // Unique token
  final String ownerId; // UID of the user sharing
  final String type; // 'reading-progress' | 'reading-goal' | 'spicy-tbr'
  final DateTime createdAt;
  final DateTime expiresAt;
  final int accessCount;
  final bool revoked;
  final Map<String, dynamic>? metadata; // Additional data (reading stats, etc.)

  ShareLink({
    required this.shareId,
    required this.ownerId,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
    this.accessCount = 0,
    this.revoked = false,
    this.metadata,
  });

  /// Check if share link is still valid
  bool get isValid => !revoked && DateTime.now().isBefore(expiresAt);

  /// Convert Firestore document to ShareLink object
  factory ShareLink.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShareLink(
      shareId: doc.id,
      ownerId: data['ownerId'] ?? '',
      type: data['type'] ?? 'reading-progress',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      accessCount: data['accessCount'] ?? 0,
      revoked: data['revoked'] ?? false,
      metadata: data['metadata'],
    );
  }

  /// Convert ShareLink object to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'accessCount': accessCount,
      'revoked': revoked,
      'metadata': metadata,
    };
  }

  /// Create a copy with modified fields
  ShareLink copyWith({
    String? shareId,
    String? ownerId,
    String? type,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? accessCount,
    bool? revoked,
    Map<String, dynamic>? metadata,
  }) {
    return ShareLink(
      shareId: shareId ?? this.shareId,
      ownerId: ownerId ?? this.ownerId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      accessCount: accessCount ?? this.accessCount,
      revoked: revoked ?? this.revoked,
      metadata: metadata ?? this.metadata,
    );
  }
}
