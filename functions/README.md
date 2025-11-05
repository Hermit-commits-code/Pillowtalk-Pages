# Spicy-Reads Cloud Functions

This folder contains a small scaffold for server-side Play subscription verification and RTDN (Real-Time Developer Notifications) reconciliation.

Files:
- `index.js` - Exports `verifyPurchase` (HTTP) and `handleRtdn` (Pub/Sub). Also includes a small local dev server when run directly.
- `package.json` - Node dependencies and engine.
- `tools/verify_sub.js` - local helper to call Play's `purchases.subscriptions.get` for manual testing.

Configuration options
- Use Application Default Credentials (preferred) by attaching the `play-api-verifier` service account to the runtime (Workload Identity / Cloud Functions service account). In this case the code will use ADC and Secret Manager won't be required.
- Alternatively, store the service account JSON in Secret Manager under the secret name `PLAY_API_KEY_JSON` in the same GCP project. The scaffold will try ADC first and then fall back to reading the secret from:
  `projects/${PROJECT_ID}/secrets/${SECRET_NAME}/versions/latest`
  where `PROJECT_ID` is taken from environment (or fallback numeric id `511866750127`) and `SECRET_NAME` defaults to `PLAY_API_KEY_JSON`.

Deploy notes
- To deploy with Firebase Functions (via `firebase deploy --only functions`), set the runtime service account for the function to `projects/PROJECT_ID/serviceAccounts/play-api-verifier@PROJECT_ID.iam.gserviceaccount.com` in the Cloud Console after deploy, or use Cloud Run with the service account attached.
- You must grant the `play-api-verifier` service account the following roles:
  - `roles/datastore.user` or Firestore writer role (to update `users/{uid}` and `play_purchases`)
  - `roles/pubsub.editor` (or sufficient Pub/Sub roles) to allow Pub/Sub access if you plan to publish (Play will publish using Play's own service account)
  - `roles/secretmanager.secretAccessor` if you store a JSON key in Secret Manager

Local testing
- Install dependencies in `functions/`:

```bash
cd functions
npm install
```

- To run the local verifyPurchase dev server using ADC or a JSON key in `GOOGLE_APPLICATION_CREDENTIALS`:

```bash
PROJECT_ID=your-project-id node index.js
# then POST to http://localhost:8080/verifyPurchase with body { uid, packageName, subscriptionId, purchaseToken }
```

- Or use the helper to directly call Play API:

```bash
cd functions
node tools/verify_sub.js com.example.app subscription_id purchase_token_here
```

Security note
- The `verifyPurchase` endpoint in production must be protected (authenticated + authenticated client -> server mapping) — consider using a Cloud Endpoint, Identity-Aware Proxy, or requiring signed tokens from your client to prevent arbitrary callers from marking users Pro.

Next steps
- After you confirm you want me to deploy, I can produce exact `gcloud` / `firebase` deploy commands and a short step list covering creating the Pub/Sub topic, granting Play Console `pubsub.publisher` on it, and hooking RTDN in Play Console.
