const Family = require('../models/mysql/Family');
const FamilyMember = require('../models/mysql/FamilyMember');
const User = require('../models/mysql/User');
const CodeGenerator = require('../utils/codeGenerator');
const auditLog = require('../utils/auditLog');

class FamilyService {
  /**
   * 创建家庭组
   * @param {number} userId - 创建者用户ID
   * @param {string} name - 家庭组名称
   * @returns {Promise<Object>} 创建结果
   */
  static async createFamily(userId, name) {
    // 验证参数
    if (!name || name.length < 2 || name.length > 20) {
      throw { code: 9001, message: '组名需在2-20字之间' };
    }
    
    // 生成唯一邀请码
    let inviteCode;
    let existingFamily;
    let retryCount = 0;
    const maxRetries = 10;
    
    do {
      inviteCode = CodeGenerator.generateInviteCode();
      existingFamily = await Family.findByInviteCode(inviteCode);
      retryCount++;
    } while (existingFamily && retryCount < maxRetries);
    
    if (existingFamily) {
      throw { code: 9007, message: '生成邀请码失败，请重试' };
    }
    
    // 创建家庭组
    const family = await Family.create({
      name,
      ownerId: userId,
      inviteCode
    });
    
    // 将创建者添加为owner成员
    await FamilyMember.add({
      familyId: family.id,
      userId,
      role: 'owner',
      permissions: CodeGenerator.getDefaultPermissions('owner')
    });
    
    return {
      familyId: family.id,
      name: family.name,
      inviteCode: family.inviteCode
    };
  }
  
  /**
   * 获取用户的家庭组列表
   * @param {number} userId - 用户ID
   * @returns {Promise<Array>} 家庭组列表
   */
  static async getFamilyList(userId) {
    const families = await Family.findByUserId(userId);
    
    // 为每个家庭组添加成员数量信息
    const familiesWithCount = await Promise.all(families.map(async (family) => {
      const memberCount = await FamilyMember.countByFamilyId(family.id);
      return {
        id: family.id,
        name: family.name,
        role: family.role,
        memberCount,
        photoCount: family.photo_count ?? 0,
        createdAt: family.created_at
      };
    }));
    
    return familiesWithCount;
  }
  
  /**
   * 获取家庭组详情
   * @param {number} familyId - 家庭组ID
   * @param {number} userId - 当前用户ID
   * @returns {Promise<Object>} 家庭组详情
   */
  static async getFamilyDetail(familyId, userId) {
    // 检查用户是否为成员
    const isMember = await FamilyMember.isMember(familyId, userId);
    if (!isMember) {
      throw { code: 9004, message: '无权限访问此家庭组' };
    }
    
    // 获取家庭组信息
    const family = await Family.findById(familyId);
    if (!family) {
      throw { code: 9005, message: '家庭组不存在' };
    }
    
    // 获取成员列表
    const members = await FamilyMember.findByFamilyId(familyId);
    
    // 获取用户在该家庭组的角色
    const currentMember = await FamilyMember.findByFamilyAndUser(familyId, userId);
    
    return {
      id: family.id,
      name: family.name,
      inviteCode: currentMember.role === 'owner' ? family.invite_code : null, // 只有owner能看到邀请码
      ownerId: family.owner_id,
      role: currentMember.role,
      members: members.map(member => ({
        id: member.id,
        userId: member.user_id,
        nickname: member.nickname,
        avatar: member.avatar,
        role: member.role,
        joinedAt: member.joined_at
      })),
      createdAt: family.created_at
    };
  }
  
  /**
   * 添加成员（通过手机号）
   * @param {number} familyId - 家庭组ID
   * @param {number} currentUserId - 当前用户ID
   * @param {string} phone - 手机号
   * @param {string} role - 角色
   * @returns {Promise<Object>} 添加结果
   */
  static async addMemberByPhone(familyId, currentUserId, phone, role = 'member') {
    // 检查当前用户是否有manage权限
    const currentMember = await FamilyMember.findByFamilyAndUser(familyId, currentUserId);
    if (!currentMember) {
      throw { code: 9004, message: '无权限操作此家庭组' };
    }
    
    if (currentMember.role !== 'owner' && !currentMember.permissions?.includes('manage')) {
      throw { code: 9004, message: '无权限添加成员' };
    }
    
    // 查找用户
    const user = await User.findByPhone(phone);
    if (!user) {
      throw { code: 9005, message: '该用户未注册' };
    }
    
    // 检查是否已经是成员
    const existingMember = await FamilyMember.findByFamilyAndUser(familyId, user.id);
    if (existingMember) {
      throw { code: 3002, message: '已经是该家庭组成员' };
    }
    
    // 添加成员
    await FamilyMember.add({
      familyId,
      userId: user.id,
      role,
      permissions: CodeGenerator.getDefaultPermissions(role)
    });

    auditLog('member.add', { userId: currentUserId }, { familyId, targetUserId: user.id, role });

    return {
      userId: user.id,
      nickname: user.nickname,
      role
    };
  }
  
