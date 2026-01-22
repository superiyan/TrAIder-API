"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TradeController = void 0;
const trade_service_1 = require("../services/trade.service");
const appError_1 = require("../utils/appError");
const tradeService = new trade_service_1.TradeService();
class TradeController {
    async getPortfolio(req, res, next) {
        try {
            if (!req.user)
                throw new appError_1.AppError('User not authenticated', 401);
            const portfolio = await tradeService.getPortfolio(req.user.id);
            res.json({
                status: 'success',
                data: { portfolio }
            });
        }
        catch (error) {
            next(error);
        }
    }
    async getPositions(req, res, next) {
        try {
            if (!req.user)
                throw new appError_1.AppError('User not authenticated', 401);
            const positions = await tradeService.getPositions(req.user.id);
            res.json({
                status: 'success',
                data: { positions }
            });
        }
        catch (error) {
            next(error);
        }
    }
    async placeOrder(req, res, next) {
        try {
            if (!req.user)
                throw new appError_1.AppError('User not authenticated', 401);
            const order = await tradeService.placeOrder(req.user.id, req.body);
            res.status(201).json({
                status: 'success',
                data: { order }
            });
        }
        catch (error) {
            next(error);
        }
    }
    async getOrders(req, res, next) {
        try {
            if (!req.user)
                throw new appError_1.AppError('User not authenticated', 401);
            const { status, limit = 50 } = req.query;
            const orders = await tradeService.getOrders(req.user.id, status, parseInt(limit));
            res.json({
                status: 'success',
                data: { orders }
            });
        }
        catch (error) {
            next(error);
        }
    }
    async getOrderById(req, res, next) {
        try {
            if (!req.user)
                throw new appError_1.AppError('User not authenticated', 401);
            const order = await tradeService.getOrderById(req.params.id, req.user.id);
            res.json({
                status: 'success',
                data: { order }
            });
        }
        catch (error) {
            next(error);
        }
    }
    async cancelOrder(req, res, next) {
        try {
            if (!req.user)
                throw new appError_1.AppError('User not authenticated', 401);
            await tradeService.cancelOrder(req.params.id, req.user.id);
            res.json({
                status: 'success',
                message: 'Order cancelled successfully'
            });
        }
        catch (error) {
            next(error);
        }
    }
    async getTradeHistory(req, res, next) {
        try {
            if (!req.user)
                throw new appError_1.AppError('User not authenticated', 401);
            const { limit = 50, offset = 0 } = req.query;
            const history = await tradeService.getTradeHistory(req.user.id, parseInt(limit), parseInt(offset));
            res.json({
                status: 'success',
                data: { history }
            });
        }
        catch (error) {
            next(error);
        }
    }
}
exports.TradeController = TradeController;
