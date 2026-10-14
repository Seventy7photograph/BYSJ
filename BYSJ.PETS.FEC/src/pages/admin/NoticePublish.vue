<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import {
  createNotice,
  deleteNotice,
  getNoticeList,
  publishNotice,
  updateNotice,
  NOTICE_STATE,
  NOTICE_TYPE,
  type NoticeRow,
} from '@/api/admin/notice'
import { labelOf } from '@/constants/domain'
import { formatDateTime, formatRelative } from '@/utils/format'

/**
 * 公告与通知。
 *
 * 草稿 / 已发布两态是这一页的主线：新建的记录一律是草稿（后端写死 notice_status = 0），
 * 只有 PUT /admin/notices/{id}/publish 才是"发布"，没有别的入口能改这一列。
 *
 * sys_notice 一张表同时装着平台公告和系统自动发给单个用户的通知（库存预警、退款、
 * 封禁…），列表接口不过滤类型，所以这里默认只看 notice_type = 0 的平台公告，
 * 需要排查通知时可以切到全部。原来那一页把 119 条库存提醒和公告混在一张表里，
 * 既看不清也管不了。
 */

const VIEWS = [
  { value: 'notice', label: '平台公告' },
  { value: 'all', label: '全部通知' },
] as const

const view = ref<'notice' | 'all'>('notice')
const loading = ref(true)
const failed = ref(false)
const rows = ref<NoticeRow[]>([])
const all = ref<NoticeRow[]>([])
const matched = ref(0)
const scanned = ref(0)
const windowTruncated = ref(false)
const page = ref(1)
const size = ref(10)
const keyword = ref('')
const busyId = ref<number | null>(null)
const listError = ref('')

/**
 * /admin/notices 没有 noticeType 过滤参数，关键词只作用于 content，分页还是服务端的。
 * 设成 30 那种小页会在第 1 页里一条平台公告都筛不出来（前 119 条大多是库存提醒），
 * 于是页面明明有 28 条公告却显示空态。这里一次取一个足够大的窗口，再在本地筛类型、
 * 本地分页；窗口装不下时明确告诉管理员还有多少没扫到。
 */
const WINDOW_SIZE = 200

const drawer = ref(false)
const mode = ref<'create' | 'edit'>('create')
const saving = ref(false)
const formError = ref('')

const form = reactive({
  noticeId: 0,
  content: '',
  noticeType: 0,
  userId: '' as string,
  expireTime: '' as string,
  published: false,
})

const drawerTitle = computed(() =>
  mode.value === 'edit' ? `编辑${form.published ? '已发布公告' : '草稿'}` : '新建公告',
)

async function load() {
  loading.value = true
  failed.value = false
  listError.value = ''
  try {
    const pageData = await getNoticeList({
      pageNum: 1,
      pageSize: WINDOW_SIZE,
      keyword: keyword.value.trim() || undefined,
    })
    const records = pageData.records ?? []
    all.value = records
    scanned.value = records.length
    windowTruncated.value = (pageData.total ?? 0) > records.length
    applyFilter()
  } catch {
    failed.value = true
    all.value = []
    matched.value = 0
    scanned.value = 0
    windowTruncated.value = false
    applyFilter()
  } finally {
    loading.value = false
  }
}

function applyFilter() {
  const filtered =
    view.value === 'notice' ? all.value.filter((row) => row.noticeType === 0) : all.value
  matched.value = filtered.length
  const start = (page.value - 1) * size.value
  rows.value = filtered.slice(start, start + size.value)
}

function switchView(next: 'notice' | 'all') {
  if (view.value === next) return
  view.value = next
  page.value = 1
  applyFilter()
}

function search() {
  page.value = 1
  void load()
}

function resetSearch() {
  keyword.value = ''
  search()
}

function changeSize(next: number) {
  size.value = next
  page.value = 1
  applyFilter()
}

function changePage(next: number) {
  page.value = next
  applyFilter()
}

function openCreate() {
  mode.value = 'create'
  form.noticeId = 0
  form.content = ''
  form.noticeType = 0
  form.userId = ''
  form.expireTime = ''
  form.published = false
  formError.value = ''
  drawer.value = true
}

