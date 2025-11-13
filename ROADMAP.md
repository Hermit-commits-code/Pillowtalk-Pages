# ��� Spicy Reads: Personal-Only Sanctuary Roadmap (v0.6.0+)

**Strategic Direction**: Personal-only book tracker with mental health protections, premium subscription model, and affiliate revenue stream.

**Positioning**: "The Goodreads for privacy-conscious romance readers who want accurate, personal content filtering."

---

## Table of Contents

1. Strategic Philosophy
2. Product Positioning vs. Competitors
3. Personal-Only MOAT (What Makes Us Different)
4. Monetization Strategy (Personal-Only Model)
5. Phase 0: Immediate Priorities (30 Days)
6. Phase 1-4: Full Implementation Roadmap
7. Success Metrics & KPIs

---

## ��� Strategic Philosophy

**Vein of Truth**: "Romance is not a genre; it's a culture. We are the first book tracker built INSIDE that culture, protecting reader mental health through personal data ownership."

**Core Principle**: Every user's data is theirs alone. No aggregation. No community voting. No algorithmic manipulation. Just accurate, personal content filtering.

**Why Personal-Only?**

- ✅ **Privacy first**: Users control all data; zero sharing across accounts
- ✅ **Mental health**: Hard Stops + Kink Filters protect against triggering content
- ✅ **Legal simplicity**: No GDPR/privacy concerns with community data
- ✅ **Speed to market**: No need to build moderation, voting systems, or community features
- ✅ **Defensible moat**: Competitors can't beat us on privacy if we own it first

---

## ��� Product Positioning: Spicy Reads vs. Competitors

| Aspect                                | Goodreads (Free)                       | StoryGraph (Plus $3.99/mo)          | Spicy Reads                                |
| ------------------------------------- | -------------------------------------- | ----------------------------------- | ------------------------------------------ |
| **Primary Use**                       | Social book tracking                   | Mood-based discovery + tracking     | Personal tracking (spice-focused)          |
| **Community Ratings**                 | ✅ Yes                                 | ❌ No (personal-only)               | ❌ No (personal-only)                      |
| **Spice Rating / Content Detail**     | ❌ No                                  | ✅ Half + quarter stars             | ✅ Detailed (0-5 flames + sub-categories)  |
| **Hard Stops / Mental Health Filter** | ❌ No                                  | ✅ Content Warnings (basic)         | ✅ Yes (hard stops + kink filters)         |
| **Mood-Based Discovery**              | ❌ No                                  | ✅ Yes                              | ❌ Manual filter only                      |
| **Audiobook Support**                 | ✅ Basic (metadata only)               | ✅ Yes                              | ✅ Yes (format + listen tracking)          |
| **Reading Stats + Heatmaps**          | ❌ Basic (counts only)                 | ✅ Yes (Charts, pace, mood splits)  | 🚧 Planned v0.7.0                          |
| **Buddy Reads**                       | ✅ Yes (basic)                         | ✅ Yes (spoiler-safe + reactions)   | ❌ No (privacy-first)                      |
| **Privacy Model**                     | Centralized; profile public by default | Centralized; profile can be private | Decentralized; all data private by default |
| **Data Ownership**                    | Amazon owns your data                  | User owns; no Amazon backend        | You own your data                          |
| **Target User**                       | General readers + social seekers       | Indie readers + mood-based seekers  | Private, spice-focused romance readers     |
| **Moat Strength**                     | Scale (100M+ users)                    | Privacy + better UX                 | **Spice + Mental Health + Privacy**        |

---

## ��� Personal-Only MOAT: Our Competitive Advantage

### What Makes Us Defensible (Without Community)

| Component              | How It Works                                                                                                                               | Competitive Advantage                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| **Vetted Spice Meter** | User rates each book personally (0-5 flames + 3 sub-categories: On-Page Sex, Emotional Intensity, Content Warnings)                        | Only app with this level of granularity; users build their own library of accurate ratings for their preferences |
| **Hard Stops Filter**  | Users define content they absolutely won't read (e.g., infidelity, violence, dubcon). Search/browse auto-filters.                          | Only app protecting mental health PROACTIVELY; shows warning when books contain hard stops before reading        |
| **Kink Filter**        | Users exclude specific tropes (e.g., "no cheating," "no A/B/O"). Library and search respect this.                                          | User control over "spicy level" discovery; no algorithmic nudging into uncomfortable content                     |
| **Deep Tropes Search** | Multi-select search (genre + 2-10 tropes + reading status + ownership type). AND logic only.                                               | Fast, lightweight search without external indexing (Algolia, Elasticsearch); works on personal library scale     |
| **Personal Library**   | Each user's library is optimized for THEIR reading journey: status tracking, personal notes, custom tropes, dates, star ratings, ownership | Goodreads can't personalize at this level; each user has control over their full book metadata                   |
| **Reading Analytics**  | Personal dashboard: total books tracked, avg spice, status breakdown, books read per month                                                 | Motivates continued usage and pro subscription                                                                   |
| **Privacy First**      | All data encrypted, zero sharing, all processing client-side where possible                                                                | Users trust Spicy Reads more than Goodreads/Bookly for sensitive content preferences                             |

