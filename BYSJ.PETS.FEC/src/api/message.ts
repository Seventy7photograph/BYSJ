import axios from '@/axios'

// 消息中心相关API

export interface MessageItem {
  noticeId: number
  userId: number
  content: string
  noticeType: number
  createTime: string
  isRead: number
  expireTime?: string
  noticeStatus: number
  title?: string // 消息标题，用于前端展示
}

// 获取消息列表
export const getMessageList = async (params: {
  page?: number
  pageSize?: number
  noticeType?: number
}) => {
  console.log('调用getMessageList的调用栈:', new Error().stack)
  try {
    const response = await axios.get(`/message/list`, {
      params: {
        page: params.page,
        pageSize: params.pageSize,
        noticeType: params.noticeType
      }
    })
    return response.data
  } catch (error) {
    console.error('获取消息列表失败:', error)
    return {
      records: [],
      total: 0
    }
  }
}

// 获取未读消息数量
export const getUnreadCount = async () => {
  try {
    const response = await axios.get(`/message/unread/count`)
    return response.data
  } catch (error) {
    console.error('获取未读消息数量失败:', error)
    return 0
  }
}

// 标记单条消息为已读
export const markMessageAsRead = async (noticeId: number) => {
  try {
    const response = await axios.put(`/message/${noticeId}/read`)
    return response.data
  } catch (error) {
    console.error('标记消息为已读失败:', error)
    throw error
  }
}

// 标记所有消息为已读
export const markAllMessagesAsRead = async () => {
  try {
    const response = await axios.put(`/message/all/read`)
    return response.data
  } catch (error) {
    console.error('标记所有消息为已读失败:', error)
    throw error
  }
}

// 删除消息
export const deleteMessage = async (noticeId: number) => {
  try {
    const response = await axios.delete(`/message/${noticeId}`)
    return response.data
  } catch (error) {
    console.error('删除消息失败:', error)
    throw error
  }
}
