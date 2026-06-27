/**
 * 输入清理工具
 *
 * 防御措施：
 *   1. 去除控制字符（\x00-\x1f, \x7f）
 *   2. 去除 Unicode 双向文本覆盖字符（防止 bidi 攻击）
 *   3. 去除 HTML 标签（防止存储型 XSS，即使 Flutter 端不渲染 HTML）
 *   4. 压缩多余空白
 *   5. trim
 */

const HTML_TAG_RE = /<[^>]*>/g;
const CONTROL_CHARS_RE = /[\x00-\x09\x0b\x0c\x0e-\x1f\x7f]/g;
const BIDI_OVERRIDE_RE = /[‎‏‪-‮⁦-⁩]/g;
const MULTI_SPACE_RE = /\s{2,}/g;

/**
 * 清理单个字符串
 * @param {string|null|undefined} str
 * @returns {string} 清理后的字符串，null/undefined 返回 ''
 */
const clean = (str) => {
  if (str == null) return '';
  return String(str)
    .replace(CONTROL_CHARS_RE, '')
    .replace(BIDI_OVERRIDE_RE, '')
    .replace(HTML_TAG_RE, '')
    .replace(MULTI_SPACE_RE, ' ')
    .trim();
};

/**
 * 清理字符串数组中的每个元素
 * @param {Array|null|undefined} arr
 * @returns {Array<string>}
 */
const cleanArray = (arr) => {
  if (!Array.isArray(arr)) return [];
  return arr.map(clean).filter(Boolean);
};

module.exports = { clean, cleanArray };
