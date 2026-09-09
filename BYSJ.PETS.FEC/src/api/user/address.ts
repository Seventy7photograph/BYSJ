import axios from '@/axios'

// 地址相关API

export interface AddressItem {
  addressId: number
  userId: number
  recipient: string
  phone: string
  province: string
  city: string
  district: string
  detail: string
  isDefault: boolean
  [key: string]: any
}

// 获取地址列表
export const getAddressList = async () => {
  try {
    const response = await axios.get(`/user/addresses`)
    return response.data
  } catch (error) {
    console.error('获取地址列表失败:', error)
    throw error
  }
}

// 获取地址详情
export const getAddressDetail = async (addressId: number) => {
  try {
    const response = await axios.get(`/user/addresses/${addressId}`)
    return response.data
  } catch (error) {
    console.error('获取地址详情失败:', error)
    throw error
  }
}

// 添加地址
export const addAddress = async (data: {
  recipient: string
  phone: string
  province: string
  city: string
  district: string
  detail: string
  isDefault: boolean
  [key: string]: any
}) => {
  try {
    const response = await axios.post(`/user/addresses`, data)
    return response.data
  } catch (error) {
    console.error('添加地址失败:', error)
    throw error
  }
}

// 更新地址
export const updateAddress = async (data: {
  addressId: number
  recipient: string
  phone: string
  province: string
  city: string
  district: string
  detail: string
  isDefault: boolean
  [key: string]: any
}) => {
  try {
    const response = await axios.put(`/user/addresses`, data)
    return response.data
  } catch (error) {
    console.error('更新地址失败:', error)
    throw error
  }
}

// 删除地址
export const deleteAddress = async (addressId: number) => {
  try {
    const response = await axios.delete(`/user/addresses/${addressId}`)
    return response.data
  } catch (error) {
    console.error('删除地址失败:', error)
    throw error
  }
}

// 设置默认地址
export const setDefaultAddress = async (addressId: number) => {
  try {
    const response = await axios.put(`/user/addresses/${addressId}/default`)
    return response.data
  } catch (error) {
    console.error('设置默认地址失败:', error)
    throw error
  }
}
