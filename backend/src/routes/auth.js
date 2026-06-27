const express = require('express');
const router = express.Router();
const AuthController = require('../controllers/authController');
const authMiddleware = require('../middleware/auth');
const { validateBody } = require('../middleware/validate');
const { auth: schemas } = require('../validators/schemas');

// 注册 [DEPRECATED] — 已废弃，仅保留兼容
router.post('/register', validateBody(schemas.register), AuthController.register);

// 密码登录 [DEPRECATED] — 已废弃，仅保留兼容
router.post('/login', validateBody(schemas.login), AuthController.login);

// 发送短信验证码
router.post('/send-code', validateBody(schemas.sendCode), AuthController.sendSmsCode);

// 短信验证码登录
router.post('/sms-login', validateBody(schemas.smsLogin), AuthController.smsLogin);

// 修改密码（需认证）
router.put('/password', authMiddleware, validateBody(schemas.changePassword), AuthController.changePassword);

// 登出（需认证，加入黑名单）
router.post('/logout', authMiddleware, AuthController.logout);

// 获取用户信息（需认证）
router.get('/profile', authMiddleware, AuthController.getUserInfo);

// 更新用户资料（需认证）
router.put('/profile', authMiddleware, validateBody(schemas.updateProfile), AuthController.updateProfile);

module.exports = router;
