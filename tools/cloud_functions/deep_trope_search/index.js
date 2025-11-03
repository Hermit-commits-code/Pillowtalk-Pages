/*
 * Deep Trope Search - Cloud Function (HTTP)
 * - Accepts POST JSON: { tags: string[], mode: 'AND'|'OR', limit?: number }
 * - Returns JSON: { results: [RomanceBook], count }
 *
 * Note: This is a pragmatic MVP. For large catalogs use a dedicated search
 * index (Algolia/Elastic) or extend this to use pagination cursors.
 */

const admin = require('firebase-admin');
const express = require('express');
const bodyParser = require('body-parser');

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(bodyParser.json());

// Helper to normalize tags
function normTags(tags) {
  return (tags || []).map(t => (t || '').trim()).filter(t => t.length > 0);
}

app.post('/searchTropes', async (req, res) => {
  try {
    const body = req.body || {};
    const tags = normTags(body.tags || []);
    const mode = (body.mode || 'OR').toUpperCase();
    const limit = Math.max(1, Math.min(200, body.limit || 50));

    if (!tags.length) {
      return res.status(400).json({ error: 'No tags provided' });
    }

    const aggCol = db.collection('book_aggregates');
    const booksCol = db.collection('books');
    const results = [];
    const seen = new Set();

    if (mode === 'OR') {
      // Firestore supports array-contains-any up to 10 values
      const chunk = tags.slice(0, 10);
      const snaps = await Promise.all([
        aggCol.where('communityTropes', 'array-contains-any', chunk).limit(limit).get(),
        booksCol.where('communityTropes', 'array-contains-any', chunk).limit(limit).get(),
      ]);
      for (const snap of snaps) {
        snap.forEach(doc => {
          if (!seen.has(doc.id)) {
            seen.add(doc.id);
            results.push(doc.data());
          }
        });
      }
    } else {
      // AND mode: query the first tag then filter server-side for full intersection
      const first = tags[0];
      const snaps = await Promise.all([
        aggCol.where('communityTropes', 'array-contains', first).limit(limit).get(),
        booksCol.where('communityTropes', 'array-contains', first).limit(limit).get(),
      ]);
      for (const snap of snaps) {
        snap.forEach(doc => {
          if (seen.has(doc.id)) return;
          const data = doc.data();
          const tropes = (data.communityTropes || []).map(t => String(t).toLowerCase());
          let ok = true;
          for (const t of tags) {
            const low = t.toLowerCase();
            if (!tropes.some(tt => tt.includes(low) || low.includes(tt))) {
              ok = false;
              break;
            }
          }
          if (ok) {
            seen.add(doc.id);
            results.push(data);
          }
        });
      }
    }

    return res.json({ count: results.length, results });
  } catch (e) {
    console.error('searchTropes error', e);
    return res.status(500).json({ error: String(e) });
  }
});

// Export as a Cloud Function compatible handler
module.exports = { app };

// If running locally, allow starting the server
if (require.main === module) {
  const port = process.env.PORT || 8080;
  app.listen(port, () => console.log(`Deep trope search running on ${port}`));
}
