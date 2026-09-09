import axios from '@/axios'

// 管理员商品管理相关API

export interface ProductItem {
  productId: number
  name: string
  brandName: string
  price: number
  sellerName: string
  auditStatus: number
  createTime: string
  [key: string]: any
}

// 获取商品列表
export const getProductList = async (params: {
  pageNum?: number
  pageSize?: number
  keyword?: string
  status?: number
  productType?: number
}) => {
  try {
    const response = await axios.get(`/admin/products`, {
      params
    })
    return response.data
  } catch (error) {
    console.error('获取商品列表失败:', error)
    throw error
  }
}

// 获取商品审核列表
export const getProductAuditList = async (params: {
  pageNum?: number
  pageSize?: number
  keyword?: string
}) => {
  try {
    const response = await axios.get(`/admin/products/audit`, {
      params
    })
    return response.data
  } catch (error) {
    console.error('获取商品审核列表失败:', error)
    throw error
  }
}

// 审核商品
export const auditProduct = async (productId: number, data: {
  auditStatus: number
  rejectReason?: string
  [key: string]: any
}) => {
  try {
    const response = await axios.put(`/admin/products/${productId}/audit`, data)
    return response.data
  } catch (error) {
    console.error('审核商品失败:', error)
    throw error
  }
}

// 获取商品详情
export const getProductDetail = async (productId: number) => {
  try {
    const response = await axios.get(`/admin/products/${productId}`)
    return response.data
  } catch (error) {
    console.error('获取商品详情失败:', error)
    throw error
  }
}

// 删除商品
export const deleteProduct = async (productId: number) => {
  try {
    const response = await axios.delete(`/admin/products/${productId}`)
    return response.data
  } catch (error) {
    console.error('删除商品失败:', error)
    throw error
  }
}
