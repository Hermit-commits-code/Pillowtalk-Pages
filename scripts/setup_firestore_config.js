// Script to create the Firestore config/appUpdates document for in-app updates
// Usage: node scripts/setup_firestore_config.js --sa=/path/to/service-account.json

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
let serviceAccountPath = process.env.MIGRATE_SA_PATH || process.env.GOOGLE_APPLICATION_CREDENTIALS;
let projectId = process.env.GCP_PROJECT || 'spicy-reads-1';

// Parse command line arguments
for (let i = 2; i < process.argv.length; i++) {
  if (process.argv[i].startsWith('--sa=')) {
    serviceAccountPath = process.argv[i].substring(5);
  } else if (process.argv[i].startsWith('--project=')) {
    projectId = process.argv[i].substring(10);
  }
}

if (!serviceAccountPath) {
  console.error('Error: Service account key path not provided.');
  console.error('Usage: node scripts/setup_firestore_config.js --sa=/path/to/service-account.json --project=spicy-reads-1');
  console.error('Or set GOOGLE_APPLICATION_CREDENTIALS or MIGRATE_SA_PATH environment variable.');
  process.exit(1);
}

const serviceAccount = require(path.resolve(serviceAccountPath));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: projectId,
});

const db = admin.firestore();

async function setupFirestoreConfig() {
  try {
    console.log(`Setting up Firestore config for project: ${projectId}`);

    // Create config/appUpdates document
    const configData = {
      latestVersion: '1.5.2',
      releaseNotes: 'In-app update notifications now available. Manual update prompts with dismissible banner or blocking dialog. See docs/IN_APP_UPDATES.md for details.',
      downloadUrl: 'https://github.com/Hermit-commits-code/Spicy-Reads/releases/download/v1.5.2/app-release.apk',
      isRequired: false,
      releasedAt: new Date().toISOString(),
    };

    await db.collection('config').doc('appUpdates').set(configData);
    console.log('✓ Created config/appUpdates document:');
    console.log(JSON.stringify(configData, null, 2));

    console.log('\n✓ Firestore configuration complete!');
    console.log('The app will now show update notifications on launch.');
    process.exit(0);
  } catch (error) {
    console.error('Error setting up Firestore config:', error.message);
    process.exit(1);
  }
}

setupFirestoreConfig();
