# Play Console & Google Cloud setup for server-side subscription verification

This document is a step-by-step checklist to set up Google Play API access and Real-Time Developer Notifications (RTDN) so your server can verify Android subscriptions and keep `users/{uid}.isPro` in sync.

Important notes up front

- Prefer to use an existing Google Cloud project already linked to your Firebase project. If you create a new project, make sure to link it in Play Console.
- Never commit service account JSON keys to source control. Use Secret Manager or CI/CD secrets to store keys.
- For production, use a server (Cloud Run or Cloud Functions) with a service account that has the right IAM roles; do not rely on client-only verification.

High-level steps

1. Link Play Console to a Google Cloud Project
2. Create a service account (Google Cloud IAM) and JSON key
3. Grant Play Console access to that service account and assign appropriate Play Console permissions
4. Enable Google Play Developer API on the linked Cloud project
5. Configure RTDN (Pub/Sub) in Play Console and grant publisher rights
6. Deploy a server (Cloud Functions / Cloud Run) that:
   - uses the service account credentials to call purchases.subscriptions.get
   - exposes an endpoint for clients to forward purchase tokens (for initial verification)
   - subscribes to RTDN Pub/Sub messages to reconcile subscription state

Detailed step-by-step (Console + gcloud)

A. Prepare / link project in Play Console

1. Open Google Play Console -> Setup -> API access.
2. If you see "Link Project", use it to link your existing Google Cloud project (prefer the same project used by Firebase). If you don't have one, create a new project first in Google Cloud Console.
3. After linking, you will see a section for "Service accounts".

B. Create a service account and JSON key (Google Cloud Console)

1. Open Google Cloud Console -> IAM & admin -> Service accounts.
2. Click "Create Service Account". Name it e.g. `play-api-verifier`.
3. (Optional) Grant this service account minimal roles here — we'll grant Play Console access separately. At a minimum you can skip granting broad project roles now; you'll use the key to authenticate server-side.
4. After creating the service account, create a JSON key and download it. Save it securely; treat it as a secret.

Alternatively, with gcloud:

```bash
gcloud iam service-accounts create play-api-verifier \
  --display-name="Play API verifier"

# Create a key (writes local JSON file - keep it safe)
gcloud iam service-accounts keys create play-api-verifier-key.json \
  --iam-account=play-api-verifier@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

C. Grant Play Console access to the service account

1. Back in Play Console -> Setup -> API access -> Service accounts
2. Click "Grant access" or "Add user" for the service account you created. Play Console will list the service account's email for you to select.
3. For initial testing, grant broad rights (e.g., "Administrator"). Restrict later: your server needs access to the Subscriptions API (purchases.subscriptions.get) and RTDN setup. If you want least privilege, grant roles that include "View financial data, orders and cancellations" and other subscription-related permissions.

D. Enable required APIs in Google Cloud

1. In Google Cloud Console -> APIs & Services -> Library, enable:
   - Google Play Developer API
   - Cloud Pub/Sub API
2. (Optional) If using the googleapis Node client, make sure the service account has the roles required to call the Play API.

E. Configure RTDN Pub/Sub topic

1. In Google Cloud Console -> Pub/Sub -> Topics, create a topic, e.g. `play-rtdn-topic`.
2. Create a subscription for that topic, e.g. `play-rtdn-sub` (or you can let your Cloud Function create a push subscription).
3. In Play Console -> Setup -> API access -> Real-time developer notifications, enter the topic name (format `projects/YOUR_PROJECT_ID/topics/play-rtdn-topic`) and save.
4. Grant the Play Console service account the Pub/Sub Publisher role on that topic so Play can publish RTDN messages to it:

Using gcloud:

```bash
# give the Play Console's service account the 'pubsub.publisher' role on the topic
gcloud pubsub topics add-iam-policy-binding play-rtdn-topic \
  --member=serviceAccount:PLAY_CONSOLE_SERVICE_ACCOUNT_EMAIL \
  --role=roles/pubsub.publisher
```

F. Securely store the service account key

- For Cloud Functions/Cloud Run, prefer using Workload Identity or attach a service account rather than shipping JSON keys.
- If you must use a JSON key, store it in Secret Manager and let your function fetch it at startup.

G. Quick sanity checks

- Use the `googleapis` Node client on a dev machine with the JSON key to call `androidpublisher.purchases.subscriptions.get()` for a known token to confirm auth works.
- Confirm Play Console shows RTDN messages by observing Pub/Sub messages (use `gcloud pubsub subscriptions pull --auto-ack play-rtdn-sub --limit=1`).

Example: quick node verification script (dev-only)

- Install: `npm install googleapis@39` (or latest)
- Minimal snippet:

```js
const { google } = require('googleapis');
const androidpublisher = google.androidpublisher('v3');

async function verifySub(
  projectId,
  packageName,
  subscriptionId,
  token,
  keyFile,
) {
  const auth = new google.auth.GoogleAuth({
    keyFile,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });

  const authClient = await auth.getClient();
  google.options({ auth: authClient });

  const res = await androidpublisher.purchases.subscriptions.get({
    packageName,
    subscriptionId,
    token,
  });
  console.log(res.data);
}

// call with your values
// verifySub('PROJECT_ID', 'com.example.app', 'pro_monthly', 'PURCHASE_TOKEN', './play-api-key.json');
```

Deployment recommendations

- For production, use Cloud Run or Cloud Functions with a dedicated service account (created above). Avoid placing JSON keys in source.
- Use Secret Manager for any runtime secrets and grant the function's runtime service account permission to access the secret.

Next manual steps for you

- Create or reuse a Cloud project for Play integration and link it in Play Console.
- Create service account and a JSON key (or configure Workload Identity) and store the key in Secret Manager.
- Create the Pub/Sub topic and configure RTDN in Play Console.
- Deploy the server verification service and test a few purchase tokens.

References

- Google Play Developer API docs: https://developers.google.com/android-publisher
- RTDN docs: https://developer.android.com/google/play/billing/realtime_developer_notifications
- Google Cloud Pub/Sub docs: https://cloud.google.com/pubsub/docs

---

If you'd like, I can now scaffold a Cloud Function that uses the service account to call `purchases.subscriptions.get` and also attaches a Pub/Sub trigger for RTDN messages. That would complete the server verification scaffold task in the todo list.
