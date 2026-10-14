<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { getUserList, updateUser, updateUserStatus } from '@/api/admin/user'
import type { AdminUser } from '@/api/admin/http'
import { ACCOUNT_STATUS, USER_TYPE, labelOf } from '@/constants/domain'
import { formatDateTime, formatRelative, maskPhone } from '@/utils/format'

/**
 * 普通用户（买家账号）管理。
 *
 * 停用是这一页唯一的高风险动作，所以每一次停用都有二次确认，并且写清楚影响范围；
 * 批量操作逐条收集结果，不再"整体成功/整体失败"。
 *
 * 原来的页面有几处不成立：
 *   1. 批量启用/停用用了 ElMessageBox 但没 import，点了就是 ReferenceError；
 *   2. 停用没有任何确认，点一下账号就没了；
 *   3. 状态标签把 status 只有 0/1 两态来渲染，而库里 status=2 是"未认证"，
 *      会被显示成"禁用"；
 *   4. 状态筛选的初值是空字符串，与 el-select 的数值选项混用。
 */

const loading = ref(true)
const failed = ref(false)
const rows = ref<AdminUser[]>([])
const total = ref(0)
const page = ref(1)
const size = ref(10)
const selected = ref<AdminUser[]>([])
const busy = ref(false)

const filters = reactive({
  keyword: '',
  status: '' as number | '',
})

const editing = ref(false)
const form = reactive({
  userId: 0,
  username: '',
  nickname: '',
  phone: '',
  email: '',
  status: 1,
  /** 记录打开表单时的原始状态，用来决定"未认证"选项是否出现。 */
  originalStatus: 1,
})
const saving = ref(false)
const saveError = ref('')

const statusOptions = computed(() => {
  const base = [
    { value: 1, label: '正常' },
    { value: 0, label: '已停用' },
  ]
  if (form.originalStatus === 2) base.push({ value: 2, label: '未认证（不能下单）' })
  return base
})

function accountState(row: AdminUser) {
  return labelOf(ACCOUNT_STATUS, row.status, '未认证')
}