### What We DON'T Do (And Why)

| Feature                               | Why We Skip It                                                                                               |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Community Ratings Aggregation**     | Creates data quality problems; requires moderation; dilutes "personal" positioning; high infrastructure cost |
| **Public Profiles / Follower System** | Contradicts privacy-first positioning; introduces toxic social dynamics; moderation burden                   |
| **Social Sharing of Library Data**    | Opens privacy concerns; users may not want data shared; creates compliance issues                            |
| **Community Trope Tagging**           | We trust user-entered tropes (personal accuracy > crowdsourced consensus)                                    |
| **Leaderboards / Gamification**       | Not aligned with "sanctuary" positioning; encourages unhealthy competition                                   |
| **Algorithm-Driven Recommendations**  | Users curate their own discovery via filters; we don't manipulate reading choices                            |

---

## ��� Monetization Strategy (Personal-Only Edition)

### Revenue Streams

| Stream                        | Mechanism                                                       | Projected Monthly (100 Active Users)             | Projected Monthly (1000 Active Users) |
| ----------------------------- | --------------------------------------------------------------- | ------------------------------------------------ | ------------------------------------- |
| **Pro Subscription**          | $2.99/mo or $24.99/yr for advanced features                     | $300 (10% conversion)                            | $3,000 (10% conversion)               |
| **Amazon Affiliate**          | "Buy on Amazon" button on each book; 3% commission on purchases | $50-150 (users buy avg 2-5 books/mo at $15/book) | $500-1,500                            |
| **Bookshop.org Affiliate**    | Alternative affiliate for users avoiding Amazon; 10% commission | $20-50                                           | $200-500                              |
| **Audible Affiliate**         | Audiobook links + referrals; 3% commission or $5/signup         | $10-30 (audiobook readers)                       | $100-300                              |
| **In-App Ads (Optional)**     | Banner/interstitial ads for free users; removed for Pro         | $20-50                                           | $200-500                              |
| \***\*TOTAL MONTHLY REVENUE** |                                                                 | **$400 - $630**                                  | **$4,000 - $6,300**                   |

### Pricing Tiers (Benchmarked vs. Competitors)

**Competitive Context**:

- **Goodreads**: Free (no premium tier)
- **StoryGraph Plus**: $3.99/mo or $39.99/yr
- **Spicy Reads Pro**: $2.99/mo or $24.99/yr (premium positioning, lower friction entry)

| Tier     | Features                                                                                                                                                                                  | Price                         | Target User                                |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- | ------------------------------------------ |
| **Free** | Track up to 100 books, basic trope search (1-3 tags), hard stops + kink filter, reading status, 3 lists                                                                                   | **$0/mo**                     | Casual romance readers (discovery phase)   |
| **Pro**  | ✅ Unlimited books ✅ Advanced trope search (unlimited) ✅ Reading analytics (dashboard + exports) ✅ Custom filters (saved searches) ✅ Audiobook tracking ✅ No ads ✅ Priority support | **$2.99/mo** or **$24.99/yr** | Serious readers; 5-10% conversion expected |

### Pro Feature Breakdown (vs. Competitors)

| Feature                          | StoryGraph Plus | Goodreads | Spicy Reads Pro       |
| -------------------------------- | --------------- | --------- | --------------------- |
| **Unlimited books**              | ✅              | ✅        | ✅                    |
| **Advanced mood/filter search**  | ✅              | ❌        | ✅                    |
| **Reading statistics dashboard** | ✅              | ❌        | ✅ (with export)      |
| **Saved custom filters**         | ❌              | ❌        | ✅ (Spicy Reads edge) |
| **Hard stops alerting**          | Basic           | ❌        | ✅ Advanced           |
| **Audiobook format tracking**    | ✅              | ✅        | ✅                    |
| **No ads**                       | ✅              | ✅        | ✅                    |
| **Spice-specific features**      | ❌              | ❌        | ✅ (MOAT)             |
| **Price**                        | $3.99/mo        | Free      | $2.99/mo              |

---

## ⚡ Competitive Strategy: Why Spicy Reads Wins

**Spicy Reads Pro positioning**: "The most affordable, spice-optimized reading tracker."

