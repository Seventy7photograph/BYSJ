<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import {
  createAdmin,
  deleteAdmin,
  fetchAdmins,
  readableError,
  setAdminStatus,
  updateAdmin,
  type AdminForm,
  type AdminUser,
} from '@/api/super-admin'
import { ACCOUNT_STATUS, labelOf } from '@/constants/domain'
import { formatDateTime, formatRelative } from '@/utils/format'

/**
 * 管理员账号管理。
 *
 * 账号类型固定是「管理员」（user_type = 3），权限不挂在账号上，而是挂在角色上，
 * 所以这里没有"分配角色"这一步 —— 要改能力范围去角色权限矩阵。
 *
 * 页面原有的功能都保留：关键词与状态筛选、分页、新增 / 编辑 / 启停 / 删除、
 * 批量启停与批量删除、导出 CSV。
 */

const PAGE_SIZES = [10, 20, 50, 100]
const STATUS_TABS: { label: string; value: number | null }[] = [
  { label: '全部', value: null },
  { label: '正常', value: 1 },
  { label: '已停用', value: 0 },
]

const loading = ref(true)
const error = ref('')
const rows = ref<AdminUser[]>([])
const total = ref(0)
const page = ref(1)
const pageSize = ref(10)
const statusFilter = ref<number | null>(null)
const usernameInput = ref('')
const phoneInput = ref('')
const selectedIds = ref<number[]>([])
const batchBusy = ref(false)

const filtered = computed(
  () =>
    statusFilter.value !== null ||
    usernameInput.value.trim().length > 0 ||
    phoneInput.value.trim().length > 0,
)

const selectedRows = computed(() => rows.value.filter((row) => selectedIds.value.includes(row.userId)))
const allSelected = computed(
  () => rows.value.length > 0 && rows.value.every((row) => selectedIds.value.includes(row.userId)),
)
const canEnable = computed(
  () => selectedRows.value.length > 0 && selectedRows.value.every((row) => row.status === 0),
)
const canDisable = computed(
  () => selectedRows.value.length > 0 && selectedRows.value.every((row) => row.status === 1),
)

function statusOf(status: number) {
  return labelOf(ACCOUNT_STATUS, status, '状态未知')
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const result = await fetchAdmins({
      page: page.value,
      pageSize: pageSize.value,
      username: usernameInput.value.trim(),
      phone: phoneInput.value.trim(),
      status: statusFilter.value,
    })
    rows.value = result.records
    total.value = result.total
    selectedIds.value = []
  } catch (e) {
    rows.value = []
    total.value = 0
    error.value = readableError(e, '管理员列表加载失败')
  } finally {
    loading.value = false
  }
}

function applyFilters() {
  page.value = 1
  void load()
}

function resetFilters() {
  statusFilter.value = null
  usernameInput.value = ''
  phoneInput.value = ''
  applyFilters()
}

function onChangePage(value: number) {
  page.value = value
  void load()
}

function onChangeSize(value: number) {
  pageSize.value = value
  page.value = 1
  void load()
}

function toggleRow(userId: number) {
  selectedIds.value = selectedIds.value.includes(userId)
    ? selectedIds.value.filter((id) => id !== userId)
    : [...selectedIds.value, userId]
}

function toggleAll() {
  selectedIds.value = allSelected.value ? [] : rows.value.map((row) => row.userId)
}

/* --- 新增 / 编辑 ---------------------------------------------------------- */

const drawerOpen = ref(false)
const submitting = ref(false)
const formRef = ref<FormInstance>()
const editingId = ref<number | null>(null)
const form = reactive<AdminForm>({
  username: '',
  nickname: '',
  password: '',
  phone: '',
  email: '',
  status: 1,
})

function requireLetterAndDigit(_rule: unknown, value: string, callback: (error?: Error) => void) {
  const text = String(value ?? '')
  if (!text) return callback(new Error('请输入密码'))
  if (text.length < 6 || text.length > 20) return callback(new Error('密码长度 6 到 20 位'))
  if (/\s/.test(text)) return callback(new Error('密码不能包含空格'))
  if (!/[A-Za-z]/.test(text) || !/\d/.test(text)) {
    return callback(new Error('密码需同时包含字母和数字'))
  }
  return callback()
}

