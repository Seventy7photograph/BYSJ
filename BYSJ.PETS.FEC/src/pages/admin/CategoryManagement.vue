<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import {
  addCategory,
  deleteCategory,
  getCategoryTree,
  updateCategory,
  type CategoryNode,
} from '@/api/admin/category'
import { getProductList } from '@/api/admin/product'
import { humanizeError } from '@/api/admin/http'
import { useUserStore } from '@/stores/user'

/**
 * 分类管理。
 *
 * 三件事必须让管理员看得见：
 *   1. 每个分类下有多少商品 —— 删除前先知道自己会挡掉什么；
 *   2. 排序值 —— 前端展示顺序按 sort 升序，不改这个数就没法调整顺序；
 *   3. 删除被拒绝的真实原因 —— 后端返回"该分类下有子分类，无法删除"，
 *      被商品引用时则是数据库外键报错，两者都要翻成人话，不能只弹"操作失败"。
 *
 * 另外，新增分类在后端是坏的：product_category.create_by / create_time /
 * update_time 都是 NOT NULL，而 AdminController.addCategory 既不从登录态取用户，
 * 实体也没有自动填充，插入必然被数据库拒绝。这里在请求体里补上这三个字段让功能
 * 可用（正确的修法在后端），见 @/api/admin/category 里的说明。
 */

const userStore = useUserStore()

const loading = ref(true)
const failed = ref(false)
const tree = ref<CategoryNode[]>([])
/** categoryId → 该分类下的商品数。 */
const productCount = ref<Record<number, number>>({})
/** categoryId → 层级（1 起）。 */
const levels = ref<Record<number, number>>({})
const expandAll = ref(true)
const treeKey = ref(0)

const drawer = ref(false)
const mode = ref<'create' | 'edit'>('create')
const parent = ref<CategoryNode | null>(null)
const saving = ref(false)
const formError = ref('')
const listError = ref('')

const form = reactive({
  categoryId: 0,
  categoryName: '',
  categoryCode: '',
  sort: 0,
  status: 1,
  description: '',
})

const drawerTitle = computed(() => {
  if (mode.value === 'edit') return `编辑分类 · ${form.categoryName}`
  return parent.value ? `在「${parent.value.categoryName}」下新增子分类` : '新增顶级分类'
})

/** 分类编码的层级规则到三层为止：第三层不再允许加子分类。 */
const MAX_LEVEL = 3

const maxLevel = computed(() => Math.max(1, ...Object.values(levels.value)))

/** 树结构自己算层级：后端实体里并没有 level 字段（旧代码判的是 undefined）。 */
function collectLevels(nodes: CategoryNode[], level: number, map: Record<number, number>) {
  for (const node of nodes) {
    map[node.categoryId] = level
    if (node.children?.length) collectLevels(node.children, level + 1, map)
  }
  return map
}

/** 后端 selectList 不带排序，这里按 sort + id 归一，展示顺序才稳定。 */
function normalize(nodes: CategoryNode[]): CategoryNode[] {
  return [...nodes]
    .sort((a, b) => (a.sort ?? 0) - (b.sort ?? 0) || a.categoryId - b.categoryId)
    .map((node) => ({ ...node, children: node.children?.length ? normalize(node.children) : [] }))
}

async function load() {
  loading.value = true
  failed.value = false
  listError.value = ''
  try {
    const [nodes, products] = await Promise.all([
      getCategoryTree(),
      getProductList({ pageNum: 1, pageSize: 200 }),
    ])
    const normalized = normalize(nodes ?? [])
    tree.value = normalized
    levels.value = collectLevels(normalized, 1, {})
    if ((products.total ?? 0) > (products.records?.length ?? 0)) {
      listError.value = `商品共 ${products.total} 件，这里只统计了最近 ${products.records.length} 件的占用情况。`
    }
    const counts: Record<number, number> = {}
    for (const item of products.records ?? []) {
      if (item.categoryId === null || item.categoryId === undefined) continue
      counts[item.categoryId] = (counts[item.categoryId] ?? 0) + 1
    }
    productCount.value = counts
  } catch {
    failed.value = true
    tree.value = []
    productCount.value = {}
  } finally {
    loading.value = false
  }
}

