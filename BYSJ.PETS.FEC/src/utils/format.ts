/**
 * 展示层格式化。金额、日期、库存、图片地址在各页面重复实现了太多次，
 * 这里收敛成唯一实现，保证同一个数字在全站只有一种呈现。
 */

/** 商品图缺失时的占位图，见 public/images/placeholder-product.svg。 */
export const IMAGE_PLACEHOLDER = '/images/placeholder-product.svg'

/**
 * 把后端返回的图片路径解析成浏览器可用的 URL。
 * 后端存的是根相对路径（/images/x.png、/head/x.png），可以直接使用；
 * 完整 URL 与 data URI 原样透传。
 */
export function resolveImageUrl(path?: string | null, fallback = IMAGE_PLACEHOLDER): string {
  if (!path || !path.trim()) return fallback
  const value = path.trim()
  if (/^(https?:)?\/\//i.test(value) || value.startsWith('data:')) return value
  return value.startsWith('/') ? value : `/${value}`
}

/**
 * 金额。整数不带小数，非整数保留两位并补足千分位。
 *   16999      -> ¥16,999
 *   120.5      -> ¥120.50
 *   null       -> —
 */
export function formatMoney(value: number | string | null | undefined): string {
  if (value === null || value === undefined || value === '') return '—'
  const num = Number(value)
  if (!Number.isFinite(num)) return '—'
  const hasFraction = Math.round(num * 100) % 100 !== 0
  return `¥${num.toLocaleString('zh-CN', {
    minimumFractionDigits: hasFraction ? 2 : 0,
    maximumFractionDigits: hasFraction ? 2 : 0,
  })}`
}

/** 只要数字部分，供 <PriceTag> 自己拆符号与数额。 */
export function formatAmount(value: number | string | null | undefined): string {
  return formatMoney(value).replace(/^¥/, '')
}

/** 库存。负数在业务上是错的，显示时明确标出来而不是假装正常。 */
export function formatStock(value: number | null | undefined): string {
  if (value === null || value === undefined) return '—'
  if (value < 0) return '库存异常'
  return `${value} 件`
}

/** 「剩余 N 件」——低于安全库存时补一句，不靠颜色单独传达。 */
export function stockNote(
  stock: number | null | undefined,
  minStock?: number | null,
): { text: string; low: boolean; out: boolean } {
  if (stock === null || stock === undefined) return { text: '库存未知', low: false, out: false }
  if (stock <= 0) return { text: '已售完', low: false, out: true }
  const low = minStock !== null && minStock !== undefined && stock <= minStock
  return { text: `剩余 ${stock} 件`, low, out: false }
}

/** 折扣：仅在确实更便宜时返回，例如「6.6 折」。 */
export function discountLabel(
  price: number | null | undefined,
  originalPrice: number | null | undefined,
): string | null {
  if (!price || !originalPrice || originalPrice <= price) return null
  const ratio = (Number(price) / Number(originalPrice)) * 10
  if (ratio >= 9.95) return null
  return `${ratio.toFixed(1).replace(/\.0$/, '')} 折`
}

const pad = (n: number) => String(n).padStart(2, '0')

/** 后端返回 'YYYY-MM-DD HH:mm:ss' 或 ISO 串，统一成展示格式。 */
function toDate(value: string | number | Date | null | undefined): Date | null {
  if (value === null || value === undefined || value === '') return null
  if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value
  const normalised = typeof value === 'string' ? value.replace(' ', 'T') : value
  const d = new Date(normalised)
  return Number.isNaN(d.getTime()) ? null : d
}

/** 2026-04-10 18:22 */
export function formatDateTime(value: string | number | Date | null | undefined): string {
  const d = toDate(value)
  if (!d) return '—'
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}

/** 2026-04-10 */
export function formatDate(value: string | number | Date | null | undefined): string {
  const d = toDate(value)
  if (!d) return '—'
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

/** 刚刚 / 12 分钟前 / 3 小时前 / 2 天前 / 2026-04-10 */
export function formatRelative(value: string | number | Date | null | undefined): string {
  const d = toDate(value)
  if (!d) return '—'
  const diff = Date.now() - d.getTime()
  if (diff < 0) return formatDateTime(d)
  const min = Math.floor(diff / 60000)
  if (min < 1) return '刚刚'
  if (min < 60) return `${min} 分钟前`
  const hour = Math.floor(min / 60)
  if (hour < 24) return `${hour} 小时前`
  const day = Math.floor(hour / 24)
  if (day < 30) return `${day} 天前`
  return formatDate(d)
}

/** 租期天数 → 「3 天」，用于租赁商品的计价单位。 */
export function rentalUnit(days: number | null | undefined): string {
  const n = Number(days)
  return Number.isFinite(n) && n > 0 ? `${n} 天起租` : '按天计价'
}

/** 手机号脱敏：183****1990 */
export function maskPhone(phone?: string | null): string {
  if (!phone) return '—'
  const v = String(phone).trim()
  if (v.length < 7) return v
  return `${v.slice(0, 3)}****${v.slice(-4)}`
}

/** 订单号等长串截断，避免撑破表格列。 */
export function truncateMiddle(value?: string | null, head = 6, tail = 4): string {
  if (!value) return '—'
  const v = String(value)
  if (v.length <= head + tail + 3) return v
  return `${v.slice(0, head)}…${v.slice(-tail)}`
}
