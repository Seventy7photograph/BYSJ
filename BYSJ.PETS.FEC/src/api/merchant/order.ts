import axios from '@/axios'

/**
 * 商家订单接口。订单本体仍走同一组 OrderController 映射：
 *   GET  /orders/list?type&status&orderNo&pageNum&pageSize
 *   GET  /orders/{orderId}
 *   POST /orders/{orderId}/ship            商家发货
 *   POST /orders/{orderId}/confirm-return  商家确认归还
 *   GET  /refunds/merchant/list            本店退款列表
 *   POST /refunds/process                  退款处理（1 同意 / 2 拒绝）
 *
 * 发货与确认归还只有一份实现（api/user/order.ts 里那对），这里直接转出，
 * 免得两个角色各写一遍、日后改一处漏一处。
 */
export { shipOrder, confirmReturn } from '@/api/user/order'

export type TransactionType = 'new' | 'used' | 'rental'

export interface MerchantOrderQuery {
  type?: TransactionType
  status?: string | number
  orderNo?: string
  pageNum?: number
  pageSize?: number
}

/** 订单列表行：OrderServiceImpl.getOrderList 拼出来的扁平结构。 */
export interface MerchantOrderRow {
  orderId: number
  orderNo: string
  /** 下单账号的登录名。 */
  userName: string | null
  /** 收件人姓名（后端字段名沿用了 customerName）。 */
  customerName: string | null
  totalAmount: number | string
  orderStatus: number
  createTime: string
  items: MerchantOrderItem[]
}

export interface MerchantOrderItem {
  itemId: number
  orderId: number
  productId: number
  productName: string | null
  productImage: string | null
  unitPrice: number | string | null
  quantity: number
  specifications: string | null
  brandName: string | null
  /** 1 全新 / 2 二手 / 3 租赁。 */
  productType: number | null
  /** 成色百分比（85 / 95 …），仅二手与租赁有值。 */
  condition: number | null
  deposit: number | string | null
  freight: number | string | null
  itemStatus: number | null
  leaseTerm: number | null
}

export interface MerchantOrderPage {
  list: MerchantOrderRow[]
  total: number
  pageNum: number
  pageSize: number
}

export interface MerchantRefundRow {
  refundId: number
  orderId: number
  orderNo: string
  refundAmount: number | string
  /** 0 申请中 / 1 退款成功 / 2 退款失败 */
  refundStatus: number
  refundReason: string | null
  refundDescription: string | null
  applyTime: string | null
  createTime: string | null
  items: { productId: number; productName: string | null; brandName: string | null; quantity: number }[]
}

export interface MerchantRefundPage {
  list: MerchantRefundRow[]
  total: number
  page: number
  pageSize: number
}

function unwrap(res: any): any {
  return res?.data ?? res
}

/**
 * 订单列表。
 *
 * 后端把 status / orderNo 的判断写在分页之后：命中的是「当前这一页」里的订单，
 * 但 total 仍是未过滤的总数。照它分页会出现「明明有订单却搜不到」的假空结果，
 * 所以调用方一次取回该交易线的订单，再在页面内过滤与分页。
 */
export async function getOrderList(query: MerchantOrderQuery = {}): Promise<MerchantOrderPage> {
  const res = await axios.get('/orders/list', {
    params: {
      type: query.type ?? undefined,
      status: query.status ?? undefined,
      orderNo: query.orderNo || undefined,
      pageNum: query.pageNum ?? 1,
      pageSize: query.pageSize ?? 100,
    },
  })
  const data = unwrap(res)
  const list: MerchantOrderRow[] = data?.list ?? []
  return {
    list,
    total: Number(data?.total ?? list.length),
    pageNum: Number(data?.pageNum ?? query.pageNum ?? 1),
    pageSize: Number(data?.pageSize ?? query.pageSize ?? 100),
  }
}

export interface MerchantOrderDetail {
  order: Record<string, any>
  orderItems: MerchantOrderItem[]
}

/** 订单详情。orderId 同时接受数字主键与 ORD 开头的订单号。 */
export async function getOrderDetail(orderId: number | string): Promise<MerchantOrderDetail> {
  const isOrderNo = typeof orderId === 'string' && /^[A-Za-z]/.test(orderId)
  const res = isOrderNo
    ? await axios.get(`/orders/by-order-no/${orderId}`)
    : await axios.get(`/orders/${orderId}`)
  const data = unwrap(res) ?? {}
  return { order: data.order ?? {}, orderItems: data.orderItems ?? [] }
}

/**
 * 发货前的收货信息校验。
 *
 * orders 表把收件人/电话/省市区/详细地址抄在订单自己身上，缺一项快递就发不出去。
 * 返回缺失的字段名，空数组表示可以发货 —— 页面据此给出「去补」的提示，
 * 而不是发一个假成功再把包裹寄丢。
 */
export function missingReceiverFields(order: Record<string, any> | null | undefined): string[] {
  if (!order) return ['收货信息']
  const missing: string[] = []
  const text = (value: unknown) => String(value ?? '').trim()
  if (!text(order.recipient)) missing.push('收件人')
  if (!text(order.phone)) missing.push('联系电话')
  const region = `${text(order.province)}${text(order.city)}${text(order.district)}`
  if (!region && !text(order.detail)) missing.push('收货地址')
  else if (!text(order.detail)) missing.push('详细地址')
  return missing
}

/** 本店退款列表。 */
export async function getMerchantRefunds(params: {
  status?: string | number
  orderNo?: string
  page?: number
  pageSize?: number
} = {}): Promise<MerchantRefundPage> {
  const res = await axios.get('/refunds/merchant/list', {
    params: {
      status: params.status ?? undefined,
      orderNo: params.orderNo || undefined,
      page: params.page ?? 1,
      pageSize: params.pageSize ?? 100,
    },
  })
  const data = unwrap(res) ?? {}
  const list: MerchantRefundRow[] = data.list ?? []
  return {
    list,
    total: Number(data.total ?? list.length),
    page: Number(data.page ?? 1),
    pageSize: Number(data.pageSize ?? 100),
  }
}

/** 退款处理。status：1 同意退款（退款成功），2 拒绝（退款失败）。 */
export async function processRefund(refundId: number, status: 1 | 2) {
  const res = await axios.post('/refunds/process', { refundId, status })
  return unwrap(res)
}
