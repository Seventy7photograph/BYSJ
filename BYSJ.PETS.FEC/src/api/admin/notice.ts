import axios from '@/axios'

// 管理员公告管理相关API

export interface NoticeItem {
  noticeId: number
  title: string
  content: string
  publisher: string
  publishTime: string
  [key: string]: any
}

// 获取公告列表
export const getNoticeList = async (params: {
  pageNum?: number
  pageSize?: number
  keyword?: string
}) => {
  try {
    const response = await axios.get(`/admin/notices`, {
      params
    })
    return response.data
  } catch (error) {
    console.error('获取公告列表失败:', error)
    throw error
  }
}

// 获取公告详情
export const getNoticeDetail = async (noticeId: number) => {
  try {
    const response = await axios.get(`/admin/notices/${noticeId}`)
    return response.data
  } catch (error) {
    console.error('获取公告详情失败:', error)
    throw error
  }
}

// 发布公告
export const publishNotice = async (data: {
  title: string
  content: string
  [key: string]: any
}) => {
  try {
    const response = await axios.post(`/admin/notices`, data)
    return response.data
  } catch (error) {
    console.error('发布公告失败:', error)
    throw error
  }
}

// 更新公告
export const updateNotice = async (noticeId: number, data: {
  title: string
  content: string
  [key: string]: any
}) => {
  try {
    const response = await axios.put(`/admin/notices/${noticeId}`, data)
    return response.data
  } catch (error) {
    console.error('更新公告失败:', error)
    throw error
  }
}

// 删除公告
export const deleteNotice = async (noticeId: number) => {
  try {
    const response = await axios.delete(`/admin/notices/${noticeId}`)
    return response.data
  } catch (error) {
    console.error('删除公告失败:', error)
    throw error
  }
}
