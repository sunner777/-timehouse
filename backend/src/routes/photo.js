const express = require('express');
const router = express.Router();
const PhotoController = require('../controllers/photoController');
const authMiddleware = require('../middleware/auth');

// 上传照片路由（需要认证）
router.post('/upload', authMiddleware, PhotoController.uploadPhoto);

// 获取照片列表路由（需要认证）
router.get('/', authMiddleware, PhotoController.getPhotos);

// 获取照片详情路由（需要认证）
router.get('/:id', authMiddleware, PhotoController.getPhotoDetail);

// 更新照片信息路由（需要认证）
router.put('/:id', authMiddleware, PhotoController.updatePhoto);

// 删除照片路由（需要认证）
router.delete('/:id', authMiddleware, PhotoController.deletePhoto);

// 批量删除照片路由（需要认证）
router.post('/batch-delete', authMiddleware, PhotoController.deletePhotos);

// 获取TOS上传签名路由（需要认证）
router.post('/tos-upload-signature', authMiddleware, PhotoController.getTosUploadSignature);

// 检查照片哈希重复路由（需要认证）
router.post('/check-duplicates', authMiddleware, PhotoController.checkDuplicates);

// 更新照片的家庭组归属路由（需要认证）
router.put('/:id/family', authMiddleware, PhotoController.updatePhotoFamily);

module.exports = router;