"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_routes_1 = __importDefault(require("./auth.routes"));
const market_routes_1 = __importDefault(require("./market.routes"));
const trade_routes_1 = __importDefault(require("./trade.routes"));
const ai_routes_1 = __importDefault(require("./ai.routes"));
const user_routes_1 = __importDefault(require("./user.routes"));
const router = (0, express_1.Router)();
router.use('/auth', auth_routes_1.default);
router.use('/market', market_routes_1.default);
router.use('/trades', trade_routes_1.default);
router.use('/ai', ai_routes_1.default);
router.use('/users', user_routes_1.default);
exports.default = router;
