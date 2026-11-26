import express from 'express';
import { verifyToken } from '../middlewares/auth.middleware.js';
import { getMaterials, patchMaterialProgress } from '../controllers/materi.controller.js';

const router = express.Router();

router.get('/', verifyToken, getMaterials);
router.patch('/:materialId/progress', verifyToken, patchMaterialProgress);

export default router;
