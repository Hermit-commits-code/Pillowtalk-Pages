# Changelog

All notable changes to Spicy Reads will be documented in this file.

the format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.1] - 2025-11-15

### 🔧 Improved

- **Add Book Success Message**: Enhanced success notification when adding books to celebrate community contribution:
  - Primary message: "Added [Book Title] to your library"
  - Secondary message: "✨ You helped build our community database!"
  - Encourages user engagement by highlighting their positive contribution
  - Extended duration (3 seconds) for better readability

## [1.4.0] - 2025-11-15

### ✨ Added - Community Book Catalog System

- **Community Book Catalog**: Implemented organic community-driven book database where ALL users contribute:
  - When any user (Free, Pro, or Librarian) adds a book, it's automatically added to the `/books` community catalog if it doesn't already exist
  - Prevents duplicate entries - checks for existing books before creating new ones
  - Tracks `addedToLibrariesCount` metric showing how many users have added each book
  - Users maintain full control of their personal library - can delete books anytime without affecting the community catalog
  
- **CommunityBookService Enhancements**:
  - New `ensureBookExists()` method creates books in community catalog with metadata from Google Books API
  - Automatically increments `addedToLibrariesCount` when users add existing books
  - New `decrementLibraryCount()` method tracks when users remove books from personal libraries
  - Non-blocking design - community catalog updates don't prevent personal library operations
  
- **Enhanced Firestore Rules**:
  - Updated `/books` collection rules to allow authenticated users to CREATE new book entries
  - Librarians and admins can UPDATE books for curation (adding ASIN, librarian summaries, etc.)
  - Only admins can DELETE books
  - Field validation ensures required fields (title, authors, id) are present on creation

### 🔧 Improved

- **Add Book Flow**: Seamlessly integrates community catalog creation into existing add book workflow:
  - Step 1: Check/create book in community catalog
  - Step 2: Add to personal library
  - Graceful error handling - personal library operations succeed even if community update fails
  
- **Remove Book Flow**: Updated to decrement community library count when users remove books from their personal library

### 🎯 Benefits

- **Organic Database Growth**: Every book added by any user builds the shared catalog naturally
- **Community Discovery**: Users can see how many other readers have added each book (`addedToLibrariesCount`)
- **Foundation for Social Features**: Sets groundwork for trope voting, community ratings, and trending books
- **No Data Loss**: Personal ratings, notes, and preferences stay private in user's library
- **All Users Contribute**: Free users, Pro users, and Librarians all contribute equally to building the catalog

## [1.3.0] - 2025-11-15

### ✨ Added - Week 3-4 UI_MAGPIE Features

- **Librarian Summary Section (Book Detail)**: Added "What Should I Know?" card to book detail page with purple accent styling. Displays placeholder for future librarian-curated content including:
  - Spice level details and scene descriptions
  - Key themes and tropes
  - Important content warnings
  - Emotional intensity information
  - POV and narrative style notes
- **Your Trending Tropes (Homepage)**: New section showing user's trending tropes from the last 60 days of reading:
  - Displays top 7 most-read tropes as interactive chips
  - Shows count badge for each trope indicating frequency
  - Positioned between "Continue Reading" and Analytics Dashboard
  - Only appears if user has recent reading activity with tropes
- **Reading Streak Tracker**: Implemented comprehensive streak tracking system across both homepage and profile:
  - New `ReadingStreakService` calculates current and best streaks based on book activity (dateAdded, dateStarted, dateFinished)
  - Homepage displays compact streak card with fire emoji, current streak, and achievement badge (Getting Started / Keep Going / On Fire!)
  - Profile shows detailed streak card with side-by-side current vs. best streak comparison
  - Motivational messages based on streak length
  - Only shows when user has active streak data

### 🔧 Fixed

- **ASIN Verification Navigation**: Fixed "Open book details to add ASIN (not implemented)" error in librarian ASIN verification screen. Clicking books without ASIN now navigates to book detail page where ASIN can be added via edit modal.

### 📊 Improved

- **UI_MAGPIE compliance**: Increased from ~75% to ~90% by completing Week 3-4 high-priority features:
  - ✅ Librarian Summary Section (new)
  - ✅ Your Trending Tropes (new)
  - ✅ Reading Streak Tracker (new)

