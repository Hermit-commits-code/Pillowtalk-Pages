import 'package:cloud_firestore/cloud_firestore.dart';

/// A lightweight model representing a user-created list (reading list / shelf).
class UserList {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final bool isPrivate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> bookIds; // stores userBook.id values

  const UserList({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.isPrivate = false,
    this.createdAt,
    this.updatedAt,
    this.bookIds = const [],
  });

  factory UserList.fromJson(Map<String, dynamic> json) {
    DateTime? parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return UserList(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      isPrivate: json['isPrivate'] as bool? ?? false,
      createdAt: parseTs(json['createdAt']),
      updatedAt: parseTs(json['updatedAt']),
      bookIds: List<String>.from(json['bookIds'] ?? <dynamic>[]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'isPrivate': isPrivate,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'bookIds': bookIds,
    };
  }

  UserList copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? bookIds,
  }) {
    return UserList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookIds: bookIds ?? this.bookIds,
    );
  }
}
