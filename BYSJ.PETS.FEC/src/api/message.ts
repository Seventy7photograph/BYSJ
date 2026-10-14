import axios from '@/axios'
import type { Tone } from '@/constants/domain'

/**
 * 站内消息接口，对齐 MessageController：
 *   GET    /message/list?page&pageSize&noticeType
 *   GET    /message/unread/count
 *   PUT    /message/{id}/read
 *   PUT    /message/all/read
 *   DELETE /message/{id}            逻辑删除（notice_status = 2）
 *
 * 数据来源是 sys_notice，一个用户一行消息：notice_id / content / notice_type /
 * is_read / create_time。表里没有 title 字段，标题由 notice_type 推导，所以这里
 * 把它定义成一张字典，而不是让每个页面各写一份 if-else。
 */

export interface MessageItem {
  noticeId: number
  userId: number | null
  content: string
  /** 0 系统 / 1 订单 / 2 退款 / 3 账号 / 4 评价 */
  noticeType: number
  createTime: string
  /** 0 未读 / 1 已读 */
  isRead: number
  expireTime?: string | null
  noticeStatus?: number | null
}

export interface MessageQuery {
  page?: number
  pageSize?: number
  noticeType?: number
}

export interface MessagePage {
  records: MessageItem[]
  total: number
  pageNum: number
  pageSize: number
  pages: number
}

/** notice_type 字典。后端目前只写 1（订单/系统通知），其余为历史数据保留。 */
export const NOTICE_TYPE: Record<number, { label: string; tone: Tone }> = {
  0: { label: '系统通知', tone: 'neutral' },
  1: { label: '订单通知', tone: 'teal' },
  2: { label: '退款通知', tone: 'amber' },
  3: { label: '账号通知', tone: 'vermilion' },
  4: { label: '评价通知', tone: 'amber' },
}

/** 消息中心顶部的筛选页签，顺序即展示顺序。 */
export const MESSAGE_FILTERS = [
  { key: 'all', label: '全部', codes: null },
  { key: 'system', label: '系统通知', codes: [0] },
  { key: 'order', label: '订单通知', codes: [1] },
  { key: 'refund', label: '退款通知', codes: [2] },
  { key: 'account', label: '账号通知', codes: [3] },
  { key: 'review', label: '评价通知', codes: [4] },
] as const

export type MessageFilterKey = (typeof MESSAGE_FILTERS)[number]['key']

export function noticeTypeLabel(noticeType: number | null | undefined) {
  return NOTICE_TYPE[Number(noticeType)] ?? { label: '通知', tone: 'outline' as Tone }
}

/** 拆掉 Result 外壳。 */
function unwrap(res: any): any {
  return res?.data ?? res
}

/**
 * 消息列表。
 * 返回体是 MyBatis-Plus 的 Page，被包在 Result.data 里；这里直接整理成
 * { records, total, ... }，message store 与消息中心页面共用同一份结构。
 * 失败时抛错，让调用方能给出错误态，而不是静默变成"暂无消息"。
 */
export async function getMessageList(query: MessageQuery = {}): Promise<MessagePage> {
  const res = await axios.get('/message/list', {
    params: {
      page: query.page ?? 1,
      pageSize: query.pageSize ?? 20,
      noticeType: query.noticeType,
    },
  })
  const data = unwrap(res)
  const records: MessageItem[] = data?.records ?? data?.list ?? []
  return {
    records,
    total: Number(data?.total ?? records.length),
    pageNum: Number(data?.current ?? data?.pageNum ?? query.page ?? 1),
    pageSize: Number(data?.size ?? data?.pageSize ?? query.pageSize ?? 20),
    pages: Number(data?.pages ?? 1),
  }
}

/** 未读消息数量。 */
export async function getUnreadCount(): Promise<number> {
  const res = await axios.get('/message/unread/count')
  return Number(unwrap(res) ?? 0)
}

/** 标记单条消息为已读。 */
export async function markMessageAsRead(noticeId: number) {
  const res = await axios.put(`/message/${noticeId}/read`)
  return unwrap(res)
}

/** 全部标记为已读。 */
export async function markAllMessagesAsRead() {
  const res = await axios.put('/message/all/read')
  return unwrap(res)
}

/** 删除消息。 */
export async function deleteMessage(noticeId: number) {
  const res = await axios.delete(`/message/${noticeId}`)
  return unwrap(res)
}
