/**
 * 错误处理中间件
 */
const response = require('../utils/response');

const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);
  
  // 处理Joi验证错误
  if (err.isJoi) {
    return response.error(res, 9002, err.details[0].message);
  }
  
  // 处理MongoDB错误
  if (err.name === 'MongoError') {
    if (err.code === 11000) {
      return response.error(res, 9006, '资源已存在');
    }
    return response.serverError(res, '数据库错误');
  }
  
  // 处理MySQL错误
  if (err.code && typeof err.code === 'string' && err.code.startsWith('ER_')) {
    return response.serverError(res, '数据库错误');
  }
  
  // 处理自定义错误
  if (err.code) {
    // 根据错误码确定HTTP状态码
    let statusCode = 400;
    // 认证相关错误返回401
    if (err.code === 1003 || err.code === 1004 || err.code === 1005 || err.code === 1006 || err.code === 1007) {
      statusCode = 401;
    }
    // 无权限错误返回403
    if (err.code === 9004) {
      statusCode = 403;
    }
    // 资源不存在返回404
    if (err.code === 9005) {
      statusCode = 404;
    }
    return response.error(res, err.code, err.message || '操作失败', statusCode);
  }
  
  // 处理其他错误
  return response.serverError(res, err.message || '服务器错误');
};

module.exports = errorHandler;