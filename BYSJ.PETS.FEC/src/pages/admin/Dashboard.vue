<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import PriceTag from '@/components/ui/PriceTag.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import StatStrip, { type StatEntry } from '@/components/ui/StatStrip.vue'
import { getAdminDashboardData, type AdminDashboardData } from '@/api/admin/dashboard'
import { getMerchantAuditList } from '@/api/admin/merchant'
import { getBrandList } from '@/api/admin/brand'
import { getProductAuditList, getProductList, type AuditProductRow } from '@/api/admin/product'
import { listOperations, type OperationRow } from '@/api/admin/operations'
import type { AdminUser } from '@/api/admin/http'
import { PRODUCT_TYPE, labelOf } from '@/constants/domain'
import { formatDateTime, formatRelative, maskPhone } from '@/utils/format'

/**
 * 管理员待办总览。
 *
 * 这不是数据大屏：管理员每天做的事是"把队列清空"，所以第一屏是两条待办队列
 * （待审商家、待审商品），点进去就能处理；读数只保留能立刻支撑决定的四个。
 *
 * 被删掉的是原来那六张 ECharts 图和七张"大数字卡片"。其中"器材分类分布"和
 * "热门器材排行"的数字来自后端写死的假数据（AdminServiceImpl 里注释着
 * "模拟数据"），"较上月 +12.5%" 这类趋势也是编的——没有数据支撑的读数比没有读数更糟。
 * 真实存在的趋势（近 7 天新增用户/订单）保留下来，用一排细柱表示，不再引图表库。
 */

const router = useRouter()
const route = useRoute()

/** 页面挂在哪套外壳下，链接就指回哪套。 */
const prefix = computed(() =>
  route.path.startsWith('/super-admin-dashboard') ? '/super-admin-dashboard' : '/admin-dashboard',
)

/** 已过审且上架——买家真正能看到的商品。 */
interface CatalogRow {
  productId: number
  brand: number | null
  model: string
  productType: number
  stock: number | null
  minStock: number | null
  auditStatus: number
  isOnShelf: number | null
  price: number | null
}

const loading = ref(true)
const failed = ref(false)
const dashboard = ref<AdminDashboardData | null>(null)
const merchantQueue = ref<AdminUser[]>([])
const productQueue = ref<AuditProductRow[]>([])
const catalog = ref<{ items: CatalogRow[]; total: number }>({ items: [], total: 0 })
const brandNames = ref<Record<number, string>>({})

/** 操作日志（对话框里的完整列表）。 */
const opDialog = ref(false)
const opLoading = ref(false)
const opRows = ref<OperationRow[]>([])
const opTotal = ref(0)
const opPage = ref(1)
const opSize = ref(10)
const opKeyword = ref('')

const statEntries = computed<StatEntry[]>(() => {
  const merchantPending = merchantQueue.value.length
  const productPending = dashboard.value?.pendingProductsCount ?? 0
  const sellable = catalog.value.items.filter((p) => isSellable(p))
  const onShelf = sellable.length
  const alerts = sellable.filter((p) => stockState(p) !== 'ok')
  const outOfStock = alerts.filter((p) => stockState(p) === 'out').length
  const truncated = catalog.value.total > catalog.value.items.length
  const sample = truncated ? `按最近 ${catalog.value.items.length} 件统计` : '全量统计'

  return [
    {
      label: '待审核商家',
      value: merchantPending,
      unit: '家',
      tone: merchantPending > 0 ? 'amber' : 'default',
      note: merchantPending > 0 ? '资质在等一个决定' : '队列已清空',
    },
    {
      label: '待审核商品',
      value: productPending,
      unit: '件',
      tone: productPending > 0 ? 'amber' : 'default',
      note: productPending > 0 ? '未过审不会出现在商城里' : '队列已清空',
    },
    { label: '在售商品', value: onShelf, unit: '件', note: sample },
    {
      label: '库存异常',
      value: alerts.length,
      unit: '件',
      tone: alerts.length > 0 ? 'vermilion' : 'default',
      note: alerts.length > 0 ? `其中 ${outOfStock} 件已售完` : '在售商品库存均高于安全线',
    },
  ]
})

