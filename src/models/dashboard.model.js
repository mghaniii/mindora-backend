import pool from '../config/database.js';
import { getMaterialsWithProgress } from './material.model.js';

export const dashboardUserExists = async (userId) => {
  const [rows] = await pool.query('SELECT 1 FROM users WHERE id = ? LIMIT 1', [userId]);
  return rows.length > 0;
};

export const getDashboardSummaryRow = async (userId) => {
  const [rows] = await pool.query(
    `SELECT
       u.name,
       u.streak_days,
       u.daily_goal_minutes,
       COALESCE((
         SELECT SUM(a.xp_earned)
         FROM user_quiz_attempts a
         WHERE a.user_id = u.id AND a.status = 'completed'
       ), 0) AS total_xp,
       COALESCE((
         SELECT SUM(a.time_spent_seconds)
         FROM user_quiz_attempts a
         WHERE a.user_id = u.id
           AND a.status = 'completed'
           AND a.completed_at >= CURDATE()
           AND a.completed_at < CURDATE() + INTERVAL 1 DAY
       ), 0) AS today_seconds
     FROM users u
     WHERE u.id = ?`,
    [userId]
  );

  const summary = rows[0] || null;
  if (!summary) return null;

  const materials = await getMaterialsWithProgress(userId);
  const currentMaterial = materials
    .filter((material) => material.status === 'in_progress')
    .sort((a, b) => String(b.last_activity_at || '').localeCompare(String(a.last_activity_at || '')))[0];

  return {
    ...summary,
    completed_modules: materials.filter((material) => material.status === 'completed').length,
    current_topic: currentMaterial?.title || null,
  };
};

export const getContinueLearningRow = async (userId) => {
  const materials = await getMaterialsWithProgress(userId);
  const currentMaterial = materials
    .filter((material) => material.status === 'in_progress')
    .sort((a, b) => String(b.last_activity_at || '').localeCompare(String(a.last_activity_at || '')))[0];

  return currentMaterial
    ? {
        material_id: currentMaterial.id,
        chapter: currentMaterial.chapter,
        title: currentMaterial.title,
        completed_subtopics: currentMaterial.completed_subtopics,
        total_modules: currentMaterial.total_modules,
        progress_percentage: currentMaterial.progress,
      }
    : null;
};

export const getMaterialRecommendationRows = async (userId) => {
  const materials = await getMaterialsWithProgress(userId);
  return materials
    .filter((material) => material.status === 'ready' || material.status === 'prerequisite_progress')
    .slice(0, 3);
};

export const getLeaderboardRows = async (userId) => {
  const [rows] = await pool.query(
    `SELECT
       u.id,
       u.name,
       u.avatar,
       COALESCE(SUM(
         CASE
           WHEN a.status = 'completed'
            AND YEARWEEK(a.completed_at, 1) = YEARWEEK(CURDATE(), 1)
           THEN a.xp_earned
           ELSE 0
         END
       ), 0) AS xp
     FROM users u
     LEFT JOIN user_quiz_attempts a ON a.user_id = u.id
     WHERE u.kelas IS NOT NULL
       AND u.kelas = (SELECT kelas FROM users WHERE id = ?)
     GROUP BY u.id, u.name, u.avatar
     ORDER BY xp DESC, u.name ASC, u.id ASC
     LIMIT 10`,
    [userId]
  );

  return rows;
};
