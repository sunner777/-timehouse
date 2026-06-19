const { mysqlPool } = require('../../config/database');

class FamilyMember {
  /**
   * 添加成员
   * @param {Object} memberData - 成员数据
   * @returns {Promise<Object>} 添加的成员
   */
  static async add(memberData) {
    const { familyId, userId, role, permissions } = memberData;
    
    const query = `
      INSERT INTO family_members (family_id, user_id, role, permissions, joined_at)
      VALUES (?, ?, ?, ?, NOW())
    `;
    
    const [result] = await mysqlPool.execute(query, [
      familyId, 
      userId, 
      role, 
      permissions ? JSON.stringify(permissions) : null
    ]);
    
    return {
      id: result.insertId,
      familyId,
      userId,
      role,
      permissions
    };
  }
  
  /**
   * 根据家庭组ID和用户ID查找成员
   * @param {number} familyId - 家庭组ID
   * @param {number} userId - 用户ID
   * @returns {Promise<Object|null>} 成员信息
   */
  static async findByFamilyAndUser(familyId, userId) {
    const query = 'SELECT * FROM family_members WHERE family_id = ? AND user_id = ?';
    const [rows] = await mysqlPool.execute(query, [familyId, userId]);
    return rows.length > 0 ? rows[0] : null;
  }
  
  /**
   * 获取家庭组的所有成员
   * @param {number} familyId - 家庭组ID
   * @returns {Promise<Array>} 成员列表
   */
  static async findByFamilyId(familyId) {
    const query = `
      SELECT fm.*, u.nickname, u.avatar
      FROM family_members fm
      INNER JOIN users u ON fm.user_id = u.id
      WHERE fm.family_id = ?
      ORDER BY fm.joined_at ASC
    `;
    const [rows] = await mysqlPool.execute(query, [familyId]);
    return rows;
  }
  
  /**
   * 获取家庭组成员数量
   * @param {number} familyId - 家庭组ID
   * @returns {Promise<number>} 成员数量
   */
  static async countByFamilyId(familyId) {
    const query = 'SELECT COUNT(*) as count FROM family_members WHERE family_id = ?';
    const [rows] = await mysqlPool.execute(query, [familyId]);
    return rows[0].count;
  }
  
  /**
   * 更新成员角色和权限
   * @param {number} familyId - 家庭组ID
   * @param {number} userId - 用户ID
   * @param {Object} updateData - 更新数据
   * @returns {Promise<boolean>} 更新是否成功
   */
  static async update(familyId, userId, updateData) {
    const { role, permissions } = updateData;
    
    let query = 'UPDATE family_members SET ';
    const params = [];
    
    if (role !== undefined) {
      query += 'role = ?, ';
      params.push(role);
    }
    if (permissions !== undefined) {
      query += 'permissions = ?, ';
      params.push(permissions ? JSON.stringify(permissions) : null);
    }
    
    query += 'joined_at = NOW() WHERE family_id = ? AND user_id = ?';
    params.push(familyId, userId);
    
    const [result] = await mysqlPool.execute(query, params);
    return result.affectedRows > 0;
  }
  
  /**
   * 移除成员
   * @param {number} familyId - 家庭组ID
   * @param {number} userId - 用户ID
   * @returns {Promise<boolean>} 移除是否成功
   */
  static async remove(familyId, userId) {
    const query = 'DELETE FROM family_members WHERE family_id = ? AND user_id = ?';
    const [result] = await mysqlPool.execute(query, [familyId, userId]);
    return result.affectedRows > 0;
  }
  
  /**
   * 检查用户是否为某个家庭组的成员
   * @param {number} familyId - 家庭组ID
   * @param {number} userId - 用户ID
   * @returns {Promise<boolean>} 是否为成员
   */
  static async isMember(familyId, userId) {
    const query = 'SELECT id FROM family_members WHERE family_id = ? AND user_id = ?';
    const [rows] = await mysqlPool.execute(query, [familyId, userId]);
    return rows.length > 0;
  }
}

module.exports = FamilyMember;
