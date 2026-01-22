import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../config/database';
import { AppError } from '../utils/appError';

interface RegisterData {
  email: string;
  password: string;
  name: string;
}

export class AuthService {
  async register(data: RegisterData) {
    const existingUser = await prisma.user.findUnique({
      where: { email: data.email }
    });

    if (existingUser) {
      throw new AppError('Email already registered', 400);
    }

    const hashedPassword = await bcrypt.hash(data.password, 12);

    const user = await prisma.user.create({
      data: {
        email: data.email,
        password: hashedPassword,
        name: data.name,
        role: 'USER'
      }
    });

    const tokens = this.generateTokens(user.id, user.email, user.role);

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role
      },
      ...tokens
    };
  }

  async login(email: string, password: string) {
    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      throw new AppError('Invalid credentials', 401);
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      throw new AppError('Invalid credentials', 401);
    }

    const tokens = this.generateTokens(user.id, user.email, user.role);

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role
      },
      ...tokens
    };
  }

  async refreshToken(refreshToken: string) {
    try {
      const jwtRefreshSecret = process.env.JWT_REFRESH_SECRET || 'default-refresh-secret-key';
      const decoded = jwt.verify(refreshToken, jwtRefreshSecret) as {
        userId: string;
        email: string;
        role: string;
      };

      const user = await prisma.user.findUnique({
        where: { id: decoded.userId }
      });

      if (!user) {
        throw new AppError('User not found', 404);
      }

      const tokens = this.generateTokens(user.id, user.email, user.role);

      return tokens;
    } catch (error) {
      throw new AppError('Invalid refresh token', 401);
    }
  }

  async getUserById(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        createdAt: true
      }
    });

    return user;
  }

  private generateTokens(userId: string, email: string, role: string) {
    const jwtSecret = process.env.JWT_SECRET || 'default-secret-key';
    const jwtRefreshSecret = process.env.JWT_REFRESH_SECRET || 'default-refresh-secret-key';
    const jwtExpire = process.env.JWT_EXPIRE || '7d';
    const jwtRefreshExpire = process.env.JWT_REFRESH_EXPIRE || '30d';

    const accessToken = jwt.sign(
      { userId, email, role },
      jwtSecret as jwt.Secret,
      { expiresIn: jwtExpire } as jwt.SignOptions
    );

    const refreshToken = jwt.sign(
      { userId, email, role },
      jwtRefreshSecret as jwt.Secret,
      { expiresIn: jwtRefreshExpire } as jwt.SignOptions
    );

    return { accessToken, refreshToken };
  }
}
