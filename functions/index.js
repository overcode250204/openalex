const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getRemoteConfig } = require('firebase-admin/remote-config');
const { onCall, HttpsError } = require('firebase-functions/v2/https');

initializeApp();

const ADMIN_ROLES_COLLECTION = 'admin_roles';
const NOTIFICATION_LOG_COLLECTION = 'admin_notification_log';
const REPORTS_COLLECTION = 'uploaded_pdf_reports';
const BROADCAST_TOPIC = 'broadcast_all';

const REMOTE_CONFIG_KEYS = {
  maxJournalsDisplayed: 'max_journals_displayed',
  maxKeywordsDisplayed: 'max_keywords_displayed',
};

/**
 * Verifies the caller is signed in AND has an admin_roles/{uid} doc with role: 'admin'.
 * Throws HttpsError('unauthenticated' | 'permission-denied') otherwise.
 * This is the server-side security boundary — the client-side role check
 * in the Flutter app is UX only and is not trusted here.
 */
async function assertIsAdmin(auth) {
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Sign-in required.');
  }
  const doc = await getFirestore()
    .collection(ADMIN_ROLES_COLLECTION)
    .doc(auth.uid)
    .get();
  if (!doc.exists || doc.data().role !== 'admin') {
    throw new HttpsError('permission-denied', 'Admin role required.');
  }
  return auth.uid;
}

// ── Users ────────────────────────────────────────────────────────────────

exports.adminListUsers = onCall(async (request) => {
  await assertIsAdmin(request.auth);

  const pageToken = request.data && request.data.pageToken;
  const result = await getAuth().listUsers(1000, pageToken || undefined);

  const rolesSnapshot = await getFirestore()
    .collection(ADMIN_ROLES_COLLECTION)
    .where('role', '==', 'admin')
    .get();
  const adminUids = new Set(rolesSnapshot.docs.map((d) => d.id));

  const users = result.users.map((u) => ({
    uid: u.uid,
    email: u.email || null,
    displayName: u.displayName || null,
    disabled: u.disabled,
    createdAt: u.metadata.creationTime || null,
    isAdmin: adminUids.has(u.uid),
  }));

  return { users, nextPageToken: result.pageToken || null };
});

exports.adminSetUserDisabled = onCall(async (request) => {
  const callerUid = await assertIsAdmin(request.auth);
  const { uid, disabled } = request.data || {};
  if (!uid || typeof disabled !== 'boolean') {
    throw new HttpsError('invalid-argument', 'uid and disabled are required.');
  }
  if (uid === callerUid && disabled) {
    throw new HttpsError('failed-precondition', 'You cannot disable your own account.');
  }

  await getAuth().updateUser(uid, { disabled });
  return { ok: true };
});

exports.adminSetUserRole = onCall(async (request) => {
  const callerUid = await assertIsAdmin(request.auth);
  const { uid, role } = request.data || {};
  if (!uid || (role !== 'admin' && role !== 'user')) {
    throw new HttpsError('invalid-argument', 'uid and role ("admin" | "user") are required.');
  }

  const rolesCollection = getFirestore().collection(ADMIN_ROLES_COLLECTION);
  const roleDoc = rolesCollection.doc(uid);

  if (role === 'user') {
    if (uid === callerUid) {
      throw new HttpsError('failed-precondition', 'You cannot remove your own admin role.');
    }
    const adminsSnapshot = await rolesCollection.where('role', '==', 'admin').get();
    if (adminsSnapshot.size <= 1) {
      throw new HttpsError('failed-precondition', 'At least one admin must remain.');
    }
    await roleDoc.delete();
  } else {
    await roleDoc.set({ role: 'admin', grantedBy: callerUid, grantedAt: FieldValue.serverTimestamp() });
  }

  return { ok: true };
});

// ── Remote Config ────────────────────────────────────────────────────────

exports.adminGetRemoteConfigValues = onCall(async (request) => {
  await assertIsAdmin(request.auth);

  const template = await getRemoteConfig().getTemplate();
  const readIntParam = (key) => {
    const param = template.parameters[key];
    const raw = param && param.defaultValue && param.defaultValue.value;
    const parsed = parseInt(raw, 10);
    return Number.isFinite(parsed) ? parsed : null;
  };

  return {
    maxJournalsDisplayed: readIntParam(REMOTE_CONFIG_KEYS.maxJournalsDisplayed),
    maxKeywordsDisplayed: readIntParam(REMOTE_CONFIG_KEYS.maxKeywordsDisplayed),
  };
});

