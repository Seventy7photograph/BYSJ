import axios from '@/axios'

// 库存管理相关API

export interface InventoryItem {
  id: number
  productId: number
  productName: string
  productType: string
  skuId: number
  skuAttribute: string
  skuValue: string
  currentStock: number
  minStock: number
  sales: number
  createTime: string
  lastUpdateTime: string
  [key: string]: any
}

export interface InventoryHistoryItem {
  id: number
  changeTime: string
  changeType: string
  beforeStock: number
  afterStock: number
  changeQuantity: number
  reason: string
  operator: string
  [key: string]: any
}

// 模拟库存数据
const mockInventoryData: InventoryItem[] = [
  {
    id: 1,
    productId: 1,
    productName: '尼康 Z6II',
    productType: 'new',
    skuId: 1,
    skuAttribute: '颜色',
    skuValue: '黑色',
    currentStock: 72,
    minStock: 10,
    sales: 120,
    createTime: '2025-12-18 20:13:03',
    lastUpdateTime: '2025-12-29 21:43:30'
  },
  {
    id: 2,
    productId: 2,
    productName: '尼康 Z 24-120 F4S',
    productType: 'new',
    skuId: 2,
    skuAttribute: '版本',
    skuValue: '国行',
    currentStock: 87,
    minStock: 10,
    sales: 95,
    createTime: '2025-12-18 20:13:04',
    lastUpdateTime: '2025-12-29 21:43:35'
  },
  {
    id: 3,
    productId: 3,
    productName: '索尼 A7R5',
    productType: 'new',
    skuId: 3,
    skuAttribute: '套餐',
    skuValue: '单机',
    currentStock: 99,
    minStock: 10,
    sales: 88,
    createTime: '2025-12-18 20:13:05',
    lastUpdateTime: '2025-12-30 21:11:23'
  },
  {
    id: 4,
    productId: 4,
    productName: '尼康 D850',
    productType: 'used',
    skuId: 4,
    skuAttribute: '成色',
    skuValue: '95新',
    currentStock: 6,
    minStock: 5,
    sales: 45,
    createTime: '2025-12-18 20:13:06',
    lastUpdateTime: '2025-12-30 21:13:08'
  },
  {
    id: 5,
    productId: 5,
    productName: '尼康 Z6',
    productType: 'used',
    skuId: 5,
    skuAttribute: '成色',
    skuValue: '90新',
    currentStock: 55,
    minStock: 10,
    sales: 67,
    createTime: '2025-12-18 20:13:08',
    lastUpdateTime: '2025-12-30 21:13:14'
  },
  {
    id: 6,
    productId: 6,
    productName: '尼康 ZR',
    productType: 'rental',
    skuId: 6,
    skuAttribute: '状态',
    skuValue: '可租',
    currentStock: 3,
    minStock: 2,
    sales: 32,
    createTime: '2025-12-18 20:13:13',
    lastUpdateTime: '2025-12-30 21:14:16'
  },
  {
    id: 7,
    productId: 7,
    productName: '尼康 Z 70-200mm f2.8 VR S',
    productType: 'rental',
    skuId: 7,
    skuAttribute: '状态',
    skuValue: '可租',
    currentStock: 20,
    minStock: 5,
    sales: 56,
    createTime: '2025-12-18 18:24:03',
    lastUpdateTime: '2025-12-30 21:14:20'
  }
]

// 模拟库存变更历史数据
const mockInventoryHistory: Record<number, InventoryHistoryItem[]> = {
  1: [
    {
      id: 1,
      changeTime: '2025-12-29 21:43:30',
      changeType: '增加',
      beforeStock: 70,
      afterStock: 72,
      changeQuantity: 2,
      reason: '进货',
      operator: '管理员'
    },
    {
      id: 2,
      changeTime: '2025-12-28 16:01:42',
      changeType: '减少',
      beforeStock: 75,
      afterStock: 70,
      changeQuantity: 5,
      reason: '销售出库',
      operator: '系统'
    }
  ],
  2: [
    {
      id: 3,
      changeTime: '2025-12-29 21:43:35',
      changeType: '增加',
      beforeStock: 85,
      afterStock: 87,
      changeQuantity: 2,
      reason: '进货',
      operator: '管理员'
    }
  ],
  3: [
    {
      id: 4,
      changeTime: '2025-12-30 21:11:23',
      changeType: '减少',
      beforeStock: 100,
      afterStock: 99,
      changeQuantity: 1,
      reason: '销售出库',
      operator: '系统'
    }
  ]
}

// 获取库存列表
export const getInventoryList = async (params: {
  productType?: string
  stockStatus?: string
  keyword?: string
  page?: number
  pageSize?: number
}) => {
  const response = await axios.get('/merchant/inventory', { params })
  return response.data.list || []
}

// 获取库存详情
export const getInventoryDetail = async (inventoryId: number) => {
  const response = await axios.get(`/merchant/inventory/${inventoryId}`)
  return response.data
}

// 调整库存
export const adjustInventory = async (data: {
  inventoryId: number
  adjustType: '增加' | '减少' | '直接设置'
  adjustQuantity: number
  reason?: string
  minStock?: number
}) => {
  const response = await axios.post('/merchant/inventory/adjust', data)
  return response
}

// 获取库存变更历史
export const getInventoryHistory = async (params: {
  inventoryId: number
  page?: number
  pageSize?: number
}) => {
  const response = await axios.get('/merchant/inventory/history', { params })
  return response.data.list || []
}

// 批量导入库存
export const batchImportInventory = async (file: File) => {
  // 后端暂时没有实现该接口
  console.warn('后端暂未实现批量导入库存接口')
  return Promise.resolve({})
}

// 设置安全库存
export const setMinStock = async (inventoryId: number, minStock: number) => {
  const response = await axios.put(`/merchant/inventory/${inventoryId}/min-stock`, { minStock })
  return response
}
