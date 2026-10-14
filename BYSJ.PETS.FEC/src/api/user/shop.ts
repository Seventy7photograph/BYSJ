import axios from '@/axios'

/**
 * 前台商城的商品与分类接口。
 *
 * 之前这些调用散落在各页面里直接写 axios，路径还与后端不一致
 * （如 /shop/products、/order/list 后端根本没有）。这里集中一份，
 * 路径与 ShopController、OrderController 的 @RequestMapping 一一对应。
 */

export interface ShopQuery {
  category?: string | number
  categoryId?: string | number
  brand?: string | number
  brandId?: string | number
  type?: string
  keyword?: string
  sort?: string
  quality?: string
  condition?: string
  productType?: number
  priceRange?: string
  pageNum?: number
  pageSize?: number
}

export interface ShopPage<T> {
  list: T[]
  total: number
  pageNum: number
  pageSize: number
  pages: number
}

/** 商品列表（分页）。 */
export async function getProducts(params: ShopQuery = {}): Promise<ShopPage<any>> {
  const res = await axios.get('/shop/products', { params })
  const data = res?.data ?? res
  return {
    list: data?.list ?? [],
    total: Number(data?.total ?? 0),
    pageNum: Number(data?.pageNum ?? params.pageNum ?? 1),
    pageSize: Number(data?.pageSize ?? params.pageSize ?? 20),
    pages: Number(data?.pages ?? 1),
  }
}

/** 商品详情。 */
export async function getProductDetail(productId: number | string) {
  const res = await axios.get(`/shop/products/${productId}`)
  return res?.data ?? res
}

/** 一级分类。 */
export async function getCategories() {
  const res = await axios.get('/shop/categories')
  return res?.data ?? res
}

/** 某分类下的品牌。 */
export async function getBrands(parentId: number | string) {
  const res: any = await axios.get('/shop/brands', { params: { parentId } })
  return res?.brands ?? res?.data?.brands ?? []
}

/** 某分类下的子类。 */
export async function getSubCategories(parentId: number | string) {
  const res: any = await axios.get('/shop/sub-categories', { params: { parentId } })
  return res?.subCategories ?? res?.data?.subCategories ?? []
}

/** 同类推荐。 */
export async function getRelated(categoryId?: number | string, productId?: number | string, limit = 8) {
  const res = await axios.get('/shop/related', { params: { categoryId, productId, limit } })
  return res?.data ?? res ?? []
}
