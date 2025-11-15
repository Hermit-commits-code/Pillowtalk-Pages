// scripts/populate_users_by_email.js
// One-off utility to populate users_by_email/{normalizedEmail} -> { uid }
// Usage: node scripts/populate_users_by_email.js [path/to/service-account.json]

const admin = require('firebase-admin');
const path = require('path');

async function main() {
  try {
    const serviceAccountPath = process.argv[2] || path.resolve(process.cwd(), 'service-account.json');
    console.log('Using service account:', serviceAccountPath);
    const serviceAccount = require(serviceAccountPath);

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      // Optionally set databaseURL/projectId if not in service account
    });

    const db = admin.firestore();

    console.log('Querying users collection...');

    const usersRef = db.collection('users');
    const snapshot = await usersRef.get();
    console.log('Found', snapshot.size, 'users.');

    let count = 0;
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const email = (data && data.email) ? data.email.toString().toLowerCase().trim() : null;
      if (!email) continue;

      const normalized = normalize(email);
      const mappingRef = db.collection('users_by_email').doc(normalized);

      try {
        await mappingRef.set({ uid: doc.id });
        count++;
        if (count % 100 === 0) console.log('Processed', count);
      } catch (err) {
        console.error('Failed to write mapping for', email, err);
      }
    }

    console.log('Completed. Wrote', count, 'mapping docs to users_by_email/.');
    process.exit(0);
  } catch (err) {
    console.error('Error running populate script:', err);
    process.exit(1);
  }
}

function normalize(email) {
  return email.toLowerCase().trim().replace(/\./g, ',');
}

main();
