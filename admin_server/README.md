# admin_server

Standalone REST backend for the ScholarTrend Admin Dashboard. It exposes the
same 8 operations as `functions/index.js`, but as a plain Express app hosted
outside Firebase — so it works even when the Firebase project **cannot** be
upgraded to the Blaze plan (e.g. blocked by a Google Billing error).

It authenticates every request the same way the Cloud Functions did: verify
the caller's Firebase ID token, then re-check `admin_roles/{uid}` server-side
via the Admin SDK before doing anything privileged. The Flutter app never
gets to skip that check — the client-side role routing is UX only.

None of this requires Blaze. Calling Firebase Auth / Firestore / Cloud
Messaging / Remote Config from a server with a service account key is a
normal Admin SDK operation on every plan; only *deploying Cloud Functions
inside Firebase's own infrastructure* requires Blaze, which this approach
avoids entirely by hosting the server elsewhere.

## Endpoints

All endpoints are `POST`, require `Authorization: Bearer <Firebase ID token>`,
and return JSON. On error: `{"error": {"code": "...", "message": "..."}}`.

| Path | Body | Purpose |
|---|---|---|
| `/admin/listUsers` | `{pageToken?}` | Paginated Firebase Auth users + admin flag |
| `/admin/setUserDisabled` | `{uid, disabled}` | Enable/disable an account |
| `/admin/setUserRole` | `{uid, role: "admin"\|"user"}` | Grant/revoke admin |
| `/admin/getRemoteConfigValues` | `{}` | Read `max_journals_displayed`, `max_keywords_displayed` |
| `/admin/updateRemoteConfigValues` | `{maxJournalsDisplayed?, maxKeywordsDisplayed?}` | Update Remote Config |
| `/admin/sendBroadcastNotification` | `{title, body}` | FCM push to `broadcast_all` topic |
| `/admin/listAllReports` | `{limit?, cursor?}` | Paginated uploaded PDF reports |
| `/admin/getDashboardStats` | `{}` | Total users / admins / reports |

`GET /health` — plain liveness check, no auth.

## 1. Get a service account key

1. Firebase Console → your project → ⚙️ **Project settings** → **Service accounts**
2. **Generate new private key** → downloads a JSON file
3. Minify it to one line (needed for pasting into an env var):
   ```bash
   node -e "console.log(JSON.stringify(require('./serviceAccountKey.json')))"
   ```
4. Keep that output somewhere safe — you'll paste it as `FIREBASE_SERVICE_ACCOUNT_KEY`.

**Never commit the key file or the minified string to git.**

## 2. Run locally

```bash
cd admin_server
npm install
cp .env.example .env
# paste the minified service account JSON as FIREBASE_SERVICE_ACCOUNT_KEY in .env
npm start
```

Server listens on `http://localhost:8080`. Confirm with:

```bash
curl http://localhost:8080/health
```

Point the Flutter app at it by setting in the app's root `.env`:

```
ADMIN_API_BASE_URL=http://localhost:8080
```

## 3. Deploy for free (Render.com)

1. Push this repo to GitHub (already done for the main project)
2. [render.com](https://render.com) → **New** → **Web Service** → connect the repo
3. **Root Directory**: `admin_server`
4. **Runtime**: Node
5. **Build Command**: `npm install`
6. **Start Command**: `npm start`
7. **Instance Type**: Free
8. Under **Environment**, add:
   - `FIREBASE_SERVICE_ACCOUNT_KEY` = the minified JSON string from step 1
9. Deploy. Render gives you a URL like `https://scholartrend-admin.onrender.com`
10. Set `ADMIN_API_BASE_URL=https://scholartrend-admin.onrender.com` in the
    Flutter app's `.env` (no trailing slash needed either way)

**Free tier note:** Render's free web services sleep after ~15 minutes of no
traffic and take ~30-60s to wake up on the next request — fine for a student
project demo, just expect the first admin action after idle to be slow.

## 4. Deploy for free (Railway.app) — alternative

1. [railway.app](https://railway.app) → **New Project** → **Deploy from GitHub repo**
2. Set **Root Directory** to `admin_server` in the service settings
3. Add the `FIREBASE_SERVICE_ACCOUNT_KEY` variable under **Variables**
4. Railway auto-detects `npm start`; deploy
5. Copy the generated public URL into the Flutter app's `.env` as `ADMIN_API_BASE_URL`

## Switching back to Cloud Functions later

If the Blaze billing issue gets resolved, `functions/index.js` already has
the identical logic as callable functions. To switch back:

1. `firebase deploy --only functions`
2. In `lib/app/app_providers.dart`, swap `HttpAdminService(baseUrl: ...)`
   back to `FirebaseAdminService()` (the file is untouched, still present
   under `lib/services/firebase/firebase_admin_service.dart`)

Both implementations satisfy the same `AdminService` interface, so nothing
else in the app needs to change.
