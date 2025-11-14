const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');

// Initialize the Admin SDK. In Functions, this will use the runtime service account.
admin.initializeApp();

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Developer email allowed to perform admin actions from the app
const DEVELOPER_EMAIL = 'hotcupofjoe2013@gmail.com';

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
    // Write an audit record for this admin action. We don't have a callable
    // context here, so capture whatever actor info is provided in headers/body.
    try {
      const actorEmail =
        req.get('x-admin-email') || req.body?.actorEmail || null;
      await admin
        .firestore()
        .collection('admin_audit')
        .add({
          actorUid: null,
          actorEmail: actorEmail,
          action: 'setProClaim',
          targetUid: uid,
          details: { pro: !!pro },
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
    } catch (auditErr) {
      console.warn('Failed to write admin audit for setProClaim:', auditErr);
    }
    return res.status(200).json({ ok: true, uid, pro });
  } catch (err) {
    console.error('setProClaim error', err);
    return res.status(500).json({ error: String(err) });
  }
});

exports.api = functions.https.onRequest(app);

// -----------------------------
// Callable admin functions
// -----------------------------

// Helper to validate caller. This prefers a UID allow-list stored in
// Firestore at `config/admins` (field `uids: []`). It falls back to
// checking custom claims or the developer email.
async function isAdmin(context) {
  const auth = context.auth;
  if (!auth || !auth.token) return false;

  const uid = auth.uid || null;
  const email = (auth.token && auth.token.email) || '';

  // 1) Check custom admin claim
  if (auth.token && auth.token.admin === true) return true;

  // 2) Check environment variable ADMIN_UIDS (comma-separated)
  const envUids =
    process.env.ADMIN_UIDS || functions.config().admin?.uids || '';
  if (envUids) {
    const arr = envUids
      .toString()
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
    if (uid && arr.includes(uid)) return true;
  }

  // 3) Check Firestore allow-list document: config/admins { uids: [...] }
  try {
    const doc = await admin.firestore().doc('config/admins').get();
    if (doc.exists) {
      const data = doc.data() || {};
      const uids = Array.isArray(data.uids) ? data.uids : [];
      if (uid && uids.includes(uid)) return true;
    }
  } catch (err) {
    console.warn('Failed to read admin allow-list:', err);
  }

  // 4) Fallback to developer email check
  if (email && email.toLowerCase() === DEVELOPER_EMAIL.toLowerCase())
    return true;

  return false;
}

// Audit logger for admin actions
async function writeAdminAudit(
  context,
  action,
  targetUid = null,
  details = {},
) {
  try {
    const auth = context.auth || {};
    const actorUid = auth.uid || null;
    const actorEmail = (auth.token && auth.token.email) || null;
    await admin
      .firestore()
      .collection('admin_audit')
      .add({
        actorUid,
        actorEmail,
        action,
        targetUid: targetUid || null,
        details: details || {},
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
  } catch (err) {
    console.warn('Failed to write admin audit:', err);
  }
}

exports.getUserByEmail = functions.https.onCall(async (data, context) => {
  if (!(await isAdmin(context))) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Developer access required',
    );
  }

  const email = ((data && data.email) || '').toString().toLowerCase().trim();
  if (!email)
    throw new functions.https.HttpsError('invalid-argument', 'Missing email');

  try {
    const usersRef = admin.firestore().collection('users');
    const q = await usersRef.where('email', '==', email).limit(1).get();
    if (q.empty) return { found: false };
    const doc = q.docs[0];
    const d = doc.data();
    const result = {
      found: true,
      uid: doc.id,
      email: d.email || null,
      displayName: d.displayName || null,
      proStatus: d.proStatus || false,
      librarian: d.librarian || false,
      createdAt: d.createdAt || null,
    };
    // audit
    await writeAdminAudit(context, 'getUserByEmail', doc.id, { email });
    return result;
  } catch (err) {
    console.error('getUserByEmail error', err);
    throw new functions.https.HttpsError('internal', String(err));
  }
});

