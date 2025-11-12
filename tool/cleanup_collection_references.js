#!/usr/bin/env node

/**
 * Cleanup Collection References
 *
 * Removes bookIds from collections that no longer exist in the books collection.
 * This is needed after deleting books to keep collections in sync with the canonical books.
 *
 * Usage:
 *   node tool/cleanup_collection_references.js              # dry-run (show what would be removed)
 *   node tool/cleanup_collection_references.js --apply      # actually remove the references
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
let serviceAccount;

// Try to get service account from environment variable first
if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
  try {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
  } catch (err) {
    console.error(
      '❌ Error: Could not parse FIREBASE_SERVICE_ACCOUNT_JSON environment variable',
    );
    process.exit(1);
  }
} else {
  // Fallback to local file
  const serviceAccountPath = path.join(__dirname, '../service-account.json');
  try {
    serviceAccount = require(serviceAccountPath);
  } catch (err) {
    console.error(`❌ Error: Could not load service account`);
    console.error(
      `   Option 1: Set FIREBASE_SERVICE_ACCOUNT_JSON environment variable`,
    );
    console.error(
      `   Option 2: Create service-account.json in the project root`,
    );
    process.exit(1);
  }
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const dryRun = !process.argv.includes('--apply');

async function main() {
  console.log('🔍 Cleaning up collection references...\n');

  try {
    // Get all book IDs that exist
    console.log('📚 Fetching all books from canonical collection...');
    const booksSnapshot = await db.collection('books').select('__name__').get();
    const existingBookIds = new Set(booksSnapshot.docs.map((doc) => doc.id));
    console.log(
      `   Found ${existingBookIds.size} books in canonical collection\n`,
    );

    // Get all collections
    console.log('📂 Fetching all collections...');
    const collectionsSnapshot = await db.collection('collections').get();
    console.log(`   Found ${collectionsSnapshot.size} collections\n`);

    let totalRemoved = 0;
    let collectionsModified = 0;

    // For each collection, check for missing book references
    for (const collectionDoc of collectionsSnapshot.docs) {
      const data = collectionDoc.data();
      const bookIds = Array.isArray(data.bookIds) ? data.bookIds : [];

      // Filter out book IDs that don't exist
      const validBookIds = bookIds.filter((id) => existingBookIds.has(id));
      const removedCount = bookIds.length - validBookIds.length;

      if (removedCount > 0) {
        console.log(`📋 Collection: ${collectionDoc.id}`);
        console.log(`   Title: ${data.title || 'N/A'}`);
        console.log(`   Total bookIds: ${bookIds.length}`);
        console.log(`   Removing: ${removedCount} references`);
        console.log(`   Remaining: ${validBookIds.length} references`);

        // Show which book IDs are being removed
        const missingIds = bookIds.filter((id) => !existingBookIds.has(id));
        if (missingIds.length > 0 && missingIds.length <= 10) {
          console.log(`   Removed IDs: ${missingIds.join(', ')}`);
        } else if (missingIds.length > 10) {
          console.log(
            `   Removed IDs: ${missingIds.slice(0, 10).join(', ')} ... and ${
              missingIds.length - 10
            } more`,
          );
        }

        if (!dryRun) {
          // Update the collection with valid book IDs only
          await db.collection('collections').doc(collectionDoc.id).update({
            bookIds: validBookIds,
          });
          console.log(`   ✅ Updated`);
        } else {
          console.log(`   (would be updated in --apply mode)`);
        }

        console.log();
        totalRemoved += removedCount;
        collectionsModified++;
      }
    }

    console.log(
      '═══════════════════════════════════════════════════════════════',
    );
    console.log(`Summary:`);
    console.log(`  Collections modified: ${collectionsModified}`);
    console.log(`  Total references removed: ${totalRemoved}`);
    console.log(
      `  Dry-run mode: ${
        dryRun ? 'YES (use --apply to save changes)' : 'NO (changes applied)'
      }`,
    );
    console.log(
      '═══════════════════════════════════════════════════════════════',
    );

    process.exit(0);
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
    process.exit(1);
  } finally {
    await admin.app().delete();
  }
}

main();
