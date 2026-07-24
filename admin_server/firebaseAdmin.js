const { initializeApp, cert, applicationDefault } = require('firebase-admin/app');

/**
 * Credential resolution order:
 *  1. FIREBASE_SERVICE_ACCOUNT_KEY — the full service account JSON as a
 *     single-line env var string (what you set on Render/Railway).
 *  2. GOOGLE_APPLICATION_CREDENTIALS — a file path (local dev only).
 * This backend never needs the Blaze plan: it talks to Firebase Auth,
 * Firestore, Cloud Messaging and Remote Config as a normal Admin SDK
 * client, the same way any server-side app would — that surface is
 * free on every plan. Only deploying *Cloud Functions themselves*
 * requires Blaze, which this project deliberately avoids.
 */
function buildCredential() {
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
  if (raw) {
    return cert(JSON.parse(raw));
  }
  return applicationDefault();
}

const app = initializeApp({ credential: buildCredential() });

module.exports = { app };
