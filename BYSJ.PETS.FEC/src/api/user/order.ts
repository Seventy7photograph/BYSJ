import axios from '@/axios'

// 订单相关API

export interface OrderItem {
  orderId: number
  orderNo: string
  totalAmount: number
  orderStatus: number
  createTime: string
  [key: string]: any
}

export interface OrderDetail {
  orderId: number
  orderNo: string
  totalAmount: number
  shippingFee: number
  payAmount: number
  orderStatus: number
  paymentMethod: string
  recipient: string
  phone: string
  address: string
  createTime: string
  updateTime: string
  orderItems: OrderItemDetail[]
  [key: string]: any
}

export interface OrderItemDetail {
  orderItemId: number
  productId: number
  productName: string
  price: number
  quantity: number
  imageUrl: string
  [key: string]: any
}

// 获取订单列表
export const getOrderList = async (params: {
  pageNum?: number
  pageSize?: number
  status?: number
}) => {
  try {
    const response = await axios.get(`/order/list`, {
      params
    })
    return response.data
  } catch (error) {
    console.error('获取订单列表失败:', error)
    throw error
  }
}

// 获取订单详情
export const getOrderDetail = async (orderId: number) => {
  try {
    const response = await axios.get(`/order/${orderId}`)
    return response.data
  } catch (error) {
    console.error('获取订单详情失败:', error)
    throw error
  }
}

// 确认订单
export const confirmOrder = async (data: {
  productIds: number[]
  addressId: number
  [key: string]: any
}) => {
  try {
    const response = await axios.post(`/order/confirm`, data)
    return response.data
  } catch (error) {
    console.error('确认订单失败:', error)
    throw error
  }
}

// 支付订单
export const payOrder = async (paymentId: number, data: {
  paymentMethod: string
  [key: string]: any
}) => {
  try {
    const response = await axios.post(`/order/payment/${paymentId}`, data)
    return response.data
  } catch (error) {
    console.error('支付订单失败:', error)
    throw error
  }
}

// 取消订单
export const cancelOrder = async (orderId: number) => {
  try {
    const response = await axios.put(`/order/${orderId}/cancel`)
    return response.data
  } catch (error) {
    console.error('取消订单失败:', error)
    throw error
  }
}

// 确认收货
export const confirmReceipt = async (orderId: number) => {
  try {
    const response = await axios.put(`/order/${orderId}/receipt`)
    return response.data
  } catch (error) {
    console.error('确认收货失败:', error)
    throw error
  }
}
