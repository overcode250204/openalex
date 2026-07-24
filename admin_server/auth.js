const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
require('./firebaseAdmin');

const ADMIN_ROLES_COLLECTION = 'admin_roles';

function sendError(res, status, code, message) {
  res.status(status).json({ error: { code, message } });
}

/**
 * Verifies the caller sent a valid Firebase ID token AND has an
 * admin_roles/{uid} doc with role: 'admin'. This is the real security
 * boundary — the client-side role check in the Flutter app is UX only
 * and is never trusted here, same as the Cloud Functions version.
 */
async function requireAdmin(req, res, next) {
  const header = req.headers.authorization || '';
  const match = header.match(/^Bearer (.+)$/);
  if (!match) {
    return sendError(res, 401, 'unauthenticated', 'Missing bearer token.');
  }

  let decoded;
  try {
    decoded = await getAuth().verifyIdToken(match[1]);
  } catch (err) {
    return sendError(res, 401, 'unauthenticated', 'Invalid or expired token.');
  }

  let doc;
  try {
    doc = await getFirestore().collection(ADMIN_ROLES_COLLECTION).doc(decoded.uid).get();
  } catch (err) {
    return sendError(res, 500, 'internal', 'Failed to verify admin role.');
  }

  if (!doc.exists || doc.data().role !== 'admin') {
    return sendError(res, 403, 'permission-denied', 'Admin role required.');
  }

  req.uid = decoded.uid;
  next();
}

module.exports = { requireAdmin, sendError };
