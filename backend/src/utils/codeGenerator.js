/**
 * 邀请码生成工具
 */
class CodeGenerator {
  /**
   * 生成随机邀请码（6位大写字母+数字）
   * @returns {string} 邀请码
   */
  static generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 避免容易混淆的字符
    let code = '';
    for (let i = 0; i < 6; i++) {
      const randomIndex = Math.floor(Math.random() * chars.length);
      code += chars[randomIndex];
    }
    return code;
  }
  
  /**
   * 获取默认权限列表
   * @param {string} role - 角色
   * @returns {Array<string>} 权限列表
   */
  static getDefaultPermissions(role) {
    const permissionMap = {
      owner: ['view', 'edit', 'delete', 'manage'],
      admin: ['view', 'edit', 'delete'],
      member: ['view', 'edit'],
      guest: ['view']
    };
    return permissionMap[role] || permissionMap.member;
  }
}

module.exports = CodeGenerator;
