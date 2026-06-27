#!/bin/bash
# 时光家后端部署脚本
# 用法：本地 git push server master 之后，ssh 服务器执行此脚本
#   ssh server 'cd /opt/timehouse-repo/backend && bash deploy.sh'
set -e

REPO_DIR="/opt/timehouse-repo/backend"

# ── 记录变更文件 ──
CHANGED=$(git -C /opt/timehouse-repo diff --name-only HEAD@{1} HEAD 2>/dev/null || echo "")

echo "[$(date -Iseconds)] Deploy start"

# ── npm install（仅 package.json 变更时） ──
if echo "$CHANGED" | grep -q "package.json"; then
  echo "  package.json changed, running npm install..."
  cd "$REPO_DIR" && npm install --production 2>&1 | tail -3
fi

# ── PM2 reload ──
cd "$REPO_DIR" && pm2 reload ecosystem.config.js 2>&1
echo "  PM2 reloaded"

# ── Nginx 配置更新 ──
if echo "$CHANGED" | grep -q "nginx/timehouse.conf"; then
  cp "$REPO_DIR/nginx/timehouse.conf" /etc/nginx/sites-available/timehouse
  nginx -t 2>&1 && systemctl reload nginx && echo "  Nginx reloaded"
fi

echo "[$(date -Iseconds)] Deploy done"

# ── Health check ──
sleep 2
curl -sf https://api.timehouse.top/api/v1/health && echo "" && echo "Health: OK" || echo "Health: FAIL"
