const { mysqlPool } = require('../src/config/database');

/**
 * 迁移：为 photos 表添加 hash 字段，用于照片去重
 */
async function migrate() {
  try {
    console.log('开始数据库迁移：添加 hash 字段到 photos 表...');

    // 检查 hash 列是否已存在
    const [columns] = await mysqlPool.execute(`SHOW COLUMNS FROM photos LIKE 'hash'`);

    if (columns.length > 0) {
      console.log('hash 字段已存在，跳过迁移');
    } else {
      // 添加 hash 列
      await mysqlPool.execute(
        `ALTER TABLE photos ADD COLUMN hash CHAR(64) DEFAULT NULL COMMENT 'SHA-256 hash of photo bytes' AFTER content_type`
      );
      console.log('成功添加 hash 字段');

      // 添加唯一索引（防止并发重复插入）
      await mysqlPool.execute(`CREATE UNIQUE INDEX idx_hash ON photos(hash)`);
      console.log('成功添加 idx_hash 唯一索引');
    }

    console.log('数据库迁移完成！');
  } catch (error) {
    console.error('数据库迁移失败:', error);
    throw error;
  } finally {
    await mysqlPool.end();
    console.log('数据库连接已关闭');
  }
}

migrate();
