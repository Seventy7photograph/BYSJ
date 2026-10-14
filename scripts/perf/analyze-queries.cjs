/* 热点查询的 EXPLAIN ANALYZE 计时工具（无第三方依赖）。
 *
 * 用法：
 *   node scripts/perf/analyze-queries.cjs [库名] [标签]
 * 例：
 *   node scripts/perf/analyze-queries.cjs db_bysj_perf BEFORE
 *
 * 每条查询跑 5 次取中位数：单次 EXPLAIN ANALYZE 的读数很容易被冷缓存和
 * 后台刷盘干扰，用它下结论会得出错误的方向（实测过一次 52ms 的假回退）。
 */
const { execFileSync } = require('node:child_process')
const os = require('node:os')

const DB = process.argv[2] || 'db_bysj_perf'
const TAG = process.argv[3] || ''
const MYSQL = process.env.MYSQL_BIN || 'C:\\Program Files\\MySQL\\MySQL Server 8.0\\bin\\mysql.exe'
const USER = process.env.MYSQL_USER || 'root'
const PASSWORD = process.env.MYSQL_PWD || '123456'
const RUNS = Number(process.env.RUNS || 5)

/** 与后端 mapper 一致或近似的热点查询。 */
const QUERIES = [
  {
    name: '前台商品列表',
    sql: `SELECT p.product_id, CONCAT(b.brand_name,' ',p.model) AS name, p.price, p.stock, si.storage_path AS imageUrl
FROM product p
LEFT JOIN product_category pc ON p.category_id = pc.category_id
LEFT JOIN brand b ON p.brand = b.brand_id
LEFT JOIN sys_image si ON si.id = (
    SELECT pi.image_id FROM product_image pi
    WHERE pi.product_id = p.product_id AND pi.image_type = 'main'
    ORDER BY pi.sort ASC, pi.id ASC LIMIT 1
) AND si.is_deleted = 0
WHERE p.audit_status = 1 AND p.is_on_shelf = 1
ORDER BY p.create_time DESC, p.product_id DESC LIMIT 20`,
  },
  {
    name: '前台商品总数',
    sql: `SELECT COUNT(1) FROM product p WHERE p.audit_status = 1 AND p.is_on_shelf = 1`,
  },
  {
    name: '后台商品审核列表',
    sql: `SELECT p.product_id, p.model, b.brand_name
FROM product p LEFT JOIN brand b ON b.brand_id = p.brand
WHERE p.audit_status = 0 ORDER BY p.create_time DESC LIMIT 20`,
  },
  {
    name: '商家订单列表',
    sql: `SELECT o.order_id, o.order_no, o.pay_amount
FROM orders o WHERE o.seller_id = 7 ORDER BY o.create_time DESC LIMIT 10`,
  },
  {
    name: '买家订单列表',
    sql: `SELECT o.order_id FROM orders o WHERE o.user_id = 100 ORDER BY o.create_time DESC LIMIT 10`,
  },
  {
    name: '商家库存列表',
    sql: `SELECT i.id, i.product_name, i.current_stock
FROM inventory i JOIN product p ON p.product_id = i.product_id
WHERE p.seller_id = 7 ORDER BY i.current_stock ASC LIMIT 20`,
  },
  {
    name: '买家收藏列表',
    sql: `SELECT f.favorite_id, p.model
FROM favorite f JOIN product p ON f.product_id = p.product_id
WHERE f.user_id = 100 AND p.is_on_shelf = 1
ORDER BY f.create_time DESC LIMIT 12`,
  },
  {
    name: '消息列表',
    sql: `SELECT notice_id, content FROM sys_notice
WHERE user_id = 100 AND notice_status = 0 ORDER BY create_time DESC LIMIT 20`,
  },
  {
    name: '后台用户列表',
    sql: `SELECT u.user_id, u.username FROM user u
WHERE u.user_type = 1 AND u.status = 1 ORDER BY u.create_time DESC LIMIT 20`,
  },
  {
    name: '商品评价列表',
    sql: `SELECT e.eval_id, e.score FROM evaluation e
WHERE e.product_id = 100 ORDER BY e.create_time DESC LIMIT 10`,
  },
]

function runOnce(sql) {
  const out = execFileSync(MYSQL, [
    `--default-character-set=utf8mb4`, `-u`, USER, `-D`, DB, `-e`, `EXPLAIN ANALYZE ${sql}`,
  ], { env: { ...process.env, MYSQL_PWD: PASSWORD }, encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 })
  const m = /actual time=[\d.]+\.\.([\d.]+)/.exec(out)
  const plan = /-> ([^\n(]+)/.exec(out.replace(/\\n/g, '\n'))
  return { ms: m ? Number(m[1]) : NaN, head: plan ? plan[1].trim() : '?' }
}

function median(values) {
  const s = [...values].sort((a, b) => a - b)
  return s[Math.floor(s.length / 2)]
}

console.log(`库: ${DB}${TAG ? '  标签: ' + TAG : ''}   每条取 ${RUNS} 次中位数`)
console.log('-'.repeat(78))
const rows = []
for (const q of QUERIES) {
  const samples = []
  let head = ''
  for (let i = 0; i < RUNS; i++) {
    const r = runOnce(q.sql)
    if (!Number.isNaN(r.ms)) samples.push(r.ms)
    head = r.head
  }
  const ms = median(samples)
  rows.push({ name: q.name, ms, head })
  console.log(`${q.name.padEnd(16)} ${ms.toFixed(2).padStart(9)} ms   ${head.slice(0, 44)}`)
}
console.log('-'.repeat(78))
console.log(`合计: ${rows.reduce((s, r) => s + r.ms, 0).toFixed(2)} ms`)
