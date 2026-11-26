import express from 'express';
import { verifyToken } from '../middlewares/auth.middleware.js';
import {
  getDashboardSummary,
  getContinueLearning,
  getMaterialRecommendations,
  getLeaderboard,
} from '../controllers/dashboard.controller.js';

const router = express.Router();

router.use(verifyToken);
router.get('/summary', getDashboardSummary);
router.get('/continue-learning', getContinueLearning);
router.get('/recommendations', getMaterialRecommendations);
router.get('/leaderboard', getLeaderboard);

export default router;
