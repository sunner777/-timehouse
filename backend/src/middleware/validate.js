/**
 * Joi 请求校验中间件
 *
 * 用法：
 *   const { validateBody, validateQuery, validateParams } = require('../middleware/validate');
 *   router.post('/xxx', validateBody(schema), controller.handler);
 *
 * 校验失败时返回 9002 + 第一条错误消息
 */
const response = require('../utils/response');

/**
 * @param {import('joi').ObjectSchema} schema
 * @param {'body'|'query'|'params'} source
 */
const validate = (schema, source = 'body') => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req[source], {
      abortEarly: true,      // 第一条错误即返回
      stripUnknown: true,    // 移除 schema 未定义的字段
      allowUnknown: true,    // 允许未知字段（静默剥离，兼容客户端）
    });

    if (error) {
      const msg = error.details[0].message;
      return response.error(res, 9002, `参数校验失败: ${msg}`);
    }

    req[source] = value; // 替换为清洗后的值
    next();
  };
};

const validateBody = (schema) => validate(schema, 'body');
const validateQuery = (schema) => validate(schema, 'query');
const validateParams = (schema) => validate(schema, 'params');

module.exports = { validate, validateBody, validateQuery, validateParams };
