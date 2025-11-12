#!/usr/bin/env node

// Safe single-book editor for Firestore 'books' documents.
// Usage (dry-run):
//   node tool/edit_book.js --id <BOOK_ID> [--description "long text"] [--imageUrl <url>] [--genres "g1,g2"] [--subGenres "s1,s2"]
// To actually apply changes add --apply
// Example:
//   node tool/edit_book.js --id 0FF_zgEACAAJ --description "New description" --imageUrl "https://.../cover.jpg" --genres "Romance,Paranormal" --apply

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

async function main() {
  const args = parseArgs(process.argv);
  const id = args.id;
  if (!id) {
    console.error('Missing --id <BOOK_ID>');
    process.exit(2);
  }

  // Build update object from args
  const update = {};
  if (args.description) update.description = args.description;
  if (args.imageUrl) update.imageUrl = args.imageUrl;
  if (args.genres)
    update.genres = args.genres
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
  if (args.subGenres)
    update.subGenres = args.subGenres
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);

  // Support loading a JSON file with arbitrary fields: --from-json path
  if (args['from-json']) {
    const jsonPath = path.resolve(args['from-json']);
    if (!fs.existsSync(jsonPath)) {
      console.error('JSON file not found:', jsonPath);
      process.exit(2);
    }
    try {
      const content = fs.readFileSync(jsonPath, 'utf8');
      const obj = JSON.parse(content);
      Object.assign(update, obj);
    } catch (e) {
      console.error('Failed to read/parse JSON:', e.message);
      process.exit(2);
    }
  }

  if (Object.keys(update).length === 0) {
    console.error(
      'No updates provided. Pass --description, --imageUrl, --genres, --subGenres or --from-json',
    );
    process.exit(2);
  }

  // Initialize Firebase Admin
  let admin;
  let db;
  try {
    admin = require('firebase-admin');
  } catch (e) {
    console.error(
      'firebase-admin is required. Install with `npm install firebase-admin`',
    );
    process.exit(1);
  }

  try {
    // Prefer GOOGLE_APPLICATION_CREDENTIALS env var, fallback to tool/service-account.json
    const credPath =
      process.env.GOOGLE_APPLICATION_CREDENTIALS ||
      path.join(__dirname, 'service-account.json');
    if (!fs.existsSync(credPath)) {
      console.error(
        'Service account not found. Set GOOGLE_APPLICATION_CREDENTIALS or place service-account.json next to this script. Tried:',
        credPath,
      );
      process.exit(1);
    }
    const serviceAccount = require(credPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    db = admin.firestore();
  } catch (e) {
    console.error('Failed to initialize Firebase Admin:', e.message);
    process.exit(1);
  }

  const docRef = db.collection('books').doc(id);
  try {
    const before = await docRef.get();
    console.log('Document exists:', before.exists);
    console.log('\n--- Before ---');
    if (before.exists) {
      const data = before.data();
      console.log(JSON.stringify(data, null, 2));
    } else {
      console.log('(no document)');
    }

    console.log('\nPlanned updates:');
    console.log(JSON.stringify(update, null, 2));

    if (!args.apply) {
      console.log('\nDry-run only. To apply changes, re-run with --apply');
      process.exit(0);
    }

    // Apply update (merge)
    await docRef.set(update, { merge: true });

    const after = await docRef.get();
    console.log('\n--- After ---');
    console.log(JSON.stringify(after.data(), null, 2));

    console.log('\n✅ Update applied successfully');
    process.exit(0);
  } catch (e) {
    console.error('Error updating document:', e.message);
    process.exit(1);
  }
}

main();
