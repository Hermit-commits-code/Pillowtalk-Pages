# Phase 0 Implementation Guide: Personal-Only MVP (30 Days)

**Goal**: Launch beta with critical friction-reducing features. Move from "feature-complete" to "user-ready."

**Timeline**: November 11 - December 11, 2025

---

## ⚡ Quick Start

```bash
# Week 1: Content Seeding
node tool/seed_romance_books.js --dry-run --limit=100
node tool/seed_romance_books.js --limit=500
flutter analyze  # verify no errors

# Week 2: Onboarding Funnel
# (Build UI screens - see detailed tasks below)

# Week 3: Amazon Affiliate
# (Add affiliate links to book detail screen)

# Week 4: Beta Launch
# Update version, test, deploy, invite testers
flutter pub get
flutter analyze
flutter build apk --release
```

---

## Week 1: Content Seeding (500-1000 Books)

### Task 1.1: Set Up Firebase Service Account

**Why**: The seed script needs Firebase admin credentials to write to Firestore.

**Steps**:

1. Download service account JSON from Firebase Console:

   - Go to: https://console.firebase.google.com → Your Project → Settings ⚙️ → Service Accounts → Generate New Private Key
   - Save as: `service-account.json` (in project root)
   - Add to `.gitignore` (never commit credentials)

2. Verify in terminal:
   ```bash
   cd c:/Users/Joe/Desktop/Spicy-Reads
   ls -la service-account.json  # should exist
   ```

**Done When**: `service-account.json` exists in project root.

---

### Task 1.2: Install Node.js Dependencies

**Why**: The seed script uses `axios` and `firebase-admin` npm packages.

**Steps**:

1. Create `package.json` in project root (if not exists):

   ```json
   {
     "name": "spicy-reads-tools",
     "version": "1.0.0",
     "description": "Seed scripts for Spicy Reads",
     "scripts": {
       "seed": "node tool/seed_romance_books.js"
     },
     "dependencies": {
       "axios": "^1.6.0",
       "firebase-admin": "^12.0.0"
     }
   }
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Verify:
   ```bash
   npm list axios firebase-admin  # should show both installed
   ```

**Done When**: `npm list` shows both packages installed.

---

### Task 1.3: Run Dry-Run Seed (Test Without Writing)

**Why**: Verify the script works before committing 500 books to Firestore.

**Steps**:

```bash
node tool/seed_romance_books.js --dry-run --limit=50
```

**Expected Output**:

```
✅ Firebase initialized

🌱 Starting Romance Books Seeding...

Configuration:
  - Dry run: true
  - Target books: 50
  - Queries: 11
  - API Key: Not provided (rate limits apply)

📚 Querying: "contemporary romance"
  [DRY RUN] Would save: The Hating Game by Sally Thorne
  [DRY RUN] Would save: Red Rising by Pierce Brown
  ... (50 books total)

✨ Seeding Complete!

Summary:
  - Total processed: 50
  - Saved: 50
  - Skipped (duplicates/errors): 0
  - Mode: DRY RUN

