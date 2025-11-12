const admin = require('firebase-admin');
const fs = require('fs');

/**
 * Usage: node tools/set_pro_claim.js <uid> [true|false]
 * Example: node tools/set_pro_claim.js abc123 true
 * Requires: tools/service-account.json (copy your service-account.json here or
 * set GOOGLE_APPLICATION_CREDENTIALS to the service account path).
 */

const uid = process.argv[2];
const val = process.argv[3] === 'false' ? false : true;

if (!uid) {
  console.error('Usage: node tools/set_pro_claim.js <uid> [true|false]');
  process.exit(1);
}

// Prefer environment-provided credentials but allow a local copy.
const saPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS || 'service-account.json';
if (!fs.existsSync(saPath)) {
  console.error(
    `Service account not found at ${saPath}. Place your service account or set GOOGLE_APPLICATION_CREDENTIALS.`,
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(`../${saPath}`)),
});

admin
  .auth()
  .setCustomUserClaims(uid, { pro: val })
  .then(() => {
    console.log(`Set pro=${val} for ${uid}`);
    process.exit(0);
  })
  .catch((err) => {
    console.error('Failed to set claim:', err);
    process.exit(2);
  });
