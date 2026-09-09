import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { useMessageStore } from './message'

export const useUserStore = defineStore('user', () => {
  const router = useRouter()

  // 用户状态
  const token = ref<string | null>(null)
  const userInfo = ref<any>(null)
  const isLoggedIn = computed(() => {
    const result = !!token.value
    console.log('计算isLoggedIn:', result, 'token.value:', token.value)
    return result
  })

  // 设置token
  function setToken(newToken: string) {
    token.value = newToken
    sessionStorage.setItem('token', newToken)
    localStorage.setItem('token', newToken)
  }

  // 设置用户信息
  function setUserInfo(info: any) {
    userInfo.value = info
    sessionStorage.setItem('userInfo', JSON.stringify(info))
    localStorage.setItem('userInfo', JSON.stringify(info))
  }

  // 清除用户信息
  function clearUserInfo() {
    userInfo.value = null
    sessionStorage.removeItem('userInfo')
    localStorage.removeItem('userInfo')
  }

  // 登录
  function login(newToken: string, info?: any) {
    setToken(newToken)
    if (info) {
      setUserInfo(info)
    }
    ElMessage.success('登录成功')
    console.log('登录函数中的info参数:', info);
    console.log('info中的role_type:', info?.role_type);
    console.log('info中的roleType:', info?.roleType);
    console.log('info中的role:', info?.role);
    console.log('info中的type:', info?.type);

    // 启动消息轮询
    const messageStore = useMessageStore()
    messageStore.startPolling()

    // 根据用户角色跳转到不同的首页
    // 同时检查role_type、roleType、role、type等可能的字段名
    let roleType = info?.role_type || info?.roleType || info?.role || info?.type || 0
    // 将roleType转换为数字类型，确保比较正确
    roleType = Number(roleType)
    console.log('最终使用的roleType:', roleType);

    if (roleType) {
      if (roleType === 2 || roleType === 'merchant' || roleType === '商家') {
        // 商家角色，跳转到商家后台首页
        console.log('跳转到商家后台首页');
        router.push('/merchant-dashboard')
      } else if (roleType === 3 || roleType === 'admin' || roleType === '管理员') {
        // 管理员角色，跳转到管理员后台首页
        console.log('跳转到管理员后台首页');
        router.push('/admin-dashboard')
      } else if (roleType === 4 || roleType === 'super_admin' || roleType === '超级管理员') {
        // 超级管理员角色，跳转到超级管理员后台首页
        console.log('跳转到超级管理员后台首页');
        router.push('/super-admin-dashboard')
      } else {
        // 普通用户，跳转到系统首页
        console.log('跳转到系统首页');
        router.push('/index')
      }
    } else {
      // 默认跳转到系统首页
      console.log('没有找到roleType，跳转到系统首页');
      router.push('/index')
    }
  }

  // 退出登录
  function logout() {
    // 清除token
    token.value = null
    sessionStorage.removeItem('token')
    localStorage.removeItem('token')

    // 清除用户信息
    clearUserInfo()

    // 清除记住的用户（仍然使用localStorage，因为记住密码是跨标签页的）
    localStorage.removeItem('rememberedUser')

    // 停止消息轮询并清空消息列表
    const messageStore = useMessageStore()
    messageStore.stopPolling()
    messageStore.clearMessages()

    // 跳转到首页
    router.push('/index')

    // 显示退出成功提示
    ElMessage.success('已成功退出登录')
  }

  // 检查登录状态
  async function checkLoginStatus() {
    // 优先从sessionStorage获取，然后从localStorage获取
    let storedToken = sessionStorage.getItem('token')
    if (!storedToken) {
      storedToken = localStorage.getItem('token')
    }

    if (storedToken) {
      // 先设置token.value，确保axios请求能携带Authorization头
      token.value = storedToken

      try {
        // 向后端验证token是否有效
        const { auth } = await import('@/api/user')
        const response = await auth.getCurrentUser()
        if (response.code === 200) {
          // 优先从sessionStorage获取用户信息，然后从localStorage获取
          let storedUserInfo = sessionStorage.getItem('userInfo')
          if (!storedUserInfo) {
            storedUserInfo = localStorage.getItem('userInfo')
          }
          if (storedUserInfo) {
            userInfo.value = JSON.parse(storedUserInfo)
          } else {
            // 如果本地没有用户信息，使用后端返回的
            userInfo.value = response.data
            setUserInfo(response.data)
          }
        } else {
          // token无效，清除本地存储
          token.value = null
          sessionStorage.removeItem('token')
          localStorage.removeItem('token')
          clearUserInfo()
        }
      } catch (error) {
        console.error('验证token失败:', error)
        // 验证失败，清除本地存储
        token.value = null
        sessionStorage.removeItem('token')
        localStorage.removeItem('token')
        clearUserInfo()
      }
    }
  }

  return {
    token,
    userInfo,
    isLoggedIn,
    login,
    logout,
    setToken,
    setUserInfo,
    clearUserInfo,
    checkLoginStatus
  }
})
