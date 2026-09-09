import axios from 'axios'
import type { AxiosRequestConfig, CancelTokenSource } from 'axios'
import { ElMessage } from 'element-plus'
import router from './router' // 导入路由实例
import { useUserStore } from './stores/user' // 导入用户状态管理

// 创建 Axios 实例
const service = axios.create({
  baseURL: import.meta.env.VITE_APP_BASE_API,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 重复请求拦截：存储 pending 请求
const pendingRequests = new Map<string, CancelTokenSource>()
const generateKey = (config: AxiosRequestConfig) => {
  const { method, url, params, data } = config
  return [method, url, JSON.stringify(params), JSON.stringify(data)].join('&')
}

// 请求拦截器
service.interceptors.request.use(
  (config) => {
    // 取消重复请求
    const key = generateKey(config)
    if (pendingRequests.has(key)) {
      pendingRequests.get(key)?.cancel('取消重复请求')
    }
    const source = axios.CancelToken.source()
    config.cancelToken = source.token
    pendingRequests.set(key, source)

    // 添加 Token，优先从用户状态管理中获取，然后从本地存储获取
    let token = null;
    try {
      const userStore = useUserStore();
      token = userStore.token;
    } catch (e) {
      // 如果store还未初始化，直接从本地存储获取
      token = sessionStorage.getItem('token') || localStorage.getItem('token');
    }
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    // 调试：打印请求头，确认Authorization是否正确设置
    console.log('Authorization Header:', config.headers.Authorization);

    return config
  },
  (error) => {
    const key = generateKey(error.config)
    pendingRequests.delete(key)
    ElMessage.error('请求发送失败：' + error.message)
    return Promise.reject(error)
  }
)

// 响应拦截器
service.interceptors.response.use(
  (response) => {
    const key = generateKey(response.config)
    pendingRequests.delete(key)

    const res = response.data
    // 检查是否有code字段
    if (res.code !== undefined) {
      if (res.code !== 200) {
        ElMessage.error(res.msg || '操作失败')
        if (res.code === 401) {
          // 登录已过期，安全退出并跳转到登录页
          const userStore = useUserStore()
          userStore.logout()
          ElMessage.error('登录已过期，请重新登录')
          router.push('/login')
        }
        return Promise.reject(res)
      }
      return res
    } else {
      // 如果没有code字段，直接返回数据
      return res
    }
  },
  (error) => {
    // 处理取消请求
    if (axios.isCancel(error)) {
      console.log('请求已取消：', error.message)
      return Promise.resolve({ list: [], total: 0 })
    }

    // 处理 HTTP 401 状态码
    if (error.response?.status === 401) {
      // 登录已过期，安全退出并跳转到登录页
      const userStore = useUserStore()
      userStore.logout()
      ElMessage.error('登录已过期，请重新登录')
      router.push('/login')
    } else {
      // 检查响应数据是否包含登录过期信息
      const errorMsg = error.response?.data?.message || error.response?.data?.msg || error.message
      if (errorMsg.includes('用户未登录') || errorMsg.includes('令牌已过期') || errorMsg.includes('登录已过期')) {
        // 登录已过期，安全退出并跳转到登录页
        const userStore = useUserStore()
        userStore.logout()
        ElMessage.error('登录已过期，请重新登录')
        router.push('/login')
      } else {
        ElMessage.error('服务器响应失败：' + errorMsg)
      }
    }

    const key = generateKey(error.config)
    pendingRequests.delete(key)
    return Promise.reject(error)
  }
)

export default service
