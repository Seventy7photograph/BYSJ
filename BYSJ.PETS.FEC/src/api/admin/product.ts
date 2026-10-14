import { apiDelete, apiGet, apiPut, type Paged } from './http'

// 管理员商品管理相关 API

/** product 表的实体形状，/admin/products 与 /admin/products/{id} 都返回它。 */
export interface AdminProduct {
  productId: number
  categoryId: number | null
  brand: number | null
  model: string
  /** 1 全新 / 2 二手 / 3 租赁。 */
  productType: number
  /** 成色百分比（95 即 95 新），仅二手与租赁有值。 */
  condition: number | null
  originalPrice: number | null
  price: number | null
  stock: number | null
  minRentalDays: number | null
  minStock: number | null
  sellerId: number | null
  /** 0 待审核 / 1 已通过 / 2 已驳回。 */
  auditStatus: number
  rejectReason: string | null
  /** 0 未上架 / 1 已上架。 */
  isOnShelf: number | null
  createTime: string | null
  updateTime: string | null
  color: string | null
  /** 详情接口额外回填的图片路径。 */
  images: string[] | null
}

/**
 * 审核列表的一行。后端用的是另一条 SQL（selectProductListWithBrandName），
 * 只返回下面这几个字段，没有成色、没有图片、没有卖家。
 */
export interface AuditProductRow {
  productId: number
  model: string
  brand: number
  brandName: string | null
  productType: number
  price: number | null
  stock: number | null
  auditStatus: number
  createTime: string | null
}

export interface ProductQuery {
  pageNum?: number
  pageSize?: number
  /** 对应 audit_status。 */
  status?: number
  productType?: number
}

export interface ProductAuditQuery {
  pageNum?: number
  pageSize?: number
  /** 必传：后端 SQL 里 audit_status 是硬条件。 */
  auditStatus: number
  productName?: string
  brand?: string
  model?: string
  productType?: number
}

export interface ProductAuditPayload {
  /** 0 待审核 / 1 通过（后端会同时上架）/ 2 驳回。 */
  auditStatus: number
  /**
   * 驳回原因。
   *
   * 目前后端 auditProduct 只写了 audit_status，把 rejectReason 丢掉了，
   * product.reject_reason 始终为 NULL，商家也看不到驳回理由。
   * 前端照契约提交，等后端补上落库即可生效。
   */
  rejectReason?: string
}

export function getProductList(params: ProductQuery): Promise<Paged<AdminProduct>> {
  return apiGet<Paged<AdminProduct>>('/admin/products', { ...params })
}

export function getProductAuditList(params: ProductAuditQuery): Promise<Paged<AuditProductRow>> {
  return apiGet<Paged<AuditProductRow>>('/admin/products/audit', { ...params })
}

export function getProductDetail(productId: number): Promise<AdminProduct> {
  return apiGet<AdminProduct>(`/admin/products/${productId}`)
}

export function auditProduct(productId: number, data: ProductAuditPayload): Promise<unknown> {
  return apiPut<unknown>(`/admin/products/${productId}/audit`, { ...data })
}

/** 上架 / 下架。后端读请求体里的 isOnShelf，不接受字符串。 */
export function setProductShelf(productId: number, isOnShelf: 0 | 1): Promise<unknown> {
  return apiPut<unknown>(`/admin/products/${productId}/shelf`, { isOnShelf })
}

export function deleteProduct(productId: number): Promise<unknown> {
  return apiDelete<unknown>(`/admin/products/${productId}`)
}

/**
 * 审核证据：商品详情页的公开接口（/shop/** 是 permitAll）。
 *
 * /admin/products/{id} 只给 product 一张表的字段，缺成色描述、瑕疵说明、
 * 参数表、卖家名称这些审核必须看到的东西；二手档案（second_hand 表）只有
 * 这个公开接口会返回，而管理员身份访问它没有任何权限问题。
 */
export interface ProductEvidence {
  id: number
  name: string
  brandName: string | null
  categoryId: number | null
  price: number | null
  originalPrice: number | null
  stock: number | null
  imageUrl: string | null
  description: string | null
  /** 规格参数：{ 卡口: '尼康 Z', ... } */
  parameters: Record<string, string> | null
  specifications: Record<string, string> | null
  imageUrls: string[] | null
  condition: number | null
  sellerId: number | null
  sellerName: string | null
  /** 二手专属。 */
  qualityReport: string | null
  usedTime: string | null
  defectDesc: string | null
  defectImg: string[] | null
  secondHandDescription: string | null
  secondHandImgUrls: string[] | null
  warrantyInfo: string | null
  /** 租赁专属。 */
  minRentalDays: number | null
  maxRentalDays: number | null
  deposit: number | null
  insuranceFee: number | null
  deliveryFee: number | null
}

export function getProductEvidence(productId: number): Promise<ProductEvidence> {
  return apiGet<ProductEvidence>(`/shop/products/${productId}`)
}
