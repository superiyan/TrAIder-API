import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { errorHandler } from './middleware/errorHandler';
import { notFoundHandler } from './middleware/notFoundHandler';
import { rateLimiter } from './middleware/rateLimiter';
import logger from './utils/logger';
import routes from './routes';

// Load environment variables
dotenv.config();

const app: Application = express();
const PORT = parseInt(process.env.PORT || '3000', 10);

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || '*',
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
app.use(`/api/${process.env.API_VERSION || 'v1'}`, routes);

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

// Start server  
const server = app.listen(PORT, '0.0.0.0', () => {
  logger.info(`🚀 Server running on http://0.0.0.0:${PORT} in ${process.env.NODE_ENV} mode`);
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
