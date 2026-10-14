<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { addBrand, deleteBrand, getBrandList, updateBrand, type BrandRow } from '@/api/admin/brand'
import { getProductList } from '@/api/admin/product'
import { humanizeError } from '@/api/admin/http'
import { formatDateTime } from '@/utils/format'

/**
 * 品牌管理。
 *
 * 品牌表是一张平表（parent_id 指向父品牌），页面上按树展示：大类 → 品牌。
 * 与分类管理同样的两件事：说清每个品牌被多少商品使用、把删除被拒绝的真实理由翻成人话。
 *
 * 与后端的对不上的地方：
 *   1. 品牌没有 logo 列，也没有任何图片字段，所以这一页不提供 logo 上传；
 *   2. 新增时后端强制重算 sort（顶级 0、子品牌取父品牌 +1），因此新建表单不承诺排序值；
 *   3. 停用父品牌会级联把子品牌一起停用（后端 updateBrand 的行为），操作前要说明。
 */

const loading = ref(true)
const failed = ref(false)
const brands = ref<BrandRow[]>([])
const productCount = ref<Record<number, number>>({})
const expandAll = ref(true)
const tableKey = ref(0)
const listError = ref('')

const drawer = ref(false)
const mode = ref<'create' | 'edit'>('create')
const parent = ref<BrandRow | null>(null)
const saving = ref(false)
const formError = ref('')

const form = reactive({
  brandId: 0,
  brandName: '',
  categoryCode: '',
  sort: 0,
  status: 1,
  description: '',
  parentId: null as number | null,
})

const drawerTitle = computed(() => {
  if (mode.value === 'edit') return `编辑品牌 · ${form.brandName}`
  return parent.value ? `在「${parent.value.brandName}」下新增子品牌` : '新增品牌大类'
})

const tree = computed(() => {
  const map = new Map<number, BrandRow & { children?: BrandRow[] }>()
  for (const row of brands.value) map.set(row.brandId, { ...row, children: [] })
  const roots: (BrandRow & { children?: BrandRow[] })[] = []
  for (const row of brands.value) {
    const node = map.get(row.brandId)
    if (!node) continue
    if (row.parentId === null || row.parentId === undefined || row.parentId === 0) {
      roots.push(node)
    } else {
      const owner = map.get(row.parentId)
      if (owner) owner.children?.push(node)
      else roots.push(node)
    }
  }
  const sortTree = (list: (BrandRow & { children?: BrandRow[] })[]) => {
    list.sort((a, b) => (a.sort ?? 0) - (b.sort ?? 0) || a.brandId - b.brandId)
    for (const node of list) if (node.children?.length) sortTree(node.children)
  }
  sortTree(roots)
  return roots
})

function countOf(row: BrandRow) {
  return productCount.value[row.brandId] ?? 0
}

async function load() {
  loading.value = true
  failed.value = false
  listError.value = ''
  try {
    const [list, products] = await Promise.all([
      getBrandList(),
      getProductList({ pageNum: 1, pageSize: 200 }),
    ])
    brands.value = list ?? []
    if ((products.total ?? 0) > (products.records?.length ?? 0)) {
      listError.value = `商品共 ${products.total} 件，这里只统计了最近 ${products.records.length} 件的占用情况。`
    }
    const counts: Record<number, number> = {}
    for (const item of products.records ?? []) {
      if (item.brand === null || item.brand === undefined) continue
      counts[item.brand] = (counts[item.brand] ?? 0) + 1
    }
    productCount.value = counts
  } catch {
    failed.value = true
    brands.value = []
    productCount.value = {}
  } finally {
    loading.value = false
  }
}

function openCreate(parentRow: BrandRow | null) {
  mode.value = 'create'
  parent.value = parentRow
  form.brandId = 0
  form.brandName = ''
  form.categoryCode = parentRow?.categoryCode ?? ''
  form.sort = 0
  form.status = 1
  form.description = ''
  form.parentId = parentRow?.brandId ?? null
  formError.value = ''
  drawer.value = true
}

