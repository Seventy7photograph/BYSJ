import axios from '@/axios'

// 商品相关API

export interface ProductItem {
  productId: number
  name: string
  brandName: string
  price: number
  originalPrice: number
  stock: number
  imageUrl: string
  categoryId: number
  [key: string]: any
}

export interface ProductDetail {
  productId: number
  name: string
  brandName: string
  price: number
  originalPrice: number
  stock: number
  imageUrl: string
  description: string
  specifications: Record<string, any>
  categoryId: number
  sellerId: number
  sellerName: string
  [key: string]: any
}

// 获取商品列表
export const getProductList = async (params: {
  category?: string
  brand?: string
  type?: string
  keyword?: string
  sort?: string
  quality?: string
  condition?: string
  productType?: number
  priceRange?: string
  pageNum?: number
  pageSize?: number
}) => {
  try {
    const response = await axios.get(`/shop/products`, {
      params
    })
    return response.data
  } catch (error) {
    console.error('获取商品列表失败:', error)
    throw error
  }
}

// 获取商品详情
export const getProductDetail = async (productId: number) => {
  try {
    const response = await axios.get(`/shop/products/${productId}`)
    // 处理后端返回的Result对象格式（响应拦截器已经处理过）
    if (response.code === 200) {
      return response.data
    } else {
      throw new Error(response.message || '获取商品详情失败')
    }
  } catch (error) {
    console.error('获取商品详情失败:', error)
    throw error
  }
}

// 获取相关商品推荐
export const getRelatedProducts = async (params: {
  categoryId: number
  limit?: number
  productId?: number
}) => {
  try {
    const response = await axios.get(`/shop/related`, {
      params
    })
    // 处理后端返回的Result对象格式
    if (response.data && response.data.data) {
      return response.data.data
    } else if (response.data) {
      return response.data
    } else {
      return []
    }
  } catch (error) {
    console.error('获取相关商品失败:', error)
    return []
  }
}

// 获取随机商品
export const getRandomProducts = async (params: {
  pageNum?: number
  pageSize?: number
  quality?: string
}) => {
  try {
    const response = await axios.get(`/shop/random-products`, {
      params
    })
    return response.data
  } catch (error) {
    console.error('获取随机商品失败:', error)
    throw error
  }
}
