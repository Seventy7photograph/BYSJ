import axios from '@/axios'

/**
 * 商家商品接口。
 *
 * 与 MerchantProductController / ImageController 的路径一一对应。原文件在每一层都
 * try/catch 后返回 [] 或 null，页面分不清「没有商品」和「请求失败」，还会在拦截器
 * 已经弹过提示之后再弹一次。这里只做三件事：
 *   1. 把后端的两种分页结构收敛成 { list, total }；
 *   2. 让错误继续往上抛，由页面的错误态统一处理；
 *   3. 把散落的字段名收敛成一处类型定义。
 */

export type MerchantTypeKey = 'new' | 'used' | 'rental'

/** 商品类型：1 全新 / 2 二手 / 3 租赁，与 product.product_type 对齐。 */
export const PRODUCT_TYPE_CODE: Record<MerchantTypeKey, number> = {
  new: 1,
  used: 2,
  rental: 3,
}

/** 列表行。字段来自 ProductService.getMerchantProductList。 */
export interface MerchantProduct {
  productId: number
  name: string
  price: number | null
  stock: number | null
  sales: number | null
  isOnShelf: number
  auditStatus: number
  rejectReason?: string | null
  createTime?: string | null
  /** 仅二手商品返回。 */
  condition?: number | null
  /** 仅租赁商品返回。 */
  deposit?: number | null
  minRentalDays?: number | null
}

export interface MerchantProductPage {
  list: MerchantProduct[]
  total: number
}

export interface MerchantProductQuery {
  type: MerchantTypeKey
  /** 上架状态 0 / 1；留空表示不限。 */
  status?: 0 | 1 | ''
  keyword?: string
  pageNum?: number
  pageSize?: number
}

/** 商品详情（ProductService.getMerchantProductDetail），字段为扁平结构。 */
export interface MerchantProductDetail {
  productId: number
  categoryId: number | null
  brand: number | null
  model: string
  price: number | null
  originalPrice: number | null
  stock: number | null
  minStock: number | null
  productType: number
  isOnShelf: number
  auditStatus: number
  rejectReason?: string | null
  color?: string | null
  condition?: number | null
  minRentalDays?: number | null
  description?: string | null
  usageDuration?: string | null
  repairHistory?: string | number | null
  accessories?: string | null
}

/** product_rental_detail 的一行；商家详情接口不返回押金与最长租期。 */
export interface RentalRule {
  deposit: number | null
  minRentalDays: number | null
  maxRentalDays: number | null
}

export interface ProductImageRef {
  /** sys_image 主键，重新绑定时原样回传。 */
  imageId: number
  url: string
}

export interface CategoryNode {
  id: number
  value: string
  name: string
  children?: CategoryNode[]
}

export interface BrandNode {
  id: number
  value: number
  name: string
  children?: BrandNode[]
}

export interface SkuRow {
  skuId: number
  skuAttribute: string
  skuValue: string
  price: number
  stock: number
  minStock?: number
  sales?: number
}

export interface SkuPayload {
  skuAttribute: string
  skuValue: string
  price: number
  stock: number
  minStock?: number
}

/** POST /merchant/product 与 PUT /merchant/product/{id} 的载荷。 */
export interface ProductPayload {
  model: string
  brand: number
  categoryId: number
  productType: number
  originalPrice: number
  price: number
  stock: number
  minStock: number
  description: string
  /** 图片顺序即展示顺序，第一张是主图。 */
  imageIds: number[]
  /** product_detail.parameters，买家详情页的规格表。 */
  parameters?: Record<string, string>
  /** 二手：成色 / 使用时长 / 维修记录 / 配件清单 / 瑕疵说明。 */
  condition?: number | null
  usageDuration?: string
  repairHistory?: string
  accessories?: string
  defectDesc?: string
  /** 租赁：押金与租期。 */
  deposit?: number
  minRentalDays?: number
  maxRentalDays?: number
  /** 全新：颜色。 */
  color?: string
}

