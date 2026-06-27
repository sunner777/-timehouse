const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const config = require('./config');
const { mysqlPool, testMySQLConnection } = require('./config/database');
const routes = require('./routes');
const errorHandler = require('./middleware/errorHandler');
const rateLimiter = require('./middleware/rateLimiter');

// 创建Express应用
const app = express();

// 信任 Nginx 反代的 X-Forwarded-For 头（rate limiter 依赖此配置）
app.set('trust proxy', 1);

// 请求日志中间件 — 环境感知，绝不记录请求体或 Authorization 头
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    if (config.app.env === 'production') {
      console.log(JSON.stringify({
        timestamp: new Date().toISOString(),
        method: req.method,
        url: req.originalUrl,
        status: res.statusCode,
        duration_ms: duration,
        ip: req.ip
      }));
    } else {
      console.log(`${new Date().toISOString()} ${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`);
    }
  });
  next();
});

// 安全头（Nginx 已设基础头，此处纵深防御）
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' }, // 允许前端跨域加载图片
  contentSecurityPolicy: false, // Nginx 层统一管理 CSP
}));

// 配置中间件
app.use(cors({
  origin: config.cors.origin
}));
app.use(express.json({ limit: '10mb' }));
// 本服务仅处理 JSON API，关闭 extended querystring 解析减少攻击面
app.use(express.urlencoded({ extended: false, limit: '1mb' }));

// 应用速率限制
app.use(rateLimiter);

// 注册路由
app.use('/api/v1', routes);

// 错误处理中间件
app.use(errorHandler);

// 404处理
app.use((req, res) => {
  res.status(404).json({
    code: 9005,
    message: '接口不存在',
    data: null
  });
});

// 启动服务器
const startServer = async () => {
  try {
    await testMySQLConnection();

    // 连接 Redis
    try {
      const { redis } = require('./config/redis');
      await redis.connect();
      console.log('Redis connected');
    } catch (redisErr) {
      console.warn('Redis connection failed (non-fatal):', redisErr.message);
    }

    app.listen(config.app.port, '127.0.0.1', () => {
      console.log(`Server running on port ${config.app.port}`);
      console.log(`Environment: ${config.app.env}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// 启动服务器
startServer();

// 优雅关闭
const gracefulShutdown = async (signal) => {
  console.log(`Received ${signal}. Shutting down gracefully...`);
  const forceExit = setTimeout(() => {
    console.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000);

  try {
    try { await mysqlPool.end(); console.log('MySQL connection closed'); } catch (e) { console.error('MySQL close error:', e); }
  } finally {
    clearTimeout(forceExit);
    process.exit(0);
  }
};

process.on('SIGINT', () => gracefulShutdown('SIGINT'));
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));