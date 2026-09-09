// 超级管理员仪表盘API
import service from '@/axios'

/**
 * 获取超级管理员仪表盘数据
 */
export const getSuperAdminDashboardData = async () => {
  return service({
    url: '/admin/super-admin/dashboard',
    method: 'get'
  })
}
