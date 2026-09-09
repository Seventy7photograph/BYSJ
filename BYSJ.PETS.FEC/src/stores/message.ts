import { ref, computed, onMounted, onUnmounted } from 'vue'
import { defineStore } from 'pinia'
import {
  getMessageList,
  markMessageAsRead,
  markAllMessagesAsRead,
  deleteMessage,
  type MessageItem
} from '@/api/message'
import { useUserStore } from './user'

export const useMessageStore = defineStore('message', () => {
  const userStore = useUserStore()

  // 消息中心相关状态
  const messages = ref<MessageItem[]>([])
  const loading = ref(false)
  const lastFetchedTime = ref(0)
  const FETCH_INTERVAL = 60000 // 1分钟内不重复请求
  let pollingInterval: number | null = null

  // 计算未读消息数量
  const unreadCount = computed(() => {
    return messages.value.filter(msg => msg.isRead === 0).length
  })

  // 系统消息
  const systemMessages = computed(() => {
    return messages.value.filter(msg =>
      msg.noticeType == 0 || // 通用通知
      msg.noticeType == 3 || // 账号封禁/冻结通知
      msg.noticeType == 4     // 差评提醒通知
    )
  })

  // 订单消息
  const orderMessages = computed(() => {
    return messages.value.filter(msg =>
      msg.noticeType == 1 || // 订单状态变更通知
      msg.noticeType == 2     // 退款通知
    )
  })

  // 审核通知
  const auditMessages = computed(() => {
    return messages.value.filter(msg =>
      msg.content.includes('审核')
    )
  })

  // 库存预警
  const inventoryMessages = computed(() => {
    return messages.value.filter(msg =>
      msg.noticeType == 1     // 库存预警通知
    )
  })

  // 加载消息列表
  const loadMessages = async (forceRefresh = false) => {
    // 检查登录状态，如果未登录则不加载消息
    if (!userStore.isLoggedIn) {
      messages.value = []
      return
    }

    // 检查是否在短时间内已经请求过，如果是则跳过
    const now = Date.now()
    if (!forceRefresh && now - lastFetchedTime.value < FETCH_INTERVAL) {
      return
    }

    loading.value = true
    try {
      const response = await getMessageList({ page: 1, pageSize: 100 })
      if (response && response.records) {
        messages.value = response.records
      }
      lastFetchedTime.value = now
    } catch (error) {
      console.error('加载消息列表失败:', error)
    } finally {
      loading.value = false
    }
  }

  // 标记单条消息为已读
  const markAsRead = async (noticeId: number) => {
    try {
      await markMessageAsRead(noticeId)
      // 更新本地状态
      const msgIndex = messages.value.findIndex(msg => msg.noticeId === noticeId)
      if (msgIndex !== -1 && messages.value[msgIndex]) {
        messages.value[msgIndex].isRead = 1
      }
    } catch (error) {
      console.error('标记消息为已读失败:', error)
      throw error
    }
  }

  // 一键标记所有消息为已读
  const markAllAsRead = async () => {
    try {
      await markAllMessagesAsRead()
      // 更新本地状态
      messages.value.forEach(msg => {
        msg.isRead = 1
      })
    } catch (error) {
      console.error('标记所有消息为已读失败:', error)
      throw error
    }
  }

  // 删除消息
  const deleteMessageById = async (noticeId: number) => {
    try {
      await deleteMessage(noticeId)
      // 更新本地状态
      messages.value = messages.value.filter(msg => msg.noticeId !== noticeId)
    } catch (error) {
      console.error('删除消息失败:', error)
      throw error
    }
  }

  // 清空消息列表（用于退出登录）
  const clearMessages = () => {
    messages.value = []
    lastFetchedTime.value = 0
  }

  // 开始定时轮询
  const startPolling = () => {
    if (pollingInterval) {
      clearInterval(pollingInterval)
    }
    // 每30秒轮询一次消息
    pollingInterval = window.setInterval(() => {
      if (userStore.isLoggedIn) {
        loadMessages(true)
      }
    }, 30000)
  }

  // 停止定时轮询
  const stopPolling = () => {
    if (pollingInterval) {
      clearInterval(pollingInterval)
      pollingInterval = null
    }
  }

  // 组件挂载时启动轮询
  onMounted(() => {
    startPolling()
  })

  // 组件卸载时停止轮询
  onUnmounted(() => {
    stopPolling()
  })

  return {
    // 状态
    messages,
    loading,
    unreadCount,

    // 计算属性
    systemMessages,
    orderMessages,
    auditMessages,
    inventoryMessages,

    // 方法
    loadMessages,
    markAsRead,
    markAllAsRead,
    deleteMessageById,
    clearMessages,
    startPolling,
    stopPolling
  }
})
