import axios from '@/axios'

// 购物车相关API

export interface CartItem {
  cartId: number
  productId: number
  productName: string
  price: number
  quantity: number
  imageUrl: string
  stock: number
  [key: string]: any
}

// 获取购物车列表
export const getCartList = async () => {
  try {
    const response = await axios.get(`/cart/items`)
    return response.data
  } catch (error) {
    console.error('获取购物车列表失败:', error)
    throw error
  }
}

// 添加商品到购物车
export const addToCart = async (data: {
  productId: number
  quantity: number
  [key: string]: any
}) => {
  try {
    const response = await axios.post(`/cart/add`, data)
    return response.data
  } catch (error) {
    console.error('添加商品到购物车失败:', error)
    throw error
  }
}

// 更新购物车商品数量
export const updateCartItem = async (cartId: number, data: {
  quantity: number
  [key: string]: any
}) => {
  try {
    const response = await axios.put(`/cart/items/${cartId}`, data)
    return response.data
  } catch (error) {
    console.error('更新购物车商品数量失败:', error)
    throw error
  }
}

// 删除购物车商品
export const deleteCartItem = async (cartId: number) => {
  try {
    const response = await axios.delete(`/cart/items/${cartId}`)
    return response.data
  } catch (error) {
    console.error('删除购物车商品失败:', error)
    throw error
  }
}

// 清空购物车
export const clearCart = async () => {
  try {
    const response = await axios.delete(`/cart/clear`)
    return response.data
  } catch (error) {
    console.error('清空购物车失败:', error)
    throw error
  }
}

// 批量添加商品到购物车
export const batchAddToCart = async (data: {
  productIds: number[]
  [key: string]: any
}) => {
  try {
    const response = await axios.post(`/cart/batch-add`, data)
    return response.data
  } catch (error) {
    console.error('批量添加商品到购物车失败:', error)
    throw error
  }
}
