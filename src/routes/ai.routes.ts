import { Router } from 'express';
import { AIController } from '../controllers/ai.controller';
import { authenticate } from '../middleware/auth';

const router = Router();
const aiController = new AIController();

router.get('/signals', authenticate, aiController.getTradingSignals);
router.get('/analysis/:symbol', authenticate, aiController.getSymbolAnalysis);
router.post('/predict', authenticate, aiController.getPricePrediction);
router.get('/sentiment/:symbol', authenticate, aiController.getSentimentAnalysis);

export default router;
