import { getMaterialsWithProgress, updateMaterialProgress } from '../models/material.model.js';
import { httpError, requireNonNegativeInteger } from '../utils/activityValidation.js';

const toMaterialDTO = (m) => ({
  id: m.id,
  title: m.title,
  category: m.category,
  categoryFilter: m.category_filter,
  description: m.description,
  chapter: m.chapter,
  totalModules: m.total_modules,
  exercisesCount: m.exercises_count,
  durationMinutes: m.duration_minutes,
  xpReward: m.xp_reward,
  progress: m.progress,
  status: m.status,
  completedSubtopics: m.completed_subtopics,
  score: m.score,
});

export const getMaterials = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const materials = await getMaterialsWithProgress(userId);
    return res.status(200).json({ success: true, data: materials.map(toMaterialDTO) });
  } catch (error) {
    next(error);
  }
};

export const patchMaterialProgress = async (req, res, next) => {
  try {
    const body = req.body || {};
    const completedSubtopics = requireNonNegativeInteger(body.completedSubtopics, 'completedSubtopics');
    const scoreProvided = Object.prototype.hasOwnProperty.call(body, 'score') && body.score !== undefined;
    let score = null;

    if (scoreProvided && body.score !== null) {
      if (typeof body.score !== 'number' || !Number.isFinite(body.score) || body.score < 0 || body.score > 100) {
        throw httpError(400, 'score harus bernilai null atau berupa angka antara 0 dan 100.');
      }
      score = Math.round(body.score);
    }

    const progress = await updateMaterialProgress({
      userId: req.user.id,
      materialId: req.params.materialId,
      completedSubtopics,
      scoreProvided,
      score,
    });

    return res.status(200).json({
      success: true,
      data: {
        materialId: progress.material_id,
        completedSubtopics: Number(progress.completed_subtopics),
        totalModules: Number(progress.total_modules),
        progressPercentage: Number(progress.progress_percentage),
        status: progress.status,
        score: progress.score === null ? null : Number(progress.score),
        lastActivityAt: progress.last_activity_at,
      },
    });
  } catch (error) {
    next(error);
  }
};
