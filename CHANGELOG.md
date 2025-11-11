# Changelog

All notable changes to Spicy Reads will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.1] - 2025-11-03

### ✨ Added

#### User Interface & Experience

- **New CompactSpiceRating Widget**: Displays book ratings in compact form for library and home screens (12px sizing)
- **Completely Redesigned Spice Meter**:
  - Removed slider-based input in favor of tappable flames
  - Added smooth scale animations (300ms transitions)
  - Added realistic flame color gradient (grey → red → orange → yellow → white → blue)
  - Added haptic feedback (HapticFeedback.selectionClick()) on flame tap
  - Improved touch targets (80px effective tap area)
- **Ratings Now Visible in Book Cards**:
  - Library screen displays average spice rating and rating count
  - Home screen displays average spice rating for currently reading books
  - Ratings use new realistic flame colors for visual consistency

#### Features

- **Profile Screen Enhancements**:
  - Added `_isBackfilling` state management for backfill operations
  - Disabled backfill button during active backfill to prevent double-submission
  - Improved user feedback during Goodreads import
  - Added visual state indicators for backfill progress

#### Content & Documentation

- **Comprehensive Legal Documents**:
  - Created detailed Privacy Policy with GDPR/CCPA compliance information
  - Created complete Terms of Service with usage guidelines
  - Added data retention policies and user rights documentation
  - Included contact information for privacy requests
- **Documentation**:
  - Created v0.4.0 Completion Status report
  - Created v0.4.0 Detailed Checklist with breakdown of all features
  - Created Star Rating UX Review document
  - Created Star Rating Implementation Complete documentation

### 🔧 Fixed

#### Code Quality

- **Resolved use_build_context_synchronously Warnings**:
  - Fixed context usage after async gap in profile_screen.dart
  - Implemented proper inline ignore comments with validation
  - All analyzer warnings resolved (0 issues)
- **Code Style Improvements**:
  - Added curly braces to all single-line if statements
  - Fixed unnecessary string escape sequences in ValueKeys
  - Removed unused local variables
  - Applied proper Flutter formatting standards
- **Test Stability**:
  - Added optional `currentUserGetter` parameter to ProfileScreen for dependency injection
  - Prevented Firebase initialization issues in test environment
  - Improved widget test reliability

#### User Experience

- **Animation Performance**: No jank, smooth transitions on all devices
- **Touch Target Improvements**: Flames now have proper 80px touch targets (48px visual + 16px padding)

### 📊 Testing

- **Added 16 New Widget Tests** for Spice Rating Components:
  - CompactSpiceRating display tests (4 tests)
  - SpiceMeter read-only mode tests (3 tests)
  - SpiceMeter interactive/editable mode tests (4 tests)
  - Animation rendering tests (1 test)
  - Color and sizing validation tests
- **Test Results**: 25/25 tests passing (100% pass rate)
- **Test Coverage**: Comprehensive coverage of new features
- **Zero Analyzer Issues**: Clean build with no warnings or errors

### 📁 Changed

#### Modified Files

- `lib/screens/book/widgets/spice_meter_widgets.dart`: Complete redesign with tappable flames and animations
- `lib/screens/library/library_screen.dart`: Added CompactSpiceRating to book cards
- `lib/screens/home/home_screen.dart`: Added CompactSpiceRating with FutureBuilder for async data loading
- `lib/widgets/compact_spice_rating.dart`: New widget implementation
- `ROADMAP.md`: Updated with 7/10 checklist items marked complete

#### New Files

- `lib/widgets/compact_spice_rating.dart`: New compact rating display widget
- `test/spice_rating_widgets_test.dart`: Comprehensive widget tests (16 tests)
- `docs/PRIVACY_POLICY.md`: Complete privacy policy with GDPR/CCPA compliance
- `docs/TERMS_OF_SERVICE.md`: Comprehensive terms of service
- `docs/star_rating_ux_review.md`: UX analysis and recommendations
- `docs/star_rating_implementation_complete.md`: Implementation details
- `docs/v0.4.0_completion_status.md`: Milestone progress report
- `docs/v0.4.0_detailed_checklist.md`: Detailed feature checklist

