#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const { parse } = require('csv-parse/sync');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');

function slugify(input) {
  if (!input) return '';
  // Normalize unicode, remove diacritics, lowercase, replace non-alphanum with hyphens
  return input
    .normalize('NFKD')
    .replace(/\p{M}/gu, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}

function normalizeSeriesName(series) {
  if (!series) return null;
  // Normalize: remove diacritics, lowercase, remove punctuation, collapse whitespace
  return series
    .normalize('NFKD')
    .replace(/\p{M}/gu, '') // remove diacritic marks
    .toLowerCase()
    .replace(/[^a-z0-9\s]+/g, ' ') // replace punctuation with space
    .replace(/\s+/g, ' ') // collapse multiple spaces
    .trim();
}

async function initFirebase(serviceAccountPath) {
  if (admin.apps.length === 0) {
    if (serviceAccountPath) {
      const key = require(path.resolve(serviceAccountPath));
      admin.initializeApp({ credential: admin.credential.cert(key) });
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      admin.initializeApp();
    } else {
      console.error('No service account provided and GOOGLE_APPLICATION_CREDENTIALS not set.');
      process.exit(1);
    }
  }
  return admin.firestore();
}

async function migrateSeriesNormalized(db, options) {
  console.log('Starting migration scan of collection:', options.collection);
  const snapshot = await db.collection(options.collection).get();
  const docs = snapshot.docs;
  console.log(`Found ${docs.length} documents in ${options.collection}`);

  let changed = 0;
  let processed = 0;
  const batchSize = Number(options.batchSize || 500);
  let batch = db.batch();
  let opsInBatch = 0;
  const changedIds = [];

  for (const doc of docs) {
    if (options.limit && processed >= options.limit) break;
    processed++;
    const data = doc.data();
    const series = data.seriesName || data.series_name || null;
    const currentNormalized = data.seriesName_normalized || data.seriesNameNormalized || null;
    const shouldSet = series && (options.force || !currentNormalized);
    if (!shouldSet) continue;

    const normalized = normalizeSeriesName(series);
    if (options.dryRun) {
      console.log('[dry-run] would set', doc.id, '=>', normalized);
    } else {
      batch.update(doc.ref, { seriesName_normalized: normalized });
      opsInBatch++;
      changed++;
      changedIds.push({ id: doc.id, seriesName_normalized: normalized });
    }

    if (opsInBatch >= batchSize) {
      console.log('Committing batch of', opsInBatch);
      await batch.commit();
      batch = db.batch();
      opsInBatch = 0;
    }
  }

  if (!options.dryRun && opsInBatch > 0) {
    console.log('Committing final batch of', opsInBatch);
    await batch.commit();
  }

  console.log(`Processed ${processed} docs. Changed: ${changed}`);
  if (!options.dryRun && changedIds.length > 0) {
    const outPath = path.resolve(process.cwd(), 'tools/migrate_series_normalized/changed_ids_' + Date.now() + '.json');
    fs.writeFileSync(outPath, JSON.stringify(changedIds, null, 2), 'utf8');
    console.log('Wrote change log to', outPath);
    // also write CSV for easier review
    try {
      const csvPath = outPath.replace(/\.json$/, '.csv');
      const csvLines = ['id,seriesName_normalized'];
      for (const r of changedIds) csvLines.push(`${r.id},"${(r.seriesName_normalized || '').replace(/"/g, '""')}"`);
      fs.writeFileSync(csvPath, csvLines.join('\n'), 'utf8');
      console.log('Wrote CSV change log to', csvPath);
    } catch (e) {
      console.warn('Failed to write CSV log:', e.message);
    }
  }
}

async function reconcileAggregates(db, options) {
  console.log('Starting reconciliation of aggregates from users/* collections');
  const usersSnap = await db.collection('users').get();
  const agg = new Map();

  for (const userDoc of usersSnap.docs) {
    const uid = userDoc.id;
    // check ratings under users/{uid}/ratings
    const ratingsRef = db.collection('users').doc(uid).collection('ratings');
    const ratingsSnap = await ratingsRef.get();
    for (const r of ratingsSnap.docs) {
      const data = r.data();
      const bookId = data.bookId || data.book_id || data.book;
      const spice = typeof data.spice === 'number' ? data.spice : parseFloat(data.spice || 0);
      if (!bookId || Number.isNaN(spice)) continue;
      const cur = agg.get(bookId) || { sum: 0, count: 0 };
      cur.sum += spice;
      cur.count += 1;
      agg.set(bookId, cur);
    }

    // also check library entries if they contain spice
    const libRef = db.collection('users').doc(uid).collection('library');
    const libSnap = await libRef.get();
    for (const l of libSnap.docs) {
      const data = l.data();
      const bookId = l.id;
      const spice = typeof data.spice === 'number' ? data.spice : parseFloat(data.spice || 0);
      if (Number.isNaN(spice)) continue;
      const cur = agg.get(bookId) || { sum: 0, count: 0 };
      cur.sum += spice;
      cur.count += 1;
      agg.set(bookId, cur);
    }
  }

  console.log(`Aggregated data for ${agg.size} books`);

  // apply updates to aggregates collection (default: book_aggregates)
  const aggregatesCollection = options.aggregatesCollection || 'book_aggregates';
  const batchSize = Number(options.batchSize || 500);
  let batch = db.batch();
  let opsInBatch = 0;
  const changed = [];

  for (const [bookId, data] of agg.entries()) {
    const avg = data.count > 0 ? data.sum / data.count : 0;
    const aggRef = db.collection(aggregatesCollection).doc(bookId);
    if (options.dryRun) {
      console.log('[dry-run] would set aggregate', bookId, '=> avgSpice=', avg.toFixed(3), 'count=', data.count, 'into', aggregatesCollection);
    } else {
      batch.set(aggRef, { avgSpice: avg, ratingCount: data.count }, { merge: true });
      opsInBatch++;
      changed.push({ id: bookId, avgSpice: avg, ratingCount: data.count });
    }

    // Optionally merge aggregates into books/{bookId} if the doc exists
    if (!options.dryRun && options.mergeToBooksIfExists) {
      const bookRef = db.collection('books').doc(bookId);
      // we cannot use a read inside a write batch, so perform existence check synchronously
      // by scheduling a get now (but to keep it simple and safe, we'll perform a get outside of batch)
      // Collect a list to merge after batching below
    }

    if (opsInBatch >= batchSize) {
      console.log('Committing batch of', opsInBatch, 'to', aggregatesCollection);
      await batch.commit();
      batch = db.batch();
      opsInBatch = 0;
    }
  }

  if (!options.dryRun && opsInBatch > 0) {
    console.log('Committing final batch of', opsInBatch, 'to', aggregatesCollection);
    await batch.commit();
  }

  console.log('Reconciliation completed. Updated aggregates:', changed.length);
  if (!options.dryRun && changed.length > 0) {
    const outPath = path.resolve(process.cwd(), 'tools/migrate_series_normalized/reconcile_changed_' + Date.now() + '.json');
    fs.writeFileSync(outPath, JSON.stringify(changed, null, 2), 'utf8');
    console.log('Wrote reconcile change log to', outPath);
    try {
      const csvPath = outPath.replace(/\.json$/, '.csv');
      const csvLines = ['id,avgSpice,ratingCount'];
      for (const r of changed) csvLines.push(`${r.id},${r.avgSpice},${r.ratingCount}`);
      fs.writeFileSync(csvPath, csvLines.join('\n'), 'utf8');
      console.log('Wrote reconcile CSV to', csvPath);
    } catch (e) {
      console.warn('Failed to write reconcile CSV:', e.message);
    }
  }

  // If requested, merge aggregates into books/{bookId} only when that doc exists
  if (!options.dryRun && options.mergeToBooksIfExists) {
    const merges = [];
    for (const item of changed) merges.push(item.id);
    console.log('Checking existence for', merges.length, 'books to optionally merge into books/');
    const mergeBatchSize = 100; // limit concurrency
    for (let i = 0; i < merges.length; i += mergeBatchSize) {
      const chunk = merges.slice(i, i + mergeBatchSize);
      const checks = await Promise.all(chunk.map(id => db.collection('books').doc(id).get()));
      const mergeBatch = db.batch();
      let mergeOps = 0;
      for (let j = 0; j < checks.length; j++) {
        const docSnap = checks[j];
        if (docSnap.exists) {
          const id = chunk[j];
          const data = changed.find(c => c.id === id);
          mergeBatch.set(db.collection('books').doc(id), { avgSpice: data.avgSpice, ratingCount: data.ratingCount }, { merge: true });
          mergeOps++;
        }
      }
      if (mergeOps > 0) {
        console.log('Committing merge batch of', mergeOps, 'into books/');
        await mergeBatch.commit();
      }
    }
  }
}

function readInputFile(inputPath) {
  const raw = fs.readFileSync(inputPath, 'utf8');
  const ext = path.extname(inputPath).toLowerCase();
  if (ext === '.json') {
    return JSON.parse(raw);
  }
  // assume CSV otherwise
  const records = parse(raw, { columns: true, skip_empty_lines: true });
  return records;
}

async function importBooks(db, options) {
  if (!options.input) {
    console.error('Import mode requires --input file');
    process.exit(1);
  }
  const rows = readInputFile(options.input);
  console.log(`Read ${rows.length} records from ${options.input}`);

  const batchSize = Number(options.batchSize || 500);
  let batch = db.batch();
  let opsInBatch = 0;
  let processed = 0;
  let created = 0;

  for (const row of rows) {
    if (options.limit && processed >= options.limit) break;
    processed++;

    // Normalize field names (common CSV/JSON fields)
    const title = row.title || row.Title || row.name || '';
    const author = row.author || row.authorName || row.authors || '';
    const isbn = (row.isbn || row.ISBN || row.industryIdentifiers || '').toString().trim();
    const series = row.seriesName || row.series || row.series_name || '';
    const seriesIndex = row.seriesIndex || row.series_index || row.seriesNumber || null;
    const genre = row.genre || row.genres || row.category || null;

    let docId = '';
    if (options.idField && row[options.idField]) {
      docId = String(row[options.idField]).trim();
    } else if (isbn) {
      docId = isbn;
    } else {
      // fallback slug: title-author
      docId = slugify(`${title} ${author}`) || `book-${processed}`;
    }

    const docRef = db.collection(options.collection).doc(docId);

    const docData = Object.assign({}, row);
    // ensure seriesName_normalized is set
    if (series) docData.seriesName_normalized = normalizeSeriesName(series);

    if (options.dryRun) {
      console.log('[dry-run] set', docId, '=> seriesName_normalized=', docData.seriesName_normalized || null);
    } else {
      // set merge so we don't clobber extra fields unless --force
      if (options.force) {
        batch.set(docRef, docData, { merge: false });
      } else {
        batch.set(docRef, docData, { merge: true });
      }
      opsInBatch++;
      created++;
    }

    if (opsInBatch >= batchSize) {
      console.log('Committing batch of', opsInBatch);
      await batch.commit();
      batch = db.batch();
      opsInBatch = 0;
    }
  }

  if (!options.dryRun && opsInBatch > 0) {
    console.log('Committing final batch of', opsInBatch);
    await batch.commit();
  }

  console.log(`Import processed: ${processed}, written (approx): ${created}`);
}

async function main() {
  const argv = yargs(hideBin(process.argv))
    .option('mode', { choices: ['migrate', 'import', 'reconcile'], default: 'migrate', describe: 'Operation mode' })
    .option('aggregatesCollection', { type: 'string', describe: 'Collection to write aggregates to (default: book_aggregates)' })
    .option('mergeToBooksIfExists', { type: 'boolean', default: false, describe: 'If true, also merge aggregates into books/{bookId} when that doc exists' })
    .option('serviceAccount', { type: 'string', describe: 'Path to service account JSON' })
    .option('collection', { type: 'string', default: 'books', describe: 'Firestore collection to operate on' })
    .option('dryRun', { type: 'boolean', default: false, describe: 'Do not write changes' })
    .option('limit', { type: 'number', describe: 'Limit number of documents to process' })
    .option('batchSize', { type: 'number', default: 500, describe: 'Batch size for writes (max 500)' })
    .option('force', { type: 'boolean', default: false, describe: 'Force overwrite/replace behavior when importing or migrating' })
    .option('input', { type: 'string', describe: 'Input CSV or JSON file for import mode' })
    .option('idField', { type: 'string', describe: 'Field name to use as document ID when importing (e.g., isbn)' })
    .argv;

  const db = await initFirebase(argv.serviceAccount);

  if (argv.mode === 'migrate') {
    await migrateSeriesNormalized(db, argv);
  } else if (argv.mode === 'import') {
    await importBooks(db, argv);
  } else if (argv.mode === 'reconcile') {
    await reconcileAggregates(db, argv);
  }

  // graceful shutdown
  if (admin.apps.length > 0) await admin.app().delete();
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