/** 后端分页有两种写法（records / list），一并兼容。 */
function readPage(payload: unknown): MerchantProductPage {
  const data = (payload ?? {}) as Record<string, unknown>
  const rows = Array.isArray(data.records)
    ? data.records
    : Array.isArray(data.list)
      ? data.list
      : []
  return { list: rows as MerchantProduct[], total: Number(data.total ?? rows.length) }
}

/** 拦截器返回的是 { code, msg, data }，取 data；没有这一层时原样返回。 */
function unwrap<T>(response: unknown): T {
  const body = response as { data?: unknown } | null
  return (body?.data ?? body) as T
}

export async function getProductList(query: MerchantProductQuery): Promise<MerchantProductPage> {
  const keyword = query.keyword?.trim()
  const res = await axios.get('/merchant/product/list', {
    params: {
      type: query.type,
      status: query.status === '' || query.status === undefined ? undefined : query.status,
      keyword: keyword ? keyword : undefined,
      pageNum: query.pageNum ?? 1,
      pageSize: query.pageSize ?? 10,
    },
  })
  return readPage(unwrap<unknown>(res))
}

export async function getProductDetail(productId: number | string) {
  return unwrap<MerchantProductDetail>(await axios.get(`/merchant/product/${productId}`))
}

export async function createProduct(payload: ProductPayload) {
  await axios.post('/merchant/product', payload)
}

export async function updateProduct(productId: number | string, payload: ProductPayload) {
  await axios.put(`/merchant/product/${productId}`, payload)
}

export async function setProductStatus(productId: number | string, status: 0 | 1) {
  await axios.put(`/merchant/product/${productId}/status`, { status })
}

export async function deleteProduct(productId: number | string) {
  await axios.delete(`/merchant/product/${productId}`)
}

export async function getProductImages(productId: number | string): Promise<ProductImageRef[]> {
  const rows = unwrap<Record<string, unknown>[]>(
    await axios.get(`/merchant/product/${productId}/images`),
  )
  if (!Array.isArray(rows)) return []
  return rows
    .map((row) => ({
      imageId: Number(row.imageId ?? row.id ?? 0),
      url: String(row.storagePath ?? row.imagePath ?? ''),
    }))
    .filter((item) => Number.isFinite(item.imageId) && item.imageId > 0 && item.url)
}

/**
 * 绑定商品图片（整组替换，服务端软删旧绑定、按数组顺序写 sort）。
 *
 * product_image 的口径是「一张主图 + 若干详情图」，所以分两次提交；
 * 主图先提交，让主图行的 id 小于详情图，接口按 (sort, id) 取主图时结果稳定。
 */
export async function bindProductImages(
  productId: number | string,
  imageType: 'main' | 'detail',
  imageIds: number[],
) {
  await axios.post('/image/bind/product', { productId, imageType, imageIds })
}

export async function getCategoryTree(): Promise<CategoryNode[]> {
  const data = unwrap<{ categoryTree?: CategoryNode[] }>(
    await axios.get('/merchant/product/categories'),
  )
  const tree = data?.categoryTree
  return Array.isArray(tree) ? tree : []
}

export async function getBrandTree(): Promise<BrandNode[]> {
  const data = unwrap<{ brandTree?: BrandNode[] }>(await axios.get('/merchant/product/brand-tree'))
  const tree = data?.brandTree
  return Array.isArray(tree) ? tree : []
}

export async function getSkuList(productId: number | string): Promise<SkuRow[]> {
  const rows = unwrap<SkuRow[]>(await axios.get(`/merchant/product/${productId}/skus`))
  return Array.isArray(rows) ? rows : []
}

export async function createSku(productId: number | string, payload: SkuPayload) {
  await axios.post(`/merchant/product/${productId}/skus`, payload)
}

export async function updateSku(productId: number | string, skuId: number, payload: SkuPayload) {
  await axios.put(`/merchant/product/${productId}/skus/${skuId}`, payload)
}

