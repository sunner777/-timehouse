const express = require('express');
const router = express.Router();
const AuthController = require('../controllers/authController');
const authMiddleware = require('../middleware/auth');

// 注册 [DEPRECATED] — 已废弃，仅保留兼容
router.post('/register', AuthController.register);

// 密码登录 [DEPRECATED] — 已废弃，仅保留兼容
router.post('/login', AuthController.login);

// 发送短信验证码
router.post('/send-code', AuthController.sendSmsCode);

// 短信验证码登录
router.post('/sms-login', AuthController.smsLogin);

// 修改密码（需认证）
router.put('/password', authMiddleware, AuthController.changePassword);

// 登出（需认证，加入黑名单）
router.post('/logout', authMiddleware, AuthController.logout);

// 获取用户信息（需认证）
router.get('/profile', authMiddleware, AuthController.getUserInfo);

// 更新用户资料（需认证）
router.put('/profile', authMiddleware, AuthController.updateProfile);

module.exports = router;