async function load() {
  loading.value = true
  failed.value = false
  try {
    const pageData = await getUserList({
      pageNum: page.value,
      pageSize: size.value,
      keyword: filters.keyword.trim() || undefined,
      status: filters.status === '' ? undefined : Number(filters.status),
    })
    const records = pageData.records ?? []
    // 后端的关键词检索绕过了 user_type 限制，这里再筛一次，只留普通用户。
    rows.value = records.filter((row) => row.userType === 1)
    total.value = pageData.total ?? rows.value.length
    selected.value = []
  } catch {
    failed.value = true
    rows.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

function search() {
  page.value = 1
  void load()
}

function resetFilters() {
  filters.keyword = ''
  filters.status = ''
  search()
}

function changeSize() {
  page.value = 1
  void load()
}

function openEditor(row: AdminUser) {
  form.userId = row.userId
  form.username = row.username
  form.nickname = row.nickname ?? ''
  form.phone = row.phone ?? ''
  form.email = row.email ?? ''
  form.status = row.status
  form.originalStatus = row.status
  saveError.value = ''
  editing.value = true
}

async function save() {
  if (saving.value) return
  const nickname = form.nickname.trim()
  const phone = form.phone.trim()
  const email = form.email.trim()
  if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    saveError.value = '邮箱格式不正确。'
    return
  }
  if (phone && !/^\d{6,20}$/.test(phone)) {
    saveError.value = '手机号只能是 6 到 20 位数字。'
    return
  }
  saveError.value = ''
  saving.value = true
  try {
    // 后端是全量覆盖，必须把整行带上，否则没传的字段会被写成 null。
    await updateUser(form.userId, {
      username: form.username,
      nickname: nickname || null,
      phone: phone || null,
      email: email || null,
      status: form.status,
    })
    ElMessage.success('资料已更新')
    editing.value = false
    await load()
  } catch (error) {
    saveError.value = error instanceof Error ? error.message : '保存失败，请重试'
  } finally {
    saving.value = false
  }
}

function disableEffect(row: AdminUser) {
  return `停用后「${row.nickname || row.username}」无法登录、下单、评价或发布内容；已支付订单照常流转，随时可以再启用。`
}

async function toggleStatus(row: AdminUser, next: 0 | 1) {
  const title = next === 0 ? '停用账号' : '启用账号'
  try {
    await ElMessageBox.confirm(
      next === 0 ? disableEffect(row) : '启用后该账号可以正常登录与下单。',
      title,
      { confirmButtonText: next === 0 ? '停用' : '启用', cancelButtonText: '取消' },
    )
  } catch {
    return
  }
  try {
    await updateUserStatus(row.userId, next)
    ElMessage.success(next === 0 ? '账号已停用' : '账号已启用')
    await load()
  } catch {
    // 拦截器已经提示过服务端原因，这里只需要让列表回到真实状态。
    await load()
  }
}

function batchTargets(next: 0 | 1) {
  return selected.value.filter((row) => (next === 0 ? row.status === 1 : row.status !== 1))
}

async function runBatch(next: 0 | 1) {
  const targets = batchTargets(next)
  if (targets.length === 0) {
    ElMessage.warning(next === 0 ? '选中的账号里没有可停用的' : '选中的账号里没有可启用的')
    return
  }
  try {
    await ElMessageBox.confirm(
      next === 0
        ? `将停用 ${targets.length} 个账号。停用后这些账号无法登录与下单，已支付订单不受影响。`
        : `将启用 ${targets.length} 个账号。`,
      next === 0 ? '批量停用' : '批量启用',
      { confirmButtonText: next === 0 ? '停用' : '启用', cancelButtonText: '取消' },
    )
  } catch {
    return
  }

  busy.value = true
  const failures: string[] = []
  for (const row of targets) {
    try {
      await updateUserStatus(row.userId, next)
    } catch (error) {
      failures.push(`${row.username}：${error instanceof Error ? error.message : '失败'}`)
    }
  }
  busy.value = false
  if (failures.length === 0) {
    ElMessage.success(`已处理 ${targets.length} 个账号`)
  } else {
    ElMessage.warning(`${targets.length - failures.length} 个成功，${failures.length} 个失败`)
  }
  await load()
}

function exportCsv() {
  const header = ['用户ID', '账号', '昵称', '手机号', '邮箱', '状态', '注册时间']
  const body = rows.value.map((row) => [
    row.userId,
    row.username,
    row.nickname ?? '',
    row.phone ?? '',
    row.email ?? '',
    accountState(row).label,
    formatDateTime(row.createTime),
  ])
  const csv = [header, ...body].map((row) => row.map(csvCell).join(',')).join('\n')
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  link.href = URL.createObjectURL(blob)
  link.download = `普通用户_${new Date().toISOString().slice(0, 10)}.csv`
  link.click()
  URL.revokeObjectURL(link.href)
}

function csvCell(value: string | number | null | undefined) {
  const text = value === null || value === undefined ? '' : String(value)
  return /[",\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text
}

onMounted(() => {
  void load()
})
</script>

<template>
  <div class="users" data-density="admin">
    <SectionHead
      title="普通用户"
      note="买家账号。停用会立刻阻止登录与下单，已支付的订单不受影响。"
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
      <el-input
        v-model="filters.keyword"
        class="toolbar__input"
        placeholder="账号 / 昵称 / 手机号"
        clearable
        @keyup.enter="search"
      />
      <el-select v-model="filters.status" class="toolbar__select" placeholder="账号状态" clearable>
        <el-option label="正常" :value="1" />
        <el-option label="已停用" :value="0" />
        <el-option label="未认证" :value="2" />
      </el-select>
      <el-button @click="search">查询</el-button>
      <el-button @click="resetFilters">重置</el-button>
      <el-button :disabled="rows.length === 0" @click="exportCsv">
        <AppIcon name="download" size="14" />
        导出当前页
      </el-button>
      <span class="toolbar__count">共 {{ total }} 个账号</span>
    </div>

    <div v-if="selected.length > 0" class="bulk">
      <span class="bulk__count">已选 {{ selected.length }} 个</span>
      <el-button size="small" :disabled="busy" @click="runBatch(1)">批量启用</el-button>
      <el-button size="small" :disabled="busy" @click="runBatch(0)">批量停用</el-button>
    </div>

    <p v-if="failed" class="band band--error">
      <AppIcon name="warning" size="15" />
      <span>用户列表没能加载。请确认后端服务在运行，然后重试。</span>
      <button class="band__action" type="button" @click="load">重试</button>
    </p>

    <section class="plate">
      <div v-if="loading" class="loading-list">
        <span v-for="n in 5" :key="n" class="skeleton loading-list__row" />
      </div>

      <EmptyState
        v-else-if="rows.length === 0"
        title="没有符合条件的用户"
        note="换个关键词或状态再试；筛选条件为空时也会走到这里。"
      />

      <div v-else class="table-scroll">
        <el-table
          :data="rows"
          size="small"
          style="width: 100%"
          @selection-change="(val: AdminUser[]) => (selected = val)"
        >
          <el-table-column type="selection" width="42" />
          <el-table-column label="账号" min-width="180">
            <template #default="{ row }">
              <span class="cell-strong">{{ row.nickname || '未设置昵称' }}</span>
              <span class="cell-sub mono">{{ row.username }}</span>
            </template>
          </el-table-column>
          <el-table-column label="角色" width="100">
            <template #default="{ row }">
              <StatePill
                :label="labelOf(USER_TYPE, row.userType).label"
                :tone="labelOf(USER_TYPE, row.userType).tone"
              />
            </template>
          </el-table-column>
          <el-table-column label="手机号" min-width="130">
            <template #default="{ row }">{{ maskPhone(row.phone) }}</template>
          </el-table-column>
          <el-table-column label="邮箱" min-width="180">
            <template #default="{ row }">{{ row.email || '—' }}</template>
          </el-table-column>
          <el-table-column label="状态" width="110">
            <template #default="{ row }">
              <StatePill :label="accountState(row).label" :tone="accountState(row).tone" />
            </template>
          </el-table-column>
          <el-table-column label="注册时间" min-width="160">
            <template #default="{ row }">
              <span>{{ formatDateTime(row.createTime) }}</span>
              <span class="cell-sub">{{ formatRelative(row.createTime) }}</span>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="170" fixed="right">
            <template #default="{ row }">
              <el-button size="small" @click="openEditor(row)">编辑</el-button>
              <el-button
                v-if="row.status === 1"
                size="small"
                @click="toggleStatus(row, 0)"
              >
                停用
              </el-button>
              <el-button v-else size="small" type="primary" @click="toggleStatus(row, 1)">
                启用
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
        :total="total"
        @size-change="changeSize"
        @current-change="load"
      />
    </div>

    <el-drawer v-model="editing" title="编辑用户资料" size="420px" direction="rtl">
      <div class="form">
        <label class="field">
          <span class="field__label">登录账号</span>
          <el-input :model-value="form.username" disabled />
        </label>
        <label class="field">
          <span class="field__label">昵称</span>
          <el-input v-model="form.nickname" placeholder="未设置时留空" />
        </label>
        <label class="field">
          <span class="field__label">手机号</span>
          <el-input v-model="form.phone" placeholder="用于登录与订单通知" />
        </label>
        <label class="field">
          <span class="field__label">邮箱</span>
          <el-input v-model="form.email" placeholder="用于找回密码" />
        </label>
        <label class="field">
          <span class="field__label">账号状态</span>
          <el-select v-model="form.status" style="width: 100%">
            <el-option
              v-for="option in statusOptions"
              :key="option.value"
              :label="option.label"
              :value="option.value"
            />
          </el-select>
        </label>

        <p class="form__note">
          保存会整体覆盖这几项资料，未填写的项会变成空值。登录账号不可修改。
        </p>

        <p v-if="saveError" class="form__error">
          <AppIcon name="warning" size="14" />
          <span>{{ saveError }}</span>
        </p>
      </div>

      <template #footer>
        <div class="form__actions">
          <el-button @click="editing = false">取消</el-button>
          <el-button type="primary" :loading="saving" @click="save">保存</el-button>
        </div>
      </template>
    </el-drawer>
  </div>
</template>

<style scoped>
.users {
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

.toolbar__select {
  width: 150px;
}

.toolbar__count {
  margin-left: auto;
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.bulk {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--space-4);
  background: var(--paper-2);
  border: var(--edge);
  border-radius: var(--radius-md);
}

.bulk__count {
  font-size: var(--text-sm);
  color: var(--ink-2);
  margin-right: var(--space-2);
}

.band {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-3) var(--space-4);
  border: var(--edge);
  border-radius: var(--radius-md);
  font-size: var(--text-sm);
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
  color: var(--ink-0);
  font-weight: 600;
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
