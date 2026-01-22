import { prisma } from '../config/database';
import { AppError } from '../utils/appError';
import bcrypt from 'bcryptjs';

export class UserService {
  async getProfile(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        createdAt: true,
        updatedAt: true
      }
    });

    if (!user) {
      throw new AppError('User not found', 404);
    }

    return user;
  }

  async updateProfile(userId: string, data: { name?: string }) {
    const user = await prisma.user.update({
      where: { id: userId },
      data,
      select: {
        id: true,
        email: true,
        name: true,
        role: true
      }
    });

    return user;
  }

  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) {
      throw new AppError('User not found', 404);
    }

    const isPasswordValid = await bcrypt.compare(currentPassword, user.password);

    if (!isPasswordValid) {
      throw new AppError('Current password is incorrect', 400);
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);

    await prisma.user.update({
      where: { id: userId },
      data: { password: hashedPassword }
    });
  }

  async getSettings(userId: string) {
    const settings = await prisma.userSettings.findUnique({
      where: { userId }
    });

    return settings || {};
  }

  async updateSettings(userId: string, data: any) {
    const settings = await prisma.userSettings.upsert({
      where: { userId },
      update: data,
      create: {
        userId,
        ...data
      }
    });

    return settings;
  }
}
