const express = require('express');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getRemoteConfig } = require('firebase-admin/remote-config');
require('../firebaseAdmin');
const { requireAdmin, sendError } = require('../auth');

const router = express.Router();

const ADMIN_ROLES_COLLECTION = 'admin_roles';
const NOTIFICATION_LOG_COLLECTION = 'admin_notification_log';
const REPORTS_COLLECTION = 'uploaded_pdf_reports';
const BROADCAST_TOPIC = 'broadcast_all';

const REMOTE_CONFIG_KEYS = {
  maxJournalsDisplayed: 'max_journals_displayed',
  maxKeywordsDisplayed: 'max_keywords_displayed',
};

router.use(requireAdmin);

function asyncHandler(fn) {
  return (req, res) => fn(req, res).catch((err) => {
    console.error(err);
    sendError(res, 500, 'internal', err.message || 'Internal error.');
  });
}

// ── Users ────────────────────────────────────────────────────────────────

router.post('/listUsers', asyncHandler(async (req, res) => {
  const pageToken = req.body && req.body.pageToken;
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

  res.json({ users, nextPageToken: result.pageToken || null });
}));

router.post('/setUserDisabled', asyncHandler(async (req, res) => {
  const callerUid = req.uid;
  const { uid, disabled } = req.body || {};
  if (!uid || typeof disabled !== 'boolean') {
    return sendError(res, 400, 'invalid-argument', 'uid and disabled are required.');
  }
  if (uid === callerUid && disabled) {
    return sendError(res, 412, 'failed-precondition', 'You cannot disable your own account.');
  }

  await getAuth().updateUser(uid, { disabled });
  res.json({ ok: true });
}));

router.post('/setUserRole', asyncHandler(async (req, res) => {
  const callerUid = req.uid;
  const { uid, role } = req.body || {};
  if (!uid || (role !== 'admin' && role !== 'user')) {
    return sendError(res, 400, 'invalid-argument', 'uid and role ("admin" | "user") are required.');
  }

  const rolesCollection = getFirestore().collection(ADMIN_ROLES_COLLECTION);
  const roleDoc = rolesCollection.doc(uid);

  if (role === 'user') {
    if (uid === callerUid) {
      return sendError(res, 412, 'failed-precondition', 'You cannot remove your own admin role.');
    }
    const adminsSnapshot = await rolesCollection.where('role', '==', 'admin').get();
    if (adminsSnapshot.size <= 1) {
      return sendError(res, 412, 'failed-precondition', 'At least one admin must remain.');
    }
    await roleDoc.delete();
  } else {
    await roleDoc.set({ role: 'admin', grantedBy: callerUid, grantedAt: FieldValue.serverTimestamp() });
  }

  res.json({ ok: true });
}));

// ── Remote Config ────────────────────────────────────────────────────────

router.post('/getRemoteConfigValues', asyncHandler(async (req, res) => {
  const template = await getRemoteConfig().getTemplate();
  const readIntParam = (key) => {
    const param = template.parameters[key];
    const raw = param && param.defaultValue && param.defaultValue.value;
    const parsed = parseInt(raw, 10);
    return Number.isFinite(parsed) ? parsed : null;
  };

  res.json({
    maxJournalsDisplayed: readIntParam(REMOTE_CONFIG_KEYS.maxJournalsDisplayed),
    maxKeywordsDisplayed: readIntParam(REMOTE_CONFIG_KEYS.maxKeywordsDisplayed),
  });
}));

router.post('/updateRemoteConfigValues', asyncHandler(async (req, res) => {
  const { maxJournalsDisplayed, maxKeywordsDisplayed } = req.body || {};
  if (maxJournalsDisplayed == null && maxKeywordsDisplayed == null) {
    return sendError(res, 400, 'invalid-argument', 'Provide at least one value to update.');
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
  res.json({ ok: true });
}));

// ── Notifications ────────────────────────────────────────────────────────

router.post('/sendBroadcastNotification', asyncHandler(async (req, res) => {
  const callerUid = req.uid;
  const { title, body } = req.body || {};
  if (!title || !body) {
    return sendError(res, 400, 'invalid-argument', 'title and body are required.');
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

  res.json({ ok: true });
}));

// ── Reports ──────────────────────────────────────────────────────────────

router.post('/listAllReports', asyncHandler(async (req, res) => {
  const limit = Math.min((req.body && req.body.limit) || 20, 100);
  const cursor = req.body && req.body.cursor;

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
  res.json({ reports, nextCursor });
}));

// ── Dashboard stats ──────────────────────────────────────────────────────

router.post('/getDashboardStats', asyncHandler(async (req, res) => {
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

  res.json({
    totalUsers,
    totalAdmins: adminsCountSnap.data().count,
    totalReports: reportsCountSnap.data().count,
  });
}));

module.exports = router;
