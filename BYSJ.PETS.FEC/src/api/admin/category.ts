import axios from '@/axios'

// 管理员分类管理相关API

export interface CategoryItem {
  categoryId: number
  categoryName: string
  categoryCode: string
  parentId: number
  level: number
  sort: number
  [key: string]: any
}

// 获取分类列表
export const getCategoryList = async () => {
  try {
    const response = await axios.get(`/admin/categories`)
    return response.data
  } catch (error) {
    console.error('获取分类列表失败:', error)
    throw error
  }
}

// 获取分类树形结构
export const getCategoryTree = async () => {
  try {
    const response = await axios.get(`/admin/categories/tree`)
    return response.data
  } catch (error) {
    console.error('获取分类树形结构失败:', error)
    throw error
  }
}

// 添加分类
export const addCategory = async (data: {
  categoryName: string
  categoryCode: string
  parentId: number
  sort: number
  [key: string]: any
}) => {
  try {
    const response = await axios.post(`/admin/categories`, data)
    return response.data
  } catch (error) {
    console.error('添加分类失败:', error)
    throw error
  }
}

// 更新分类
export const updateCategory = async (categoryId: number, data: {
  categoryName: string
  categoryCode: string
  parentId: number
  sort: number
  [key: string]: any
}) => {
  try {
    const response = await axios.put(`/admin/categories/${categoryId}`, data)
    return response.data
  } catch (error) {
    console.error('更新分类失败:', error)
    throw error
  }
}

// 删除分类
export const deleteCategory = async (categoryId: number) => {
  try {
    const response = await axios.delete(`/admin/categories/${categoryId}`)
    return response.data
  } catch (error) {
    console.error('删除分类失败:', error)
    throw error
  }
}
