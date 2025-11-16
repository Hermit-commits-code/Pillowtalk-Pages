/// Model representing app update information
class AppUpdate {
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final bool
  isRequired; // If true, show blocking dialog; if false, show dismissible banner
  final DateTime releasedAt;

  AppUpdate({
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    this.isRequired = false,
    required this.releasedAt,
  });

  /// Parse from Firestore document
  factory AppUpdate.fromFirestore(Map<String, dynamic> data) {
    return AppUpdate(
      latestVersion: data['latestVersion'] as String? ?? '1.0.0',
      releaseNotes: data['releaseNotes'] as String? ?? '',
      downloadUrl: data['downloadUrl'] as String? ?? '',
      isRequired: data['isRequired'] as bool? ?? false,
      releasedAt: (data['releasedAt'] != null)
          ? DateTime.parse(data['releasedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'latestVersion': latestVersion,
      'releaseNotes': releaseNotes,
      'downloadUrl': downloadUrl,
      'isRequired': isRequired,
      'releasedAt': releasedAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'AppUpdate(v$latestVersion, required=$isRequired, url=$downloadUrl)';
}
