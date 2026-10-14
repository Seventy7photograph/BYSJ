<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import SpecList from '@/components/ui/SpecList.vue'
import { getMerchantList, setMerchantStatus, shopStateOf } from '@/api/admin/merchant'
import { updateUser } from '@/api/admin/user'
import type { AdminUser } from '@/api/admin/http'
import { ACCOUNT_STATUS, labelOf } from '@/constants/domain'
import { formatDateTime, formatRelative, maskPhone } from '@/utils/format'

/**
 * 商家账户管理。
 *
 * 这一页只管两件与账号有关的事：营业状态的切换，以及商家账号资料的更正。
 * 店铺名称、店铺地址、简介属于店铺资料，由商家在"店铺管理"里维护，
 * 后端也没有管理员侧的更新入口，所以这里只读展示，不做假的编辑框。
 *
 * 原来的页面有三处对不上后端：
 *   1. 分页参数写的是 `page`（后端认 pageNum），第 2 页起永远是第 1 页；
 *   2. 搜索参数写的是 username / shopName（后端只认 keyword），搜索框完全无效；
 *   3. "保存编辑"打到 PUT /admin/merchants/{id} —— 这个映射在后端根本不存在，
 *      点保存必然 404。真正能改账号资料的是 PUT /admin/users/{id}。
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
  originalStatus: 1,
})
const saving = ref(false)
const saveError = ref('')

const contact = computed(() => {
  const parts: string[] = []
  if (form.phone.trim()) parts.push(`手机 ${form.phone.trim()}`)
  if (form.email.trim()) parts.push(`邮箱 ${form.email.trim()}`)
  return parts.join(' · ') || '未填写'
})

const statusOptions = computed(() => {
  const base = [
    { value: 1, label: '正常' },
    { value: 0, label: '已停用' },
  ]
  if (form.originalStatus === 2) base.push({ value: 2, label: '未认证（不能发布商品）' })
  return base
})

function accountState(row: AdminUser) {
  return labelOf(ACCOUNT_STATUS, row.status, '未认证')
}

async function load() {
  loading.value = true
  failed.value = false
  try {
    const pageData = await getMerchantList({
      pageNum: page.value,
      pageSize: size.value,
      keyword: filters.keyword.trim() || undefined,
      status: filters.status === '' ? undefined : Number(filters.status),
    })
    const records = pageData.records ?? []
    // 关键词检索会绕过 user_type 过滤，这里再筛一次。
    rows.value = records.filter((row) => row.userType === 2)
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
  const phone = form.phone.trim()
  const email = form.email.trim()
  if (phone && !/^\d{6,20}$/.test(phone)) {
    saveError.value = '手机号只能是 6 到 20 位数字。'
    return
  }
  if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    saveError.value = '邮箱格式不正确。'
    return
  }
  saveError.value = ''
  saving.value = true
  try {
    // 走用户资料接口，并且整行提交：后端对该接口是全量覆盖。
    await updateUser(form.userId, {
      username: form.username,
      nickname: form.nickname.trim() || null,
      phone: phone || null,
      email: email || null,
      status: form.status,
    })
    ElMessage.success('账号资料已更新')
    editing.value = false
    await load()
  } catch (error) {
    saveError.value = error instanceof Error ? error.message : '保存失败，请重试'
  } finally {
    saving.value = false
  }
}

async function setShopState(row: AdminUser, next: 0 | 1) {
  const shop = row.shopName || row.nickname || row.username
  try {
    await ElMessageBox.confirm(
      next === 0
        ? `停业后「${shop}」的店铺状态变为已关闭，商家无法继续经营。注意：已上架的商品不会自动下架，需要商家或管理员另行处理。`
        : `恢复后「${shop}」可以正常营业、发布与发货。`,
      next === 0 ? '停业处理' : '恢复营业',
      { confirmButtonText: next === 0 ? '停业' : '恢复', cancelButtonText: '取消' },
    )
  } catch {
    return
  }
  try {
    await setMerchantStatus(row.userId, next)
    ElMessage.success(next === 0 ? '店铺已停业' : '店铺已恢复营业')
    await load()
  } catch {
    // 拦截器已提示服务端原因。
  }
}

async function runBatch(next: 0 | 1) {
  const targets = selected.value.filter((row) =>
    next === 0 ? row.shopStatus === 1 : row.shopStatus === 0,
  )
  if (targets.length === 0) {
    ElMessage.warning(next === 0 ? '选中的店铺里没有营业中的' : '选中的店铺里没有已关闭的')
    return
  }
  try {
    await ElMessageBox.confirm(
      next === 0
        ? `将停业 ${targets.length} 家店铺。已上架商品不会自动下架。`
        : `将恢复 ${targets.length} 家店铺的营业状态。`,
      next === 0 ? '批量停业' : '批量恢复',
      { confirmButtonText: next === 0 ? '停业' : '恢复', cancelButtonText: '取消' },
    )
  } catch {
    return
  }

  busy.value = true
  const failures: string[] = []
  for (const row of targets) {
    try {
      await setMerchantStatus(row.userId, next)
    } catch (error) {
      failures.push(`${row.username}：${error instanceof Error ? error.message : '失败'}`)
    }
  }
  busy.value = false
  if (failures.length === 0) {
    ElMessage.success(`已处理 ${targets.length} 家店铺`)
  } else {
    ElMessage.warning(`${targets.length - failures.length} 家成功，${failures.length} 家失败`)
  }
  await load()
}

function exportCsv() {
  const header = ['商家ID', '登录账号', '店铺名称', '店铺状态', '账号状态', '联系方式', '注册时间']
  const body = rows.value.map((row) => [
    row.userId,
    row.username,
    row.shopName ?? '',
    shopStateOf(row.shopStatus).label,
    accountState(row).label,
    row.phone ?? row.email ?? '',
    formatDateTime(row.createTime),
  ])
  const csv = [header, ...body].map((row) => row.map(csvCell).join(',')).join('\n')
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  link.href = URL.createObjectURL(blob)
  link.download = `商家账户_${new Date().toISOString().slice(0, 10)}.csv`
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
  <div class="merchants" data-density="admin">
    <SectionHead
      title="商家账户"
      note="认证审核在「商家认证审核」里做。这里处理已入驻商家的账号资料与营业状态。"
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
        placeholder="店铺名称 / 登录账号"
        clearable
        @keyup.enter="search"
      />
      <el-select v-model="filters.status" class="toolbar__select" placeholder="店铺状态" clearable>
        <el-option label="正常营业" :value="1" />
        <el-option label="待审核" :value="2" />
        <el-option label="已关闭" :value="0" />
      </el-select>
      <el-button @click="search">查询</el-button>
      <el-button @click="resetFilters">重置</el-button>
      <el-button :disabled="rows.length === 0" @click="exportCsv">
        <AppIcon name="download" size="14" />
        导出当前页
      </el-button>
      <span class="toolbar__count">共 {{ total }} 家</span>
    </div>

    <div v-if="selected.length > 0" class="bulk">
      <span class="bulk__count">已选 {{ selected.length }} 家</span>
      <el-button size="small" :disabled="busy" @click="runBatch(1)">批量恢复营业</el-button>
      <el-button size="small" :disabled="busy" @click="runBatch(0)">批量停业</el-button>
    </div>

    <p v-if="failed" class="band band--error">
      <AppIcon name="warning" size="15" />
      <span>商家列表没能加载。请确认后端服务在运行，然后重试。</span>
      <button class="band__action" type="button" @click="load">重试</button>
    </p>

    <section class="plate">
      <div v-if="loading" class="loading-list">
        <span v-for="n in 5" :key="n" class="skeleton loading-list__row" />
      </div>

      <EmptyState
        v-else-if="rows.length === 0"
        title="没有符合条件的商家"
        note="换个关键词或店铺状态再试。"
      />

      <div v-else class="table-scroll">
        <el-table
          :data="rows"
          size="small"
          style="width: 100%"
          @selection-change="(val: AdminUser[]) => (selected = val)"
        >
          <el-table-column type="selection" width="42" />
          <el-table-column label="店铺" min-width="200">
            <template #default="{ row }">
              <span class="cell-strong">{{ row.shopName || '未填写店铺名称' }}</span>
              <span class="cell-sub mono">{{ row.username }}</span>
            </template>
          </el-table-column>
          <el-table-column label="店铺状态" width="120">
            <template #default="{ row }">
              <StatePill
                :label="shopStateOf(row.shopStatus).label"
                :tone="shopStateOf(row.shopStatus).tone"
              />
            </template>
          </el-table-column>
          <el-table-column label="账号状态" width="120">
            <template #default="{ row }">
              <StatePill :label="accountState(row).label" :tone="accountState(row).tone" />
            </template>
          </el-table-column>
          <el-table-column label="联系方式" min-width="160">
            <template #default="{ row }">
              <span>{{ maskPhone(row.phone) }}</span>
              <span class="cell-sub">{{ row.email || '未填写邮箱' }}</span>
            </template>
          </el-table-column>
          <el-table-column label="入驻时间" min-width="160">
            <template #default="{ row }">
              <span>{{ formatDateTime(row.createTime) }}</span>
              <span class="cell-sub">{{ formatRelative(row.createTime) }}</span>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="180" fixed="right">
            <template #default="{ row }">
              <el-button size="small" @click="openEditor(row)">资料</el-button>
              <el-button
                v-if="row.shopStatus === 1"
                size="small"
                @click="setShopState(row, 0)"
              >
                停业
              </el-button>
              <el-button v-else size="small" type="primary" @click="setShopState(row, 1)">
                恢复营业
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

    <el-drawer v-model="editing" title="商家账号资料" size="460px" direction="rtl">
      <div class="form">
        <SpecList
          :entries="[
            { key: '登录账号', value: form.username, mono: true },
            { key: '联系方式', value: contact },
          ]"
        />

        <label class="field">
          <span class="field__label">联系人（昵称）</span>
          <el-input v-model="form.nickname" placeholder="未填写时留空" />
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
          店铺名称、地址、简介属于店铺资料，由商家在「店铺管理」里维护；管理员侧没有相应的
          更新接口，因此这里只改账号资料。
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
.merchants {
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
