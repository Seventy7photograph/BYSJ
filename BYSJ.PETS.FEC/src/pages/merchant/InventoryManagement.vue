<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import SpecList, { type SpecEntry } from '@/components/ui/SpecList.vue'
import StatStrip, { type StatEntry } from '@/components/ui/StatStrip.vue'
import StatePill from '@/components/ui/StatePill.vue'
import {
  ADJUST_REASONS,
  ADJUST_TYPES,
  adjustInventory,
  getInventoryHistory,
  getInventoryList,
  importInventory,
  setMinStock,
  type AdjustType,
  type InventoryHistoryItem,
  type InventoryItem,
} from '@/api/merchant/inventory'
import { labelOf, PRODUCT_TYPE } from '@/constants/domain'
import { formatDateTime, formatRelative } from '@/utils/format'

/**
 * 库存管理。
 *
 * 原来这一页读的是 api/merchant/inventory.ts 里那批 mock 数组：改库存是真的，
 * 看到的数却是假的；「批量导入」点了只弹一句开发中。现在全部走真实接口，并且：
 * - 库存调整必须选一个业务原因（进货 / 销售出库 / 盘点修正 / 退货入库），
 *   它会写进 inventory_history，事后能对账；
 * - 调整后不认前端算出来的数，一律重新拉服务端结果；
 * - 安全库存单独可改（只改阈值，不动库存，也不产生变更记录）；
 * - 列表按库存风险排序：缺货、低于安全库存先被看见。
 *
 * 后端 /merchant/inventory 目前不真正分页（一次返回该商家全部命中行），
 * 因此这里按 20 条一页在客户端翻页，并说明总条数。
 */
const router = useRouter()

const PAGE_SIZE = 20
const SEARCH_DEBOUNCE = 300

const TYPE_TABS = [
  { value: '', label: '全部' },
  { value: 'new', label: '全新' },
  { value: 'used', label: '二手' },
  { value: 'rental', label: '租赁' },
] as const

const STOCK_TABS = [
  { value: '', label: '全部' },
  { value: 'out', label: '缺货' },
  { value: 'warning', label: '低于安全库存' },
  { value: 'sufficient', label: '充足' },
] as const

/** inventory.product_type 是字符串，领域字典按 1/2/3 编码，这里做一次桥接。 */
const TYPE_CODE: Record<string, number> = { new: 1, used: 2, rental: 3 }

const rows = ref<InventoryItem[]>([])
const overview = ref<InventoryItem[]>([])
const serverTotal = ref(0)
const loading = ref(true)
const error = ref('')
const keyword = ref('')
const productType = ref('')
const stockStatus = ref('')
const page = ref(1)
const importing = ref(false)
const importRef = ref<HTMLInputElement | null>(null)

/* --- 读取 ---------------------------------------------------------------- */

async function loadList() {
  loading.value = true
  error.value = ''
  try {
    const res = await getInventoryList({
      productType: productType.value,
      stockStatus: stockStatus.value,
      keyword: keyword.value.trim(),
    })
    rows.value = res.list
    serverTotal.value = res.total
  } catch (e) {
    rows.value = []
    serverTotal.value = 0
    error.value = e instanceof Error ? e.message : '库存没有加载出来'
  } finally {
    loading.value = false
  }
}

/** 顶部读数永远按「本店全部库存」算，不跟着筛选条件变。 */
async function loadOverview() {
  try {
    const res = await getInventoryList({})
    overview.value = res.list
  } catch {
    overview.value = []
  }
}

let searchTimer: ReturnType<typeof setTimeout> | undefined
watch(keyword, () => {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(() => {
    page.value = 1
    void loadList()
  }, SEARCH_DEBOUNCE)
})

watch([productType, stockStatus], () => {
  page.value = 1
  void loadList()
})

onMounted(() => {
  void loadList()
  void loadOverview()
})

/* --- 派生 ---------------------------------------------------------------- */