function countOf(node: CategoryNode) {
  return productCount.value[node.categoryId] ?? 0
}

function childCount(node: CategoryNode) {
  return node.children?.length ?? 0
}

function canAddChild(node: CategoryNode) {
  return (levels.value[node.categoryId] ?? 1) < MAX_LEVEL
}

function openCreate(parentNode: CategoryNode | null) {
  mode.value = 'create'
  parent.value = parentNode
  form.categoryId = 0
  form.categoryName = ''
  form.categoryCode = ''
  form.sort = parentNode ? childCount(parentNode) + 1 : tree.value.length + 1
  form.status = 1
  form.description = ''
  formError.value = ''
  drawer.value = true
}

function openEdit(node: CategoryNode) {
  mode.value = 'edit'
  parent.value = null
  form.categoryId = node.categoryId
  form.categoryName = node.categoryName
  form.categoryCode = node.categoryCode
  form.sort = node.sort ?? 0
  form.status = node.status ?? 1
  form.description = node.description ?? ''
  formError.value = ''
  drawer.value = true
}

/** 后端字段是非空约束，前端补上创建人/时间，功能才走得通。 */
function auditFields() {
  const now = new Date().toISOString().slice(0, 19).replace('T', ' ')
  const userId = Number(userStore.userInfo?.userId) || undefined
  return { createBy: userId, updateBy: userId, createTime: now, updateTime: now }
}

async function save() {
  if (saving.value) return
  const name = form.categoryName.trim()
  const code = form.categoryCode.trim()
  if (name.length < 2) {
    formError.value = '分类名称至少 2 个字。'
    return
  }
  if (!/^[A-Za-z0-9_-]+$/.test(code)) {
    formError.value = '分类编码只能是字母、数字、下划线或连字符，例如 CAM-LENS。'
    return
  }

  formError.value = ''
  saving.value = true
  const payload = {
    categoryName: name,
    categoryCode: code,
    parentId: mode.value === 'edit' ? (findNode(form.categoryId)?.parentId ?? null) : (parent.value?.categoryId ?? null),
    sort: Number(form.sort) || 0,
    status: form.status,
    description: form.description.trim() || null,
    ...auditFields(),
  }
  try {
    if (mode.value === 'edit') {
      await updateCategory(form.categoryId, payload)
      ElMessage.success('分类已更新')
    } else {
      await addCategory(payload)
      ElMessage.success('分类已创建')
    }
    drawer.value = false
    await load()
  } catch (error) {
    formError.value = humanizeError(error, { fallback: '保存失败，请重试' })
  } finally {
    saving.value = false
  }
}

function findNode(id: number, list = tree.value): CategoryNode | null {
  for (const node of list) {
    if (node.categoryId === id) return node
    const hit = node.children?.length ? findNode(id, node.children) : null
    if (hit) return hit
  }
  return null
}

async function toggleStatus(node: CategoryNode, next: number) {
  try {
    await updateCategory(node.categoryId, {
      categoryName: node.categoryName,
      categoryCode: node.categoryCode,
      parentId: node.parentId ?? null,
      sort: node.sort ?? 0,
      status: next,
      description: node.description ?? null,
      ...auditFields(),
    })
    ElMessage.success(next === 1 ? '分类已启用' : '分类已停用')
    await load()
  } catch (error) {
    listError.value = humanizeError(error, { fallback: '状态切换失败' })
  }
}

/**
 * 删除。先在本地说清楚为什么不能被删（有子分类 / 有商品占用），
 * 只有确实没人用才真的发请求；后端仍可能因为并发数据拒绝，那时再把理由翻出来。
 */
