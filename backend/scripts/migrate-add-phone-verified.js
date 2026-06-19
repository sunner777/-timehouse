const { mysqlPool } = require('../src/config/database');

async function migrate() {
  try {
    console.log('开始数据库迁移：添加phone_verified字段到users表...');

    // 检查phone_verified字段是否已存在
    const [columns] = await mysqlPool.execute(`SHOW COLUMNS FROM users LIKE 'phone_verified'`);

    if (columns.length > 0) {
      console.log('phone_verified字段已存在，跳过迁移');
    } else {
      // 添加phone_verified字段
      await mysqlPool.execute(`ALTER TABLE users ADD COLUMN phone_verified TINYINT(1) NOT NULL DEFAULT 0 COMMENT '手机号是否已验证' AFTER password`);
      console.log('成功添加phone_verified字段');
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
