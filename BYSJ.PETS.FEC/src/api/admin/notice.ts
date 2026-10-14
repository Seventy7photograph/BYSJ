import { apiDelete, apiGet, apiPost, apiPut, type Paged } from './http'
import type { StateLabel } from '@/constants/domain'

// 管理员公告管理相关 API

/**
 * 通知类型字典，取自 sys_notice.notice_type 的列注释。
 * 0 是平台公告（管理端自己发的），1..5 都是系统按业务自动发给单个用户的通知。
 */
export const NOTICE_TYPE: Record<number, StateLabel> = {
  0: { label: '平台公告', tone: 'neutral' },
  1: { label: '库存预警', tone: 'amber' },
  2: { label: '退款通知', tone: 'amber' },
  3: { label: '账号冻结', tone: 'vermilion' },
  4: { label: '差评提醒', tone: 'amber' },
  5: { label: '租赁到期', tone: 'amber' },
}

/**
 * 发布状态。
 *
 * 口径来自后端行为：新增时 notice_status = 0，PUT /notices/{id}/publish 把它置为 1。
 * 库里这一列的注释写的是"0 正常 / 1 已过期 / 2 已删除"，和发布接口的用法冲突；
 * 更要紧的是用户侧的消息列表只捞 notice_status = 0 的记录（MessageController），
 * 也就是说"已发布"的公告目前反而不会出现在接收人的消息中心里。
 * 页面按发布动作的真实语义（0 草稿 / 1 已发布）呈现，并把这条冲突原样告诉管理员。
 */
export const NOTICE_STATE: Record<number, StateLabel> = {
  0: { label: '草稿', tone: 'outline' },
  1: { label: '已发布', tone: 'teal' },
  2: { label: '已删除', tone: 'vermilion' },
}

/**
 * sys_notice 一行。这张表同时装着"平台公告"和"系统给单个用户的通知"
 * （库存预警、退款、封禁……），靠 noticeType 区分；列表接口不过滤类型，
 * 所以页面上必须把两者分开呈现，否则公告列表里会混进上百条库存提醒。
 */
export interface NoticeRow {
  noticeId: number
  /** 接收人。为空表示面向全体用户的公告，不会出现在任何人的消息中心。 */
  userId: number | null
  content: string
  /** 0 通用（平台公告）/ 1 库存预警 / 2 退款 / 3 封禁冻结 / 4 差评提醒 / 5 租赁到期。 */
  noticeType: number
  createTime: string | null
  isRead: number
  expireTime: string | null
  /** 后端把发布动作写成 1，草稿是 0。 */
  noticeStatus: number
}

export interface NoticePayload {
  content: string
  noticeType: number
  userId?: number | null
  expireTime?: string | null
}

export interface NoticeQuery {
  pageNum?: number
  pageSize?: number
  /** 后端按 content 模糊匹配。 */
  keyword?: string
}

export function getNoticeList(params: NoticeQuery): Promise<Paged<NoticeRow>> {
  return apiGet<Paged<NoticeRow>>('/admin/notices', { ...params })
}

export function getNoticeDetail(noticeId: number): Promise<NoticeRow> {
  return apiGet<NoticeRow>(`/admin/notices/${noticeId}`)
}

/** 新建公告。后端固定写成草稿（notice_status = 0）并盖上创建时间。 */
export function createNotice(data: NoticePayload): Promise<unknown> {
  return apiPost<unknown>('/admin/notices', { ...data })
}

export function updateNotice(noticeId: number, data: NoticePayload): Promise<unknown> {
  return apiPut<unknown>(`/admin/notices/${noticeId}`, { ...data })
}

/** 发布。后端把 notice_status 置为 1，这是唯一的"发布"入口。 */
export function publishNotice(noticeId: number): Promise<unknown> {
  return apiPut<unknown>(`/admin/notices/${noticeId}/publish`)
}

export function deleteNotice(noticeId: number): Promise<unknown> {
  return apiDelete<unknown>(`/admin/notices/${noticeId}`)
}
