import axios from '@/axios'

/**
 * 店铺管理接口，路径对齐 ShopManageController（前缀 /merchant/shop）：
 *   GET  /info                   店铺资料
 *   PUT  /info                   更新店铺资料
 *   POST /upload-logo            店铺 logo（落到 user.shop_logo_url，不再覆盖个人头像）
 *   POST /upload-auth-material   资质材料（营业执照/法人证件，允许 PNG/JPG/PDF）
 *   GET  /auth-info              认证状态与已交材料
 *   POST /auth-info              提交认证
 *   GET  /security-info          安全设置
 *   POST /change-password        修改登录密码
 *   POST /set-pay-password       设置支付密码
 *   POST /change-pay-password    修改支付密码
 *   以及工作台用的 dashboard / recent-orders / chart-data / calendar-data / product-distribution
 *
 * 这份文件原来每个函数都往控制台打一遍响应体（含令牌上下文下的业务数据），
 * 并且两层 data 取值不一致（有的 .data.data，有的 .data）。现在统一拆 Result 外壳。
 */

export interface ShopInfo {
  shopName: string
  /** personal 个人店铺 / enterprise 企业店铺 */
  shopType: string
  /** normal 正常 / pending 审核中 / closed 已关闭 */
  status: string
  openTime: string
  phone: string
  email: string
  address: string
  description: string
  logo: string
}

export interface ShopAuthInfo {
  /** approved 已认证 / pending 审核中 / rejected 已驳回 / closed 未认证 */
  status: string
  authType: string
  authTime: string
  rejectReason?: string
  businessLicense: string
  idCardFront: string
  idCardBack: string
}

export interface ShopSecurityInfo {
  payPasswordSet: boolean
}

export interface UploadedMaterial {
  url: string
  id: number
}

function unwrap(res: any): any {
  return res?.data ?? res
}

/** 店铺资料。 */
export async function getShopInfo(): Promise<ShopInfo> {
  const res = await axios.get('/merchant/shop/info')
  return unwrap(res) ?? ({} as ShopInfo)
}

/**
 * 更新店铺资料。只提交要改的字段：后端按 key 存在与否逐个写入,
 * 少传一个字段就等于不动它。
 */
export async function updateShopInfo(data: Partial<ShopInfo>) {
  const res = await axios.put('/merchant/shop/info', data)
  return unwrap(res)
}

/**
 * 上传店铺 logo。
 *
 * 用店铺自己的端点而不是通用 /files/upload：只有它会写 user.shop_logo_url，
 * logo 才会出现在店铺页与前台。通用上传只会把文件放进图库，页面刷新即丢。
 */
export async function uploadShopLogo(file: File): Promise<UploadedMaterial> {
  const form = new FormData()
  form.append('file', file)
  const res: any = await axios.post('/merchant/shop/upload-logo', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
    timeout: 60000,
  })
  const data = unwrap(res)
  if (!data?.url) throw new Error('上传失败：服务端未返回文件地址')
  return { url: data.url, id: Number(data.id ?? 0) }
}

/**
 * 上传资质材料。这个端点允许 PDF（营业执照常见 PDF），
 * 上传只拿到 URL，真正归属到「营业执照 / 身份证正反面」由提交认证时决定。
 */
export async function uploadAuthMaterial(file: File): Promise<UploadedMaterial> {
  const form = new FormData()
  form.append('file', file)
  const res: any = await axios.post('/merchant/shop/upload-auth-material', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
    timeout: 60000,
  })
  const data = unwrap(res)
  if (!data?.url) throw new Error('上传失败：服务端未返回文件地址')
  return { url: data.url, id: Number(data.id ?? 0) }
}

/** 认证信息。 */
export async function getAuthInfo(): Promise<ShopAuthInfo> {
  const res = await axios.get('/merchant/shop/auth-info')
  return unwrap(res) ?? ({} as ShopAuthInfo)
}

/** 提交认证材料。后端会把店铺状态置为「审核中」并等待平台审核。 */
export async function submitAuthInfo(data: {
  businessLicense?: string
  legalIdFront?: string
  legalIdBack?: string
}) {
  const res = await axios.post('/merchant/shop/auth-info', data)
  return unwrap(res)
}

/** 安全设置。 */
export async function getSecurityInfo(): Promise<ShopSecurityInfo> {
  const res = await axios.get('/merchant/shop/security-info')
  return unwrap(res) ?? { payPasswordSet: false }
}

/** 修改登录密码。 */
export async function changePassword(data: {
  oldPassword: string
  newPassword: string
  confirmPassword: string
}) {
  const res = await axios.post('/merchant/shop/change-password', data)
  return unwrap(res)
}

/** 设置支付密码。 */
export async function setPayPassword(data: { payPassword: string; confirmPassword: string }) {
  const res = await axios.post('/merchant/shop/set-pay-password', data)
  return unwrap(res)
}

/** 修改支付密码。 */
export async function changePayPassword(data: {
  oldPayPassword: string
  newPayPassword: string
  confirmPassword: string
}) {
  const res = await axios.post('/merchant/shop/change-pay-password', data)
  return unwrap(res)
}

/* --- 工作台（商家首页用） -------------------------------------------------- */

export async function getDashboardData() {
  const res = await axios.get('/merchant/shop/dashboard')
  return unwrap(res)
}

export async function getRecentOrders() {
  const res = await axios.get('/merchant/shop/recent-orders')
  return unwrap(res)
}

export async function getChartData() {
  const res = await axios.get('/merchant/shop/chart-data')
  return unwrap(res)
}

/** 日历销售数据：后端包了一层 salesData。 */
export async function getCalendarSalesData() {
  const res = await axios.get('/merchant/shop/calendar-data')
  const data = unwrap(res)
  return data?.salesData ?? {}
}

export async function getProductDistributionData() {
  const res = await axios.get('/merchant/shop/product-distribution')
  return unwrap(res)
}
