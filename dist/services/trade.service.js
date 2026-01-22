"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TradeService = void 0;
const database_1 = require("../config/database");
const appError_1 = require("../utils/appError");
class TradeService {
    async getPortfolio(userId) {
        const positions = await database_1.prisma.position.findMany({
            where: { userId, status: 'OPEN' }
        });
        const totalValue = positions.reduce((sum, pos) => sum + pos.currentValue, 0);
        const totalPnL = positions.reduce((sum, pos) => sum + pos.unrealizedPnL, 0);
        return {
            totalValue,
            totalPnL,
            positions: positions.length,
            details: positions
        };
    }
    async getPositions(userId) {
        const positions = await database_1.prisma.position.findMany({
            where: { userId, status: 'OPEN' },
            orderBy: { createdAt: 'desc' }
        });
        return positions;
    }
    async placeOrder(userId, data) {
        // Validate balance, check limits, etc.
        const order = await database_1.prisma.order.create({
            data: {
                userId,
                symbol: data.symbol,
                type: data.type,
                side: data.side,
                quantity: data.quantity,
                price: data.price,
                status: 'PENDING'
            }
        });
        // In production, send order to exchange API
        // For now, simulate order execution
        await this.simulateOrderExecution(order.id);
        return order;
    }
    async getOrders(userId, status, limit = 50) {
        const orders = await database_1.prisma.order.findMany({
            where: {
                userId,
                ...(status && { status })
            },
            orderBy: { createdAt: 'desc' },
            take: limit
        });
        return orders;
    }
    async getOrderById(orderId, userId) {
        const order = await database_1.prisma.order.findFirst({
            where: { id: orderId, userId }
        });
        if (!order) {
            throw new appError_1.AppError('Order not found', 404);
        }
        return order;
    }
    async cancelOrder(orderId, userId) {
        const order = await database_1.prisma.order.findFirst({
            where: { id: orderId, userId, status: 'PENDING' }
        });
        if (!order) {
            throw new appError_1.AppError('Order not found or cannot be cancelled', 404);
        }
        await database_1.prisma.order.update({
            where: { id: orderId },
            data: { status: 'CANCELLED' }
        });
    }
    async getTradeHistory(userId, limit, offset) {
        const trades = await database_1.prisma.trade.findMany({
            where: { userId },
            orderBy: { executedAt: 'desc' },
            take: limit,
            skip: offset
        });
        return trades;
    }
    async simulateOrderExecution(orderId) {
        // Simulate order execution after a delay
        setTimeout(async () => {
            await database_1.prisma.order.update({
                where: { id: orderId },
                data: { status: 'FILLED', executedAt: new Date() }
            });
        }, 1000);
    }
}
exports.TradeService = TradeService;