function openEdit(row: NoticeRow) {
  mode.value = 'edit'
  form.noticeId = row.noticeId
  form.content = row.content
  form.noticeType = row.noticeType
  form.userId = row.userId === null || row.userId === undefined ? '' : String(row.userId)
  form.expireTime = row.expireTime ?? ''
  form.published = row.noticeStatus === 1
  formError.value = ''
  drawer.value = true
}

function payloadOf() {
  const userId = form.userId.trim()
  return {
    content: form.content.trim(),
    noticeType: Number(form.noticeType),
    userId: userId ? Number(userId) : null,
    expireTime: form.expireTime || null,
  }
}

async function save() {
  if (saving.value) return
  const content = form.content.trim()
  if (content.length < 4) {
    formError.value = '公告内容至少 4 个字。'
    return
  }
  const userId = form.userId.trim()
  if (userId && !/^\d+$/.test(userId)) {
    formError.value = '接收用户 ID 只能是数字；留空表示面向全体用户。'
    return
  }
  formError.value = ''
  saving.value = true
  try {
    if (mode.value === 'edit') {
      await updateNotice(form.noticeId, payloadOf())
      ElMessage.success('已保存')
    } else {
      await createNotice(payloadOf())
      ElMessage.success('已存为草稿，发布后才会生效')
    }
    drawer.value = false
    await load()
  } catch (error) {
    formError.value = error instanceof Error ? error.message : '保存失败，请重试'
  } finally {
    saving.value = false
  }
}

async function publish(row: NoticeRow) {
  const target = row.userId === null || row.userId === undefined ? '全体用户' : `用户 #${row.userId}`
  try {
    await ElMessageBox.confirm(
      `将发布这条公告（面向 ${target}）。发布后不能再改回草稿状态。`,
      '发布公告',
      { confirmButtonText: '发布', cancelButtonText: '取消' },
    )
  } catch {
    return
  }
  busyId.value = row.noticeId
  try {
    await publishNotice(row.noticeId)
    ElMessage.success('已发布')
    await load()
  } catch {
    // 拦截器已提示服务端原因。
  } finally {
    busyId.value = null
  }
}

async function remove(row: NoticeRow) {
  try {
    await ElMessageBox.confirm(
      row.userId === null || row.userId === undefined
        ? '删除这条公告后无法恢复。'
        : `删除这条通知后，用户 #${row.userId} 的消息中心里也会消失，且无法恢复。`,
      '删除记录',
      { confirmButtonText: '删除', cancelButtonText: '取消' },
    )
  } catch {
    return
  }
  busyId.value = row.noticeId
  try {
    await deleteNotice(row.noticeId)
    ElMessage.success('已删除')
    await load()
  } catch {
    // 拦截器已提示服务端原因。
  } finally {
    busyId.value = null
  }
}

onMounted(() => {
  void load()
})
</script>

