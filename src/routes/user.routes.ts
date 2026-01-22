import { Router } from 'express';
import { UserController } from '../controllers/user.controller';
import { authenticate } from '../middleware/auth';
import { validateRequest } from '../middleware/validateRequest';
import { userValidation } from '../validators/user.validator';

const router = Router();
const userController = new UserController();

router.get('/profile', authenticate, userController.getProfile);
router.put('/profile', authenticate, validateRequest(userValidation.updateProfile), userController.updateProfile);
router.put('/password', authenticate, validateRequest(userValidation.changePassword), userController.changePassword);
router.get('/settings', authenticate, userController.getSettings);
router.put('/settings', authenticate, userController.updateSettings);

export default router;
