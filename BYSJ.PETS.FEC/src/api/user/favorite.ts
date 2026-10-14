import axios from '@/axios'

/**
 * 收藏接口。路径与参数名对齐 FavoriteController：
 *   GET    /favorites?page&size          分页列表
 *   POST   /favorites                    { productId }
 *   DELETE /favorites/{favoriteId}       按收藏记录取消
 *   DELETE /favorites?productId=         按商品取消（商品详情页在用）
 *   POST   /favorites/batch-delete       { favoriteIds: [] }
 *   GET    /favorites/check?productId=   是否已收藏
 *
 * 两处历史错误：
 *   1. 列表接口的返回值是 Result{ code, msg, data: { list, total, ... } }，
 *      原实现把整个 Result 当分页对象读，导致 list / total 永远是 undefined，
 *      收藏页永远显示空。
 *   2. 删除类接口返回的是裸 Map（{ success, message }），不是 Result。
 *      失败时（success=false）原实现照样提示"取消收藏成功"，这里统一抛错。
 */

export interface FavoriteItem {
  /** favorite.favorite_id */
  id: number
  productId: number
  /** product.model */
  productName: string | null
  brandName: string | null
  /** sys_image.storage_path */
  productImage: string | null
  price: number | null
  stock: number | null
  /** 1 全新 / 2 二手 / 3 租赁 —— 判断商品类型只看这个数字字段 */
  product_type: number | null
  /** 后端补的英文类型名：new / second-hand / rent，仅用于展示 */
  productType?: string | null
  condition: number | null
  /** 成色百分比字符串，等同 product_type=2 时的 condition */
  quality?: string | null
  sellerName?: string | null
  specifications?: string | null
  createdAt: string | null
}

export interface FavoritePage {
  list: FavoriteItem[]
  total: number
  pageNum: number
  pageSize: number
  pages: number
}

export interface FavoriteQuery {
  pageNum?: number
  pageSize?: number
}

/** 拆掉 Result 外壳；裸 Map 响应原样返回。 */
function unwrap(res: any): any {
  return res?.data ?? res
}

/** 删除类接口用 { success, message } 表达结果，失败必须让调用方看到。 */
function assertDone(res: any, fallback: string) {
  const data = unwrap(res)
  if (data && data.success === false) {
    throw new Error(data.message || fallback)
  }
  return data
}

/** 收藏列表（当前用户的，按收藏时间倒序）。 */
export async function getFavoriteList(query: FavoriteQuery = {}): Promise<FavoritePage> {
  const res = await axios.get('/favorites', {
    params: {
      page: query.pageNum ?? 1,
      size: query.pageSize ?? 12,
    },
  })
  const data = unwrap(res)
  const list: FavoriteItem[] = data?.list ?? data?.records ?? []
  return {
    list,
    total: Number(data?.total ?? list.length),
    pageNum: Number(data?.current ?? data?.pageNum ?? query.pageNum ?? 1),
    pageSize: Number(data?.size ?? data?.pageSize ?? query.pageSize ?? 12),
    pages: Number(data?.pages ?? 1),
  }
}

/** 添加收藏。已收藏时后端返回 success=false，不视为错误。 */
export async function addFavorite(data: { productId: number; [key: string]: any }) {
  const res = await axios.post('/favorites', { productId: data.productId })
  return unwrap(res)
}

/** 按商品取消收藏（详情页「已收藏」按钮）。 */
export async function removeFavorite(productId: number) {
  const res = await axios.delete('/favorites', { params: { productId } })
  return assertDone(res, '取消收藏失败')
}

/** 按收藏记录取消收藏（收藏列表单条操作）。 */
export async function removeFavoriteById(favoriteId: number) {
  const res = await axios.delete(`/favorites/${favoriteId}`)
  return assertDone(res, '取消收藏失败')
}

/** 批量取消收藏。 */
export async function batchRemoveFavorites(favoriteIds: number[]) {
  if (!favoriteIds.length) return { success: true, message: '未选择商品' }
  const res = await axios.post('/favorites/batch-delete', { favoriteIds })
  return assertDone(res, '批量取消收藏失败')
}

/** 是否已收藏。后端返回裸 Map { isFavorited }。 */
export async function checkFavorite(productId: number): Promise<boolean> {
  const res = await axios.get('/favorites/check', { params: { productId } })
  return Boolean(unwrap(res)?.isFavorited)
}