async function remove(node: CategoryNode) {
  const children = childCount(node)
  const used = countOf(node)
  if (children > 0) {
    listError.value = `「${node.categoryName}」下面还有 ${children} 个子分类，先把子分类删掉或移走。`
    return
  }
  if (used > 0) {
    listError.value = `「${node.categoryName}」被 ${used} 件商品占用，无法删除。请先把这些商品改到其它分类。`
    return
  }
  try {
    await ElMessageBox.confirm(
      `删除「${node.categoryName}」（${node.categoryCode}）后无法恢复。当前没有子分类，也没有商品占用。`,
      '删除分类',
      { confirmButtonText: '删除', cancelButtonText: '取消' },
    )
  } catch {
    return
  }
  try {
    await deleteCategory(node.categoryId)
    ElMessage.success('分类已删除')
    listError.value = ''
    await load()
  } catch (error) {
    listError.value = humanizeError(error, {
      occupiedBy: '分类',
      fallback: '删除失败，请重试',
    })
  }
}

function toggleExpand() {
  expandAll.value = !expandAll.value
  // 重建树让 default-expand-all 重新生效。
  treeKey.value += 1
}

onMounted(() => {
  void load()
})
</script>

<template>
  <div class="category" data-density="admin">
    <SectionHead
      title="分类管理"
      note="商品只能挂在叶子分类上。排序值越小越靠前，编码会拼进商品的分类路径。"
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
      <el-button type="primary" @click="openCreate(null)">
        <AppIcon name="plus" size="14" />
        新增顶级分类
      </el-button>
      <el-button @click="toggleExpand">{{ expandAll ? '全部收起' : '全部展开' }}</el-button>
      <span class="toolbar__count">当前最深 {{ maxLevel }} 级，最多 3 级</span>
    </div>

    <p v-if="failed" class="band band--error">
      <AppIcon name="warning" size="15" />
      <span>分类树没能加载。请确认后端服务在运行，然后重试。</span>
      <button class="band__action" type="button" @click="load">重试</button>
    </p>

    <p v-if="listError" class="band band--notice">
      <AppIcon name="warning" size="15" />
      <span>{{ listError }}</span>
      <button class="band__action" type="button" @click="listError = ''">知道了</button>
    </p>

    <section class="plate">
      <div v-if="loading" class="loading-list">
        <span v-for="n in 6" :key="n" class="skeleton loading-list__row" />
      </div>

      <EmptyState
        v-else-if="tree.length === 0"
        title="还没有任何分类"
        note="先建一级分类（相机、镜头、无人机），再在下面建子分类。"
      >
        <el-button type="primary" @click="openCreate(null)">新增顶级分类</el-button>
      </EmptyState>

      <el-tree
        v-else
        :key="treeKey"
        class="tree"
        :data="tree"
        node-key="categoryId"
        :props="{ children: 'children', label: 'categoryName' }"
        :default-expand-all="expandAll"
        :expand-on-click-node="false"
      >
        <template #default="{ data }">
          <div class="node">
            <span class="node__name">{{ data.categoryName }}</span>
            <span class="node__code mono">{{ data.categoryCode }}</span>
            <span class="node__stat">排序 {{ data.sort }}</span>
            <span class="node__stat">商品 {{ countOf(data) }}</span>
            <span class="node__stat">子分类 {{ childCount(data) }}</span>
            <StatePill
              :label="data.status === 1 ? '启用' : '停用'"
              :tone="data.status === 1 ? 'teal' : 'outline'"
            />

            <span class="node__actions">
              <button class="node__action" type="button" @click.stop="openEdit(data)">编辑</button>
              <button
                class="node__action"
                type="button"
                :disabled="!canAddChild(data)"
                :title="canAddChild(data) ? '' : '分类最多三层'"
                @click.stop="openCreate(data)"
              >
                加子分类
              </button>
              <button
                class="node__action"
                type="button"
                @click.stop="toggleStatus(data, data.status === 1 ? 0 : 1)"
              >
                {{ data.status === 1 ? '停用' : '启用' }}
              </button>
              <button class="node__action node__action--danger" type="button" @click.stop="remove(data)">
                删除
              </button>
            </span>
          </div>
        </template>
      </el-tree>
    </section>

    <el-drawer v-model="drawer" :title="drawerTitle" size="420px" direction="rtl">
      <div class="form">
        <label class="field">
          <span class="field__label">分类名称</span>
          <el-input v-model="form.categoryName" placeholder="例如 微单相机" />
        </label>
        <label class="field">
          <span class="field__label">分类编码</span>
          <el-input v-model="form.categoryCode" placeholder="例如 MCAM，用于商品分类路径" />
        </label>
        <label class="field">
          <span class="field__label">排序值</span>
          <el-input-number v-model="form.sort" :min="0" :max="999" controls-position="right" />
          <span class="field__hint">数字越小越靠前，同层内比较。</span>
        </label>
        <label class="field">
          <span class="field__label">状态</span>
          <el-select v-model="form.status" style="width: 100%">
            <el-option label="启用（前端可见、可挂商品）" :value="1" />
            <el-option label="停用（前端隐藏、不可挂商品）" :value="0" />
          </el-select>
        </label>
        <label class="field">
          <span class="field__label">描述</span>
          <el-input
            v-model="form.description"
            type="textarea"
            :rows="3"
            placeholder="说明这个分类涵盖哪些器材，可留空"
          />
        </label>

        <p v-if="formError" class="form__error">
          <AppIcon name="warning" size="14" />
          <span>{{ formError }}</span>
        </p>
      </div>

      <template #footer>
        <div class="form__actions">
          <el-button @click="drawer = false">取消</el-button>
          <el-button type="primary" :loading="saving" @click="save">
            {{ mode === 'edit' ? '保存' : '创建' }}
          </el-button>
        </div>
      </template>
    </el-drawer>
  </div>
