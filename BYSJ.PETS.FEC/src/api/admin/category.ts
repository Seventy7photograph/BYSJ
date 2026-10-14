import { apiDelete, apiGet, apiPost, apiPut } from './http'

// 管理员分类管理相关 API

export interface CategoryNode {
  categoryId: number
  categoryName: string
  parentId: number | null
  categoryCode: string
  sort: number
  /** 1 启用 / 0 禁用。 */
  status: number
  description: string | null
  createBy?: number | null
  createTime?: string | null
  updateBy?: number | null
  updateTime?: string | null
  children?: CategoryNode[]
}

/**
 * 新增 / 修改分类的表单。
 *
 * createBy / createTime / updateTime 不是业务字段，是被迫补的：后端
 * AdminController.addCategory 直接把实体插库，既没有从登录态取当前用户，
 * 实体上也没有 @TableField(fill = INSERT)，而这几列在库里都是 NOT NULL，
 * 结果是"添加分类"必然抛 `Field 'create_by' doesn't have a default value`。
 * 正确的修法在后端（取 SecurityContext 里的 user_id + 依赖自动填充），
 * 这里先让功能可用。
 */
export interface CategoryPayload {
  categoryName: string
  categoryCode: string
  parentId: number | null
  sort: number
  status: number
  description?: string | null
  createBy?: number
  updateBy?: number
  createTime?: string
  updateTime?: string
}

/** 分类树。后端只返回 parent_id 为 null 的根节点及其后代。 */
export function getCategoryTree(): Promise<CategoryNode[]> {
  return apiGet<CategoryNode[]>('/admin/categories/tree')
}

export function addCategory(data: CategoryPayload): Promise<unknown> {
  return apiPost<unknown>('/admin/categories', { ...data })
}

export function updateCategory(categoryId: number, data: CategoryPayload): Promise<unknown> {
  return apiPut<unknown>(`/admin/categories/${categoryId}`, { ...data })
}

/**
 * 删除分类。后端会先检查子分类，有子分类时返回
 * "该分类下有子分类，无法删除"，调用方要把这句话原样展示给管理员。
 */
export function deleteCategory(categoryId: number): Promise<unknown> {
  return apiDelete<unknown>(`/admin/categories/${categoryId}`)
}
