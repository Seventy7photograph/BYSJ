import { apiDelete, apiGet, apiPut, type AdminUser, type Paged } from './http'

// 管理员用户管理相关 API

export interface UserQuery {
  pageNum?: number
  pageSize?: number
  /** 后端按 username / nickname / phone 模糊匹配。 */
  keyword?: string
  /** 0 已停用 / 1 正常 / 2 待审核。 */
  status?: number
}

/**
 * 用户资料更新。
 *
 * 字段全部必填：后端 updateUser 是无条件覆盖（`existingUser.setNickname(user.getNickname())`），
 * 少传一个字段就会把它写成 null，username 为空还会直接触发非空约束报错。
 * 调用方请带上整行数据，只修改要改的那几项。
 */
export interface UserUpdate {
  username: string
  nickname: string | null
  phone: string | null
  email: string | null
  status: number
}

/**
 * 普通用户列表。
 *
 * 注意：后端把这个接口的 user_type = 1 约束和 keyword 的 or 条件写在同一个
 * WHERE 里（`user_type = 1 AND username like ? OR nickname like ?`），关键词
 * 检索会绕过用户类型限制。调用方因此要按 userType 过滤一次，见 UserManagement.vue。
 */
export function getUserList(params: UserQuery): Promise<Paged<AdminUser>> {
  return apiGet<Paged<AdminUser>>('/admin/users', { ...params })
}

export function getUserDetail(userId: number): Promise<AdminUser> {
  return apiGet<AdminUser>(`/admin/users/${userId}`)
}

/** 停用 / 启用账号。status: 0 停用，1 正常。 */
export function updateUserStatus(userId: number, status: number): Promise<unknown> {
  return apiPut<unknown>(`/admin/users/${userId}/status`, { status })
}

export function updateUser(userId: number, data: UserUpdate): Promise<unknown> {
  return apiPut<unknown>(`/admin/users/${userId}`, data)
}

export function deleteUser(userId: number): Promise<unknown> {
  return apiDelete<unknown>(`/admin/users/${userId}`)
}
