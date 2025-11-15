populate_users_by_email.js

One-off script to populate `users_by_email/{normalizedEmail}` mapping documents.

Why
- Your client now looks up `users_by_email/{normalizedEmail}` to convert an email to a UID without performing broad queries on the `users` collection.

Prerequisites
- Node 16+ and npm installed
- A service account JSON file with permissions to read `users` and write `users_by_email` (do NOT commit this to source control)

How to run
1. Place your service account JSON in the repo root (or anywhere local) and note the path.
2. Run:

```bash
node scripts/populate_users_by_email.js path/to/service-account.json
```

If you omit the path the script will try to use `./service-account.json`.

Notes
- This script is intended to be run once (or occasionally) by an admin operator. After running you can delete or archive it.
- Mapping normalization: the script lowercases and trims emails and replaces `.` with `,` to make Firestore doc ids safe.
- You may prefer to deploy the accompanying Cloud Function listener (in `functions/index.js`) to keep mappings in sync automatically; that requires deploying Cloud Functions and enabling them in your project.
