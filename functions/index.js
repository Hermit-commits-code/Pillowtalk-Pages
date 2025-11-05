/*
  Cloud Functions scaffold for Spicy-Reads

  Exports:
    - verifyPurchase: HTTP function to verify a purchase token with Google Play and record mapping uid <-> purchase token
    - handleRtdn: Pub/Sub function to consume Play RTDN messages and reconcile subscription state

  Configuration (env vars / secrets):
    - SECRET_NAME (optional): the secret name holding the service account JSON (default: PLAY_API_KEY_JSON)
    - PROJECT_ID (optional): GCP project id / number to locate the secret. If not set, the code will try common env vars and fall back to the numeric project id in the README (511866750127).

  The code tries application default credentials first. If unavailable, it will read the service-account JSON from Secret Manager
  at projects/${PROJECT_ID}/secrets/${SECRET_NAME}/versions/latest and construct credentials for the Play Developer API and Firestore.
*/

const {SecretManagerServiceClient} = require('@google-cloud/secret-manager');
const {google} = require('googleapis');
const admin = require('firebase-admin');

// Default fallback PROJECT_ID used for Secret Manager read if no env var provided.
const FALLBACK_PROJECT_ID = process.env.PROJECT_ID || process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || process.env.PROJECT_ID || '511866750127';
const SECRET_NAME = process.env.SECRET_NAME || 'PLAY_API_KEY_JSON';

let googleAuthClient = null;
let androidpublisher = null;

async function ensureCredentials() {
  if (googleAuthClient && androidpublisher) return {googleAuthClient, androidpublisher};

  // Try ADC first for firebase-admin and for Google APIs.
  try {
    // Initialize firebase-admin with default creds if not already.
    if (!admin.apps.length) {
      admin.initializeApp();
    }
    googleAuthClient = new google.auth.GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/androidpublisher']
    });
    androidpublisher = google.androidpublisher({version: 'v3', auth: googleAuthClient});
    return {googleAuthClient, androidpublisher};
  } catch (err) {
    // fallthrough to secret-based flow
    console.warn('ADC not available or partial failure; will attempt Secret Manager:', err.message || err);
  }

  // If ADC didn't work, read service account JSON from Secret Manager
  const client = new SecretManagerServiceClient();
  const name = `projects/${FALLBACK_PROJECT_ID}/secrets/${SECRET_NAME}/versions/latest`;
  const [version] = await client.accessSecretVersion({name});
  const payload = version.payload && version.payload.data ? Buffer.from(version.payload.data, 'base64').toString('utf8') : null;
  if (!payload) throw new Error('Secret payload empty when reading service account JSON from Secret Manager');
  const credentials = JSON.parse(payload);

  // Initialize firebase-admin with the cert if not already initialized
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(credentials)
    });
  }

  googleAuthClient = new google.auth.GoogleAuth({
    credentials,
    scopes: ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/androidpublisher']
  });
  androidpublisher = google.androidpublisher({version: 'v3', auth: googleAuthClient});
  return {googleAuthClient, androidpublisher};
}

// Helper: verify a subscription purchase with Play API
async function verifySubscription(packageName, subscriptionId, purchaseToken) {
  const {androidpublisher} = (await ensureCredentials());
  const res = await androidpublisher.purchases.subscriptions.get({
    packageName,
    subscriptionId,
    token: purchaseToken
  });
  return res.data;
}

