import { apiGet } from './http'

/**
 * 管理员仪表盘读数。
 *
 * 只声明这个页面真正会用的字段。后端还返回 categoryDistribution / hotProducts /
 * orderTypeDistribution，那三个是写死的假数据（见 AdminServiceImpl 注释里的
 * "模拟数据"），页面上不再展示，所以这里也不声明。
 */
export interface AdminDashboardData {
  /** 普通用户数。 */
  userCount: number
  /** 商家数。 */
  merchantCount: number
  /** 全新 / 二手 / 租赁商品数（含未过审）。 */
  newProductCount: number
  usedProductCount: number
  rentalProductCount: number
  /** 待审核商品数（audit_status = 0）。 */
  pendingProductsCount: number
  /** 分类总数。 */
  categoryCount: number
  /** 器材类型分布（真实统计）。 */
  productTypeDistribution: { name: string; value: number }[]
  /** 近 7 天新增用户 / 订单（真实统计）。 */
  userGrowthTrend: { dates: string[]; users: number[] }
  orderTrend: { dates: string[]; orders: number[] }
  recentOperations: {
    operator: string
    operation: string
    target: string
    result: string
    operationTime: string
  }[]
}

/** 获取管理员仪表盘数据。 */
export function getAdminDashboardData(): Promise<AdminDashboardData> {
  return apiGet<AdminDashboardData>('/admin/dashboard')
}