🔍 Dry run completed. Run without --dry-run to actually save books.
```

**Done When**: Dry-run completes with 0 errors.

---

### Task 1.4: Run Live Seed (500 Books)

**Why**: Populate Firestore with pre-seeded books for day 1 UX.

**Steps**:

```bash
node tool/seed_romance_books.js --limit=500
```

**What Happens**:

- Queries Google Books API 11 times (1 per romance keyword)
- Fetches ~40 books per query (440 total, minus duplicates)
- Writes to `/books` Firestore collection
- Each book has: `id`, `isbn`, `title`, `authors`, `imageUrl`, `description`, `pageCount`, `genres`, `isPreSeeded: true`

**Time**: ~5-10 minutes (respects Google Books rate limits)

**Verify in Firebase Console**:

1. Go to: https://console.firebase.google.com → Your Project → Firestore Database
2. Navigate to: `books` collection
3. Should see ~400-500 documents with `isPreSeeded: true`

**Done When**: Firebase Console shows 400-500 books in `/books` collection.

---

### Task 1.5: Manual Curation (50-100 Spicy Books)

**Why**: Pre-seeded books have no metadata (warnings/tropes). Manually curate 50-100 to be "exemplars."

**Steps**:

1. Create `tool/curated_spicy_books.json`:

   ```json
   [
     {
       "title": "The Hating Game",
       "authors": ["Sally Thorne"],
       "isbn": "9780062418739",
       "warnings": ["sexual content", "workplace dynamics"],
       "tropes": [
         "Enemies to Lovers",
         "Banter",
         "Forced Proximity",
         "Mutual Pining"
       ],
       "spiceLevel": 3
     },
     {
       "title": "Red Rising",
       "authors": ["Pierce Brown"],
       "isbn": "9780345539786",
       "warnings": ["violence", "dystopian themes"],
       "tropes": ["Coming of Age", "Forbidden Romance", "Survival"],
       "spiceLevel": 2
     }
     // ... add 50-100 more
   ]
   ```

2. Create a script `tool/apply_curation.js` to update Firestore:

   ```javascript
   const admin = require('firebase-admin');
   const fs = require('fs');
   const curatedBooks = require('./curated_spicy_books.json');

   async function applyCuration() {
     const db = admin.firestore();
     for (const book of curatedBooks) {
       const query = await db
         .collection('books')
         .where('isbn', '==', book.isbn)
         .limit(1)
         .get();

       if (!query.empty) {
         const docRef = query.docs[0].ref;
         await docRef.update({
           cachedTopWarnings: book.warnings,
           cachedTropes: book.tropes,
         });
         console.log(`✅ Updated: ${book.title}`);
       }
     }
     process.exit(0);
   }

   applyCuration();
   ```

3. Run:
   ```bash
   node tool/apply_curation.js
   ```

**Done When**: 50-100 books have `cachedTopWarnings` and `cachedTropes` populated in Firestore.

---

## Week 2: Onboarding Funnel (Critical UX)

**Goal**: Users set Hard Stops + Kink Filters BEFORE landing in library. This is THE critical friction point.

### Task 2.1: Create OnboardingScreen (Wrapper)

**File**: `lib/screens/onboarding/onboarding_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_book.dart';
import '../../services/hard_stops_service.dart';
import '../../services/kink_filter_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0; // 0-4
  List<String> _selectedHardStops = [];
  List<String> _selectedKinkFilters = [];
  List<String> _selectedFavoriteTropes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentStep,
        children: [
          // Step 0: Welcome
          _buildWelcomeStep(),
          // Step 1: Hard Stops
          _buildHardStopsStep(),
          // Step 2: Kink Filters
          _buildKinkFiltersStep(),
          // Step 3: Favorite Tropes
          _buildFavoriteTropesStep(),
          // Step 4: Curated Library
          _buildCuratedLibraryStep(),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 64, color: theme.primaryColor),
            const SizedBox(height: 24),
            const Text(
              'Protect Yourself First',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'We\'ll filter books based on your comfort level. Let\'s set your preferences.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text('Let\'s Set Hard Stops'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHardStopsStep() {
    // TODO: Implement multi-select chips for hard stops
    return const Placeholder();
  }

  Widget _buildKinkFiltersStep() {
    // TODO: Implement multi-select chips for kink filters
    return const Placeholder();
  }

  Widget _buildFavoriteTropesStep() {
    // TODO: Implement multi-select chips for favorite tropes
    return const Placeholder();
  }

  Widget _buildCuratedLibraryStep() {
    // TODO: Show 10 books matching user preferences
    return const Placeholder();
  }
}
```

**Done When**: All 5 steps render without errors.

---

### Task 2.2: Implement Hard Stops Selection Screen

**Update**: `lib/screens/onboarding/onboarding_screen.dart`

Add the hard stops step. Replace the placeholder:

```dart
Widget _buildHardStopsStep() {
  const hardStopsList = [
    'Dubcon',
    'Infidelity',
    'Violence',
    'Non-Consent',
    'Abuse',
    'Sexual Assault',
    'Self-Harm',
    'Suicide',
    'Graphic Violence',
    'Alcohol Abuse',
    'Drug Use',
    'Eating Disorders',
    'Loss of Loved One',
    'Racism',
    'Homophobia',
    'Cheating',
    'Infertility',
    'Child Abuse',
    'Human Trafficking',
    'Cancer',
  ];

  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        const Text('Add Hard Stops', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Select content you absolutely won\'t read:'),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hardStopsList.map((stop) {
            final isSelected = _selectedHardStops.contains(stop);
            return FilterChip(
              label: Text(stop),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedHardStops.add(stop);
                  } else {
                    _selectedHardStops.remove(stop);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: const Text('Back'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => setState(() => _currentStep = 2),
              child: const Text('Next: Kink Filters'),
            ),
          ],
        ),
      ],
    ),
  );
}
```

**Done When**: Users can select/deselect hard stops and proceed to next step.

---

### Task 2.3: Implement Kink Filters Selection Screen

Similar to hard stops, but for kinks/tropes to EXCLUDE:

```dart
Widget _buildKinkFiltersStep() {
  const kinksList = [
    'A/B/O (Alpha/Beta/Omega)',
    'BDSM',
    'Humiliation',
    'Ménage',
    'Reverse Harem',
    'Scat/Bodily Fluids',
    'Bestiality',
    'Incest',
    'Teacher/Student',
    'Age Gap (significant)',
    'Virgin/Innocent',
    'Pregnancy',
    'Breeding',
  ];

  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        const Text('Kink Filters (Optional)', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Select tropes/kinks you\'d like to exclude:'),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kinksList.map((kink) {
            final isSelected = _selectedKinkFilters.contains(kink);
            return FilterChip(
              label: Text(kink),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedKinkFilters.add(kink);
                  } else {
                    _selectedKinkFilters.remove(kink);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep = 1),
              child: const Text('Back'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => setState(() => _currentStep = 3),
              child: const Text('Next: Favorite Tropes'),
            ),
          ],
        ),
      ],
    ),
  );
}
```

**Done When**: Users can select/deselect kink filters and proceed.

---

### Task 2.4: Implement Favorite Tropes Selection Screen

```dart
Widget _buildFavoriteTropesStep() {
  const tropes = [
    'Grumpy-Sunshine',
    'Forced Proximity',
    'Fake Dating',
    'Mutual Pining',
    'Unrequited Love',
    'Friends to Lovers',
    'Enemies to Lovers',
    'Second Chance Romance',
    'Found Family',
    'Childhood Sweetheart',
    'One Night Stand',
    'Accidental Marriage',
    'Bodyguard Romance',
    'CEO Romance',
    'Reverse Harem',
    'Forbidden Romance',
    'Royal Romance',
    'Supernatural/Paranormal',
    'Time Travel',
    'Reincarnation',
  ];

  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        const Text('Favorite Tropes (Optional)', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('What tropes do you love? This helps us personalize your library.'),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tropes.map((trope) {
            final isSelected = _selectedFavoriteTropes.contains(trope);
            return FilterChip(
              label: Text(trope),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedFavoriteTropes.add(trope);
                  } else {
                    _selectedFavoriteTropes.remove(trope);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep = 2),
              child: const Text('Back'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                // Save to Firestore
                await HardStopsService().setHardStops(_selectedHardStops);
                await KinkFilterService().setKinkFilter(_selectedKinkFilters);
                // TODO: Save favorite tropes somewhere (user profile?)

                setState(() => _currentStep = 4);
              },
              child: const Text('Save & Discover'),
            ),
          ],
        ),
      ],
    ),
  );
}
```

**Done When**: Users can save preferences and proceed to final step.

---

### Task 2.5: Implement Curated Library Step

```dart
Widget _buildCuratedLibraryStep() {
  return FutureBuilder(
    future: _getCuratedBooks(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final books = (snapshot.data as List<UserBook>?) ?? [];

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            const Text('Your Curated Library', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('We found ${books.length} books matching your preferences'),
            const SizedBox(height: 24),
            // Show 10 curated books
            ...books.take(10).map((book) {
              return ListTile(
                leading: book.imageUrl != null ? Image.network(book.imageUrl!) : null,
                title: Text(book.title),
                subtitle: Text(book.authors.join(', ')),
              );
            }),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Start Reading'),
            ),
          ],
        ),
      );
    },
  );
}

