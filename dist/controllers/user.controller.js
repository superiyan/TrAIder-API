"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserController = void 0;
const user_service_1 = require("../services/user.service");
const appError_1 = require("../utils/appError");
const userService = new user_service_1.UserService();
class UserController {
    async getProfile(req, res, next) {
        try {
            if (!req.user)
                throw new appError_1.AppError('User not authenticated', 401);
            const profile = await userService.getProfile(req.user.id);
            res.json({
                status: 'success',
                data: { profile }
            });
        }
        catch (error) {
            next(error);
        }
    }
    async updateProfile(req, res, next) {
        try {
            if (!req.user)
                throw new appError_1.AppError('User not authenticated', 401);
            const profile = await userService.updateProfile(req.user.id, req.body);
            res.json({
                status: 'success',
                data: { profile }
            });
        }
        catch (error) {
            next(error);
        }
    }
    async changePassword(req, res, next) {
        try {
            if (!req.user)
                throw new appError_1.AppError('User not authenticated', 401);
            const { currentPassword, newPassword } = req.body;
            await userService.changePassword(req.user.id, currentPassword, newPassword);
            res.json({
                status: 'success',
                message: 'Password changed successfully'
            });
        }
        catch (error) {
            next(error);
        }
    }
    async getSettings(req, res, next) {
        try {
            if (!req.user)
                throw new appError_1.AppError('User not authenticated', 401);
            const settings = await userService.getSettings(req.user.id);
            res.json({
                status: 'success',
                data: { settings }
            });
        }
        catch (error) {
            next(error);
        }
    }
    async updateSettings(req, res, next) {
        try {
            if (!req.user)
                throw new appError_1.AppError('User not authenticated', 401);
            const settings = await userService.updateSettings(req.user.id, req.body);
            res.json({
                status: 'success',
                data: { settings }
            });
        }
        catch (error) {
            next(error);
        }
    }
}
exports.UserController = UserController;
