/**
 * XSS攻击防护工具函数
 * 实现对用户输入的XSS攻击检测和防护
 */

/**
 * 检测输入是否包含XSS风险
 * @param {string} input - 用户输入
 * @returns {boolean} - 是否包含XSS风险
 */
export function containsXss(input) {
  if (!input || typeof input !== 'string') {
    return false;
  }
  const xssPattern = /<script[\s\S]*?<\/script>|<iframe[\s\S]*?<\/iframe>|<object[\s\S]*?<\/object>|<embed[\s\S]*?<\/embed>|<link[\s\S]*?<\/link>|<style[\s\S]*?<\/style>|<meta[\s\S]*?>|javascript:|vbscript:|onload=|onerror=|onclick=|onmouseover=|onmouseout=|onkeydown=|onkeyup=|onchange=|onfocus=|onblur=/i;
  const match = xssPattern.test(input);
  if (match) {
    console.warn('检测到XSS攻击风险输入:', input);
  }
  return match;
}

/**
 * 过滤XSS风险字符
 * @param {string} input - 用户输入
 * @returns {string} - 过滤后的输入
 */
export function filterXss(input) {
  if (!input || typeof input !== 'string') {
    return input;
  }
  // 替换危险字符
  let filtered = input
    .replace(/<script[\s\S]*?<\/script>/gi, '')
    .replace(/<iframe[\s\S]*?<\/iframe>/gi, '')
    .replace(/<object[\s\S]*?<\/object>/gi, '')
    .replace(/<embed[\s\S]*?<\/embed>/gi, '')
    .replace(/<link[\s\S]*?<\/link>/gi, '')
    .replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<meta[\s\S]*?>/gi, '')
    .replace(/javascript:/gi, '')
    .replace(/vbscript:/gi, '')
    .replace(/onload=/gi, '')
    .replace(/onerror=/gi, '')
    .replace(/onclick=/gi, '')
    .replace(/onmouseover=/gi, '')
    .replace(/onmouseout=/gi, '')
    .replace(/onkeydown=/gi, '')
    .replace(/onkeyup=/gi, '')
    .replace(/onchange=/gi, '')
    .replace(/onfocus=/gi, '')
    .replace(/onblur=/gi, '');

  if (input !== filtered) {
    console.info('过滤XSS攻击风险输入:', input, '->', filtered);
  }
  return filtered;
}

/**
 * HTML转义，防止XSS攻击
 * @param {string} input - 用户输入
 * @returns {string} - 转义后的输入
 */
export function escapeHtml(input) {
  if (!input || typeof input !== 'string') {
    return input;
  }
  return input
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/'/g, '&#39;')
    .replace(/"/g, '&quot;');
}

/**
 * 清理和验证输入，防止XSS攻击
 * @param {string} input - 用户输入
 * @param {number} maxLength - 最大长度
 * @returns {string} - 清理后的输入
 */
export function sanitizeInput(input, maxLength) {
  if (!input || typeof input !== 'string') {
    return input;
  }
  // 截断过长的输入
  if (input.length > maxLength) {
    input = input.substring(0, maxLength);
    console.info('截断过长输入，长度:', input.length, '->', maxLength);
  }
  // 过滤XSS风险
  input = filterXss(input);
  // HTML转义
  return escapeHtml(input);
}

/**
 * 验证输入是否安全
 * @param {string} input - 用户输入
 * @param {number} maxLength - 最大长度
 * @returns {boolean} - 是否安全
 */
export function isValidInput(input, maxLength) {
  if (!input || typeof input !== 'string') {
    return true;
  }
  if (input.length > maxLength) {
    console.warn('输入长度超过限制:', input.length, '(最大长度:', maxLength, ')');
    return false;
  }
  if (containsXss(input)) {
    return false;
  }
  return true;
}
