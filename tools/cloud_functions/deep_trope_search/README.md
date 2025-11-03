Deep Trope Search Cloud Function
================================

This function provides server-side AND/OR trope search for the Deep Tropes engine.

Usage (local)

1. Install dependencies:

   npm install

2. Run locally:

   node index.js

3. POST to the endpoint:

   POST <http://localhost:8080/searchTropes>
   Content-Type: application/json

   {
     "tags": ["Enemies to Lovers", "Grumpy Sunshine"],
     "mode": "AND", // OR
     "limit": 50
   }

Deployment (Cloud Functions)

- Wrap the `app` export in a Cloud Function (see firebase functions docs) or deploy as an HTTP function.
- Example `index.js` for firebase-functions wrapper:

  const functions = require('firebase-functions');
  const { app } = require('./index');
  exports.searchTropes = functions.https.onRequest(app);

Notes

- AND mode does a first-tag query then filters server-side (practical but not perfect for very large datasets).
- OR mode uses Firestore `array-contains-any` (max 10 tags per query).
- For production-scale search consider a dedicated search index (Algolia/Elastic) or implement robust pagination with cursors.
