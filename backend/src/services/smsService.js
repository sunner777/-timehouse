const config = require('../config');
const { redis } = require('../config/redis');

/**
 * SMS 验证码服务（阿里云短信认证服务）
 *
 * 使用阿里云 SDK 调用两个专用 API：
 *   RequiredPhoneCode  — 平台生成验证码并发送短信
 *   ValidPhoneCode     — 平台核验用户输入的验证码
 *
 * 签名和模板在阿里云账户级别配置，不需要每次请求传递。
 * Redis 仅用于发送频率限制（60s 同号码一次）。
 */
class SmsService {

  static _getClient() {
    const Dysmsapi = require('@alicloud/dysmsapi20170525');
    return new Dysmsapi.default({
      accessKeyId: config.sms.accessKeyId,
      accessKeySecret: config.sms.accessKeySecret,
      endpoint: 'dysmsapi.aliyuncs.com',
    });
  }

  static _validatePhone(phone) {
    if (!phone || !/^1\d{10}$/.test(phone)) {
      throw { code: 9002, message: '手机号格式不正确' };
    }
  }

  /**
   * 发送验证码 — RequiredPhoneCode
   */
  static async sendCode(phone) {
    this._validatePhone(phone);

    const rateKey = `sms_rate:${phone}`;
    if (await redis.exists(rateKey)) {
      throw { code: 9007, message: '发送过于频繁，请60秒后再试' };
    }

    const accessKeyId = config.sms.accessKeyId;
    const accessKeySecret = config.sms.accessKeySecret;
    if (!accessKeyId || !accessKeySecret) {
      console.warn(`[SMS DEV] RequiredPhoneCode skipped (not configured)`);
      await redis.set(rateKey, '1', 'EX', 60);
      return;
    }

    const Dysmsapi = require('@alicloud/dysmsapi20170525');
    const client = this._getClient();
    const req = new Dysmsapi.RequiredPhoneCodeRequest({ phoneNo: phone });

    try {
      const response = await client.requiredPhoneCode(req);
      if (response.body.code !== 'OK') {
        throw new Error(`${response.body.code} - ${response.body.message}`);
      }
    } catch (err) {
      console.error('[SMS] RequiredPhoneCode failed:', err.message);
      throw { code: 1008, message: '短信发送失败，请稍后再试' };
    }

    await redis.set(rateKey, '1', 'EX', 60);
    console.log(`[SMS] code sent to ${phone.slice(0, 3)}****${phone.slice(-4)}`);
  }

  /**
   * 核验验证码 — ValidPhoneCode
   */
  static async verifyCode(phone, code) {
    this._validatePhone(phone);

    if (!code || !/^\d{4,6}$/.test(code)) {
      throw { code: 9002, message: '验证码格式不正确' };
    }

    const accessKeyId = config.sms.accessKeyId;
    const accessKeySecret = config.sms.accessKeySecret;
    if (!accessKeyId || !accessKeySecret) {
      console.warn(`[SMS DEV] ValidPhoneCode skipped (not configured)`);
      return true;
    }

    const Dysmsapi = require('@alicloud/dysmsapi20170525');
    const client = this._getClient();
    const req = new Dysmsapi.ValidPhoneCodeRequest({
      phoneNo: phone,
      certifyCode: code,
    });

    try {
      const response = await client.validPhoneCode(req);
      console.log('[SMS] ValidPhoneCode response:', JSON.stringify(response.body));
      // code=OK 且 data=true 表示验证通过
      if (response.body.code === 'OK' && response.body.data === true) {
        return true;
      }
      // code=OK 但 data=false 表示验证码不匹配
      if (response.body.code === 'OK' && response.body.data === false) {
        throw new Error('MISMATCH');
      }
      throw new Error(`${response.body.code} - ${response.body.message}`);
    } catch (err) {
      console.error('[SMS] ValidPhoneCode error:', err.message, '| body:', JSON.stringify(err.body || err.data || {}));
      const msg = (err.message || '').toUpperCase();
      if (msg.includes('NOT_EXIST') || msg.includes('NOTFOUND')) {
        throw { code: 1007, message: '请先发送验证码' };
      }
      if (msg.includes('EXPIRED') || msg.includes('TIMEOUT')) {
        throw { code: 1006, message: '验证码已过期，请重新发送' };
      }
      if (msg.includes('MISMATCH') || msg.includes('ERROR') || msg.includes('FALSE')) {
        throw { code: 1006, message: '验证码错误' };
      }
      if (msg.includes('LIMIT') || msg.includes('EXCEED')) {
        throw { code: 9007, message: '验证次数过多，请稍后再试' };
      }
      throw { code: 1006, message: '验证码错误' };
    }
  }
}

module.exports = SmsService;