function openEdit(row: BrandRow) {
  mode.value = 'edit'
  parent.value = null
  form.brandId = row.brandId
  form.brandName = row.brandName
  form.categoryCode = row.categoryCode
  form.sort = row.sort ?? 0
  form.status = row.status ?? 1
  form.description = row.description ?? ''
  form.parentId = row.parentId ?? null
  formError.value = ''
  drawer.value = true
}

async function save() {
  if (saving.value) return
  const name = form.brandName.trim()
  const code = form.categoryCode.trim().toUpperCase()
  if (name.length < 1) {
    formError.value = '请填写品牌名称。'
    return
  }
  if (!/^[A-Z0-9_-]+$/.test(code)) {
    formError.value = '编码只能是大写字母、数字、下划线或连字符，例如 NIKON。'
    return
  }
  formError.value = ''
  saving.value = true
  const payload = {
    brandName: name,
    categoryCode: code,
    parentId: mode.value === 'edit' ? form.parentId : (parent.value?.brandId ?? null),
    // 新建时后端会重算排序，这里传什么都没有意义，统一给 0。
    sort: mode.value === 'edit' ? Number(form.sort) || 0 : 0,
    status: form.status,
    description: form.description.trim() || null,
  }
  try {
    if (mode.value === 'edit') {
      await updateBrand(form.brandId, payload)
      ElMessage.success(
        form.status === 0 ? '品牌已保存，子品牌已同步停用' : '品牌已保存',
      )
    } else {
      await addBrand(payload)
      ElMessage.success('品牌已创建')
    }
    drawer.value = false
    await load()
  } catch (error) {
    formError.value = humanizeError(error, { fallback: '保存失败，请重试' })
  } finally {
    saving.value = false
  }
}

async function toggleStatus(row: BrandRow, next: number) {
  const hasChildren = brands.value.some((item) => item.parentId === row.brandId)
  try {
    await ElMessageBox.confirm(
      next === 0
        ? `停用「${row.brandName}」后，它不会再出现在商家选品牌的列表里。${
            hasChildren ? '它下面的子品牌也会一起停用。' : ''
          }`
        : `启用「${row.brandName}」，商家即可再次选用。`,
      next === 0 ? '停用品牌' : '启用品牌',
      { confirmButtonText: next === 0 ? '停用' : '启用', cancelButtonText: '取消' },
    )
  } catch {
    return
  }
  try {
    await updateBrand(row.brandId, {
      brandName: row.brandName,
      categoryCode: row.categoryCode,
      parentId: row.parentId ?? null,
      sort: row.sort ?? 0,
      status: next,
      description: row.description ?? null,
    })
    ElMessage.success(next === 0 ? '品牌已停用' : '品牌已启用')
    await load()
  } catch (error) {
    listError.value = humanizeError(error, { fallback: '状态切换失败' })
  }
}

async function remove(row: BrandRow) {
  const used = countOf(row)
  const hasChildren = brands.value.some((item) => item.parentId === row.brandId)
  if (hasChildren) {
    listError.value = `「${row.brandName}」下面还有子品牌，先把它们删掉或移走。`
    return
  }
  if (used > 0) {
    listError.value = `「${row.brandName}」被 ${used} 件商品占用，无法删除。请先把这些商品改到其它品牌。`
    return
  }
  try {
    await ElMessageBox.confirm(
      `删除「${row.brandName}」（${row.categoryCode}）后无法恢复。当前没有子品牌，也没有商品占用。`,
      '删除品牌',
      { confirmButtonText: '删除', cancelButtonText: '取消' },
    )
  } catch {
    return
  }
  try {
    await deleteBrand(row.brandId)
    ElMessage.success('品牌已删除')
    listError.value = ''
    await load()
  } catch (error) {
    listError.value = humanizeError(error, {
      occupiedBy: '品牌',
      fallback: '删除失败，请重试',
    })
  }
}

function toggleExpand() {
  expandAll.value = !expandAll.value
  tableKey.value += 1
}

onMounted(() => {
  void load()
})
</script>

