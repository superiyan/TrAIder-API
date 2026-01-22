"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MarketController = void 0;
const market_service_1 = require("../services/market.service");
const marketService = new market_service_1.MarketService();
class MarketController {
    async getTickers(req, res, next) {
        try {
            const tickers = await marketService.getAllTickers();
            res.json({
                status: 'success',
                data: { tickers }
            });
        }
        catch (error) {
            next(error);
        }
    }
    async getTickerData(req, res, next) {
        try {
            const { symbol } = req.params;
            const tickerData = await marketService.getTickerData(symbol);
            res.json({
                status: 'success',
                data: { ticker: tickerData }
            });
        }
        catch (error) {
            next(error);
        }
    }
    async getCandlestickData(req, res, next) {
        try {
            const { symbol } = req.params;
            const { interval = '1h', limit = 100 } = req.query;
            const candles = await marketService.getCandlestickData(symbol, interval, parseInt(limit));
            res.json({
                status: 'success',
                data: { candles }
            });
        }
        catch (error) {
            next(error);
        }
    }
    async searchSymbols(req, res, next) {
        try {
            const { q } = req.query;
            const results = await marketService.searchSymbols(q);
            res.json({
                status: 'success',
                data: { results }
            });
        }
        catch (error) {
            next(error);
        }
    }
}
exports.MarketController = MarketController;