export async function deleteSku(productId: number | string, skuId: number) {
  await axios.delete(`/merchant/product/${productId}/skus/${skuId}`)
}

/**
 * 从任意异常里取一句人能读的话。
 * 拦截器把后端的 msg 同时写在 error.message 与 error.response.data.msg 上，
 * 两个位置都覆盖，免得页面显示 "Request failed with status code 400"。
 */
export function errorText(error: unknown, fallback = '操作失败，请稍后重试'): string {
  const candidate = error as {
    message?: string
    response?: { data?: { msg?: string; message?: string } }
  } | null
  return (
    candidate?.response?.data?.msg ??
    candidate?.response?.data?.message ??
    candidate?.message ??
    fallback
  )
}

/**
 * 登录失效或身份不可用。
 * 后端在拿不到登录身份时会报「无法确定当前登录用户，请重新登录后再试」，
 * 401 走的是同一条恢复路径 —— 两类都需要提示并引导重新登录。
 */
export function isAuthError(error: unknown): boolean {
  const status = (error as { response?: { status?: number } } | null)?.response?.status
  if (status === 401 || status === 403) return true
  return /登录|认证|token/i.test(errorText(error, ''))
}

/* -------------------------------------------------------------------------
 * 表单与后端字段之间的换算。
 *
 * 放在接口层是因为商品发布与商品编辑两页要用同一套口径，而 product_detail 目前
 * 只有 description 一列能被商品接口写入（见下），两边各写一遍必然漂移。
 * ---------------------------------------------------------------------- */

/** product_rental_detail.max_rental_days 由平台统一设定，商家不单独设置。 */
export const MAX_RENTAL_DAYS = 90

/** product_detail.description 里的瑕疵说明标记。 */
const DEFECT_MARK = '【瑕疵说明】'

export interface SpecEntry {
  key: string
  value: string
}

/**
 * 瑕疵说明写进商品描述。
 *
 * 二手档案（second_hand.defect_desc）目前没有任何写入接口，而 product_detail 里
 * 只有 description 一列能被商品接口写入。为了让商家填的瑕疵说明真的能出现在买家
 * 眼前，这里把它写成描述的第一段；后端补上 defect_desc 写入后改回专用字段即可。
 */
export function composeDescription(description: string, defectDesc: string): string {
  const desc = description.trim()
  const defect = defectDesc.trim()
  if (!defect) return desc
  return `${DEFECT_MARK}${defect}${desc ? `\n\n${desc}` : ''}`
}

/** composeDescription 的逆运算：编辑页把描述拆回「瑕疵说明 + 商品描述」。 */
export function splitDescription(text: string | null | undefined): {
  description: string
  defectDesc: string
} {
  const raw = (text ?? '').trim()
  if (!raw.startsWith(DEFECT_MARK)) return { description: raw, defectDesc: '' }
  const rest = raw.slice(DEFECT_MARK.length)
  const gap = rest.indexOf('\n\n')
  if (gap < 0) return { description: '', defectDesc: rest.trim() }
  return { description: rest.slice(gap + 2).trim(), defectDesc: rest.slice(0, gap).trim() }
}

/** 规格行 → product_detail.parameters（JSON 对象）。空键或空值的行丢弃。 */
export function specRowsToObject(rows: SpecEntry[]): Record<string, string> {
  const result: Record<string, string> = {}
  for (const row of rows) {
    const key = row.key.trim()
    const value = String(row.value ?? '').trim()
    if (!key || !value) continue
    result[key] = value
  }
  return result
}

/** product_detail.parameters → 规格行。 */
export function specObjectToRows(value: unknown): SpecEntry[] {
  if (!value || typeof value !== 'object') return []
  return Object.entries(value as Record<string, unknown>).map(([key, entry]) => ({
    key,
    value: entry === null || entry === undefined ? '' : String(entry),
  }))
}