const rules = computed<FormRules>(() => ({
  username: [
    { required: true, message: '请输入登录用户名', trigger: 'blur' },
    { min: 4, max: 50, message: '用户名长度 4 到 50 位', trigger: 'blur' },
    { pattern: /^[A-Za-z0-9_.@-]+$/, message: '用户名可用字母、数字与 . _ @ -', trigger: 'blur' },
  ],
  nickname: [
    { required: true, message: '请输入昵称', trigger: 'blur' },
    { min: 2, max: 50, message: '昵称长度 2 到 50 位', trigger: 'blur' },
  ],
  password: editingId.value
    ? [{ validator: requireLetterAndDigit, trigger: 'blur' }]
    : [{ required: true, validator: requireLetterAndDigit, trigger: 'blur' }],
  phone: [{ pattern: /^1[3-9]\d{9}$/, message: '请输入 11 位手机号', trigger: 'blur' }],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '邮箱格式不正确', trigger: 'blur' },
  ],
}))

function openCreate() {
  editingId.value = null
  Object.assign(form, {
    username: '',
    nickname: '',
    password: '',
    phone: '',
    email: '',
    status: 1,
  })
  drawerOpen.value = true
  void formRef.value?.clearValidate()
}

function openEdit(row: AdminUser) {
  editingId.value = row.userId
  Object.assign(form, {
    username: row.username,
    nickname: row.nickname ?? '',
    password: '',
    phone: row.phone ?? '',
    email: row.email ?? '',
    status: row.status,
  })
  drawerOpen.value = true
  void formRef.value?.clearValidate()
}

async function submit() {
  if (!formRef.value) return
  try {
    await formRef.value.validate()
  } catch {
    return
  }

  submitting.value = true
  try {
    if (editingId.value === null) {
      await createAdmin({ ...form })
      ElMessage.success('管理员账号已创建')
    } else {
      await updateAdmin(editingId.value, { ...form })
      ElMessage.success(form.password ? '资料与密码已更新' : '资料已更新')
    }
    drawerOpen.value = false
    await load()
  } catch (e) {
    ElMessage.error(readableError(e, '保存失败，请检查填写内容'))
  } finally {
    submitting.value = false
  }
}

/* --- 启停与删除 ---------------------------------------------------------- */

async function toggleStatus(row: AdminUser) {
  const disable = row.status === 1
  if (disable) {
    try {
      await ElMessageBox.confirm(
        `停用「${row.username}」后，该账号无法登录后台，已持有的会话在下一次请求时失效；账号资料与角色权限配置保留，可随时重新启用。`,
        '停用管理员账号',
        { confirmButtonText: '停用', cancelButtonText: '取消', type: 'warning' },
      )
    } catch {
      return
    }
  }

  try {
    await setAdminStatus(row.userId, disable ? 0 : 1)
    ElMessage.success(disable ? `已停用「${row.username}」` : `已启用「${row.username}」`)
    await load()
  } catch (e) {
    ElMessage.error(readableError(e, disable ? '停用失败' : '启用失败'))
  }
}

