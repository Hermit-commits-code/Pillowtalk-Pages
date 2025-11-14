# Changelog

All notable changes to Spicy Reads will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2025-11-13

### 🔧 Fixed

- **Firestore security rules**: Added rules for `affiliate_clicks` collection (user can write their own, read by user or admins; read-only for audit), `users/{userId}/friends` (per-user read/write), and `app_config` (authenticated read, admin write).
- **Social framework**: Friends and share links screens now have proper Firestore permissions.

### 📝 Notes

- Firestore rules must be deployed via Firebase Console or CLI for changes to take effect.

---

## [1.1.0] - 2025-11-13

### ✨ Added

- **Runtime analytics toggle**: Per-user analytics opt-out persisted in Profile settings (`users/{uid}.analyticsEnabled`).
- **Affiliate tracking with multi-layer guards**: Audible affiliate links are logged to Firebase Analytics and persisted to Firestore `affiliate_clicks` collection.
  - Compile-time guard: `--dart-define=DISABLE_ANALYTICS=true` disables all analytics.
  - Runtime per-user preference: Users can opt-out via Profile toggle.
  - Owner-only mode (optional): Analytics restricted to owner accounts via `lib/config/admin.dart` and runtime Firestore override.
- **Owner-only analytics enforcement**: Configurable static owner UID/email lists with runtime Firestore override at `app_config/admin.restrictAnalyticsToOwners`.
- **Developer Tools enhancements**: Added "View Affiliate Clicks" (read-only), "Show My UID", and owner-only analytics toggle in Developer Tools screen.
- **Admin config**: `lib/config/admin.dart` with `kRestrictAnalyticsToOwners`, `kOwnerAnalyticsUids`, and `kOwnerAnalyticsEmails`.
- **Unit tests**: `test/audible_affiliate_owner_test.dart` validates owner-only analytics config and AudibleAffiliateService behavior.
- **Social tab**: Added Social tab to bottom navigation bar, exposing Friends, Friend Settings, and Share Links screens.
- **Example credential file**: `service-account.json.example` added; actual credentials removed from repo.

### 🔧 Changed

- Bumped package version to `1.1.0+0`.
- `README.md` updated with analytics toggle, `dart-define`, and service account guidance.
- `PRIVACY_POLICY.md` updated with analytics and affiliate disclosures, opt-out instructions.
- `CONTRIBUTING.md` added with Conventional Commits guidance.
- `docs/screenshots/README.md` added with screenshot placeholder.
- Removed CI workflows (`.github/workflows/`). Project uses manual testing and git tags for releases.

### 🔐 Security & Privacy

- Analytics and affiliate data can be disabled at build-time via `--dart-define=DISABLE_ANALYTICS=true`.
- Per-user runtime opt-out available via Profile settings.
- Owner-only analytics mode restricts collection to configured owner accounts.
- Credentials (`service-account.json`) no longer committed; template added with `.gitignore` reference.

### ✅ Known Notes

- Owner-only mode is **enabled by default** (`kRestrictAnalyticsToOwners = true`). Add your UID to `kOwnerAnalyticsUids` or use the fallback email `hotcupofjoe2013@gmail.com`. Toggle runtime behavior via Developer Tools.
- Analytics is **optional** and fully compliant with privacy policies. Users can opt-out, and the feature can be disabled entirely at build time.
- Affiliate tracking is **opt-in** and respects all three layers of guards (compile-time, runtime per-user, owner-only).

---

## [0.8.2] - 2025-11-03

### ✨ Added

- **ASIN field for books**: Added `asin` to `UserBook` model and librarian UI.
- **Developer / Admin tools**: Developer Tools screen with user lookup, Pro/Librarian toggles, ASIN management.
- **Callable Cloud Functions**: Server-side callables for admin operations (`getUserByEmail`, `setLibrarianStatus`, `setProStatus`, etc.).
- **Diagnostics**: `pingAdmin` callable and Diagnostics UI in Developer Tools.

### 🔐 Security

- Admin allow-list with Firestore fallback and custom claims support.
- Audit logging for admin actions to `admin_audit` collection.

### 📦 Changes

- Bumped `cloud_functions` to `^6.0.3`.
- Bumped package version to `0.8.2+2`.

---

## [0.4.1] - 2025-11-03

### ✨ Added

- **Spice Rating Redesign**: Tappable flames with realistic color gradient, animations, haptic feedback.
- **Compact Spice Rating Widget**: Display ratings on library and home screens.
- **Profile Screen Enhancements**: Backfill state management, improved Goodreads import feedback.
- **Legal Documents**: Comprehensive Privacy Policy, Terms of Service with GDPR/CCPA compliance.
- **Documentation**: v0.4.0 Completion Status, detailed checklist, UX reviews.

### 🔧 Fixed

- Analyzer warnings resolved (`use_build_context_synchronously`).
- Code style: curly braces on single-line ifs, proper string escapes.
- Test stability: Optional `currentUserGetter` parameter, Firebase initialization handling.

### 📊 Tests

- Added 16 new widget tests for spice rating components.
- Test results: 25/25 passing (100% pass rate).

### 📦 Changes

- Bumped package version to `0.4.1+2`.
- Removed CI workflows for simpler release management.

---

## [0.4.0] - (Previous Release)

See git history for v0.4.0 release notes.

---

## Version Numbering

This project uses [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes, backwards compatible
- **Build number**: Increased for each release build

Current version: `1.1.0+0`

---

## Upcoming

See [ROADMAP.md](ROADMAP.md) for planned features and improvements.
