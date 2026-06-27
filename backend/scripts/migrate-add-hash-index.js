/**
 * 迁移：为 photos.hash 添加唯一索引
 *
 * 运行方式：node scripts/migrate-add-hash-index.js
 * 生产环境：NODE_ENV=production node scripts/migrate-add-hash-index.js
 *
 * 日常去重由 Photo.checkDuplicates() SELECT 查询完成，此索引为并发竞态兜底。
 */
const { mysqlPool } = require('../src/config/database');

async function main() {
  try {
    // 检查索引是否已存在
    const [existing] = await mysqlPool.execute(
      `SELECT COUNT(*) as cnt FROM information_schema.statistics
       WHERE table_schema = DATABASE() AND table_name = 'photos' AND index_name = 'idx_photos_hash'`
    );

    if (existing[0].cnt > 0) {
      console.log('索引 idx_photos_hash 已存在，跳过。');
      return;
    }

    // 检查是否有重复 hash 值
    const [dupes] = await mysqlPool.execute(
      `SELECT hash, COUNT(*) as cnt FROM photos WHERE hash IS NOT NULL GROUP BY hash HAVING cnt > 1 LIMIT 5`
    );
    if (dupes.length > 0) {
      console.warn('警告：发现重复 hash 值，创建索引前需清理：');
      dupes.forEach(d => console.warn(`  hash=${d.hash} cnt=${d.cnt}`));
      console.warn('请手动清理重复行后再执行此迁移。');
      return;
    }

    await mysqlPool.execute('CREATE UNIQUE INDEX idx_photos_hash ON photos(hash)');
    console.log('索引 idx_photos_hash 创建成功。');
  } finally {
    await mysqlPool.end();
  }
}

main().catch(err => { console.error(err); process.exit(1); });
