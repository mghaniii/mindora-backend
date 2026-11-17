import express from 'express';
import { verifyToken } from '../middlewares/auth.middleware.js';
import { getMaterials } from '../controllers/materi.controller.js';

const router = express.Router();

router.get('/', verifyToken, getMaterials);

export default router;
