"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.tradeValidation = void 0;
const joi_1 = __importDefault(require("joi"));
exports.tradeValidation = {
    createOrder: joi_1.default.object({
        symbol: joi_1.default.string().required(),
        type: joi_1.default.string().valid('MARKET', 'LIMIT', 'STOP_LOSS', 'TAKE_PROFIT').required(),
        side: joi_1.default.string().valid('BUY', 'SELL').required(),
        quantity: joi_1.default.number().positive().required(),
        price: joi_1.default.number().positive().when('type', {
            is: joi_1.default.string().valid('LIMIT', 'STOP_LOSS', 'TAKE_PROFIT'),
            then: joi_1.default.required(),
            otherwise: joi_1.default.optional()
        })
    })
};
