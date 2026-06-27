const { mysqlPool } = require('../../config/database');
const { clean, cleanArray } = require('../../utils/sanitize');

const ALLOWED_ORDER_COLUMNS = ['created_at', 'taken_at', 'id', 'updated_at'];
const ALLOWED_ORDER_DIRECTIONS = ['ASC', 'DESC'];

const sanitizeOrder = (orderBy, order) => {
  const col = ALLOWED_ORDER_COLUMNS.includes(orderBy) ? orderBy : 'created_at';
  const dir = ALLOWED_ORDER_DIRECTIONS.includes(order?.toUpperCase()) ? order.toUpperCase() : 'DESC';
  return { sanitizedOrderBy: col, sanitizedOrder: dir };
};

class Photo {
  /**
   * 创建照片
   * @param {Object} photoData - 照片数据
   * @returns {Promise<Object>} 创建的照片
   */
  static async create(photoData) {
    const { userId, familyId, url, thumbnailUrl, fileName, size, contentType, hash, takenAt, location, tags } = photoData;

    // 清理URL和文件名中的反引号和空格
    const cleanUrl = url ? url.replace(/`/g, '').trim() : '';
    const cleanThumbnailUrl = thumbnailUrl ? thumbnailUrl.replace(/`/g, '').trim() : '';
    const cleanFileName = fileName ? fileName.replace(/`/g, '').trim() : '';
    const cleanHash = hash ? hash.trim() : null;

    try {
      const query = `
        INSERT INTO photos (user_id, family_id, url, thumbnail_url, file_name, size, content_type, hash, taken_at, location, tags, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
      `;

      const safeLocation = clean(location);
      const safeTags = cleanArray(tags);
      const [result] = await mysqlPool.execute(query, [
        userId, familyId || null, cleanUrl, cleanThumbnailUrl, cleanFileName,
        size, contentType, cleanHash, takenAt, safeLocation, JSON.stringify(safeTags)
      ]);

      return {
        id: result.insertId,
        userId,
        familyId: familyId || null,
        url: cleanUrl,
        thumbnailUrl: cleanThumbnailUrl,
        fileName: cleanFileName,
        size,
        contentType,
        hash: cleanHash,
        takenAt,
        location,
        tags
      };
    } catch (error) {
      // 并发重复插入处理：hash 唯一索引冲突 → 返回已存在的记录
      if (error.code === 'ER_DUP_ENTRY' && cleanHash) {
        const existing = await this.findByHash(cleanHash);
        if (existing) {
          return existing;
        }
      }
      throw error;
    }
  }

  /**
   * 根据用户ID获取照片列表
   * @param {number} userId - 用户ID
   * @param {Object} options - 查询选项
   * @returns {Promise<Array>} 照片列表
   */
  static async findByUserId(userId, options = {}) {
    const { page = 1, pageSize = 20, orderBy = 'created_at', order = 'DESC' } = options;
    const offset = (page - 1) * pageSize;
    const { sanitizedOrderBy, sanitizedOrder } = sanitizeOrder(orderBy, order);

    const query = `
      SELECT id, user_id as userId, family_id as familyId, url, thumbnail_url as thumbnailUrl, file_name as fileName,
             size, content_type as contentType, hash, taken_at as takenAt, location, tags,
             created_at as createdAt, updated_at as updatedAt
      FROM photos
      WHERE user_id = ?
      ORDER BY ${sanitizedOrderBy} ${sanitizedOrder}
      LIMIT ${parseInt(pageSize)} OFFSET ${parseInt(offset)}
    `;

    const [rows] = await mysqlPool.query(query, [parseInt(userId)]);

    // 解析tags字段，处理无效的JSON数据
    return rows.map(row => {
      let tags = [];
      if (row.tags && typeof row.tags === 'string') {
        try {
          tags = JSON.parse(row.tags);
        } catch (e) {
          tags = [];
        }
      }
      return {
        ...row,
        url: row.url ? row.url.trim() : '',
        thumbnailUrl: row.thumbnailUrl ? row.thumbnailUrl.trim() : '',
        tags
      };
    });
  }

  /**
   * 根据家庭组ID获取照片列表
   * @param {number} familyId - 家庭组ID
   * @param {Object} options - 查询选项
   * @returns {Promise<Array>} 照片列表
   */
  static async findByFamilyId(familyId, options = {}) {
    const { page = 1, pageSize = 20, orderBy = 'created_at', order = 'DESC' } = options;
    const offset = (page - 1) * pageSize;
    const { sanitizedOrderBy, sanitizedOrder } = sanitizeOrder(orderBy, order);

    const query = `
      SELECT id, user_id as userId, family_id as familyId, url, thumbnail_url as thumbnailUrl, file_name as fileName,
             size, content_type as contentType, taken_at as takenAt, location, tags,
             created_at as createdAt, updated_at as updatedAt
      FROM photos
      WHERE family_id = ?
      ORDER BY ${sanitizedOrderBy} ${sanitizedOrder}
      LIMIT ${parseInt(pageSize)} OFFSET ${parseInt(offset)}
    `;

    const [rows] = await mysqlPool.query(query, [parseInt(familyId)]);

    // 解析tags字段，处理无效的JSON数据
    return rows.map(row => {
      let tags = [];
      if (row.tags && typeof row.tags === 'string') {
        try {
          tags = JSON.parse(row.tags);
        } catch (e) {
          tags = [];
        }
      }
      return {
        ...row,
        url: row.url ? row.url.trim() : '',
        thumbnailUrl: row.thumbnailUrl ? row.thumbnailUrl.trim() : '',
        tags
      };
    });
  }

  /**
   * 根据ID查找照片
   * @param {number} id - 照片ID
   * @param {number} userId - 用户ID（用于权限验证）
   * @returns {Promise<Object|null>} 照片信息
   */
  static async findById(id, userId) {
    const query = `
      SELECT id, user_id as userId, family_id as familyId, url, thumbnail_url as thumbnailUrl, file_name as fileName,
             size, content_type as contentType, hash, taken_at as takenAt, location, tags,
             created_at as createdAt, updated_at as updatedAt
      FROM photos
      WHERE id = ? AND user_id = ?
    `;

    const [rows] = await mysqlPool.execute(query, [id, userId]);

    if (rows.length === 0) return null;

    const photo = rows[0];
    let tags = [];
    if (photo.tags && typeof photo.tags === 'string') {
      try {
        tags = JSON.parse(photo.tags);
      } catch (e) {
        tags = [];
      }
    }
    return {
      ...photo,
      url: photo.url ? photo.url.trim() : '',
      thumbnailUrl: photo.thumbnailUrl ? photo.thumbnailUrl.trim() : '',
      tags
    };
  }

  /**
   * 更新照片的家庭组归属
   * @param {number} id - 照片ID
   * @param {number} userId - 用户ID（用于权限验证）
   * @param {number} familyId - 家庭组ID（null表示移除
   * @returns {Promise<boolean>} 更新是否成功
   */
  static async updateFamily(id, userId, familyId) {
    const query = 'UPDATE photos SET family_id = ?, updated_at = NOW() WHERE id = ? AND user_id = ?';
    const [result] = await mysqlPool.execute(query, [familyId || null, id, userId]);
    return result.affectedRows > 0;
  }

  /**
   * 统计家庭组照片数量
   * @param {number} familyId - 家庭组ID
   * @returns {Promise<number>} 照片数量
   */
  static async countByFamilyId(familyId) {
    const query = 'SELECT COUNT(*) as count FROM photos WHERE family_id = ?';
    const [rows] = await mysqlPool.execute(query, [familyId]);
    return rows[0].count;
  }

  /**
   * 更新照片信息
   * @param {number} id - 照片ID
   * @param {number} userId - 用户ID（用于权限验证）
   * @param {Object} photoData - 照片数据
   * @returns {Promise<boolean>} 更新是否成功
   */
  static async update(id, userId, photoData) {
    const { location, tags } = photoData;

    const query = `
      UPDATE photos
      SET location = ?, tags = ?, updated_at = NOW()
      WHERE id = ? AND user_id = ?
    `;

    const safeLocation = clean(location);
    const safeTags = cleanArray(tags);
    const [result] = await mysqlPool.execute(query, [safeLocation, JSON.stringify(safeTags), id, userId]);
    return result.affectedRows > 0;
  }

  /**
   * 删除照片
   * @param {number} id - 照片ID
   * @param {number} userId - 用户ID（用于权限验证）
   * @returns {Promise<boolean>} 删除是否成功
   */
  static async delete(id, userId) {
    const query = 'DELETE FROM photos WHERE id = ? AND user_id = ?';
    const [result] = await mysqlPool.execute(query, [id, userId]);
    return result.affectedRows > 0;
  }

  /**
   * 批量删除照片
   * @param {Array<number>} ids - 照片ID数组
   * @param {number} userId - 用户ID（用于权限验证）
   * @returns {Promise<number>} 删除的照片数量
   */
  static async deleteBatch(ids, userId) {
    const placeholders = ids.map(() => '?').join(',');
    const query = `DELETE FROM photos WHERE id IN (${placeholders}) AND user_id = ?`;

    const [result] = await mysqlPool.execute(query, [...ids, userId]);
    return result.affectedRows;
  }

  /**
   * 统计用户照片数量
   * @param {number} userId - 用户ID
   * @returns {Promise<number>} 照片数量
   */
  static async countByUserId(userId) {
    const query = 'SELECT COUNT(*) as count FROM photos WHERE user_id = ?';
    const [rows] = await mysqlPool.execute(query, [userId]);
    return rows[0].count;
  }

  /**
   * 仅根据ID查找照片（不做用户权限过滤）
   * @param {number} id - 照片ID
   * @returns {Promise<Object|null>} 照片信息
   */
  static async findByIdOnly(id) {
    const query = `
      SELECT id, user_id as userId, family_id as familyId, url, thumbnail_url as thumbnailUrl, file_name as fileName,
             size, content_type as contentType, hash, taken_at as takenAt, location, tags,
             created_at as createdAt, updated_at as updatedAt
      FROM photos
      WHERE id = ?
    `;

    const [rows] = await mysqlPool.execute(query, [id]);

    if (rows.length === 0) return null;

    const photo = rows[0];
    let tags = [];
    if (photo.tags && typeof photo.tags === 'string') {
      try {
        tags = JSON.parse(photo.tags);
      } catch (e) {
        tags = [];
      }
    }
    return {
      ...photo,
      url: photo.url ? photo.url.trim() : '',
      thumbnailUrl: photo.thumbnailUrl ? photo.thumbnailUrl.trim() : '',
      tags
    };
  }

  /**
   * 根据哈希查找照片
   * @param {string} hash - SHA-256 哈希值
   * @returns {Promise<Object|null>} 照片信息
   */
  static async findByHash(hash) {
    if (!hash) return null;
    const query = `
      SELECT id, user_id as userId, family_id as familyId, url, thumbnail_url as thumbnailUrl, file_name as fileName,
             size, content_type as contentType, hash, taken_at as takenAt, location, tags,
             created_at as createdAt, updated_at as updatedAt
      FROM photos
      WHERE hash = ?
      LIMIT 1
    `;
    const [rows] = await mysqlPool.execute(query, [hash]);
    if (rows.length === 0) return null;

    const photo = rows[0];
    let tags = [];
    if (photo.tags && typeof photo.tags === 'string') {
      try { tags = JSON.parse(photo.tags); } catch (e) { tags = []; }
    }
    return {
      ...photo,
      url: photo.url ? photo.url.trim() : '',
      thumbnailUrl: photo.thumbnailUrl ? photo.thumbnailUrl.trim() : '',
      tags
    };
  }

  /**
   * 检查照片哈希是否已存在
   * @param {Array<string>} hashes - SHA-256 哈希数组
   * @returns {Promise<Object>} { duplicates: string[], duplicatePhotoIds: { [hash]: { photoId, userId, familyId } } }
   */
  static async checkDuplicates(hashes) {
    if (!Array.isArray(hashes) || hashes.length === 0) {
      return { duplicates: [], duplicatePhotoIds: {} };
    }

    const placeholders = hashes.map(() => '?').join(',');
    const query = `SELECT id, hash, user_id as userId, family_id as familyId FROM photos WHERE hash IN (${placeholders})`;

    const [rows] = await mysqlPool.execute(query, hashes);

    const duplicatePhotoIds = {};
    const duplicateHashes = rows.map(row => {
      duplicatePhotoIds[row.hash] = {
        photoId: row.id.toString(),
        userId: row.userId,
        familyId: row.familyId
      };
      return row.hash;
    });

    return { duplicates: duplicateHashes, duplicatePhotoIds };
  }
}

module.exports = Photo;