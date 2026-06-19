#!/bin/bash
set -e

# 加载环境变量（docker-compose 同目录下的 .env.production）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="/opt/backups/mysql"
RETENTION_DAYS=7

# 从 .env.production 读取数据库密码
source <(grep -E '^MYSQL_ROOT_PASSWORD=' "$APP_DIR/.env.production")

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/timehouse_${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

# 从 Docker 容器内执行 mysqldump
docker exec timehouse-mysql mysqldump \
  -u root \
  -p"${MYSQL_ROOT_PASSWORD}" \
  --single-transaction \
  --quick \
  --skip-lock-tables \
  --default-character-set=utf8mb4 \
  timehouse | gzip > "$BACKUP_FILE"

echo "Backup created: ${BACKUP_FILE}"

# 删除旧备份
find "$BACKUP_DIR" -name "timehouse_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
echo "Cleaned backups older than ${RETENTION_DAYS} days"