<template>
  <div class="notices" data-density="admin">
    <SectionHead
      title="公告与通知"
      note="新建即草稿，发布会写 notice_status = 1，这是唯一的发布入口。"
      size="lg"
    >
      <template #action>
        <button class="link-action" type="button" :disabled="loading" @click="load">
          <AppIcon name="refresh" size="14" />
          刷新
        </button>
      </template>
    </SectionHead>

    <div class="toolbar">
      <el-button type="primary" @click="openCreate">
        <AppIcon name="plus" size="14" />
        新建公告
      </el-button>
      <div class="segmented" role="tablist" aria-label="列表范围">
        <button
          v-for="item in VIEWS"
          :key="item.value"
          class="segmented__item"
          :class="{ 'is-on': view === item.value }"
          type="button"
          role="tab"
          :aria-selected="view === item.value"
          @click="switchView(item.value)"
        >
          {{ item.label }}
        </button>
      </div>
      <el-input
        v-model="keyword"
        class="toolbar__input"
        placeholder="按内容搜索"
        clearable
        @keyup.enter="search"
      />
      <el-button @click="search">查询</el-button>
      <el-button @click="resetSearch">重置</el-button>
      <span class="toolbar__count">
        {{ view === 'notice' ? '平台公告' : '全部通知' }} {{ matched }} 条
        <template v-if="windowTruncated">（仅扫描最近 {{ scanned }} 条记录）</template>
      </span>
    </div>

    <p class="band band--notice">
      <AppIcon name="info" size="15" />
      <span>
        用户侧的消息中心只读取 notice_status = 0 的记录，而发布动作把它写成 1 ——
        也就是说此刻"已发布"的通知不会出现在接收人的消息中心里；另外接收用户留空的公告
        目前只是平台存档，不会群发到每个人的收件箱。这两处要对齐需要后端改动。
      </span>
    </p>

    <p v-if="failed" class="band band--error">
      <AppIcon name="warning" size="15" />
      <span>列表没能加载。请确认后端服务在运行，然后重试。</span>
      <button class="band__action" type="button" @click="load">重试</button>
    </p>

    <p v-if="listError" class="band band--error">
      <AppIcon name="warning" size="15" />
      <span>{{ listError }}</span>
      <button class="band__action" type="button" @click="listError = ''">知道了</button>
    </p>

    <section class="plate">
      <div v-if="loading" class="loading-list">
        <span v-for="n in 5" :key="n" class="skeleton loading-list__row" />
      </div>

      <EmptyState
        v-else-if="rows.length === 0"
        :title="view === 'notice' ? '还没有平台公告' : '没有符合条件的通知'"
        note="新建一条公告，它会先以草稿形式保存。"
      >
        <el-button type="primary" @click="openCreate">新建公告</el-button>
      </EmptyState>

      <div v-else class="table-scroll">
        <el-table :data="rows" size="small" style="width: 100%">
          <el-table-column label="内容" min-width="320">
            <template #default="{ row }">
              <span class="cell-strong">{{ row.content }}</span>
            </template>
          </el-table-column>
          <el-table-column label="类型" width="110">
            <template #default="{ row }">
              <StatePill
                :label="labelOf(NOTICE_TYPE, row.noticeType).label"
                :tone="labelOf(NOTICE_TYPE, row.noticeType).tone"
              />
            </template>
          </el-table-column>
          <el-table-column label="接收对象" width="130">
            <template #default="{ row }">
              {{ row.userId === null || row.userId === undefined ? '全体用户' : `用户 #${row.userId}` }}
            </template>
          </el-table-column>
          <el-table-column label="状态" width="100">
            <template #default="{ row }">
              <StatePill
                :label="labelOf(NOTICE_STATE, row.noticeStatus).label"
                :tone="labelOf(NOTICE_STATE, row.noticeStatus).tone"
              />
            </template>
          </el-table-column>
          <el-table-column label="创建时间" min-width="160">
            <template #default="{ row }">
              <span>{{ formatDateTime(row.createTime) }}</span>
              <span class="cell-sub">{{ formatRelative(row.createTime) }}</span>
            </template>
          </el-table-column>
          <el-table-column label="有效期" min-width="120">
            <template #default="{ row }">{{ row.expireTime || '长期有效' }}</template>
          </el-table-column>
          <el-table-column label="操作" width="220" fixed="right">
            <template #default="{ row }">
              <el-button size="small" @click="openEdit(row)">编辑</el-button>
              <el-button
                v-if="row.noticeStatus !== 1"
                size="small"
                type="primary"
                :loading="busyId === row.noticeId"
                @click="publish(row)"
              >
                发布
              </el-button>
              <el-button
                size="small"
                :loading="busyId === row.noticeId"
                @click="remove(row)"
              >
                删除
              </el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </section>

    <div v-if="!loading && rows.length > 0" class="pager">
      <el-pagination
        v-model:current-page="page"
        v-model:page-size="size"
        :page-sizes="[10, 20, 50]"
        layout="total, sizes, prev, pager, next"
        :total="matched"
        @size-change="changeSize"
        @current-change="changePage"
      />
    </div>

    <el-drawer v-model="drawer" :title="drawerTitle" size="480px" direction="rtl">
      <div class="form">
        <label class="field">
          <span class="field__label">内容</span>
          <el-input
            v-model="form.content"
            type="textarea"
            :rows="5"
            maxlength="500"
            show-word-limit
            placeholder="写给商家与用户看的一句话，例如：平台将于 4 月 20 日 02:00-04:00 维护"
          />
        </label>
        <label class="field">
          <span class="field__label">类型</span>
          <el-select v-model="form.noticeType" style="width: 100%">
            <el-option
              v-for="(item, code) in NOTICE_TYPE"
              :key="code"
              :label="item.label"
              :value="Number(code)"
            />
          </el-select>
        </label>
        <label class="field">
          <span class="field__label">接收用户 ID</span>
          <el-input v-model="form.userId" placeholder="留空表示面向全体用户" />
          <span class="field__hint">
            填写单个用户 ID 时，这条会作为站内通知出现在对方的消息中心；留空则是平台公告存档。
          </span>
        </label>
        <label class="field">
          <span class="field__label">有效期</span>
          <el-date-picker
            v-model="form.expireTime"
            type="date"
            value-format="YYYY-MM-DD"
            placeholder="可留空"
            style="width: 100%"
          />
        </label>

        <p v-if="formError" class="form__error">
          <AppIcon name="warning" size="14" />
          <span>{{ formError }}</span>
        </p>

        <p class="form__note">
          保存后记录是草稿；要让它生效，请在列表里对它点「发布」。
        </p>
      </div>

      <template #footer>
        <div class="form__actions">
          <el-button @click="drawer = false">取消</el-button>
          <el-button type="primary" :loading="saving" @click="save">保存</el-button>
        </div>
      </template>
    </el-drawer>
  </div>
