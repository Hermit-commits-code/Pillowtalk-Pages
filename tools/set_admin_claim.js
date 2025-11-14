#!/usr/bin/env node
// tools/set_admin_claim.js
// Usage:
//   node tools/set_admin_claim.js <UID> --set
//   node tools/set_admin_claim.js <UID> --remove
// Requires a `service-account.json` file at the repository root with
// a service account that has permission to set custom user claims.

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

async function main() {
  const args = process.argv.slice(2);
  if (args.length < 2) {
    console.error('Usage: node tools/set_admin_claim.js <UID> --set|--remove');
    process.exit(1);
  }

  const uid = args[0];
  const op = args[1];
  const cwd = process.cwd();
  const saPath = path.resolve(cwd, 'service-account.json');

  if (!fs.existsSync(saPath)) {
    console.error(`service-account.json not found at ${saPath}`);
    process.exit(2);
  }

  const serviceAccount = require(saPath);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  try {
    if (op === '--set') {
      await admin.auth().setCustomUserClaims(uid, { admin: true });
      console.log(`Set custom claim { admin: true } for UID ${uid}`);
    } else if (op === '--remove') {
      await admin.auth().setCustomUserClaims(uid, {});
      console.log(`Removed custom claims for UID ${uid}`);
    } else {
      console.error('Unknown operation. Use --set or --remove');
      process.exit(1);
    }

    console.log('Done. The user must sign out and sign back in to refresh ID token.');
  } catch (err) {
    console.error('Error setting custom claim:', err);
    process.exit(3);
  }
}

main();
