# Competitive Feature Analysis: What to Magpie from StoryGraph & Goodreads

## Strategic Overview

**Your Hybrid Model** beats both competitors because:

1. **Privacy**: No forced sharing (vs. StoryGraph/Goodreads)
2. **Customization**: Users control what they see (vs. fixed UI)
3. **Spice-First**: Built for romance readers, not general readers
4. **Librarian Curation**: Quality over crowdsourced voting

---

## Feature Categories to Adopt

### 1. DISCOVERY & BROWSING (StoryGraph Edge)

**What StoryGraph Does Well:**

- ✅ Mood-based filtering (Adventurous? Funny? Dark? Slow-paced?)
- ✅ Nested filters (Genre + Mood + Pace + Fiction/Nonfiction)
- ✅ Visual book cards with quick stats (⭐ 4.2, 287 pages, published 2020)
- ✅ "Currently Reading" queue visible on browse
- ✅ Quick-add buttons (+ Want to Read, + Currently Reading without leaving page)

**Action for Spicy Reads:**

```
v0.7.0 Planned: Advanced Filter Builder
- Spice Level (0-5) slider
- Mood: "Dark & Tense", "Sweet & Emotional", "Funny & Witty", "Intense & Steamy"
- Pace: "Fast-paced", "Slow-burn", "Mixed"
- Format: Physical, Ebook, Audiobook
- Trigger Avoidance: Hard Stops toggle
- Save as custom filter ("My Dark Romance + No Cheating" = one-tap reuse)
```

### 2. BOOK DETAIL & METADATA (Goodreads Strength)

**What Goodreads Shows:**

- ✅ Multiple edition tabs (paperback, hardcover, ebook, audiobook)
- ✅ Audiobook narrator + runtime visible
- ✅ Awards won (Goodreads Choice Awards, etc.)
- ✅ Related books / series navigation
- ✅ Community reviews (quote snippets)
- ✅ "Readers Also Enjoyed" sidebar
- ✅ Edition information (ISBN, publication date, publisher, pages)

**Action for Spicy Reads:**

```
v0.7.1 Planned: Book Detail Enhancements
- Format tabs: Paperback | Hardcover | Ebook | Audiobook
  (Let user switch between editions on same detail screen)
- Narrator name + runtime (audiobook-specific)
- Series info: Book 3 of 5 in "Dark Desires" series + quick nav to other books
- Related books: "If you liked this, you might like..." (librarian curated)
- Edition dropdown: Show page count + ISBN per edition
```

### 3. READING PROGRESS & STATUS (StoryGraph Innovation)

**What StoryGraph Does:**

- ✅ Track reading progress % (vs. Goodreads "# pages read")
- ✅ "Finished" date auto-calc based on pages + reading pace
- ✅ Did Not Finish (DNF) tracking with reason
- ✅ Reading pace visible in library ("234 pages/month")
- ✅ Audiobook listening progress (hours listened)

**Action for Spicy Reads:**

```
v0.7.2 Planned: Reading Progress Enhancement
- Reading status: Want to Read | Reading (with %) | Did Not Finish | Finished
- DNF reasons: "Too slow", "Too dark", "Didn't connect with characters", "Other"
- Reading pace calculated: "245 pages/month based on your history"
- Progress for audiobooks: "2h 15m / 10h 45m listened"
- Auto-suggest next book when finishing: "Based on your recent reads + preferences"
```

### 4. STATS & ANALYTICS (StoryGraph Nails This)

**What StoryGraph Shows:**

- ✅ Pie charts: Books by mood, pace, genres
- ✅ Line graphs: Books read over time (monthly)
- ✅ Heatmap: Which days of week you read
- ✅ Average page count per book
- ✅ Most-read authors
- ✅ Half & quarter stars (more granular than Goodreads)

**Action for Spicy Reads (Pro Feature):**

```
v0.8.0 Planned: Advanced Analytics Dashboard
- Spice rating trends (line graph: avg spice/month)
- Books by format (pie: 40% physical, 30% audiobook, 30% ebook)
- Tropes heatmap: Which tropes you read most (Grumpy-Sunshine: 25 books)
- Hard Stops avoided: "You avoided 5 books this month due to hard stops"
- Reading streaks: "45-day streak! 🔥"
- Export as PDF: "2024 Reading Year in Review"
```

