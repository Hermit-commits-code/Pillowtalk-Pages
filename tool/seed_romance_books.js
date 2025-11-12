#!/usr/bin/env node

/**
 * Seed Spicy Reads with romance books from Google Books API
 * 
 * Usage:
 *   node tool/seed_romance_books.js [--dry-run] [--limit=100]
 * 
 * Environment Variables:
 *   GOOGLE_BOOKS_API_KEY: Your Google Books API key (optional, has rate limits without it)
 *   FIREBASE_PROJECT_ID: Your Firebase project ID
 * 
 * This script:
 * 1. Queries Google Books API for popular romance books
 * 2. Stores them in Firestore under /books collection
 * 3. Marks them with isPreSeeded: true for filtering
 */

const axios = require('axios');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Configuration
const GOOGLE_BOOKS_API_KEY = process.env.GOOGLE_BOOKS_API_KEY || '';
const GOOGLE_BOOKS_API_URL = 'https://www.googleapis.com/books/v1/volumes';
const DRY_RUN = process.argv.includes('--dry-run');
const LIMIT = parseInt(
  process.argv.find(arg => arg.startsWith('--limit='))?.split('=')[1] || '500',
  10
);

// Romance keywords to search
const ROMANCE_QUERIES = [
  'contemporary romance',
  'paranormal romance',
  'historical romance',
  'spicy romance',
  'romantic suspense',
  'fantasy romance',
  'LGBT romance',
  'romance enemies to lovers',
  'romance forced proximity',
  'romance grumpy sunshine',
];

// Initialize Firebase Admin SDK
let db;
try {
  const serviceAccountPath = path.join(__dirname, '../service-account.json');
  if (!fs.existsSync(serviceAccountPath)) {
    console.error('❌ service-account.json not found at:', serviceAccountPath);
    console.error('Please ensure your Firebase service account key is in the project root.');
    process.exit(1);
  }

  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id,
  });

  db = admin.firestore();
  console.log('✅ Firebase initialized');
} catch (error) {
  console.error('❌ Failed to initialize Firebase:', error.message);
  process.exit(1);
}

/**
 * Fetch books from Google Books API for a given query
 */
async function fetchBooksFromGoogle(query, maxResults = 40) {
  try {
    const params = {
      q: query,
      maxResults,
      printType: 'books',
      orderBy: 'newest',
    };

    if (GOOGLE_BOOKS_API_KEY) {
      params.key = GOOGLE_BOOKS_API_KEY;
    }

    const response = await axios.get(GOOGLE_BOOKS_API_URL, { params });
    const items = response.data.items || [];

    return items.map(item => parseGoogleBook(item)).filter(book => book !== null);
  } catch (error) {
    console.error(`❌ Error fetching books for query "${query}":`, error.message);
    return [];
  }
}

/**
 * Parse Google Books API response into our book schema
 */
function parseGoogleBook(item) {
  try {
    const volumeInfo = item.volumeInfo || {};
    const saleInfo = item.saleInfo || {};

    // Extract ISBN
    let isbn = '';
    const identifiers = volumeInfo.industryIdentifiers || [];
    for (const id of identifiers) {
      if (id.type === 'ISBN_13' || id.type === 'ISBN_10') {
        isbn = id.identifier;
        break;
      }
    }

    // Skip if no ISBN (can't reliably identify duplicates)
    if (!isbn) return null;

    // Extract cover image
    const imageLinks = volumeInfo.imageLinks || {};
    let imageUrl =
      imageLinks.extraLarge ||
      imageLinks.large ||
      imageLinks.medium ||
      imageLinks.thumbnail;

    if (imageUrl && imageUrl.startsWith('http:')) {
      imageUrl = imageUrl.replace('http:', 'https:');
    }

    // Extract genres
    const categories = volumeInfo.categories || [];
    const genres = categories.filter(cat => 
      cat.toLowerCase().includes('romance') ||
      cat.toLowerCase().includes('fiction')
    ).slice(0, 3);

    return {
      id: item.id,
      isbn,
      title: volumeInfo.title || 'Unknown Title',
      authors: volumeInfo.authors || ['Unknown Author'],
      imageUrl: imageUrl || null,
      description: volumeInfo.description || null,
      publishedDate: volumeInfo.publishedDate || null,
      pageCount: volumeInfo.pageCount || null,
      genres,
      cachedTopWarnings: [],
      cachedTropes: [],
      averageSpice: null,
      ratingCount: 0,
      isPreSeeded: true,
      createdAt: new Date().toISOString(),
    };
  } catch (error) {
    console.error('❌ Error parsing book:', error.message);
    return null;
  }
}

/**
 * Check if book already exists in Firestore (by ISBN)
 */
async function bookExists(isbn) {
  try {
    const snapshot = await db
      .collection('books')
      .where('isbn', '==', isbn)
      .limit(1)
      .get();
    return !snapshot.empty;
  } catch (error) {
    console.error('❌ Error checking book existence:', error.message);
    return false;
  }
}

/**
 * Save book to Firestore
 */
async function saveBook(book) {
  try {
    const docRef = db.collection('books').doc(book.id);
    if (DRY_RUN) {
      console.log(`[DRY RUN] Would save: ${book.title} by ${book.authors.join(', ')}`);
      return true;
    }

    await docRef.set(book);
    return true;
  } catch (error) {
    console.error(`❌ Error saving book "${book.title}":`, error.message);
    return false;
  }
}

/**
 * Main seeding function
 */
async function seedBooks() {
  console.log('\n🌱 Starting Romance Books Seeding...\n');
  console.log(`Configuration:
  - Dry run: ${DRY_RUN}
  - Target books: ${LIMIT}
  - Queries: ${ROMANCE_QUERIES.length}
  - API Key: ${GOOGLE_BOOKS_API_KEY ? 'Provided' : 'Not provided (rate limits apply)'}
  \n`);

  let totalBooks = 0;
  let savedBooks = 0;
  let skippedBooks = 0;
  const seenISBNs = new Set();

  for (const query of ROMANCE_QUERIES) {
    if (totalBooks >= LIMIT) break;

    console.log(`📚 Querying: "${query}"`);
    const books = await fetchBooksFromGoogle(query, 40);

    for (const book of books) {
      if (totalBooks >= LIMIT) break;

      // Skip duplicates
      if (seenISBNs.has(book.isbn)) {
        skippedBooks++;
        continue;
      }

      seenISBNs.add(book.isbn);
      totalBooks++;

      // Check if already in Firestore
      const exists = await bookExists(book.isbn);
      if (exists) {
        console.log(`  ⏭️  Already exists: ${book.title}`);
        skippedBooks++;
        continue;
      }

      // Save book
      const saved = await saveBook(book);
      if (saved) {
        console.log(`  ✅ Saved: ${book.title} (${totalBooks}/${LIMIT})`);
        savedBooks++;
      } else {
        skippedBooks++;
      }

      // Respect rate limits: 1 API call per 100ms
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    console.log(`   Found ${books.length} books from this query\n`);
  }

  console.log('\n✨ Seeding Complete!\n');
  console.log(`Summary:
  - Total processed: ${totalBooks}
  - Saved: ${savedBooks}
  - Skipped (duplicates/errors): ${skippedBooks}
  - Mode: ${DRY_RUN ? 'DRY RUN' : 'LIVE'}
  \n`);

  if (DRY_RUN) {
    console.log('🔍 Dry run completed. Run without --dry-run to actually save books.\n');
  }

  process.exit(0);
}

// Run seeding
seedBooks().catch(error => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});
