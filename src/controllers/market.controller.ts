import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { MarketService } from '../services/market.service';

const marketService = new MarketService();

export class MarketController {
  async getTickers(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const tickers = await marketService.getAllTickers();

      res.json({
        status: 'success',
        data: { tickers }
      });
    } catch (error) {
      next(error);
    }
  }

  async getTickerData(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { symbol } = req.params;
      const tickerData = await marketService.getTickerData(symbol);

      res.json({
        status: 'success',
        data: { ticker: tickerData }
      });
    } catch (error) {
      next(error);
    }
  }

  async getCandlestickData(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { symbol } = req.params;
      const { interval = '1h', limit = 100 } = req.query;

      const candles = await marketService.getCandlestickData(
        symbol,
        interval as string,
        parseInt(limit as string)
      );

      res.json({
        status: 'success',
        data: { candles }
      });
    } catch (error) {
      next(error);
    }
  }

  async searchSymbols(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { q } = req.query;
      const results = await marketService.searchSymbols(q as string);

      res.json({
        status: 'success',
        data: { results }
      });
    } catch (error) {
      next(error);
    }
  }
}
