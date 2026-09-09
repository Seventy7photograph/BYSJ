import axios from '@/axios'

// 管理员商家管理相关API

export interface MerchantItem {
  merchantId: number
  userId: number
  username: string
  shopName: string
  contactName: string
  contactPhone: string
  auditStatus: number
  createTime: string
  [key: string]: any
}

// 获取商家列表
export const getMerchantList = async (params: {
  pageNum?: number
  pageSize?: number
  keyword?: string
  status?: number
}) => {
  try {
    const response = await axios.get(`/admin/merchants`, {
      params
    })
    return response.data
  } catch (error) {
    console.error('获取商家列表失败:', error)
    throw error
  }
}

// 获取商家审核列表
export const getMerchantAuditList = async (params: {
  pageNum?: number
  pageSize?: number
  keyword?: string
}) => {
  try {
    const response = await axios.get(`/admin/merchants/audit`, {
      params
    })
    return response.data
  } catch (error) {
    console.error('获取商家审核列表失败:', error)
    throw error
  }
}

// 审核商家
export const auditMerchant = async (merchantId: number, data: {
  auditStatus: number
  rejectReason?: string
  [key: string]: any
}) => {
  try {
    const response = await axios.put(`/admin/merchants/${merchantId}/audit`, data)
    return response.data
  } catch (error) {
    console.error('审核商家失败:', error)
    throw error
  }
}

// 获取商家详情
export const getMerchantDetail = async (merchantId: number) => {
  try {
    const response = await axios.get(`/admin/merchants/${merchantId}`)
    return response.data
  } catch (error) {
    console.error('获取商家详情失败:', error)
    throw error
  }
}

// 禁用商家
export const disableMerchant = async (merchantId: number) => {
  try {
    const response = await axios.put(`/admin/merchants/${merchantId}/disable`)
    return response.data
  } catch (error) {
    console.error('禁用商家失败:', error)
    throw error
  }
}