// Allow authenticated users to request a friend by email.
// This callable will look up the target user by email and create a
// pending friend document under the target's `users/{targetUid}/friends/{senderUid}`.
// It also writes a lightweight outgoing marker under the sender's friends collection.
exports.sendFriendRequestByEmail = functions.https.onCall(
  async (data, context) => {
    const auth = context.auth;
    if (!auth || !auth.uid) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required',
      );
    }

    const email = ((data && data.email) || '').toString().toLowerCase().trim();
    if (!email)
      throw new functions.https.HttpsError('invalid-argument', 'Missing email');

    // Prevent sending requests to yourself
    const callerEmail = (auth.token && auth.token.email) || '';
    if (callerEmail.toLowerCase() === email.toLowerCase()) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Cannot add yourself as a friend',
      );
    }

    try {
      const usersRef = admin.firestore().collection('users');
      const q = await usersRef.where('email', '==', email).limit(1).get();
      if (q.empty) return { found: false };

      const doc = q.docs[0];
      const targetUid = doc.id;
      const senderUid = auth.uid;

      // Create pending request under the target user's friends collection
      const targetFriendRef = usersRef
        .doc(targetUid)
        .collection('friends')
        .doc(senderUid);
      await targetFriendRef.set({
        friendId: senderUid,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        sharing: {
          readingProgress: true,
          spiceRatings: true,
          hardStops: false,
          reviews: true,
        },
      });

      // Create an outgoing marker under the sender's friends collection so the sender
      // has a record of the request (status 'outgoing'). This is optional but useful.
      const senderFriendRef = usersRef
        .doc(senderUid)
        .collection('friends')
        .doc(targetUid);
      await senderFriendRef.set({
        friendId: targetUid,
        status: 'outgoing',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await writeAdminAudit(context, 'sendFriendRequest', targetUid, {
        from: senderUid,
        email,
      });

      return {
        ok: true,
        found: true,
        uid: targetUid,
        email: doc.data().email || null,
        displayName: doc.data().displayName || null,
      };
    } catch (err) {
      console.error('sendFriendRequestByEmail error', err);
      throw new functions.https.HttpsError('internal', String(err));
    }
  },
);

exports.setLibrarianStatus = functions.https.onCall(async (data, context) => {
  if (!(await isAdmin(context))) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Developer access required',
    );
  }

  const { uid, librarian } = data || {};
  if (!uid || typeof librarian !== 'boolean') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing uid or librarian boolean',
    );
  }

  try {
    const docRef = admin.firestore().collection('users').doc(uid);
    await docRef.update({
      librarian: librarian,
      librarianStatusUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      librarianStatusUpdatedBy: DEVELOPER_EMAIL,
    });
    await writeAdminAudit(context, 'setLibrarianStatus', uid, { librarian });
    return { ok: true, uid, librarian };
  } catch (err) {
    console.error('setLibrarianStatus error', err);
    throw new functions.https.HttpsError('internal', String(err));
  }
});

exports.setProStatus = functions.https.onCall(async (data, context) => {
  if (!(await isAdmin(context))) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Developer access required',
    );
  }

  const { uid, pro } = data || {};
  if (!uid || typeof pro !== 'boolean') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing uid or pro boolean',
    );
  }

  try {
    // Update Firestore user doc
    const docRef = admin.firestore().collection('users').doc(uid);
    await docRef.update({
      proStatus: pro,
      proStatusUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      proStatusUpdatedBy: DEVELOPER_EMAIL,
    });
    // Also set custom claim in Auth so server-side checks can rely on it
    await admin.auth().setCustomUserClaims(uid, { pro });
    await writeAdminAudit(context, 'setProStatus', uid, { pro });
    return { ok: true, uid, pro };
  } catch (err) {
    console.error('setProStatus error', err);
    throw new functions.https.HttpsError('internal', String(err));
  }
});

