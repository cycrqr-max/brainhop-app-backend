// server.js
import express from 'express';
import cors from 'cors';
import fetch from 'node-fetch';

const app = express();
app.use(cors()); // allow your app to call this from anywhere

const PCLOUD_API_BASE = 'https://eapi.pcloud.com';
const PCLOUD_USERNAME = 'brainhop@gmx.at';
const PCLOUD_PASSWORD = 'k.e.brainhop';

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

// (Optional) old endpoint, now just for debugging if you want
app.get('/pcloud/file-url', async (req, res) => {
  try {
    const path = req.query.path;
    const code = req.query.code;

    if (!path && !code) {
      return res.status(400).json({ error: 'path or code is required' });
    }

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

/**
 * NEW: stream endpoint
 * app/video URL will be:  https://brainhop-app-backend.onrender.com/pcloud/stream?path=/0-21-Tage-Programm/...
 */
app.get('/pcloud/stream', async (req, res) => {
  try {
    const path = req.query.path;
    if (!path || typeof path !== 'string') {
      return res.status(400).json({ error: 'path query param is required' });
    }

    // 1) resolve a direct pCloud link with auth+path
    const auth = await getAuthToken();
    const params = new URLSearchParams({ path, auth });

    const linkRes = await fetch(`${PCLOUD_API_BASE}/getfilelink?${params.toString()}`);
    const linkJson = await linkRes.json();

    if (linkJson.result !== 0) {
      console.error('getfilelink error (stream):', linkJson);
      return res
        .status(500)
        .json({ error: 'getfilelink failed', details: linkJson });
    }

    const host = Array.isArray(linkJson.hosts) ? linkJson.hosts[0] : linkJson.hosts;
    const filePath = linkJson.path;

    if (!host || !filePath) {
      console.error('Invalid getfilelink response (stream):', linkJson);
      return res.status(500).json({ error: 'invalid getfilelink response' });
    }

    const fileUrl =
      host.startsWith('http') ? `${host}${filePath}` : `https://${host}${filePath}`;

    // 2) Forward Range header so video seeking works
    const range = req.headers.range;
    const headers = {};
    if (range) {
      headers['range'] = range;
    }

    const fileRes = await fetch(fileUrl, { headers });

    // 3) Copy status + headers
    res.status(fileRes.status);
    fileRes.headers.forEach((value, key) => {
      if (key.toLowerCase() === 'transfer-encoding') return; // avoid conflicts
      res.setHeader(key, value);
    });

    // 4) Pipe body
    if (!fileRes.body) {
      return res.end();
    }

    fileRes.body.pipe(res);
  } catch (err) {
    console.error('Backend /pcloud/stream error:', err);
    if (!res.headersSent) {
      res.status(500).json({ error: 'stream failed', message: err.message });
    } else {
      res.end();
    }
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('pCloud helper backend listening on port', PORT);
});
