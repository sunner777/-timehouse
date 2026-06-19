const { mysqlPool } = require('../../config/database');

class Family {
  /**
   * 创建家庭组
   * @param {Object} familyData - 家庭组数据
   * @returns {Promise<Object>} 创建的家庭组
   */
  static async create(familyData) {
    const { name, ownerId, inviteCode } = familyData;
    
    const query = `
      INSERT INTO families (name, owner_id, invite_code, created_at, updated_at)
      VALUES (?, ?, ?, NOW(), NOW())
    `;
    
    const [result] = await mysqlPool.execute(query, [name, ownerId, inviteCode]);
    
    return {
      id: result.insertId,
      name,
      ownerId,
      inviteCode
    };
  }
  
  /**
   * 根据ID查找家庭组
   * @param {number} id - 家庭组ID
   * @returns {Promise<Object|null>} 家庭组信息
   */
  static async findById(id) {
    const query = 'SELECT * FROM families WHERE id = ?';
    const [rows] = await mysqlPool.execute(query, [id]);
    return rows.length > 0 ? rows[0] : null;
  }
  
  /**
   * 根据邀请码查找家庭组
   * @param {string} inviteCode - 邀请码
   * @returns {Promise<Object|null>} 家庭组信息
   */
  static async findByInviteCode(inviteCode) {
    const query = 'SELECT * FROM families WHERE invite_code = ?';
    const [rows] = await mysqlPool.execute(query, [inviteCode]);
    return rows.length > 0 ? rows[0] : null;
  }
  
  /**
   * 获取用户的所有家庭组
   * @param {number} userId - 用户ID
   * @returns {Promise<Array>} 家庭组列表
   */
  static async findByUserId(userId) {
    const query = `
      SELECT f.*, fm.role, fm.joined_at,
             COALESCE(p.photo_count, 0) as photo_count
      FROM families f
      INNER JOIN family_members fm ON f.id = fm.family_id
      LEFT JOIN (
        SELECT family_id, COUNT(*) as photo_count
        FROM photos
        WHERE family_id IS NOT NULL
        GROUP BY family_id
      ) p ON f.id = p.family_id
      WHERE fm.user_id = ?
      ORDER BY photo_count DESC, fm.joined_at DESC
    `;
    const [rows] = await mysqlPool.execute(query, [userId]);
    return rows;
  }
  
  /**
   * 更新家庭组信息
   * @param {number} id - 家庭组ID
   * @param {Object} familyData - 家庭组数据
   * @returns {Promise<boolean>} 更新是否成功
   */
  static async update(id, familyData) {
    const { name } = familyData;
    const query = 'UPDATE families SET name = ?, updated_at = NOW() WHERE id = ?';
    const [result] = await mysqlPool.execute(query, [name, id]);
    return result.affectedRows > 0;
  }
  
  /**
   * 更新邀请码
   * @param {number} id - 家庭组ID
   * @param {string} newInviteCode - 新邀请码
   * @returns {Promise<boolean>} 更新是否成功
   */
  static async updateInviteCode(id, newInviteCode) {
    const query = 'UPDATE families SET invite_code = ?, updated_at = NOW() WHERE id = ?';
    const [result] = await mysqlPool.execute(query, [newInviteCode, id]);
    return result.affectedRows > 0;
  }
  
  /**
   * 删除家庭组
   * @param {number} id - 家庭组ID
   * @returns {Promise<boolean>} 删除是否成功
   */
  static async delete(id) {
    const query = 'DELETE FROM families WHERE id = ?';
    const [result] = await mysqlPool.execute(query, [id]);
    return result.affectedRows > 0;
  }
}

module.exports = Family;
