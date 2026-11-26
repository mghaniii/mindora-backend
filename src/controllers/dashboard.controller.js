import {
  dashboardUserExists,
  getDashboardSummaryRow,
  getContinueLearningRow,
  getMaterialRecommendationRows,
  getLeaderboardRows,
} from '../models/dashboard.model.js';
import {
  toDashboardSummaryDTO,
  toContinueLearningDTO,
  toMaterialRecommendationDTO,
  toLeaderboardDTO,
} from '../utils/dashboardDto.js';

const invalidSession = (res) => res.status(401).json({
  success: false,
  message: 'Sesi tidak valid. Silakan login kembali.',
});

export const getDashboardSummary = async (req, res, next) => {
  try {
    const row = await getDashboardSummaryRow(req.user.id);
    if (!row) return invalidSession(res);

    return res.status(200).json({ success: true, data: toDashboardSummaryDTO(row) });
  } catch (error) {
    next(error);
  }
};

export const getContinueLearning = async (req, res, next) => {
  try {
    if (!(await dashboardUserExists(req.user.id))) return invalidSession(res);

    const row = await getContinueLearningRow(req.user.id);
    return res.status(200).json({ success: true, data: toContinueLearningDTO(row) });
  } catch (error) {
    next(error);
  }
};

export const getMaterialRecommendations = async (req, res, next) => {
  try {
    if (!(await dashboardUserExists(req.user.id))) return invalidSession(res);

    const rows = await getMaterialRecommendationRows(req.user.id);
    const data = rows.map(toMaterialRecommendationDTO);
    return res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};

export const getLeaderboard = async (req, res, next) => {
  try {
    if (!(await dashboardUserExists(req.user.id))) return invalidSession(res);

    const rows = await getLeaderboardRows(req.user.id);
    const data = toLeaderboardDTO(rows, req.user.id);
    return res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
