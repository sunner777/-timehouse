const rateLimit = require('express-rate-limit');
const config = require('../config');
const response = require('../utils/response');

/**
 * 速率限制中间件
 * 防止API被恶意请求
 */
const rateLimiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.max,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    code: 9007,
    message: '请求过于频繁，请稍后再试',
    data: null
  },
  handler: (req, res, options) => {
    response.error(res, 9007, '请求过于频繁，请稍后再试', 429);
  }
});

module.exports = rateLimiter;