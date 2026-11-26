import express from 'express';
import { verifyToken } from '../middlewares/auth.middleware.js';
import { getLatihanQuiz, submitLatihanQuiz } from '../controllers/latihan.controller.js';

const router = express.Router();

router.use(verifyToken);
router.get('/:itemId/kuis', getLatihanQuiz);
router.post('/:itemId/kuis/submit', submitLatihanQuiz);

export default router;
