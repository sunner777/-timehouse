#!/bin/bash
# 时光家后端部署脚本
# 在服务器上运行：cd /opt/timehouse-repo/backend && bash deploy.sh
set -e

echo "[$(date -Iseconds)] Deploy start"

# 从 GitHub 拉取最新代码（需要服务器能访问 GitHub）
git -C /opt/timehouse-repo pull origin master 2>/dev/null || echo "  (git pull skipped — using local commits from git push)"

# 仅当 package.json 变更时重新安装依赖
CHANGED=$(git -C /opt/timehouse-repo diff --name-only HEAD@{1} HEAD 2>/dev/null || echo "")
if echo "$CHANGED" | grep -q "package.json"; then
  echo "  package.json changed, running npm install..."
  cd /opt/timehouse-repo/backend && npm install --production 2>&1 | tail -3
fi

# PM2 reload
cd /opt/timehouse-repo/backend && pm2 reload ecosystem.config.js 2>&1
echo "  PM2 reloaded"

# Nginx 配置更新
if echo "$CHANGED" | grep -q "nginx/timehouse.conf"; then
  cp /opt/timehouse-repo/backend/nginx/timehouse.conf /etc/nginx/sites-available/timehouse
  nginx -t 2>&1 && systemctl reload nginx && echo "  Nginx reloaded"
fi

echo "[$(date -Iseconds)] Deploy done"
sleep 2
curl -sf https://api.timehouse.top/api/v1/health && echo "  Health: OK" || echo "  Health: FAIL"
