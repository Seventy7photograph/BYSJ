import {
  collectPermissionIds,
  flattenPermissions,
  httpDelete,
  httpGet,
  httpPost,
  httpPut,
  type PermissionItem,
  type PermissionPayload,
  type RoleItem,
  type RolePayload,
} from './shared'

/**
 * 权限项与角色（RBAC 配置面）。
 *
 * 后端事实（SuperAdminController）：
 *   GET    /super-admin/permissions           权限树：parent_id 为 NULL 的根 + 递归 children
 *   POST   /super-admin/permissions
 *   PUT    /super-admin/permissions/{id}
 *   DELETE /super-admin/permissions/{id}      外键 ON DELETE CASCADE：连同子权限与角色绑定一起删
 *   GET    /super-admin/roles
 *   GET    /super-admin/roles/{id}
 *   POST   /super-admin/roles
 *   PUT    /super-admin/roles/{id}
 *   DELETE /super-admin/roles/{id}
 *   GET    /super-admin/roles/{id}/permissions   该角色的权限对象数组
 *   PUT    /super-admin/roles/{id}/permissions   请求体 { permissionIds: number[] }，全量覆盖
 *
 * 原来这里还有一个 getPermissionTree() 打 /super-admin/permissions/tree ——
 * 后端没有这个映射，调用即 404；权限树本身就在 /super-admin/permissions。
 */

export async function fetchPermissionTree(): Promise<PermissionItem[]> {
  const tree = await httpGet<PermissionItem[]>('/super-admin/permissions')
  return Array.isArray(tree) ? tree : []
}

/** 权限树 + 一次扁平化：页面几乎都要扁平列表（计数、查找、选上级）。 */
export async function fetchPermissions(): Promise<{
  tree: PermissionItem[]
  flat: PermissionItem[]
}> {
  const tree = await fetchPermissionTree()
  return { tree, flat: flattenPermissions(tree) }
}

export async function createPermission(payload: PermissionPayload): Promise<string> {
  return httpPost<string>('/super-admin/permissions', payload)
}

export async function updatePermission(
  permissionId: number,
  payload: PermissionPayload,
): Promise<string> {
  return httpPut<string>(`/super-admin/permissions/${permissionId}`, payload)
}

export async function deletePermission(permissionId: number): Promise<string> {
  return httpDelete<string>(`/super-admin/permissions/${permissionId}`)
}

export async function fetchRoles(): Promise<RoleItem[]> {
  const roles = await httpGet<RoleItem[]>('/super-admin/roles')
  return Array.isArray(roles) ? roles : []
}

export async function fetchRoleDetail(roleId: number): Promise<RoleItem> {
  return httpGet<RoleItem>(`/super-admin/roles/${roleId}`)
}

export async function createRole(payload: RolePayload): Promise<string> {
  return httpPost<string>('/super-admin/roles', payload)
}

export async function updateRole(roleId: number, payload: RolePayload): Promise<string> {
  return httpPut<string>(`/super-admin/roles/${roleId}`, payload)
}

export async function deleteRole(roleId: number): Promise<string> {
  return httpDelete<string>(`/super-admin/roles/${roleId}`)
}

export async function fetchRolePermissions(roleId: number): Promise<PermissionItem[]> {
  const list = await httpGet<PermissionItem[]>(`/super-admin/roles/${roleId}/permissions`)
  return Array.isArray(list) ? list : []
}

/** 矩阵需要的只有 id 集合。 */
export async function fetchRolePermissionIds(roleId: number): Promise<number[]> {
  const list = await fetchRolePermissions(roleId)
  return list.map((item) => item.permissionId)
}

/** 勾选父权限时后端只存父权限本身，所以保存前把父项的子项一并补齐。 */
export function expandPermissionIds(ids: number[], tree: PermissionItem[]): number[] {
  const map = new Map<number, PermissionItem>()
  for (const item of flattenPermissions(tree)) map.set(item.permissionId, item)
  const out = new Set<number>()
  for (const id of ids) {
    const node = map.get(id)
    if (node) {
      for (const child of collectPermissionIds(node)) out.add(child)
    } else {
      out.add(id)
    }
  }
  return [...out]
}

/** 全量覆盖该角色的权限。 */
export async function saveRolePermissions(
  roleId: number,
  permissionIds: number[],
): Promise<string> {
  return httpPut<string>(`/super-admin/roles/${roleId}/permissions`, { permissionIds })
}
