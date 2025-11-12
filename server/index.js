/**
 * Server example to verify Google Play purchases and grant 'pro' claim.
 * Usage:
 * 1) Create a Google Service Account with access to the Play Developer API and
 *    download its JSON key. Set ENV var GOOGLE_APPLICATION_CREDENTIALS to that path.
 * 2) Set env variables:
 *    - FUNCTIONS_URL: URL of your Cloud Function endpoint to call (setProClaim)
 *    - FUNCTIONS_ADMIN_KEY: the admin key configured in functions config
 *    - PORT (optional)
 * 3) Run: node index.js
 *
 * Endpoint: POST /verifyPurchase
 * Body: { uid, packageName, productId, purchaseToken }
 */

require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const { google } = require('googleapis');
const fetch = require('node-fetch');

const app = express();
app.use(bodyParser.json());

const port = process.env.PORT || 4000;
const functionsUrl = process.env.FUNCTIONS_URL; // e.g. https://us-central1-<proj>.cloudfunctions.net/api/setProClaim
const functionsAdminKey = process.env.FUNCTIONS_ADMIN_KEY;

if (!functionsUrl || !functionsAdminKey) {
  console.warn(
    'Warning: FUNCTIONS_URL or FUNCTIONS_ADMIN_KEY not set; server will run but cannot call functions.',
  );
}

// Verify a one-time product purchase with Google Play
app.post('/verifyPurchase', async (req, res) => {
  const { uid, packageName, productId, purchaseToken } = req.body || {};
  if (!uid || !packageName || !productId || !purchaseToken) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    // Use Application Default Credentials (GOOGLE_APPLICATION_CREDENTIALS)
    const auth = new google.auth.GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
    const authClient = await auth.getClient();
    const androidpublisher = google.androidpublisher({
      version: 'v3',
      auth: authClient,
    });

    // For one-time in-app product purchases:
    const resp = await androidpublisher.purchases.products.get({
      packageName,
      productId,
      token: purchaseToken,
    });

    // The response contains purchaseState (0 means purchased)
    const purchase = resp.data || {};
    const purchaseState = purchase.purchaseState; // 0 = purchased

    if (purchaseState === 0) {
      // Call Cloud Function to set pro claim
      if (!functionsUrl || !functionsAdminKey) {
        console.error(
          'Functions URL/Admin Key not set; cannot set claim automatically.',
        );
        return res
          .status(500)
          .json({ error: 'Server not configured to set pro claim' });
      }

      const callResp = await fetch(functionsUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-admin-key': functionsAdminKey,
        },
        body: JSON.stringify({ uid, pro: true }),
      });

      const callJson = await callResp.json();
      if (!callResp.ok) {
        console.error('Functions call failed', callJson);
        return res.status(500).json({ error: 'Failed to grant pro claim' });
      }

      return res.json({ ok: true, granted: true, details: callJson });
    }

    return res
      .status(400)
      .json({ error: 'Purchase not in purchased state', purchase });
  } catch (err) {
    console.error('verifyPurchase error', err);
    return res.status(500).json({ error: String(err) });
  }
});

app.listen(port, () => console.log(`Play verify server running on ${port}`));
