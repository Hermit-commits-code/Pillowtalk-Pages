#!/usr/bin/env node
const admin = require('firebase-admin');
const path = require('path');

const saPath = process.argv[2];
if (!saPath) {
  console.error('Usage: node check.js /path/to/service-account.json');
  process.exit(1);
}

const key = require(path.resolve(saPath));
admin.initializeApp({ credential: admin.credential.cert(key) });
const db = admin.firestore();

(async () => {
  const snap = await db.collection('books').limit(50).get();
  let missing = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    if (!data.seriesName_normalized) {
      console.log('MISSING', doc.id, data.seriesName || null);
      missing++;
    } else {
      console.log('HAS', doc.id, '->', data.seriesName_normalized);
    }
  }
  console.log('Checked', snap.size, 'missing', missing);
  await admin.app().delete();
})();