### What Makes Pro Worth $2.99/mo:

1. **Audiobook Listening Tracking** 📻

   - Track audiobooks separately from physical/digital
   - Link to Audible affiliate (earn on referrals)
   - Spicy Reads + StoryGraph both support; Goodreads doesn't

2. **Saved Custom Filters** (Spicy Reads Edge)

   - "Dark Romance + No Cheating + 4+ Spice" → saved as "My Perfect Dark Read"
   - One-tap search re-run
   - StoryGraph doesn't offer this; neither does Goodreads

3. **Advanced Hard Stops Dashboard**

   - Track which books triggered your hard stops
   - Export "avoided" list
   - Only Spicy Reads does this

4. **Reading Analytics + Export**

   - Monthly spice trends
   - Books by format (physical vs. audiobook)
   - Export as PDF for personal records
   - StoryGraph has charts; Spicy Reads goes deeper on spice metrics

5. **Priority Support** (email, in-app help)
   - Faster response vs. free tier (24h vs. 72h)

---

## ⚡⚡⚡ STRATEGIC PIVOT: Hybrid Community + Personal Model (v0.8.0+)

**Key Insight**: Separate **canonical/librarian books** from **community-contributed books** + **personal libraries**.

This allows us to:

- ✅ Maintain privacy (personal libraries stay private)
- ✅ Enable community contribution (librarians + trusted users expand catalog)
- ✅ Give users control (toggle content warnings, hard stops, spoiler warnings on/off)
- ✅ Support diverse reading (Kindle-only, audiobook-only, format preferences)
- ✅ Avoid moderation hell (librarians curate, not crowdsourced voting)

### What Librarians Add to Canonical Books

**Canonical Books** = Librarian-curated library + Google Books API base data

- Page count, publication date, publisher (auto-fetched)
- **Spice metadata**: Common hard stops, common tropes (verified by librarians)
- **Content warnings**: Aggregated from reader reviews (no voting, just patterns)
- **Narrator names** (for audiobooks)
- **Format availability** (ebook, audiobook, physical)

**User Libraries** = Personal tracking only (stays private)

- Personal spice rating (0-5 flames)
- Personal hard stops (private, only used for filtering)
- Personal tropes tagged
- Reading status, dates, personal notes

### Settings: What Users Can Toggle

1. **Content Warning Display**

   - ☑️ Show full warnings (default, transparent)
   - ☐ Hide warnings (read blind)
   - ☐ Show only hard stops (hide mild warnings)

2. **Preferred Formats**

   - ☑️ Paperback
   - ☑️ Ebook
   - ☑️ Audiobook
   - Filter out unsupported formats from search/browse

3. **Hard Stops Visibility**

   - ☑️ Show hard stops for this book (auto-filter)
   - ☐ Hide hard stops (let me discover)
   - ☐ Spoiler mode (show warnings only after reading)

4. **Review Form Customization**
   - ☑️ Spice rating
   - ☑️ Hard stops check
   - ☐ Tropes (optional)
   - ☑️ Content warnings
   - ☐ Emotional arc (optional)

### Architecture: Three Book Collections

```
📚 /books (Canonical - Librarian-Curated)
  - title, author, image, description
  - pageCount, publishedDate, publisher
  - genres, cachedTropes, cachedWarnings
  - isPreSeeded: true/false
  - librarian: "email@librarian.com" (who added/verified)
  - lastVerifiedDate: ISO timestamp
  - confidence: "high" | "medium" (based on source)

📚 /community-books (User-Contributed - Needs Librarian Review)
  - Same as /books BUT
  - status: "pending" | "approved" | "rejected"
  - submittedBy: userId
  - reviewedBy: librarian userId
  - votesUp: 5 (community feedback, not binding)
  - approvalNotes: "Added narrator info from Audible"

📚 /user-libraries/{userId}/books (Personal - Private)
  - userBook data (no librarian review needed)
  - personalSpiceRating, personalWarnings, personalNotes
  - never shared unless user explicitly exports
```

---

## ⚡ Phase 0: IMMEDIATE PRIORITIES (Next 30 Days)

**Goal**: Launch beta with critical friction-reducing features. Move from "feature-complete" to "user-ready."

### Week 1-2: Content Seeding (500-1000 Books via Google Books API)

**Why**: New users land in blank library → abandon app. Pre-seeding gives them 500-1000 books to browse on day 1.

**Implementation**:

1. **Build bulk import script** (Node.js + Google Books API)
   - Query popular romance keywords: "contemporary romance", "paranormal romance", "historical romance", "spicy romance", etc.
   - Use Google Books API to fetch books (max 40/query, respect rate limits)
   - Extract: title, author, cover art (image URL), description, page count, genres
   - Store in `/books` Firestore collection with `isPreSeeded: true` flag
   - Script: `tools/seed_romance_books.js`
