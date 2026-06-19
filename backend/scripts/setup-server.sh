#!/bin/bash
set -e
# 阿里云轻量服务器初始化脚本
# 适用于 Ubuntu 22.04+

echo "=== 更新系统 ==="
apt update && apt upgrade -y

echo "=== 安装基础工具 ==="
apt install -y curl wget gnupg lsb-release ca-certificates nginx git ufw

echo "=== 安装 Docker ==="
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com | bash
  systemctl enable docker
  systemctl start docker
else
  echo "Docker 已安装"
fi

echo "=== 安装 Docker Compose ==="
if ! command -v docker-compose &> /dev/null; then
  apt install -y docker-compose-plugin
  # 创建 docker-compose 别名
  echo 'alias docker-compose="docker compose"' >> /etc/profile.d/docker.sh
fi

echo "=== 安装 Node.js 20 ==="
if ! command -v node &> /dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt install -y nodejs
else
  echo "Node.js 已安装: $(node -v)"
fi

echo "=== 安装 PM2 ==="
if ! command -v pm2 &> /dev/null; then
  npm install -g pm2
else
  echo "PM2 已安装"
fi

echo "=== 配置防火墙 ==="
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "=== 创建应用目录 ==="
mkdir -p /opt/timehouse
mkdir -p /opt/backups/mysql
mkdir -p /var/log/timehouse

echo "=== 配置 Nginx ==="
# 确保必要的目录存在
mkdir -p /etc/nginx/ssl

echo ""
echo "=== 初始化完成 ==="
echo "下一步："
echo "1. 上传代码到 /opt/timehouse"
echo "2. 创建 .env.production 配置数据库密码"
echo "3. docker compose up -d (启动 MySQL)"
echo "4. node scripts/initDb.js (初始化表)"
echo "5. 配置 Nginx + SSL 证书"
echo "6. pm2 start ecosystem.config.js"
