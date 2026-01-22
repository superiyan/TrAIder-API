"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.userValidation = void 0;
const joi_1 = __importDefault(require("joi"));
exports.userValidation = {
    updateProfile: joi_1.default.object({
        name: joi_1.default.string().min(2).max(100).optional()
    }),
    changePassword: joi_1.default.object({
        currentPassword: joi_1.default.string().required(),
        newPassword: joi_1.default.string().min(8).required()
    })
};
