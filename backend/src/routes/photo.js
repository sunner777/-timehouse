const express = require('express');
const router = express.Router();
const PhotoController = require('../controllers/photoController');
const authMiddleware = require('../middleware/auth');
const { validateBody, validateQuery } = require('../middleware/validate');
const { photos: schemas } = require('../validators/schemas');

// 上传照片路由（需要认证）
router.post('/upload', authMiddleware, validateBody(schemas.upload), PhotoController.uploadPhoto);

// 获取照片列表路由（需要认证）
router.get('/', authMiddleware, validateQuery(schemas.listQuery), PhotoController.getPhotos);

// 获取照片详情路由（需要认证）
router.get('/:id', authMiddleware, PhotoController.getPhotoDetail);

// 更新照片信息路由（需要认证）
router.put('/:id', authMiddleware, validateBody(schemas.update), PhotoController.updatePhoto);

// 删除照片路由（需要认证）
router.delete('/:id', authMiddleware, PhotoController.deletePhoto);

// 批量删除照片路由（需要认证）
router.post('/batch-delete', authMiddleware, validateBody(schemas.batchDelete), PhotoController.deletePhotos);

// 获取TOS上传签名路由（需要认证）
router.post('/tos-upload-signature', authMiddleware, validateBody(schemas.tosSignature), PhotoController.getTosUploadSignature);

// 检查照片哈希重复路由（需要认证）
router.post('/check-duplicates', authMiddleware, validateBody(schemas.checkDuplicates), PhotoController.checkDuplicates);

// 更新照片的家庭组归属路由（需要认证）
router.put('/:id/family', authMiddleware, validateBody(schemas.updateFamily), PhotoController.updatePhotoFamily);

module.exports = router;