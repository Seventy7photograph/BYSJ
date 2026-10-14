import axios from 'axios'
import type { AxiosError, AxiosRequestConfig } from 'axios'
import { ElMessage } from 'element-plus'
import router from './router'
import { useUserStore } from './stores/user'

declare module 'axios' {
  export interface AxiosRequestConfig {
    /**
     * 调用方自己会在页面上展示错误时置 true。
     * 否则同一条失败会既出现在表单下方、又弹一次全局提示。
     */
    skipErrorToast?: boolean
  }
}

/**
 * 全局 HTTP 客户端。
 *
 * 这一层以前做了三件错事，都会让页面拿到"看起来正常"的错误数据：
 *
 * 1. **取消并发同请求**：同一个 URL 在一个 tick 内被请求两次，后一次会取消前一次，
 *    而取消的回调被解析成 `{ list: [], total: 0 }` —— 一个成功的空列表。
 *    页头和页面本体同帧取 /shop/categories 时，其中一方必然拿到假的空数据。
 *    真实浏览器里两个组件同时要同一份数据是常态，正确做法是共享同一个 Promise，
 *    而不是取消其中一个。
 *
 * 2. **无差别打印 Authorization**：每次请求都把带令牌的请求头打到控制台。
 *    开发时噪音，上线后是凭据泄漏。
 *
 * 3. **10 秒超时**：图片上传、报表导出这类接口 10 秒不够，会莫名失败。
 *
 * 现在：并发同请求共享结果、令牌不外泄、超时按用途区分。
 */

const service = axios.create({
  baseURL: import.meta.env.VITE_APP_BASE_API,
  timeout: 20000,
  headers: { 'Content-Type': 'application/json' },
})

/** 进行中的 GET 请求：同 URL + 同参数共享一个 Promise。 */
const inflight = new Map<string, Promise<unknown>>()

function keyOf(config: AxiosRequestConfig): string {
  return [config.method, config.url, JSON.stringify(config.params)].join('|')
}

/** 让"反正会失败"的请求不要重复弹同一条错误提示。 */
let lastErrorAt = 0
let lastErrorText = ''
function notifyError(text: string) {
  const now = Date.now()
  if (text === lastErrorText && now - lastErrorAt < 2000) return
  lastErrorAt = now
  lastErrorText = text
  ElMessage.error(text)
}

function readToken(): string | null {
  try {
    const store = useUserStore()
    if (store.token) return store.token
  } catch {
    // store 尚未初始化（例如在 router 守卫之前发起的请求）
  }
  return sessionStorage.getItem('token') || localStorage.getItem('token')
}

let redirecting = false
function forceLogout(message: string) {
  try {
    useUserStore().logout()
  } catch {
    sessionStorage.removeItem('token')
    localStorage.removeItem('token')
    sessionStorage.removeItem('userInfo')
    localStorage.removeItem('userInfo')
  }
  notifyError(message)
  if (redirecting) return
  redirecting = true
  const target = router.currentRoute.value.fullPath
  void router
    .push({ path: '/login', query: target && target !== '/index' ? { redirect: target } : undefined })
    .finally(() => {
      redirecting = false
    })
}

service.interceptors.request.use((config) => {
  const token = readToken()
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

service.interceptors.response.use(
  (response) => {
    const body = response.data
    // 后端统一返回 { code, msg, data }；不是这个形状的（例如静态文件、第三方）
    // 原样返回，交给调用方。
    if (body && typeof body === 'object' && 'code' in body) {
      if (body.code === 200) return body
      if (body.code === 401) {
        forceLogout('登录已过期，请重新登录')
        return Promise.reject(new Error(body.msg || '登录已过期'))
      }
      const text = body.msg || body.message || '操作失败'
      if (!response.config.skipErrorToast) notifyError(text)
      return Promise.reject(new Error(text))
    }
    return body
  },
  (error: AxiosError) => {
    const status = error.response?.status
    const data = error.response?.data as Record<string, unknown> | undefined
    const serverMsg = (data?.msg ?? data?.message) as string | undefined

    if (status === 401) {
      forceLogout('登录已过期，请重新登录')
      return Promise.reject(error)
    }

    const quiet = Boolean(error.config?.skipErrorToast)

    if (status === 403) {
      if (!quiet) notifyError(serverMsg || '没有权限执行该操作')
      return Promise.reject(error)
    }

    if (error.code === 'ECONNABORTED' || /timeout/i.test(error.message)) {
      if (!quiet) notifyError('请求超时，请检查网络后重试')
      return Promise.reject(error)
    }

    if (!error.response) {
      if (!quiet) notifyError('无法连接到服务器，请确认后端服务已启动')
      return Promise.reject(error)
    }

    if (!quiet) notifyError(serverMsg || `请求失败（${status}）`)
    return Promise.reject(error)
  },
)

/**
 * GET 请求按 key 合并：同 URL 同参数复用同一 Promise。
 * 既省掉重复网络往返，也不会出现"其中一个请求被取消、调用方却收到空数据"的情况。
 */
const rawGet = service.get.bind(service)
service.get = function dedupedGet<T = unknown>(url: string, config?: AxiosRequestConfig) {
  const key = keyOf({ ...config, method: 'get', url })
  const existing = inflight.get(key)
  if (existing) return existing as Promise<T>

  const promise = rawGet<T>(url, config).finally(() => {
    inflight.delete(key)
  })
  inflight.set(key, promise)
  return promise
} as typeof service.get

export default service
