/* 端到端验收脚本（临时工具，不属于项目源码）。
 * 用项目自己的 JWT 密钥为四种角色各签一个令牌，注入 localStorage 后逐页截图，
 * 同时收集控制台错误、页面异常与 HTTP >= 400 的请求。 */
const crypto = require('node:crypto')
const fs = require('node:fs')
const path = require('node:path')
// 浏览器驱动复用前端工程的依赖，避免在仓库根再装一份
const nodePath = require('node:path')
const { chromium } = require(nodePath.join(__dirname, '..', 'BYSJ.PETS.FEC', 'node_modules', '@playwright', 'test'))

const SECRET = 'defaultSecretKeyForDev12345678901234567890'
const BASE = process.env.BASE_URL || 'http://127.0.0.1:5173'
const OUT = path.join(__dirname, 'shots')

function b64url(buf) {
  return Buffer.from(buf).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

function mint(username, roles) {
  const now = Math.floor(Date.now() / 1000)
  const header = b64url(JSON.stringify({ alg: 'HS256' }))
  const payload = b64url(JSON.stringify({ sub: username, roles, iat: now, exp: now + 86400 }))
  const data = `${header}.${payload}`
  const sig = b64url(crypto.createHmac('sha256', SECRET).update(data).digest())
  return `${data}.${sig}`
}

const ROLES = {
  buyer: {
    username: '13800138000',
    roles: ['USER'],
    label: '买家',
    routes: ['/index', '/shop', '/product/1', '/rental', '/second-hand', '/cart', '/orders', '/favorites', '/address', '/profile', '/messages'],
  },
  merchant: {
    username: '52440000799352866W',
    roles: ['MERCHANT'],
    label: '商家',
    routes: ['/merchant-dashboard', '/merchant-dashboard/product-management', '/merchant-dashboard/inventory-management', '/merchant-dashboard/order-management', '/merchant-dashboard/shop-management', '/merchant-dashboard/profile'],
  },
  admin: {
    username: '18344551993',
    roles: ['ADMIN'],
    label: '管理员',
    routes: ['/admin-dashboard', '/admin-dashboard/merchant-audit', '/admin-dashboard/product-audit', '/admin-dashboard/user-management', '/admin-dashboard/category-management', '/admin-dashboard/notice-publish'],
  },
  superadmin: {
    username: '18344551990',
    roles: ['SUPER_ADMIN'],
    label: '超级管理员',
    routes: ['/super-admin-dashboard', '/super-admin-dashboard/admin-management', '/super-admin-dashboard/permission-list', '/super-admin-dashboard/dynamic-permission'],
  },
}

async function run() {
  fs.mkdirSync(OUT, { recursive: true })
  const browser = await chromium.launch({ channel: 'msedge' })
  const report = []

  for (const [key, role] of Object.entries(ROLES)) {
    const token = mint(role.username, role.roles)
    const ctx = await browser.newContext({ viewport: { width: 1440, height: 950 } })
    const page = await ctx.newPage()
    const problems = []

    page.on('console', (m) => {
      if (m.type() === 'error') problems.push(`console: ${m.text().slice(0, 160)}`)
    })
    page.on('pageerror', (e) => problems.push(`pageerror: ${String(e).slice(0, 160)}`))
    page.on('response', (r) => {
      if (r.status() >= 400 && r.url().includes('/api/')) problems.push(`http ${r.status()} ${r.url().slice(-70)}`)
    })

    await ctx.addInitScript(
      ([t, info]) => {
        localStorage.setItem('token', t)
        localStorage.setItem('userInfo', info)
      },
      [token, JSON.stringify({ username: role.username })],
    )

    for (const route of role.routes) {
      problems.length = 0
      await page.goto(BASE + route, { waitUntil: 'networkidle', timeout: 45000 }).catch(() => {})
      await page.waitForTimeout(700)
      const name = `${key}${route.replace(/\//g, '_')}`
      await page.screenshot({ path: path.join(OUT, `${name}.png`), fullPage: false })
      const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth)
      const title = await page.title()
      const bodyLen = (await page.evaluate(() => document.body.innerText)).replace(/\s+/g, ' ').length
      report.push({ role: role.label, route, title, overflowX: overflow, textLen: bodyLen, problems: [...new Set(problems)] })
    }
    await ctx.close()
  }

  // 移动端抽查
  const mCtx = await browser.newContext({ viewport: { width: 390, height: 844 }, isMobile: true })
  const mPage = await mCtx.newPage()
  await mCtx.addInitScript(
    ([t, info]) => {
      localStorage.setItem('token', t)
      localStorage.setItem('userInfo', info)
    },
    [mint('13800138000', ['USER']), JSON.stringify({ username: '13800138000' })],
  )
  for (const route of ['/index', '/shop', '/orders']) {
    await mPage.goto(BASE + route, { waitUntil: 'networkidle', timeout: 45000 }).catch(() => {})
    await mPage.waitForTimeout(600)
    const overflow = await mPage.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth)
    await mPage.screenshot({ path: path.join(OUT, `mobile${route.replace(/\//g, '_')}.png`) })
    report.push({ role: '买家(移动端)', route, title: '', overflowX: overflow, textLen: 0, problems: [] })
  }
  await mCtx.close()
  await browser.close()

  fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2), 'utf8')
  let bad = 0
  for (const r of report) {
    const flag = r.problems.length || r.overflowX > 1 ? '  <-- 有情况' : ''
    if (flag) bad++
    console.log(`${r.role} ${r.route} overflowX=${r.overflowX} text=${r.textLen}${flag}`)
    r.problems.slice(0, 4).forEach((p) => console.log(`      ${p}`))
  }
  console.log(`\n有情况的页面: ${bad}/${report.length}`)
}

run().catch((e) => {
  console.error('FAILED', e)
  process.exit(1)
})
