import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { AIService } from '../services/ai.service';

const aiService = new AIService();

export class AIController {
  async getTradingSignals(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { symbols, timeframe = '1h' } = req.query;
      
      const signals = await aiService.getTradingSignals(
        symbols as string | undefined,
        timeframe as string
      );

      res.json({
        status: 'success',
        data: { signals }
      });
    } catch (error) {
      next(error);
    }
  }

  async getSymbolAnalysis(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { symbol } = req.params;
      const analysis = await aiService.analyzeSymbol(symbol);

      res.json({
        status: 'success',
        data: { analysis }
      });
    } catch (error) {
      next(error);
    }
  }

  async getPricePrediction(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { symbol, horizon = 24 } = req.body;
      const prediction = await aiService.predictPrice(symbol, parseInt(horizon));

      res.json({
        status: 'success',
        data: { prediction }
      });
    } catch (error) {
      next(error);
    }
  }

  async getSentimentAnalysis(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { symbol } = req.params;
      const sentiment = await aiService.getSentiment(symbol);

      res.json({
        status: 'success',
        data: { sentiment }
      });
    } catch (error) {
      next(error);
    }
  }
}