function isSellable(row: CatalogRow) {
  return row.auditStatus === 1 && row.isOnShelf === 1
}

function stockState(row: CatalogRow): 'out' | 'low' | 'ok' {
  const stock = row.stock
  if (stock === null || stock === undefined) return 'ok'
  if (stock <= 0) return 'out'
  if (row.minStock !== null && row.minStock !== undefined && stock <= row.minStock) return 'low'
  return 'ok'
}

const stockAlertRows = computed(() =>
  catalog.value.items
    .filter((p) => isSellable(p) && stockState(p) !== 'ok')
    .sort((a, b) => (a.stock ?? 0) - (b.stock ?? 0)),
)

/** 库存异常最多列 8 条，剩下的在计数里说明。 */
const stockAlerts = computed(() => stockAlertRows.value.slice(0, 8))

function brandName(id: number | null) {
  if (id === null || id === undefined) return ''
  return brandNames.value[id] ?? ''
}

/** 手机号脱敏，没有手机号就退回邮箱原文——邮箱不能拿手机号脱敏规则去截。 */
function contactOf(row: AdminUser) {
  if (row.phone) return maskPhone(row.phone)
  return row.email || '未填写联系方式'
}

/** 近 7 天两组读数，柱高按组内最大值归一。 */
function trend(dates: string[] | undefined, values: number[] | undefined) {
  if (!dates || !values || dates.length === 0) return []
  const max = Math.max(1, ...values)
  return dates.map((date, index) => ({
    date,
    value: values[index] ?? 0,
    /** 0 也留一条基线，避免那一列凭空消失。 */
    height: `${Math.max(2, Math.round(((values[index] ?? 0) / max) * 100))}%`,
  }))
}

const userTrend = computed(() => trend(dashboard.value?.userGrowthTrend?.dates, dashboard.value?.userGrowthTrend?.users))
const orderTrend = computed(() => trend(dashboard.value?.orderTrend?.dates, dashboard.value?.orderTrend?.orders))

function openMerchantAudit(id: number) {
  void router.push({ path: `${prefix.value}/merchant-audit`, query: { merchant: String(id) } })
}

function openProductAudit(id: number) {
  void router.push({
    path: `${prefix.value}/product-audit`,
    query: { status: '0', product: String(id) },
  })
}

async function load() {
  loading.value = true
  failed.value = false
  try {
    const [stats, merchants, products, catalogPage, brands] = await Promise.all([
      getAdminDashboardData(),
      getMerchantAuditList({ pageNum: 1, pageSize: 5 }),
      getProductAuditList({ pageNum: 1, pageSize: 5, auditStatus: 0 }),
      getProductList({ pageNum: 1, pageSize: 100 }),
      getBrandList(),
    ])
    dashboard.value = stats
    merchantQueue.value = merchants.records ?? []
    productQueue.value = products.records ?? []
    catalog.value = { items: catalogPage.records ?? [], total: catalogPage.total ?? 0 }
    brandNames.value = Object.fromEntries(brands.map((b) => [b.brandId, b.brandName]))
  } catch {
    failed.value = true
  } finally {
    loading.value = false
  }
}

async function loadOperations() {
  opLoading.value = true
  try {
    const page = await listOperations({
      pageNum: opPage.value,
      pageSize: opSize.value,
      keyword: opKeyword.value || undefined,
    })
    opRows.value = page.records ?? []
    opTotal.value = page.total ?? 0
  } catch {
    opRows.value = []
    opTotal.value = 0
  } finally {
    opLoading.value = false
  }
}

function openOperations() {
  opDialog.value = true
  opPage.value = 1
  opKeyword.value = ''
  void loadOperations()
}

function runOperationSearch() {
  opPage.value = 1
  void loadOperations()
}

function changeOperationSize() {
  opPage.value = 1
  void loadOperations()
}

