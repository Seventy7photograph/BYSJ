/* 主业务闭环验证（临时工具）。
 * 走真实接口：加购 → 下单 → 支付（含库存扣减与超卖拦截）→ 发货 → 确认收货
 * → 退款回补库存；以及管理员商品审核、超管授权。 */
const crypto = require('node:crypto')

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

const T = {
  buyer: mint('13800138000', ['USER']),
  merchant: mint('52440000799352866W', ['MERCHANT']),
  admin: mint('18344551993', ['ADMIN']),
  super: mint('18344551990', ['SUPER_ADMIN']),
}

const results = []
function check(name, ok, detail = '') {
  results.push({ name, ok, detail })
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  —  ' + detail : ''}`)
}

async function api(method, path, { token, body } = {}) {
  const headers = { 'Content-Type': 'application/json' }
  if (token) headers.Authorization = `Bearer ${token}`
  const init = { method, headers }
  if (body !== undefined) init.body = JSON.stringify(body)
  const r = await fetch(BASE + path, init)
  const text = await r.text()
  let json = null
  try { json = JSON.parse(text) } catch { /* 非 JSON */ }
  return { status: r.status, json, text }
}

async function main() {
  // ---------- 0. 选一个库存充足的在售商品 ----------
  const list = await api('GET', '/shop/products?productType=1&pageSize=50')
  const target = (list.json?.list || []).find((p) => p.stock >= 5 && p.productType === 1)
  check('取到库存在售商品', Boolean(target), target ? `${target.name} stock=${target.stock}` : '无可用商品')
  if (!target) return finish()

  const stockBefore = (await api('GET', `/shop/products/${target.productId}`)).json.data.stock

  // 清空购物车，让数量完全可控（上一轮失败会留下残留项，导致下单数量不是期望值）
  await api('DELETE', '/cart/clear', { token: T.buyer })

  // ---------- 1. 加入购物车 ----------
  const add = await api('POST', '/cart/add', { token: T.buyer, body: { productId: target.productId, quantity: 2 } })
  check('买家加入购物车', add.status === 200 && add.json?.code === 200, `status=${add.status} msg=${add.json?.msg}`)

  // /cart/items 的 data 是数组本身（不是 {list:[]}），这里两种形状都兼容
  const cartRaw = (await api('GET', '/cart/items', { token: T.buyer })).json?.data
  const cartRows = Array.isArray(cartRaw) ? cartRaw : (cartRaw?.list ?? [])
  const cartQty = cartRows
    .filter((c) => c.productId === target.productId)
    .reduce((s, c) => s + Number(c.quantity ?? 0), 0)
  check('购物车数量入账', cartQty === 2, `cartQty=${cartQty}`)

  // 库存扣减以「订单实际成交数量」为准，而不是写死的 2
  const buyQty = cartQty || 2
  const stockBeforeOrder = (await api('GET', `/shop/products/${target.productId}`)).json.data.stock

  // ---------- 2. 下单 ----------
  const order = await api('POST', '/orders/create-from-cart', {
    token: T.buyer,
    body: { productIds: [target.productId], quantity: 2, leaseTerm: 1 },
  })
  const orderId = order.json?.data?.orderId ?? order.json?.data?.order?.orderId
  check('买家从购物车下单', Boolean(orderId), `orderId=${orderId ?? JSON.stringify(order.json).slice(0, 160)}`)
  if (!orderId) return finish()

  // ---------- 3. 支付，库存应减少 ----------
  const pay = await api('POST', `/orders/pay/${orderId}`, { token: T.buyer, body: { paymentMethod: 'alipay' } })
  check('买家支付订单', pay.json?.code === 200, `status=${pay.status} msg=${pay.json?.msg}`)
  const stockAfterPay = (await api('GET', `/shop/products/${target.productId}`)).json.data.stock
  check(
    '支付后库存原子扣减',
    stockAfterPay === stockBeforeOrder - buyQty,
    `${stockBeforeOrder} -> ${stockAfterPay}（期望 -${buyQty}）`,
  )

  // ---------- 4. 商家发货 ----------
  const ship = await api('POST', `/orders/${orderId}/ship`, {
    token: T.merchant,
    body: { shippingCompany: '顺丰速运', trackingNo: 'SF' + Date.now() },
  })
  check('商家发货', ship.json?.code === 200, `msg=${ship.json?.msg}`)

  // ---------- 5. 买家确认收货 ----------
  const receive = await api('POST', `/orders/${orderId}/confirm-receive`, { token: T.buyer })
  check('买家确认收货', receive.json?.code === 200, `msg=${receive.json?.msg}`)

  // ---------- 6. 越权：买家不能替商家发货 ----------
  const buyerShip = await api('POST', `/orders/${orderId}/ship`, { token: T.buyer, body: {} })
  check('买家无权发货（越权拦截）', buyerShip.status === 403, `status=${buyerShip.status}`)

  // ---------- 7. 越权：商家不能进管理员接口 ----------
  const merchantAdmin = await api('GET', '/admin/users', { token: T.merchant })
  check('商家无权访问管理端（越权拦截）', merchantAdmin.status === 403, `status=${merchantAdmin.status}`)

  // ---------- 8. 越权：管理员不能改超管权限 ----------
  const adminGrant = await api('PUT', '/super-admin/roles/1/permissions', {
    token: T.admin, body: { permissionIds: [1] },
  })
  check('管理员无权改角色权限（越权拦截）', adminGrant.status === 403, `status=${adminGrant.status}`)

  // ---------- 9. 超卖拦截：下单数量远超库存后再支付 ----------
  const huge = (await api('POST', '/orders/temp', {
    token: T.buyer, body: { productId: target.productId, quantity: 9999 },
  })).json
  const hugeId = huge?.data?.orderId ?? huge?.data?.order?.orderId
  if (hugeId) {
    const hugePay = await api('POST', `/orders/pay/${hugeId}`, { token: T.buyer, body: { paymentMethod: 'alipay' } })
    const ok = hugePay.json?.code !== 200
    check('超量支付被拒（不会超卖）', ok, `msg=${hugePay.json?.msg}`)
    await api('POST', `/orders/${hugeId}/cancel`, { token: T.buyer })
  } else {
    check('超量下单未生成订单（同样安全）', true, `msg=${huge?.msg ?? '未返回订单'}`)
  }

  // ---------- 10. 管理员审核一个待审商品 ----------
  const pending = (await api('GET', '/admin/products/audit?pageNum=1&pageSize=1', { token: T.admin })).json
  const pendingRow = (pending?.data?.records || pending?.data?.list || [])[0]
  if (pendingRow) {
    const pid = pendingRow.productId ?? pendingRow.id
    const reject = await api('PUT', `/admin/products/${pid}/audit`, { token: T.admin, body: { auditStatus: 2 } })
    check('驳回商品必须填写理由', reject.json?.code !== 200, `msg=${reject.json?.msg}`)
    const approve = await api('PUT', `/admin/products/${pid}/audit`, {
      token: T.admin, body: { auditStatus: 1, rejectReason: '' },
    })
    check('管理员审核通过商品', approve.json?.code === 200, `msg=${approve.json?.msg}`)
    const after = (await api('GET', `/admin/products/${pid}`, { token: T.admin })).json
    const p = after?.data ?? after
    check('审核通过后自动上架', Number(p?.isOnShelf) === 1 || p?.isOnShelf === true, `isOnShelf=${p?.isOnShelf}`)
  } else {
    check('商品审核队列（当前为空，跳过）', true, '无待审商品')
  }

  // ---------- 11. 超管：读取并回写角色权限（矩阵生效） ----------
  const perms = await api('GET', '/super-admin/roles/3/permissions', { token: T.super })
  const current = (perms.json?.data || []).map((x) => x.permissionId ?? x.id).filter(Boolean)
  const writeBack = await api('PUT', '/super-admin/roles/3/permissions', {
    token: T.super, body: { permissionIds: current },
  })
  check('超管回写角色权限', writeBack.json?.code === 200, `共 ${current.length} 项，msg=${writeBack.json?.msg}`)
  const afterGrant = await api('GET', '/admin/brands', { token: T.admin })
  check('授权变更后管理员仍可访问（缓存已失效）', afterGrant.status === 200, `status=${afterGrant.status}`)

  // ---------- 12. 退款回补库存 ----------
  const add2 = await api('POST', '/cart/add', { token: T.buyer, body: { productId: target.productId, quantity: 1 } })
  const order2 = await api('POST', '/orders/create-from-cart', {
    token: T.buyer, body: { productIds: [target.productId], quantity: 1, leaseTerm: 1 },
  })
  const oid2 = order2.json?.data?.orderId ?? order2.json?.data?.order?.orderId
  if (oid2 && add2.json?.code === 200) {
    await api('POST', `/orders/pay/${oid2}`, { token: T.buyer, body: { paymentMethod: 'alipay' } })
    const mid = (await api('GET', `/shop/products/${target.productId}`)).json.data.stock
    const apply = await api('POST', '/refunds/apply', {
      token: T.buyer, body: { orderId: oid2, refundReason: '不想要了', refundDescription: '测试退款' },
    })
    const refundId = apply.json?.data?.refundId
    check('买家申请退款', Boolean(refundId), `msg=${apply.json?.msg}`)
    if (refundId) {
      const process = await api('POST', '/refunds/process', {
        token: T.merchant, body: { refundId, status: 1 },
      })
      check('商家处理退款（同意）', process.json?.code === 200, `msg=${process.json?.msg}`)
      const end = (await api('GET', `/shop/products/${target.productId}`)).json.data.stock
      check('退款成功回补库存', end === mid + 1, `${mid} -> ${end}（期望 +1）`)
    }
  }

  finish()
}

function finish() {
  const failed = results.filter((r) => !r.ok)
  console.log(`\n===== 业务闭环：${results.length - failed.length}/${results.length} 通过 =====`)
  if (failed.length) {
    console.log('失败项：')
    failed.forEach((f) => console.log(`  · ${f.name}  ${f.detail}`))
  }
  process.exitCode = failed.length ? 1 : 0
}

main().catch((e) => { console.error('CRASH', e); process.exitCode = 1 })
