"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authValidation = void 0;
const joi_1 = __importDefault(require("joi"));
exports.authValidation = {
    register: joi_1.default.object({
        email: joi_1.default.string().email().required(),
        password: joi_1.default.string().min(8).required(),
        name: joi_1.default.string().min(2).max(100).required()
    }),
    login: joi_1.default.object({
        email: joi_1.default.string().email().required(),
        password: joi_1.default.string().required()
    }),
    refresh: joi_1.default.object({
        refreshToken: joi_1.default.string().required()
    })
};
