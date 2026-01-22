import { prisma } from '../config/database';
import { AppError } from '../utils/appError';

interface CreateOrderData {
  symbol: string;
  type: string;
  side: string;
  quantity: number;
  price?: number;
}

export class TradeService {
  async getPortfolio(userId: string) {
    const positions = await prisma.position.findMany({
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

  async getPositions(userId: string) {
    const positions = await prisma.position.findMany({
      where: { userId, status: 'OPEN' },
      orderBy: { createdAt: 'desc' }
    });

    return positions;
  }

  async placeOrder(userId: string, data: CreateOrderData) {
    // Validate balance, check limits, etc.
    const order = await prisma.order.create({
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

  async getOrders(userId: string, status?: string, limit: number = 50) {
    const orders = await prisma.order.findMany({
      where: {
        userId,
        ...(status && { status })
      },
      orderBy: { createdAt: 'desc' },
      take: limit
    });

    return orders;
  }

  async getOrderById(orderId: string, userId: string) {
    const order = await prisma.order.findFirst({
      where: { id: orderId, userId }
    });

    if (!order) {
      throw new AppError('Order not found', 404);
    }

    return order;
  }

  async cancelOrder(orderId: string, userId: string) {
    const order = await prisma.order.findFirst({
      where: { id: orderId, userId, status: 'PENDING' }
    });

    if (!order) {
      throw new AppError('Order not found or cannot be cancelled', 404);
    }

    await prisma.order.update({
      where: { id: orderId },
      data: { status: 'CANCELLED' }
    });
  }

  async getTradeHistory(userId: string, limit: number, offset: number) {
    const trades = await prisma.trade.findMany({
      where: { userId },
      orderBy: { executedAt: 'desc' },
      take: limit,
      skip: offset
    });

    return trades;
  }

  private async simulateOrderExecution(orderId: string) {
    // Simulate order execution after a delay
    setTimeout(async () => {
      await prisma.order.update({
        where: { id: orderId },
        data: { status: 'FILLED', executedAt: new Date() }
      });
    }, 1000);
  }
}
