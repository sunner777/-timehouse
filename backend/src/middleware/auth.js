const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const config = require('../config');
const response = require('../utils/response');

// lazy-load redis to avoid circular dependency at startup
let _redis = null;
const getRedis = () => {
  if (!_redis) {
    try {
      _redis = require('../config/redis').redis;
    } catch (e) {
      _redis = { get: () => null, set: () => {} };
    }
  }
  return _redis;
};

const tokenFingerprint = (token) =>
  crypto.createHash('sha256').update(token).digest('hex').slice(0, 16);

/**
 * 认证中间件
 * 1. 验证 JWT 签名和有效期
 * 2. 检查 Redis 黑名单（支持 token 吊销）
 */
const authMiddleware = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return response.unauthorized(res, '缺少认证token');
  }

  const token = authHeader.substring(7);

  try {
    const decoded = jwt.verify(token, config.jwt.secret);

    // 检查 Redis 黑名单
    try {
      const redis = getRedis();
      const fp = tokenFingerprint(token);
      const blacklisted = await redis.get(`jwt_bl:${fp}`);
      if (blacklisted) {
        return response.unauthorized(res, 'token已失效，请重新登录');
      }
    } catch (redisErr) {
      // Redis 不可用时放行（降级，不阻断正常请求）
      console.warn('[Auth] Redis blacklist check failed:', redisErr.message);
    }

    req.user = {
      id: decoded.userId,
      phone: decoded.phone,
    };
    req._tokenFingerprint = tokenFingerprint(token);
    req._tokenExp = decoded.exp;

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return response.unauthorized(res, 'token已过期');
    } else if (error.name === 'JsonWebTokenError') {
      return response.unauthorized(res, '无效的token');
    }
    return response.serverError(res, '认证失败');
  }
};

module.exports = authMiddleware;
