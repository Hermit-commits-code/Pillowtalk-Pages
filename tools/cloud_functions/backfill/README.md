Backfill cached community fields
================================

This is a safe, idempotent admin script to backfill `cachedTopWarnings`, `cachedTropes`, and `cachedGenre` on `users/{userId}/library/{userBookId}` documents.

Design goals

- Idempotent: repeated runs won't change data beyond the first write.
- Bounded concurrency: processes library docs in batches to avoid quota spikes.
- Dry-run mode: preview writes without performing them.
- Safe: expects to run from a trusted admin environment with a service account.

Usage (local)

1. Install dependencies (Node 18+):

   npm install firebase-admin @google-cloud/firestore yargs

2. Run the script (dry run):

   node index.js --project <GCP_PROJECT_ID> --serviceAccount ./sa.json --dryRun

3. To actually write updates:

   node index.js --project <GCP_PROJECT_ID> --serviceAccount ./sa.json

Options

- --project: your GCP project id (required)
- --serviceAccount: path to a service account JSON file with Firestore admin permissions (recommended)
- --concurrency: number of parallel library doc workers (default 6)
- --dryRun: if set, no writes are performed; actions are logged
- --limitUsers: optional numeric limit to process only the first N users (useful for testing)

Deployment as a Cloud Function

- This script is written as a standalone admin tool. If you need a serverless variant, refactor it into a callable Cloud Function with a small change: accept a list of user IDs or a cursor and process them in chunks. Be careful with function timeouts and Firestore quotas.

Safety notes

- Always run with dryRun first.
- Monitor Firestore quota and costs — each document write will incur costs.
- For large datasets prefer a staged rollout (limitUsers) or server-side batching with backoff.