const stats = computed<StatEntry[]>(() => {
  const list = overview.value
  const stockSum = list.reduce((sum, item) => sum + Number(item.currentStock ?? 0), 0)
  const low = list.filter((item) => item.currentStock > 0 && item.currentStock < item.minStock).length
  const out = list.filter((item) => item.currentStock <= 0).length
  return [
    { label: '库存条目', value: list.length },
    { label: '库存总量', value: stockSum, unit: '件' },
    { label: '低于安全库存', value: low, unit: '条', tone: low > 0 ? 'amber' : 'default' },
    { label: '缺货', value: out, unit: '条', tone: out > 0 ? 'vermilion' : 'default' },
  ]
})

function riskRank(item: InventoryItem): number {
  if (item.currentStock <= 0) return 0
  if (item.currentStock < item.minStock) return 1
  return 2
}

/** 缺货和最接近断货的先排前面，再按商品 ID 稳定排序。 */
const sortedRows = computed(() =>
  [...rows.value].sort(
    (a, b) => riskRank(a) - riskRank(b) || Number(a.productId) - Number(b.productId),
  ),
)

const pagedRows = computed(() =>
  sortedRows.value.slice((page.value - 1) * PAGE_SIZE, page.value * PAGE_SIZE),
)

const filtered = computed(
  () => Boolean(keyword.value.trim()) || Boolean(productType.value) || Boolean(stockStatus.value),
)

/** 后端一次最多给 100 条，超过时明确说明，不让用户以为这就是全部。 */
const truncated = computed(() => serverTotal.value > rows.value.length)

function typeLabel(item: InventoryItem) {
  return labelOf(PRODUCT_TYPE, TYPE_CODE[item.productType] ?? 0)
}

function specText(item: InventoryItem): string {
  const attribute = String(item.skuAttribute ?? '').trim()
  const value = String(item.skuValue ?? '').trim()
  if (!attribute && !value) return '单规格'
  // 无规格商品在库里存成「默认/默认」，别把它读成两条信息。
  if (attribute === value) return attribute === '默认' ? '单规格' : attribute
  return [attribute, value].filter(Boolean).join(' · ')
}

function isOut(item: InventoryItem): boolean {
  return item.currentStock <= 0
}

function isLow(item: InventoryItem): boolean {
  return item.currentStock > 0 && item.currentStock < item.minStock
}

function resetFilters() {
  keyword.value = ''
  productType.value = ''
  stockStatus.value = ''
}

/* --- 选择与批量 ---------------------------------------------------------- */

const selectedIds = ref<number[]>([])

const allSelected = computed(
  () => pagedRows.value.length > 0 && pagedRows.value.every((item) => selectedIds.value.includes(item.id)),
)

function toggleRow(id: number) {
  const index = selectedIds.value.indexOf(id)
  if (index >= 0) selectedIds.value.splice(index, 1)
  else selectedIds.value.push(id)
}

function toggleAll() {
  const pageIds = pagedRows.value.map((item) => item.id)
  if (allSelected.value) {
    selectedIds.value = selectedIds.value.filter((id) => !pageIds.includes(id))
  } else {
    selectedIds.value = Array.from(new Set([...selectedIds.value, ...pageIds]))
  }
}

/* --- 调整库存 ------------------------------------------------------------ */

const adjustOpen = ref(false)
const adjustMode = ref<'single' | 'batch'>('single')
const adjustTarget = ref<InventoryItem | null>(null)
const adjustSubmitting = ref(false)
const adjustError = ref('')
const adjustForm = ref({
  adjustType: '增加' as AdjustType,
  adjustQuantity: 1,
  reason: '',
  minStock: 0,
})

/** 直接设置是「改成多少」，一次只能针对一条。 */
const availableAdjustTypes = computed(() =>
  adjustMode.value === 'batch' ? ADJUST_TYPES.filter((item) => item.value !== '直接设置') : ADJUST_TYPES,
)

