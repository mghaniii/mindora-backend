import pool from '../config/database.js';

// Daftar materi digabung (LEFT JOIN) dengan progres user: materi tanpa
// baris progres mendapat status 'ready' dan progress 0 lewat COALESCE.
export const getMaterialsWithProgress = async (userId) => {
  const [rows] = await pool.query(
    `SELECT
       m.id, m.title, m.category, m.category_filter, m.description, m.chapter,
       m.total_modules, m.exercises_count, m.duration_minutes, m.xp_reward,
       COALESCE(p.progress_percentage, 0) AS progress,
       COALESCE(p.status, 'ready') AS status,
       p.completed_subtopics, p.score
     FROM materials m
     LEFT JOIN user_material_progress p
       ON p.material_id = m.id AND p.user_id = ?
     ORDER BY m.sort_order ASC`,
    [userId]
  );
  // CAST memastikan COALESCE kembali sebagai angka (mysql2 kadang
  // mengembalikannya sebagai string pada hasil fungsi agregat).
  return rows.map((m) => ({
    ...m,
    progress: Number(m.progress),
    completed_subtopics: Number(m.completed_subtopics ?? 0),
  }));
};
