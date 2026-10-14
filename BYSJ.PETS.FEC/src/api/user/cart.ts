import axios from '@/axios'
import { labelOf, PRODUCT_TYPE } from '@/constants/domain'

/**
 * 购物车接口。
 *
 * 路径与后端 CartController 一一对应：/cart/items、/cart/add、
 * PUT /cart/items/{cartItemId}、DELETE /cart/items/{cartItemId}、
 * DELETE /cart/clear、POST /cart/batch-add。
 *
 * 原实现每个函数都套一层 try/catch 只为了 console.error 再原样抛出，
 * 既没有加工数据也让错误信息散落各处。这里只做「请求 → 归一化成数组」，
 * 失败原因由 axios 拦截器统一提示，页面只负责展示与恢复。
 */

/** 后端 CartItemDTO。字段名用后端的原样：主键是 id（不是 cartId），图是 productImage。 */
export interface CartItem {
  /** 购物车记录 ID */
  id: number
  productId: number
  productName: string | null
  productImage: string | null
  price: number | string
  quantity: number
  /** 商品当前库存，加购后可能被商家改小 */
  stock: number | null
  selected: boolean
  /** 规格参数 JSON 字符串 */
  specifications?: string | null
  brandName?: string | null
  /** 商品类型数字码：1 全新 / 2 二手 / 3 租赁 */
  product_type?: number | null
  /** 后端拼的英文类型名：new / second-hand / rent，只作兜底 */
  productType?: string | null
  condition?: number | null
  sellerName?: string | null
  quality?: string | null
}

/** 把后端可能返回的 { code, msg, data } 或裸数组统一成数组。 */
function toList(res: any): CartItem[] {
  const data = res?.data ?? res
  if (Array.isArray(data)) return data as CartItem[]
  if (Array.isArray(data?.list)) return data.list as CartItem[]
  return []
}

/**
 * 购物车商品的类型码。
 * 后端同时给了数字码和英文名，两者历史上对不上（租赁的英文名是 rent 而不是
 * rental），所以以数字码为准，英文名只作兜底。
 */
export function cartItemTypeCode(item: CartItem): number | null {
  if (item?.product_type !== null && item?.product_type !== undefined) {
    return Number(item.product_type)
  }
  switch (item?.productType) {
    case 'new':
      return 1
    case 'second-hand':
      return 2
    case 'rent':
    case 'rental':
      return 3
    default:
      return null
  }
}

/** 购物车商品的类型文案，与商品列表、订单使用同一张表。 */
export function cartItemTypeLabel(item: CartItem): string {
  return labelOf(PRODUCT_TYPE, cartItemTypeCode(item)).label
}

/** 获取购物车列表。 */
export async function getCartList(): Promise<CartItem[]> {
  const res = await axios.get('/cart/items')
  return toList(res)
}

/** 加入购物车。同一商品重复加购时后端累加数量。 */
export async function addToCart(data: { productId: number; quantity: number }) {
  const res = await axios.post('/cart/add', data)
  return res?.data ?? res
}

/** 修改购物车商品数量。数量必须 ≥ 1，删除请用 deleteCartItem。 */
export async function updateCartItem(cartItemId: number, quantity: number) {
  const res = await axios.put(`/cart/items/${cartItemId}`, { quantity })
  return res?.data ?? res
}

/** 删除单条购物车商品。 */
export async function deleteCartItem(cartItemId: number) {
  const res = await axios.delete(`/cart/items/${cartItemId}`)
  return res?.data ?? res
}

/** 清空当前用户的购物车。 */
export async function clearCart() {
  const res = await axios.delete('/cart/clear')
  return res?.data ?? res
}

/** 批量加购。 */
export async function batchAddToCart(productIds: number[]) {
  const res = await axios.post('/cart/batch-add', { productIds })
  return res?.data ?? res
}
