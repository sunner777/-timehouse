/**
 * 检查数据库表结构
 */
const { mysqlPool } = require('../src/config/database');

async function checkTables() {
  try {
    console.log('📊 正在检查数据库表结构...\n');

    // 获取所有表名
    const [tables] = await mysqlPool.execute(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'timehouse'"
    );

    // 提取表名数组
    const tableNames = tables.map(t => t.TABLE_NAME || t.table_name).filter(Boolean);
    
    console.log(`找到 ${tableNames.length} 个表:`);
    tableNames.forEach(tableName => {
      console.log(`  - ${tableName}`);
    });

    // 查看每个表的结构
    for (const tableName of tableNames) {
      console.log(`\n📋 ${tableName} 表结构:`);
      
      const [columns] = await mysqlPool.execute(
        `SHOW COLUMNS FROM ${tableName}`
      );
      
      console.log('┌────────────────────┬─────────────────┬──────┬───┬──────────────┐');
      console.log('│ 字段名             │ 类型            │ 空   │ 键 │ 默认值       │');
      console.log('├────────────────────┼─────────────────┼──────┼───┼──────────────┤');
      
      columns.forEach(col => {
        const field = col.Field.padEnd(18);
        const type = col.Type.padEnd(15);
        const nullable = col.Null.padEnd(6);
        const key = col.Key.padEnd(3);
        const defaultValue = (col.Default || '').padEnd(12);
        console.log(`│ ${field}│ ${type}│ ${nullable}│ ${key}│ ${defaultValue}│`);
      });
      
      console.log('└────────────────────┴─────────────────┴──────┴───┴──────────────┘');
    }

    // 统计各表数据量
    console.log('\n📈 各表数据量统计:');
    for (const tableName of tableNames) {
      const [result] = await mysqlPool.execute(
        `SELECT COUNT(*) as count FROM ${tableName}`
      );
      console.log(`  ${tableName}: ${result[0].count} 条记录`);
    }

    await mysqlPool.end();
    console.log('\n✅ 检查完成！');
  } catch (error) {
    console.error('❌ 检查失败:', error);
    process.exit(1);
  }
}

checkTables();
