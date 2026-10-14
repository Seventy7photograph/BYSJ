/* 权限矩阵审计（临时工具）。
 * 用四种角色的真实 JWT（项目自己的密钥签发）加匿名身份，逐一请求各区域接口，
 * 判定"是否越过了鉴权门"。判定规则：401/403 = 被拦；其它任何状态码 = 放行。
 * 对写接口一律使用不存在的 ID，确保即使放行也不会真的改数据。 */
const crypto = require('node:crypto')
const fs = require('node:fs')
const path = require('node:path')

const SECRET = 'defaultSecretKeyForDev12345678901234567890'
const BASE = 'http://127.0.0.1:9090'

const b64 = (b) => Buffer.from(b).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
function mint(username, roles) {
  const now = Math.floor(Date.now() / 1000)
  const h = b64(JSON.stringify({ alg: 'HS256' }))
  const p = b64(JSON.stringify({ sub: username, roles, iat: now, exp: now + 86400 }))
  const d = `${h}.${p}`
  return `${d}.${b64(crypto.createHmac('sha256', SECRET).update(d).digest())}`
}

const IDENTITIES = [
  { key: 'anon', label: '匿名', token: null },
  { key: 'user', label: '买家', token: mint('13800138000', ['USER']) },
  { key: 'merchant', label: '商家', token: mint('52440000799352866W', ['MERCHANT']) },
  { key: 'admin', label: '管理员', token: mint('18344551993', ['ADMIN']) },
  { key: 'super', label: '超级管理员', token: mint('18344551990', ['SUPER_ADMIN']) },
]

// area: 该接口属于哪个区域；expect.allow 列出"应当放行"的角色
/*
 * 期望模型（超管持有根权限 SYSTEM_ROOT「/  *」，因此所有区域都放行；
 * 管理员是平台运营角色，不是买家，所以不拥有购物车/收藏/评价这些自有数据接口）：
 */
const CASES = [
  // 公开区域
  { m: 'GET', p: '/shop/products?pageSize=1', area: '公开-商城', allow: ['anon', 'user', 'merchant', 'admin', 'super'] },
  { m: 'GET', p: '/shop/categories', area: '公开-商城', allow: ['anon', 'user', 'merchant', 'admin', 'super'] },
  { m: 'GET', p: '/captcha', area: '公开-认证', allow: ['anon', 'user', 'merchant', 'admin', 'super'] },

  // 买家区域
  { m: 'GET', p: '/cart/items', area: '买家-购物车', allow: ['user', 'merchant', 'super'] },
  { m: 'GET', p: '/favorites', area: '买家-收藏', allow: ['user', 'merchant', 'super'] },
  { m: 'GET', p: '/user/addresses', area: '买家-地址', allow: ['user', 'merchant', 'super'] },
  { m: 'GET', p: '/user/profile', area: '通用-个人资料', allow: ['user', 'merchant', 'admin', 'super'] },
  { m: 'GET', p: '/orders/list', area: '买家-订单', allow: ['user', 'merchant', 'super'] },
  { m: 'GET', p: '/message/list', area: '通用-消息', allow: ['user', 'merchant', 'super'] },
  // 管理员不是买家：没有购物车/收藏/评价自有数据，被拦是正确行为
  { m: 'GET', p: '/evaluations/user', area: '买家-评价', allow: ['user', 'merchant', 'super'] },
  { m: 'POST', p: '/files/upload', area: '通用-上传', allow: ['user', 'merchant', 'admin', 'super'] },

  // 商家区域
  { m: 'GET', p: '/merchant/product/list', area: '商家-商品', allow: ['merchant', 'super'] },
  { m: 'GET', p: '/merchant/inventory', area: '商家-库存', allow: ['merchant', 'super'] },
  { m: 'GET', p: '/merchant/shop/info', area: '商家-店铺', allow: ['merchant', 'super'] },
  { m: 'GET', p: '/merchant/shop/dashboard', area: '商家-看板', allow: ['merchant', 'super'] },
  { m: 'PUT', p: '/merchant/product/999999/status?status=1', area: '商家-商品', allow: ['merchant', 'super'] },
  { m: 'POST', p: '/orders/999999/ship', area: '商家-发货', allow: ['merchant', 'super'] },
  { m: 'GET', p: '/refunds/merchant/list', area: '商家-退款', allow: ['merchant', 'super'] },

  // 管理员区域
  { m: 'GET', p: '/admin/dashboard', area: '管理员-看板', allow: ['admin', 'super'] },
  { m: 'GET', p: '/admin/users', area: '管理员-用户', allow: ['admin', 'super'] },
  { m: 'GET', p: '/admin/merchants', area: '管理员-商家', allow: ['admin', 'super'] },
  { m: 'GET', p: '/admin/merchants/audit', area: '管理员-商家审核', allow: ['admin', 'super'] },
  { m: 'GET', p: '/admin/products/audit', area: '管理员-商品审核', allow: ['admin', 'super'] },
  { m: 'PUT', p: '/admin/products/999999/audit', area: '管理员-商品审核', allow: ['admin', 'super'] },
  { m: 'PUT', p: '/admin/merchants/999999/audit', area: '管理员-商家审核', allow: ['admin', 'super'] },
  { m: 'GET', p: '/admin/categories/tree', area: '管理员-分类', allow: ['admin', 'super'] },
  { m: 'GET', p: '/admin/brands', area: '管理员-品牌', allow: ['admin', 'super'] },
  { m: 'GET', p: '/admin/notices', area: '管理员-公告', allow: ['admin', 'super'] },
  { m: 'GET', p: '/admin/operations', area: '管理员-日志', allow: ['admin', 'super'] },
  { m: 'PUT', p: '/admin/users/999999/status?status=0', area: '管理员-用户', allow: ['admin', 'super'] },
  { m: 'DELETE', p: '/admin/users/999999', area: '管理员-用户', allow: ['admin', 'super'] },

  // 超级管理员区域 —— 这里最需要确认越权被拦住
  { m: 'GET', p: '/super-admin/admins', area: '超管-账号', allow: ['super'] },
  { m: 'POST', p: '/super-admin/admins', area: '超管-账号', allow: ['super'] },
  { m: 'GET', p: '/super-admin/permissions', area: '超管-权限', allow: ['super'] },
  { m: 'POST', p: '/super-admin/permissions', area: '超管-权限', allow: ['super'] },
  { m: 'DELETE', p: '/super-admin/permissions/999999', area: '超管-权限', allow: ['super'] },
  { m: 'GET', p: '/super-admin/roles', area: '超管-角色', allow: ['super'] },
  { m: 'PUT', p: '/super-admin/roles/1/permissions', area: '超管-授权', allow: ['super'] },
  { m: 'DELETE', p: '/super-admin/roles/999999', area: '超管-角色', allow: ['super'] },
]

