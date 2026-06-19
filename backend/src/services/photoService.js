const Photo = require('../models/mysql/Photo');
const FamilyMember = require('../models/mysql/FamilyMember');
const tosService = require('../services/tosService');
const auditLog = require('../utils/auditLog');

class PhotoService {
  /**
   * 上传照片
   * @param {number} userId - 用户ID
   * @param {Object} photoData - 照片数据
   * @returns {Promise<Object>} 上传的照片
   */
  static async uploadPhoto(userId, photoData) {
    const { url, thumbnailUrl, fileName, size, contentType, takenAt, location, tags, familyId, hash } = photoData;
    
    // 验证参数
    if (!url || !thumbnailUrl || !fileName || !size || !contentType) {
      throw { code: 9001, message: '参数缺失' };
    }
    
    // 创建照片记录
    const photo = await Photo.create({
      userId,
      familyId: familyId || null,
      url,
      thumbnailUrl,
      fileName,
      size,
      contentType,
      hash: hash || null,
      takenAt: takenAt || new Date(),
      location: location || '',
      tags: tags || []
    });
    
    return photo;
  }
  
  /**
   * 获取用户照片列表
   * @param {number} userId - 用户ID
   * @param {Object} options - 查询选项
   * @returns {Promise<Object>} 照片列表和总数
   */
  static async getPhotos(userId, options = {}) {
    const { page = 1, pageSize = 20, orderBy = 'createdAt', order = 'DESC' } = options;
    
    // 转换orderBy字段名
    const orderByMap = {
      createdAt: 'created_at',
      takenAt: 'taken_at'
    };
    const dbOrderBy = orderByMap[orderBy] || 'created_at';
    
    // 获取照片列表
    let photos = await Photo.findByUserId(userId, {
      page,
      pageSize,
      orderBy: dbOrderBy,
      order
    });
    
    // 为每个照片生成下载预签名URL
    photos = await Promise.all(photos.map(async (photo) => {
      try {
        const downloadResult = await tosService.generateDownloadUrl(photo.url);
        return {
          ...photo,
          url: downloadResult.downloadUrl,
          thumbnailUrl: downloadResult.downloadUrl
        };
      } catch (error) {
        console.error('生成下载URL失败:', error);
        return photo;
      }
    }));
    
    // 获取总数
    const total = await Photo.countByUserId(userId);
    
    return {
      photos,
      pagination: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize)
      }
    };
  }
  
  /**
   * 获取照片详情
   * @param {number} photoId - 照片ID
   * @param {number} userId - 用户ID
   * @returns {Promise<Object>} 照片详情
   */
  static async getPhotoDetail(photoId, userId) {
    let photo = await Photo.findById(photoId, userId);
    if (!photo) {
      // 尝试无用户过滤查找（用于共享组跨用户访问）
      photo = await Photo.findByIdOnly(photoId);
      if (!photo) {
        throw { code: 9005, message: '照片不存在' };
      }
      // 检查是否有familyId，且当前用户是否是该组成员
      if (photo.familyId) {
        const isMember = await FamilyMember.isMember(photo.familyId, userId);
        if (!isMember) {
          throw { code: 9005, message: '照片不存在' };
        }
      } else {
        throw { code: 9005, message: '照片不存在' };
      }
    }

    // 记录照片查看审计
    auditLog('photo.view', { userId }, { photoId, userId: photo.userId, familyId: photo.familyId });

    // 为照片生成下载预签名URL
    try {
      const downloadResult = await tosService.generateDownloadUrl(photo.url);
      photo = {
        ...photo,
        url: downloadResult.downloadUrl,
        thumbnailUrl: downloadResult.downloadUrl
      };
    } catch (error) {
      console.error('生成下载URL失败:', error);
    }

    return photo;
  }
  
  /**
   * 检查照片哈希是否重复
   * @param {Array<string>} hashes - SHA-256 哈希数组
   * @returns {Promise<Object>} 重复信息
   */
  static async checkDuplicates(hashes) {
    if (!Array.isArray(hashes) || hashes.length === 0) {
      throw { code: 9001, message: '参数缺失' };
    }
    // 防止滥用：单次最多检查 100 个哈希
    if (hashes.length > 100) {
      throw { code: 9001, message: '单次最多检查100个哈希' };
    }
    return await Photo.checkDuplicates(hashes);
  }

  /**
   * 更新照片信息
   * @param {number} photoId - 照片ID
   * @param {number} userId - 用户ID
   * @param {Object} photoData - 照片数据
   * @returns {Promise<boolean>} 更新是否成功
   */
  static async updatePhoto(photoId, userId, photoData) {
    const { location, tags } = photoData;
    
    const success = await Photo.update(photoId, userId, {
      location,
      tags
    });
    
    if (!success) {
      throw { code: 9005, message: '照片不存在' };
    }
    
    return success;
  }
  
  /**
   * 删除照片
   * @param {number} photoId - 照片ID
   * @param {number} userId - 用户ID
   * @returns {Promise<boolean>} 删除是否成功
   */
  static async deletePhoto(photoId, userId) {
    const success = await Photo.delete(photoId, userId);

    if (!success) {
      throw { code: 9005, message: '照片不存在' };
    }

    auditLog('photo.delete', { userId }, { photoId });
    return success;
  }
  
  /**
   * 批量删除照片
   * @param {Array<number>} photoIds - 照片ID数组
   * @param {number} userId - 用户ID
   * @returns {Promise<number>} 删除的照片数量
   */
  static async deletePhotos(photoIds, userId) {
    if (!Array.isArray(photoIds) || photoIds.length === 0) {
      throw { code: 9001, message: '参数缺失' };
    }
    
    const deletedCount = await Photo.deleteBatch(photoIds, userId);
    auditLog('photo.deleteBatch', { userId }, { count: deletedCount, photoIds });
    return deletedCount;
  }

  /**
   * 获取家庭组照片列表
   * @param {number} familyId - 家庭组ID
   * @param {Object} options - 查询选项
   * @returns {Promise<Object>} 照片列表和总数
   */
  static async getFamilyPhotos(familyId, options = {}) {
    const { page = 1, pageSize = 20, orderBy = 'created_at', order = 'DESC' } = options;

    // 获取照片列表
    let photos = await Photo.findByFamilyId(familyId, {
      page,
      pageSize,
      orderBy,
      order
    });

    // 为每个照片生成下载预签名URL
    photos = await Promise.all(photos.map(async (photo) => {
      try {
        const downloadResult = await tosService.generateDownloadUrl(photo.url);
        return {
          ...photo,
          url: downloadResult.downloadUrl,
          thumbnailUrl: downloadResult.downloadUrl
        };
      } catch (error) {
        console.error('生成下载URL失败:', error);
        return photo;
      }
    }));

    // 获取总数
    const total = await Photo.countByFamilyId(familyId);

    return {
      photos,
      pagination: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize)
      }
    };
  }

  /**
   * 更新照片的家庭组归属
   * @param {number} photoId - 照片ID
   * @param {number} userId - 用户ID
   * @param {number} familyId - 家庭组ID
   * @returns {Promise<boolean>} 更新是否成功
   */
  static async updatePhotoFamily(photoId, userId, familyId) {
    const success = await Photo.updateFamily(photoId, userId, familyId);
    if (!success) {
      throw { code: 9005, message: '照片不存在或无权操作' };
    }
    return success;
  }
}

module.exports = PhotoService;