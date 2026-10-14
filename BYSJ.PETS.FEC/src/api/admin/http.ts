import service from '@/axios'

/**
 * 管理员后台的统一请求层。
 *
 * 这一层的存在是因为原来的 8 个 api/admin 文件各自决定返回值长什么样：
 * 有的 `return response.data`（拿到 data 载荷），有的 `return service({...})`
 * （拿到 { code, msg, data } 整包），调用方只能靠记忆猜，猜错就是"接口成功但页面空白"。
 *
 * `@/axios` 的响应拦截器已经把 HTTP 响应体交到调用方，并在 code !== 200 时
 * reject（错误提示由拦截器统一弹出）。因此这里只做两件事：
 *   1. 把整包拆成 data 载荷，让每个函数的返回值就是它名字所描述的东西；
 *   2. 失败向上抛，页面只需 catch 后进入错误态，不必再自己 console.error。
 */

export interface Envelope<T> {
  code: number
  msg?: string
  data: T
}

/** MyBatis-Plus 分页对象。 */
export interface Paged<T> {
  records: T[]
  total: number
  size: number
  current: number
  pages: number
}

export async function apiGet<T>(url: string, params?: Record<string, unknown>): Promise<T> {
  const body = (await service.get(url, { params })) as unknown as Envelope<T>
  return body?.data as T
}

export async function apiPost<T>(url: string, data?: unknown): Promise<T> {
  const body = (await service.post(url, data)) as unknown as Envelope<T>
  return body?.data as T
}

export async function apiPut<T>(
  url: string,
  data?: unknown,
  params?: Record<string, unknown>,
): Promise<T> {
  const body = (await service.put(url, data, { params })) as unknown as Envelope<T>
  return body?.data as T
}

export async function apiDelete<T>(url: string): Promise<T> {
  const body = (await service.delete(url)) as unknown as Envelope<T>
  return body?.data as T
}

/**
 * 把数据库层的报错翻译成管理员能据以行动的一句话。
 *
 * 分类和品牌的删除在后端只做了"有没有子节点"的判断，被商品引用时直接把 MySQL
 * 的外键报错抛给前端（`Cannot delete or update a parent row: a foreign key
 * constraint fails ...`）。这句话对管理员没有意义，这里换成可执行的说明。
 */
export function humanizeError(
  error: unknown,
  options: { occupiedBy?: string; fallback?: string } = {},
): string {
  const raw = error instanceof Error ? error.message : ''
  const fallback = options.fallback ?? '操作失败，请稍后重试'
  if (!raw) return fallback
  if (/foreign key constraint/i.test(raw)) {
    return options.occupiedBy
      ? `${options.occupiedBy}已被商品占用，无法删除。请先把这些商品改到其它${options.occupiedBy}，再回来删除。`
      : '该项已被其它数据引用，无法删除。请先处理引用它的数据。'
  }
  if (/Duplicate entry/i.test(raw)) return '已存在同名或同编码的记录，请修改后重试。'
  if (/doesn't have a default value/i.test(raw)) {
    return '数据库拒绝了这次写入：缺少非空字段的默认值。'
  }
  return raw
}

/**
 * user 表的对外形状。后端目前把 `password` 散列一起返回了（见 AdminController），
 * 这里刻意不声明该字段：页面不读、不渲染，避免把散列带到视图层。
 */
export interface AdminUser {
  userId: number
  username: string
  nickname?: string | null
  userType: number
  realName?: string | null
  idCard?: string | null
  businessLicense?: string | null
  legalIdFront?: string | null
  legalIdBack?: string | null
  phone?: string | null
  email?: string | null
  gender?: number | null
  status: number
  createTime?: string | null
  updateTime?: string | null
  avatarUrl?: string | null
  shopName?: string | null
  businessType?: string | null
  shopStatus?: number | null
  openTime?: string | null
  shopAddress?: string | null
  shopDescription?: string | null
  shopLogoUrl?: string | null
  hasShop?: number | null
}