function exportOperations() {
  const header = ['操作人', '操作', '模块', '结果', '时间']
  const rows = opRows.value.map((row) => [
    row.operator,
    row.operation,
    row.target,
    row.result,
    formatDateTime(row.operationTime),
  ])
  const csv = [header, ...rows].map((row) => row.map(csvCell).join(',')).join('\n')
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  link.href = URL.createObjectURL(blob)
  link.download = `操作记录_${new Date().toISOString().slice(0, 10)}.csv`
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
  <div class="dashboard" data-density="admin">
    <SectionHead
      title="待办总览"
      note="先看两条队列：审核通过的商家才能营业，审核通过的商品才会出现在商城里"
      size="lg"
    >
      <template #action>
        <button class="link-action" type="button" :disabled="loading" @click="load">
          <AppIcon name="refresh" size="14" />
          刷新
        </button>
      </template>
    </SectionHead>

    <StatStrip :entries="statEntries" :loading="loading" />

    <p v-if="failed" class="band band--error">
      <AppIcon name="warning" size="15" />
      <span>总览数据没能取回来。网络或后端服务异常时，队列会显示为空，别据此当成"没有待办"。</span>
      <button class="band__action" type="button" @click="load">重试</button>
    </p>

    <!-- 两条待办队列 -->
    <div class="queues">
      <section class="plate queue">
        <div class="plate__head">
          <span class="plate__title">待审核商家</span>
          <button class="link-action" type="button" @click="router.push(`${prefix}/merchant-audit`)">
            进入审核
            <AppIcon name="chevron-right" size="13" />
          </button>
        </div>

        <div v-if="loading" class="queue__body">
          <span v-for="n in 3" :key="n" class="skeleton queue__skeleton" />
        </div>
        <EmptyState
          v-else-if="merchantQueue.length === 0"
          title="没有商家在等审核"
          note="有新的店铺认证申请时会出现在这里。"
        />
        <div v-else class="queue__body">
          <button
            v-for="row in merchantQueue"
            :key="row.userId"
            class="queue__row"
            type="button"
            @click="openMerchantAudit(row.userId)"
          >
            <span class="queue__main">
              <span class="queue__title">{{ row.shopName || '未填写店铺名称' }}</span>
              <span class="queue__meta">
                {{ row.username }} · {{ contactOf(row) }} · {{ formatRelative(row.createTime) }}
              </span>
            </span>
            <StatePill label="待审核" tone="amber" />
            <AppIcon name="chevron-right" size="14" />
          </button>
        </div>
      </section>

      <section class="plate queue">
        <div class="plate__head">
          <span class="plate__title">待审核商品</span>
          <button class="link-action" type="button" @click="router.push(`${prefix}/product-audit`)">
            进入审核
            <AppIcon name="chevron-right" size="13" />
          </button>
        </div>

        <div v-if="loading" class="queue__body">
          <span v-for="n in 3" :key="n" class="skeleton queue__skeleton" />
        </div>
        <EmptyState
          v-else-if="productQueue.length === 0"
          title="没有商品在等审核"
          note="待审核的商品不会出现在商城里，队列清空说明货架已经同步。"
        />
        <div v-else class="queue__body">
          <button
            v-for="row in productQueue"
            :key="row.productId"
            class="queue__row"
            type="button"
            @click="openProductAudit(row.productId)"
          >
            <span class="queue__main">
              <span class="queue__title">
                {{ row.brandName || brandName(row.brand) }} {{ row.model }}
              </span>
              <span class="queue__meta">
                {{ labelOf(PRODUCT_TYPE, row.productType).label }} ·
                库存 {{ row.stock ?? '—' }} 件 · {{ formatRelative(row.createTime) }}
              </span>
            </span>
            <PriceTag :price="row.price" size="sm" :show-original="false" />
            <AppIcon name="chevron-right" size="14" />
          </button>
        </div>
      </section>
    </div>

    <!-- 库存异常 -->
    <section v-if="!loading && stockAlerts.length > 0" class="plate section">
      <div class="plate__head">
        <span class="plate__title">在售商品的库存问题</span>
        <span class="plate__note">
          共 {{ stockAlertRows.length }} 条，按库存从低到高列前 {{ stockAlerts.length }} 条
        </span>
      </div>
      <ul class="stock-list">
        <li v-for="row in stockAlerts" :key="row.productId" class="stock-row">
          <span class="stock-row__name">{{ brandName(row.brand) }} {{ row.model }}</span>
          <span class="stock-row__num mono">{{ row.stock ?? '—' }} 件</span>
          <span class="stock-row__line">安全库存 {{ row.minStock ?? '—' }} 件</span>
          <StatePill
            :label="stockState(row) === 'out' ? '已售完' : '低于安全库存'"
            :tone="stockState(row) === 'out' ? 'vermilion' : 'amber'"
          />
        </li>
      </ul>
      <p class="plate__foot">
        库存由商家的库存管理页维护。管理员在这里只做发现，不代商家改库存。
      </p>
    </section>

    <!-- 近 7 天 -->
    <section class="plate section">
      <div class="plate__head">
        <span class="plate__title">近 7 天新增</span>
        <span class="plate__note">按注册与下单日期统计</span>
      </div>
      <div class="trends">
        <div class="trend">
          <p class="trend__title">新增用户</p>
          <ol class="trend__bars">
            <li v-for="point in userTrend" :key="point.date" class="trend__col">
              <span class="trend__value mono">{{ point.value }}</span>
              <span class="trend__bar" :style="{ height: point.height }" />
              <span class="trend__date">{{ point.date }}</span>
            </li>
          </ol>
        </div>
        <div class="trend">
          <p class="trend__title">新增订单</p>
          <ol class="trend__bars">
            <li v-for="point in orderTrend" :key="point.date" class="trend__col">
              <span class="trend__value mono">{{ point.value }}</span>
              <span class="trend__bar" :style="{ height: point.height }" />
              <span class="trend__date">{{ point.date }}</span>
            </li>
          </ol>
        </div>
      </div>
    </section>

    <!-- 最近操作 -->
    <section class="plate section">
      <div class="plate__head">
        <span class="plate__title">最近操作</span>
        <button class="link-action" type="button" @click="openOperations">
          全部操作记录
          <AppIcon name="chevron-right" size="13" />
        </button>
      </div>
      <div class="table-scroll">
        <el-table
          :data="dashboard?.recentOperations ?? []"
          :show-header="true"
          size="small"
          style="width: 100%"
        >
          <el-table-column prop="operator" label="操作人" min-width="140" />
          <el-table-column prop="operation" label="操作" min-width="200" />
          <el-table-column prop="target" label="模块" min-width="120" />
          <el-table-column label="时间" min-width="170">
            <template #default="{ row }">{{ formatDateTime(row.operationTime) }}</template>
          </el-table-column>
        </el-table>
      </div>
      <p v-if="!loading && (dashboard?.recentOperations?.length ?? 0) === 0" class="plate__foot">
        还没有操作记录。
      </p>
    </section>

    <!-- 全部操作记录 -->
    <el-dialog v-model="opDialog" title="操作记录" width="880px">
      <div class="op-toolbar">
        <el-input
          v-model="opKeyword"
          class="op-search"
          placeholder="按操作或模块关键词搜索"
          clearable
          @keyup.enter="runOperationSearch"
        />
        <el-button @click="runOperationSearch">查询</el-button>
        <el-button :disabled="opRows.length === 0" @click="exportOperations">
          <AppIcon name="download" size="14" />
          导出当前页
        </el-button>
      </div>

      <div class="table-scroll">
        <el-table v-loading="opLoading" :data="opRows" size="small" style="width: 100%">
          <el-table-column prop="operator" label="操作人" min-width="140" />
          <el-table-column prop="operation" label="操作" min-width="200" />
          <el-table-column prop="target" label="模块" min-width="120" />
          <el-table-column prop="result" label="结果" min-width="90">
            <template #default="{ row }">
              <StatePill :label="row.result" :tone="row.result === '成功' ? 'teal' : 'vermilion'" />
            </template>
          </el-table-column>
          <el-table-column label="时间" min-width="170">
            <template #default="{ row }">{{ formatDateTime(row.operationTime) }}</template>
          </el-table-column>
        </el-table>
      </div>

      <div class="op-pager">
        <el-pagination
          v-model:current-page="opPage"
          v-model:page-size="opSize"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next"
          :total="opTotal"
          @size-change="changeOperationSize"
          @current-change="loadOperations"
        />
      </div>
    </el-dialog>
  </div>
</template>

<style scoped>
.dashboard {
  display: flex;
  flex-direction: column;
  gap: var(--gap-surface);
}

/* --- 通用小块 ------------------------------------------------------------- */

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

.plate__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.plate__foot {
  padding: var(--space-2) var(--space-4) var(--space-3);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.section {
  display: flex;
  flex-direction: column;
}

.table-scroll {
  width: 100%;
  overflow-x: auto;
}

/* --- 队列 ---------------------------------------------------------------- */

.queues {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(420px, 1fr));
  /* 两条队列各自独立，短的那条不拉伸出空白。 */
  align-items: start;
  gap: var(--gap-surface);
}

.queue {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.queue__body {
  display: flex;
  flex-direction: column;
}

.queue__skeleton {
  height: calc(42px * var(--dense));
  margin: var(--space-2) var(--space-4);
}

.queue__row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  width: 100%;
  padding: var(--space-3) var(--space-4);
  border: none;
  border-top: var(--hairline);
  background: transparent;
  text-align: left;
  cursor: pointer;
  transition: background-color var(--dur-state) ease;
}

.queue__row:first-child {
  border-top: none;
}

.queue__row:hover {
  background: var(--paper-1);
}

.queue__main {
  display: flex;
  flex-direction: column;
  gap: 1px;
  min-width: 0;
  flex: 1;
}

.queue__title {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-0);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.queue__meta {
  font-size: var(--text-xs);
  color: var(--ink-3);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* --- 库存异常 -------------------------------------------------------------- */

.stock-list {
  margin: 0;
  padding: 0;
  list-style: none;
}

.stock-row {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 88px 160px 108px;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-2) var(--space-4);
  border-top: var(--hairline);
  font-size: var(--text-sm);
}

.stock-row:first-child {
  border-top: none;
}

.stock-row__name {
  color: var(--ink-0);
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.stock-row__num {
  color: var(--ink-1);
  text-align: right;
}

.stock-row__line {
  color: var(--ink-3);
  font-size: var(--text-xs);
}

/* --- 近 7 天 -------------------------------------------------------------- */

.trends {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: var(--space-6);
  padding: var(--space-4);
}

.trend__title {
  margin-bottom: var(--space-3);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.trend__bars {
  display: grid;
  grid-template-columns: repeat(7, minmax(0, 1fr));
  gap: var(--space-2);
  align-items: end;
  margin: 0;
  padding: 0;
  list-style: none;
  height: 68px;
}

.trend__col {
  display: grid;
  grid-template-rows: auto 1fr auto;
  align-items: end;
  gap: 2px;
  height: 100%;
  text-align: center;
}

.trend__value {
  font-size: var(--text-2xs);
  color: var(--ink-2);
}

.trend__bar {
  display: block;
  width: 100%;
  background: var(--ink-3);
  border-radius: var(--radius-xs) var(--radius-xs) 0 0;
}

.trend__date {
  font-size: var(--text-2xs);
  color: var(--ink-4);
}

/* --- 操作记录对话框 --------------------------------------------------------- */

.op-toolbar {
  display: flex;
  gap: var(--space-2);
  margin-bottom: var(--space-3);
}

.op-search {
  max-width: 320px;
}

.op-pager {
  display: flex;
  justify-content: flex-end;
  margin-top: var(--space-3);
}

@media (max-width: 767px) {
  .queues {
    grid-template-columns: minmax(0, 1fr);
  }

  .stock-row {
    grid-template-columns: minmax(0, 1fr) 72px;
    row-gap: 2px;
  }

  .stock-row__line {
    grid-column: 1 / -1;
  }

  .op-toolbar {
    flex-wrap: wrap;
  }
}
</style>
