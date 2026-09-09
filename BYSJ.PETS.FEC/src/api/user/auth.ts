import service from '@/axios'

// 认证相关API

export interface LoginData {
  username: string
  password: string
  [key: string]: any
}

export interface RegisterData {
  username: string
  password: string
  confirmPassword: string
  email: string
  phone: string
  [key: string]: any
}

export interface UserInfo {
  userId: number
  username: string
  email: string
  phone: string
  userType: number
  [key: string]: any
}

// 登录
export const login = async (data: LoginData) => {
  try {
    const response = await service.post(`/login`, data)
    return response
  } catch (error) {
    console.error('登录失败:', error)
    throw error
  }
}

// 注册
export const register = async (data: RegisterData) => {
  try {
    const response = await service.post(`/auth/register`, data)
    return response.data
  } catch (error) {
    console.error('注册失败:', error)
    throw error
  }
}

// 退出登录
export const logout = async () => {
  try {
    const response = await service.post(`/auth/logout`)
    return response.data
  } catch (error) {
    console.error('退出登录失败:', error)
    throw error
  }
}

// 获取当前用户信息
export const getCurrentUser = async () => {
  try {
    const response = await service.get(`/user/profile`)
    return response
  } catch (error) {
    console.error('获取用户信息失败:', error)
    throw error
  }
}

// 验证用户是否存在并获取邮箱
export const checkUser = async (data: { username: string }) => {
  try {
    const response = await service.post(`/auth/check-user`, data)
    return response
  } catch (error) {
    console.error('验证用户失败:', error)
    throw error
  }
}

// 发送重置密码验证码
export const sendResetPasswordCode = async (data: { email: string }) => {
  try {
    const response = await service.post(`/auth/send-reset-code`, data)
    return response
  } catch (error) {
    console.error('发送验证码失败:', error)
    throw error
  }
}

// 验证重置密码验证码
export const verifyResetPasswordCode = async (data: { email: string; code: string }) => {
  try {
    const response = await service.post(`/auth/verify-reset-code`, data)
    return response
  } catch (error) {
    console.error('验证验证码失败:', error)
    throw error
  }
}

// 重置密码
export const resetPassword = async (data: { username: string; email: string; code: string; newPassword: string }) => {
  try {
    const response = await service.post(`/auth/reset-password`, data)
    return response
  } catch (error) {
    console.error('重置密码失败:', error)
    throw error
  }
}