async function probe(identity, c) {
  const headers = { 'Content-Type': 'application/json' }
  if (identity.token) headers.Authorization = `Bearer ${identity.token}`
  const init = { method: c.m, headers }
  if (c.m === 'POST' || c.m === 'PUT') init.body = JSON.stringify({ permissionIds: [], status: 1, auditStatus: 0 })
  try {
    const r = await fetch(BASE + c.p, init)
    return r.status
  } catch (e) {
    return -1
  }
}

async function main() {
  const rows = []
  const holes = []
  for (const c of CASES) {
    const actual = {}
    for (const id of IDENTITIES) actual[id.key] = await probe(id, c)
    const allowed = IDENTITIES.filter((i) => actual[i.key] !== 401 && actual[i.key] !== 403).map((i) => i.key)
    const leaked = allowed.filter((k) => !c.allow.includes(k))
    rows.push({ ...c, actual, enabled: allowed, leaked })
    if (leaked.length) holes.push(`${c.area} ${c.m} ${c.p}  ->  ${leaked.join(', ')} 也放行了`)
  }

  const pad = (s, n) => String(s).padEnd(n)
  console.log(pad('区域', 16) + pad('方法', 7) + pad('接口', 40) + IDENTITIES.map((i) => pad(i.label, 7)).join(''))
  for (const r of rows) {
    console.log(
      pad(r.area, 16) + pad(r.m, 7) + pad(r.p.split('?')[0].slice(0, 38), 40) +
      IDENTITIES.map((i) => pad(r.actual[i.key], 7)).join(''),
    )
  }
  console.log('\n=== 越权（不该放行却放行了）===')
  console.log(holes.length ? holes.join('\n') : '无')
  console.log('\n=== 过严（应当放行却被拦）===')
  const tooStrict = []
  for (const r of rows) {
    for (const k of r.allow) {
      const st = r.actual[k]
      if (st === 401 || st === 403) tooStrict.push(`${r.area} ${r.m} ${r.p}  ->  ${k} 被拦(${st})`)
    }
  }
  console.log(tooStrict.length ? tooStrict.join('\n') : '无')
  fs.writeFileSync(path.join(__dirname, 'perm-matrix.json'), JSON.stringify(rows, null, 2), 'utf8')
}

main()
