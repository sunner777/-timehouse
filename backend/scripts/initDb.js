const { mysqlPool } = require('../src/config/database');

/**
 * 初始化数据库表结构
 */
async function initDatabase() {
  try {
    console.log('开始初始化数据库...');
    
    // 创建用户表
    const createUserTable = `
      CREATE TABLE IF NOT EXISTS users (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '用户ID',
        phone VARCHAR(20) NOT NULL UNIQUE COMMENT '手机号',
        password VARCHAR(255) NOT NULL COMMENT '密码（bcrypt加密）',
        phone_verified TINYINT(1) NOT NULL DEFAULT 0 COMMENT '手机号是否已验证',
        nickname VARCHAR(50) DEFAULT '' COMMENT '昵称',
        avatar VARCHAR(500) DEFAULT '' COMMENT '头像URL',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
        INDEX idx_phone (phone),
        INDEX idx_created_at (created_at)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';
    `;
    
    // 创建家庭组表
    const createFamilyTable = `
      CREATE TABLE IF NOT EXISTS families (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '家庭组ID',
        name VARCHAR(100) NOT NULL COMMENT '组名',
        owner_id BIGINT UNSIGNED NOT NULL COMMENT '群主ID',
        invite_code CHAR(6) NOT NULL UNIQUE COMMENT '邀请码',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
        INDEX idx_owner_id (owner_id),
        INDEX idx_invite_code (invite_code),
        FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='家庭组表';
    `;
    
    // 创建家庭组成员表
    const createFamilyMemberTable = `
      CREATE TABLE IF NOT EXISTS family_members (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '成员ID',
        family_id BIGINT UNSIGNED NOT NULL COMMENT '家庭组ID',
        user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
        role ENUM('owner', 'admin', 'member', 'guest') DEFAULT 'member' COMMENT '角色',
        permissions JSON DEFAULT NULL COMMENT '权限列表["view","edit","delete","manage"]',
        joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
        UNIQUE KEY uk_family_user (family_id, user_id),
        INDEX idx_user_id (user_id),
        FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='家庭组成员表';
    `;
    
    // 创建照片表
    const createPhotoTable = `
      CREATE TABLE IF NOT EXISTS photos (
        id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '照片ID',
        user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
        family_id BIGINT UNSIGNED DEFAULT NULL COMMENT '家庭组ID',
        url VARCHAR(500) NOT NULL COMMENT '照片URL',
        thumbnail_url VARCHAR(500) NOT NULL COMMENT '缩略图URL',
        file_name VARCHAR(255) NOT NULL COMMENT '文件名',
        size BIGINT UNSIGNED NOT NULL COMMENT '文件大小（字节）',
        content_type VARCHAR(50) NOT NULL COMMENT '文件类型',
        taken_at DATETIME DEFAULT NULL COMMENT '拍摄时间',
        location VARCHAR(255) DEFAULT '' COMMENT '拍摄地点',
        tags JSON DEFAULT NULL COMMENT '标签',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
        INDEX idx_user_id (user_id),
        INDEX idx_family_id (family_id),
        INDEX idx_created_at (created_at),
        INDEX idx_taken_at (taken_at),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE SET NULL
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='照片表';
    `;
    
    // 执行创建表语句
    await mysqlPool.execute(createUserTable);
    console.log('创建用户表成功');
    
    await mysqlPool.execute(createFamilyTable);
    console.log('创建家庭组表成功');
    
    await mysqlPool.execute(createFamilyMemberTable);
    console.log('创建家庭组成员表成功');
    
    await mysqlPool.execute(createPhotoTable);
    console.log('创建照片表成功');
    
    console.log('数据库初始化完成！');
  } catch (error) {
    console.error('数据库初始化失败:', error);
  } finally {
    // 关闭数据库连接
    await mysqlPool.end();
    console.log('数据库连接已关闭');
  }
}

// 执行初始化
initDatabase();