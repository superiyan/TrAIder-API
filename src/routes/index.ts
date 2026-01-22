import { Router } from 'express';
import authRoutes from './auth.routes';
import marketRoutes from './market.routes';
import tradeRoutes from './trade.routes';
import aiRoutes from './ai.routes';
import userRoutes from './user.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/market', marketRoutes);
router.use('/trades', tradeRoutes);
router.use('/ai', aiRoutes);
router.use('/users', userRoutes);

export default router;