exports.adminUpdateRemoteConfigValues = onCall(async (request) => {
  await assertIsAdmin(request.auth);

  const { maxJournalsDisplayed, maxKeywordsDisplayed } = request.data || {};
  if (maxJournalsDisplayed == null && maxKeywordsDisplayed == null) {
    throw new HttpsError('invalid-argument', 'Provide at least one value to update.');
  }

  const remoteConfig = getRemoteConfig();
  const template = await remoteConfig.getTemplate();

  const setParam = (key, value) => {
    if (value == null) return;
    template.parameters[key] = template.parameters[key] || {};
    template.parameters[key].defaultValue = { value: String(value) };
  };

  setParam(REMOTE_CONFIG_KEYS.maxJournalsDisplayed, maxJournalsDisplayed);
  setParam(REMOTE_CONFIG_KEYS.maxKeywordsDisplayed, maxKeywordsDisplayed);

  await remoteConfig.publishTemplate(template);
  return { ok: true };
});

// ── Notifications ────────────────────────────────────────────────────────

exports.adminSendBroadcastNotification = onCall(async (request) => {
  const callerUid = await assertIsAdmin(request.auth);
  const { title, body } = request.data || {};
  if (!title || !body) {
    throw new HttpsError('invalid-argument', 'title and body are required.');
  }

  await getMessaging().send({
    topic: BROADCAST_TOPIC,
    notification: { title, body },
  });

  await getFirestore().collection(NOTIFICATION_LOG_COLLECTION).add({
    title,
    body,
    sentBy: callerUid,
    sentAt: FieldValue.serverTimestamp(),
  });

  return { ok: true };
});

// ── Reports ──────────────────────────────────────────────────────────────

exports.adminListAllReports = onCall(async (request) => {
  await assertIsAdmin(request.auth);

  const limit = Math.min((request.data && request.data.limit) || 20, 100);
  const cursor = request.data && request.data.cursor;

  let query = getFirestore()
    .collection(REPORTS_COLLECTION)
    .orderBy('createdAt', 'desc')
    .limit(limit);

  if (cursor) {
    const cursorDoc = await getFirestore().collection(REPORTS_COLLECTION).doc(cursor).get();
    if (cursorDoc.exists) {
      query = query.startAfter(cursorDoc);
    }
  }

  const snapshot = await query.get();
  const reports = snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      userId: data.userId || null,
      topic: data.topic || '',
      provider: data.provider || '',
      bucket: data.bucket || '',
      objectKey: data.objectKey || '',
      fileName: data.fileName || '',
      downloadUrl: data.downloadUrl || '',
      sizeBytes: data.sizeBytes || 0,
      uploadedAt: data.uploadedAt ? data.uploadedAt.toDate().toISOString() : null,
    };
  });

  const nextCursor = snapshot.docs.length === limit ? snapshot.docs[snapshot.docs.length - 1].id : null;
  return { reports, nextCursor };
});

// ── Dashboard stats ──────────────────────────────────────────────────────

exports.adminGetDashboardStats = onCall(async (request) => {
  await assertIsAdmin(request.auth);

  const auth = getAuth();
  let totalUsers = 0;
  let pageToken;
  // Bounded to 10 pages (10,000 users) to keep this call cheap and fast.
  for (let i = 0; i < 10; i += 1) {
    const page = await auth.listUsers(1000, pageToken);
    totalUsers += page.users.length;
    pageToken = page.pageToken;
    if (!pageToken) break;
  }

  const firestore = getFirestore();
  const [adminsCountSnap, reportsCountSnap] = await Promise.all([
    firestore.collection(ADMIN_ROLES_COLLECTION).where('role', '==', 'admin').count().get(),
    firestore.collection(REPORTS_COLLECTION).count().get(),
  ]);

  return {
    totalUsers,
    totalAdmins: adminsCountSnap.data().count,
    totalReports: reportsCountSnap.data().count,
  };
});
