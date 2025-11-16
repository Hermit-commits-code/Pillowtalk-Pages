import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_update.dart';

/// Service for checking app updates and version management.
/// Fetches latest version info from Firestore and compares with current app version.
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _configPath = 'config/appUpdates';

  /// Current app version (cached from package_info_plus)
  String? _currentVersion;

  /// Fetch the current app version
  Future<String> getCurrentAppVersion() async {
    if (_currentVersion != null) return _currentVersion!;

    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;
      return _currentVersion!;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting app version: $e');
      return '1.0.0';
    }
  }

  /// Fetch latest app update info from Firestore
  Future<AppUpdate?> getLatestUpdate() async {
    try {
      final doc = await _firestore.doc(_configPath).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return AppUpdate.fromFirestore(doc.data()!);
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching app update info: $e');
      return null;
    }
  }

  /// Check if an update is available by comparing versions
  /// Returns true if remoteVersion > currentVersion
  bool _isNewerVersion(String remoteVersion, String currentVersion) {
    try {
      final remoteParts = remoteVersion.split('.').map(int.tryParse).toList();
      final currentParts = currentVersion.split('.').map(int.tryParse).toList();

      // Pad shorter version with zeros
      final maxLen = remoteParts.length > currentParts.length
          ? remoteParts.length
          : currentParts.length;
      while (remoteParts.length < maxLen) {
        remoteParts.add(0);
      }
      while (currentParts.length < maxLen) {
        currentParts.add(0);
      }

      // Compare each part
      for (int i = 0; i < maxLen; i++) {
        final remote = remoteParts[i] ?? 0;
        final current = currentParts[i] ?? 0;

        if (remote > current) return true;
        if (remote < current) return false;
      }

      return false; // Versions are equal
    } catch (e) {
      // ignore: avoid_print
      print('Error comparing versions: $e');
      return false;
    }
  }

  /// Check if an update is available (fetches from Firestore and compares)
  Future<AppUpdate?> checkForUpdate() async {
    try {
      final update = await getLatestUpdate();
      if (update == null) return null;

      final currentVersion = await getCurrentAppVersion();

      if (_isNewerVersion(update.latestVersion, currentVersion)) {
        return update;
      }

      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error checking for update: $e');
      return null;
    }
  }

  /// Publish a new app version to Firestore (admin operation)
  /// This would typically be called from a backend service or admin panel
  Future<void> publishUpdate({
    required String version,
    required String releaseNotes,
    required String downloadUrl,
    bool isRequired = false,
  }) async {
    try {
      final update = AppUpdate(
        latestVersion: version,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
        isRequired: isRequired,
        releasedAt: DateTime.now(),
      );

      await _firestore.doc(_configPath).set(update.toFirestore());
      // ignore: avoid_print
      print('Update published: $version');
    } catch (e) {
      // ignore: avoid_print
      print('Error publishing update: $e');
    }
  }
}
