"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.prisma = void 0;
const client_1 = require("@prisma/client");
const logger_1 = __importDefault(require("../utils/logger"));
const prisma = new client_1.PrismaClient({
    log: [
        { level: 'query', emit: 'event' },
        { level: 'error', emit: 'stdout' },
        { level: 'warn', emit: 'stdout' }
    ]
});
exports.prisma = prisma;
// Log queries in development
if (process.env.NODE_ENV === 'development') {
    prisma.$on('query', (e) => {
        logger_1.default.debug(`Query: ${e.query}`);
        logger_1.default.debug(`Duration: ${e.duration}ms`);
    });
}
