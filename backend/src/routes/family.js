const express = require('express');
const router = express.Router();
const FamilyController = require('../controllers/familyController');
const PhotoController = require('../controllers/photoController');
const authMiddleware = require('../middleware/auth');

// 创建家庭组（需要认证）
router.post('/', authMiddleware, FamilyController.createFamily);

// 获取家庭组列表（需要认证）
router.get('/', authMiddleware, FamilyController.getFamilyList);

// 获取家庭组详情（需要认证）
router.get('/:familyId', authMiddleware, FamilyController.getFamilyDetail);

// 获取家庭组照片（需要认证）
router.get('/:familyId/photos', authMiddleware, PhotoController.getFamilyPhotos);

// 添加成员（需要认证）
router.post('/:familyId/members', authMiddleware, FamilyController.addMember);

// 更新成员权限（需要认证）
router.put('/:familyId/members/:userId/permissions', authMiddleware, FamilyController.updateMemberPermission);

// 移除成员（需要认证）
router.delete('/:familyId/members/:userId', authMiddleware, FamilyController.removeMember);

// 退出家庭组（需要认证）
router.post('/:familyId/leave', authMiddleware, FamilyController.leaveFamily);

module.exports = router;
