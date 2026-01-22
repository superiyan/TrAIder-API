"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserService = void 0;
const database_1 = require("../config/database");
const appError_1 = require("../utils/appError");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
class UserService {
    async getProfile(userId) {
        const user = await database_1.prisma.user.findUnique({
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
            throw new appError_1.AppError('User not found', 404);
        }
        return user;
    }
    async updateProfile(userId, data) {
        const user = await database_1.prisma.user.update({
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
    async changePassword(userId, currentPassword, newPassword) {
        const user = await database_1.prisma.user.findUnique({
            where: { id: userId }
        });
        if (!user) {
            throw new appError_1.AppError('User not found', 404);
        }
        const isPasswordValid = await bcryptjs_1.default.compare(currentPassword, user.password);
        if (!isPasswordValid) {
            throw new appError_1.AppError('Current password is incorrect', 400);
        }
        const hashedPassword = await bcryptjs_1.default.hash(newPassword, 12);
        await database_1.prisma.user.update({
            where: { id: userId },
            data: { password: hashedPassword }
        });
    }
    async getSettings(userId) {
        const settings = await database_1.prisma.userSettings.findUnique({
            where: { userId }
        });
        return settings || {};
    }
    async updateSettings(userId, data) {
        const settings = await database_1.prisma.userSettings.upsert({
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
exports.UserService = UserService;
