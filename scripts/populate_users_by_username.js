// scripts/populate_users_by_username.js
// Usage: node scripts/populate_users_by_username.js path/to/service-account.json
// Writes mapping docs: users_by_username/{normalized} -> { uid }

const admin = require('firebase-admin');
const path = require('path');

function normalize(username) {
  return username.toLowerCase().trim();
}

async function main() {
  try {
    const serviceAccountPath = process.argv[2] || path.resolve(process.cwd(), 'service-account.json');
    console.log('Using service account:', serviceAccountPath);
    const serviceAccount = require(serviceAccountPath);

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    const db = admin.firestore();

    console.log('Querying users collection...');
    const usersRef = db.collection('users');
    const snapshot = await usersRef.get();
    console.log('Found', snapshot.size, 'users.');

    let written = 0;
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const raw = data && data.username ? data.username.toString() : null;
      if (!raw) continue;

      const normalized = normalize(raw);
      const mappingRef = db.collection('users_by_username').doc(normalized);

      try {
        // Avoid overwriting existing mappings; if exists, skip or log.
        const existing = await mappingRef.get();
        if (existing.exists) {
          console.log('Skipping existing mapping for', normalized);
          continue;
        }

        await mappingRef.set({ uid: doc.id });
        written++;
        if (written % 100 === 0) console.log('Wrote', written, 'mappings so far');
      } catch (err) {
        console.error('Failed to write mapping for', normalized, err);
      }
    }

    console.log('Completed. Wrote', written, 'username mapping docs to users_by_username/.');
    process.exit(0);
  } catch (err) {
    console.error('Error running populate script:', err);
    process.exit(1);
  }
}

main();
