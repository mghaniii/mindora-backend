import pool from '../config/database.js';
import { httpError } from '../utils/activityValidation.js';

const getUserLevel = async (database, userId) => {
  const [xpRows] = await database.query(
    `SELECT COALESCE(SUM(xp_earned), 0) AS total_xp
     FROM user_quiz_attempts
     WHERE user_id = ? AND status = 'completed'`,
    [userId]
  );
  const [levels] = await database.query('SELECT level, min_xp FROM levels ORDER BY min_xp DESC');
  const totalXp = Number(xpRows[0]?.total_xp ?? 0);
  return levels.find((level) => totalXp >= Number(level.min_xp))?.level ?? 1;
};

const getProgressStatus = (material, progress) => {
  if (!progress) return 'ready';
  const completedSubtopics = Number(progress.completed_subtopics ?? 0);
  if (completedSubtopics >= Number(material.total_modules)) return 'completed';
  if (completedSubtopics > 0) return 'in_progress';
  return 'ready';
};

const createStatusResolver = (materials, progressByMaterial, userLevel) => {
  const materialById = new Map(materials.map((material) => [material.id, material]));
  const resolved = new Map();
  const resolving = new Set();

  const resolve = (material) => {
    if (resolved.has(material.id)) return resolved.get(material.id);
    if (resolving.has(material.id)) return 'locked_prerequisite';
    resolving.add(material.id);

    const progress = progressByMaterial.get(material.id);
    let status = getProgressStatus(material, progress);

    if (material.prerequisite_id) {
      const prerequisite = materialById.get(material.prerequisite_id);
      const prerequisiteStatus = prerequisite ? resolve(prerequisite) : 'locked_prerequisite';
      if (prerequisiteStatus !== 'completed') {
        const prerequisiteProgress = progressByMaterial.get(material.prerequisite_id);
        const hasProgress = Number(prerequisiteProgress?.completed_subtopics ?? 0) > 0;
        status = hasProgress ? 'prerequisite_progress' : 'locked_prerequisite';
      }
    }

    if (status !== 'locked_prerequisite' && status !== 'prerequisite_progress'
      && material.required_level !== null && userLevel < Number(material.required_level)) {
      status = 'locked_level';
    }

    resolving.delete(material.id);
    resolved.set(material.id, status);
    return status;
  };

  return resolve;
};

export const getMaterialsWithProgress = async (userId) => {
  const [materials] = await pool.query(
    `SELECT id, title, category, category_filter, description, chapter,
            total_modules, exercises_count, duration_minutes, xp_reward,
            prerequisite_id, required_level, sort_order
     FROM materials
     ORDER BY sort_order ASC`
  );
  const [progressRows] = await pool.query(
    `SELECT material_id, progress_percentage, status, completed_subtopics,
            score, last_activity_at, updated_at
     FROM user_material_progress
     WHERE user_id = ?`,
    [userId]
  );
  const progressByMaterial = new Map(progressRows.map((progress) => [progress.material_id, progress]));
  const userLevel = await getUserLevel(pool, userId);
  const resolveStatus = createStatusResolver(materials, progressByMaterial, userLevel);

  return materials.map((material) => {
    const progress = progressByMaterial.get(material.id);
    return {
      ...material,
      progress: Number(progress?.progress_percentage ?? 0),
      status: resolveStatus(material),
      completed_subtopics: Number(progress?.completed_subtopics ?? 0),
      score: progress?.score ?? null,
      last_activity_at: progress?.last_activity_at ?? null,
      updated_at: progress?.updated_at ?? null,
    };
  });
};

const refreshMaterialStatuses = async (connection, materials, progressByMaterial, userLevel) => {
  const resolveStatus = createStatusResolver(materials, progressByMaterial, userLevel);
  for (const material of materials) {
    const progress = progressByMaterial.get(material.id);
    if (!progress) continue;
    const status = resolveStatus(material);
    if (status === progress.status) continue;
    await connection.query(
      'UPDATE user_material_progress SET status = ?, updated_at = NOW() WHERE user_id = ? AND material_id = ?',
      [status, progress.user_id, material.id]
    );
    progress.status = status;
  }
};

