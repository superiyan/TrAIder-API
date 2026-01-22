"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.errorHandler = void 0;
const appError_1 = require("../utils/appError");
const logger_1 = __importDefault(require("../utils/logger"));
const errorHandler = (err, req, res, _next) => {
    if (err instanceof appError_1.AppError) {
        logger_1.default.error(`${err.statusCode} - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
        res.status(err.statusCode).json({
            status: 'error',
            message: err.message,
            ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
        });
        return;
    }
    // Handle Prisma errors
    if (err.name === 'PrismaClientKnownRequestError') {
        logger_1.default.error(`Database error: ${err.message}`);
        res.status(400).json({
            status: 'error',
            message: 'Database operation failed'
        });
        return;
    }
    // Handle JWT errors
    if (err.name === 'JsonWebTokenError') {
        res.status(401).json({
            status: 'error',
            message: 'Invalid token'
        });
        return;
    }
    if (err.name === 'TokenExpiredError') {
        res.status(401).json({
            status: 'error',
            message: 'Token expired'
        });
        return;
    }
    // Default error
    logger_1.default.error(`500 - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
    res.status(500).json({
        status: 'error',
        message: 'Internal server error',
        ...(process.env.NODE_ENV === 'development' && { error: err.message, stack: err.stack })
    });
};
exports.errorHandler = errorHandler;
