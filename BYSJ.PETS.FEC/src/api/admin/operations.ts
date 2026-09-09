// 管理员操作记录API
import service from '@/axios'

/**
 * 获取操作记录列表
 * @param pageNum 页码
 * @param pageSize 每页数量
 * @param keyword 关键词
 */
export const getOperationList = async (pageNum = 1, pageSize = 10, keyword?: string) => {
  return service({
    url: '/admin/operations',
    method: 'get',
    params: {
      pageNum,
      pageSize,
      keyword
    }
  })
}
