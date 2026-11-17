import pool from '../config/database.js';

const USER_SELECT = `
  SELECT u.id, u.name, u.email, u.password, u.kelas,
         EXISTS(SELECT 1 FROM diagnostic_history dh WHERE dh.user_id = u.id) AS has_completed_diagnostic
  FROM users u
`;

export const findUserByEmail = async (email) => {
  const [rows] = await pool.query(`${USER_SELECT} WHERE u.email = ? LIMIT 1`, [email]);
  return rows[0] || null;
};

export const findUserById = async (id) => {
  const [rows] = await pool.query(`${USER_SELECT} WHERE u.id = ? LIMIT 1`, [id]);
  return rows[0] || null;
};

// kelas sengaja dihilangkan dari INSERT saat tidak dikirim, supaya
// DEFAULT 'Kelas 2 SMA' di database yang dipakai (INSERT eksplisit NULL
// akan menyimpan NULL, bukan default).
export const createUser = async ({ name, email, passwordHash, kelas }) => {
  if (kelas === undefined || kelas === null || kelas === '') {
    const [result] = await pool.query(
      'INSERT INTO users (name, email, password, created_at) VALUES (?, ?, ?, NOW())',
      [name, email, passwordHash],
    );
    return result.insertId;
  }
  const [result] = await pool.query(
    'INSERT INTO users (name, email, password, kelas, created_at) VALUES (?, ?, ?, ?, NOW())',
    [name, email, passwordHash, kelas],
  );
  return result.insertId;
};