</template>

<style scoped>
.category {
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

.toolbar__count {
  margin-left: auto;
  font-size: var(--text-xs);
  color: var(--ink-3);
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

.band--notice {
  background: var(--signal-amber-wash);
  border-color: var(--signal-amber);
  color: var(--signal-amber-deep);
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
  height: calc(34px * var(--dense));
}

.tree {
  padding: var(--space-2) var(--space-3) var(--space-3);
  background: transparent;
}

.tree :deep(.el-tree-node__content) {
  height: auto;
  min-height: var(--row-h);
}

.node {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  width: 100%;
  padding: var(--space-1) 0;
  font-size: var(--text-sm);
}

.node__name {
  font-weight: 600;
  color: var(--ink-0);
}

.node__code {
  color: var(--ink-3);
  font-size: var(--text-xs);
}

.node__stat {
  color: var(--ink-3);
  font-size: var(--text-xs);
  font-variant-numeric: tabular-nums;
}

.node__actions {
  display: flex;
  gap: var(--space-1);
  margin-left: auto;
  opacity: 0;
  transition: opacity var(--dur-state) ease;
}

.tree :deep(.el-tree-node__content):hover .node__actions,
.node:focus-within .node__actions {
  opacity: 1;
}

.node__action {
  padding: 2px 8px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  color: var(--ink-2);
  font-size: var(--text-xs);
  cursor: pointer;
}

.node__action:hover:not(:disabled) {
  border-color: var(--ink-3);
  color: var(--ink-0);
}

.node__action:disabled {
  color: var(--ink-4);
  cursor: not-allowed;
}

.node__action--danger:hover:not(:disabled) {
  border-color: var(--signal-vermilion);
  color: var(--signal-vermilion-deep);
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

.field__hint {
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

@media (max-width: 900px) {
  .node__actions {
    opacity: 1;
  }
}

@media (max-width: 767px) {
  .node {
    flex-wrap: wrap;
    gap: var(--space-2);
  }

  .node__actions {
    margin-left: 0;
    width: 100%;
  }
}
</style>