/** 仅作提示：权威值以提交后重新拉取的服务端数据为准。 */
const adjustPreview = computed(() => {
  const target = adjustTarget.value
  if (adjustMode.value !== 'single' || !target) return ''
  const quantity = Number(adjustForm.value.adjustQuantity ?? 0)
  const next =
    adjustForm.value.adjustType === '增加'
      ? target.currentStock + quantity
      : adjustForm.value.adjustType === '减少'
        ? target.currentStock - quantity
        : quantity
  return `预计调整后 ${next} 件`
})

function openAdjust(item: InventoryItem) {
  adjustMode.value = 'single'
  adjustTarget.value = item
  adjustError.value = ''
  adjustForm.value = {
    adjustType: '增加',
    adjustQuantity: 1,
    reason: '',
    minStock: item.minStock,
  }
  adjustOpen.value = true
}

function openBatchAdjust() {
  if (selectedIds.value.length === 0) {
    ElMessage.warning('先勾选要调整的库存')
    return
  }
  adjustMode.value = 'batch'
  adjustTarget.value = null
  adjustError.value = ''
  adjustForm.value = {
    adjustType: '增加',
    adjustQuantity: 1,
    reason: '',
    minStock: 0,
  }
  adjustOpen.value = true
}

async function submitAdjust() {
  if (adjustSubmitting.value) return
  const form = adjustForm.value
  const quantity = Number(form.adjustQuantity)

  if (!form.reason) {
    adjustError.value = '请选择调整原因，它会写进库存变更记录'
    return
  }
  if (!Number.isFinite(quantity) || quantity < 0 || (form.adjustType !== '直接设置' && quantity <= 0)) {
    adjustError.value = form.adjustType === '直接设置' ? '请填写目标库存（不小于 0）' : '请填写大于 0 的调整数量'
    return
  }
  if (form.adjustType === '减少' && adjustMode.value === 'single' && adjustTarget.value) {
    if (quantity > adjustTarget.value.currentStock) {
      adjustError.value = `现有库存 ${adjustTarget.value.currentStock} 件，减少数量不能超过它`
      return
    }
  }

  const targets =
    adjustMode.value === 'single'
      ? adjustTarget.value
        ? [adjustTarget.value.id]
        : []
      : [...selectedIds.value]

  if (targets.length === 0) {
    adjustError.value = '没有选中任何库存'
    return
  }

  adjustError.value = ''
  adjustSubmitting.value = true
  let done = 0
  let failed = 0
  for (const inventoryId of targets) {
    try {
      await adjustInventory({
        inventoryId,
        adjustType: form.adjustType,
        adjustQuantity: quantity,
        reason: form.reason,
        // 安全库存在单条调整里一起提交；批量时不动阈值。
        minStock: adjustMode.value === 'single' ? Number(form.minStock) : undefined,
      })
      done += 1
    } catch {
      failed += 1
    }
  }
  adjustSubmitting.value = false

  if (done > 0) {
    ElMessage.success(
      failed === 0 ? `已调整 ${done} 条库存，列表已刷新` : `${done} 条调整成功，${failed} 条失败`,
    )
    adjustOpen.value = false
    selectedIds.value = []
    await Promise.all([loadList(), loadOverview()])
    if (historyOpen.value && historyTarget.value) {
      await loadHistory(historyTarget.value.id, 1)
    }
  } else {
    adjustError.value = '调整没有成功，请检查网络或稍后重试'
  }
}

/* --- 安全库存 ------------------------------------------------------------ */

const minStockOpen = ref(false)
const minStockTarget = ref<InventoryItem | null>(null)
const minStockValue = ref(0)
const minStockSubmitting = ref(false)

function openMinStock(item: InventoryItem) {
  minStockTarget.value = item
  minStockValue.value = item.minStock
  minStockOpen.value = true
}

