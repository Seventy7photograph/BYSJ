import axios from '@/axios'

// 管理员用户管理相关API

export interface UserItem {
  userId: number
  username: string
  email: string
  phone: string
  userType: number
  createTime: string
  status: number
  [key: string]: any
}

// 获取用户列表
export const getUserList = async (params: {
  pageNum?: number
  pageSize?: number
  keyword?: string
  status?: number
}) => {
  try {
    const response = await axios.get(`/admin/users`, {
      params
    })
    return response.data
  } catch (error) {
    console.error('获取用户列表失败:', error)
    throw error
  }
}

// 获取用户详情
export const getUserDetail = async (userId: number) => {
  try {
    const response = await axios.get(`/admin/users/${userId}`)
    return response.data
  } catch (error) {
    console.error('获取用户详情失败:', error)
    throw error
  }
}

// 更新用户状态
export const updateUserStatus = async (userId: number, status: number) => {
  try {
    const response = await axios.put(`/admin/users/${userId}/status`, { status })
    return response.data
  } catch (error) {
    console.error('更新用户状态失败:', error)
    throw error
  }
}

// 删除用户
export const deleteUser = async (userId: number) => {
  try {
    const response = await axios.delete(`/admin/users/${userId}`)
    return response.data
  } catch (error) {
    console.error('删除用户失败:', error)
    throw error
  }
}

// 更新用户信息
export const updateUser = async (userId: number, data: {
  username?: string
  nickname?: string
  phone?: string
  email?: string
  status?: number
  [key: string]: any
}) => {
  try {
    const response = await axios.put(`/admin/users/${userId}`, data)
    return response.data
  } catch (error) {
    console.error('更新用户信息失败:', error)
    throw error
  }
}