### 5. LISTS & COLLECTIONS (Goodreads Feature)

**What Goodreads Does:**

- ✅ Create custom lists/shelves (unlimited)
- ✅ Sort lists by rating, date added, author
- ✅ Merge duplicate lists
- ✅ Public/private toggle per list
- ✅ Share lists (URL)
- ✅ Official lists ("Best Sci-Fi of 2024", etc.)

**Action for Spicy Reads:**

```
v0.6.2: Enhanced Lists (Already Partially Built)
- ✅ Create custom shelves (want to implement: unlimited)
- ✅ Sort by rating, date added, status, spice level
- 🚧 Coming: Public/private toggle (privacy-first)
- 🚧 Coming: Share via link (encrypted, read-only for non-users)
```

### 6. SEARCH & FILTERING (StoryGraph > Goodreads)

**What StoryGraph Does Better:**

- ✅ Multi-select filters (not checkbox sliders)
- ✅ "AND" logic only (no "OR" noise)
- ✅ Quick filters on sidebar (sticky while browsing)
- ✅ "Clear filters" with one tap

**Action for Spicy Reads:**

```
✅ Already built: Deep Trope Search (multi-select)
- Genre + 2-10 tropes + reading status + ownership type
- AND logic only (user expectations match)
Planned: Surface this better in UI (make it more discoverable)
```

### 7. SOCIAL FEATURES (Privacy-Respecting Version)

