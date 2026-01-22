import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { UserService } from '../services/user.service';
import { AppError } from '../utils/appError';

const userService = new UserService();

export class UserController {
  async getProfile(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('User not authenticated', 401);

      const profile = await userService.getProfile(req.user.id);

      res.json({
        status: 'success',
        data: { profile }
      });
    } catch (error) {
      next(error);
    }
  }

  async updateProfile(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('User not authenticated', 401);

      const profile = await userService.updateProfile(req.user.id, req.body);

      res.json({
        status: 'success',
        data: { profile }
      });
    } catch (error) {
      next(error);
    }
  }

  async changePassword(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('User not authenticated', 401);

      const { currentPassword, newPassword } = req.body;
      await userService.changePassword(req.user.id, currentPassword, newPassword);

      res.json({
        status: 'success',
        message: 'Password changed successfully'
      });
    } catch (error) {
      next(error);
    }
  }

  async getSettings(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('User not authenticated', 401);

      const settings = await userService.getSettings(req.user.id);

      res.json({
        status: 'success',
        data: { settings }
      });
    } catch (error) {
      next(error);
    }
  }

  async updateSettings(req: AuthRequest, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new AppError('User not authenticated', 401);

      const settings = await userService.updateSettings(req.user.id, req.body);

      res.json({
        status: 'success',
        data: { settings }
      });
    } catch (error) {
      next(error);
    }
  }
}
