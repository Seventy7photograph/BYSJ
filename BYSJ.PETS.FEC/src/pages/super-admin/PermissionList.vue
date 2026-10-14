<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import {
  buildPermissionModules,
  collectPermissionIds,
  createPermission,
  deletePermission,
  fetchPermissions,
  flattenPermissions,
  readableError,
  updatePermission,
  type PermissionItem,
  type PermissionModule,
} from '@/api/super-admin'

/**
 * 权限清单。
 *
 * 一条权限就是一条后端接口规则：权限码（大写下划线）加接口地址与请求方法。
 * 权限表本身是树（parent_id 自引用），所以这里按模块分组展示，用缩进表达层级，
 * 同时保留原来的增删改与导出。
 *
 * 数据库给 parent_id 建了 ON DELETE CASCADE：删掉一条权限会连同它的整棵子树、
 * 以及所有角色对它们的绑定一起消失，所以删除前的确认里会写清受影响的条数。
 */

const METHODS = ['GET', 'POST', 'PUT', 'DELETE', '*'] as const

const loading = ref(true)
const error = ref('')
const tree = ref<PermissionItem[]>([])
const keyword = ref('')
const moduleKey = ref<string>('all')
const selectedIds = ref<number[]>([])
const batchBusy = ref(false)

const flat = computed(() => flattenPermissions(tree.value))
const modules = computed<PermissionModule[]>(() => buildPermissionModules(tree.value))

/**
 * 每条权限的层级与所属模块，用来做缩进与分组筛选。
 * 模块划分必须与权限矩阵用同一套规则（buildPermissionModules），
 * 否则同一条权限在两个页面里会归到不同的模块名下。
 */
const rowMeta = computed(() => {
  const depth = new Map<number, number>()
  const walk = (list: PermissionItem[], level: number) => {
    for (const node of list) {
      depth.set(node.permissionId, level)
      walk(node.children ?? [], level + 1)
    }
  }
  walk(tree.value, 0)

  const meta = new Map<number, { depth: number; moduleKey: string; moduleTitle: string }>()
  for (const module of modules.value) {
    for (const item of module.items) {
      meta.set(item.permissionId, {
        depth: depth.get(item.permissionId) ?? 0,
        moduleKey: module.key,
        moduleTitle: module.title,
      })
    }
  }
  return meta
})

const visibleRows = computed(() => {
  const text = keyword.value.trim().toLowerCase()
  return flat.value
    .map((item) => ({
      item,
      meta: rowMeta.value.get(item.permissionId) ?? { depth: 0, moduleKey: 'all', moduleTitle: '' },
    }))
    .filter(({ item, meta }) => {
      if (moduleKey.value !== 'all' && meta.moduleKey !== moduleKey.value) return false
      if (!text) return true
      return (
        item.permissionName.toLowerCase().includes(text) ||
        item.permissionCode.toLowerCase().includes(text) ||
        item.url.toLowerCase().includes(text)
      )
    })
})

const filtered = computed(() => moduleKey.value !== 'all' || keyword.value.trim().length > 0)
const selectedCount = computed(() => selectedIds.value.length)

function descendantCount(item: PermissionItem): number {
  return collectPermissionIds(item).length - 1
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const result = await fetchPermissions()
    tree.value = result.tree
    selectedIds.value = []
    if (moduleKey.value !== 'all' && !modules.value.some((item) => item.key === moduleKey.value)) {
      moduleKey.value = 'all'
    }
  } catch (e) {
    tree.value = []
    error.value = readableError(e, '权限清单加载失败')
  } finally {
    loading.value = false
  }
}

function resetFilters() {
  moduleKey.value = 'all'
  keyword.value = ''
}

function toggleRow(permissionId: number) {
  selectedIds.value = selectedIds.value.includes(permissionId)
    ? selectedIds.value.filter((id) => id !== permissionId)
    : [...selectedIds.value, permissionId]
}

/* --- 新增 / 编辑 ---------------------------------------------------------- */

const dialogOpen = ref(false)
const submitting = ref(false)
const formRef = ref<FormInstance>()
const editingId = ref<number | null>(null)
const form = reactive({
  permissionName: '',
  permissionCode: '',
  url: '',
  method: 'GET' as string,
  parentId: null as number | null,
})

