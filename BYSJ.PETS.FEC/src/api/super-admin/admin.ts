import {
  httpDelete,
  httpGet,
  httpPost,
  httpPut,
  normalizePage,
  withoutPassword,
  type AdminForm,
  type AdminQuery,
  type AdminUser,
  type Paged,
} from './shared'

/**
 * 管理员账号（user_type = 3）的增删改查与启停。
 *
 * 后端事实（SuperAdminController）：
 *   GET    /super-admin/admins         参数 page / pageSize / username / phone / status
 *   POST   /super-admin/admins         请求体是 User，后端强制 user_type = 3 并加密密码
 *   PUT    /super-admin/admins/{id}    接受 username / nickname / phone / email / status（可选 password）
 *   DELETE /super-admin/admins/{id}    物理删除
 *   PUT    /super-admin/admins/{id}/status?status=0|1   status 是查询参数，不是请求体
 *
 * 原实现有两处对不上：查询参数写的是 pageNum / keyword（后端叫 page / username，
 * 于是分页永远停在第 1 页、用户名搜索完全无效），启停把 status 放进了请求体
 * （后端用 @RequestParam 取值，收不到就 400）。
 */

export async function fetchAdmins(query: AdminQuery): Promise<Paged<AdminUser>> {
  const page = await httpGet<Paged<AdminUser>>('/super-admin/admins', {
    page: query.page,
    pageSize: query.pageSize,
    username: query.username || undefined,
    phone: query.phone || undefined,
    status: query.status === null || query.status === undefined ? undefined : query.status,
  })
  const normalized = normalizePage(page)
  return { ...normalized, records: normalized.records.map(withoutPassword) }
}

/** 只关心数量时用 pageSize=1，避免把整页账号拉回来。 */
export async function countAdmins(status?: number): Promise<number> {
  const page = await httpGet<Paged<AdminUser>>('/super-admin/admins', {
    page: 1,
    pageSize: 1,
    status,
  })
  return Number(page?.total ?? 0)
}

export async function createAdmin(form: AdminForm): Promise<string> {
  return httpPost<string>('/super-admin/admins', {
    username: form.username,
    nickname: form.nickname,
    password: form.password,
    phone: form.phone,
    email: form.email,
    status: form.status,
    userType: 3,
  })
}

export async function updateAdmin(userId: number, form: AdminForm): Promise<string> {
  const payload: Record<string, unknown> = {
    username: form.username,
    nickname: form.nickname,
    phone: form.phone,
    email: form.email,
    status: form.status,
  }
  // 编辑时留空表示不改密码：后端只在这个字段非空时才覆盖。
  if (form.password) payload.password = form.password
  return httpPut<string>(`/super-admin/admins/${userId}`, payload)
}

/** 启用 / 停用。status 走查询参数：1 正常，0 停用。 */
export async function setAdminStatus(userId: number, status: number): Promise<string> {
  return httpPut<string>(`/super-admin/admins/${userId}/status`, undefined, { status })
}

export async function deleteAdmin(userId: number): Promise<string> {
  return httpDelete<string>(`/super-admin/admins/${userId}`)
}
