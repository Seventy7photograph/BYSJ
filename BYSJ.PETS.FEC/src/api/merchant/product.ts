import axios from '@/axios'

// 商品管理相关API

export interface ProductItem {
  productId: number
  name: string
  price: number
  stock: number
  sales: number
  status: number
  createTime: string
  skus?: SkuItem[]
  [key: string]: any
}

export interface SkuItem {
  skuId: number
  attribute: string
  value: string
  price: number
  stock: number
  [key: string]: any
}

// 获取商品列表
export const getProductList = async (params: {
  type: 'new' | 'used' | 'rental'
  status?: string
  keyword?: string
  page?: number
  pageSize?: number
}) => {
  try {
    console.log('调用getProductList，参数:', params)
    const response = await axios.get(`/merchant/product/list`, {
      params: {
        type: params.type,
        status: params.status,
        keyword: params.keyword,
        pageNum: params.page,
        pageSize: params.pageSize
      }
    })
    console.log('getProductList响应:', response)

    // 检查response是否存在
    if (!response) {
      console.error('响应为空')
      return []
    }

    // 检查response.data是否存在
    if (!response.data) {
      console.error('响应数据为空')
      return []
    }

    // 检查list是否为数组
    if (!Array.isArray(response.data.list)) {
      console.error('响应数据中的list不是数组')
      return []
    }

    // 返回列表数据，并将总数存储在自定义属性中
    const list = response.data.list || []
    ;(list as any).total = response.data.total || 0

    return list
  } catch (error) {
    console.error('获取商品列表失败:', error)
    return []
  }
}

// 获取商品详情
export const getProductDetail = async (productId: number) => {
  try {
    const response = await axios.get(`/merchant/product/${productId}`)
    return response.data
  } catch (error) {
    console.error('获取商品详情失败:', error)
    return null
  }
}

// 添加商品
export const addProduct = async (data: any) => {
  try {
    const response = await axios.post(`/merchant/product`, data)
    return response.data
  } catch (error) {
    console.error('添加商品失败:', error)
    throw error
  }
}

// 更新商品
export const updateProduct = async (productId: number, data: any) => {
  try {
    const response = await axios.put(`/merchant/product/${productId}`, data)
    return response.data
  } catch (error) {
    console.error('更新商品失败:', error)
    throw error
  }
}

// 删除商品
export const deleteProduct = async (productId: number) => {
  try {
    const response = await axios.delete(`/merchant/product/${productId}`)
    return response.data
  } catch (error) {
    console.error('删除商品失败:', error)
    throw error
  }
}

// 切换商品状态（上架/下架）
export const toggleProductStatus = async (productId: number, status: number) => {
  try {
    const response = await axios.put(`/merchant/product/${productId}/status`, { status })
    return response.data
  } catch (error) {
    console.error('切换商品状态失败:', error)
    throw error
  }
}

// 获取SKU列表
export const getSkuList = async (productId: number) => {
  try {
    const response = await axios.get(`/merchant/product/${productId}/skus`)
    return response.data
  } catch (error) {
    console.error('获取SKU列表失败:', error)
    return []
  }
}

// 添加SKU
export const addSku = async (productId: number, data: any) => {
  try {
    const response = await axios.post(`/merchant/product/${productId}/skus`, data)
    return response.data
  } catch (error) {
    console.error('添加SKU失败:', error)
    throw error
  }
}

// 更新SKU
export const updateSku = async (productId: number, skuId: number, data: any) => {
  try {
    const response = await axios.put(`/merchant/product/${productId}/skus/${skuId}`, data)
    return response.data
  } catch (error) {
    console.error('更新SKU失败:', error)
    throw error
  }
}

// 删除SKU
export const deleteSku = async (productId: number, skuId: number) => {
  try {
    const response = await axios.delete(`/merchant/product/${productId}/skus/${skuId}`)
    return response.data
  } catch (error) {
    console.error('删除SKU失败:', error)
    throw error
  }
}
