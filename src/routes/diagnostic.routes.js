import express from 'express';
import { verifyToken } from '../middlewares/auth.middleware.js';
import { getDiagnosticQuestions, submitDiagnostic } from '../controllers/diagnostic.controller.js';

const router = express.Router();

router.get('/questions', verifyToken, getDiagnosticQuestions);
router.post('/submit', verifyToken, submitDiagnostic);

export default router;