<template>
  <div class="brands" data-density="admin">
    <SectionHead
      title="品牌管理"
      note="大类下面挂品牌（相机 → 尼康、索尼）。商品只能选择启用中的品牌。"
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
        新增品牌大类
      </el-button>
      <el-button @click="toggleExpand">{{ expandAll ? '全部收起' : '全部展开' }}</el-button>
      <span class="toolbar__count">共 {{ brands.length }} 条品牌记录</span>
    </div>

    <p v-if="failed" class="band band--error">
      <AppIcon name="warning" size="15" />
      <span>品牌列表没能加载。请确认后端服务在运行，然后重试。</span>
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
        v-else-if="brands.length === 0"
        title="还没有任何品牌"
        note="先建大类（相机、镜头、无人机），再在下面建具体品牌。"
      >
        <el-button type="primary" @click="openCreate(null)">新增品牌大类</el-button>
      </EmptyState>

      <div v-else class="table-scroll">
        <el-table
          :key="tableKey"
          :data="tree"
          row-key="brandId"
          :tree-props="{ children: 'children' }"
          :default-expand-all="expandAll"
          size="small"
          style="width: 100%"
        >
          <el-table-column label="品牌" min-width="200">
            <template #default="{ row }">
              <span class="cell-strong">{{ row.brandName }}</span>
              <span v-if="row.parentId === null || row.parentId === undefined" class="cell-sub">
                大类
              </span>
            </template>
          </el-table-column>
          <el-table-column prop="categoryCode" label="编码" width="130">
            <template #default="{ row }">
              <span class="mono">{{ row.categoryCode }}</span>
            </template>
          </el-table-column>
          <el-table-column label="排序" width="80">
            <template #default="{ row }">{{ row.sort }}</template>
          </el-table-column>
          <el-table-column label="状态" width="100">
            <template #default="{ row }">
              <StatePill
                :label="row.status === 1 ? '启用' : '停用'"
                :tone="row.status === 1 ? 'teal' : 'outline'"
              />
            </template>
          </el-table-column>
          <el-table-column label="在售/全部商品" width="140">
            <template #default="{ row }">
              <span class="mono">{{ countOf(row) }} 件</span>
            </template>
          </el-table-column>
          <el-table-column label="更新时间" min-width="150">
            <template #default="{ row }">{{ formatDateTime(row.updateTime) }}</template>
          </el-table-column>
          <el-table-column label="操作" width="300" fixed="right">
            <template #default="{ row }">
              <el-button size="small" @click="openEdit(row)">编辑</el-button>
              <el-button size="small" @click="openCreate(row)">加子品牌</el-button>
              <el-button size="small" @click="toggleStatus(row, row.status === 1 ? 0 : 1)">
                {{ row.status === 1 ? '停用' : '启用' }}
              </el-button>
              <el-button size="small" @click="remove(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </section>

    <el-drawer v-model="drawer" :title="drawerTitle" size="420px" direction="rtl">
      <div class="form">
        <label class="field">
          <span class="field__label">品牌名称</span>
          <el-input v-model="form.brandName" placeholder="例如 尼康" />
        </label>
        <label class="field">
          <span class="field__label">编码</span>
          <el-input v-model="form.categoryCode" placeholder="例如 NIKON" />
        </label>
        <label v-if="mode === 'edit'" class="field">
          <span class="field__label">排序值</span>
          <el-input-number v-model="form.sort" :min="0" :max="999" controls-position="right" />
          <span class="field__hint">数字越小越靠前。</span>
        </label>
        <label class="field">
          <span class="field__label">状态</span>
          <el-select v-model="form.status" style="width: 100%">
            <el-option label="启用（商家可选）" :value="1" />
            <el-option label="停用（商家不可选）" :value="0" />
          </el-select>
        </label>
        <label class="field">
          <span class="field__label">描述</span>
          <el-input v-model="form.description" type="textarea" :rows="3" placeholder="可留空" />
        </label>

        <p class="form__note">
          新建时排序值由后端按父级自动推算；停用父品牌会让子品牌一起停用。品牌没有 logo 字段，
          页面不提供图片上传。
        </p>

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
.brands {
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
  height: calc(36px * var(--dense));
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
