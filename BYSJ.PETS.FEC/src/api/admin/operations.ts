// 管理员操作记录 API
import service from '@/axios'
import { apiGet, type Envelope, type Paged } from './http'

/**
 * 操作日志一行。后端把 sys_log 翻译成这套字段：
 * operator 操作人 / operation 动作 / target 模块 / result 结果 / operationTime 时间。
 */
export interface OperationRow {
  operator: string
  operation: string
  target: string
  result: string
  operationTime: string | null
}

export interface OperationQuery {
  pageNum?: number
  pageSize?: number
  /** 后端按 operation / module 模糊匹配。 */
  keyword?: string
}

/** 操作日志分页。 */
export function listOperations(params: OperationQuery): Promise<Paged<OperationRow>> {
  return apiGet<Paged<OperationRow>>('/admin/operations', { ...params })
}

/**
 * 旧签名，返回整包 { code, msg, data }。
 *
 * 超级管理员的首页（pages/super-admin/Dashboard.vue）按这个形状取数，
 * 而那个文件不在本次管理员后台重构范围内，改签名会让它的表格静默变空。
 * 管理员后台请用 listOperations()，等超级管理台迁移过去之后删掉这个导出。
 */
export const getOperationList = async (
  pageNum = 1,
  pageSize = 10,
  keyword?: string,
): Promise<Envelope<Paged<OperationRow>>> => {
  return (await service({
    url: '/admin/operations',
    method: 'get',
    params: { pageNum, pageSize, keyword },
  })) as unknown as Envelope<Paged<OperationRow>>
}