Future<List<UserBook>> _getCuratedBooks() async {
  // Query /books collection for pre-seeded books
  // Filter by favorite tropes
  // Return 10 books
  // TODO: Implement
  return [];
}
```

**Done When**: Final step shows curated books and "Start Reading" button navigates to home.

---

### Task 2.6: Wire Onboarding to Auth Flow

**Update**: `lib/config/router.dart` or your auth screen

After login succeeds, route to onboarding instead of home:

```dart
// In your login/auth flow:
if (FirebaseAuth.instance.currentUser != null) {
  final hasCompletedOnboarding = // TODO: Check user profile
  if (hasCompletedOnboarding) {
    context.go('/home');
  } else {
    context.go('/onboarding');
  }
}
```

**Done When**: New users see onboarding after login; existing users skip to home.

---

## Week 3: Amazon Affiliate Integration

### Task 3.1: Get Amazon Associates Account

**Steps**:

1. Go to: https://affiliate-program.amazon.com
2. Sign up with your email
3. Provide site/app details: "Spicy Reads mobile app for romance readers"
4. Get Associates ID (looks like: `spicyreads-20`)
5. Save somewhere safe

**Done When**: You have an Amazon Associates ID.

---

### Task 3.2: Add "Buy on Amazon" Button to BookDetailScreen

**File**: `lib/screens/book/book_detail_screen.dart`

Add this button below the book description:

```dart
ElevatedButton.icon(
  onPressed: () {
    final affiliateUrl = _buildAmazonAffiliateLink(userBook.isbn);
    url_launcher.launchUrl(Uri.parse(affiliateUrl));
  },
  icon: const Icon(Icons.shopping_cart),
  label: const Text('Buy on Amazon'),
),
```

Add helper function:

```dart
String _buildAmazonAffiliateLink(String isbn) {
  if (isbn.isEmpty) {
    return 'https://amazon.com/s?k=romantic+fiction';
  }
  return 'https://amazon.com/s?k=$isbn&tag=spicyreads-20';
}
```

**Done When**: Button appears on book detail, opens Amazon in browser.

---

### Task 3.3: Add Affiliate Disclosure

**Update**: `lib/screens/profile/profile_screen.dart`

Add to legal section:

```dart
const Padding(
  padding: EdgeInsets.symmetric(vertical: 16),
  child: Text(
    'Affiliate Disclosure: Spicy Reads is a participant in the Amazon Services LLC Associates Program. We earn from qualifying purchases through affiliate links.',
    style: TextStyle(fontSize: 12),
  ),
),
```

**Done When**: Disclosure appears in Profile → Legal section.

---

## Week 4: Polish + Beta Launch

### Task 4.1: Test Onboarding End-to-End

**Steps**:

1. Create 3 test accounts (different preferences)
2. Go through full onboarding for each
3. Verify hard stops are saved
4. Verify library shows curated books matching preferences

**Done When**: All 3 test runs complete without errors.

---

### Task 4.2: Test Affiliate Links

**Steps**:

1. Open a book in BookDetailScreen
2. Click "Buy on Amazon" button
3. Verify browser opens Amazon affiliate link
4. Check URL contains `tag=spicyreads-20`

**Done When**: Affiliate link opens correctly in browser.

---

### Task 4.3: Run Analyzer & Fix Issues

```bash
flutter analyze
```

**Done When**: 0 issues reported.

---

### Task 4.4: Update Version & Create Release Notes

**Update** `pubspec.yaml`:

```yaml
version: 0.6.0+2 # or higher
```

**Create** `docs/RELEASE_NOTES_v0.6.0.md`:

```markdown
# Spicy Reads v0.6.0 - Phase 0 Beta

