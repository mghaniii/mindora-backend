import { getMaterialsWithProgress } from '../models/material.model.js';

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
