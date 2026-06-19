/**
 * 统一API响应格式
 */

// 成功响应
const success = (res, data = null, message = '操作成功') => {
  return res.status(200).json({
    code: 0,
    message,
    data
  });
};

// 错误响应
const error = (res, code, message, statusCode = 400) => {
  return res.status(statusCode).json({
    code,
    message,
    data: null
  });
};

// 未授权响应
const unauthorized = (res, message = '未授权') => {
  return res.status(401).json({
    code: 9003,
    message,
    data: null
  });
};

// 无权限响应
const forbidden = (res, message = '无权限') => {
  return res.status(403).json({
    code: 9004,
    message,
    data: null
  });
};

// 资源不存在响应
const notFound = (res, message = '资源不存在') => {
  return res.status(404).json({
    code: 9005,
    message,
    data: null
  });
};

// 服务器错误响应
const serverError = (res, message = '服务器错误') => {
  return res.status(500).json({
    code: 9008,
    message,
    data: null
  });
};

module.exports = {
  success,
  error,
  unauthorized,
  forbidden,
  notFound,
  serverError
};