"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AIController = void 0;
const ai_service_1 = require("../services/ai.service");
const aiService = new ai_service_1.AIService();
class AIController {
    async getTradingSignals(req, res, next) {
        try {
            const { symbols, timeframe = '1h' } = req.query;
            const signals = await aiService.getTradingSignals(symbols, timeframe);
            res.json({
                status: 'success',
                data: { signals }
            });
        }
        catch (error) {
            next(error);
        }
    }
    async getSymbolAnalysis(req, res, next) {
        try {
            const { symbol } = req.params;
            const analysis = await aiService.analyzeSymbol(symbol);
            res.json({
                status: 'success',
                data: { analysis }
            });
        }
        catch (error) {
            next(error);
        }
    }
    async getPricePrediction(req, res, next) {
        try {
            const { symbol, horizon = 24 } = req.body;
            const prediction = await aiService.predictPrice(symbol, parseInt(horizon));
            res.json({
                status: 'success',
                data: { prediction }
            });
        }
        catch (error) {
            next(error);
        }
    }
    async getSentimentAnalysis(req, res, next) {
        try {
            const { symbol } = req.params;
            const sentiment = await aiService.getSentiment(symbol);
            res.json({
                status: 'success',
                data: { sentiment }
            });
        }
        catch (error) {
            next(error);
        }
    }
}
exports.AIController = AIController;