  /**
   * 更新成员权限
   * @param {number} familyId - 家庭组ID
   * @param {number} currentUserId - 当前用户ID
   * @param {number} targetUserId - 目标用户ID
   * @param {string} role - 新角色
   * @param {Array<string>} permissions - 权限列表（可选）
   * @returns {Promise<boolean>} 更新是否成功
   */
  static async updateMemberPermission(familyId, currentUserId, targetUserId, role, permissions) {
    // 检查当前用户是否有manage权限
    const currentMember = await FamilyMember.findByFamilyAndUser(familyId, currentUserId);
    if (!currentMember) {
      throw { code: 9004, message: '无权限操作此家庭组' };
    }
    
    if (currentMember.role !== 'owner' && !currentMember.permissions?.includes('manage')) {
      throw { code: 9004, message: '无权限修改成员权限' };
    }
    
    // 检查目标成员是否存在
    const targetMember = await FamilyMember.findByFamilyAndUser(familyId, targetUserId);
    if (!targetMember) {
      throw { code: 9005, message: '成员不存在' };
    }
    
    // 不能修改owner的权限
    if (targetMember.role === 'owner') {
      throw { code: 9004, message: '不能修改创建者权限' };
    }
    
    // 更新权限
    const updateData = {
      role: role || targetMember.role,
      permissions: permissions || CodeGenerator.getDefaultPermissions(role || targetMember.role)
    };
    
    const success = await FamilyMember.update(familyId, targetUserId, updateData);
    if (!success) {
      throw { code: 9007, message: '更新权限失败' };
    }

    auditLog('member.permissionChange', { userId: currentUserId }, { familyId, targetUserId, newRole: updateData.role });

    return true;
  }
  
  /**
   * 移除成员
   * @param {number} familyId - 家庭组ID
   * @param {number} currentUserId - 当前用户ID
   * @param {number} targetUserId - 目标用户ID
   * @returns {Promise<boolean>} 移除是否成功
   */
  static async removeMember(familyId, currentUserId, targetUserId) {
    // 检查当前用户是否有manage权限
    const currentMember = await FamilyMember.findByFamilyAndUser(familyId, currentUserId);
    if (!currentMember) {
      throw { code: 9004, message: '无权限操作此家庭组' };
    }
    
    // 检查是否是移除自己
    if (currentUserId === targetUserId) {
      throw { code: 9004, message: '请使用退出家庭组功能' };
    }
    
    if (currentMember.role !== 'owner' && !currentMember.permissions?.includes('manage')) {
      throw { code: 9004, message: '无权限移除成员' };
    }
    
    // 检查目标成员是否存在
    const targetMember = await FamilyMember.findByFamilyAndUser(familyId, targetUserId);
    if (!targetMember) {
      throw { code: 9005, message: '成员不存在' };
    }
    
    // 不能移除owner
    if (targetMember.role === 'owner') {
      throw { code: 9004, message: '不能移除创建者' };
    }
    
    // 移除成员
    const success = await FamilyMember.remove(familyId, targetUserId);
    if (!success) {
      throw { code: 9007, message: '移除成员失败' };
    }

    auditLog('member.remove', { userId: currentUserId }, { familyId, targetUserId });

    return true;
  }
  
  /**
   * 退出家庭组
   * @param {number} familyId - 家庭组ID
   * @param {number} userId - 用户ID
   * @returns {Promise<boolean>} 退出是否成功
   */
  static async leaveFamily(familyId, userId) {
    // 检查是否为成员
    const member = await FamilyMember.findByFamilyAndUser(familyId, userId);
    if (!member) {
      throw { code: 9004, message: '不是该家庭组成员' };
    }
    
    // 检查是否为owner
    if (member.role === 'owner') {
      throw { code: 9004, message: '创建者不能退出，请删除家庭组' };
    }
    
    // 退出家庭组
    const success = await FamilyMember.remove(familyId, userId);
    if (!success) {
      throw { code: 9007, message: '退出失败' };
    }
    
    return true;
  }
}

module.exports = FamilyService;
