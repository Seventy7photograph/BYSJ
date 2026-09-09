import axios from '@/axios'

// 店铺管理相关API

export interface ShopInfo {
  shopName: string
  shopType: string
  status: string
  openTime: string
  phone: string
  email: string
  address: string
  description: string
  logo: string
  [key: string]: any
}

export interface AuthInfo {
  status: string
  authType: string
  authTime?: string
  rejectReason?: string
  businessLicense?: string
  idCardFront?: string
  idCardBack?: string
  [key: string]: any
}

export interface SecurityInfo {
  payPasswordSet: boolean
  [key: string]: any
}

// 获取店铺信息
export const getShopInfo = async () => {
  const response = await axios.get('/merchant/shop/info')
  console.log('API响应 - 获取店铺信息:', response.data)
  return response.data.data || response.data
}

// 更新店铺信息
export const updateShopInfo = async (data: {
  shopName: string
  shopType: string
  phone: string
  email: string
  address: string
  description: string
}) => {
  const response = await axios.put('/merchant/shop/info', data)
  console.log('API响应 - 更新店铺信息:', response.data)
  return response.data
}

// 上传店铺logo
export const uploadShopLogo = async (file: File) => {
  const formData = new FormData()
  formData.append('file', file)
  const response = await axios.post('/merchant/shop/upload-logo', formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
  console.log('API响应 - 上传店铺logo:', response.data)
  return response.data
}

// 获取认证信息
export const getAuthInfo = async () => {
  const response = await axios.get('/merchant/shop/auth-info')
  console.log('API响应 - 获取认证信息:', response.data)
  return response.data.data || response.data
}

// 提交认证信息
export const submitAuthInfo = async (data: any) => {
  const response = await axios.post('/merchant/shop/auth-info', data)
  console.log('API响应 - 提交认证信息:', response.data)
  return response.data
}

// 获取安全设置
export const getSecurityInfo = async () => {
  const response = await axios.get('/merchant/shop/security-info')
  console.log('API响应 - 获取安全设置:', response.data)
  return response.data.data || response.data
}

// 修改登录密码
export const changePassword = async (data: {
  oldPassword: string
  newPassword: string
  confirmPassword: string
}) => {
  const response = await axios.post('/merchant/shop/change-password', data)
  console.log('API响应 - 修改登录密码:', response.data)
  return response.data
}

// 设置支付密码
export const setPayPassword = async (data: {
  payPassword: string
  confirmPassword: string
}) => {
  const response = await axios.post('/merchant/shop/set-pay-password', data)
  console.log('API响应 - 设置支付密码:', response.data)
  return response.data
}

// 修改支付密码
export const changePayPassword = async (data: {
  oldPayPassword: string
  newPayPassword: string
  confirmPassword: string
}) => {
  const response = await axios.post('/merchant/shop/change-pay-password', data)
  console.log('API响应 - 修改支付密码:', response.data)
  return response.data
}

// 获取店铺dashboard数据
export const getDashboardData = async () => {
  const response = await axios.get('/merchant/shop/dashboard')
  console.log('API响应 - 获取dashboard数据:', response.data)
  return response.data.data || response.data
}

// 获取最近订单
export const getRecentOrders = async () => {
  const response = await axios.get('/merchant/shop/recent-orders')
  console.log('API响应 - 获取最近订单:', response.data)
  return response.data.data || response.data
}

// 获取图表数据
export const getChartData = async () => {
  const response = await axios.get('/merchant/shop/chart-data')
  console.log('API响应 - 获取图表数据:', response.data)
  return response.data.data || response.data
}

// 获取日历销售数据
export const getCalendarSalesData = async () => {
  const response = await axios.get('/merchant/shop/calendar-data')
  console.log('API响应 - 获取日历销售数据:', response.data)
  // 确保返回正确的结构
  if (response.data.data && response.data.data.salesData) {
    return response.data.data.salesData
  } else if (response.data.salesData) {
    return response.data.salesData
  }
  return {}
}

// 获取器材销售分布数据
export const getProductDistributionData = async () => {
  const response = await axios.get('/merchant/shop/product-distribution')
  console.log('API响应 - 获取器材销售分布数据:', response.data)
  return response.data.data || response.data
}
