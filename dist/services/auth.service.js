"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const database_1 = require("../config/database");
const appError_1 = require("../utils/appError");
class AuthService {
    async register(data) {
        const existingUser = await database_1.prisma.user.findUnique({
            where: { email: data.email }
        });
        if (existingUser) {
            throw new appError_1.AppError('Email already registered', 400);
        }
        const hashedPassword = await bcryptjs_1.default.hash(data.password, 12);
        const user = await database_1.prisma.user.create({
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
    async login(email, password) {
        const user = await database_1.prisma.user.findUnique({
            where: { email }
        });
        if (!user) {
            throw new appError_1.AppError('Invalid credentials', 401);
        }
        const isPasswordValid = await bcryptjs_1.default.compare(password, user.password);
        if (!isPasswordValid) {
            throw new appError_1.AppError('Invalid credentials', 401);
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
    async refreshToken(refreshToken) {
        try {
            const jwtRefreshSecret = process.env.JWT_REFRESH_SECRET || 'default-refresh-secret-key';
            const decoded = jsonwebtoken_1.default.verify(refreshToken, jwtRefreshSecret);
            const user = await database_1.prisma.user.findUnique({
                where: { id: decoded.userId }
            });
            if (!user) {
                throw new appError_1.AppError('User not found', 404);
            }
            const tokens = this.generateTokens(user.id, user.email, user.role);
            return tokens;
        }
        catch (error) {
            throw new appError_1.AppError('Invalid refresh token', 401);
        }
    }
    async getUserById(userId) {
        const user = await database_1.prisma.user.findUnique({
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
    generateTokens(userId, email, role) {
        const jwtSecret = process.env.JWT_SECRET || 'default-secret-key';
        const jwtRefreshSecret = process.env.JWT_REFRESH_SECRET || 'default-refresh-secret-key';
        const jwtExpire = process.env.JWT_EXPIRE || '7d';
        const jwtRefreshExpire = process.env.JWT_REFRESH_EXPIRE || '30d';
        const accessToken = jsonwebtoken_1.default.sign({ userId, email, role }, jwtSecret, { expiresIn: jwtExpire });
        const refreshToken = jsonwebtoken_1.default.sign({ userId, email, role }, jwtRefreshSecret, { expiresIn: jwtRefreshExpire });
        return { accessToken, refreshToken };
    }
}
exports.AuthService = AuthService;
