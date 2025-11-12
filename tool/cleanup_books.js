#!/usr/bin/env node

/**
 * tool/cleanup_books.js
 *
 * Identify and remove books missing imageUrl and detect duplicates by ISBN/title.
 *
 * Usage (dry-run):
 *   node tool/cleanup_books.js
 *
 * Usage (apply deletions):
 *   node tool/cleanup_books.js --apply
 *
 * Flags:
 *   --apply          Actually delete flagged books (default: dry-run only)
 *   --only-no-image  Only remove books missing imageUrl (skip duplicate detection)
 *   --only-dupes     Only remove duplicates (keep all books even without imageUrl)
 */

const fs = require('fs');
const path = require('path');

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith('--')) continue;
    const key = a.slice(2);
    const next = argv[i + 1];
    if (!next || next.startsWith('--')) {
      args[key] = true;
    } else {
      args[key] = next;
      i++;
    }
  }
  return args;
}

function normalizeIsbn(isbn) {
  return (isbn || '').replace(/[^0-9Xx]/g, '').toLowerCase();
}

function normalizeTitle(title) {
  return (title || '')
    .toLowerCase()
    .replace(/[^\w\s]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

async function main() {
  const args = parseArgs(process.argv);
  const apply = !!args.apply;
  const onlyNoImage = !!args['only-no-image'];
  const onlyDupes = !!args['only-dupes'];

  let admin;
  try {
    admin = require('firebase-admin');
  } catch (e) {
    console.error(
      'firebase-admin required. Install with: npm install firebase-admin',
    );
    process.exit(1);
  }

  try {
    let credPath =
      process.env.GOOGLE_APPLICATION_CREDENTIALS ||
      path.join(__dirname, 'service-account.json');
    if (!fs.existsSync(credPath)) {
      const alt = path.join(
        __dirname,
        'archive_2025-11-12_1200',
        'service-account.json',
      );
      if (fs.existsSync(alt)) {
        credPath = alt;
        console.warn('Using archived service account at', credPath, '\n');
      } else {
        console.error(
          'Service account not found. Set GOOGLE_APPLICATION_CREDENTIALS or place service-account.json next to this script.',
        );
        process.exit(1);
      }
    }
    const serviceAccount = require(credPath);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  } catch (e) {
    console.error('Failed to initialize Firebase Admin:', e.message);
    process.exit(1);
  }

  const db = admin.firestore();

  try {
    console.log('Scanning books collection...\n');
    const snap = await db.collection('books').get();

    const books = [];
    snap.forEach((doc) => {
      books.push({
        id: doc.id,
        data: doc.data() || {},
      });
    });

    console.log(`Found ${books.length} total books.\n`);

    // Identify books missing imageUrl
    const noImage = [];
    const withImage = [];
    for (const book of books) {
      const img = book.data.imageUrl;
      if (!img || (typeof img === 'string' && img.trim() === '')) {
        noImage.push(book);
      } else {
        withImage.push(book);
      }
    }

    console.log(`Books WITHOUT imageUrl: ${noImage.length}`);
    console.log(`Books WITH imageUrl: ${withImage.length}\n`);

    // Detect duplicates (by ISBN or normalized title)
    const isbnMap = {};
    const titleMap = {};
    const duplicates = new Set();

    for (const book of books) {
      const isbns =
        (book.data.isbn &&
          (typeof book.data.isbn === 'string'
            ? [book.data.isbn]
            : book.data.isbn)) ||
        [];
      for (const isbn of isbns) {
        const clean = normalizeIsbn(isbn);
        if (clean) {
          if (isbnMap[clean]) {
            // Duplicate ISBN found
            duplicates.add(book.id);
            duplicates.add(isbnMap[clean]);
          } else {
            isbnMap[clean] = book.id;
          }
        }
      }

      const title = book.data.title || '';
      const norm = normalizeTitle(title);
      if (norm && norm.length > 3) {
        if (titleMap[norm]) {
          // Potential duplicate title (weaker match; mark but review)
          duplicates.add(book.id);
          duplicates.add(titleMap[norm]);
        } else {
          titleMap[norm] = book.id;
        }
      }
    }

    console.log(`Duplicate books detected: ${duplicates.size}\n`);

    // Decide what to delete
    const toDelete = new Set();

    if (!onlyDupes) {
      for (const book of noImage) {
        toDelete.add(book.id);
      }
    }

    if (!onlyNoImage) {
      for (const id of duplicates) {
        toDelete.add(id);
      }
    }

    if (toDelete.size === 0) {
      console.log('No books to remove. Exiting.');
      process.exit(0);
    }

    console.log(`\n=== DRY RUN: Would remove ${toDelete.size} books ===\n`);

    const deleteList = Array.from(toDelete).map((id) => {
      const book = books.find((b) => b.id === id);
      const reason = noImage.some((b) => b.id === id)
        ? 'missing-imageUrl'
        : 'duplicate';
      return {
        id,
        title: book.data.title || '(no title)',
        author: book.data.authors ? book.data.authors[0] || '?' : '?',
        reason,
      };
    });

    // Sort by reason then title for readability
    deleteList.sort(
      (a, b) =>
        a.reason.localeCompare(b.reason) || a.title.localeCompare(b.title),
    );

    // Print summary by reason
    const byReason = {};
    for (const item of deleteList) {
      if (!byReason[item.reason]) byReason[item.reason] = [];
      byReason[item.reason].push(item);
    }

    for (const reason of Object.keys(byReason).sort()) {
      console.log(`${reason.toUpperCase()}: ${byReason[reason].length} books`);
      byReason[reason].slice(0, 5).forEach((item) => {
        console.log(`  - ${item.id} | ${item.title} by ${item.author}`);
      });
      if (byReason[reason].length > 5) {
        console.log(`  ... and ${byReason[reason].length - 5} more`);
      }
      console.log();
    }

    if (!apply) {
      console.log(
        `\n✅ Dry-run complete. To apply deletions, re-run with --apply`,
      );
      process.exit(0);
    }

    // Apply deletions
    console.log(
      `\n⚠️  APPLYING DELETIONS... deleting ${toDelete.size} books\n`,
    );

    const batch = db.batch();
    let batchCount = 0;

    for (const id of toDelete) {
      batch.delete(db.collection('books').doc(id));
      batchCount++;

      if (batchCount % 500 === 0) {
        await batch.commit();
        console.log(`  Deleted ${batchCount} books...`);
        batch.clear(); // reset batch for next set
      }
    }

    if (batchCount % 500 !== 0) {
      await batch.commit();
    }

    console.log(`\n✅ Deleted ${toDelete.size} books successfully`);
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

main();
