# Phase 0 Quick Start Guide

**Goal**: Launch beta with 500 pre-seeded books + smart onboarding + affiliate revenue.

**Timeline**: November 11 - December 11, 2025 (30 days)

---

## 🚀 Quick Commands

### Week 1: Content Seeding

```bash
# 1. Set up Firebase service account
# Go to: https://console.firebase.google.com → Settings → Service Accounts → Generate Key
# Save as: service-account.json (in project root)

# 2. Install npm dependencies
npm install

# 3. Test seed script (dry-run, won't write)
node tool/seed_romance_books.js --dry-run --limit=50

# 4. Actually seed 500 books (takes ~5-10 minutes)
node tool/seed_romance_books.js --limit=500

# 5. Verify in Firebase Console
# https://console.firebase.google.com → Firestore → books collection
# Should see ~400-500 documents with isPreSeeded: true
```

### Week 2: Onboarding Funnel

```bash
# Create onboarding screens
# lib/screens/onboarding/onboarding_screen.dart

# Wire to router after login
# Update your auth flow to route to /onboarding for new users

flutter analyze  # Check for errors
```

### Week 3: Amazon Affiliate

```bash
# 1. Sign up: https://affiliate-program.amazon.com
# 2. Get Associates ID (e.g., spicyreads-20)
# 3. Add button to BookDetailScreen
# 4. Add disclosure to ProfileScreen

flutter analyze
```

### Week 4: Beta Launch

```bash
# 1. Test everything
flutter analyze

# 2. Build release APK
flutter build apk --release

# 3. Upload to Play Store → Closed Testing
# https://play.console.google.com → Your App → Release → Closed Testing

# 4. Invite 50-100 beta testers
# Share link from Play Store console
```

---

## 📋 Detailed Tasks

### Week 1: Content Seeding (3-4 Days)

| Task                            | Time     | Deliverable                                            |
| ------------------------------- | -------- | ------------------------------------------------------ |
| Set up Firebase service account | 15 min   | `service-account.json` in project root                 |
| Install npm dependencies        | 5 min    | `npm list axios firebase-admin` shows both             |
| Run dry-run seed                | 5 min    | Outputs "50 books would save"                          |
| Run live seed (500 books)       | 10 min   | ~400-500 books in Firestore `/books` collection        |
| Manual curation (optional)      | 1-2 days | 50-100 books with `cachedTopWarnings` + `cachedTropes` |

### Week 2: Onboarding Funnel (3-4 Days)

| Task                      | Time    | Deliverable                                                  |
| ------------------------- | ------- | ------------------------------------------------------------ |
| Create onboarding wrapper | 2 hours | `lib/screens/onboarding/onboarding_screen.dart` with 5 steps |
| Hard Stops selection      | 2 hours | Users select from 20 common warnings                         |
| Kink Filters selection    | 1 hour  | Users select from 30 common tropes                           |
| Favorite Tropes selection | 1 hour  | Users select from 40 popular tropes                          |
| Curated Library step      | 2 hours | Shows 10 books matching preferences                          |
| Wire to auth flow         | 1 hour  | New users see onboarding after login                         |
| Test end-to-end           | 1 hour  | 3 test accounts, full flow per account                       |

### Week 3: Amazon Affiliate (1-2 Days)

| Task                           | Time   | Deliverable                                    |
| ------------------------------ | ------ | ---------------------------------------------- |
| Sign up for Associates         | 20 min | Amazon Associates ID (e.g., `spicyreads-20`)   |
| Add button to BookDetailScreen | 30 min | "Buy on Amazon" button visible, opens link     |
| Add legal disclosure           | 15 min | Disclosure text in ProfileScreen legal section |
| Test affiliate links           | 30 min | Verify URL has `tag=spicyreads-20`             |

### Week 4: Polish + Beta Launch (2-3 Days)