/** 编辑时不能把权限挂到自己或自己的后代下面，否则树会成环。 */
const parentOptions = computed(() => {
  const currentId = editingId.value
  const banned = new Set<number>()
  if (currentId !== null) {
    const self = flat.value.find((item) => item.permissionId === currentId)
    if (self) for (const id of collectPermissionIds(self)) banned.add(id)
  }
  return flat.value.filter((item) => !banned.has(item.permissionId))
})

const rules: FormRules = {
  permissionName: [
    { required: true, message: '请输入权限名称', trigger: 'blur' },
    { min: 2, max: 100, message: '权限名称长度 2 到 100 位', trigger: 'blur' },
  ],
  permissionCode: [
    { required: true, message: '请输入权限编码', trigger: 'blur' },
    {
      pattern: /^[A-Z][A-Z0-9_]*$/,
      message: '权限编码用大写字母、数字与下划线，并以字母开头',
      trigger: 'blur',
    },
  ],
  url: [
    { required: true, message: '请输入接口地址', trigger: 'blur' },
    { pattern: /^\/.*$/, message: '接口地址以 / 开头，可用 ** 通配', trigger: 'blur' },
  ],
  method: [{ required: true, message: '请选择请求方法', trigger: 'change' }],
}

function openCreate(parent: PermissionItem | null) {
  editingId.value = null
  Object.assign(form, {
    permissionName: '',
    permissionCode: '',
    url: '',
    method: 'GET',
    parentId: parent ? parent.permissionId : null,
  })
  dialogOpen.value = true
  void formRef.value?.clearValidate()
}

function openEdit(item: PermissionItem) {
  editingId.value = item.permissionId
  Object.assign(form, {
    permissionName: item.permissionName,
    permissionCode: item.permissionCode,
    url: item.url,
    method: item.method || 'GET',
    parentId: item.parentId ?? null,
  })
  dialogOpen.value = true
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
    const payload = {
      permissionName: form.permissionName.trim(),
      permissionCode: form.permissionCode.trim(),
      url: form.url.trim(),
      method: form.method,
      parentId: form.parentId,
    }
    if (editingId.value === null) {
      await createPermission(payload)
      ElMessage.success('权限已新增')
    } else {
      await updatePermission(editingId.value, payload)
      ElMessage.success('权限已更新')
    }
    dialogOpen.value = false
    await load()
  } catch (e) {
    ElMessage.error(readableError(e, '保存失败，请检查填写内容'))
  } finally {
    submitting.value = false
  }
}

/* --- 删除 ---------------------------------------------------------------- */

