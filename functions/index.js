const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');

// Initialize the Admin SDK. In Functions, this will use the runtime service account.
admin.initializeApp();

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Simple admin-key check to avoid unauthenticated calls. Set ADMIN_KEY as an
// environment variable in your functions environment (or use functions config).
function checkAdminKey(req) {
  const header = req.get('x-admin-key') || '';
  const secret = process.env.ADMIN_KEY || functions.config().admin?.key || '';
  return header && secret && header === secret;
}

// POST /setProClaim
// body: { uid: string, pro: boolean }
app.post('/setProClaim', async (req, res) => {
  if (!checkAdminKey(req)) {
    return res.status(403).json({ error: 'Missing or invalid admin key' });
  }

  const { uid, pro } = req.body || {};
  if (!uid || typeof pro !== 'boolean') {
    return res.status(400).json({ error: 'Missing uid or pro boolean' });
  }

  try {
    await admin.auth().setCustomUserClaims(uid, { pro });
    return res.status(200).json({ ok: true, uid, pro });
  } catch (err) {
    console.error('setProClaim error', err);
    return res.status(500).json({ error: String(err) });
  }
});

exports.api = functions.https.onRequest(app);
