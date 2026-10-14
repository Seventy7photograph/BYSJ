import { apiGet, apiPut, type AdminUser, type Paged } from './http'

// 管理员商家管理相关 API

export interface MerchantQuery {
  pageNum?: number
  pageSize?: number
  /** 后端按 username / shop_name 模糊匹配。 */
  keyword?: string
  /** 店铺状态，取值见下面 SHOP_STATE。 */
  status?: number
}

export interface MerchantAuditPayload {
  /** 1 通过，其它值按驳回处理。 */
  auditStatus: number
  /** 驳回原因。后端会把它写进给商家的站内通知。 */
  rejectReason?: string
}

/**
 * 店铺状态。
 *
 * user.shop_status 的真实口径是 0-关闭 / 1-正常 / 2-审核中（user 表注释、
 * ShopServiceImpl.getAuthInfo 的映射、AdminController 里 `eq("shop_status", 2)`
 * 取审核队列，三处一致）。
 *
 * @/constants/domain 的 SHOP_STATUS 表把 0 当作"待审核"、2 当作"已驳回"，与
 * 数据库对不上——按那张表渲染，审核队列里每一家待审的店铺都会显示成"已驳回"。
 * 管理员后台是审核决定的地方，标签错了就是错判，所以这里用一份与库一致的口径，
 * 并且只维护这一份（MerchantAudit / MerchantManagement 共用）。domain.ts 修好
 * 之后删掉这个常量、改回 SHOP_STATUS 即可。
 */
export const SHOP_STATE: Record<number, { label: string; tone: 'neutral' | 'teal' | 'amber' | 'vermilion' | 'outline' }> = {
  0: { label: '已关闭', tone: 'vermilion' },
  1: { label: '正常营业', tone: 'teal' },
  2: { label: '待审核', tone: 'amber' },
}

export function shopStateOf(code: number | null | undefined) {
  if (code === null || code === undefined) return { label: '未知', tone: 'neutral' as const }
  return SHOP_STATE[code] ?? { label: `未知（${code}）`, tone: 'neutral' as const }
}

/**
 * 商家列表（user_type = 2）。
 *
 * 与用户列表同样的坑：keyword 的 or 条件会绕过 user_type / shop_status 过滤，
 * 调用方需要按 userType === 2 再筛一次。
 */
export function getMerchantList(params: MerchantQuery): Promise<Paged<AdminUser>> {
  return apiGet<Paged<AdminUser>>('/admin/merchants', { ...params })
}

/** 待审核商家队列（后端固定 shop_status = 2）。 */
export function getMerchantAuditList(params: MerchantQuery): Promise<Paged<AdminUser>> {
  return apiGet<Paged<AdminUser>>('/admin/merchants/audit', { ...params })
}

export function getMerchantDetail(merchantId: number): Promise<AdminUser> {
  return apiGet<AdminUser>(`/admin/merchants/${merchantId}`)
}

/** 审核商家：通过写 shop_status = 1，驳回写 0 并给商家发一条通知。 */
export function auditMerchant(
  merchantId: number,
  data: MerchantAuditPayload,
): Promise<unknown> {
  return apiPut<unknown>(`/admin/merchants/${merchantId}/audit`, { ...data })
}

/** 停业（等价于把店铺状态置为 0）。 */
export function disableMerchant(merchantId: number): Promise<unknown> {
  return apiPut<unknown>(`/admin/merchants/${merchantId}/disable`)
}

/** 设置店铺状态。后端用的是 query 参数，不是请求体。 */
export function setMerchantStatus(merchantId: number, status: number): Promise<unknown> {
  return apiPut<unknown>(`/admin/merchants/${merchantId}/status`, undefined, { status })
}
