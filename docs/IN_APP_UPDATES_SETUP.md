# Setting Up the In-App Update System

## Quick Start

### 1. Create the Firestore Config Document

In your Firebase Console, navigate to **Cloud Firestore** and create the document at path `config/appUpdates`:

**Collection:** `config`  
**Document ID:** `appUpdates`

**Document Content:**
```json
{
  "latestVersion": "1.5.2",
  "releaseNotes": "In-app update notifications now available. Bug fixes and improvements.",
  "downloadUrl": "https://github.com/Hermit-commits-code/Spicy-Reads/releases/download/v1.5.2/app-release.apk",
  "isRequired": false,
  "releasedAt": "2025-11-15T12:00:00.000Z"
}
```

### 2. Firestore Security Rules

Ensure your security rules allow read access to the config document. Example:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all authenticated users to read config
    match /config/{document=**} {
      allow read: if request.auth != null;
    }
  }
}
```

### 3. Test the Flow

1. **Build and run the app:**
   ```bash
   flutter run
   ```

2. **On first launch**, the app checks `config/appUpdates` and:
   - If `latestVersion > currentVersion` and `isRequired: false` → shows dismissible banner
   - If `latestVersion > currentVersion` and `isRequired: true` → shows blocking dialog
   - If versions are equal → no notification

3. **Tap the download link** to test URL launching (will open in browser)

### 4. Publishing Updates

When you release a new version (e.g., v1.5.3):

1. **Bump version in `pubspec.yaml`:**
   ```yaml
   version: 1.5.3+3
   ```

2. **Build release APK:**
   ```bash
   flutter build apk --release
   ```

3. **Create GitHub release:**
   ```bash
   gh release create v1.5.3 build/app/outputs/flutter-apk/app-release.apk \
     --title "Spicy Reads v1.5.3" \
     --notes "Release notes here..."
   ```

4. **Update Firestore config:**
   ```
   latestVersion: "1.5.3"
   downloadUrl: "https://github.com/Hermit-commits-code/Spicy-Reads/releases/download/v1.5.3/app-release.apk"
   releaseNotes: "Bug fixes and new features"
   isRequired: false  (or true for critical fixes)
   releasedAt: (current timestamp)
   ```

5. Users will see the update notification on next app launch!

## Important Notes

### Version Format
- Use semantic versioning: `X.Y.Z` (e.g., `1.5.2`)
- The system compares versions numerically (1.10.0 > 1.9.0 ✓)

### Download URLs
- **GitHub Releases:** `https://github.com/{owner}/{repo}/releases/download/{tag}/{filename}`
- **Direct APK:** Any publicly accessible URL to the `.apk` file
- **App Stores:** Link to Google Play, F-Droid, Amazon Appstore, etc.

### Optional vs Required Updates
- **`isRequired: false`** (default)
  - Dismissible banner at the top
  - User can continue using the app
  - Useful for feature updates or minor improvements
  
- **`isRequired: true`**
  - Blocking dialog (non-dismissible)
  - Prevents app usage until user taps download
  - Reserved for critical security fixes or breaking bugs

### Testing with Different Versions

**To test an update prompt:**
1. Set Firestore `latestVersion` to something higher than current `pubspec.yaml` version
2. Restart app
3. Banner/dialog should appear

**To test no update available:**
1. Set Firestore `latestVersion` equal to `pubspec.yaml` version
2. Restart app
3. No notification should appear

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Update notification doesn't appear | Check Firestore rules allow read access; verify `config/appUpdates` doc exists |
| Download link doesn't work | Verify URL is publicly accessible; test in browser |
| Wrong version comparison | Ensure semantic versioning format (X.Y.Z); no letters or extra dots |
| Banner appears indefinitely | Set `latestVersion` equal to app version to dismiss |

## Example Update Sequence

```
User has v1.5.0 installed
    ↓
App checks Firestore → finds v1.5.2 available
    ↓
Firestore has isRequired: false
    ↓
Dismissible banner appears: "New version available (v1.5.2)"
    ↓
User can tap "Download" or dismiss
    ↓
On next app restart, check runs again (unless user already updated)
```

## References

- Full documentation: `docs/IN_APP_UPDATES.md`
- UpdateService: `lib/services/update_service.dart`
- UI Widgets: `lib/widgets/update_notification.dart`
- Integration: `lib/main.dart` (UpdateCheckWrapper)
