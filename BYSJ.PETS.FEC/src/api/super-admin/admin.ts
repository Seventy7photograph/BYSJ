import axios from '@/axios'

// 超级管理员-管理员管理相关API

export interface AdminItem {
  adminId: number
  userId: number
  username: string
  email: string
  phone: string
  createTime: string
  status: number
  [key: string]: any
}

// 获取管理员列表
export const getAdminList = async (params: {
  pageNum?: number
  pageSize?: number
  keyword?: string
  status?: number
}) => {
  try {
    const response = await axios.get(`/super-admin/admins`, {
      params
    })
    return response.data
  } catch (error) {
    console.error('获取管理员列表失败:', error)
    throw error
  }
}

// 添加管理员
export const addAdmin = async (data: {
  username: string
  password: string
  email: string
  phone: string
  roleId: number
  [key: string]: any
}) => {
  try {
    const response = await axios.post(`/super-admin/admins`, data)
    return response.data
  } catch (error) {
    console.error('添加管理员失败:', error)
    throw error
  }
}

// 更新管理员
export const updateAdmin = async (adminId: number, data: {
  email: string
  phone: string
  roleId: number
  [key: string]: any
}) => {
  try {
    const response = await axios.put(`/super-admin/admins/${adminId}`, data)
    return response.data
  } catch (error) {
    console.error('更新管理员失败:', error)
    throw error
  }
}

// 删除管理员
export const deleteAdmin = async (adminId: number) => {
  try {
    const response = await axios.delete(`/super-admin/admins/${adminId}`)
    return response.data
  } catch (error) {
    console.error('删除管理员失败:', error)
    throw error
  }
}

// 更新管理员状态
export const updateAdminStatus = async (adminId: number, status: number) => {
  try {
    const response = await axios.put(`/super-admin/admins/${adminId}/status`, { status })
    return response.data
  } catch (error) {
    console.error('更新管理员状态失败:', error)
    throw error
  }
}
