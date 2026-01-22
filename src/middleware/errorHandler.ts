import { Request, Response, NextFunction } from 'express';
import { AppError } from '../utils/appError';
import logger from '../utils/logger';

export const errorHandler = (
  err: Error | AppError,
  req: Request,
  res: Response,
  _next: NextFunction
): void => {
  if (err instanceof AppError) {
    logger.error(`${err.statusCode} - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
    
    res.status(err.statusCode).json({
      status: 'error',
      message: err.message,
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
    return;
  }

  // Handle Prisma errors
  if (err.name === 'PrismaClientKnownRequestError') {
    logger.error(`Database error: ${err.message}`);
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
  logger.error(`500 - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
  
  res.status(500).json({
    status: 'error',
    message: 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { error: err.message, stack: err.stack })
  });
};
