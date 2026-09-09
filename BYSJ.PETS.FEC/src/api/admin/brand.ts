import axios from '@/axios'

// 管理员品牌管理相关API

export interface BrandItem {
  brandId: number
  brandName: string
  brandLogo: string
  parentId: number
  sort: number
  [key: string]: any
}

// 获取品牌列表
export const getBrandList = async (params: {
  pageNum?: number
  pageSize?: number
  keyword?: string
}) => {
  try {
    const response = await axios.get(`/admin/brands`, {
      params
    })
    return response.data
  } catch (error) {
    console.error('获取品牌列表失败:', error)
    throw error
  }
}

// 获取品牌树形结构
export const getBrandTree = async () => {
  try {
    const response = await axios.get(`/admin/brands/tree`)
    return response.data
  } catch (error) {
    console.error('获取品牌树形结构失败:', error)
    throw error
  }
}

// 添加品牌
export const addBrand = async (data: {
  brandName: string
  brandLogo: string
  parentId: number
  sort: number
  [key: string]: any
}) => {
  try {
    const response = await axios.post(`/admin/brands`, data)
    return response.data
  } catch (error) {
    console.error('添加品牌失败:', error)
    throw error
  }
}

// 更新品牌
export const updateBrand = async (brandId: number, data: {
  brandName: string
  brandLogo: string
  parentId: number
  sort: number
  [key: string]: any
}) => {
  try {
    const response = await axios.put(`/admin/brands/${brandId}`, data)
    return response.data
  } catch (error) {
    console.error('更新品牌失败:', error)
    throw error
  }
}

// 删除品牌
export const deleteBrand = async (brandId: number) => {
  try {
    const response = await axios.delete(`/admin/brands/${brandId}`)
    return response.data
  } catch (error) {
    console.error('删除品牌失败:', error)
    throw error
  }
}