## [1.2.3] - 2025-11-15

### 🔧 Fixed

- **Friend add dialog UX**: Changed "Add Friend" dialog from email-based input to username-based input for better user experience. Dialog now shows:
  - Label: "Friend's username" (previously "Friend's email")
  - Hint text: "@username" (previously "user@example.com")
  - Icon: @ symbol (previously envelope icon)
  - Keyboard type: text (previously email)
- This aligns with how friends are displayed (@username) and improves discoverability since usernames are more shareable than email addresses.

## [1.2.2] - 2025-11-15

### ✨ Added

- **Currently Reading Big Card (Homepage)**: Redesigned homepage to feature the first currently reading book as a large prominent card (120x180px cover) with title, author, spice level, and "Continue Reading" button. Additional currently reading books display in horizontal scroll below.
- **My Preferences Summary (Profile)**: New card on profile screen showing personalized reading preferences:
  - Primary format preference (calculated from library)
  - Average spice level with flame emoji
  - Top 3 favorite tropes as chips
  - Active hard stops count (only when enabled)
  - Active kink filters count (only when enabled)
- **Kink filters display**: Added kink filters row to preferences summary alongside hard stops.

### 🔧 Fixed

- **Hard stops visibility logic**: Hard stops row in preferences now respects the enabled toggle - disappears when disabled even if filters are configured.
- **Kink filters visibility logic**: Kink filters row only appears when both enabled AND filters exist.
- **Book detail navigation**: Fixed "Continue Reading" button to use correct route `/book/:id` instead of non-existent `/book-detail`.

### 📊 Improved

- **UI_MAGPIE compliance**: Increased from ~60% to ~75% by implementing Week 1-2 high-priority features:
  - ✅ Hard stops alert modal (already existed)
  - ✅ Currently Reading big card (new)
  - ✅ My Preferences summary (new)

### 📝 Notes

- Version bumped to `1.2.2+0`
- All Week 1-2 UI_MAGPIE goals completed
- Next focus: Week 3-4 features (Librarian summary, trending tropes, reading streak)

Current version: `1.2.2+0`

---

## [1.2.1] - 2025-11-15

### 🔧 Fixed

- **Friends list username display**: Friends list now displays friend's @username (or displayName) instead of generic "Friend" label. Matches the behavior of pending requests for consistency.

### 📊 Added

- **UI_MAGPIE gap analysis**: Created comprehensive comparison document (`UI_MAGPIE_GAP_ANALYSIS.md`) showing current implementation vs UI_MAGPIE target state. Identified missing high-priority features:
  - Hard stops alert modal (HIGH PRIORITY)
  - Currently Reading big card redesign (HIGH PRIORITY)
  - "My Preferences" summary on profile (HIGH PRIORITY)
  - Librarian summary section on book detail
  - Community spice insights (Pro feature)

### 📝 Notes

- Version bumped to `1.2.1+0`
- Gap analysis shows ~60% UI_MAGPIE compliance
- Next focus: Implement Phase 1 high-priority features (hard stops alert, homepage big card, profile preferences)

Current version: `1.2.1+0`

---

## [1.1.5] - 2025-11-14

### 🔧 Fixed

- **Restored corrupted discovery screen**: Recovered `lib/screens/discovery/community_discovery_screen.dart` from the last committed state (git HEAD) to resolve a large set of analyzer and syntax errors introduced by accidental file corruption.
- **Render overflow / layout fixes**: Prevented bottom RenderFlex overflow on the Discover → For You grid by wrapping the `TabBarView` in a `SafeArea` (bottom-only), adding dynamic bottom padding to discovery grids (accounts for `MediaQuery.of(context).padding.bottom + 12`), and reducing book-card vertical density (adjusted `childAspectRatio`, reduced inner padding and button sizes).
- **Search tab layout improvements**: Reworked the Search tab header into a single bordered container that contains the search input, a larger `Quick Moods` chips area, and an `Expanded` results area so the chips are no longer visually clipped.
- **Smaller placeholder footprint**: Reduced search placeholder icon and spacer sizes to free vertical space in the header.
- **Client-side auth guards for cloud callables**: Added auth checks before invoking friend-request callables to avoid `[firebase_functions/unauthenticated] UNAUTHENTICATED` errors when the client is not signed in.
- **Dialog overflow prevention**: Constrained Developer Tools dialog content to avoid overflow on small screens.

