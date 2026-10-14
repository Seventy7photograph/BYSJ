import service from '@/axios'
import type { AxiosResponse } from 'axios'

/**
 * 认证接口。端点以后端 AuthController 为准：
 *
 *   POST /login                   登录（username / password / captcha / captchaKey）
 *   GET  /captcha                 图形验证码：Redis 存 5 分钟，校验一次即失效
 *   POST /register                注册
 *   POST /auth/check-user         找回密码第一步：账号是否存在、绑定邮箱是哪个
 *   POST /auth/send-reset-code    发送 6 位邮件验证码
 *   POST /auth/verify-reset-code  校验邮件验证码
 *   POST /auth/reset-password     重置密码
 *
 * 后端没有 logout 映射，原来的 POST /auth/logout 只会拿到 404。退出登录因此是
 * 纯前端动作：页面请调用 useUserStore().logout()，它负责清凭据、停消息轮询并回首页。
 */

/** 后端统一响应体，code 200 为成功。 */
export interface ApiResult<T = unknown> {
  code: number
  msg?: string
  data?: T
}

/** 登录入参。验证码 key 与图形由 GET /captcha 一起下发，一一对应。 */
export interface LoginData {
  username: string
  password: string
  captcha: string
  captchaKey: string
}

/** 注册入参，字段与 user 表对齐。 */
export interface RegisterData {
  /** 1 个人用户 / 2 企业用户（器材商家）。 */
  userType: 1 | 2
  /** 个人为手机号，企业为 18 位统一社会信用代码。 */
  username: string
  /** user.nickname 非空且没有数据库默认值，注册时必须一并提交。 */
  nickname: string
  password: string
  email: string
  phone: string
}

/** 当前登录用户，对应 GET /user/profile。 */
export interface ProfileInfo {
  userId: number
  username: string
  nickname?: string
  avatarUrl?: string
  email?: string
  phone?: string
  /** 用户类型：1 普通用户 / 2 商家 / 3 管理员 / 4 超级管理员。 */
  userType: number
  [key: string]: unknown
}

/** 图形验证码，image 是可直接放进 img src 的 data URI。 */
export interface CaptchaData {
  key: string
  image: string
}

/** 重置密码入参。 */
export interface ResetPasswordData {
  username: string
  email: string
  code: string
  newPassword: string
}

/**
 * 响应拦截器已经把 response.data 解包返回，成功 resolve 的都是业务体。
 * 这里只把 axios 的类型对齐到运行时的实际形态，不做任何转换。
 */
function asApi<T>(request: Promise<AxiosResponse<unknown>>): Promise<ApiResult<T>> {
  return request as unknown as Promise<ApiResult<T>>
}

/**
 * 登录。成功时 data 是 JWT 字符串。
 *
 * 这些认证接口一律 skipErrorToast：登录/注册/找回的失败原因要显示在表单里，
 * 同时再弹一次全局提示只会让用户看到两处重复的红字。
 */
export const login = (data: LoginData) =>
  asApi<string>(service.post('/login', data, { skipErrorToast: true }))

/** 注册。账号重复时后端返回 400，说明在 msg 里。 */
export const register = (data: RegisterData) =>
  asApi<null>(service.post('/register', data, { skipErrorToast: true }))

/**
 * 获取当前用户信息。
 * 刚登录完、store 里还没写入 token 时可以显式带上，否则这次请求发不出去。
 */
export const getCurrentUser = (token?: string) =>
  asApi<ProfileInfo>(
    service.get(
      '/user/profile',
      token ? { headers: { Authorization: `Bearer ${token}` } } : undefined,
    ),
  )

/** 图形验证码。 */
export const getCaptcha = () => asApi<CaptchaData>(service.get('/captcha'))

/** 找回密码第一步：确认账号存在，取回绑定邮箱。 */
export const checkUser = (data: { username: string }) =>
  asApi<{ email: string }>(service.post('/auth/check-user', data, { skipErrorToast: true }))

/** 发送重置密码邮件验证码。 */
export const sendResetPasswordCode = (data: { email: string }) =>
  asApi<null>(service.post('/auth/send-reset-code', data, { skipErrorToast: true }))

/** 校验重置密码邮件验证码。 */
export const verifyResetPasswordCode = (data: { email: string; code: string }) =>
  asApi<null>(service.post('/auth/verify-reset-code', data, { skipErrorToast: true }))

/** 重置密码。 */
export const resetPassword = (data: ResetPasswordData) =>
  asApi<null>(service.post('/auth/reset-password', data, { skipErrorToast: true }))

/**
 * 退出登录（纯前端）。后端没有对应接口，这里只清掉本地凭据，
 * 免得请求打到 404 之后再走一遍错误提示。
 */
export const logout = async (): Promise<ApiResult<null>> => {
  sessionStorage.removeItem('token')
  sessionStorage.removeItem('userInfo')
  localStorage.removeItem('token')
  localStorage.removeItem('userInfo')
  return { code: 200, msg: '已退出登录' }
}

/**
 * 把接口错误转成一句可以直接展示给用户的话。
 *
 * 响应拦截器对 code !== 200 的响应体是直接 reject 的（普通对象，没有 response
 * 字段），HTTP 层失败才是 AxiosError，两种形态都要认。
 */
export function errorText(error: unknown, fallback = '操作失败，请稍后重试'): string {
  const err = error as {
    response?: { data?: { msg?: string; message?: string } }
    request?: unknown
    code?: string
    msg?: string
    message?: string
  }
  const body = err?.response?.data ?? err
  const text = body?.msg || body?.message
  if (text) return text
  if (err?.code === 'ECONNABORTED') return '请求超时，请检查网络后重试'
  if (err?.request) return '无法连接服务器，请检查网络后重试'
  return fallback
}
