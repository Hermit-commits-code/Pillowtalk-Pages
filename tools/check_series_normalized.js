// tools/check_series_normalized.js
const admin = require('firebase-admin');
const path = require('path');

const saPath = process.argv[2]; // e.g. /path/to/service-account.json
if (!saPath) throw new Error('usage: node check_series_normalized.js /path/to/service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(require(path.resolve(saPath))),
});
const db = admin.firestore();

(async () => {
  const snap = await db.collection('books').limit(20).get();
  let missing = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    if (!data.seriesName_normalized) {
      console.log('MISSING:', doc.id, 'seriesName:', data.seriesName || null);
      missing++;
    } else {
      console.log('HAS:', doc.id, '->', data.seriesName_normalized);
    }
  }
  console.log('Checked', snap.size, 'docs, missing normalized:', missing);
  process.exit(0);
})();