// HTTP function to verify a purchase token and store mapping to uid
// Expects JSON body: { uid, packageName, subscriptionId, purchaseToken }
// Returns Play API response and writes a doc at `play_purchases/{purchaseToken}` with uid and raw response.
async function verifyPurchase(req, res) {
  try {
    if (req.method !== 'POST') return res.status(405).send('Use POST');
    const {uid, packageName, subscriptionId, purchaseToken} = req.body || {};
    if (!uid || !packageName || !subscriptionId || !purchaseToken) {
      return res.status(400).json({error: 'Missing one of uid, packageName, subscriptionId, purchaseToken'});
    }

    const verification = await verifySubscription(packageName, subscriptionId, purchaseToken);

    // Persist mapping so RTDN handler can lookup uid by token
    const db = admin.firestore();
    await db.collection('play_purchases').doc(purchaseToken).set({
      uid,
      packageName,
      subscriptionId,
      verification,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, {merge: true});

    // Simple policy: if the subscription is in an active state (e.g., paymentState 1 / expiryTimeMillis > now), mark user Pro
    let isPro = false;
    const nowMs = Date.now();
    const expiryMillis = parseInt(verification.expiryTimeMillis || '0', 10);
    if (expiryMillis && expiryMillis > nowMs) isPro = true;

    await db.collection('users').doc(uid).set({isPro, lastVerified: admin.firestore.FieldValue.serverTimestamp()}, {merge: true});

    return res.json({ok: true, verification, isPro});
  } catch (err) {
    console.error('verifyPurchase error', err && (err.stack || err.message || err));
    return res.status(500).json({error: String(err && (err.message || err))});
  }
}

// Pub/Sub RTDN handler
// Expects Play RTDN topic messages. The handler decodes the message, attempts to find a purchase token -> uid mapping,
// then verifies subscription state and updates users/{uid}.isPro accordingly.
async function handleRtdn(message, context) {
  try {
    const raw = Buffer.from(message.data, 'base64').toString('utf8');
    const payload = JSON.parse(raw);

    // Play RTDN format: {message: {data: '<base64 payload>'}} when proxied by Pub/Sub; but when invoked directly we get data already.
    // The Play RTDN payload is also base64-encoded inside the Pub/Sub message in some setups — handle both possibilities.
    let rtdn = payload;
    // If the Play RTDN is inside a 'message' wrapper
    if (payload && payload.subscriptionNotification == null && payload.signedData == null && payload.message && payload.message.data) {
      const inner = Buffer.from(payload.message.data, 'base64').toString('utf8');
      rtdn = JSON.parse(inner);
    }

    // subscriptionNotification contains { notificationType, purchaseToken, subscriptionId, packageName }
    const sn = rtdn.subscriptionNotification || rtdn;
    const purchaseToken = sn.purchaseToken || (sn && sn.oneTimeProductNotification && sn.oneTimeProductNotification.purchaseToken);
    const packageName = sn.packageName || sn.packageName;
    const subscriptionId = sn.subscriptionId || sn.subscriptionId;

    if (!purchaseToken) {
      console.warn('RTDN message missing purchaseToken, skipping', sn);
      return;
    }

    const db = admin.firestore();
    const doc = await db.collection('play_purchases').doc(purchaseToken).get();
    if (!doc.exists) {
      console.warn('No local mapping for purchaseToken; cannot map to uid. Consider running verifyPurchase for that token first.', purchaseToken);
      return;
    }
    const data = doc.data();
    const uid = data.uid;
    if (!uid) {
      console.warn('play_purchases document lacks uid:', purchaseToken);
      return;
    }

    // Re-verify with Play API to get canonical state
    const verification = await verifySubscription(data.packageName || packageName, data.subscriptionId || subscriptionId, purchaseToken);

    const nowMs = Date.now();
    const expiryMillis = parseInt(verification.expiryTimeMillis || '0', 10);
    const isPro = !!(expiryMillis && expiryMillis > nowMs);

    await db.collection('users').doc(uid).set({isPro, lastRtdn: admin.firestore.FieldValue.serverTimestamp()}, {merge: true});
    await db.collection('play_purchases').doc(purchaseToken).set({lastRtdn: sn, verification, updatedAt: admin.firestore.FieldValue.serverTimestamp()}, {merge: true});

    console.log(`RTDN reconciled token=${purchaseToken} uid=${uid} isPro=${isPro}`);
  } catch (err) {
    console.error('handleRtdn error', err && (err.stack || err.message || err));
    throw err; // rethrow so Pub/Sub may retry depending on config
  }
}

// Export functions for Cloud Functions / Cloud Run
exports.verifyPurchase = (req, res) => {
  return verifyPurchase(req, res);
};

exports.handleRtdn = async (message, context) => {
  return handleRtdn(message, context);
};

// If run locally (`node index.js`) provide a tiny dev server to accept verifyPurchase for local testing
if (require.main === module) {
  const express = require('express');
  const bodyParser = require('body-parser');
  const app = express();
  app.use(bodyParser.json());
  app.post('/verifyPurchase', async (req, res) => {
    return verifyPurchase(req, res);
  });
  const port = process.env.PORT || 8080;
  app.listen(port, () => console.log(`Local verifyPurchase listening on ${port}`));
}
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Temporary verifyPurchase HTTP endpoint (testing scaffold).
 *
 * This endpoint is intentionally minimal: it accepts a JSON body with
 * { uid, productId, platform, purchaseToken } and a header 'x-verify-key'
 * matching the environment variable VERIFY_KEY or functions config verify.key.
 * If authenticated, it records the purchase in `purchases` and marks
 * users/{uid}.isPro = true. This is a testing scaffold only — replace
 * with real verification using Google Play Developer API / App Store Server.
 */
exports.verifyPurchase = onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    const providedKey = req.get('x-verify-key') || '';
    const expectedKey =
      process.env.VERIFY_KEY ||
      (process.env.FUNCTIONS_CONFIG &&
        JSON.parse(process.env.FUNCTIONS_CONFIG).verify?.key) ||
      '';
    if (!expectedKey || providedKey !== expectedKey) {
      logger.warn('Unauthorized verifyPurchase attempt', { ip: req.ip });
      return res.status(401).send('Unauthorized');
    }

    const { uid, productId, platform, purchaseToken } = req.body || {};
    if (!uid || !productId) {
      return res.status(400).send('Missing required fields: uid, productId');
    }

    const db = admin.firestore();
    await db.collection('purchases').add({
      uid,
      productId,
      platform: platform || 'unknown',
      purchaseToken: purchaseToken || null,
      created: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection('users').doc(uid).set(
      {
        isPro: true,
        proProductId: productId,
        proSince: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    logger.log('verifyPurchase: marked user as Pro', { uid, productId });
    return res.json({ ok: true });
  } catch (err) {
    logger.error('verifyPurchase failed', { error: err });
    return res.status(500).send('Internal error');
  }
});

/**
 * Aggregates user ratings for a book whenever a rating is written.
 */
exports.aggregateRating = onDocumentWritten(
  'ratings/{ratingId}',
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const bookId = afterData?.bookId ?? beforeData?.bookId;

    if (!bookId) {
      logger.log('Rating document lacks a bookId. Cannot aggregate.');
      return;
    }

    const db = admin.firestore();
    const bookRef = db.collection('book_aggregates').doc(bookId);
    const ratingsQuery = db.collection('ratings').where('bookId', '==', bookId);

    logger.log('aggregateRating triggered', { bookId, eventId: event.id });
    const ratingsSnapshot = await ratingsQuery.get();
    logger.log('ratingsSnapshot retrieved', {
      bookId,
      size: ratingsSnapshot.size,
    });

    if (ratingsSnapshot.empty) {
      logger.log('No ratings found for book. Deleting aggregate.', { bookId });
      await bookRef.delete();
      return;
    }

    // Aggregate the new Vetted Spice Meter data
    try {
      let totalSpice = 0.0;
      let totalEmotional = 0.0;
      let spiceCount = 0;
      let emotionalCount = 0;
      const genresSet = new Set();
      const tropesSet = new Set();
      const warningsSet = new Set();

      ratingsSnapshot.forEach((doc) => {
        const data = doc.data() || {};
        const spice = data.spiceOverall;
        const emotional = data.emotionalArc;
        if (typeof spice === 'number') {
          totalSpice += spice;
          spiceCount += 1;
        }
        if (typeof emotional === 'number') {
          totalEmotional += emotional;
          emotionalCount += 1;
        }
        if (Array.isArray(data.genres)) {
          data.genres.forEach((g) => {
            if (g != null) genresSet.add(String(g));
          });
        }
        if (Array.isArray(data.tropes)) {
          data.tropes.forEach((t) => {
            if (t != null) tropesSet.add(String(t));
          });
        }
        if (Array.isArray(data.warnings)) {
          data.warnings.forEach((w) => {
            if (w != null) warningsSet.add(String(w));
          });
        }
      });

      const totalUserRatings = ratingsSnapshot.size;
      const avgSpiceOnPage = spiceCount > 0 ? totalSpice / spiceCount : null;
      const avgEmotionalArc =
        emotionalCount > 0 ? totalEmotional / emotionalCount : null;

      const dataToUpdate = {
        totalUserRatings: totalUserRatings,
        avgSpiceOnPage: avgSpiceOnPage,
        avgEmotionalArc: avgEmotionalArc,
        genres: Array.from(genresSet),
        tropes: Array.from(tropesSet),
        warnings: Array.from(warningsSet),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      };
      logger.log('Updating book aggregate (server).', {
        bookId,
        data: dataToUpdate,
      });

      await bookRef.set(dataToUpdate, { merge: true });
      logger.log('book_aggregates write completed', { bookId });
    } catch (err) {
      logger.error(
        'aggregateRating failed while computing/writing aggregates',
        { bookId, error: err },
      );
      throw err;
    }
  },
);