export const updateMaterialProgress = async ({
  userId,
  materialId,
  completedSubtopics,
  scoreProvided,
  score,
}) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [users] = await connection.query('SELECT id FROM users WHERE id = ? LIMIT 1 FOR UPDATE', [userId]);
    if (users.length === 0) throw httpError(401, 'Sesi tidak valid. Silakan login kembali.');

    const [materials] = await connection.query(
      `SELECT id, total_modules, prerequisite_id, required_level
       FROM materials
       ORDER BY sort_order ASC
       FOR UPDATE`
    );
    const material = materials.find((item) => item.id === materialId);
    if (!material) throw httpError(404, 'Materi tidak ditemukan.');

    const totalModules = Number(material.total_modules);
    if (!Number.isInteger(totalModules) || totalModules <= 0) {
      throw httpError(500, 'Konfigurasi total modul materi tidak valid.');
    }
    if (!Number.isSafeInteger(completedSubtopics) || completedSubtopics < 0 || completedSubtopics > totalModules) {
      throw httpError(400, `completedSubtopics harus berada antara 0 dan ${totalModules}.`);
    }

    const [progressRows] = await connection.query(
      `SELECT user_id, material_id, status, completed_subtopics
       FROM user_material_progress
       WHERE user_id = ?
       FOR UPDATE`,
      [userId]
    );
    const progressByMaterial = new Map(progressRows.map((progress) => [progress.material_id, progress]));
    const userLevel = await getUserLevel(connection, userId);
    const resolveStatus = createStatusResolver(materials, progressByMaterial, userLevel);
    const lockStatus = resolveStatus(material);
    if (lockStatus === 'locked_prerequisite' || lockStatus === 'locked_level') {
      throw httpError(409, 'Materi masih terkunci dan progresnya tidak dapat diubah.');
    }

    const currentProgress = progressByMaterial.get(materialId);
    if (currentProgress && completedSubtopics < Number(currentProgress.completed_subtopics)) {
      throw httpError(409, 'Progres materi tidak dapat dikurangi dari nilai yang sudah tersimpan.');
    }

    const progressPercentage = Math.round((completedSubtopics / totalModules) * 100);
    const status = completedSubtopics === 0
      ? 'ready'
      : completedSubtopics === totalModules ? 'completed' : 'in_progress';
    const scoreUpdate = scoreProvided ? 'score = VALUES(score),' : '';

    await connection.query(
      `INSERT INTO user_material_progress
         (user_id, material_id, progress_percentage, status, completed_subtopics, score, last_activity_at)
       VALUES (?, ?, ?, ?, ?, ?, NOW())
       ON DUPLICATE KEY UPDATE
         progress_percentage = VALUES(progress_percentage),
         status = VALUES(status),
         completed_subtopics = VALUES(completed_subtopics),
         ${scoreUpdate}
         last_activity_at = NOW(),
         updated_at = NOW()`,
      [userId, materialId, progressPercentage, status, completedSubtopics, scoreProvided ? score : null]
    );

    progressByMaterial.set(materialId, {
      user_id: userId,
      material_id: materialId,
      status,
      completed_subtopics: completedSubtopics,
    });
    await refreshMaterialStatuses(connection, materials, progressByMaterial, userLevel);

    const [savedRows] = await connection.query(
      `SELECT p.material_id, p.completed_subtopics, m.total_modules,
              p.progress_percentage, p.status, p.score, p.last_activity_at
       FROM user_material_progress p
       JOIN materials m ON m.id = p.material_id
       WHERE p.user_id = ? AND p.material_id = ?
       LIMIT 1`,
      [userId, materialId]
    );
    await connection.commit();
    return savedRows[0];
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};