2. **Manual curation** (50-100 highly-spicy books)
   - Hand-pick 50-100 known-spicy romance books (e.g., "The Hating Game", "Red Rising", etc.)
   - Look up each via Google Books API
   - Manually add metadata: `cachedTopWarnings`, `cachedTropes`
   - These become "exemplars" for the filtering system
3. **Firestore schema for pre-seeded books**:
   ```json
   {
     "id": "google_books_volume_id",
     "isbn": "9781234567890",
     "title": "The Hating Game",
     "authors": ["Sally Thorne"],
     "imageUrl": "https://books.google.com/books/content?id=...",
     "description": "...",
     "publishedDate": "2016-10-04",
     "pageCount": 384,
     "genres": ["Contemporary Romance", "Enemies to Lovers"],
     "cachedTopWarnings": ["sexual content", "workplace romance"],
     "cachedTropes": ["Enemies to Lovers", "Banter", "Forced Proximity"],
     "averageSpice": null,
     "ratingCount": 0,
     "isPreSeeded": true
   }
   ```

**Deliverable**: 500-1000 books in Firestore with metadata; users can search/filter immediately.

**Time Estimate**: 3-4 days (API bulk import + manual curation).

---

### Week 2-3: Onboarding Funnel (Critical UX)

**Why**: Users need to set Hard Stops + Kink Filters BEFORE seeing library. Current UX: blank library → abandon.

**New Onboarding Flow**:

1. **Post-Login Screen 1**: "Protect Yourself First"
   - Intro text: "We'll filter books based on your comfort level."
   - Button: "Let's Set Hard Stops"
