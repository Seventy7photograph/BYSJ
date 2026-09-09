import axios from '@/axios'

// 订单管理相关API

export interface OrderItem {
  orderId: number
  orderNo: string
  totalAmount: number
  orderStatus: number
  createTime: string
  [key: string]: any
}

// 获取订单列表
export const getOrderList = async (params: {
  type: 'new' | 'used' | 'rental'
  status?: string
  orderNo?: string
  page?: number
  pageSize?: number
}) => {
  // 转换参数名，确保与后端一致
  const transformedParams = {
    type: params.type,
    status: params.status,
    orderNo: params.orderNo,
    pageNum: params.page,
    pageSize: params.pageSize
  }

  const response = await axios.get(`/orders/list`, { params: transformedParams })
  // axios拦截器会自动处理响应，返回response.data
  return response || { list: [], total: 0 }
}

// 获取订单详情
export const getOrderDetail = async (orderId: number | string) => {
  if (typeof orderId === 'string' && orderId.startsWith('ORD')) {
    // 通过订单号获取订单详情
    const response = await axios.get(`/orders/by-order-no/${orderId}`)
    return response
  } else {
    // 通过订单ID获取订单详情
    const response = await axios.get(`/orders/${orderId}`)
    return response
  }
}

// 取消订单
export const cancelOrder = async (orderId: number) => {
  const response = await axios.post(`/orders/${orderId}/cancel`)
  return response
}

// 确认收货
export const confirmReceive = async (orderId: number) => {
  const response = await axios.post(`/orders/${orderId}/confirm-receive`)
  return response
}

// 发货
export const shipOrder = async (orderId: number, params?: any) => {
  const response = await axios.post(`/orders/${orderId}/ship`, params)
  return response
}
