import { apiDelete, apiGet, apiPost, apiPut } from './http'

// 管理员品牌管理相关 API

export interface BrandRow {
  brandId: number
  brandName: string
  parentId: number | null
  /** 分类编码。品牌与分类共用一套编码规则（相机 CAM、镜头 LEN）。 */
  categoryCode: string
  sort: number
  /** 1 启用 / 0 禁用。禁用会级联到子品牌。 */
  status: number
  description: string | null
  createTime?: string | null
  updateTime?: string | null
}

/**
 * 品牌表没有 logo 列，也没有品牌图片的存储约定，所以不提供 logo 字段。
 * （原来的接口类型里挂着 brandLogo，任何页面都没法真正填写它。）
 */
export interface BrandPayload {
  brandName: string
  categoryCode: string
  parentId: number | null
  sort: number
  status: number
  description?: string | null
}

/**
 * 品牌列表。后端返回的是一张平表（按 sort 升序），不是树；
 * 父子关系靠 parentId 自行组织。原先的 /admin/brands/tree 在后端并不存在。
 */
export function getBrandList(): Promise<BrandRow[]> {
  return apiGet<BrandRow[]>('/admin/brands')
}

export function getBrandDetail(brandId: number): Promise<BrandRow> {
  return apiGet<BrandRow>(`/admin/brands/${brandId}`)
}

/**
 * 新增品牌。后端会自动带上 create_by / create_time，并忽略请求里的 sort
 * （顶级固定 0，子品牌取父品牌 sort + 1），所以排序值不要在表单里承诺给用户。
 */
export function addBrand(data: BrandPayload): Promise<unknown> {
  return apiPost<unknown>('/admin/brands', { ...data })
}

export function updateBrand(brandId: number, data: BrandPayload): Promise<unknown> {
  return apiPut<unknown>(`/admin/brands/${brandId}`, { ...data })
}

/** 删除品牌。被商品引用时数据库会拒绝，调用方要翻译这条报错。 */
export function deleteBrand(brandId: number): Promise<unknown> {
  return apiDelete<unknown>(`/admin/brands/${brandId}`)
}
