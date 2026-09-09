import axios from '@/axios'

// 收藏相关API

export interface FavoriteItem {
  favoriteId: number
  productId: number
  productName: string
  brandName: string
  price: number
  imageUrl: string
  createTime: string
  [key: string]: any
}

// 获取收藏列表
export const getFavoriteList = async (params: {
  pageNum?: number
  pageSize?: number
}) => {
  try {
    const response = await axios.get(`/favorites`, {
      params: {
        page: params.pageNum || 1,
        size: params.pageSize || 12
      }
    })
    return response.data
  } catch (error) {
    console.error('获取收藏列表失败:', error)
    throw error
  }
}

// 添加收藏
export const addFavorite = async (data: {
  productId: number
  [key: string]: any
}) => {
  try {
    const response = await axios.post(`/favorites`, data)
    return response.data
  } catch (error) {
    console.error('添加收藏失败:', error)
    throw error
  }
}

// 取消收藏
export const removeFavorite = async (productId: number) => {
  try {
    const response = await axios.delete(`/favorites`, {
      params: { productId }
    })
    return response.data
  } catch (error) {
    console.error('取消收藏失败:', error)
    throw error
  }
}

// 通过收藏ID取消收藏
export const removeFavoriteById = async (favoriteId: number) => {
  try {
    const response = await axios.delete(`/favorites/${favoriteId}`)
    return response.data
  } catch (error) {
    console.error('取消收藏失败:', error)
    throw error
  }
}

// 批量取消收藏
export const batchRemoveFavorites = async (favoriteIds: number[]) => {
  try {
    const response = await axios.post(`/favorites/batch-delete`, {
      favoriteIds
    })
    return response.data
  } catch (error) {
    console.error('批量取消收藏失败:', error)
    throw error
  }
}

// 检查是否已收藏
export const checkFavorite = async (productId: number) => {
  try {
    const response = await axios.get(`/favorites/check`, {
      params: { productId }
    })
    return response.data
  } catch (error) {
    console.error('检查收藏状态失败:', error)
    throw error
  }
}