## New Features

### 🎯 Smart Onboarding

- Users set Hard Stops before landing in library
- Pre-curated books on day 1 based on preferences
- Kink Filter + Favorite Tropes selection

### 📚 500+ Pre-Seeded Books

- Google Books API integration
- All major romance sub-genres included

### 🛒 Amazon Affiliate

- Buy on Amazon button on every book
- Spicy Reads earns 3% commission

## Improvements

- Better first-run UX (no blank library)
- Mental health protections (hard stops warning)
- Revenue stream enabled

## Known Issues

None (beta testing phase)
```

**Done When**: Version updated, release notes created.

---

### Task 4.5: Deploy to Play Store (Closed Testing)

**Steps**:

1. Build APK:

   ```bash
   flutter build apk --release
   ```

2. Go to: https://play.console.google.com → Your App → Release → Testing → Closed Testing

3. Upload APK + release notes

4. Create testers list (email addresses)

5. Share beta link with 50-100 testers

**Testers Source**:

- Reddit: /r/RomanceAuthors, /r/RomanceReaders
- Discord: Romance reader communities
- Twitter: #BookTwitter, #AmWriting
- TikTok: #BookTok communities

**Done When**: Beta link is live and testers have access.

---

## Success Criteria

| Metric                                | Target          | Why                      |
| ------------------------------------- | --------------- | ------------------------ |
| Day 1 retention (onboarding complete) | >50%            | Smooth UX                |
| Day 7 retention                       | >25%            | Users come back          |
| Books added per user                  | 5-10            | Active usage             |
| Hard Stops set per user               | 1-3 average     | Mental health engagement |
| Affiliate clicks                      | 5-10/user/month | Revenue indicator        |
| Crash-free                            | >98%            | Stability                |
| App rating                            | >4.0 stars      | Quality                  |

---

## Critical Path (Don't Skip)

1. ✅ Content Seeding (500 books) — required for day 1 UX
2. ✅ Onboarding Funnel — REQUIRED (no blank library)
3. ✅ Amazon Affiliate — required for revenue
4. ✅ Testing & Beta Launch — required for user feedback

---

## Next Steps (After Week 4)

Based on beta feedback:

1. Iterate on onboarding (A/B test hard stops order)
2. Add hard stop warning prompts (v0.6.1)
3. Build reading analytics dashboard (v0.7.0)
4. Plan Play Store launch (v0.8.0)

---

**Created**: November 11, 2025
**Target**: December 11, 2025 (Public Beta)
