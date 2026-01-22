"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthController = void 0;
const auth_service_1 = require("../services/auth.service");
const appError_1 = require("../utils/appError");
const authService = new auth_service_1.AuthService();
class AuthController {
    async register(req, res, next) {
        try {
            const { email, password, name } = req.body;
            const result = await authService.register({ email, password, name });
            res.status(201).json({
                status: 'success',
                data: result
            });
        }
        catch (error) {
            next(error);
        }
    }
    async login(req, res, next) {
        try {
            const { email, password } = req.body;
            const result = await authService.login(email, password);
            res.json({
                status: 'success',
                data: result
            });
        }
        catch (error) {
            next(error);
        }
    }
    async refreshToken(req, res, next) {
        try {
            const { refreshToken } = req.body;
            const result = await authService.refreshToken(refreshToken);
            res.json({
                status: 'success',
                data: result
            });
        }
        catch (error) {
            next(error);
        }
    }
    async logout(req, res, next) {
        try {
            // Add token to blacklist or remove refresh token
            res.json({
                status: 'success',
                message: 'Logged out successfully'
            });
        }
        catch (error) {
            next(error);
        }
    }
    async getCurrentUser(req, res, next) {
        try {
            if (!req.user) {
                throw new appError_1.AppError('User not found', 404);
            }
            const user = await authService.getUserById(req.user.id);
            res.json({
                status: 'success',
                data: { user }
            });
        }
        catch (error) {
            next(error);
        }
    }
}
exports.AuthController = AuthController;
