import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { TradeService } from '../services/trade.service';
import { AppError } from '../utils/appError';

const tradeService = new TradeService();

export class TradeController {
  async getPortfolio(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('User not authenticated', 401);

      const portfolio = await tradeService.getPortfolio(req.user.id);

      res.json({
        status: 'success',
        data: { portfolio }
      });
    } catch (error) {
      next(error);
    }
  }

  async getPositions(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('User not authenticated', 401);

      const positions = await tradeService.getPositions(req.user.id);

      res.json({
        status: 'success',
        data: { positions }
      });
    } catch (error) {
      next(error);
    }
  }

  async placeOrder(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('User not authenticated', 401);

      const order = await tradeService.placeOrder(req.user.id, req.body);

      res.status(201).json({
        status: 'success',
        data: { order }
      });
    } catch (error) {
      next(error);
    }
  }

  async getOrders(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('User not authenticated', 401);

      const { status, limit = 50 } = req.query;
      const orders = await tradeService.getOrders(
        req.user.id,
        status as string | undefined,
        parseInt(limit as string)
      );

      res.json({
        status: 'success',
        data: { orders }
      });
    } catch (error) {
      next(error);
    }
  }

  async getOrderById(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('User not authenticated', 401);

      const order = await tradeService.getOrderById(req.params.id, req.user.id);

      res.json({
        status: 'success',
        data: { order }
      });
    } catch (error) {
      next(error);
    }
  }

  async cancelOrder(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('User not authenticated', 401);

      await tradeService.cancelOrder(req.params.id, req.user.id);

      res.json({
        status: 'success',
        message: 'Order cancelled successfully'
      });
    } catch (error) {
      next(error);
    }
  }

  async getTradeHistory(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('User not authenticated', 401);

      const { limit = 50, offset = 0 } = req.query;
      const history = await tradeService.getTradeHistory(
        req.user.id,
        parseInt(limit as string),
        parseInt(offset as string)
      );

      res.json({
        status: 'success',
        data: { history }
      });
    } catch (error) {
      next(error);
    }
  }
}
