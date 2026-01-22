"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const morgan_1 = __importDefault(require("morgan"));
const dotenv_1 = __importDefault(require("dotenv"));
const path_1 = __importDefault(require("path"));
const errorHandler_1 = require("./middleware/errorHandler");
const notFoundHandler_1 = require("./middleware/notFoundHandler");
const rateLimiter_1 = require("./middleware/rateLimiter");
const logger_1 = __importDefault(require("./utils/logger"));
const routes_1 = __importDefault(require("./routes"));
const envValidator_1 = require("./utils/envValidator");
// Load environment variables based on NODE_ENV
const nodeEnv = process.env.NODE_ENV || 'development';
const envFile = nodeEnv === 'production' ? '.env.production' : '.env';
dotenv_1.default.config({ path: path_1.default.resolve(process.cwd(), envFile) });
// For docker, also try default .env
if (nodeEnv === 'production' && !process.env.DATABASE_URL) {
    dotenv_1.default.config({ path: path_1.default.resolve(process.cwd(), '.env') });
}
// Validate required environment variables
try {
    (0, envValidator_1.validateEnvironment)();
}
catch (error) {
    logger_1.default.error(`❌ Configuration Error: ${error instanceof Error ? error.message : String(error)}`);
    console.error(`\n❌ FATAL: Configuration Error`);
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
}
const app = (0, express_1.default)();
const PORT = envValidator_1.config.port;
// Trust proxy for Docker/Production environments
app.set('trust proxy', true);
// Security middleware
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)({
    origin: envValidator_1.config.corsOrigin,
    credentials: true
}));
// Request parsing
app.use(express_1.default.json());
app.use(express_1.default.urlencoded({ extended: true }));
// Logging
app.use((0, morgan_1.default)('combined', { stream: { write: (message) => logger_1.default.info(message.trim()) } }));
// Rate limiting
app.use(rateLimiter_1.rateLimiter);
// Health check
app.get('/health', (_req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});
// API routes
app.use(`/api/${envValidator_1.config.apiVersion}`, routes_1.default);
// Error handling
app.use(notFoundHandler_1.notFoundHandler);
app.use(errorHandler_1.errorHandler);
// Start server  
const server = app.listen(PORT, '0.0.0.0', () => {
    logger_1.default.info(`🚀 Server running on http://0.0.0.0:${PORT} in ${envValidator_1.config.nodeEnv} mode`);
    console.log(`\n✅ Server is ready!`);
    console.log(`📡 Local: http://localhost:${PORT}`);
    console.log(`📡 Network: http://0.0.0.0:${PORT}`);
    console.log(`🔗 Health: http://localhost:${PORT}/health\n`);
});
// Graceful shutdown
server.on('error', (error) => {
    if (error.code === 'EADDRINUSE') {
        logger_1.default.error(`❌ Port ${PORT} is already in use`);
        console.error(`\n❌ ERROR: Port ${PORT} is already in use!`);
        console.log(`Try: netstat -ano | findstr ":${PORT}"`);
    }
    else if (error.code === 'EACCES') {
        logger_1.default.error(`❌ Permission denied to bind port ${PORT}`);
        console.error(`\n❌ ERROR: Permission denied for port ${PORT}!`);
    }
    else {
        logger_1.default.error(`❌ Server error: ${error.message}`);
        console.error(`\n❌ ERROR: ${error.message}`);
    }
    process.exit(1);
});
process.on('SIGTERM', () => {
    logger_1.default.info('SIGTERM signal received: closing HTTP server');
    server.close(() => {
        logger_1.default.info('HTTP server closed');
    });
});
exports.default = app;
