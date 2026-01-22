import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { validateRequest } from '../middleware/validateRequest';
import { authValidation } from '../validators/auth.validator';
import { authenticate } from '../middleware/auth';

const router = Router();
const authController = new AuthController();

router.post('/register', validateRequest(authValidation.register), authController.register);
router.post('/login', validateRequest(authValidation.login), authController.login);
router.post('/refresh', validateRequest(authValidation.refresh), authController.refreshToken);
router.post('/logout', authenticate, authController.logout);
router.get('/me', authenticate, authController.getCurrentUser);

export default router;