async function remove(row: AdminUser) {
  try {
    await ElMessageBox.confirm(
      `将永久删除「${row.username}」的账号记录，不能恢复。若该账号被分类、品牌等数据记为创建人，数据库会拒绝删除，这种情况请改用停用。`,
      '删除管理员账号',
      { confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning' },
    )
  } catch {
    return
  }

  try {
    await deleteAdmin(row.userId)
    ElMessage.success('账号已删除')
    if (rows.value.length === 1 && page.value > 1) page.value -= 1
    await load()
  } catch (e) {
    ElMessage.error(readableError(e, '删除失败'))
  }
}

/** 批量操作逐条提交，最后如实报出成功与失败的条数。 */
async function runBatch(
  label: string,
  action: (userId: number) => Promise<unknown>,
  ids: number[],
): Promise<void> {
  batchBusy.value = true
  try {
    const results = await Promise.allSettled(ids.map((id) => action(id)))
    const failed = results.filter((item) => item.status === 'rejected').length
    const done = results.length - failed
    if (failed === 0) {
      ElMessage.success(`已${label} ${done} 个账号`)
    } else if (done === 0) {
      ElMessage.error(`${label}失败，${failed} 个账号未变更`)
    } else {
      ElMessage.warning(`已${label} ${done} 个，${failed} 个失败`)
    }
    await load()
  } finally {
    batchBusy.value = false
  }
}

async function batchStatus(status: number) {
  const ids = selectedRows.value.map((row) => row.userId)
  if (ids.length === 0) return
  const label = status === 1 ? '启用' : '停用'
  if (status === 0) {
    try {
      await ElMessageBox.confirm(
        `停用选中的 ${ids.length} 个账号后，他们将无法登录后台，已持有的会话在下一次请求时失效。`,
        '批量停用账号',
        { confirmButtonText: '停用', cancelButtonText: '取消', type: 'warning' },
      )
    } catch {
      return
    }
  }
  await runBatch(label, (id) => setAdminStatus(id, status), ids)
}

async function batchDelete() {
  const ids = selectedRows.value.map((row) => row.userId)
  if (ids.length === 0) return
  try {
    await ElMessageBox.confirm(
      `将永久删除选中的 ${ids.length} 个账号，不能恢复。被业务数据引用的账号会被数据库拒绝，失败条数会在完成后告知。`,
      '批量删除账号',
      { confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning' },
    )
  } catch {
    return
  }
  await runBatch('删除', (id) => deleteAdmin(id), ids)
}

/* --- 导出 ---------------------------------------------------------------- */

function csvCell(value: unknown): string {
  const text = value === null || value === undefined ? '' : String(value)
  return `"${text.replace(/"/g, '""')}"`
}

async function exportCsv() {
  try {
    const result = await fetchAdmins({
      page: 1,
      pageSize: 1000,
      username: usernameInput.value.trim(),
      phone: phoneInput.value.trim(),
      status: statusFilter.value,
    })
    const header = ['管理员ID', '用户名', '昵称', '手机号', '邮箱', '状态', '创建时间', '更新时间']
    const lines = result.records.map((row) =>
      [
        row.userId,
        row.username,
        row.nickname,
        row.phone,
        row.email,
        statusOf(row.status).label,
        formatDateTime(row.createTime),
        formatDateTime(row.updateTime),
      ]
        .map(csvCell)
        .join(','),
    )
    const csv = [header.map(csvCell).join(','), ...lines].join('\n')
    const blob = new Blob([`\ufeff${csv}`], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = `管理员账号_${new Date().toISOString().slice(0, 10)}.csv`
    link.style.visibility = 'hidden'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    URL.revokeObjectURL(link.href)
    ElMessage.success(`已导出 ${result.records.length} 条`)
  } catch (e) {
    ElMessage.error(readableError(e, '导出失败'))
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <SectionHead
      title="管理员账号"
      :note="`共 ${total} 个账号 · 统一属于「管理员」角色，能力范围由角色权限矩阵决定`"
      size="lg"
    >
      <template #action>
        <div class="head-actions">
          <button class="btn" type="button" :disabled="loading" @click="load">
            <AppIcon name="refresh" size="14" />
            刷新
          </button>
          <button class="btn" type="button" @click="exportCsv">
            <AppIcon name="download" size="14" />
            导出
          </button>
          <button class="btn btn--solid" type="button" @click="openCreate">
            <AppIcon name="plus" size="14" />
            新增管理员
          </button>
        </div>
      </template>
    </SectionHead>

    <div class="filters">
      <div class="seg" role="tablist" aria-label="账号状态">
        <button
          v-for="tab in STATUS_TABS"
          :key="tab.label"
          class="seg__item"
          :class="{ 'is-active': statusFilter === tab.value }"
          type="button"
          role="tab"
          :aria-selected="statusFilter === tab.value"
          @click="((statusFilter = tab.value), applyFilters())"
        >
          {{ tab.label }}
        </button>
      </div>

      <label class="search">
        <AppIcon name="search" size="15" />
        <input
          v-model="usernameInput"
          class="search__input"
          type="search"
          placeholder="用户名"
          aria-label="按用户名搜索"
          @keyup.enter="applyFilters"
        />
      </label>

      <label class="search">
        <AppIcon name="search" size="15" />
        <input
          v-model="phoneInput"
          class="search__input"
          type="search"
          placeholder="手机号"
          aria-label="按手机号搜索"
          @keyup.enter="applyFilters"
        />
      </label>

      <button class="btn" type="button" @click="applyFilters">查询</button>
      <button v-if="filtered" class="btn btn--ghost" type="button" @click="resetFilters">重置</button>
    </div>

    <div class="bulk">
      <p class="bulk__count">
        {{ selectedIds.length ? `已选 ${selectedIds.length} 个` : `本页 ${rows.length} 个` }}
      </p>
      <button
        v-if="selectedIds.length"
        class="btn"
        type="button"
        :disabled="!canEnable || batchBusy"
        @click="batchStatus(1)"
      >
        批量启用
      </button>
      <button
        v-if="selectedIds.length"
        class="btn"
        type="button"
        :disabled="!canDisable || batchBusy"
        @click="batchStatus(0)"
      >
        批量停用
      </button>
      <button
        v-if="selectedIds.length"
        class="btn btn--danger"
        type="button"
        :disabled="batchBusy"
        @click="batchDelete"
      >
        批量删除
      </button>
      <button v-if="selectedIds.length" class="btn btn--ghost" type="button" @click="selectedIds = []">
        取消选择
      </button>
      <span v-if="batchBusy" class="bulk__note">正在处理…</span>
    </div>

    <!-- 加载 -->
    <div v-if="loading" class="plate" aria-busy="true">
      <div v-for="n in 6" :key="n" class="ghost-row">
        <span class="ghost ghost--lg skeleton" />
        <span class="ghost ghost--sm skeleton" />
        <span class="ghost ghost--sm skeleton" />
      </div>
    </div>

    <!-- 错误 -->
    <div v-else-if="error" class="plate">
      <EmptyState title="管理员列表加载失败" :note="error">
        <button class="btn" type="button" @click="load">
          <AppIcon name="refresh" size="14" />
          重新加载
        </button>
      </EmptyState>
    </div>

    <!-- 空 -->
    <div v-else-if="rows.length === 0" class="plate">
      <EmptyState
        :title="filtered ? '没有符合条件的账号' : '还没有管理员账号'"
        :note="
          filtered
            ? '换一个状态，或清空用户名与手机号再查一次。'
            : '新增管理员后，账号即可登录管理员后台处理用户、商家与商品的审核队列。'
        "
      >
        <button v-if="filtered" class="btn" type="button" @click="resetFilters">清空筛选</button>
        <button v-else class="btn btn--solid" type="button" @click="openCreate">
          新增管理员
        </button>
      </EmptyState>
    </div>

    <!-- 列表 -->
    <div v-else class="plate table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th class="col-check">
              <input
                type="checkbox"
                :checked="allSelected"
                aria-label="选中本页全部账号"
                @change="toggleAll"
              />
            </th>
            <th>账号</th>
            <th>昵称</th>
            <th>手机号</th>
            <th>邮箱</th>
            <th>状态</th>
            <th>创建时间</th>
            <th>最后更新</th>
            <th class="col-action">操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="row in rows" :key="row.userId">
            <td class="col-check">
              <input
                type="checkbox"
                :checked="selectedIds.includes(row.userId)"
                :aria-label="`选中 ${row.username}`"
                @change="toggleRow(row.userId)"
              />
            </td>
            <td>
              <span class="account">{{ row.username }}</span>
              <span class="sub mono">#{{ row.userId }}</span>
            </td>
            <td class="nowrap">{{ row.nickname || '—' }}</td>
            <td class="mono">{{ row.phone || '—' }}</td>
            <td class="dim">{{ row.email || '—' }}</td>
            <td>
              <StatePill :label="statusOf(row.status).label" :tone="statusOf(row.status).tone" />
            </td>
            <td class="dim" :title="formatDateTime(row.createTime)">
              {{ formatDateTime(row.createTime) }}
            </td>
            <td class="dim" :title="formatDateTime(row.updateTime)">
              {{ formatRelative(row.updateTime) }}
            </td>
            <td class="col-action">
              <div class="row-actions">
                <button class="link" type="button" @click="openEdit(row)">编辑</button>
                <button class="link" type="button" @click="toggleStatus(row)">
                  {{ row.status === 1 ? '停用' : '启用' }}
                </button>
                <button class="link link--danger" type="button" @click="remove(row)">删除</button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="!loading && !error && total > 0" class="pager">
      <span class="pager__count">
        第 {{ page }} 页 · 每页 {{ pageSize }} 条 · 共 {{ total }} 条
      </span>
      <el-pagination
        :current-page="page"
        :page-size="pageSize"
        :page-sizes="PAGE_SIZES"
        :total="total"
        layout="sizes, prev, pager, next"
        background
        @update:current-page="(value: number) => onChangePage(value)"
        @update:page-size="(value: number) => onChangeSize(value)"
      />
    </div>

    <!-- 新增 / 编辑 -->
    <el-drawer
      v-model="drawerOpen"
      :title="editingId === null ? '新增管理员' : '编辑管理员'"
      direction="rtl"
      size="440px"
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-position="top">
        <el-form-item label="登录用户名" prop="username">
          <el-input v-model="form.username" placeholder="登录后台时使用" maxlength="50" />
        </el-form-item>
        <el-form-item label="昵称" prop="nickname">
          <el-input v-model="form.nickname" placeholder="后台里显示的名字" maxlength="50" />
        </el-form-item>
        <el-form-item :label="editingId === null ? '初始密码' : '重置密码（留空则不修改）'" prop="password">
          <el-input
            v-model="form.password"
            type="password"
            show-password
            placeholder="6 到 20 位，需含字母与数字"
            maxlength="20"
          />
        </el-form-item>
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="form.phone" placeholder="用于登录与通知，可留空" maxlength="11" />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="form.email" placeholder="用于密码重置" maxlength="100" />
        </el-form-item>
        <el-form-item label="账号状态">
          <el-radio-group v-model="form.status">
            <el-radio :value="1">正常</el-radio>
            <el-radio :value="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>

      <template #footer>
        <div class="drawer-foot">
          <button class="btn" type="button" @click="drawerOpen = false">取消</button>
          <button class="btn btn--solid" type="button" :disabled="submitting" @click="submit">
            {{ submitting ? '保存中…' : '保存' }}
          </button>
        </div>
      </template>
    </el-drawer>
  </div>
</template>

<style scoped>
.page {
  max-width: var(--shell-max);
  margin-inline: auto;
  padding-bottom: var(--space-8);
}

.head-actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

/* --- 筛选 ---------------------------------------------------------------- */

.filters {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-3);
  margin: var(--space-4) 0 var(--space-3);
}

.seg {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-1);
}

.seg__item {
  padding: 6px 12px;
  border: 1px solid transparent;
  border-radius: var(--radius-sm);
  background: transparent;
  font-size: var(--text-sm);
  color: var(--ink-3);
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    border-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.seg__item:hover {
  background: var(--paper-2);
  color: var(--ink-1);
}

.seg__item.is-active {
  background: var(--paper-0);
  border-color: var(--line-2);
  color: var(--ink-0);
  font-weight: 600;
}

.search {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  width: 180px;
  height: var(--control-h);
  padding-inline: 10px;
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-xs);
  color: var(--ink-3);
}

.search:focus-within {
  border-color: var(--ink-0);
}

.search__input {
  flex: 1;
  min-width: 0;
  border: none;
  outline: none;
  background: transparent;
  font-size: var(--text-sm);
  color: var(--ink-0);
}

.search__input::placeholder {
  color: var(--ink-4);
}

.bulk {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-3);
  min-height: 32px;
  margin-bottom: var(--space-3);
}

.bulk__count,
.bulk__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

/* --- 表格 ---------------------------------------------------------------- */

.table-wrap {
  overflow-x: auto;
}

.table {
  width: 100%;
  min-width: 1040px;
  border-collapse: collapse;
  font-size: var(--text-sm);
}

.table th {
  padding: var(--space-3) var(--space-4);
  background: var(--paper-2);
  border-bottom: var(--hairline);
  text-align: left;
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--ink-2);
  white-space: nowrap;
}

.table td {
  padding: var(--space-3) var(--space-4);
  border-bottom: var(--hairline);
  color: var(--ink-1);
  vertical-align: middle;
}

.table tbody tr:last-child td {
  border-bottom: none;
}

.table tbody tr:hover td {
  background: var(--paper-1);
}

.col-check {
  width: 44px;
  padding-right: 0 !important;
}

.col-action {
  width: 170px;
}

.account {
  display: block;
  font-weight: 600;
  color: var(--ink-0);
}

/*
 * 注意：表格单元格不能用 .sub —— 那个类带 display:block，会把 <td> 变成非表格单元，
 * 整行的纵向对齐都会错位。单元格用 .dim，只有颜色与字号。
 */
.dim {
  color: var(--ink-3);
  font-size: var(--text-xs);
}

.sub {
  display: block;
  color: var(--ink-3);
  font-size: var(--text-xs);
}

.nowrap {
  white-space: nowrap;
}

.row-actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-3);
}

