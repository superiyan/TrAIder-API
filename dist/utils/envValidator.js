"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.config = exports.validateEnvironment = void 0;
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
const requiredEnvVars = [
    'DATABASE_URL',
    'JWT_SECRET',
    'NODE_ENV',
    'PORT',
];
const validateEnvironment = () => {
    const missing = requiredEnvVars.filter((envVar) => !process.env[envVar]);
    if (missing.length > 0) {
        throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
    }
    // Validate JWT_SECRET length
    if (process.env.JWT_SECRET && process.env.JWT_SECRET.length < 32) {
        throw new Error('JWT_SECRET must be at least 32 characters long');
    }
    // Validate PORT is a number
    if (isNaN(parseInt(process.env.PORT || '', 10))) {
        throw new Error('PORT must be a valid number');
    }
    // Validate NODE_ENV
    const validEnv = ['development', 'production', 'test'];
    if (!validEnv.includes(process.env.NODE_ENV || '')) {
        throw new Error(`NODE_ENV must be one of: ${validEnv.join(', ')}`);
    }
};
exports.validateEnvironment = validateEnvironment;
exports.config = {
    nodeEnv: process.env.NODE_ENV || 'development',
    port: parseInt(process.env.PORT || '3000', 10),
    apiVersion: process.env.API_VERSION || 'v1',
    databaseUrl: process.env.DATABASE_URL,
    jwtSecret: process.env.JWT_SECRET,
    jwtExpire: process.env.JWT_EXPIRE || '7d',
    corsOrigin: process.env.CORS_ORIGIN?.split(',') || '*',
    logLevel: process.env.LOG_LEVEL || 'info',
    redisUrl: process.env.REDIS_URL,
    rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10),
    rateLimitMaxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10),
    sentryDsn: process.env.SENTRY_DSN,
    aiModelKey: process.env.OPENAI_API_KEY,
    aiModel: process.env.AI_MODEL || 'gpt-4',
};
