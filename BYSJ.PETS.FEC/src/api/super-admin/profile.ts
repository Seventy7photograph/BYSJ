import service from '@/axios'
import { httpGet, httpPut, type Result } from './shared'

/**
 * 超管自己的账号资料（走公共的 /user/** 接口，身份由令牌决定，无需超管专属接口）。
 *
 * 原页面用的是 npm 的裸 axios 再手写 Authorization 头、再手拼 baseURL，
 * 既绕开了响应拦截器的 401/403 处理，也与全局配置漂移。现在统一走 @/axios。
 */

export interface ProfileUser {
  userId: number
  username: string
  nickname: string | null
  phone: string | null
  email: string | null
  avatarUrl: string | null
  gender: number | null
  realName: string | null
  idCard: string | null
  status: number
  userType: number
  createTime: string | null
  updateTime: string | null
}

export interface ProfilePayload {
  nickname: string
  phone: string
  email: string
  gender: number
  realName: string
  idCard: string
}

export async function fetchProfile(): Promise<ProfileUser> {
  return httpGet<ProfileUser>('/user/profile')
}

/** 后端只回写这些字段（UserController 的白名单），其它字段传了也不会存。 */
export async function updateProfile(payload: ProfilePayload): Promise<ProfileUser> {
  return httpPut<ProfileUser>('/user/profile', payload)
}

export async function changePassword(oldPassword: string, newPassword: string): Promise<string> {
  return httpPut<string>('/user/password', { oldPassword, newPassword })
}

/**
 * 头像走唯一的文件入口 POST /files/upload（bizType=avatar）。
 * 后端在这一个请求里就写回了 user.avatar_url，不需要再补一次调用。
 */
export async function uploadAvatar(file: File): Promise<string> {
  const form = new FormData()
  form.append('file', file)
  form.append('bizType', 'avatar')
  const body = (await service.post('/files/upload', form, {
    // 实例默认头是 application/json，axios 会把 FormData 序列化成 JSON，必须显式覆盖。
    headers: { 'Content-Type': 'multipart/form-data' },
    timeout: 60000,
  })) as unknown as Result<{ url: string }>
  const url = body?.data?.url
  if (!url) throw new Error('上传失败：服务端未返回文件地址')
  return url
}
