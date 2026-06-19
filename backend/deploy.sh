#!/bin/bash
set -e
ECS_HOST="${ECS_HOST:-}"
SSH_USER="${SSH_USER:-root}"
APP_DIR="/opt/timehouse"

if [ -z "$ECS_HOST" ]; then
  echo "Usage: ECS_HOST=<new-server-ip> ./deploy.sh"
  exit 1
fi

echo "=== Deploying to ${ECS_HOST} ==="

echo "=== Syncing code ==="
rsync -avz \
  --exclude 'node_modules' \
  --exclude '.env' \
  --exclude '.env.production' \
  --exclude '.git' \
  --exclude '*.log' \
  --exclude 'logs' \
  --exclude 'mysql_data' \
  ./ ${SSH_USER}@${ECS_HOST}:${APP_DIR}/

echo "=== Copy .env.production ==="
scp .env.production ${SSH_USER}@${ECS_HOST}:${APP_DIR}/.env.production

echo "=== Installing dependencies ==="
ssh ${SSH_USER}@${ECS_HOST} "cd ${APP_DIR} && npm ci --production"

echo "=== Reloading PM2 ==="
ssh ${SSH_USER}@${ECS_HOST} "cd ${APP_DIR} && pm2 reload ecosystem.config.js || pm2 start ecosystem.config.js"
ssh ${SSH_USER}@${ECS_HOST} "pm2 save"

echo "=== Deployment complete ==="
echo "=== Running health check ==="
sleep 3
curl -f "https://api.timehouse.top/api/v1/health" || echo "Health check failed (may need DNS/SSL setup first)"
