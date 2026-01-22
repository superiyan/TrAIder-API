import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import path from 'path';
import { errorHandler } from './middleware/errorHandler';
import { notFoundHandler } from './middleware/notFoundHandler';
import { rateLimiter } from './middleware/rateLimiter';
import logger from './utils/logger';
import routes from './routes';
import { validateEnvironment, config } from './utils/envValidator';

// Load environment variables based on NODE_ENV
const nodeEnv = process.env.NODE_ENV || 'development';
const envFile = nodeEnv === 'production' ? '.env.production' : '.env';
dotenv.config({ path: path.resolve(process.cwd(), envFile) });

// For docker, also try default .env
if (nodeEnv === 'production' && !process.env.DATABASE_URL) {
  dotenv.config({ path: path.resolve(process.cwd(), '.env') });
}

// Validate required environment variables
try {
  validateEnvironment();
} catch (error) {
  logger.error(`❌ Configuration Error: ${error instanceof Error ? error.message : String(error)}`);
  console.error(`\n❌ FATAL: Configuration Error`);
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}

const app: Application = express();
const PORT = config.port;

// Trust proxy for Docker/Production environments
app.set('trust proxy', true);

// Security middleware
app.use(helmet());
app.use(cors({
  origin: config.corsOrigin,
  credentials: true
}));

// Request parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging
app.use(morgan('combined', { stream: { write: (message) => logger.info(message.trim()) } }));

// Rate limiting
app.use(rateLimiter);

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// API routes
app.use(`/api/${config.apiVersion}`, routes);

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

// Start server  
const server = app.listen(PORT, '0.0.0.0', () => {
  logger.info(`🚀 Server running on http://0.0.0.0:${PORT} in ${config.nodeEnv} mode`);
  console.log(`\n✅ Server is ready!`);
  console.log(`📡 Local: http://localhost:${PORT}`);
  console.log(`📡 Network: http://0.0.0.0:${PORT}`);
  console.log(`🔗 Health: http://localhost:${PORT}/health\n`);
});

// Graceful shutdown
server.on('error', (error: NodeJS.ErrnoException) => {
  if (error.code === 'EADDRINUSE') {
    logger.error(`❌ Port ${PORT} is already in use`);
    console.error(`\n❌ ERROR: Port ${PORT} is already in use!`);
    console.log(`Try: netstat -ano | findstr ":${PORT}"`);
  } else if (error.code === 'EACCES') {
    logger.error(`❌ Permission denied to bind port ${PORT}`);
    console.error(`\n❌ ERROR: Permission denied for port ${PORT}!`);
  } else {
    logger.error(`❌ Server error: ${error.message}`);
    console.error(`\n❌ ERROR: ${error.message}`);
  }
  process.exit(1);
});

process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    logger.info('HTTP server closed');
  });
});

export default app;
