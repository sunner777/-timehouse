/**
 * 迁移：为 photos.hash 添加唯一索引
 *
 * 运行方式：node scripts/migrate-add-hash-index.js
 *
 * 作用：防止并发上传同一张照片时产生重复行。
 * 日常去重由 checkDuplicates() SELECT 查询完成，此索引为并发竞态兜底。
 */
const mysql = require('mysql2/promise');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

async function main() {
  const pool = mysql.createPool({
    host: process.env.MYSQL_HOST || 'localhost',
    port: process.env.MYSQL_PORT || 3306,
    user: process.env.MYSQL_USER || 'root',
    password: process.env.MYSQL_PASSWORD || 'password',
    database: process.env.MYSQL_DATABASE || 'timehouse',
  });

  try {
    // 检查索引是否已存在
    const [existing] = await pool.execute(
      `SELECT COUNT(*) as cnt FROM information_schema.statistics
       WHERE table_schema = ? AND table_name = 'photos' AND index_name = 'idx_photos_hash'`,
      [process.env.MYSQL_DATABASE || 'timehouse']
    );

    if (existing[0].cnt > 0) {
      console.log('索引 idx_photos_hash 已存在，跳过。');
      return;
    }

    // 检查是否有重复 hash 值（非空）
    const [dupes] = await pool.execute(
      `SELECT hash, COUNT(*) as cnt FROM photos WHERE hash IS NOT NULL GROUP BY hash HAVING cnt > 1 LIMIT 5`
    );
    if (dupes.length > 0) {
      console.warn('警告：发现重复 hash 值，创建索引前需清理：');
      dupes.forEach(d => console.warn(`  hash=${d.hash} cnt=${d.cnt}`));
      console.warn('请手动清理重复行后再执行此迁移。');
      return;
    }

    await pool.execute('CREATE UNIQUE INDEX idx_photos_hash ON photos(hash)');
    console.log('索引 idx_photos_hash 创建成功。');
  } finally {
    await pool.end();
  }
}

main().catch(err => { console.error(err); process.exit(1); });
