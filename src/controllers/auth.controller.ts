import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { AuthService } from '../services/auth.service';
import { AppError } from '../utils/appError';

const authService = new AuthService();

export class AuthController {
  async register(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { email, password, name } = req.body;
      
      const result = await authService.register({ email, password, name });

      res.status(201).json({
        status: 'success',
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  async login(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { email, password } = req.body;
      
      const result = await authService.login(email, password);

      res.json({
        status: 'success',
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  async refreshToken(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      const { refreshToken } = req.body;
      
      const result = await authService.refreshToken(refreshToken);

      res.json({
        status: 'success',
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  async logout(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      // Add token to blacklist or remove refresh token
      res.json({
        status: 'success',
        message: 'Logged out successfully'
      });
    } catch (error) {
      next(error);
    }
  }

  async getCurrentUser(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) {
        throw new AppError('User not found', 404);
      }

      const user = await authService.getUserById(req.user.id);

      res.json({
        status: 'success',
        data: { user }
      });
    } catch (error) {
      next(error);
    }
  }
}