2. **Post-Login Screen 2**: "Add Hard Stops" (Content You Absolutely Won't Read)
   - Pre-defined list of 20 common warnings: Dubcon, Infidelity, Violence, Non-Consent, Abuse, etc.
   - Multi-select chips
   - "Save & Continue"
3. **Post-Login Screen 3**: "Add Kink Filters" (Optional: Tropes to Exclude)
   - Pre-defined list of 30 common tropes: A/B/O, Ménage, BDSM, Humiliation, etc.
   - Multi-select chips
   - "Save & Continue"
4. **Post-Login Screen 4**: "Pick Favorite Tropes" (Optional: What You LOVE)
   - Pre-defined list of 40 popular tropes: Grumpy-Sunshine, Forced Proximity, Fake Dating, etc.
   - Multi-select chips
   - "Save & Discover"
5. **Post-Login Screen 5**: "Your Curated Library" (Results)
   - Show 10 books from pre-seeded collection that match their preferences
   - Button: "Add These" or "Browse All Books"

**Deliverable**: Complete onboarding flow; users see 10 curated books on day 1.

**Time Estimate**: 3-4 days (UI + logic).

---

### Week 3: Amazon Affiliate Integration

**Why**: Zero revenue without it. Affiliate is low-friction, high-upside. Every book needs a "Buy on Amazon" link.

**Implementation**:

1. **Generate affiliate links** (3-5% commission)
   - Format: `https://amazon.com/s?k=[ISBN]&tag=spicyreads-20` (replace with actual associate ID)
   - OR use Amazon Product Advertising API (1000 lookups/month free)
2. **Add "Buy on Amazon" button** to BookDetailScreen
   - Green button below book description
   - Opens affiliate link in browser
   - Track clicks via Firebase Analytics
3. **Affiliate disclosure** (required by Amazon)
   - Add to ProfileScreen legal section: "Spicy Reads is a participant in the Amazon Services LLC Associates Program"
   - Add tooltip to "Buy" button: "Spicy Reads earns from qualifying purchases"

**Deliverable**: Every book has affiliate link; users can purchase directly; affiliate revenue tracking live.

**Time Estimate**: 1-2 days.

---

### Week 4: Polish + Beta Launch

**Checklist**:

- [ ] Test onboarding end-to-end (5 test accounts)
- [ ] Verify affiliate links work (test clicks + URLs)
- [ ] Check analyzer for errors (0 issues)
- [ ] Update pubspec.yaml version to 0.6.0+1
- [ ] Update ROADMAP.md with personal-only strategy
- [ ] Create BETA_TESTING.md (how to invite beta testers)
- [ ] Deploy to Play Store closed testing track
- [ ] Invite 50-100 beta testers (Reddit /r/RomanceAuthors, Discord, Twitter)

**Deliverable**: Public beta (closed testing); collect feedback; iterate based on retention metrics.

**Time Estimate**: 2-3 days (testing + deployment).

---

## ⚡⚡ Librarian Program (Starts v0.6.0, Ramps v0.7.0+)

**Goal**: Build a trusted community of romance "librarians" who curate and expand the canonical book database.

### Who Are Librarians?

- **Expert romance readers** (self-identified)
- **Content creators** (BookTok, BookTube, bloggers)
- **Published romance authors** (expand own catalogs)
- **Community moderators** (from Reddit, Discord romance communities)
- **Spicy romance enthusiasts** who know the tropes + triggers

### What Librarians Do

1. **Verify & Enhance Canonical Books** (Monthly curations)
   - Confirm spice ratings for popular books
   - Add missing metadata: narrators, audiobook runtime, edition-specific warnings
   - Flag books missing from Google Books API that should be added manually
   - Review user-submitted book corrections

2. **Submit New Books to Canonical DB** (if missing from Google Books API)
   - Add indie-published spicy romance (often missing from Google Books)
   - Add international romance titles
   - Add niche sub-genres (paranormal, paranormal romance, PNR-specific tropes)
   - Include full metadata: page count, publication date, publisher, narrator

3. **Create Seasonal Curations** (4x/year)
   - Q1: "Emotional Winters" (cozy, found family)
   - Q2: "Summer Flings" (contemporary, beach romance)
   - Q3: "Fall Dark Reads" (paranormal, dark romance)
   - Q4: "Holiday Spice" (festive romance, holiday romance)
   - Format: 20-30 books per curation with librarian's "why I chose this" note

4. **Moderate Community Submissions** (if we enable user-contributed books later)
   - Review pending books in /community-books collection
   - Approve/reject based on accuracy + completeness
   - Suggest edits to submitters (e.g., "Add narrator name from Audible")

### Benefits for Librarians

- **Prestige**: "Verified Librarian" badge in app + on profile
- **Early access**: Beta features, Pro account free during tenure
- **Monthly stipend** (after reaching 5K+ users): $50-100/month per librarian
- **Revenue share**: 5% of affiliate revenue generated from their curations
- **Community credit**: Public profile showing curations, books verified, books added

### Librarian Onboarding (v0.6.0+)

1. User signs up through "Become a Librarian" form
2. Answer questions:
   - How many romance books have you read?
   - Favorite subgenres/tropes?
   - Why do you want to help?
   - Can you commit 2-4 hours/month?
3. Admin review (manual approval)
4. Grant Librarian role in Firestore
5. Send access to librarian dashboard (Google Sheet → Firestore sync, or in-app UI)

### Success Metrics (Librarians)

- Target: 5-10 librarians by end of Year 1
- Target: 100 new books verified/added per librarian per month
- Target: 4 seasonal curations launched per year
- Target: <2 week average review time for community submissions

---

## ⚡⚡ User Preferences & Settings (v0.6.1+)

**Goal**: Let users customize how they interact with content warnings, hard stops, and review forms.

### Settings Screen Additions

```
┌─ Content Warnings
│  ☑️ Show full content warnings (default)
│  ☐ Hide warnings (read blind)
│  ☐ Show only hard stops (hide mild spoilers)
│
├─ Preferred Formats
│  ☑️ Paperback
│  ☑️ Hardcover
│  ☑️ Ebook
│  ☑️ Audiobook
│  [Books will filter by selected formats in search]
│
├─ Hard Stops Behavior
│  ☑️ Auto-filter hard stops (hide books with my hard stops)
│  ☐ Show hard stops books (let me discover blind)
│  ☐ Spoiler mode (show warnings only after I rate the book)
│
├─ Book Review Form
│  ☑️ Spice Rating (0-5 flames)
│  ☑️ Content Warnings Check
│  ☐ Tropes (optional)
│  ☑️ Emotional Arc Rating
│  ☐ Personal Notes (optional)
│  [Customize which fields appear when adding books to library]
│
├─ Reading Preference
│  Primarily read via:
│  ○ Physical books (paperback/hardcover)
│  ○ Ebook / Kindle
│  ○ Audiobook
│  ○ Mix of all formats
│  [Affects search ranking + recommendations]
│
└─ Privacy & Data
   ☑️ Allow librarians to see my verified book ratings
   ☐ Share my trending-tropes anonymously (helps improve AI filters)
```

### Implementation Details

1. **Settings Model** (Firestore)
   ```
   /users/{userId}/settings
   {
     "showContentWarnings": true,
     "showHardStops": true,
     "hardStopsBehavior": "auto-filter", // or "show" or "spoiler-mode"
     "preferredFormats": ["physical", "ebook", "audiobook"],
     "reviewFormFields": {
       "spiceRating": true,
       "contentWarnings": true,
       "tropes": false,
       "emotionalArc": true,
       "personalNotes": false
     },
     "primaryReadFormat": "mix",
     "privacyAllowLibrarianAccess": true,
     "privacyShareTrendingData": false
   }
   ```

2. **Settings UI** (Flutter)
   - New Settings tab in main navigation (or in ProfileScreen)
   - Toggles for each setting with explanatory text
   - Save preferences to Firestore on every change
   - Load preferences on app start + cache locally

3. **Filter & Display Logic**
   - BookDetailScreen checks `showContentWarnings` setting before displaying warnings
   - Search screen filters by `preferredFormats`
   - HardStopsFilter logic checks `hardStopsBehavior` setting
   - EditBookModal shows/hides fields based on `reviewFormFields`

### Success Metrics (Settings)

- **Adoption**: 60%+ users customize at least one setting
- **Read-Blind Usage**: 10-20% disable content warnings (track anonymously)
- **Format Preference**: 40% Kindle, 30% physical, 30% audiobook (expected distribution)
- **Review Form Customization**: 50%+ simplify form by disabling non-essential fields

---

## ⚡ Phase 1-4: Full Implementation Roadmap

### Phase 1: Foundation (v0.1.0 - v0.1.x) ✅ COMPLETED

**Status**: All items below are done.

- ✅ Project setup and Firebase configuration
- ✅ Theme and UI foundation (luxury dark mode)
- ✅ Authentication (Email/Password + Google)
- ✅ Age gate (18+ verification)
- ✅ Firestore security rules (personal-only data access)

---

### Phase 2: Core Features (v0.2.0 - v0.5.x) ✅ COMPLETED

**Status**: All items below are done.

- ✅ Book search via Google Books API
- ✅ Add books to personal library
- ✅ Reading status tracking (Want to Read, Reading, Finished)
- ✅ Spice Meter rating (0-5 flames + sub-categories)
- ✅ Content warnings tagging
- ✅ Trope tagging (personal, not crowdsourced)
- ✅ Hard Stops filter (blocks books with user's hard stops)
- ✅ Kink Filter (blocks books with user's excluded tropes)
- ✅ Personal notes on books
- ✅ Home dashboard (total books, avg spice, status breakdown)
- ✅ Library view with filtering by status/genre/tropes
- ✅ Book detail screen with full book info + user's personal data
- ✅ Lists/Collections (create custom shelves)

---

### Phase 3: Personal-Only Refinements (v0.6.0 - v0.7.x) ��� IN PROGRESS

**Goal**: Remove all community-facing features; optimize for personal tracking + privacy.

#### v0.6.0: Content Seeding + Onboarding (Week 1-4 of Phase 0 above)

- [ ] Seed 1000 pre-made books in Firestore
- [ ] Implement mandatory onboarding (Hard Stops → Kink Filters → Favorites → Curated Library)
- [ ] Add "Buy on Amazon" affiliate button to book detail screen
- [ ] Add affiliate disclosure to legal section

**Deliverable**: Users land in pre-curated library matching their preferences; affiliate revenue live.

#### v0.6.1: Warning Prompts for Hard Stops

**Goal**: When user opens a book containing their hard stop, show warning before reading.

**Implementation**:

1. In BookDetailScreen, check if book's warnings overlap with user's hard stops
2. If yes, show modal before displaying book content:

   ```
   ⚠️ WARNING: Mental Health Alert

   This book contains: [Hard Stop 1], [Hard Stop 2]

   These are on your hard stops list.

   [Cancel] [I Understand, Show Anyway] [Add to Ignore List]
   ```

3. Log warning shown (for analytics)

**Deliverable**: Users get explicit warnings; can still proceed with "Ignore" option.

#### v0.7.0: Reading Analytics Dashboard + Audiobook Support

**Goal**: Motivate Pro upgrade by showing personal reading insights; add audiobook tracking as Pro feature.

**Features**:

- Total books read (all time) + breakdown by format (physical, digital, audiobook)
- Books read this month / year + audiobook listening time
- Average spice rating across library
- Most common tropes in your library
- Reading streak (days with books added)
- Heatmap (books added per day)
- Audiobook metrics: total hours listened, avg listen time per book, books by narrator

**Audiobook Implementation**:

1. **Book Format Selection** (in edit modal)

   - Paperback, Hardcover, Ebook, Audiobook
   - One book entry per format (e.g., "Project Hail Mary" as Audiobook + Paperback)

2. **Audiobook-Specific Fields**

   - Narrator name(s)
   - Total runtime (hours:minutes)
   - Listening progress (hours listened)

3. **Audible Affiliate Integration**

   - "Listen on Audible" button (Audible affiliate link)
   - Track audiobook referrals separately
   - Revenue: $5 per signup or 3% commission on sales

4. **Stats Dashboard Updates**
   - Chart: Books by format (stacked bar)
   - Metric: Total audiobook hours listened
   - Metric: Average listener rating (audiobook vs. print experience)

**Gating**:

- Free: Format display only (no audiobook tracking)
- Pro: Full audiobook tracking + listening stats + Audible affiliate links

**Deliverable**: Dashboard visible on Home; audiobook support live; affiliate revenue from audiobook referrals.

**Time Estimate**: 1.5 weeks (format enum added, audiobook UI, stats integration, Audible API).

---

### Phase 4: Distribution & Monetization Growth (v1.0.0+, After Phase 0-2)

**Goal**: Sustainable user acquisition + retention via targeted distribution + advanced monetization.

#### v1.0.0: Android App Store Launch + Public Beta

- [ ] Final security audit (penetration testing)
- [ ] Final UI/UX polish (accessibility + performance)
- [ ] Create store listing + screenshots (highlight spice filters + hard stops)
- [ ] Submit to Play Store review
- [ ] Monitor reviews + ratings; fix critical issues
- [ ] Launch to production (100% rollout)
- [ ] Setup analytics tracking (Firebase, amplitude for cohort analysis)

**Target Metrics**:

- 1,000-5,000 installs in Month 1
- 30%+ Day 1 retention (onboarding quality signal)
- 15%+ Day 7 retention

#### v1.1.0: Distribution & User Acquisition ($1-2K marketing budget)

**Goal**: Get in front of spicy romance readers via organic + paid channels.

**Channels**:

1. **Community Outreach** (Free)

   - Reddit: r/RomanceAuthors, r/Booksubreddits, r/Romances (crosspost to 5-10 communities)
   - Discord: Join 10-15 romance communities; seed discussions organically
   - TikTok: Reach out to BookTok creators with 10K-100K followers; offer "featured collection" spots
   - Twitter: Daily spicy romance content (trending tropes, hard stops tips, user testimonials)
   - Email: Beta user newsletter (weekly curation of trending spice books)

2. **Paid Acquisition** (Budget: $500-1K)

   - Google Play Ads: $0.5-1.50 cost per install
   - TikTok ads: $5K minimum spend; test with $200 pilot
   - Reddit ads: r/Romances, r/RomanceReaders ($100-200 test budget)
   - Retargeting: Website visitors who don't download

3. **Content Partnerships** (Free/Revenue-Share)

   - Create "Spicy Romance Podcast" guests interviews (10-minute clips on TikTok/YouTube)
   - Partner with 3-5 book bloggers: embedded "Find These Books on Spicy Reads" filter tool
   - Monthly "Trending Spice Report" shared on romance subreddits + blogs

4. **Influencer Seeding** (Budget: $100-300)
   - Send 10-20 free "Pro" codes to micro-influencers (50K-500K followers)
   - Request honest review after 2 weeks of use
   - Track install source via UTM codes

**Deliverable**: 10,000+ impressions/month organic reach; 100-500 new users/month from paid + organic.

#### v1.2.0: Advanced Monetization

**Goal**: Increase ARPU (average revenue per user) from $0.40 to $0.80+.

**Strategies**:

1. **Freemium Tier Optimization**

   - Paywall test 1: Free users limited to 100 books; "Upgrade to add more" prompt at 90 books
   - Paywall test 2: Advanced filter builder free 3x/month; unlimited for Pro
   - A/B test messaging: "Unlimited filters" vs. "Save time with saved searches"

2. **Annual Subscription Upgrade** ($24.99/yr = $2.08/mo, 30% cheaper)

   - Promote annually during onboarding: "Save 30% with annual"
   - Target: 40-50% of Pro users on annual (higher LTV)

3. **Affiliate Revenue Diversification**

   - Audible affiliate links (established v0.7.0)
   - Kindle Unlimited links (affiliate commission)
   - Goodreads alternative (cross-platform imports)
   - Target: $200-500/month affiliate revenue from 500 active users

4. **Potential Premium Features** (Future, only if traction warrants)
   - Per-book spice level predictions (ML-based, not launched initially)
   - "Buy the book" direct e-commerce (not necessary yet; affiliate sufficient)
   - Author collaboration (pro feature; connect directly to authors for spice interviews)

**Deliverable**: Pro conversion improves to 12-15%; affiliate revenue grows to $300-500/month.

#### v1.3.0: iOS App Store Launch

- [ ] Xcode + iOS-specific configuration
- [ ] TestFlight beta testing (50-100 testers)
- [ ] Create iOS store listing (optimized for App Store algorithm)
- [ ] Submit to App Store review (typically 24-48h)
- [ ] Launch to iOS (ramp 10% → 50% → 100%)

**Target**: 30% of Android installs come from iOS (typical for niche apps).

---

## ��� Success Metrics & KPIs

### Phase 0 Metrics (30 Days)

| Metric              | Target          | Why                                        |
| ------------------- | --------------- | ------------------------------------------ |
| Beta testers signup | 50-100          | Gauge initial interest                     |
| Day 1 retention     | >50%            | Complete onboarding without bouncing       |
| Day 7 retention     | >25%            | Users come back after first week           |
| Books added/user    | 5-10            | Active usage indicator                     |
| Hard Stops set/user | 1-3 on avg      | Users engaging with mental health features |
| Affiliate clicks    | 5-10/user/month | Revenue indicator                          |

### Phase 1-2 Metrics (Play Store Launch)

| Metric                     | Target (Year 1) | Why                            |
| -------------------------- | --------------- | ------------------------------ |
| Installs                   | 10,000          | Reasonable for romance niche   |
| Daily Active Users (DAU)   | 500             | ~5% of installs                |
| Monthly Active Users (MAU) | 2,000           | ~20% of installs               |
| Pro conversion             | 5-10%           | $3K-6K/month recurring revenue |
| Affiliate revenue          | $50-100/month   | Secondary revenue stream       |
| App store rating           | >4.5 stars      | Quality indicator              |
| Crash-free users           | >98%            | Stability                      |
| Average session duration   | >5 minutes      | Engagement                     |

### Long-term Metrics (Year 2+)

| Metric                          | Target          | Why                          |
| ------------------------------- | --------------- | ---------------------------- |
| MAU                             | 10,000+         | Sustainable growth           |
| Pro conversion                  | 10-15%          | Improving monetization       |
| Affiliate revenue               | $500-1000/month | Grows with DAU               |
| Customer acquisition cost (CAC) | <$1             | Organic + referral driven    |
| Lifetime value (LTV)            | >$50            | Pro subscription + affiliate |

---

## ��� Strategic Recommendations: Next Steps

### Recommended 30-Day Action Plan

**Week 1**: Content Seeding

- Build Goodreads scraper (Python script)
- Seed 1000 books to Firestore
- Manually add metadata to top 100 books

**Week 2**: Onboarding

- Design 5-screen onboarding flow
- Implement Hard Stops + Kink Filters selection
- Wire to search/filter logic

**Week 3**: Monetization

- Add Amazon affiliate links to book details
- Implement affiliate analytics tracking
- Add legal disclosure

**Week 4**: Beta Launch

- Full end-to-end testing
- Deploy to Play Store closed testing
- Invite 50-100 beta testers
- Collect feedback + iterate

### Key Decisions to Make NOW

1. **Content Seeding Source**:

   - Google Books API bulk import (legal, free, respects rate limits)
   - Manual curation for top 50-100 spicy books
   - Recommendation: Google Books API gives us 500-1000 books to start; sufficient for day 1 UX

2. **Affiliate Program**:

   - Amazon only, or
   - Amazon + Bookshop.org (supports indie bookstores, more ethical)
   - Recommendation: Both (gives users choice)

3. **Beta Launch Size**:

   - Closed testing (50-100 users) or
   - Open beta (500+ users)
   - Recommendation: Start closed, expand to open after 2 weeks of good metrics

4. **First Revenue Target**:
   - $0 (focus on retention), or
   - $300/month by end of Q1 2026
   - Recommendation: $300/month is realistic; requires ~100 Pro users + affiliate clicks

---

## ��� Summary: Personal-Only Philosophy

**What We Are**: A personal book tracker obsessed with privacy + mental health protection.

**What We're NOT**: A social network, community platform, or algorithmic recommendation engine.

**Our Promise to Users**:

- ✅ Your data is yours; we never sell it
- ✅ Your preferences are private; we never share them
- ✅ Your hard stops are sacred; we block triggering content automatically
- ✅ Your library is beautiful; we help you organize YOUR reading journey

**How We Win**:

- Get privacy-conscious romance readers before Goodreads/Bookly do
- Build trust through data protection + mental health features
- Monetize through Pro subscription ($2.99/mo) + affiliate revenue ($50-100/mo per 100 users)
- Grow organically through Reddit, Discord, TikTok, Twitter (BookTok community)
- Retain users by making reading tracking beautiful, safe, and personal

---

**Version**: 0.6.0+1
**Last Updated**: November 11, 2025
**Next Review**: December 1, 2025 (Post-Beta-Launch)
