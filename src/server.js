import dotenv from 'dotenv';
import app from './app.js';
import pool from './config/database.js';
import { assertJwtSecret } from './utils/jwtHelper.js';

dotenv.config();
assertJwtSecret();

const PORT = Number(process.env.PORT) || 8080;

const start = async () => {
  try {
    await pool.query('SELECT 1');
    console.log(`[DB] Koneksi MySQL berhasil (${process.env.DB_NAME || 'mindora_db'})`);
    app.listen(PORT, () => {
      console.log(`[Server] Mindora API berjalan di http://localhost:${PORT}/api`);
    });
  } catch (error) {
    console.error('[DB] Gagal koneksi MySQL:', error.message);
    process.exit(1);
  }
};

start();
