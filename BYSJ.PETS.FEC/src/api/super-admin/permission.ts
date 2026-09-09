import axios from '@/axios'

// 超级管理员-权限管理相关API

export interface PermissionItem {
  permissionId: number
  permissionName: string
  permissionCode: string
  parentId: number
  level: number
  sort: number
  [key: string]: any
}

export interface RoleItem {
  roleId: number
  roleName: string
  roleCode: string
  description: string
  [key: string]: any
}

// 获取权限列表
export const getPermissionList = async () => {
  try {
    const response = await axios.get(`/super-admin/permissions`)
    return response.data
  } catch (error) {
    console.error('获取权限列表失败:', error)
    throw error
  }
}

// 获取权限树形结构
export const getPermissionTree = async () => {
  try {
    const response = await axios.get(`/super-admin/permissions/tree`)
    return response.data
  } catch (error) {
    console.error('获取权限树形结构失败:', error)
    throw error
  }
}

// 获取角色列表
export const getRoleList = async () => {
  try {
    const response = await axios.get(`/super-admin/roles`)
    return response.data
  } catch (error) {
    console.error('获取角色列表失败:', error)
    throw error
  }
}

// 获取角色详情
export const getRoleDetail = async (roleId: number) => {
  try {
    const response = await axios.get(`/super-admin/roles/${roleId}`)
    return response.data
  } catch (error) {
    console.error('获取角色详情失败:', error)
    throw error
  }
}

// 添加角色
export const addRole = async (data: {
  roleName: string
  roleCode: string
  description: string
  permissionIds: number[]
  [key: string]: any
}) => {
  try {
    const response = await axios.post(`/super-admin/roles`, data)
    return response.data
  } catch (error) {
    console.error('添加角色失败:', error)
    throw error
  }
}

// 更新角色
export const updateRole = async (roleId: number, data: {
  roleName: string
  roleCode: string
  description: string
  permissionIds: number[]
  [key: string]: any
}) => {
  try {
    const response = await axios.put(`/super-admin/roles/${roleId}`, data)
    return response.data
  } catch (error) {
    console.error('更新角色失败:', error)
    throw error
  }
}

// 删除角色
export const deleteRole = async (roleId: number) => {
  try {
    const response = await axios.delete(`/super-admin/roles/${roleId}`)
    return response.data
  } catch (error) {
    console.error('删除角色失败:', error)
    throw error
  }
}

// 分配权限
export const assignPermissions = async (roleId: number, data: {
  permissionIds: number[]
  [key: string]: any
}) => {
  try {
    const response = await axios.put(`/super-admin/roles/${roleId}/permissions`, data)
    return response.data
  } catch (error) {
    console.error('分配权限失败:', error)
    throw error
  }
}
