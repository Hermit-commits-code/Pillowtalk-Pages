# In-App Update Notification System

## Overview

The in-app update notification system allows users to be notified about new app versions and manually download updates without relying on the Google Play Store. This is particularly useful for distributing updates through alternative channels like GitHub Releases.

## Architecture

### Components

1. **`UpdateService`** (`lib/services/update_service.dart`)

   - Fetches latest version info from Firestore (`config/appUpdates` document)
   - Compares current app version (via `package_info_plus`) with remote version
   - Provides version comparison logic supporting semantic versioning (e.g., 1.5.1)

2. **`AppUpdate` Model** (`lib/models/app_update.dart`)

   - Represents update information: version, release notes, download URL, requirement flag
   - Serializes to/from Firestore documents

3. **UI Widgets** (`lib/widgets/update_notification.dart`)

   - `UpdateNotificationBanner`: Dismissible top banner for optional updates
   - `UpdateRequiredDialog`: Blocking dialog for required updates (non-dismissible)

4. **`UpdateCheckWrapper`** (`lib/widgets/update_check_wrapper.dart`)
   - Wraps the root app to check for updates on initialization
   - Displays appropriate UI (banner or dialog) based on update availability and requirement flag

### Integration

The `UpdateCheckWrapper` is integrated in `lib/main.dart` around the `AppRoot` widget, ensuring update checks happen early in the app lifecycle.

## Firestore Setup

Create a document at `config/appUpdates` with the following structure:

```json
{
  "latestVersion": "1.5.2",
  "releaseNotes": "Fixed community view bugs and improved performance",
  "downloadUrl": "https://github.com/Hermit-commits-code/Spicy-Reads/releases/download/v1.5.2/app-release.apk",
  "isRequired": false,
  "releasedAt": "2025-11-15T10:00:00.000Z"
}
```

### Field Descriptions

- **`latestVersion`** (string): The latest app version in semantic versioning format (e.g., "1.5.1")
- **`releaseNotes`** (string): User-facing summary of changes (displayed in notification)
- **`downloadUrl`** (string): Direct link to the APK or app store listing
- **`isRequired`** (boolean):
  - If `true`: Shows blocking dialog; user must download to proceed
  - If `false`: Shows dismissible banner; user can continue using the app
- **`releasedAt`** (timestamp): When the version was released (ISO 8601 string or Firestore Timestamp)

## Usage

### For Users

1. **Optional Updates (isRequired: false)**

   - Top banner appears with update info and "Download" button
   - User can dismiss the banner to continue using the app
   - Banner reappears on next app restart

2. **Required Updates (isRequired: true)**
   - Full-screen dialog appears blocking further navigation
   - User must tap "Download Update" to proceed
   - Dialog is non-dismissible (no close button or back navigation)

### For Developers

#### Publishing a New Update

Use the admin function in `UpdateService` or directly update Firestore:

```dart
// Option 1: Using UpdateService (requires admin credentials)
final updateService = UpdateService();
await updateService.publishUpdate(
  version: '1.5.2',
  releaseNotes: 'New features and bug fixes',
  downloadUrl: 'https://github.com/Hermit-commits-code/Spicy-Reads/releases/download/v1.5.2/app-release.apk',
  isRequired: false,
);

// Option 2: Direct Firestore update (via Firebase Console or Admin SDK)
db.collection('config').doc('appUpdates').set({
  'latestVersion': '1.5.2',
  'releaseNotes': 'Bug fixes and improvements',
  'downloadUrl': 'https://github.com/.../app-release.apk',
  'isRequired': false,
  'releasedAt': DateTime.now().toIso8601String(),
});
```

#### Testing Updates

To test the update flow locally:

1. Temporarily update `config/appUpdates` in Firestore with a newer version
2. Restart the app
3. Verify the banner/dialog appears with correct info
4. Tap the download link (will open in browser)

## Version Comparison

The system uses semantic versioning (X.Y.Z format):

```
1.5.1 > 1.5.0       ✓ Update available
1.6.0 > 1.5.99      ✓ Update available
2.0.0 > 1.9.9       ✓ Update available
1.5.1 = 1.5.1       ✗ No update
```

Invalid versions default to "1.0.0" and are treated conservatively.

## Download Handling

When users tap the "Download" button:

1. The download URL is launched in an external browser/app
2. For GitHub Releases: Users are taken directly to the release page
3. For app stores: Users are taken to the store listing
4. Error handling gracefully handles cases where the URL cannot be opened

## Best Practices

1. **Version Consistency**

   - Keep `pubspec.yaml` version and Firestore `latestVersion` in sync
   - Increment version before building release APKs

2. **Release Notes**

   - Keep concise (~140 characters for banner display)
   - Highlight critical fixes or new features
   - Prefix with emoji for quick visual scanning (e.g., "🐛 Bugs fixed, 🚀 Performance improved")

3. **Download URLs**

   - Use GitHub Releases for open distribution
   - Ensure URLs are publicly accessible
   - Test links before publishing

4. **Required vs Optional**
   - Mark as `isRequired: true` only for critical security fixes or breaking bugs
   - Default to `isRequired: false` for routine updates
   - Communicate clearly if making an update required

## Privacy & Security

- Version checks happen on app start; minimal network overhead
- Firestore security rules should allow read access to `config/appUpdates` for all users
- Download URLs are validated using `url_launcher` before opening
- No user data is transmitted during update checks

## Future Enhancements

- Batch update checks (not every app start)
- Update scheduling (e.g., only show banner on weekends)
- Changelog display (expanded view)
- Beta/staging channel support
- Delta updates (only download changed files)
