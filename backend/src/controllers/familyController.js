const FamilyService = require('../services/familyService');
const response = require('../utils/response');

class FamilyController {
  /**
   * 创建家庭组
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async createFamily(req, res, next) {
    try {
      const { name } = req.body;
      const { id: userId } = req.user;

      const result = await FamilyService.createFamily(userId, name);
      response.success(res, result, '创建成功');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 获取家庭组列表
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async getFamilyList(req, res, next) {
    try {
      const { id: userId } = req.user;
      const families = await FamilyService.getFamilyList(userId);
      response.success(res, { families }, '获取成功');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 获取家庭组详情
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async getFamilyDetail(req, res, next) {
    try {
      const { familyId } = req.params;
      const { id: userId } = req.user;
      const family = await FamilyService.getFamilyDetail(familyId, userId);
      response.success(res, family, '获取成功');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 添加成员
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async addMember(req, res, next) {
    try {
      const { familyId } = req.params;
      const { phone, role = 'member' } = req.body;
      const { id: userId } = req.user;
      const result = await FamilyService.addMemberByPhone(familyId, userId, phone, role);
      response.success(res, result, '添加成功');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 更新成员权限
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async updateMemberPermission(req, res, next) {
    try {
      const { familyId, userId: targetUserId } = req.params;
      const { role, permissions } = req.body;
      const { id: userId } = req.user;
      await FamilyService.updateMemberPermission(familyId, userId, targetUserId, role, permissions);
      response.success(res, null, '更新成功');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 移除成员
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async removeMember(req, res, next) {
    try {
      const { familyId, userId: targetUserId } = req.params;
      const { id: userId } = req.user;
      await FamilyService.removeMember(familyId, userId, targetUserId);
      response.success(res, null, '移除成功');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 退出家庭组
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async leaveFamily(req, res, next) {
    try {
      const { familyId } = req.params;
      const { id: userId } = req.user;
      await FamilyService.leaveFamily(familyId, userId);
      response.success(res, null, '退出成功');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = FamilyController;