**What Goodreads Does (We'll Skip):**

- ❌ Public profiles, followers, reading activity feed (privacy risk)
- ❌ Community ratings, reviews, voting (moderation nightmare)

**What Spicy Reads Can Do Privately:**

```
v1.0+: Optional Social (Opt-In, Not Default)
- Share reading goals via private link: "I want to read 30 spicy books in 2025"
- Buddy read (encrypted, only with friends who have app + know link)
- Private group chats (Discord-style, 2-10 people, invite-only)
- Do NOT: Public profiles, public libraries, community voting
```

### 8. ACCESSIBILITY & CUSTOMIZATION (Opportunity Gap)

**What Neither Does Well:**

- ❌ Customizable warning display (show all / show none / show only hard stops)
- ❌ Preference for "reading blind" (vs. seeing all warnings upfront)
- ❌ Format preferences (Kindle-only, audiobook-only readers)
- ❌ Review form customization (show only fields I care about)

**Action for Spicy Reads (MAJOR DIFFERENTIATOR):**

```
✅ v0.6.1: User Preferences Settings
- Content warning display: Show Full | Hide All | Only Hard Stops
- Hard stops behavior: Auto-Filter | Show All | Spoiler Mode (show after reading)
- Preferred formats: Physical ☑ Ebook ☑ Audiobook ☑
- Review form customization: Pick which fields to see
- Primary read format: Physical | Ebook | Audiobook | Mixed
- Privacy: Allow librarians to see ratings | Share trending data (opt-in)
```

---

## Feature Priority Matrix (What to Build When)

### Phase 0 (Next 30 Days) - Must Have

- ✅ Audiobook format tracking
- ✅ Settings screen (User Preferences)
- ✅ Content warning display toggle
- ✅ Librarian program onboarding

### Phase 1 (Weeks 5-8) - High Impact

- 🚧 Advanced filter builder (mood + pace + spice)
- 🚧 Format tabs on book detail (paperback | ebook | audiobook)
- 🚧 Series navigation
- 🚧 DNF tracking with reasons

### Phase 2 (Weeks 9-12) - Growth

- 🔲 Reading analytics dashboard (Pro feature)
- 🔲 Progress % for reading status
- 🔲 Heatmaps + trending stats
- 🔲 PDF export for annual reading review

### Phase 3 (Month 4+) - Polish

- 🔲 Related books suggestions
- 🔲 Optional private sharing
- 🔲 Author spotlights (librarian curated)
- 🔲 Seasonal collections

---

## What NOT to Copy

### Goodreads Mistakes

- ❌ Public profiles by default (privacy nightmare)
- ❌ Amazon integration overreach (platform dependency)
- ❌ Slow app performance (no excuse in 2025)
- ❌ Community voting (quality death spiral)

### StoryGraph Gaps

- ❌ Doesn't support spice-specific filtering (YOUR MOAT)
- ❌ Generic "mood" doesn't capture romance nuance
- ❌ No hard stops / mental health features (YOUR EDGE)
- ❌ Limited audiobook support (opportunity)

---

## User Expectations Setting

**What We Tell Beta Users:**

> "Spicy Reads is different:
>
> ✅ **Privacy First**: Your library is yours alone. We never share your preferences.
>
> ✅ **Spice-Focused**: Built by romance readers, for romance readers. Hard stops + kink filters built in.
>
> ✅ **Customizable**: See what you want. Hide what you don't. Read blind or with warnings—your choice.
>
> ✅ **Librarian-Curated**: Books are verified by experts, not crowdsourced votes. Quality over quantity.
>
> ✅ **You're In Control**: Every field in the review form is optional. Your data, your rules."

---

## Firestore Schema Updates Needed

```
# Canonical Books (Librarian-Curated)
/books/{bookId}
{
  ...existing fields,
  "librarians": [
    {
      "userId": "lib_001",
      "email": "librarian@spicy.com",
      "verifiedDate": "2025-11-12",
      "changes": "Added audiobook narrator info"
    }
  ],
  "accuracy": "high" | "medium", // How trusted is this data?
  "audiobook": {
    "narrator": "Carly Robins",
    "runtime": "10h 45m",
    "audibleUrl": "affiliate link"
  }
}

# User Preferences (NEW)
/users/{userId}/preferences
{
  "contentWarningDisplay": "showFull",
  "preferredFormats": ["physical", "ebook", "audiobook"],
  "hardStopsBehavior": "autoFilter",
  "reviewFormFields": {
    "spiceRating": true,
    "contentWarnings": true,
    "tropes": false,
    "emotionalArc": true,
    "personalNotes": false
  },
  "primaryReadFormat": "mixed",
  "privacyAllowLibrarianAccess": true,
  "privacyShareTrendingData": false
}

# Librarian Roles (NEW)
/admins/librarians/{userId}
{
  "email": "librarian@spicy.com",
  "status": "active" | "pending" | "inactive",
  "role": "librarian",
  "approvedDate": "2025-11-12",
  "monthlyStipend": 50,
  "affiliation": "BookTok creator | Author | Community moderator",
  "stats": {
    "booksVerified": 245,
    "booksAdded": 18,
    "curationsCreated": 4
  }
}
```

---

## Competitive Positioning Revised

| Feature            | Goodreads | StoryGraph | Spicy Reads | Edge               |
| ------------------ | --------- | ---------- | ----------- | ------------------ |
| Spice-focused      | ❌        | ❌         | ✅          | **Only one**       |
| Hard stops filter  | ❌        | ❌         | ✅          | **Only one**       |
| Privacy by default | ❌        | Partial    | ✅          | **Strongest**      |
| Customizable UI    | ❌        | ❌         | ✅          | **Differentiator** |
| Librarian curation | ❌        | ❌         | ✅          | **Unique**         |
| Audiobook support  | Basic     | ✅         | ✅          | Par                |
| Analytics          | Basic     | ✅         | ✅          | Parity (Pro)       |
| Discovery filters  | Basic     | ✅         | Planned     | Parity (v0.7)      |

---

## Next Steps

1. **Immediate** (Next 2 weeks):

   - [ ] Implement UserPreferences model + settings UI
   - [ ] Add audiobook narrator + runtime fields
   - [ ] Create librarian onboarding form
   - [ ] Update book detail screen with format tabs

2. **Short-term** (Weeks 3-4):

   - [ ] Advanced filter builder UI
   - [ ] Series navigation
   - [ ] DNF tracking

3. **Medium-term** (Weeks 5-8):

   - [ ] Analytics dashboard (Pro-gated)
   - [ ] Reading progress %
   - [ ] Related books suggestions

4. **Beta Launch Readiness**:
   - [ ] Test all new features with 10-20 beta users
   - [ ] Get librarian feedback on curation workflow
   - [ ] Measure engagement: 30%+ day-7 retention target
