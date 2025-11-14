# Deploying Cloud Functions and Configuring Admin Access

This document describes the recommended steps to deploy the Cloud Functions used by Spicy-Reads and to configure the admin allow-list so developer/admin clients can call admin-only functions.

Overview
- Functions that require admin access: `getUserByEmail`, `setProStatus`, `setLibrarianStatus`, `getProUsers`, `getLibrarians`, `pingAdmin`, and `logClientDiagnostic`.
- These functions use an `isAdmin(context)` helper which checks (in order):
  1. custom `admin` claim on the caller
  2. `ADMIN_UIDS` env config (comma-separated UIDs) or `functions.config().admin.uids`
  3. Firestore allow-list document `config/admins` { uids: [...] }
  4. fallback developer email `hotcupofjoe2013@gmail.com`

Prerequisites
- Install Firebase CLI: `npm install -g firebase-tools`
- Login and select project:

```bash
firebase login
firebase use --add <your-project-id>
```

Recommended: add admin UIDs or Firestore allow-list before or after deploy.

Option A — set `ADMIN_UIDS` in functions config (quick)

```bash
# Replace with comma-separated UIDs of trusted admin accounts
firebase functions:config:set admin.uids="uid1,uid2"
# Optional admin key (for API-style endpoints) - keep secret
firebase functions:config:set admin.key="your-admin-key-here"

# Then deploy functions
firebase deploy --only functions
```

Option B — update Firestore allow-list (more flexible)

1. Open Firestore in the Firebase Console.
2. Create/Update the document at `config/admins` with content:

```json
{
  "uids": ["uid1", "uid2"]
}
```

3. Deploy functions (if not already deployed):

```bash
firebase deploy --only functions
```

Set environment variables (alternate)
- You can also set environment variables in your cloud provider console or via `gcloud` for runtime settings.

Deploying functions

```bash
# From the repo root where functions/ is located
cd functions
npm install
# Run tests (if any) or linting here
# Deploy
firebase deploy --only functions
```

Notes on `logClientDiagnostic`
- This callable (`logClientDiagnostic`) writes a diagnostic entry to `admin_audit` and is restricted via `isAdmin(context)`.
- Use it from the client only when signed in as an admin (developer) account.
- Example usage from a Flutter client (admin-only):

```dart
final functions = FirebaseFunctions.instance;
try {
  await functions.httpsCallable('logClientDiagnostic').call({
    'message': 'Failed to call getProUsers: permission-denied',
    'extra': { 'stack': '...', 'localState': {...} }
  });
} catch (e) {
  // handle
}
```

Local helper: set custom admin claim using a service account
----------------------------------------------------------

If you prefer to set an `admin` custom claim via a service account (Option C), a helper script is included at `tools/set_admin_claim.js`. Place a `service-account.json` file at the repository root (keep it secure) and run:

```bash
# Set admin claim for a UID
node tools/set_admin_claim.js <UID> --set

# Remove custom claims for a UID
node tools/set_admin_claim.js <UID> --remove
```

Notes:
- The script reads `service-account.json` from the repo root. Ensure the file is not accidentally committed to public repos.
- After setting a custom claim, the user must sign out and sign back in (or refresh their ID token) to pick up the new claim.


Verifying admin access
- Use the Developer Tools screen > Diagnostics to run `pingAdmin` from the app to confirm callable access.
- Check the `admin_audit` collection in Firestore for `pingAdmin` and other audit logs.

Security considerations
- Do not add untrusted UIDs to the allow-list.
- For production, prefer custom claims set via a secure server process (e.g., using Admin SDK with service account) rather than relying solely on an email match.
- Keep any `ADMIN_KEY` or similar secrets out of source control and rotate them if leaked.

Troubleshooting
- If `permission-denied` occurs after deployment:
  - Confirm the user is signed in and has the expected UID/email.
  - Confirm `config/admins` doc contains the UID or `ADMIN_UIDS` is set.
  - Check function logs (`firebase functions:log` or Cloud Console) for errors.
  - Ensure Firestore rules do not block required reads for functions (functions run with Admin SDK but any client-side fallbacks will need permissions).

If you want, I can also prepare a short script to add admin UIDs to Firestore or a helper script to set `functions:config` values for CI workflows.