async function submitMinStock() {
  const target = minStockTarget.value
  if (!target || minStockSubmitting.value) return
  const value = Number(minStockValue.value)
  if (!Number.isFinite(value) || value < 0) {
    ElMessage.warning('安全库存不能小于 0')
    return
  }
  minStockSubmitting.value = true
  try {
    await setMinStock(target.id, value)
    ElMessage.success('安全库存已更新')
    minStockOpen.value = false
    await Promise.all([loadList(), loadOverview()])
  } finally {
    minStockSubmitting.value = false
  }
}

/* --- 变更记录 ------------------------------------------------------------ */

const historyOpen = ref(false)
const historyTarget = ref<InventoryItem | null>(null)
const historyRows = ref<InventoryHistoryItem[]>([])
const historyTotal = ref(0)
const historyPage = ref(1)
const historyLoading = ref(false)
const historyError = ref('')

const HISTORY_PAGE_SIZE = 20

async function loadHistory(inventoryId: number, pageNum: number) {
  historyLoading.value = true
  historyError.value = ''
  try {
    const res = await getInventoryHistory({ inventoryId, page: pageNum, pageSize: HISTORY_PAGE_SIZE })
    historyRows.value = res.list
    historyTotal.value = res.total
    historyPage.value = pageNum
  } catch (e) {
    historyRows.value = []
    historyTotal.value = 0
    historyError.value = e instanceof Error ? e.message : '变更记录没有加载出来'
  } finally {
    historyLoading.value = false
  }
}

function openHistory(item: InventoryItem) {
  historyTarget.value = item
  historyOpen.value = true
  void loadHistory(item.id, 1)
}

const historyFacts = computed<SpecEntry[]>(() => {
  const item = historyTarget.value
  if (!item) return []
  return [
    { key: '商品ID', value: item.productId, mono: true },
    { key: '规格ID', value: item.skuId, mono: true },
    { key: '规格', value: specText(item) },
    { key: '当前库存', value: `${item.currentStock} 件` },
    { key: '安全库存', value: `${item.minStock} 件` },
    { key: '累计销量', value: `${item.sales} 件` },
    { key: '创建时间', value: formatDateTime(item.createTime) },
    { key: '最近变更', value: formatDateTime(item.lastUpdateTime) },
  ]
})

function changeSummary(row: InventoryHistoryItem): string {
  if (row.changeType === '直接设置') return `${row.beforeStock} → ${row.afterStock}`
  const delta = Number(row.afterStock) - Number(row.beforeStock)
  const sign = delta > 0 ? '+' : ''
  return `${row.beforeStock} → ${row.afterStock}（${sign}${delta}）`
}

/* --- 导入与导出 ---------------------------------------------------------- */

