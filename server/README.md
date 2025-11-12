Google Play purchase verification server (example)

Prereqs:

- Create a Google service account with Play Developer API access and download JSON key.
- Set GOOGLE_APPLICATION_CREDENTIALS to the path of that key.
- Set FUNCTIONS_URL to your Cloud Function setProClaim URL.
- Set FUNCTIONS_ADMIN_KEY to the admin key you configured in functions.

Run locally:

```bash
cd server
npm install
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
export FUNCTIONS_URL=https://us-central1-<project>.cloudfunctions.net/api/setProClaim
export FUNCTIONS_ADMIN_KEY=your_admin_key_here
node index.js
```

Call endpoint (server-to-server):

POST /verifyPurchase
Body:
{
"uid": "USER_UID",
"packageName": "com.example.app",
"productId": "pro_unlock",
"purchaseToken": "..."
}

The server will verify the purchase with Google Play and call the Cloud Function to grant the `pro` claim.
