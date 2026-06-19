/**
 * 操作审计日志
 *
 * 记录敏感操作，输出到 stdout（由 PM2 收集到日志文件）。
 * 日志为 JSON 格式，key 前缀 audit_ 方便 grep 过滤。
 *
 * 安全注意：绝不记录完整 Token、照片内容或验证码。
 */
const auditLog = (action, actor, detail = {}) => {
  const entry = {
    audit_action: action,
    audit_actorId: actor.userId ?? null,
    audit_timestamp: new Date().toISOString(),
    ...detail,
  };
  // 同步写 stdout，fire-and-forget，不增加请求延迟
  process.stdout.write(JSON.stringify(entry) + '\n');
};

module.exports = auditLog;
