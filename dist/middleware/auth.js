"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authorize = exports.authenticate = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const appError_1 = require("../utils/appError");
const auth_service_1 = require("../services/auth.service");
const authService = new auth_service_1.AuthService();
const authenticate = async (req, res, next) => {
    try {
        const token = req.headers.authorization?.replace('Bearer ', '');
        if (!token) {
            throw new appError_1.AppError('Authentication required', 401);
        }
        const jwtSecret = process.env.JWT_SECRET || 'default-secret-key';
        const decoded = jsonwebtoken_1.default.verify(token, jwtSecret);
        const user = await authService.getUserById(decoded.userId);
        if (!user) {
            throw new appError_1.AppError('User not found', 401);
        }
        req.user = {
            id: user.id,
            email: user.email,
            role: user.role
        };
        next();
    }
    catch (error) {
        next(error);
    }
};
exports.authenticate = authenticate;
const authorize = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return next(new appError_1.AppError('Authentication required', 401));
        }
        if (!roles.includes(req.user.role)) {
            return next(new appError_1.AppError('Insufficient permissions', 403));
        }
        next();
    };
};
exports.authorize = authorize;