</template>

<style scoped>
.notices {
  display: flex;
  flex-direction: column;
  gap: var(--gap-surface);
}

.link-action {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 0;
  border: none;
  background: none;
  color: var(--ink-2);
  font-size: var(--text-sm);
  font-weight: 500;
  cursor: pointer;
}

.link-action:hover {
  color: var(--ink-0);
  text-decoration: underline;
}

.link-action:disabled {
  color: var(--ink-4);
  cursor: default;
  text-decoration: none;
}

.toolbar {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.toolbar__input {
  max-width: 240px;
}

.toolbar__count {
  margin-left: auto;
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.segmented {
  display: inline-flex;
  border: var(--edge);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.segmented__item {
  padding: 0 14px;
  height: calc(30px * var(--dense));
  border: none;
  border-right: var(--hairline);
  background: var(--paper-0);
  color: var(--ink-2);
  font-size: var(--text-sm);
  cursor: pointer;
}

.segmented__item:last-child {
  border-right: none;
}

.segmented__item.is-on {
  background: var(--ink-0);
  color: var(--on-ink);
  font-weight: 600;
}

.band {
  display: flex;
  align-items: flex-start;
  gap: var(--space-2);
  padding: var(--space-3) var(--space-4);
  border: var(--edge);
  border-radius: var(--radius-md);
  font-size: var(--text-sm);
}

.band--notice {
  background: var(--paper-2);
  color: var(--ink-2);
}

.band--error {
  background: var(--signal-vermilion-wash);
  border-color: var(--signal-vermilion);
  color: var(--signal-vermilion-deep);
}

.band__action {
  margin-left: auto;
  padding: 2px 10px;
  border: 1px solid currentColor;
  border-radius: var(--radius-sm);
  background: transparent;
  color: inherit;
  font-size: var(--text-xs);
  cursor: pointer;
}

.loading-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-4);
}

.loading-list__row {
  height: calc(40px * var(--dense));
}

.table-scroll {
  width: 100%;
  overflow-x: auto;
}

.cell-strong {
  display: block;
  color: var(--ink-1);
  line-height: 1.5;
}

.cell-sub {
  display: block;
  color: var(--ink-3);
  font-size: var(--text-xs);
}

.pager {
  display: flex;
  justify-content: flex-end;
}

.form {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.field {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.field__label {
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.field__hint,
.form__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.form__error {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  color: var(--signal-vermilion-deep);
  font-size: var(--text-xs);
}

.form__actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}
</style>