.link {
  padding: 0;
  border: none;
  background: transparent;
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--ink-1);
  cursor: pointer;
}

.link:hover {
  color: var(--signal-amber-deep);
  text-decoration: underline;
}

.link--danger:hover {
  color: var(--signal-vermilion-deep);
}

.pager {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  margin-top: var(--space-4);
}

.pager__count {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.drawer-foot {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}

/* --- 骨架与控件 ---------------------------------------------------------- */

.ghost-row {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  padding: var(--space-3) var(--space-4);
  border-bottom: var(--hairline);
}

.ghost-row:last-child {
  border-bottom: none;
}

.ghost {
  display: block;
  height: 13px;
}

.ghost--lg {
  width: 30%;
  height: 18px;
}

.ghost--sm {
  width: 14%;
}

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: var(--control-h);
  padding-inline: 14px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  color: var(--ink-1);
  font-size: var(--text-sm);
  font-weight: 500;
  text-decoration: none;
  cursor: pointer;
  white-space: nowrap;
  transition:
    border-color var(--dur-state) ease,
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.btn:hover:not(:disabled) {
  border-color: var(--ink-3);
}

.btn--solid {
  border-color: var(--ink-0);
  background: var(--ink-0);
  color: var(--on-ink);
  font-weight: 600;
}

.btn--solid:hover:not(:disabled) {
  background: #262d33;
  border-color: #262d33;
}

.btn--danger {
  border-color: var(--signal-vermilion);
  color: var(--signal-vermilion-deep);
}

.btn--danger:hover:not(:disabled) {
  background: var(--signal-vermilion-wash);
  border-color: var(--signal-vermilion-deep);
}

.btn--ghost {
  border-color: transparent;
  color: var(--ink-3);
}

.btn:disabled {
  border-color: var(--line-2);
  background: var(--paper-2);
  color: var(--ink-4);
  cursor: not-allowed;
}

@media (max-width: 900px) {
  .search {
    width: 100%;
  }
  .filters {
    gap: var(--space-2);
  }
}
</style>
