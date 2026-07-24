try {
  require('dotenv').config();
} catch (_) {
  // dotenv is a devDependency-style convenience for local dev only;
  // on Render/Railway env vars are injected directly, no .env file exists.
}

const express = require('express');
const cors = require('cors');
const adminRoutes = require('./routes/admin');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (_req, res) => {
  res.json({ ok: true, service: 'scholartrend-admin-server' });
});

app.get('/health', (_req, res) => res.json({ ok: true }));

app.use('/admin', adminRoutes);

// Express error handler fallback (e.g. malformed JSON body).
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(400).json({ error: { code: 'invalid-argument', message: 'Malformed request.' } });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`admin_server listening on port ${PORT}`);
});