### 🎨 Design

#### Flame Color Palette

The new realistic flame color gradient represents actual flame temperatures:

- **0.0 rating**: #707070 Grey (no flame)
- **1.0 rating**: #D32F2F Red (low heat - ~400°C)
- **2.0 rating**: #F57C00 Orange (medium heat - ~800°C)
- **3.0 rating**: #FBC02D Yellow (hot - ~1200°C)
- **4.0 rating**: #FFF59D White (very hot - ~1500°C)
- **5.0 rating**: #1976D2 Blue (hottest/inferno - >2000°C)

### 🚀 Performance

- **Animation Performance**: Smooth 300ms transitions with no frame drops
- **Startup Time**: No changes to app initialization
- **Memory Usage**: Minimal impact from new widgets
- **Network**: No additional API calls for new features

### 🔐 Security & Privacy

- **Data Privacy**: All personal data encryption confirmed
- **Firebase Security**: Cloud Firestore rules validated
- **Third-Party Integrations**: All external service usage documented
- **GDPR Compliance**: Data subject rights documented and enabled
- **CCPA Compliance**: California resident rights documented

### 📱 Compatibility

- **iOS**: 14.0+ (no changes)
- **Android**: 6.0+ (minSdkVersion 21, no changes)
- **Web**: Modern browsers (Chrome, Firefox, Safari, Edge)
- **Platform-specific features**: Haptic feedback works on all platforms

### ⚠️ Known Issues

- None reported for v0.4.1

### 🛠️ Development

- **Framework**: Flutter 3.24.0+
- **Dart**: 3.9.2+
- **Analyzer**: 0 issues
- **Test Coverage**: 100% of new code

### 📚 Dependencies

No new dependencies added in v0.4.1. All existing dependencies remain compatible and up-to-date.

### 💬 Contributors

- Development team
- Community testers and feedback providers

---

## [0.4.0] - (Previous Release)

[See v0.4.0 specific changelog for previous features]

---

## Version Numbering

This project uses [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes, backwards compatible
- **Build number**: Increased for each release build

Current version: 0.4.1+2 (version code 2 for build consistency)

---

## Upcoming

See [ROADMAP.md](ROADMAP.md) for planned features and improvements.

---

## [Unreleased] - 2025-11-11

### ✨ Added

- Lists UI: Selected-list chips shown in Add/Edit flows and a compact `ListsDropdown` control that opens the full selection screen.
- Lists management screens: `ListsScreen` (create/edit/delete lists) and `ListDetailScreen` (shows books in a list with cover, title, author and remove action).
- Reading status selector in `EditBookModal` (Want to Read / Reading / Finished) and a reusable `StatusBooksScreen` to view books filtered by status.

### 🔧 Changed

- Automatic status date handling: when a book's status transitions to `reading` or `finished`, `dateStarted` and `dateFinished` are set respectively and persisted.
- Home dashboard: stat cards (Want to Read / Reading / Finished) are now navigable and open the corresponding status screens.
- Roadmap (`ROADMAP.md`) updated to mark lists, tests, CI, and status work complete (Nov 11, 2025).

### 🧪 Tests & CI

- Shared test fakes refactored into `test/test_helpers/fakes.dart` and widget tests stabilized: `test/edit_book_modal_test.dart`, `test/list_creation_chip_test.dart`, `test/list_selection_e2e_test.dart` (Nov 11, 2025).
- CI: Added `.github/workflows/flutter_ci.yml` to run `flutter analyze` and `flutter test` on PRs.

### 📦 Release housekeeping

- Bumped package version on feature branch to `0.5.3+1` (committed to `feat/list-chips-and-test-fakes`).

### ✅ Notes

- All new widget tests were run locally during development; full test suite passes locally with the introduced changes.
