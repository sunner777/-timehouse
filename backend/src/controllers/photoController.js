const PhotoService = require('../services/photoService');
const tosService = require('../services/tosService');
const response = require('../utils/response');

class PhotoController {
  /**
   * 上传照片
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async uploadPhoto(req, res, next) {
    try {
      const { id: userId } = req.user;
      const { url, thumbnailUrl, fileName, size, contentType, takenAt, location, tags, familyId, hash } = req.body;

      const photo = await PhotoService.uploadPhoto(userId, {
        url,
        thumbnailUrl,
        fileName,
        size,
        contentType,
        hash,
        takenAt,
        location,
        tags,
        familyId: familyId ? parseInt(familyId) : null
      });
      
      response.success(res, photo, '上传成功');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 获取家庭组照片列表
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async getFamilyPhotos(req, res, next) {
    try {
      const { familyId } = req.params;
      const { page = 1, pageSize = 20, orderBy = 'createdAt', order = 'DESC' } = req.query;
      
      const result = await PhotoService.getFamilyPhotos(parseInt(familyId), {
        page: parseInt(page),
        pageSize: parseInt(pageSize),
        orderBy,
        order
      });
      
      response.success(res, result, '获取成功');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 更新照片的家庭组归属
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async updatePhotoFamily(req, res, next) {
    try {
      const { id: userId } = req.user;
      const { id: photoId } = req.params;
      const { familyId } = req.body;
      
      await PhotoService.updatePhotoFamily(
        parseInt(photoId),
        userId,
        familyId ? parseInt(familyId) : null
      );
      
      response.success(res, null, '更新成功');
    } catch (error) {
      next(error);
    }
  }
  
  /**
   * 获取照片列表
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async getPhotos(req, res, next) {
    try {
      const { id: userId } = req.user;
      const { page = 1, pageSize = 20, orderBy = 'createdAt', order = 'DESC' } = req.query;
      
      const result = await PhotoService.getPhotos(userId, {
        page: parseInt(page),
        pageSize: parseInt(pageSize),
        orderBy,
        order
      });
      
      response.success(res, result, '获取成功');
    } catch (error) {
      next(error);
    }
  }
  
  /**
   * 获取照片详情
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async getPhotoDetail(req, res, next) {
    try {
      const { id: userId } = req.user;
      const { id: photoId } = req.params;
      
      const photo = await PhotoService.getPhotoDetail(parseInt(photoId), userId);
      
      response.success(res, photo, '获取成功');
    } catch (error) {
      next(error);
    }
  }
  
  /**
   * 更新照片信息
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async updatePhoto(req, res, next) {
    try {
      const { id: userId } = req.user;
      const { id: photoId } = req.params;
      const { location, tags } = req.body;
      
      await PhotoService.updatePhoto(parseInt(photoId), userId, {
        location,
        tags
      });
      
      response.success(res, null, '更新成功');
    } catch (error) {
      next(error);
    }
  }
  
  /**
   * 删除照片
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async deletePhoto(req, res, next) {
    try {
      const { id: userId } = req.user;
      const { id: photoId } = req.params;
      
      await PhotoService.deletePhoto(parseInt(photoId), userId);
      
      response.success(res, null, '删除成功');
    } catch (error) {
      next(error);
    }
  }
  
  /**
   * 批量删除照片
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async deletePhotos(req, res, next) {
    try {
      const { id: userId } = req.user;
      const { photoIds } = req.body;
      
      const deletedCount = await PhotoService.deletePhotos(photoIds.map(id => parseInt(id)), userId);
      
      response.success(res, { deletedCount }, '删除成功');
    } catch (error) {
      next(error);
    }
  }
  
  /**
   * 检查照片哈希重复
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async checkDuplicates(req, res, next) {
    try {
      const { hashes } = req.body;
      const result = await PhotoService.checkDuplicates(hashes);
      response.success(res, result, '查询成功');
    } catch (error) {
      next(error);
    }
  }

  /**
   * 获取TOS上传签名
   * @param {Object} req - 请求对象
   * @param {Object} res - 响应对象
   * @param {Function} next - 下一步中间件
   */
  static async getTosUploadSignature(req, res, next) {
    try {
      const { fileName, contentType } = req.body;

      // 安全校验：只允许图片类型
      const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/heic', 'image/heif'];
      if (contentType && !ALLOWED_TYPES.includes(contentType)) {
        return response.error(res, 9002, '不支持的文件类型');
      }

      // 安全校验：文件名去路径穿越和特殊字符
      const safeName = (fileName || 'photo')
        .replace(/\.\./g, '')       // 去掉路径穿越
        .replace(/[/\\]/g, '')      // 去掉路径分隔符
        .replace(/[^a-zA-Z0-9._-]/g, '_');  // 只保留安全字符
      const objectKey = `photos/${Date.now()}_${safeName}`;

      const uploadUrl = await tosService.generateUploadUrl(objectKey);

      response.success(res, uploadUrl, '获取上传签名成功');
    } catch (error) {
      next(error);
    }
  }
}

module.exports = PhotoController;