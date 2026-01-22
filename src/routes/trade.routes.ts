import { Router } from 'express';
import { TradeController } from '../controllers/trade.controller';
import { authenticate } from '../middleware/auth';
import { validateRequest } from '../middleware/validateRequest';
import { tradeValidation } from '../validators/trade.validator';

const router = Router();
const tradeController = new TradeController();

router.get('/portfolio', authenticate, tradeController.getPortfolio);
router.get('/positions', authenticate, tradeController.getPositions);
router.post('/order', authenticate, validateRequest(tradeValidation.createOrder), tradeController.placeOrder);
router.get('/orders', authenticate, tradeController.getOrders);
router.get('/orders/:id', authenticate, tradeController.getOrderById);
router.delete('/order/:id', authenticate, tradeController.cancelOrder);
router.get('/history', authenticate, tradeController.getTradeHistory);

export default router;
