/**
 * Admin backfill script for populating cachedTopWarnings / cachedTropes
 * on user library docs.
 *
 * Usage (locally with service account):
 *   node index.js --project your-project-id --serviceAccount ./sa.json --dryRun
 *
 * Deployment as a Cloud Function is possible but this script is intended as
 * an idempotent admin migration that you can run from a secure environment.
 *
 * Behavior summary:
 *  - Iterates users in `users/` collection
 *  - For each user's `library/` subcollection, finds docs missing cachedTopWarnings/cachedTropes
 *  - Attempts to read community aggregates from `book_aggregates/{bookId}` then `books/{bookId}`
 *  - Writes merged fields to the library doc: cachedTopWarnings, cachedTropes, cachedGenre
 *  - Operates in batches with limited concurrency and supports dry-run mode
 */

const {Firestore} = require('@google-cloud/firestore');
const admin = require('firebase-admin');
const yargs = require('yargs/yargs');
const {hideBin} = require('yargs/helpers');

async function main() {
  const argv = yargs(hideBin(process.argv))
    .option('project', {type: 'string', describe: 'GCP project id', demandOption: true})
    .option('serviceAccount', {type: 'string', describe: 'Path to service account JSON'})
    .option('concurrency', {type: 'number', default: 6, describe: 'Concurrent library doc workers'})
    .option('dryRun', {type: 'boolean', default: false, describe: 'Dry run: no writes'})
    .option('limitUsers', {type: 'number', describe: 'Limit number of users to process'})
    .argv;

  if (argv.serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(require(argv.serviceAccount)),
      projectId: argv.project,
    });
  } else {
    admin.initializeApp({projectId: argv.project});
  }

  const db = admin.firestore();
  console.log('Starting backfill (dryRun=', argv.dryRun, ')');

  let processedUsers = 0;
  const userDocs = await db.collection('users').listDocuments();

  for (const userDoc of userDocs) {
    if (argv.limitUsers && processedUsers >= argv.limitUsers) break;
    processedUsers++;
    const userId = userDoc.id;
    console.log(`Processing user ${userId} (${processedUsers}/${userDocs.length})`);

    try {
      const libraryRef = userDoc.collection('library');
      const snapshot = await libraryRef.get();
      const toProcess = snapshot.docs.filter(doc => {
        const data = doc.data();
        const cachedWarnings = Array.isArray(data.cachedTopWarnings) ? data.cachedTopWarnings : [];
        const cachedTropes = Array.isArray(data.cachedTropes) ? data.cachedTropes : [];
        return cachedWarnings.length === 0 || cachedTropes.length === 0;
      });

      console.log(`  Found ${toProcess.length} library docs to consider`);

      // process in batches of concurrency
      for (let i = 0; i < toProcess.length; i += argv.concurrency) {
        const batch = toProcess.slice(i, i + argv.concurrency);
        await Promise.all(batch.map(async (docSnap) => {
          const doc = docSnap;
          const data = doc.data();
          const bookId = data.bookId;
          if (!bookId) return;

          let aggDoc = null;
          try {
            const aggSnap = await db.collection('book_aggregates').doc(bookId).get();
            if (aggSnap.exists) aggDoc = aggSnap.data();
          } catch (e) {
            console.warn(`    Error reading aggregate for ${bookId}: ${e}`);
          }

          if (!aggDoc) {
            try {
              const bookSnap = await db.collection('books').doc(bookId).get();
              if (bookSnap.exists) aggDoc = bookSnap.data();
            } catch (e) {
              console.warn(`    Error reading book doc for ${bookId}: ${e}`);
            }
          }

          if (!aggDoc) {
            console.log(`    No community data found for book ${bookId}, skipping`);
            return;
          }

          const toWrite = {};
          if (Array.isArray(aggDoc.topWarnings)) toWrite.cachedTopWarnings = aggDoc.topWarnings;
          if (Array.isArray(aggDoc.communityTropes)) toWrite.cachedTropes = aggDoc.communityTropes;
          if (typeof aggDoc.genre === 'string') toWrite.cachedGenre = aggDoc.genre;

          if (Object.keys(toWrite).length === 0) {
            console.log(`    No cacheable fields present for ${bookId}, skipping`);
            return;
          }

          if (argv.dryRun) {
            console.log(`    [dryRun] Would update ${userId}/library/${doc.id} with`, toWrite);
            return;
          }

          try {
            await libraryRef.doc(doc.id).set(toWrite, {merge: true});
            console.log(`    Updated ${userId}/library/${doc.id}`);
          } catch (e) {
            console.error(`    Failed to write ${userId}/library/${doc.id}: ${e}`);
          }
        }));
      }
    } catch (e) {
      console.error(`  Failed processing user ${userId}: ${e}`);
    }
  }

  console.log('Backfill complete. Processed users:', processedUsers);
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
