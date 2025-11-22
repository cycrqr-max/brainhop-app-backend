import express from 'express';
import cors from 'cors';
import fetch from 'node-fetch';

const app = express();
app.use(cors()); // allow your app to call this from anywhere

const PCLOUD_API_BASE = 'https://eapi.pcloud.com';
const PCLOUD_USERNAME = "brainhop@gmx.at";
const PCLOUD_PASSWORD = "k.e.brainhop";

let cachedAuthToken = null;

async function getAuthToken() {
  if (cachedAuthToken) return cachedAuthToken;

  const params = new URLSearchParams({
    getauth: '1',
    username: PCLOUD_USERNAME,
    password: PCLOUD_PASSWORD,
  });

  const res = await fetch(`${PCLOUD_API_BASE}/userinfo?${params.toString()}`);
  const json = await res.json();

  if (json.result !== 0 || typeof json.auth !== 'string') {
    console.error('pCloud userinfo error:', json);
    throw new Error('pCloud login failed');
  }

  cachedAuthToken = json.auth;
  return cachedAuthToken;
}

// Option A: use full *path* inside your pCloud
app.get('/pcloud/file-url', async (req, res) => {
  try {
    const path = req.query.path;
    const code = req.query.code;

    if (!path && !code) {
      return res.status(400).json({ error: 'path or code is required' });
    }

    // ---- 1) Use path + auth (private files) ----
    if (path) {
      const auth = await getAuthToken();
      const params = new URLSearchParams({ path, auth });

      const r = await fetch(`${PCLOUD_API_BASE}/getfilelink?${params.toString()}`);
      const j = await r.json();

      if (j.result !== 0) {
        console.error('getfilelink error:', j);
        return res.status(500).json({ error: 'getfilelink failed', details: j });
      }

      const host = Array.isArray(j.hosts) ? j.hosts[0] : j.hosts;
      const filePath = j.path;

      const url = (host.startsWith('http') ? host : `https://${host}`) + filePath;
      return res.json({ url });
    }

    // ---- 2) Or use a public-link CODE (if you prefer publinks) ----
    if (code) {
      const params = new URLSearchParams({ code });

      const r = await fetch(`${PCLOUD_API_BASE}/getpublinkdownload?${params.toString()}`);
      const j = await r.json();

      if (j.result !== 0) {
        console.error('getpublinkdownload error:', j);
        return res.status(500).json({ error: 'getpublinkdownload failed', details: j });
      }

      const host = Array.isArray(j.hosts) ? j.hosts[0] : j.hosts;
      const url = `https://${host}${j.path}`;
      return res.json({ url });
    }
  } catch (err) {
    console.error('Backend /pcloud/file-url error:', err);
    res.status(500).json({ error: 'internal', message: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('pCloud helper backend listening on port', PORT);
});
