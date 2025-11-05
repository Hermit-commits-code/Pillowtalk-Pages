#!/usr/bin/env node
/*
 * tools/backfill_books_from_aggregates.js
 *
 * Simple admin script to backfill `books/{bookId}` documents from the
 * Google Books API for every id found under `book_aggregates`.
 *
 * Usage (locally):
 * 1. Install deps: npm install node-fetch@2
 * 2. Authenticate: set GOOGLE_APPLICATION_CREDENTIALS to a service account JSON
 *    with Firestore write permission, or run `gcloud auth application-default login`.
 * 3. (Optional) export GOOGLE_BOOKS_API_KEY=your_key
 * 4. Run: node tools/backfill_books_from_aggregates.js --batch=100 --concurrency=6
 *
 * The script is deliberately conservative: it reads aggregates in batches and
 * performs Google Books lookups with bounded concurrency. Each successful
 * metadata fetch is merged into `books/{bookId}`.
 */

const admin = require('firebase-admin');
const fetch = require('node-fetch');
const { argv } = require('process');

function parseArgs() {
  const args = {};
  for (const a of argv.slice(2)) {
    const [k, v] = a.split('=');
    const key = k.replace(/^--/, '');
    args[key] = v ?? true;
  }
  return args;
}

async function main() {
  const args = parseArgs();
  const batchSize = parseInt(args.batch || '100', 10);
  const concurrency = parseInt(args.concurrency || '6', 10);
  const projectId = args.project || process.env.GCLOUD_PROJECT;

  console.log('Starting backfill_books_from_aggregates');
  console.log(
    `batchSize=${batchSize} concurrency=${concurrency} project=${projectId}`,
  );

  admin.initializeApp();
  const db = admin.firestore();

  const apiKey = process.env.GOOGLE_BOOKS_API_KEY || '';

  const aggCol = db.collection('book_aggregates');

  let last = null;
  let total = 0;

  while (true) {
    let q = aggCol
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(batchSize);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    if (snap.empty) break;

    const ids = snap.docs.map((d) => d.id);
    console.log(`Fetched ${ids.length} aggregate ids`);

    // process in parallel with limited concurrency
    const chunks = [];
    for (let i = 0; i < ids.length; i += concurrency)
      chunks.push(ids.slice(i, i + concurrency));

    for (const chunk of chunks) {
      await Promise.all(
        chunk.map(async (id) => {
          try {
            const url = `https://www.googleapis.com/books/v1/volumes/${encodeURIComponent(
              id,
            )}${apiKey ? `?key=${apiKey}` : ''}`;
            const res = await fetch(url, { timeout: 10000 });
            if (!res.ok) {
              console.warn(
                `Google Books lookup failed for ${id}: ${res.status} ${res.statusText}`,
              );
              return;
            }
            const data = await res.json();
            const volumeInfo = data.volumeInfo || {};

            // pick an image URL if available
            const imageLinks = volumeInfo.imageLinks || {};
            const imageUrl =
              imageLinks.extraLarge ||
              imageLinks.large ||
              imageLinks.medium ||
              imageLinks.thumbnail ||
              null;

            // pick isbn if available
            let isbn = '';
            const idsList = volumeInfo.industryIdentifiers || [];
            for (const ident of idsList) {
              if (ident.type === 'ISBN_13' || ident.type === 'ISBN_10') {
                isbn = ident.identifier;
                break;
              }
            }

            const doc = {
              title: volumeInfo.title || id,
              authors: volumeInfo.authors || [],
              imageUrl: imageUrl,
              description: volumeInfo.description || null,
              publishedDate: volumeInfo.publishedDate || null,
              pageCount:
                typeof volumeInfo.pageCount === 'number'
                  ? volumeInfo.pageCount
                  : null,
              isbn: isbn,
              lastBackfilled: admin.firestore.FieldValue.serverTimestamp(),
            };

            await db.collection('books').doc(id).set(doc, { merge: true });
            console.log(`Backfilled books/${id} -> ${doc.title}`);
            total += 1;
          } catch (e) {
            console.error(`Error processing ${id}: ${e}`);
          }
        }),
      );
    }

    last = snap.docs[snap.docs.length - 1];
  }

  console.log(`Backfill complete. Total backfilled: ${total}`);
  process.exit(0);
}

main().catch((e) => {
  console.error('Backfill failed', e);
  process.exit(2);
});
