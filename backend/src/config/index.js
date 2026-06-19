const dotenv = require('dotenv');
const path = require('path');

// 按环境加载对应的 env 文件，.env 作为 fallback
const envFile = process.env.NODE_ENV === 'production' ? '.env.production' : '.env';
dotenv.config({ path: path.resolve(__dirname, '..', '..', envFile) });
// 同时加载 .env 作为 fallback（补充缺失的变量）
dotenv.config({ path: path.resolve(__dirname, '..', '..', '.env'), override: false });

const config = {
  // 应用配置
  app: {
    env: process.env.NODE_ENV || 'development',
    port: process.env.PORT || 3000,
    logLevel: process.env.LOG_LEVEL || 'info'
  },
  
  // MySQL配置
  mysql: {
    host: process.env.MYSQL_HOST || 'localhost',
    port: process.env.MYSQL_PORT || 3306,
    user: process.env.MYSQL_USER || 'root',
    password: process.env.MYSQL_PASSWORD || 'password',
    database: process.env.MYSQL_DATABASE || 'timehouse',
    connectionLimit: 10
  },
  
  // MongoDB配置
  mongodb: {
    uri: process.env.MONGODB_URI || 'mongodb://localhost:27017/timehouse'
  },
  
  // Redis配置
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || '',
    db: 0
  },
  
  // JWT配置
  jwt: {
    secret: process.env.JWT_SECRET || 'your-secret-key',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d'
  },
  
  // CORS配置
  cors: {
    origin: process.env.CORS_ORIGIN || '*'
  },
  
  // 速率限制配置
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW) || 900000, // 15分钟
    max: parseInt(process.env.RATE_LIMIT_MAX) || 100 // 每个IP限制100个请求
  },
  
  // 阿里云 SMS 短信认证服务（RequiredPhoneCode / ValidPhoneCode）
  // 签名和模板在阿里云账户级别配置，无需每次请求传递
  sms: {
    accessKeyId: process.env.SMS_ACCESS_KEY_ID || '',
    accessKeySecret: process.env.SMS_ACCESS_KEY_SECRET || '',
  },

  // Volcengine TOS配置
  tos: {
    accessKeyId: process.env.TOS_ACCESS_KEY_ID,
    accessKeySecret: process.env.TOS_ACCESS_KEY_SECRET,
    region: process.env.TOS_REGION || 'cn-shanghai',
    endpoint: process.env.TOS_ENDPOINT || 'tos-cn-shanghai.volces.com',
    bucket: process.env.TOS_BUCKET || 'timehouse-photos-cn-shanghai'
  }
};

module.exports = config;