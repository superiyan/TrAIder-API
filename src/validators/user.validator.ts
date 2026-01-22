import Joi from 'joi';

export const userValidation = {
  updateProfile: Joi.object({
    name: Joi.string().min(2).max(100).optional()
  }),

  changePassword: Joi.object({
    currentPassword: Joi.string().required(),
    newPassword: Joi.string().min(8).required()
  })
};
