const AuthService = require('../services/authService');
const response = require('../utils/response');

class AuthController {
  /**
   * 用户注册
   */
  static async register(req, res, next) {
    try {
      const { phone, password, nickname } = req.body;

      if (!phone || !password) {
        return response.error(res, 9001, '参数缺失');
      }

      const result = await AuthService.register({
        phone,
        password,
        nickname
      });

      response.success(res, result, '注册成功');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 用户登录
   */
  static async login(req, res, next) {
    try {
      const { phone, password } = req.body;

      if (!phone || !password) {
        return response.error(res, 9001, '参数缺失');
      }

      const result = await AuthService.login(phone, password);

      response.success(res, result, '登录成功');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 发送短信验证码
   */
  static async sendSmsCode(req, res, next) {
    try {
      const { phone } = req.body;

      if (!phone) {
        return response.error(res, 9001, '参数缺失：缺少手机号');
      }

      await AuthService.sendSmsCode(phone);

      response.success(res, null, '验证码已发送');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 短信验证码登录
   */
  static async smsLogin(req, res, next) {
    try {
      const { phone, code } = req.body;

      if (!phone || !code) {
        return response.error(res, 9001, '参数缺失');
      }

      const result = await AuthService.smsLogin(phone, code);

      response.success(res, result, '登录成功');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 修改密码
   */
  static async changePassword(req, res, next) {
    try {
      const { oldPassword, newPassword } = req.body;
      const { id: userId } = req.user;

      if (!oldPassword || !newPassword) {
        return response.error(res, 9001, '参数缺失');
      }

      await AuthService.changePassword(userId, oldPassword, newPassword);

      response.success(res, null, '密码修改成功');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 登出 — 将当前 token 加入 Redis 黑名单
   */
  static async logout(req, res, next) {
    try {
      const fp = req._tokenFingerprint;
      const exp = req._tokenExp;
      if (fp && exp) {
        const ttl = Math.max(1, exp - Math.floor(Date.now() / 1000));
        const { redis } = require('../config/redis');
        await redis.set(`jwt_bl:${fp}`, '1', 'EX', ttl);
      }
      response.success(res, null, '已退出登录');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 更新用户资料（昵称/头像）
   */
  static async updateProfile(req, res, next) {
    try {
      const { id: userId } = req.user;
      const { nickname, avatar } = req.body;
      // 临时调试日志：记录请求体内容
      console.log('[updateProfile] userId=%d body=%s', userId, JSON.stringify(req.body));
      const result = await AuthService.updateProfile(userId, { nickname, avatar });
      console.log('[updateProfile] result=%s', JSON.stringify(result));
      response.success(res, result, '更新成功');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 获取用户信息
   */
  static async getUserInfo(req, res, next) {
    try {
      const { id: userId } = req.user;

      const userInfo = await AuthService.getUserInfo(userId);

      response.success(res, userInfo, '获取成功');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = AuthController;
