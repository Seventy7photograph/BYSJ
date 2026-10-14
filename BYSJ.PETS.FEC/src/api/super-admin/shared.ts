import service from '@/axios'

/**
 * 超级管理员模块的公共类型与请求辅助。
 *
 * 后端统一返回 { code, msg, data }，axios 响应拦截器已经把这个 body 交给调用方，
 * 所以每个接口函数只负责把 data 取出来。原实现是每个函数自己 try/catch 再
 * console.error 一遍，失败时页面拿到 undefined 还照常渲染"空数据"，错误被吞掉。
 * 现在一律把错误抛给调用方，由页面决定显示哪一档错误态。
 */

export interface Result<T> {
  code: number
  msg: string
  data: T
}

/** MyBatis-Plus 的分页载荷（Page<User> 序列化后的形状）。 */
export interface Paged<T> {
  records: T[]
  total: number
  current: number
  size: number
  pages?: number
}

/**
 * 管理员账号，取自 user 表（user_type = 3）。
 * 注意后端直接返回实体行，包含 password 哈希，读到后立刻丢弃，见 withoutPassword()。
 */
export interface AdminUser {
  userId: number
  username: string
  nickname: string
  phone: string | null
  email: string | null
  avatarUrl: string | null
  status: number
  userType: number
  createTime: string | null
  updateTime: string | null
}

export interface AdminQuery {
  page: number
  pageSize: number
  username?: string
  phone?: string
  status?: number | null
}

export interface AdminForm {
  username: string
  nickname: string
  /** 仅新增与"重置密码"时使用；留空表示不改密码。 */
  password?: string
  phone: string
  email: string
  status: number
}

export interface PermissionItem {
  permissionId: number
  permissionName: string
  permissionCode: string
  url: string
  method: string
  parentId: number | null
  children?: PermissionItem[]
}

export interface PermissionPayload {
  permissionName: string
  permissionCode: string
  url: string
  method: string
  parentId: number | null
}

export interface RoleItem {
  roleId: number
  roleName: string
  roleCode: string
  userType: number
  description: string | null
  createTime?: string | null
  updateTime?: string | null
}

export interface RolePayload {
  roleName: string
  roleCode: string
  userType: number
  description: string
}

/**
 * 权限矩阵的一行分组。
 * 模块 = 权限树根节点下的第一层（系统管理 / 商品管理 / 订单管理…），
 * 模块自身也是一条权限项，所以 node 会同时出现在 items 的第一位。
 */
export interface PermissionModule {
  key: string
  title: string
  code: string
  /** 该模块下的全部权限项，含模块节点自身。 */
  items: PermissionItem[]
}

/* --- 请求辅助 ------------------------------------------------------------ */

export async function httpGet<T>(url: string, params?: Record<string, unknown>): Promise<T> {
  const body = (await service.get(url, { params })) as unknown as Result<T>
  return body?.data as T
}

export async function httpPost<T>(url: string, payload?: unknown): Promise<T> {
  const body = (await service.post(url, payload)) as unknown as Result<T>
  return body?.data as T
}

export async function httpPut<T>(
  url: string,
  payload?: unknown,
  params?: Record<string, unknown>,
): Promise<T> {
  const body = (await service.put(url, payload, { params })) as unknown as Result<T>
  return body?.data as T
}

export async function httpDelete<T>(url: string, params?: Record<string, unknown>): Promise<T> {
  const body = (await service.delete(url, { params })) as unknown as Result<T>
  return body?.data as T
}

/* --- 数据整理 ------------------------------------------------------------ */

/** 列表里的账号不需要密码哈希，读进来就地丢掉，别让它进入页面状态。 */
export function withoutPassword<T extends object>(row: T): T {
  const copy = { ...row } as T & { password?: unknown }
  delete copy.password
  return copy
}

/** 把接口返回值的边界补全，页面就不必到处写 records?.length。 */
export function normalizePage<T>(page: Paged<T> | null | undefined): Paged<T> {
  return {
    records: Array.isArray(page?.records) ? page.records : [],
    total: Number(page?.total ?? 0),
    current: Number(page?.current ?? 1),
    size: Number(page?.size ?? 10),
    pages: page?.pages,
  }
}

/** 扁平化权限树，父节点排在其子节点之前。 */
export function flattenPermissions(nodes: PermissionItem[] | null | undefined): PermissionItem[] {
  const out: PermissionItem[] = []
  const walk = (list: PermissionItem[] | null | undefined) => {
    for (const node of list ?? []) {
      out.push(node)
      walk(node.children)
    }
  }
  walk(nodes)
  return out
}

/** 权限模块分组：优先用根节点下的第一层，单层树则退化为根节点自身。 */
export function buildPermissionModules(tree: PermissionItem[] | null | undefined): PermissionModule[] {
  const modules: PermissionModule[] = []
  for (const root of tree ?? []) {
    const children = Array.isArray(root.children) ? root.children : []
    const hasGrandChildren = children.some((child) => (child.children?.length ?? 0) > 0)
    if (children.length > 0 && hasGrandChildren) {
      for (const child of children) {
        const items = [child, ...flattenPermissions(child.children)]
        modules.push({
          key: String(child.permissionId),
          title: child.permissionName,
          code: child.permissionCode,
          items,
        })
      }
    } else {
      const items = [root, ...flattenPermissions(children)]
      modules.push({
        key: String(root.permissionId),
        title: root.permissionName,
        code: root.permissionCode,
        items,
      })
    }
  }
  return modules
}

/** 一条权限及其全部后代 id —— 勾选父项即代表勾选它这一支。 */
export function collectPermissionIds(node: PermissionItem): number[] {
  return [node.permissionId, ...flattenPermissions(node.children).map((item) => item.permissionId)]
}

/** 在树里按 id 找节点。 */
export function findPermission(
  nodes: PermissionItem[] | null | undefined,
  permissionId: number,
): PermissionItem | null {
  for (const node of nodes ?? []) {
    if (node.permissionId === permissionId) return node
    const hit = findPermission(node.children, permissionId)
    if (hit) return hit
  }
  return null
}

/**
 * 把"数据库外键约束"这类后端原文翻译成人话。
 * 后端删除失败时会把 MySQL 的英文报错原样塞进 msg，直接弹给管理员没有意义。
 */
export function readableError(error: unknown, fallback: string): string {
  const raw =
    error instanceof Error
      ? error.message
      : typeof error === 'string'
        ? error
        : ((error as { msg?: string })?.msg ?? '')
  const text = String(raw || '').trim()
  if (!text) return fallback
  if (/foreign key|constraint/i.test(text)) {
    return '该记录已被其它业务数据引用，数据库拒绝删除，请改为停用或先解除引用'
  }
  if (/Duplicate entry|1062/i.test(text)) {
    return '同样的记录已经存在，请换一个名称或编码'
  }
  return text.length > 120 ? `${text.slice(0, 120)}…` : text
}
