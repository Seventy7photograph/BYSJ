import { countAdmins, fetchAdmins } from './admin'
import { fetchPermissions, fetchRolePermissionIds, fetchRoles } from './permission'
import type { AdminUser, RoleItem } from './shared'

/**
 * 超管首页要回答的问题：谁持有账号、谁被停用、每个角色手里有多少权限项。
 *
 * 全部由已有的 /super-admin/** 接口拼出来，不新增后端接口，也不用
 * /admin/super-admin/dashboard —— 那个返回的是用户数、商品数、成交额，属于
 * 管理员后台的指标，摆在"只管权限"的超管首页上会误导人。
 */

export interface RoleOverview extends RoleItem {
  /** 该角色当前持有的权限项数量；null 表示这一项没读到，页面按"未知"显示。 */
  permissionCount: number | null
}

export interface SuperAdminOverview {
  adminCount: number
  /** status = 0 的账号数。 */
  disabledCount: number
  roleCount: number
  permissionCount: number
  admins: AdminUser[]
  roles: RoleOverview[]
}

/** 首页只展示一小段账号清单，其余交给管理员管理页。 */
const PREVIEW_SIZE = 6

export async function fetchOverview(): Promise<SuperAdminOverview> {
  const [adminCount, disabledCount, adminPage, roles, permissions] = await Promise.all([
    countAdmins(),
    countAdmins(0),
    fetchAdmins({ page: 1, pageSize: PREVIEW_SIZE }),
    fetchRoles(),
    fetchPermissions(),
  ])

  // 每个角色的权限数各是一次查询；某个角色读失败不该让整页报错。
  const settled = await Promise.allSettled(roles.map((role) => fetchRolePermissionIds(role.roleId)))
  const roleOverviews: RoleOverview[] = roles.map((role, index) => {
    const result = settled[index]
    return {
      ...role,
      permissionCount: result && result.status === 'fulfilled' ? result.value.length : null,
    }
  })

  return {
    adminCount,
    disabledCount,
    roleCount: roles.length,
    permissionCount: permissions.flat.length,
    admins: adminPage.records,
    roles: roleOverviews,
  }
}
