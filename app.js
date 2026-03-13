import express from 'express';
import cors from 'cors';

import pool from './db/db.js';

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => res.send('BrainHop API running'));
//testing
pool.query('SELECT NOW()', (err, res) => {
  if (err) console.error('DB error:', err);
  else console.log('DB connected:', res.rows[0]);
});

async function connectWithRetry(retries = 10, delay = 1000) {
  for (let i = 0; i < retries; i++) {
    try {
      const res = await pool.query('SELECT NOW()');
      console.log('DB connected:', res.rows[0]);
      return;
    } catch (err) {
      console.log('DB not ready yet, retrying...', i + 1);
      await new Promise(r => setTimeout(r, delay));
    }
  }
  console.error('DB connection failed after retries.');
}

connectWithRetry();
//testing end
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`BrainHop backend listening on port ${PORT}`));