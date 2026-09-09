// 管理员仪表盘API
import service from '@/axios'

/**
 * 获取管理员仪表盘数据
 */
export const getAdminDashboardData = async () => {
  return service({
    url: '/admin/dashboard',
    method: 'get'
  })
}