| Task                        | Time   | Deliverable                             |
| --------------------------- | ------ | --------------------------------------- |
| Verify affiliate links work | 30 min | Test clicks open Amazon affiliate URL   |
| Run analyzer                | 15 min | `flutter analyze` shows 0 issues        |
| Update pubspec.yaml         | 5 min  | Version bumped to 0.6.0+3 (or higher)   |
| Create release notes        | 30 min | `docs/RELEASE_NOTES_v0.6.0.md`          |
| Build release APK           | 10 min | `flutter build apk --release` completes |
| Upload to Play Store        | 30 min | Closed Testing track, approved          |
| Invite beta testers         | 1 hour | Link shared in Reddit, Discord, Twitter |

---

## 🎯 Success Criteria

**Beta must hit these metrics to proceed to Play Store launch**:

| Metric                | Target          | Measurement                                |
| --------------------- | --------------- | ------------------------------------------ |
| Day 1 Retention       | >50%            | % of beta testers who complete onboarding  |
| Day 7 Retention       | >25%            | % of day 1 users who return after 7 days   |
| Books Added/User      | 5-10 avg        | Average books added per user in first week |
| Hard Stops Engagement | 1-3 avg         | Average hard stops set per user            |
| Zero Crashes          | >98% crash-free | Firebase Crashlytics report                |
| App Rating            | >4.0 stars      | Play Store beta rating                     |

**If any metric is RED**: Iterate before public launch.
**If all metrics are GREEN**: Ready for Play Store public release (v0.8.0).

---

## 🚨 Critical Path (Don't Skip)

1. **Content Seeding** (500 books) — WITHOUT this, day 1 UX is blank library = 90% churn
2. **Onboarding Funnel** (hard stops → curated books) — THE critical friction point
3. **Amazon Affiliate** (revenue stream) — enables sustainability
4. **Testing & Beta** (50-100 real users) — provides metrics for go/no-go decision

---

## ❌ What NOT to Do

- ❌ Web scrape Goodreads (violates ToS)
- ❌ Launch without onboarding (blank library = failure)
- ❌ Forget affiliate disclosure (required by Amazon + FTC)
- ❌ Skip beta testing (you need real user feedback)
- ❌ Rush to public launch (iterate on beta metrics first)

---

## 📊 Week-by-Week Checklist

### Week 1 (Nov 11-17)

- [ ] Firebase service account downloaded
- [ ] npm dependencies installed
- [ ] seed script tested (dry-run)
- [ ] 500 books seeded to Firestore
- [ ] Manual curation done (optional but recommended)

### Week 2 (Nov 18-24)

- [ ] OnboardingScreen created with all 5 steps
- [ ] Hard Stops selection implemented
- [ ] Kink Filters selection implemented
- [ ] Favorite Tropes selection implemented
- [ ] Curated Library step shows 10 books
- [ ] Onboarding wired to auth flow
- [ ] End-to-end testing complete (3 test accounts)

### Week 3 (Nov 25-Dec 1)

- [ ] Amazon Associates account created
- [ ] "Buy on Amazon" button added to BookDetailScreen
- [ ] Affiliate links verified working
- [ ] Legal disclosure added to ProfileScreen
- [ ] All links have correct Associates ID

### Week 4 (Dec 2-11)

- [ ] All analyzer issues fixed (0 reported)
- [ ] pubspec.yaml version updated
- [ ] Release notes created
- [ ] Release APK built and tested locally
- [ ] Uploaded to Play Store Closed Testing
- [ ] Beta link shared with 50-100 testers
- [ ] Beta metrics monitored daily

---

## 📞 Support

**If seed script fails**:

- Verify `service-account.json` exists and has correct permissions
- Check Google Books API key (if using one)
- Verify Firebase project is initialized
- Run with `--dry-run` first to debug

**If onboarding screens don't render**:

- Ensure all Placeholder widgets are replaced with actual UI
- Run `flutter analyze` to check for import errors
- Check that go_router is configured for `/onboarding` route

**If affiliate links don't work**:

- Verify Amazon Associates ID is correct
- Test ISBN extraction is working (print debug info)
- Make sure URL Launcher is properly configured

---

**Version**: 0.6.0+2
**Created**: November 11, 2025
**Target Launch**: December 11, 2025
