/**
 * 请求校验 Schema 定义
 *
 * 所有 schema 均使用 Joi，在路由层通过 validateBody / validateQuery / validateParams 应用。
 * stripUnknown: true 确保只接受 schema 声明的字段，自动丢弃未定义字段。
 */
const Joi = require('joi');

// ─── 通用工具 ──────────────────────────────────────────────

/** 中国大陆手机号 */
const phone = () => Joi.string().pattern(/^1\d{10}$/).message('手机号格式不正确');

/** 安全文本：2-50 字符，无控制字符，无 HTML 标签 */
const safeText = (min = 1, max = 50) =>
  Joi.string().min(min).max(max)
    .pattern(/^[^<>]*$/, { name: 'no-html' })
    .message('{{#label}} 不允许包含 HTML 标签');

/** 纯数字 ID（避免 SQL 注入） */
const id = () => Joi.number().integer().positive();

// ─── 认证 ──────────────────────────────────────────────────

const auth = {
  sendCode: Joi.object({
    phone: phone().required(),
  }),

  smsLogin: Joi.object({
    phone: phone().required(),
    code: Joi.string().pattern(/^\d{4,6}$/).required().messages({
      'string.pattern.base': '验证码格式不正确',
      'any.required': '验证码不能为空',
    }),
  }),

  changePassword: Joi.object({
    oldPassword: Joi.string().min(6).max(20).required(),
    newPassword: Joi.string().min(6).max(20).required(),
  }),

  updateProfile: Joi.object({
    nickname: safeText(1, 30).optional(),
    avatar: Joi.string().uri({ scheme: ['http', 'https'] }).max(500).optional(),
  }).or('nickname', 'avatar').messages({
    'object.missing': '至少需要提供昵称或头像',
  }),

  // 兼容旧接口
  register: Joi.object({
    phone: phone().required(),
    password: Joi.string().min(6).max(20).required(),
    nickname: safeText(0, 30).optional().allow(''),
  }),

  login: Joi.object({
    phone: phone().required(),
    password: Joi.string().min(6).max(20).required(),
  }),
};

// ─── 照片 ──────────────────────────────────────────────────

const photos = {
  upload: Joi.object({
    url: Joi.string().uri({ scheme: ['http', 'https'] }).max(500).required(),
    thumbnailUrl: Joi.string().uri({ scheme: ['http', 'https'] }).max(500).required(),
    fileName: Joi.string().max(255).required(),
    size: Joi.number().integer().min(0).max(100 * 1024 * 1024).required(),
    contentType: Joi.string().valid(
      'image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/heic', 'image/heif'
    ).required().messages({
      'any.only': '不支持的文件类型',
    }),
    hash: Joi.string().pattern(/^[a-fA-F0-9]{64}$/).optional().allow(null, ''),
    takenAt: Joi.date().iso().optional(),
    location: safeText(0, 200).optional().allow(null, ''),
    tags: Joi.array().items(safeText(1, 50)).max(20).optional(),
    familyId: id().optional().allow(null),
  }),

  update: Joi.object({
    location: safeText(0, 200).optional().allow(null, ''),
    tags: Joi.array().items(safeText(1, 50)).max(20).optional(),
  }),

  updateFamily: Joi.object({
    familyId: id().optional().allow(null),
  }),

  batchDelete: Joi.object({
    photoIds: Joi.array().items(id()).min(1).max(100).required(),
  }),

  checkDuplicates: Joi.object({
    hashes: Joi.array().items(
      Joi.string().pattern(/^[a-fA-F0-9]{64}$/)
    ).min(1).max(100).required(),
  }),

  tosSignature: Joi.object({
    fileName: Joi.string().max(255).required(),
    contentType: Joi.string().valid(
      'image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/heic', 'image/heif'
    ).required().messages({
      'any.only': '不支持的文件类型',
    }),
  }),

  listQuery: Joi.object({
    page: Joi.number().integer().min(1).optional().default(1),
    pageSize: Joi.number().integer().min(1).max(100).optional().default(20),
    orderBy: Joi.string().valid('createdAt', 'takenAt').optional().default('createdAt'),
    order: Joi.string().valid('ASC', 'DESC').optional().default('DESC'),
  }),
};

// ─── 家庭组 ────────────────────────────────────────────────

const families = {
  create: Joi.object({
    name: safeText(2, 20).required().messages({
      'string.min': '组名至少需要 2 个字',
      'string.max': '组名不能超过 20 个字',
    }),
  }),

  addMember: Joi.object({
    phone: phone().required(),
    role: Joi.string().valid('admin', 'member', 'guest').optional().default('member'),
  }),

  updatePermission: Joi.object({
    role: Joi.string().valid('admin', 'member', 'guest').optional(),
    permissions: Joi.array().items(
      Joi.string().valid('upload', 'delete', 'manage')
    ).optional(),
  }),
};

module.exports = { auth, photos, families };
