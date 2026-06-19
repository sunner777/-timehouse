const { mysqlPool } = require('../src/config/database');

async function migrate() {
  try {
    console.log('开始数据库迁移：添加family_id字段到photos表...');

    // 检查family_id字段是否已存在
    const [columns] = await mysqlPool.execute(`SHOW COLUMNS FROM photos LIKE 'family_id'`);
    
    if (columns.length > 0) {
      console.log('family_id字段已存在，跳过迁移');
    } else {
      // 添加family_id字段
      await mysqlPool.execute(`ALTER TABLE photos ADD COLUMN family_id BIGINT UNSIGNED DEFAULT NULL COMMENT '家庭组ID' AFTER user_id`);
      console.log('成功添加family_id字段');

      // 添加索引
      await mysqlPool.execute(`CREATE INDEX idx_family_id ON photos(family_id)`);
      console.log('成功添加idx_family_id索引');

      // 添加外键约束
      await mysqlPool.execute(`ALTER TABLE photos ADD CONSTRAINT fk_photos_family_id FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE SET NULL`);
      console.log('成功添加外键约束');
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
