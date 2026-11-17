import express from 'express';
import authRoutes from './auth.routes.js';
import diagnosticRoutes from './diagnostic.routes.js';
import materiRoutes from './materi.routes.js';

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/diagnostic', diagnosticRoutes);
router.use('/materials', materiRoutes);

export default router;
