const User = require('../models/mysql/User');
const jwt = require('jsonwebtoken');
const config = require('../config');
const SmsService = require('./smsService');

class AuthService {
  /**
   * 用户注册
   * @param {Object} userData - 用户数据
   * @returns {Promise<Object>} 注册结果
   */
  static async register(userData) {
    const { phone, password, nickname } = userData;

    // 检查手机号是否已注册
    const existingUser = await User.findByPhone(phone);
    if (existingUser) {
      throw { code: 1001, message: '手机号已注册' };
    }

    // 验证密码格式
    if (!password || password.length < 6 || password.length > 20) {
      throw { code: 1002, message: '密码长度需6-20位' };
    }

    // 创建用户
    const user = await User.create({
      phone,
      password,
      nickname,
      phone_verified: 0,
    });

    // 生成token
    const token = this.generateToken(user.id, user.phone);

    return {
      userId: user.id,
      token
    };
  }

  /**
   * 用户登录
   * @param {string} phone - 手机号
   * @param {string} password - 密码
   * @returns {Promise<Object>} 登录结果
   */
  static async login(phone, password) {
    // 查找用户
    const user = await User.findByPhone(phone);
    if (!user) {
      throw { code: 1004, message: '手机号或密码错误' };
    }

    // 验证密码
    const isPasswordValid = await User.verifyPassword(password, user.password);
    if (!isPasswordValid) {
      throw { code: 1004, message: '手机号或密码错误' };
    }

    // 生成token
    const token = this.generateToken(user.id, user.phone);

    return {
      userId: user.id,
      phone: user.phone,
      nickname: user.nickname,
      avatar: user.avatar,
      token
    };
  }

  /**
   * 发送短信验证码
   * @param {string} phone - 手机号
   */
  static async sendSmsCode(phone) {
    await SmsService.sendCode(phone);
    return { phone };
  }

  /**
   * 短信验证码登录（新用户自动注册）
   * @param {string} phone - 手机号
   * @param {string} code - 验证码
   * @returns {Promise<Object>} 登录结果
   */
  static async smsLogin(phone, code) {
    // 验证验证码
    await SmsService.verifyCode(phone, code);

    // 查找或创建用户
    let user = await User.findByPhone(phone);
    if (!user) {
      // 新用户自动注册（空密码，phone_verified = 1）
      user = await User.create({
        phone,
        password: '', // 空密码（仅SMS登录用户）
        phone_verified: 1,
      });
    }

    // 生成token
    const token = this.generateToken(user.id, user.phone);

    return {
      userId: user.id,
      phone: user.phone,
      nickname: user.nickname || '',
      avatar: user.avatar || '',
      token
    };
  }

  /**
   * 修改密码
   * @param {number} userId - 用户ID
   * @param {string} oldPassword - 旧密码
   * @param {string} newPassword - 新密码
   * @returns {Promise<boolean>} 修改是否成功
   */
  static async changePassword(userId, oldPassword, newPassword) {
    // 查找用户
    const user = await User.findById(userId);
    if (!user) {
      throw { code: 9005, message: '用户不存在' };
    }

    // 验证旧密码
    const isPasswordValid = await User.verifyPassword(oldPassword, user.password);
    if (!isPasswordValid) {
      throw { code: 1005, message: '旧密码错误' };
    }

    // 验证新密码格式
    if (!newPassword || newPassword.length < 6 || newPassword.length > 20) {
      throw { code: 1002, message: '新密码长度需6-20位' };
    }

    // 更新密码
    const success = await User.updatePassword(userId, newPassword);
    if (!success) {
      throw { code: 9007, message: '密码修改失败' };
    }

    return true;
  }

  /**
   * 更新用户资料（昵称/头像）
   * @param {number} userId - 用户ID
   * @param {Object} profileData - { nickname, avatar }
   * @returns {Promise<Object>} 更新后的信息
   */
  static async updateProfile(userId, { nickname, avatar }) {
    if (nickname === undefined && avatar === undefined) {
      throw { code: 9001, message: '至少需要提供昵称或头像' };
    }
    await User.update(userId, { nickname, avatar });
    return { nickname, avatar };
  }

  /**
   * 生成JWT token
   * @param {number} userId - 用户ID
   * @param {string} phone - 手机号
   * @returns {string} token
   */
  static generateToken(userId, phone) {
    const payload = {
      userId,
      phone,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + parseInt(config.jwt.expiresIn) * 24 * 3600
    };

    return jwt.sign(payload, config.jwt.secret);
  }

  /**
   * 获取用户信息
   * @param {number} userId - 用户ID
   * @returns {Promise<Object>} 用户信息
   */
  static async getUserInfo(userId) {
    const user = await User.findById(userId);
    if (!user) {
      throw { code: 9005, message: '用户不存在' };
    }
    return user;
  }
}

module.exports = AuthService;
