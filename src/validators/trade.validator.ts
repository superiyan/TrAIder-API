import Joi from 'joi';

export const tradeValidation = {
  createOrder: Joi.object({
    symbol: Joi.string().required(),
    type: Joi.string().valid('MARKET', 'LIMIT', 'STOP_LOSS', 'TAKE_PROFIT').required(),
    side: Joi.string().valid('BUY', 'SELL').required(),
    quantity: Joi.number().positive().required(),
    price: Joi.number().positive().when('type', {
      is: Joi.string().valid('LIMIT', 'STOP_LOSS', 'TAKE_PROFIT'),
      then: Joi.required(),
      otherwise: Joi.optional()
    })
  })
};
