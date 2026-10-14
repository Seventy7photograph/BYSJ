import axios from '@/axios'

/**
 * 商家库存接口，路径对齐 InventoryController：
 *   GET    /merchant/inventory                            列表
 *   GET    /merchant/inventory/{inventoryId}              单条库存
 *   POST   /merchant/inventory/adjust                     调整库存（后端事务更新并写 inventory_history）
 *   GET    /merchant/inventory/history?inventoryId        变更记录
 *   PUT    /merchant/inventory/{inventoryId}/min-stock    安全库存
 *   POST   /merchant/inventory/import                     批量导入（multipart file）
 *
 * 这个文件原来带着 200 多行 mockInventoryData / mockInventoryHistory，还有只
 * console.warn 一下就 resolve 的 batchImportInventory。假数据比报错危险得多：
 * 接口不通时页面看起来照样能用，商家照着它调库存，账就错在没人看得见的地方。
 * 现在全部是真实调用，失败就抛错，由页面给出错误态。
 */

export interface InventoryItem {
  id: number
  productId: number
  productName: string
  /** inventory.product_type 存的是 new / used / rental。 */
  productType: 'new' | 'used' | 'rental' | string
  skuId: number
  skuAttribute: string | null
  skuValue: string | null
  currentStock: number
  minStock: number
  sales: number
  createTime: string
  lastUpdateTime: string
  brandName?: string | null
  price?: number | null
  originalPrice?: number | null
}

export interface InventoryHistoryItem {
  id: number
  changeTime: string
  changeType: string
  beforeStock: number
  afterStock: number
  changeQuantity: number
  reason: string | null
  operator: string
}

export interface InventoryQuery {
  productType?: string
  /** out 缺货 / warning 低于安全库存 / sufficient 充足 */
  stockStatus?: string
  keyword?: string
  page?: number
  pageSize?: number
}

export interface InventoryPage {
  list: InventoryItem[]
  total: number
  pageNum: number
  pageSize: number
}

/** 后端 adjustType 是中文枚举，也是 inventory_history.change_type 的取值。 */
export type AdjustType = '增加' | '减少' | '直接设置'

export const ADJUST_TYPES: { value: AdjustType; label: string }[] = [
  { value: '增加', label: '增加' },
  { value: '减少', label: '减少' },
  { value: '直接设置', label: '直接设置' },
]

/**
 * 库存变动必须写明业务原因，只列真实发生的入库/出库场景。
 * 它会写进 inventory_history.reason，是事后对账唯一凭据。
 */
export const ADJUST_REASONS = ['进货', '销售出库', '盘点修正', '退货入库'] as const

export interface AdjustPayload {
  inventoryId: number
  adjustType: AdjustType
  /** 增加/减少时是变动量，直接设置时是目标库存。 */
  adjustQuantity: number
  reason: string
  /** 可选：同一次提交里一起改安全库存。 */
  minStock?: number
}

/** 拆掉 Result 外壳。 */
function unwrap(res: any): any {
  return res?.data ?? res
}

/** 库存列表。后端按 productType / stockStatus / keyword 过滤。 */
export async function getInventoryList(query: InventoryQuery = {}): Promise<InventoryPage> {
  const res = await axios.get('/merchant/inventory', {
    params: {
      productType: query.productType || undefined,
      stockStatus: query.stockStatus || undefined,
      keyword: query.keyword || undefined,
      page: query.page ?? 1,
      pageSize: query.pageSize ?? 100,
    },
  })
  const data = unwrap(res)
  const list: InventoryItem[] = data?.list ?? []
  return {
    list,
    total: Number(data?.total ?? list.length),
    pageNum: Number(data?.page ?? query.page ?? 1),
    pageSize: Number(data?.pageSize ?? query.pageSize ?? 100),
  }
}

/** 单条库存。 */
export async function getInventoryDetail(inventoryId: number): Promise<InventoryItem> {
  const res = await axios.get(`/merchant/inventory/${inventoryId}`)
  return unwrap(res)
}

/** 调整库存。服务端在事务里改库存并追加变更记录，返回值只表示结果。 */
export async function adjustInventory(payload: AdjustPayload) {
  const res = await axios.post('/merchant/inventory/adjust', {
    inventoryId: payload.inventoryId,
    adjustType: payload.adjustType,
    adjustQuantity: payload.adjustQuantity,
    reason: payload.reason,
    minStock: payload.minStock,
  })
  return unwrap(res)
}

/** 变更记录（分页）。 */
export async function getInventoryHistory(params: {
  inventoryId: number
  page?: number
  pageSize?: number
}): Promise<{ list: InventoryHistoryItem[]; total: number }> {
  const res = await axios.get('/merchant/inventory/history', {
    params: {
      inventoryId: params.inventoryId,
      page: params.page ?? 1,
      pageSize: params.pageSize ?? 20,
    },
  })
  const data = unwrap(res)
  const list: InventoryHistoryItem[] = data?.list ?? []
  return { list, total: Number(data?.total ?? list.length) }
}

/** 安全库存。只改安全库存，不动当前库存，也不写变更记录。 */
export async function setMinStock(inventoryId: number, minStock: number) {
  const res = await axios.put(`/merchant/inventory/${inventoryId}/min-stock`, { minStock })
  return unwrap(res)
}

/**
 * 批量导入库存。文件由服务端解析，这里只负责把文件原样 POST 上去，
 * 并把服务端返回的说明（msg）交回给页面显示。
 */
export async function importInventory(file: File): Promise<{ message: string }> {
  const form = new FormData()
  form.append('file', file)
  const res: any = await axios.post('/merchant/inventory/import', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
    timeout: 60000,
  })
  return { message: String(res?.msg ?? '导入完成') }
}
