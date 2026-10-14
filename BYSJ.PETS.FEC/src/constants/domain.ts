/**
 * 领域字典：状态码 → 文案 + 色调。
 *
 * 这些映射原本散布在 20 多个页面里各写一份，数值含义一旦变动就会漂移。
 * 后端真相来源：
 *   OrderStatus.java  — 订单状态 0..9
 *   UserType.java     — 用户/角色类型 1..4
 *   product 表        — product_type / audit_status / is_on_shelf / condition
 */

/** 状态色调，对应 base.css 里的 .pill--* 变体。 */
export type Tone = 'neutral' | 'teal' | 'amber' | 'vermilion' | 'outline'

export interface StateLabel {
  label: string
  tone: Tone
}

/** 商品类型：1 全新零售 / 2 二手 / 3 租赁。 */
export const PRODUCT_TYPE = {
  1: { label: '全新', tone: 'neutral' },
  2: { label: '二手', tone: 'amber' },
  3: { label: '租赁', tone: 'teal' },
} as const satisfies Record<number, StateLabel>

export type ProductTypeCode = keyof typeof PRODUCT_TYPE

/** 平台审核状态。 */
export const AUDIT_STATUS = {
  0: { label: '待审核', tone: 'amber' },
  1: { label: '已通过', tone: 'teal' },
  2: { label: '已驳回', tone: 'vermilion' },
} as const satisfies Record<number, StateLabel>

export type AuditStatusCode = keyof typeof AUDIT_STATUS

/** 上架状态，取自 product.is_on_shelf。 */
export const SHELF_STATUS = {
  0: { label: '未上架', tone: 'outline' },
  1: { label: '已上架', tone: 'teal' },
} as const satisfies Record<number, StateLabel>

/** 订单状态，取自 OrderStatus 枚举，0..9。 */
export const ORDER_STATUS = {
  0: { label: '待支付', tone: 'amber' },
  1: { label: '已支付', tone: 'teal' },
  2: { label: '已发货', tone: 'teal' },
  3: { label: '已完成', tone: 'neutral' },
  4: { label: '已取消', tone: 'outline' },
  5: { label: '退款处理中', tone: 'amber' },
  6: { label: '退款成功', tone: 'vermilion' },
  7: { label: '退款失败', tone: 'vermilion' },
  8: { label: '租赁中', tone: 'teal' },
  9: { label: '归还中', tone: 'amber' },
} as const satisfies Record<number, StateLabel>

export type OrderStatusCode = keyof typeof ORDER_STATUS

/** 订单状态分组，用于「我的订单 / 订单管理」的标签页。 */
export const ORDER_STATUS_GROUP = {
  all: { label: '全部', codes: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] },
  unpaid: { label: '待支付', codes: [0] },
  toShip: { label: '待发货', codes: [1] },
  toReceive: { label: '待收货', codes: [2] },
  renting: { label: '租赁中', codes: [8, 9] },
  afterSale: { label: '退款/售后', codes: [5, 6, 7] },
  done: { label: '已完成', codes: [3] },
  cancelled: { label: '已取消', codes: [4] },
} as const

export type OrderStatusGroupKey = keyof typeof ORDER_STATUS_GROUP

/** 用户与角色类型，取自 UserType 枚举。 */
export const USER_TYPE = {
  1: { label: '普通用户', tone: 'neutral' },
  2: { label: '商家', tone: 'teal' },
  3: { label: '管理员', tone: 'amber' },
  4: { label: '超级管理员', tone: 'vermilion' },
} as const satisfies Record<number, StateLabel>

/** 账号启用状态，取自 user.status。 */
export const ACCOUNT_STATUS = {
  0: { label: '已停用', tone: 'vermilion' },
  1: { label: '正常', tone: 'teal' },
} as const satisfies Record<number, StateLabel>

/**
 * 店铺状态，取自 user.shop_status。
 *
 * 口径以数据库注释为准：0 关闭 / 1 正常 / 2 审核中。
 * 之前这里按「0 待审、2 驳回」写，会把整个待审队列渲染成"已驳回"。
 */
export const SHOP_STATUS = {
  0: { label: '已停业', tone: 'outline' },
  1: { label: '营业中', tone: 'teal' },
  2: { label: '审核中', tone: 'amber' },
} as const satisfies Record<number, StateLabel>

/**
 * 成色：product.condition 存的是 0..100 的成色百分比（95 即「95新」）。
 * 二手与租赁商品才有值，全新商品为 null。
 */
export function conditionLabel(value: number | null | undefined): string | null {
  if (value === null || value === undefined) return null
  if (value >= 99) return '99新'
  if (value >= 95) return '95新'
  if (value >= 90) return '90新'
  if (value >= 80) return '8成新'
  if (value >= 70) return '7成新'
  return '有使用痕迹'
}

/** 通用查表：未知编码回退为中性文案，绝不抛错。 */
export function labelOf(
  table: Record<number, StateLabel>,
  code: number | null | undefined,
  fallback = '未知',
): StateLabel {
  if (code === null || code === undefined) return { label: fallback, tone: 'neutral' }
  return table[code] ?? { label: fallback, tone: 'neutral' }
}
