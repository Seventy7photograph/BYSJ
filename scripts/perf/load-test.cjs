/* 接口压测工具（无第三方依赖，用 Node 内置 fetch 与 crypto）。
 *
 * 用法：
 *   node scripts/perf/load-test.cjs [baseUrl] [并发数] [时长秒]
 * 例：
 *   node scripts/perf/load-test.cjs http://127.0.0.1:9091 20 15
 *
 * 混合了公共接口与一个需要登录的接口，尽量贴近真实浏览行为：
 * 列表页、筛选、详情页、分类、相关推荐，以及「我的订单」。
 * 令牌用项目自己的 JWT 密钥现场签发，不需要账号密码。
 */
const crypto = require('node:crypto')

const BASE = process.argv[2] || 'http://127.0.0.1:9090'
const CONCURRENCY = Number(process.argv[3] || 20)
const DURATION_S = Number(process.argv[4] || 15)
const SECRET = process.env.JWT_SECRET || 'defaultSecretKeyForDev12345678901234567890'
const PERF_USER = process.env.PERF_USER || 'perf_000100'

const b64 = (b) => Buffer.from(b).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
function mint(username, roles) {
  const now = Math.floor(Date.now() / 1000)
  const h = b64(JSON.stringify({ alg: 'HS256' }))
  const p = b64(JSON.stringify({ sub: username, roles, iat: now, exp: now + 3600 }))
  const d = `${h}.${p}`
  return `${d}.${b64(crypto.createHmac('sha256', SECRET).update(d).digest())}`
}

const TOKEN = mint(PERF_USER, ['USER'])

/** 带权重的请求混合。权重按「一次浏览里各类请求出现的大致比例」估。 */
const MIX = [
  { w: 30, path: () => `/shop/products?pageSize=20&pageNum=${1 + (Math.random() * 50 | 0)}`, auth: false },
  { w: 15, path: () => `/shop/products?productType=1&sort=price_asc&pageSize=20`, auth: false },
  { w: 10, path: () => `/shop/products?category=CAM&pageSize=20`, auth: false },
  { w: 10, path: () => `/shop/products?keyword=PERF-0001&pageSize=20`, auth: false },
  { w: 15, path: () => `/shop/products/${1 + (Math.random() * 20000 | 0)}`, auth: false },
  { w: 5, path: () => `/shop/categories`, auth: false },
  { w: 5, path: () => `/shop/related?categoryId=11&productId=${1 + (Math.random() * 20000 | 0)}&limit=8`, auth: false },
  { w: 10, path: () => `/orders/list?pageNum=1&pageSize=10`, auth: true },
]
const TOTAL_WEIGHT = MIX.reduce((s, m) => s + m.w, 0)

function pick() {
  let r = Math.random() * TOTAL_WEIGHT
  for (const m of MIX) {
    r -= m.w
    if (r <= 0) return m
  }
  return MIX[0]
}

const latencies = []
const statusCount = new Map()
let ok = 0
let failed = 0
let stopAt = 0

async function worker() {
  while (Date.now() < stopAt) {
    const m = pick()
    const headers = {}
    if (m.auth) headers.Authorization = `Bearer ${TOKEN}`
    const t0 = process.hrtime.bigint()
    try {
      const res = await fetch(BASE + m.path(), { headers })
      // 必须读完 body，否则连接不会及时释放，测出来的数字会虚高
      const body = await res.text()
      const ms = Number(process.hrtime.bigint() - t0) / 1e6
      latencies.push(ms)
      statusCount.set(res.status, (statusCount.get(res.status) || 0) + 1)
      // 业务层错误：HTTP 200 但 code != 200。
      // 注意 /shop/products 这类接口直接返回裸 Map，没有 code 字段，
      // 所以这里必须用 == null 同时覆盖 null 与 undefined。
      let code
      if (body.startsWith('{')) {
        try { code = JSON.parse(body).code } catch { /* 非 JSON 响应 */ }
      }
      if (res.status === 200 && (code == null || code === 200)) ok++
      else failed++
    } catch {
      const ms = Number(process.hrtime.bigint() - t0) / 1e6
      latencies.push(ms)
      failed++
      statusCount.set('ERR', (statusCount.get('ERR') || 0) + 1)
    }
  }
}

function pct(sorted, p) {
  if (!sorted.length) return 0
  const i = Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length))
  return sorted[i]
}

async function main() {
  console.log(`压测目标 ${BASE}  并发 ${CONCURRENCY}  时长 ${DURATION_S}s`)
  // 预热：让 JIT、连接池、数据库缓存进入稳态，否则前几秒的数字没意义
  await fetch(BASE + '/shop/products?pageSize=1').then((r) => r.text())

  stopAt = Date.now() + DURATION_S * 1000
  const t0 = Date.now()
  await Promise.all(Array.from({ length: CONCURRENCY }, () => worker()))
  const elapsed = (Date.now() - t0) / 1000

  const sorted = [...latencies].sort((a, b) => a - b)
  const total = latencies.length
  console.log('-'.repeat(60))
  console.log(`总请求      ${total}`)
  console.log(`成功 / 失败 ${ok} / ${failed}`)
  console.log(`吞吐        ${(total / elapsed).toFixed(1)} req/s`)
  console.log(`平均延迟    ${(sorted.reduce((a, b) => a + b, 0) / total).toFixed(2)} ms`)
  console.log(`p50 / p90   ${pct(sorted, 50).toFixed(2)} / ${pct(sorted, 90).toFixed(2)} ms`)
  console.log(`p99 / max   ${pct(sorted, 99).toFixed(2)} / ${sorted[sorted.length - 1].toFixed(2)} ms`)
  console.log(`状态码      ${[...statusCount.entries()].map(([k, v]) => `${k}:${v}`).join('  ')}`)
  console.log('-'.repeat(60))
  if (failed > 0) process.exitCode = 1
}

main().catch((e) => { console.error('压测失败', e); process.exitCode = 1 })
