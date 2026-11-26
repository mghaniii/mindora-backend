const toNumber = (value) => {
  const number = Number(value);
  return Number.isFinite(number) ? number : 0;
};

const toNonNegativeNumber = (value) => Math.max(0, toNumber(value));

const toPercentage = (value) => Math.min(100, toNonNegativeNumber(value));

const toNullableString = (value) => {
  if (value === null || value === undefined) return null;
  const text = String(value);
  return text.trim() ? text : null;
};

export const toDashboardSummaryDTO = (row) => {
  if (!row) return null;

  const totalTargetMinutes = toNonNegativeNumber(row.daily_goal_minutes);
  const spentMinutes = Math.round(toNonNegativeNumber(row.today_seconds) / 60);
  const targetPercentage = totalTargetMinutes > 0
    ? Math.min(100, Math.round((spentMinutes / totalTargetMinutes) * 100))
    : 0;

  return {
    name: String(row.name || ''),
    currentTopic: toNullableString(row.current_topic),
    targetPercentage,
    spentMinutes,
    totalTargetMinutes,
    streakDays: toNonNegativeNumber(row.streak_days),
    totalXp: toNonNegativeNumber(row.total_xp),
    completedModules: toNonNegativeNumber(row.completed_modules),
  };
};

export const toContinueLearningDTO = (row) => {
  if (!row) return null;

  return {
    materialId: String(row.material_id || ''),
    chapter: toNullableString(row.chapter),
    title: String(row.title || ''),
    completedSubtopics: toNonNegativeNumber(row.completed_subtopics),
    totalSubtopics: toNonNegativeNumber(row.total_modules),
    progressPercentage: toPercentage(row.progress_percentage),
  };
};

export const toMaterialRecommendationDTO = (row) => ({
  id: String(row.id),
  category: String(row.category || ''),
  categoryFilter: String(row.category_filter || ''),
  title: String(row.title || ''),
  description: String(row.description || ''),
  moduleCount: toNonNegativeNumber(row.total_modules),
});

export const toLeaderboardDTO = (rows, currentUserId) => rows.map((row, index) => ({
  id: String(row.id),
  rank: index + 1,
  name: String(row.name || ''),
  avatar: row.avatar || null,
  xp: toNonNegativeNumber(row.xp),
  isCurrentUser: String(row.id) === String(currentUserId),
}));