function saveCsv(content: string, filename: string) {
  const blob = new Blob([`\ufeff${content}`], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
}

const IMPORT_HEADERS = ['商品ID', '规格ID', '调整数量', '安全库存', '原因']

function downloadTemplate() {
  const rowsCsv = [IMPORT_HEADERS.join(','), ['1', '1', '10', '11', '进货'].join(',')]
  saveCsv(rowsCsv.join('\n'), '库存导入模板.csv')
}

function openImport() {
  if (importing.value) return
  importRef.value?.click()
}

async function onImportChange(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  input.value = ''
  if (!file) return
  importing.value = true
  try {
    const { message } = await importInventory(file)
    // 服务端把结果说明放在 msg 里；还没上线的功能也会在这里如实说出来。
    if (/未实现|暂未/.test(message)) ElMessage.info(message)
    else ElMessage.success(message)
    await Promise.all([loadList(), loadOverview()])
  } catch (e) {
    ElMessage.error(e instanceof Error ? e.message : '导入失败')
  } finally {
    importing.value = false
  }
}

function exportCsv() {
  if (rows.value.length === 0) {
    ElMessage.warning('当前没有可导出的库存记录')
    return
  }
  const header = ['商品ID', '商品名称', '商品类型', '规格', '当前库存', '安全库存', '销量', '最近变更']
  const body = rows.value.map((item) => [
    item.productId,
    item.productName,
    typeLabel(item).label,
    specText(item),
    item.currentStock,
    item.minStock,
    item.sales,
    formatDateTime(item.lastUpdateTime),
  ])
  const csv = [header, ...body].map((line) => line.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(','))
  saveCsv(csv.join('\n'), `库存列表_${new Date().toISOString().slice(0, 10)}.csv`)
}

function openProduct(item: InventoryItem) {
  void router.push({ path: `/merchant/product-edit/${item.productId}`, query: { type: item.productType } })
}
</script>

<template>
  <div class="page">
    <SectionHead title="库存管理" :note="`共 ${serverTotal} 条库存记录，按库存风险排序`" size="lg">
      <template #action>
        <div class="head-actions">
          <button class="btn" type="button" @click="downloadTemplate">下载模板</button>
          <button class="btn" type="button" :disabled="importing" @click="openImport">
            <AppIcon name="upload" size="14" />
            {{ importing ? '导入中…' : '导入库存' }}
          </button>
          <button class="btn" type="button" @click="exportCsv">
            <AppIcon name="download" size="14" />
            导出
          </button>
        </div>
      </template>
    </SectionHead>

    <input
      ref="importRef"
      class="sr-only"
      type="file"
      accept=".csv,.xlsx,.xls"
      @change="onImportChange"
    />

    <StatStrip :entries="stats" :loading="loading" />

    <div class="filters">
      <div class="seg" role="tablist" aria-label="商品类型">
        <button
          v-for="tab in TYPE_TABS"
          :key="tab.value || 'all'"
          class="seg__item"
          :class="{ 'is-active': productType === tab.value }"
          type="button"
          role="tab"
          :aria-selected="productType === tab.value"
          @click="productType = tab.value"
        >
          {{ tab.label }}
        </button>
      </div>

      <div class="seg" role="tablist" aria-label="库存状态">
        <button
          v-for="tab in STOCK_TABS"
          :key="tab.value || 'all'"
          class="seg__item"
          :class="{ 'is-active': stockStatus === tab.value }"
          type="button"
          role="tab"
          :aria-selected="stockStatus === tab.value"
          @click="stockStatus = tab.value"
        >
          {{ tab.label }}
        </button>
      </div>

      <label class="search">
        <AppIcon name="search" size="15" />
        <input
          v-model="keyword"
          class="search__input"
          type="search"
          placeholder="商品名称"
          aria-label="按商品名称搜索库存"
        />
      </label>
    </div>

    <div class="bulk">
      <p class="bulk__count">
        {{ selectedIds.length ? `已选 ${selectedIds.length} 条` : `本页 ${pagedRows.length} 条` }}
      </p>
      <button
        v-if="selectedIds.length"
        class="btn btn--solid"
        type="button"
        :disabled="adjustSubmitting"
        @click="openBatchAdjust"
      >
        批量调整
      </button>
      <button v-if="selectedIds.length" class="btn btn--ghost" type="button" @click="selectedIds = []">
        取消选择
      </button>
      <span v-if="importing" class="bulk__note">正在导入，请稍候…</span>
    </div>

    <p v-if="truncated" class="note">
      本次只取了前 {{ rows.length }} 条（共 {{ serverTotal }} 条），请用搜索或筛选缩小范围。
    </p>

    <!-- 加载 -->
    <div v-if="loading" class="plate" aria-busy="true">
      <div v-for="n in 6" :key="n" class="ghost-row">
        <span class="ghost ghost--lg skeleton" />
        <span class="ghost ghost--sm skeleton" />
        <span class="ghost ghost--sm skeleton" />
      </div>
    </div>

    <!-- 错误 -->
    <EmptyState v-else-if="error" title="库存列表加载失败" :note="error">
      <button class="btn" type="button" @click="loadList">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
    </EmptyState>

    <!-- 空 -->
    <EmptyState
      v-else-if="sortedRows.length === 0"
      :title="filtered ? '没有符合条件的库存' : '还没有库存记录'"
      :note="
        filtered
          ? '换一个类型或库存状态，或清空搜索词。'
          : '商品发布并上架后，这里会为每个规格建立库存记录。'
      "
    >
      <button v-if="filtered" class="btn" type="button" @click="resetFilters">查看全部库存</button>
      <RouterLink v-else class="btn" to="/merchant-dashboard/product-management?type=new">去商品管理</RouterLink>
    </EmptyState>

    <!-- 列表 -->
    <div v-else class="plate table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th class="col-check">
              <input
                type="checkbox"
                :checked="allSelected"
                aria-label="选中本页全部库存"
                @change="toggleAll"
              />
            </th>
            <th>商品</th>
            <th>类型</th>
            <th>规格</th>
            <th class="num">当前库存</th>
            <th class="num">安全库存</th>
            <th class="num">销量</th>
            <th>最近变更</th>
            <th class="col-action">操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in pagedRows" :key="item.id" :class="{ 'is-alert': isOut(item) || isLow(item) }">
            <td class="col-check">
              <input
                type="checkbox"
                :checked="selectedIds.includes(item.id)"
                :aria-label="`选中 ${item.productName}`"
                @change="toggleRow(item.id)"
              />
            </td>
            <td>
              <button class="link" type="button" @click="openProduct(item)">{{ item.productName }}</button>
              <span class="sub mono">#{{ item.productId }}</span>
            </td>
            <td>
              <StatePill :label="typeLabel(item).label" :tone="typeLabel(item).tone" />
            </td>
            <td class="sub">{{ specText(item) }}</td>
            <td class="num">
              <span class="stock tnum">{{ item.currentStock }}</span>
              <span class="unit">件</span>
              <StatePill v-if="isOut(item)" class="stock-pill" label="缺货" tone="vermilion" />
              <StatePill v-else-if="isLow(item)" class="stock-pill" label="低于安全库存" tone="amber" />
            </td>
            <td class="num tnum">{{ item.minStock }}</td>
            <td class="num tnum">{{ item.sales }}</td>
            <td class="sub" :title="formatDateTime(item.lastUpdateTime)">
              {{ formatRelative(item.lastUpdateTime) }}
            </td>
            <td class="col-action">
              <div class="row-actions">
                <button class="link" type="button" @click="openAdjust(item)">调整库存</button>
                <button class="link" type="button" @click="openMinStock(item)">安全库存</button>
                <button class="link" type="button" @click="openHistory(item)">变更记录</button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="!loading && !error && sortedRows.length > PAGE_SIZE" class="pager">
      <span class="pager__count">{{ sortedRows.length }} 条</span>
      <el-pagination
        :current-page="page"
        :page-size="PAGE_SIZE"
        :total="sortedRows.length"
        layout="prev, pager, next"
        background
        @current-change="(value: number) => (page = value)"
      />
    </div>

    <!-- 调整库存 -->
    <el-dialog
      v-model="adjustOpen"
      :title="adjustMode === 'batch' ? `批量调整 ${selectedIds.length} 条库存` : '调整库存'"
      width="480px"
    >
      <div class="form">
        <dl v-if="adjustMode === 'single' && adjustTarget" class="facts">
          <div>
            <dt>商品</dt>
            <dd>{{ adjustTarget.productName }}</dd>
          </div>
          <div>
            <dt>规格</dt>
            <dd>{{ specText(adjustTarget) }}</dd>
          </div>
          <div>
            <dt>当前库存</dt>
            <dd class="tnum">{{ adjustTarget.currentStock }} 件</dd>
          </div>
        </dl>

        <label class="field">
          <span class="field__label">调整方式</span>
          <el-radio-group v-model="adjustForm.adjustType">
            <el-radio v-for="type in availableAdjustTypes" :key="type.value" :value="type.value">
              {{ type.label }}
            </el-radio>
          </el-radio-group>
        </label>

        <label class="field">
          <span class="field__label">
            {{ adjustForm.adjustType === '直接设置' ? '目标库存' : '调整数量' }}
            <span class="field__unit">件</span>
          </span>
          <el-input-number
            v-model="adjustForm.adjustQuantity"
            :min="0"
            :step="1"
            controls-position="right"
            class="field__control"
          />
        </label>

        <label class="field">
          <span class="field__label">调整原因</span>
          <el-select v-model="adjustForm.reason" placeholder="选择这次变动的业务原因" class="field__control">
            <el-option v-for="reason in ADJUST_REASONS" :key="reason" :label="reason" :value="reason" />
          </el-select>
          <span class="field__hint">原因会写进库存变更记录，事后对账靠它。</span>
        </label>

        <label v-if="adjustMode === 'single'" class="field">
          <span class="field__label">安全库存 <span class="field__unit">件</span></span>
          <el-input-number
            v-model="adjustForm.minStock"
            :min="0"
            :step="1"
            controls-position="right"
            class="field__control"
          />
          <span class="field__hint">低于这个数量会被标成「低于安全库存」。</span>
        </label>

        <p v-if="adjustPreview" class="preview">{{ adjustPreview }}（以提交后服务端返回为准）</p>
        <p v-if="adjustError" class="field__error">{{ adjustError }}</p>
      </div>
      <template #footer>
        <div class="dialog-foot">
          <button class="btn btn--ghost" type="button" @click="adjustOpen = false">取消</button>
          <button class="btn btn--solid" type="button" :disabled="adjustSubmitting" @click="submitAdjust">
            {{ adjustSubmitting ? '提交中…' : '确认调整' }}
          </button>
        </div>
      </template>
    </el-dialog>

    <!-- 安全库存 -->
    <el-dialog v-model="minStockOpen" title="设置安全库存" width="420px">
      <div v-if="minStockTarget" class="form">
        <dl class="facts">
          <div>
            <dt>商品</dt>
            <dd>{{ minStockTarget.productName }}</dd>
          </div>
          <div>
            <dt>当前库存</dt>
            <dd class="tnum">{{ minStockTarget.currentStock }} 件</dd>
          </div>
        </dl>
        <label class="field">
          <span class="field__label">安全库存 <span class="field__unit">件</span></span>
          <el-input-number
            v-model="minStockValue"
            :min="0"
            :step="1"
            controls-position="right"
            class="field__control"
          />
        </label>
        <p class="field__hint">只改阈值，不动当前库存，也不会产生变更记录。</p>
      </div>
      <template #footer>
        <div class="dialog-foot">
          <button class="btn btn--ghost" type="button" @click="minStockOpen = false">取消</button>
          <button class="btn btn--solid" type="button" :disabled="minStockSubmitting" @click="submitMinStock">
            保存
          </button>
        </div>
      </template>
    </el-dialog>

    <!-- 变更记录 -->
    <el-drawer
      v-model="historyOpen"
      :title="historyTarget ? `${historyTarget.productName} · 库存变更记录` : '库存变更记录'"
      size="min(560px, 94vw)"
    >
      <div v-if="historyTarget" class="history">
        <SpecList :entries="historyFacts" :columns="2" />

        <div v-if="historyLoading" class="history__loading" aria-busy="true">
          <span v-for="n in 4" :key="n" class="ghost ghost--line skeleton" />
        </div>

        <EmptyState v-else-if="historyError" title="变更记录加载失败" :note="historyError">
          <button class="btn" type="button" @click="loadHistory(historyTarget.id, historyPage)">
            <AppIcon name="refresh" size="14" />
            重新加载
          </button>
        </EmptyState>

        <EmptyState
          v-else-if="historyRows.length === 0"
          title="还没有变更记录"
          note="这个规格的库存从建立到现在没有被调整过。"
        />

        <ol v-else class="changes">
          <li v-for="row in historyRows" :key="row.id" class="change">
            <div class="change__head">
              <StatePill :label="row.changeType" :tone="row.changeType === '增加' ? 'teal' : row.changeType === '减少' ? 'vermilion' : 'neutral'" />
              <time class="change__time" :title="formatDateTime(row.changeTime)">
                {{ formatRelative(row.changeTime) }}
              </time>
            </div>
            <p class="change__stock tnum">{{ changeSummary(row) }} 件</p>
            <p class="change__meta">
              <span>{{ row.reason || '未填写原因' }}</span>
              <span class="change__dot">·</span>
              <span>{{ row.operator || '系统' }}</span>
            </p>
          </li>
        </ol>

        <div v-if="historyTotal > HISTORY_PAGE_SIZE" class="pager">
          <el-pagination
            :current-page="historyPage"
            :page-size="HISTORY_PAGE_SIZE"
            :total="historyTotal"
            layout="prev, pager, next"
            background
            @current-change="(value: number) => historyTarget && loadHistory(historyTarget.id, value)"
          />
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<style scoped>
.page {
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
  margin-left: auto;
  width: 240px;
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

.note {
  margin-bottom: var(--space-3);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

/* --- 表格 ---------------------------------------------------------------- */

.table-wrap {
  overflow-x: auto;
}

.table {
  width: 100%;
  min-width: 940px;
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

.table .num {
  text-align: right;
  white-space: nowrap;
}

.table td.num {
  font-variant-numeric: tabular-nums;
}

.col-check {
  width: 40px;
  padding-right: 0 !important;
}

.col-action {
  width: 240px;
}

.sub {
  color: var(--ink-3);
  font-size: var(--text-xs);
}

.stock {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--ink-0);
}

.is-alert .stock {
  color: var(--signal-vermilion-deep);
}

.unit {
  margin-left: 2px;
  font-size: var(--text-2xs);
  color: var(--ink-3);
}

.stock-pill {
  margin-left: var(--space-2);
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

.pager {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  margin-top: var(--space-4);
}

.pager__count {
  font-size: var(--text-sm);
  color: var(--ink-3);
}

/* --- 表单 ---------------------------------------------------------------- */

.form {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.facts {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--space-3);
  margin: 0;
  padding: var(--space-3);
  background: var(--paper-1);
  border-radius: var(--radius-sm);
}

.facts dt {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.facts dd {
  margin: 2px 0 0;
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-1);
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field__label {
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.field__unit {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.field__control {
  width: 100%;
}

.field__hint {
  font-size: var(--text-xs);
  color: var(--ink-4);
}

.field__error {
  font-size: var(--text-xs);
  color: var(--signal-vermilion-deep);
}

.preview {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.dialog-foot {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}

/* --- 变更记录 ------------------------------------------------------------ */

.history {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.history__loading {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.changes {
  display: flex;
  flex-direction: column;
  margin: 0;
  padding: 0;
  list-style: none;
  border-top: var(--hairline);
}

.change {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: var(--space-3) 0;
  border-bottom: var(--hairline);
}

.change__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
}

.change__time {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.change__stock {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--ink-0);
}

.change__meta {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.change__dot {
  color: var(--ink-4);
}

/* --- 骨架与通用控件 ------------------------------------------------------ */

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

.ghost--line {
  width: 100%;
  height: 15px;
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
  background: var(--ink-1);
  border-color: var(--ink-1);
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
  .col-action {
    width: 180px;
  }
}

@media (max-width: 520px) {
  .facts {
    grid-template-columns: minmax(0, 1fr);
  }
  .bulk {
    flex-wrap: wrap;
  }
}
</style>
