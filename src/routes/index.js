import express from 'express';
import authRoutes from './auth.routes.js';
import dashboardRoutes from './dashboard.routes.js';
import diagnosticRoutes from './diagnostic.routes.js';
import latihanRoutes from './latihan.routes.js';
import materiRoutes from './materi.routes.js';

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/diagnostic', diagnosticRoutes);
router.use('/latihan', latihanRoutes);
router.use('/materials', materiRoutes);

export default router;
