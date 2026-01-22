import { Router } from 'express';
import { MarketController } from '../controllers/market.controller';
import { authenticate } from '../middleware/auth';

const router = Router();
const marketController = new MarketController();

router.get('/tickers', authenticate, marketController.getTickers);
router.get('/ticker/:symbol', authenticate, marketController.getTickerData);
router.get('/candles/:symbol', authenticate, marketController.getCandlestickData);
router.get('/search', authenticate, marketController.searchSymbols);

export default router;