exports.getProUsers = functions.https.onCall(async (data, context) => {
  if (!(await isAdmin(context))) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Developer access required',
    );
  }

  try {
    const snapshot = await admin
      .firestore()
      .collection('users')
      .where('proStatus', '==', true)
      .get();
    const users = snapshot.docs.map((d) => ({
      uid: d.id,
      email: d.data().email || null,
      displayName: d.data().displayName || null,
      proStatusUpdatedAt: d.data().proStatusUpdatedAt || null,
    }));
    await writeAdminAudit(context, 'getProUsers', null, {
      count: users.length,
    });
    return users;
  } catch (err) {
    console.error('getProUsers error', err);
    throw new functions.https.HttpsError('internal', String(err));
  }
});

exports.getLibrarians = functions.https.onCall(async (data, context) => {
  if (!(await isAdmin(context))) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Developer access required',
    );
  }

  try {
    const snapshot = await admin
      .firestore()
      .collection('users')
      .where('librarian', '==', true)
      .get();
    const users = snapshot.docs.map((d) => ({
      uid: d.id,
      email: d.data().email || null,
      displayName: d.data().displayName || null,
      librarianStatusUpdatedAt: d.data().librarianStatusUpdatedAt || null,
    }));
    await writeAdminAudit(context, 'getLibrarians', null, {
      count: users.length,
    });
    return users;
  } catch (err) {
    console.error('getLibrarians error', err);
    throw new functions.https.HttpsError('internal', String(err));
  }
});

exports.searchUsers = functions.https.onCall(async (data, context) => {
  if (!(await isAdmin(context))) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Developer access required',
    );
  }

  const pattern = ((data && data.pattern) || '')
    .toString()
    .toLowerCase()
    .trim();
  if (!pattern) return [];

  try {
    const usersRef = admin.firestore().collection('users');
    const snapshot = await usersRef
      .where('email', '>=', pattern)
      .where('email', '<', pattern + '\\uf8ff')
      .limit(50)
      .get();
    const users = snapshot.docs.map((d) => ({
      uid: d.id,
      email: d.data().email || null,
      displayName: d.data().displayName || null,
      proStatus: d.data().proStatus || false,
      librarian: d.data().librarian || false,
      createdAt: d.data().createdAt || null,
    }));
    await writeAdminAudit(context, 'searchUsers', null, {
      pattern,
      count: users.length,
    });
    return users;
  } catch (err) {
    console.error('searchUsers error', err);
    throw new functions.https.HttpsError('internal', String(err));
  }
});

// Lightweight diagnostics callable to validate admin access from the client.
// Returns basic caller info and records a ping in the admin_audit collection.
exports.pingAdmin = functions.https.onCall(async (data, context) => {
  if (!(await isAdmin(context))) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Developer access required',
    );
  }

  try {
    const auth = context.auth || {};
    const actorUid = auth.uid || null;
    const actorEmail = (auth.token && auth.token.email) || null;
    await writeAdminAudit(context, 'pingAdmin', null, {
      note: 'diagnostic ping',
    });
    return { ok: true, actorUid, actorEmail, now: Date.now() };
  } catch (err) {
    console.error('pingAdmin error', err);
    throw new functions.https.HttpsError('internal', String(err));
  }
});

// Allow an admin caller to write a diagnostic/audit entry from the client.
// This callable is intentionally restricted to admins via `isAdmin(context)`
// so that only trusted developer accounts or allow-listed UIDs can write
// diagnostic messages into `admin_audit` for troubleshooting.
exports.logClientDiagnostic = functions.https.onCall(async (data, context) => {
  if (!(await isAdmin(context))) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Developer access required',
    );
  }

  try {
    const message = (data && data.message) || '';
    const extra = (data && data.extra) || {};

    await writeAdminAudit(context, 'clientDiagnostic', null, {
      message: message.toString(),
      extra: extra,
    });

    return { ok: true };
  } catch (err) {
    console.error('logClientDiagnostic error', err);
    throw new functions.https.HttpsError('internal', String(err));
  }
});
