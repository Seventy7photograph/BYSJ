import axios from '@/axios'
import { labelOf, ORDER_STATUS } from '@/constants/domain'

/**
 * 订单接口。
 *
 * 原文件里的路径全是错的：/order/list、/order/{id}、PUT /order/{id}/cancel、
 * /order/{id}/receipt —— 后端 OrderController 的实际前缀是 /orders，
 * 取消与确认收货都是 POST，也没有 receipt 这个动作。整份文件没有一个能打通的
 * 调用，页面只能靠 catch 静默降级成空列表。
 *
 * 下面全部对齐 OrderController 的 @Mapping。
 */

export interface OrderQuery {
  /** 交易线：new 全新 / used 二手 / rental 租赁 */
  type?: 'new' | 'used' | 'rental'
  /** 订单状态，可传多个用逗号分隔 */
  status?: string | number
  orderNo?: string
  pageNum?: number
  pageSize?: number
}

export interface OrderPage {
  list: any[]
  total: number
  pageNum: number
  pageSize: number
  pages: number
}

function unwrap(res: any): any {
  return res?.data ?? res
}

function toPage(res: any, query: OrderQuery): OrderPage {
  const data = unwrap(res)
  const list = data?.list ?? data?.records ?? []
  return {
    list,
    total: Number(data?.total ?? list.length ?? 0),
    pageNum: Number(data?.pageNum ?? query.pageNum ?? 1),
    pageSize: Number(data?.pageSize ?? query.pageSize ?? 10),
    pages: Number(data?.pages ?? 1),
  }
}

/** 订单列表。不传 type 时后端返回当前用户的全部订单。 */
export async function getOrderList(query: OrderQuery = {}): Promise<OrderPage> {
  const res = await axios.get('/orders/list', {
    params: {
      type: query.type,
      status: query.status,
      orderNo: query.orderNo,
      pageNum: query.pageNum ?? 1,
      pageSize: query.pageSize ?? 10,
    },
  })
  return toPage(res, query)
}

/** 订单详情。orderId 既接受数字主键，也接受 ORD 开头的订单号。 */
export async function getOrderDetail(orderId: number | string) {
  const isOrderNo = typeof orderId === 'string' && /^[A-Za-z]/.test(orderId)
  const res = isOrderNo
    ? await axios.get(`/orders/by-order-no/${orderId}`)
    : await axios.get(`/orders/${orderId}`)
  return unwrap(res)
}

/** 从购物车创建订单。 */
export async function createFromCart(payload: {
  addressId: number
  cartItemIds?: number[]
  remark?: string
  [key: string]: any
}) {
  const res = await axios.post('/orders/create-from-cart', payload)
  return unwrap(res)
}

/** 立即购买时生成临时订单（不走购物车）。 */
export async function createTempOrder(payload: {
  productId: number
  quantity: number
  addressId?: number
  [key: string]: any
}) {
  const res = await axios.post('/orders/temp', payload)
  return unwrap(res)
}

/** 下单前检查是否已有同一商品的未支付订单。 */
export async function checkPendingOrder(payload: { productId: number; [key: string]: any }) {
  const res = await axios.post('/orders/check-pending', payload)
  return unwrap(res)
}

/** 支付订单。 */
export async function payOrder(orderId: number, payload: { paymentMethod: string; [key: string]: any }) {
  const res = await axios.post(`/orders/pay/${orderId}`, payload)
  return unwrap(res)
}

/** 取消订单。 */
export async function cancelOrder(orderId: number) {
  const res = await axios.post(`/orders/${orderId}/cancel`)
  return unwrap(res)
}

/** 买家确认收货。 */
export async function confirmReceive(orderId: number) {
  const res = await axios.post(`/orders/${orderId}/confirm-receive`)
  return unwrap(res)
}

/** 商家发货。 */
export async function shipOrder(orderId: number, payload?: Record<string, any>) {
  const res = await axios.post(`/orders/${orderId}/ship`, payload ?? {})
  return unwrap(res)
}

/** 租赁：买家发起归还。 */
export async function returnRental(orderId: number) {
  const res = await axios.post(`/orders/${orderId}/return`)
  return unwrap(res)
}

/** 租赁：商家确认归还。 */
export async function confirmReturn(orderId: number) {
  const res = await axios.post(`/orders/${orderId}/confirm-return`)
  return unwrap(res)
}

/** 订单状态文案，页面统一用它而不是各自维护一张表。 */
export function orderStatusLabel(code: number | null | undefined): string {
  return labelOf(ORDER_STATUS, code).label
}
