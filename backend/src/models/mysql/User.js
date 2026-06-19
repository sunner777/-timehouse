const { mysqlPool } = require('../../config/database');
const bcrypt = require('bcrypt');

class User {
  /**
   * 创建用户
   * @param {Object} userData - 用户数据
   * @returns {Promise<Object>} 创建的用户
   */
  static async create(userData) {
    const { phone, password, nickname, avatar, phone_verified } = userData;

    // 加密密码
    const hashedPassword = await bcrypt.hash(password, 12);

    const query = `
      INSERT INTO users (phone, password, phone_verified, nickname, avatar, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, NOW(), NOW())
    `;

    const [result] = await mysqlPool.execute(query, [phone, hashedPassword, phone_verified ? 1 : 0, nickname || '', avatar || '']);

    return {
      id: result.insertId,
      phone,
      phone_verified: phone_verified ? 1 : 0,
      nickname: nickname || '',
      avatar: avatar || ''
    };
  }
  
  /**
   * 根据手机号查找用户
   * @param {string} phone - 手机号
   * @returns {Promise<Object|null>} 用户信息
   */
  static async findByPhone(phone) {
    const query = 'SELECT * FROM users WHERE phone = ?';
    const [rows] = await mysqlPool.execute(query, [phone]);
    return rows.length > 0 ? rows[0] : null;
  }
  
  /**
   * 根据ID查找用户
   * @param {number} id - 用户ID
   * @returns {Promise<Object|null>} 用户信息
   */
  static async findById(id) {
    const query = 'SELECT id, phone, phone_verified, nickname, avatar, created_at FROM users WHERE id = ?';
    const [rows] = await mysqlPool.execute(query, [id]);
    return rows.length > 0 ? rows[0] : null;
  }
  
  /**
   * 验证密码
   * @param {string} password - 明文密码
   * @param {string} hashedPassword - 加密密码
   * @returns {Promise<boolean>} 密码是否正确
   */
  static async verifyPassword(password, hashedPassword) {
    return bcrypt.compare(password, hashedPassword);
  }
  
  /**
   * 更新密码
   * @param {number} id - 用户ID
   * @param {string} newPassword - 新密码
   * @returns {Promise<boolean>} 更新是否成功
   */
  static async updatePassword(id, newPassword) {
    const hashedPassword = await bcrypt.hash(newPassword, 12);
    const query = 'UPDATE users SET password = ?, updated_at = NOW() WHERE id = ?';
    const [result] = await mysqlPool.execute(query, [hashedPassword, id]);
    return result.affectedRows > 0;
  }
  
  /**
   * 更新用户信息
   * @param {number} id - 用户ID
   * @param {Object} userData - 用户数据
   * @returns {Promise<boolean>} 更新是否成功
   */
  static async update(id, userData) {
    const { nickname, avatar } = userData;
    const query = 'UPDATE users SET nickname = ?, avatar = ?, updated_at = NOW() WHERE id = ?';
    const [result] = await mysqlPool.execute(query, [nickname, avatar, id]);
    return result.affectedRows > 0;
  }
}

module.exports = User;