### ✨ Changed

- **Debugging aids**: Added temporary visual borders to the Search header and results container to aid layout debugging; these are present in this release to assist QA and may be removed in a follow-up polish release.
- **Version bump & release tag**: Bumped `pubspec.yaml` to `1.1.5+0`, committed with `chore(release): bump version to 1.1.5+0`, and created/pushed annotated tag `v1.1.5`.

### 📝 Notes

- The repository analyzer was run after the restore and edits (`dart analyze --fatal-warnings`) and returned clean with no issues.
- Visual QA: while these changes prevent common overflows and clipping, please verify on target devices/emulators (different screen sizes and safe-area insets). If you want, I can remove the debug borders and prepare a follow-up polish commit.

---

## [1.1.3] - 2025-11-13

### 🔧 Fixed

- **Dark mode TabBar text visibility**: Friends and Discover screens now display tab labels clearly in dark mode by explicitly setting text colors to white/white70
- **Firestore security rules**: Updated rules to check both `request.auth.token.admin` and `request.auth.customClaims.admin` for better admin permission support
- **Book discovery composite indexes**: Removed orderBy + where combinations that require composite indexes; now sort results in-memory for better performance
- **Query performance**: Book discovery now fetches 2x limit and filters client-side, eliminating dependency on composite Firestore indexes

### 📝 Notes

- Firestore rules deployed and active
- Book discovery queries work without composite index setup
- Admin permissions now respect Firebase custom claims

---

## [1.1.2] - 2025-11-13

### 🔧 Fixed

- **Firestore query index errors**: Removed orderBy + where combinations in friends_service.dart queries
- **TabBar text squashing**: Added scrollable tabs to Discover screen to prevent label cutoff
- **In-memory sorting**: Friends and requests now sorted in Dart instead of Firestore

---

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

Current version: `1.1.5+0`

## [1.1.6] - 2025-11-14

### 🔧 Fixed

- **Developer Tools / Admin callables**: Made client-side callable response parsing defensive for `getProUsers` and `getLibrarians` to avoid runtime cast errors that caused the app to fall back to direct Firestore reads (which were blocked by security rules). This resolves spurious "Permission denied" errors in Developer Tools.
- **Admin diagnostics**: Added a debug callable and client helper to surface raw responses and errors when diagnosing admin callables.

### ✨ Changed

- **Cloud Functions and tooling**: Added `logClientDiagnostic` callable, strengthened `isAdmin(context)` checks, and bumped `firebase-functions` dependency (functions package lock updated).
- **Librarian tooling**: Added a librarian search screen and wired it to the Librarian Tools.

### 📝 Notes

- Updated `pubspec.yaml` to `1.1.6+0` and created annotated tag `v1.1.6`.

## Current version: `1.1.6+0`

## [1.1.7] - 2025-11-14

### 🔧 Fixed

- **Curated collections rules & client resilience**: Tightened Firestore rules for the `collections` namespace to avoid permission-denied errors on listing while keeping Pro-only collections protected. Also adjusted client-side queries to avoid unfiltered lists for non-Pro users (prevents unexpected permission errors in the UI).

### 📝 Notes

- Bumped `pubspec.yaml` to `1.1.7+0` and created annotated tag `v1.1.7`.

## Current version: `1.1.7+0`

## [1.1.8] - 2025-11-14

### 🔧 Fixed

- **Firestore rules deployed**: Deployed updated `collections` read rules to Firestore to prevent permission-denied errors while keeping Pro-only lists protected. Client-side queries were updated so non-Pro users only request public collections.

### 📝 Notes

- Bumped `pubspec.yaml` to `1.1.8+0` and created annotated tag `v1.1.8`.

## Current version: `1.1.8+0`

## Upcoming

See [ROADMAP.md](ROADMAP.md) for planned features and improvements.