async function remove(item: PermissionItem) {
  const children = descendantCount(item)
  const scope = children > 0 ? `该权限下还有 ${children} 条子权限会一并删除，` : ''
  try {
    await ElMessageBox.confirm(
      `删除「${item.permissionName}」（${item.permissionCode}）：${scope}所有角色对它们的绑定关系也会同时移除，操作不可恢复。`,
      '删除权限',
      { confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning' },
    )
  } catch {
    return
  }

  try {
    await deletePermission(item.permissionId)
    ElMessage.success('权限已删除')
    await load()
  } catch (e) {
    ElMessage.error(readableError(e, '删除失败'))
  }
}

async function batchDelete() {
  const ids = [...selectedIds.value]
  if (ids.length === 0) return
  try {
    await ElMessageBox.confirm(
      `将删除选中的 ${ids.length} 条权限，它们的子权限与角色绑定会一并移除，操作不可恢复。`,
      '批量删除权限',
      { confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning' },
    )
  } catch {
    return
  }

  batchBusy.value = true
  try {
    const results = await Promise.allSettled(ids.map((id) => deletePermission(id)))
    const failed = results.filter((item) => item.status === 'rejected').length
    const done = results.length - failed
    if (failed === 0) ElMessage.success(`已删除 ${done} 条权限`)
    else if (done === 0) ElMessage.error(`删除失败，${failed} 条权限未变更`)
    else ElMessage.warning(`已删除 ${done} 条，${failed} 条失败`)
    await load()
  } finally {
    batchBusy.value = false
  }
}

/* --- 导出 ---------------------------------------------------------------- */

function csvCell(value: unknown): string {
  const text = value === null || value === undefined ? '' : String(value)
  return `"${text.replace(/"/g, '""')}"`
}

function exportCsv() {
  if (visibleRows.value.length === 0) {
    ElMessage.warning('没有可导出的权限')
    return
  }
  const header = ['权限ID', '权限名称', '权限编码', '接口地址', '请求方法', '上级权限ID', '所属模块']
  const lines = visibleRows.value.map(({ item, meta }) =>
    [
      item.permissionId,
      item.permissionName,
      item.permissionCode,
      item.url,
      item.method,
      item.parentId ?? '',
      meta.moduleTitle,
    ]
      .map(csvCell)
      .join(','),
  )
  const csv = [header.map(csvCell).join(','), ...lines].join('\n')
  const blob = new Blob([`\ufeff${csv}`], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  link.href = URL.createObjectURL(blob)
  link.download = `权限清单_${new Date().toISOString().slice(0, 10)}.csv`
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(link.href)
  ElMessage.success(`已导出 ${visibleRows.value.length} 条`)
}

onMounted(load)
</script>

<template>
  <div class="page">
    <SectionHead
      title="权限清单"
      :note="`共 ${flat.length} 条权限，分 ${modules.length} 个模块 · 权限码与后端接口规则一一对应`"
      size="lg"
    >
      <template #action>
        <div class="head-actions">
          <button class="btn" type="button" :disabled="loading" @click="load">
            <AppIcon name="refresh" size="14" />
            刷新
          </button>
          <button class="btn" type="button" :disabled="loading" @click="exportCsv">
            <AppIcon name="download" size="14" />
            导出
          </button>
          <button class="btn btn--solid" type="button" @click="openCreate(null)">
            <AppIcon name="plus" size="14" />
            新增权限
          </button>
        </div>
      </template>
    </SectionHead>

    <div class="filters">
      <div class="seg" role="tablist" aria-label="权限模块">
        <button
          class="seg__item"
          :class="{ 'is-active': moduleKey === 'all' }"
          type="button"
          role="tab"
          :aria-selected="moduleKey === 'all'"
          @click="moduleKey = 'all'"
        >
          全部
        </button>
        <button
          v-for="module in modules"
          :key="module.key"
          class="seg__item"
          :class="{ 'is-active': moduleKey === module.key }"
          type="button"
          role="tab"
          :aria-selected="moduleKey === module.key"
          @click="moduleKey = module.key"
        >
          {{ module.title }}
        </button>
      </div>

      <label class="search">
        <AppIcon name="search" size="15" />
        <input
          v-model="keyword"
          class="search__input"
          type="search"
          placeholder="名称、权限码或接口地址"
          aria-label="搜索权限"
        />
      </label>
      <button v-if="filtered" class="btn btn--ghost" type="button" @click="resetFilters">重置</button>
    </div>

    <div class="bulk">
      <p class="bulk__count">
        {{ selectedCount ? `已选 ${selectedCount} 条` : `当前 ${visibleRows.length} 条` }}
      </p>
      <button
        v-if="selectedCount"
        class="btn btn--danger"
        type="button"
        :disabled="batchBusy"
        @click="batchDelete"
      >
        批量删除
      </button>
      <button v-if="selectedCount" class="btn btn--ghost" type="button" @click="selectedIds = []">
        取消选择
      </button>
      <span v-if="batchBusy" class="bulk__note">正在处理…</span>
    </div>

    <div v-if="loading" class="plate" aria-busy="true">
      <div v-for="n in 7" :key="n" class="ghost-row">
        <span class="ghost ghost--lg skeleton" />
        <span class="ghost ghost--sm skeleton" />
        <span class="ghost ghost--sm skeleton" />
      </div>
    </div>

    <div v-else-if="error" class="plate">
      <EmptyState title="权限清单加载失败" :note="error">
        <button class="btn" type="button" @click="load">
          <AppIcon name="refresh" size="14" />
          重新加载
        </button>
      </EmptyState>
    </div>

    <div v-else-if="visibleRows.length === 0" class="plate">
      <EmptyState
        :title="flat.length === 0 ? '还没有权限项' : '没有符合条件的权限'"
        :note="
          flat.length === 0
            ? '先建一个顶级权限作为模块，再往模块下面挂具体的接口权限。'
            : '换一个模块，或者清空搜索词。'
        "
      >
        <button v-if="flat.length === 0" class="btn btn--solid" type="button" @click="openCreate(null)">
          新增权限
        </button>
        <button v-else class="btn" type="button" @click="resetFilters">清空筛选</button>
      </EmptyState>
    </div>

    <div v-else class="plate table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th class="col-check"><span class="sr-only">选择</span></th>
            <th>权限</th>
            <th>权限码</th>
            <th>接口</th>
            <th>所属模块</th>
            <th class="col-action">操作</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="{ item, meta } in visibleRows"
            :key="item.permissionId"
            :class="{ 'is-top': meta.depth === 0 }"
          >
            <td class="col-check">
              <input
                type="checkbox"
                :checked="selectedIds.includes(item.permissionId)"
                :aria-label="`选中 ${item.permissionName}`"
                @change="toggleRow(item.permissionId)"
              />
            </td>
            <td>
              <span class="name" :style="{ paddingLeft: `${meta.depth * 16}px` }">
                <span v-if="meta.depth > 0" class="branch" aria-hidden="true">└</span>
                {{ item.permissionName }}
              </span>
            </td>
            <td class="mono code">{{ item.permissionCode }}</td>
            <td>
              <span class="method mono">{{ item.method }}</span>
              <span class="mono url">{{ item.url }}</span>
            </td>
            <td class="sub">{{ meta.moduleTitle || '根权限' }}</td>
            <td class="col-action">
              <div class="row-actions">
                <button class="link" type="button" @click="openCreate(item)">加子项</button>
                <button class="link" type="button" @click="openEdit(item)">编辑</button>
                <button class="link link--danger" type="button" @click="remove(item)">删除</button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <el-dialog v-model="dialogOpen" :title="editingId === null ? '新增权限' : '编辑权限'" width="520px">
      <el-form ref="formRef" :model="form" :rules="rules" label-position="top">
        <el-form-item label="上级权限">
          <el-select v-model="form.parentId" placeholder="不选即顶级权限" clearable style="width: 100%">
            <el-option :value="null" label="（顶级权限）" />
            <el-option
              v-for="option in parentOptions"
              :key="option.permissionId"
              :value="option.permissionId"
              :label="`${option.permissionName} · ${option.permissionCode}`"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="权限名称" prop="permissionName">
          <el-input v-model="form.permissionName" placeholder="如：商品审核" maxlength="100" />
        </el-form-item>
        <el-form-item label="权限编码" prop="permissionCode">
          <el-input v-model="form.permissionCode" placeholder="如：PRODUCT_AUDIT" maxlength="100" />
        </el-form-item>
        <el-form-item label="接口地址" prop="url">
          <el-input
            v-model="form.url"
            placeholder="如：/admin/products/{productId}/audit"
            maxlength="255"
          />
        </el-form-item>
        <el-form-item label="请求方法" prop="method">
          <el-radio-group v-model="form.method">
            <el-radio v-for="method in METHODS" :key="method" :value="method">{{ method }}</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>

      <template #footer>
        <div class="dialog-foot">
          <button class="btn" type="button" @click="dialogOpen = false">取消</button>
          <button class="btn btn--solid" type="button" :disabled="submitting" @click="submit">
            {{ submitting ? '保存中…' : '保存' }}
          </button>
        </div>
      </template>
    </el-dialog>
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
  margin-left: auto;
  width: 260px;
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

.table-wrap {
  overflow-x: auto;
}

.table {
  width: 100%;
  min-width: 980px;
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

.table tr.is-top td {
  background: var(--paper-1);
  font-weight: 600;
}

.col-check {
  width: 44px;
  padding-right: 0 !important;
}

.col-action {
  width: 190px;
}

.name {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: var(--ink-0);
}

.branch {
  color: var(--ink-4);
}

.code {
  color: var(--ink-2);
  white-space: nowrap;
}

.url {
  color: var(--ink-1);
  word-break: break-all;
}

.method {
  display: inline-block;
  min-width: 46px;
  margin-right: var(--space-2);
  padding: 1px 4px;
  border: 1px solid var(--line-2);
  border-radius: var(--radius-xs);
  color: var(--ink-3);
  font-size: var(--text-2xs);
  text-align: center;
}

.sub {
  color: var(--ink-3);
  font-size: var(--text-xs);
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

.dialog-foot {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}

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
  width: 28%;
  height: 18px;
}

.ghost--sm {
  width: 16%;
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
    margin-left: 0;
    width: 100%;
  }

  .filters {
    gap: var(--space-2);
  }
}
</style>
