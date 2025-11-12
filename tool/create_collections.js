#!/usr/bin/env node

/**
 * Create curated collections from pre-seeded books
 *
 * Usage:
 *   node tool/create_collections.js
 *
 * This script:
 * 1. Queries Firestore for all books where isPreSeeded == true
 * 2. Groups them by genre/category
 * 3. Creates curated collection docs in the 'collections' collection
 * 4. Each collection contains a bookIds array of representative books
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
let db;
try {
  const serviceAccountPath = path.join(__dirname, '../service-account.json');
  if (!fs.existsSync(serviceAccountPath)) {
    console.error('❌ service-account.json not found at:', serviceAccountPath);
    process.exit(1);
  }

  const serviceAccount = JSON.parse(
    fs.readFileSync(serviceAccountPath, 'utf8'),
  );

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  db = admin.firestore();
  console.log('✅ Firebase initialized\n');
} catch (error) {
  console.error('❌ Firebase initialization failed:', error.message);
  process.exit(1);
}

/**
 * Categorize books by genre
 * Returns object: { categoryName: [bookIds...] }
 */
function categorizeBooks(books) {
  const categories = {
    'Dark Romance': [],
    'Paranormal Romance': [],
    'Small Town Romance': [],
    'Romantic Suspense': [],
    'Contemporary Romance': [],
  };

  // Keywords to match for each category
  const categoryKeywords = {
    'Dark Romance': ['dark', 'mafia', 'biker', 'motorcycle'],
    'Paranormal Romance': [
      'paranormal',
      'shifter',
      'wolf',
      'vampire',
      'supernatural',
      'fated mates',
    ],
    'Small Town Romance': ['small town', 'small-town'],
    'Romantic Suspense': ['suspense', 'mystery', 'thriller'],
    'Contemporary Romance': [
      'contemporary',
      'billionaire',
      'workplace',
      'grumpy',
      'enemies to lovers',
    ],
  };

  // Helper: check if book title/genres match keywords
  function matchesCategory(book, keywords) {
    const titleLower = (book.title || '').toLowerCase();
    const authorsLower = (book.authors || []).join(' ').toLowerCase();
    const genresLower = (book.genres || []).join(' ').toLowerCase();
    const descLower = (book.description || '').toLowerCase();

    return keywords.some(
      (keyword) =>
        titleLower.includes(keyword) ||
        authorsLower.includes(keyword) ||
        genresLower.includes(keyword) ||
        descLower.includes(keyword),
    );
  }

  // Assign books to categories (a book can be in multiple)
  for (const book of books) {
    let assigned = false;

    for (const [category, keywords] of Object.entries(categoryKeywords)) {
      if (matchesCategory(book, keywords)) {
        categories[category].push(book.id);
        assigned = true;
      }
    }

    // If no category matched, add to Contemporary Romance as fallback
    if (!assigned) {
      categories['Contemporary Romance'].push(book.id);
    }
  }

  return categories;
}

/**
 * Create collection documents
 */
async function createCollections() {
  console.log('🔍 Fetching all pre-seeded books from Firestore...\n');

  try {
    // Query all books where isPreSeeded == true
    const booksSnapshot = await db
      .collection('books')
      .where('isPreSeeded', '==', true)
      .limit(1000)
      .get();

    if (booksSnapshot.empty) {
      console.error('❌ No pre-seeded books found. Run seed script first.');
      process.exit(1);
    }

    const books = [];
    booksSnapshot.forEach((doc) => {
      books.push({
        id: doc.id,
        ...doc.data(),
      });
    });

    console.log(`✅ Found ${books.length} pre-seeded books\n`);

    // Categorize books
    console.log('📂 Categorizing books...\n');
    const categories = categorizeBooks(books);

    // Create collection documents
    console.log('📝 Creating collection documents...\n');

    const collectionsData = [
      {
        id: 'editors_picks',
        title: "Editor's Picks",
        description:
          'Our hand-curated selection of the best romance reads from across all subgenres.',
        isFeatured: true,
        bookIds: [],
      },
      {
        id: 'dark_romance',
        title: 'Dark Romance',
        description:
          'Intense, complex relationships with darker themes and anti-heroes.',
        isFeatured: false,
        bookIds: categories['Dark Romance'],
      },
      {
        id: 'paranormal_romance',
        title: 'Paranormal Romance',
        description:
          'Supernatural elements, shifters, vampires, and fated mates.',
        isFeatured: false,
        bookIds: categories['Paranormal Romance'],
      },
      {
        id: 'small_town_romance',
        title: 'Small Town Romance',
        description: 'Cozy, intimate stories set in small communities.',
        isFeatured: false,
        bookIds: categories['Small Town Romance'],
      },
      {
        id: 'romantic_suspense',
        title: 'Romantic Suspense',
        description: 'Thrilling plots with romance and mystery woven together.',
        isFeatured: false,
        bookIds: categories['Romantic Suspense'],
      },
      {
        id: 'contemporary_romance',
        title: 'Contemporary Romance',
        description:
          'Modern stories with billionaires, workplaces, and grumpy heroes.',
        isFeatured: false,
        bookIds: categories['Contemporary Romance'],
      },
    ];

    // For "Editor's Picks", include a diverse sample from all categories
    const sampleSize = 15;
    const allBookIds = Object.values(categories).flat();
    const shuffled = allBookIds.sort(() => Math.random() - 0.5);
    collectionsData[0].bookIds = shuffled.slice(0, sampleSize);

    // Write to Firestore
    const batch = db.batch();

    for (const collection of collectionsData) {
      const docRef = db.collection('collections').doc(collection.id);
      batch.set(docRef, {
        title: collection.title,
        description: collection.description,
        isFeatured: collection.isFeatured,
        bookIds: collection.bookIds.slice(0, 50), // Cap at 50 books per collection for performance
        publishedAt: new Date().toISOString(),
        createdAt: new Date().toISOString(),
      });
    }

    await batch.commit();

    console.log('✅ Collections created successfully!\n');
    console.log('Summary:');
    for (const collection of collectionsData) {
      console.log(
        `  - ${collection.title}: ${collection.bookIds.length} books`,
      );
    }

    console.log('\n📱 You can now use these collections in your Flutter app!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating collections:', error.message);
    process.exit(1);
  }
}

// Run
createCollections();
