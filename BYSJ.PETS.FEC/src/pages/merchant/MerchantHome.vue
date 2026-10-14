<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from '@/axios'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import PriceTag from '@/components/ui/PriceTag.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatStrip, { type StatEntry } from '@/components/ui/StatStrip.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { labelOf, PRODUCT_TYPE, type Tone } from '@/constants/domain'
import { errorText, isAuthError } from '@/api/merchant/product'
import { formatDate, formatDateTime, formatMoney } from '@/utils/format'

/**
 * 商家首页 —— 店里干活的地方。
 *
 * 原页面是「大数字 + 环比标签 + 四张 ECharts」的仪表盘模板：数字来自接口，
 * 但环比里混着写死的 5.2% / -3.1%，访客数固定 1256，租期分布图在拿不到数据时
 * 兜底成一组假比例。商家真正要看的不是这些，而是「今天有什么要处理」。
 *
 * 现在：顶部一条读数（当日订单 / 待发货 / 库存预警 / 在售商品），主体两张
 * 可操作的清单 —— 待发货订单（能直接发货）与库存预警（能直接去补货），
 * 再加一张近 7 天的成交表。趋势用表格而不是折线图：数字对齐比形状好读。
 */

const router = useRouter()

interface TrendPoint {
  date: string
  orders: number
  revenue: number
}

interface PendingOrder {
  orderId: number
  orderNo: string
  customerName?: string | null
  totalAmount?: number | null
  orderStatus: number
  createTime?: string | null
}

interface StockAlert {
  inventoryId: number
  productId: number
  productName: string
  productType: number
  currentStock: number
  minStock: number
  lastUpdateTime?: string | null
}

/** 待发货清单一次取一屏；总数超过这个窗口时明确告知，不假装完整。 */
const ORDER_WINDOW = 50

/** inventory.product_type 存的是 'new' / 'used' / 'rental'。 */
const INVENTORY_TYPE_CODE: Record<string, number> = { new: 1, used: 2, rental: 3 }

const loading = ref(true)
const failed = ref(false)
const authFailed = ref(false)
const failureText = ref('')
const shipping = ref<number | null>(null)

/** 窄屏收掉信息量最低的两列。 */
const narrow = ref(false)
let mediaQuery: MediaQueryList | null = null
function syncNarrow(event?: MediaQueryListEvent) {
  narrow.value = event ? event.matches : (mediaQuery?.matches ?? false)
}

const summary = ref({ todayOrders: 0, todayRevenue: 0, onShelf: 0, totalOrders: 0 })
const trend = ref<TrendPoint[]>([])
const pending = ref<PendingOrder[]>([])
const pendingTotal = ref(0)
const pendingWindowFull = ref(false)
const alerts = ref<StockAlert[]>([])
const soldOut = ref(0)

const weekday = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六']
const todayText = computed(() => {
  const now = new Date()
  return `${formatDate(now)} ${weekday[now.getDay()]}`
})

const trendTotal = computed(() =>
  trend.value.reduce(
    (acc, item) => ({ orders: acc.orders + item.orders, revenue: acc.revenue + item.revenue }),
    { orders: 0, revenue: 0 },
  ),
)

const stats = computed<StatEntry[]>(() => [
  {
    label: '当日订单',
    value: summary.value.todayOrders,
    unit: '单',
    note: `成交 ${formatMoney(summary.value.todayRevenue)}`,
  },
  {
    label: '待发货',
    value: pendingTotal.value,
    unit: '单',
    tone: pendingTotal.value > 0 ? 'amber' : 'default',
    note: pendingTotal.value > 0 ? '今天需要处理' : '没有积压',
  },
  {
    label: '库存预警',
    value: alerts.value.length,
    unit: '项',
    tone: alerts.value.length > 0 ? 'vermilion' : 'default',
    note: soldOut.value > 0 ? `其中 ${soldOut.value} 项已售完` : '补货线以内',
  },
  {
    label: '在售商品',
    value: summary.value.onShelf,
    unit: '件',
    note: `累计订单 ${summary.value.totalOrders} 单`,
  },
])

function typeLabel(productType: number) {
  return labelOf(PRODUCT_TYPE, productType)
}

function stockTone(alert: StockAlert): Tone {
  return alert.currentStock <= 0 ? 'vermilion' : 'amber'
}

function stockText(alert: StockAlert) {
  if (alert.currentStock <= 0) return '已售完'
  return `仅剩 ${alert.currentStock} 件`
}

/** 后端返回的是 { dates, orders, revenue } 三条平行数组，这里合成行。 */
function readTrend(payload: any): TrendPoint[] {
  const dates: string[] = Array.isArray(payload?.dates) ? payload.dates : []
  const orders: number[] = Array.isArray(payload?.orders) ? payload.orders : []
  const revenue: number[] = Array.isArray(payload?.revenue) ? payload.revenue : []
  return dates.map((date, index) => ({
    date,
    orders: Number(orders[index] ?? 0),
    revenue: Number(revenue[index] ?? 0),
  }))
}

async function loadSummary() {
  const body = await axios.get('/merchant/shop/dashboard')
  const data = (body as any)?.data ?? body ?? {}
  const today = trend.value[trend.value.length - 1] ?? null
  summary.value = {
    todayOrders: today?.orders ?? 0,
    todayRevenue: today?.revenue ?? 0,
    onShelf: Number(data.totalProducts ?? 0),
    totalOrders: Number(data.totalOrders ?? 0),
  }
  // 首页读数里唯一用到 dashboard 的地方就是「在售商品」与「累计订单」，
  // 当日数据取自 chart-data 的最后一天，口径与下面那张表一致。
}

async function loadTrend() {
  const body = await axios.get('/merchant/shop/chart-data')
  trend.value = readTrend((body as any)?.data ?? body)
}

/** 待发货 = 已支付（order_status = 1）的订单。 */
async function loadPending() {
  const body = await axios.get('/orders/list', {
    params: { pageNum: 1, pageSize: ORDER_WINDOW },
  })
  const data = (body as any)?.data ?? body ?? {}
  const rows: PendingOrder[] = Array.isArray(data.list) ? data.list : []
  pendingWindowFull.value = Number(data.total ?? 0) > rows.length
  pending.value = rows
    .filter((row) => Number(row.orderStatus) === 1)
    .sort((a, b) => String(a.createTime ?? '').localeCompare(String(b.createTime ?? '')))
  pendingTotal.value = pending.value.length
}

/** 库存预警 = 低于安全库存 + 已售完，两张口径分别查一次再合并。 */
async function loadAlerts() {
  const [warning, out] = await Promise.all([
    axios.get('/merchant/inventory', { params: { stockStatus: 'warning', page: 1, pageSize: 100 } }),
    axios.get('/merchant/inventory', { params: { stockStatus: 'out', page: 1, pageSize: 100 } }),
  ])
  const rowsOf = (body: any): any[] => {
    const data = body?.data ?? body ?? {}
    return Array.isArray(data.list) ? data.list : []
  }
  const toAlert = (row: any): StockAlert => ({
    inventoryId: Number(row.id ?? 0),
    productId: Number(row.productId ?? 0),
    productName: String(row.productName ?? '未命名商品'),
    productType: INVENTORY_TYPE_CODE[String(row.productType)] ?? 1,
    currentStock: Number(row.currentStock ?? 0),
    minStock: Number(row.minStock ?? 0),
    lastUpdateTime: row.lastUpdateTime ?? null,
  })
  const merged = [...rowsOf(out).map(toAlert), ...rowsOf(warning).map(toAlert)]
  soldOut.value = merged.filter((item) => item.currentStock <= 0).length
  alerts.value = merged.sort((a, b) => (a.currentStock - a.minStock) - (b.currentStock - b.minStock))
}

async function load() {
  loading.value = true
  failed.value = false
  authFailed.value = false
  try {
    // 趋势先取：当日订单与成交额由它提供，dashboard 的环比字段本页不再使用。
    await loadTrend()
    await Promise.all([loadSummary(), loadPending(), loadAlerts()])
  } catch (error) {
    failed.value = true
    authFailed.value = isAuthError(error)
    failureText.value = errorText(error, '没能取到店铺数据')
  } finally {
    loading.value = false
  }
}

async function ship(order: PendingOrder) {
  try {
    await ElMessageBox.confirm(
      `确认订单 ${order.orderNo} 已经打包发出？发货后买家会收到通知。`,
      '确认发货',
      { confirmButtonText: '确认发货', cancelButtonText: '再等等' },
    )
  } catch {
    return
  }
  shipping.value = order.orderId
  try {
    await axios.post(`/orders/${order.orderId}/ship`)
    ElMessage.success('已发货，买家会收到通知')
    await Promise.all([loadPending(), loadSummary()])
  } catch (error) {
    ElMessage.error(errorText(error, '发货失败，请稍后重试'))
  } finally {
    shipping.value = null
  }
}

function goOrderDetail(orderNo: string) {
  router.push(`/merchant-dashboard/order-detail/${orderNo}`)
}

onMounted(load)

onMounted(() => {
  mediaQuery = window.matchMedia('(max-width: 900px)')
  syncNarrow()
  mediaQuery.addEventListener('change', syncNarrow)
})

onBeforeUnmount(() => mediaQuery?.removeEventListener('change', syncNarrow))
</script>

<template>
  <div class="stack">
    <header class="page-head">
      <div>
        <h1 class="page-head__title">店铺概况</h1>
        <p class="page-head__note">今天是 {{ todayText }}，先从待发货和库存两件事开始。</p>
      </div>
      <el-button type="primary" @click="router.push('/merchant-dashboard/product-add')">
        <AppIcon name="plus" size="14" />
        发布商品
      </el-button>
    </header>

    <StatStrip :entries="stats" :loading="loading" />

    <EmptyState
      v-if="failed"
      :title="authFailed ? '登录状态已失效' : '没能加载店铺数据'"
      :note="
        authFailed
          ? '登录信息可能已过期，重新登录后即可继续处理订单。'
          : `${failureText}。确认后端服务已启动后重试。`
      "
    >
      <el-button v-if="authFailed" type="primary" @click="router.push('/login')">去登录</el-button>
      <el-button v-else type="primary" @click="load">重试</el-button>
    </EmptyState>

    <template v-else>
      <!-- 待处理订单：这一屏的目的就是把它清零 -->
      <section class="plate">
        <SectionHead title="待处理订单" note="已支付、等待发货的订单">
          <template #action>
            <RouterLink class="link" :to="{ path: '/merchant-dashboard/order-management', query: { type: 'new' } }">
              全部订单
              <AppIcon name="chevron-right" size="13" />
            </RouterLink>
          </template>
        </SectionHead>

        <div v-if="loading" class="ghost" aria-busy="true">
          <div v-for="n in 3" :key="n" class="ghost__row skeleton" />
        </div>

        <EmptyState
          v-else-if="!pending.length"
          title="没有待发货的订单"
          note="买家付款后订单会出现在这里，发货后自动移出。"
        />

        <div v-else class="table-wrap">
          <el-table :data="pending.slice(0, 6)" size="small" row-key="orderId">
            <el-table-column label="订单号" min-width="180">
              <template #default="{ row }">
                <span class="mono">{{ row.orderNo }}</span>
              </template>
            </el-table-column>
            <el-table-column label="买家" min-width="110">
              <template #default="{ row }">{{ row.customerName || '—' }}</template>
            </el-table-column>
            <el-table-column label="金额" width="130" align="right">
              <template #default="{ row }">
                <PriceTag :price="row.totalAmount" size="sm" :show-original="false" />
              </template>
            </el-table-column>
            <el-table-column v-if="!narrow" label="下单时间" width="150">
              <template #default="{ row }">
                <span class="muted">{{ formatDateTime(row.createTime) }}</span>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="160" align="right">
              <template #default="{ row }">
                <div class="row-actions">
                  <el-button
                    type="primary"
                    size="small"
                    :loading="shipping === row.orderId"
                    @click="ship(row)"
                  >
                    发货
                  </el-button>
                  <el-button size="small" @click="goOrderDetail(row.orderNo)">详情</el-button>
                </div>
              </template>
            </el-table-column>
          </el-table>

          <p v-if="pending.length > 6 || pendingWindowFull" class="table-note">
            <template v-if="pending.length > 6">
              还有 {{ pending.length - 6 }} 单待发货，
            </template>
            <RouterLink class="link" :to="{ path: '/merchant-dashboard/order-management', query: { type: 'new' } }">
              去订单管理批量处理
            </RouterLink>
            <template v-if="pendingWindowFull">（本页只统计最近 {{ ORDER_WINDOW }} 单）</template>
          </p>
        </div>
      </section>

      <!-- 库存预警：低于安全库存的要补，已售完的要决定是否下架 -->
      <section class="plate">
        <SectionHead title="库存预警" note="低于安全库存或已经售完的商品">
          <template #action>
            <RouterLink class="link" to="/merchant-dashboard/inventory-management">
              库存管理
              <AppIcon name="chevron-right" size="13" />
            </RouterLink>
          </template>
        </SectionHead>

        <div v-if="loading" class="ghost" aria-busy="true">
          <div v-for="n in 3" :key="n" class="ghost__row skeleton" />
        </div>

        <EmptyState
          v-else-if="!alerts.length"
          title="库存都在安全线以上"
          note="有商品低于安全库存时，这里会按缺口从大到小列出来。"
        />

        <div v-else class="table-wrap">
          <el-table :data="alerts.slice(0, 6)" size="small" row-key="inventoryId">
            <el-table-column label="商品" min-width="200">
              <template #default="{ row }">
                <span class="cell-name">{{ row.productName }}</span>
              </template>
            </el-table-column>
            <el-table-column label="类型" width="90">
              <template #default="{ row }">
                <StatePill
                  :label="typeLabel(row.productType).label"
                  :tone="typeLabel(row.productType).tone"
                />
              </template>
            </el-table-column>
            <el-table-column label="当前库存" width="120" align="right">
              <template #default="{ row }">
                <span class="stock" :class="`stock--${stockTone(row)}`">{{ stockText(row) }}</span>
              </template>
            </el-table-column>
            <el-table-column label="安全库存" width="100" align="right">
              <template #default="{ row }">
                <span class="tnum">{{ row.minStock }}</span>
              </template>
            </el-table-column>
            <el-table-column v-if="!narrow" label="最近变动" width="150">
              <template #default="{ row }">
                <span class="muted">{{ formatDateTime(row.lastUpdateTime) }}</span>
              </template>
            </el-table-column>
          </el-table>

          <p v-if="alerts.length > 6" class="table-note">
            还有 {{ alerts.length - 6 }} 项需要处理，
            <RouterLink class="link" to="/merchant-dashboard/inventory-management">去库存管理</RouterLink>
          </p>
        </div>
      </section>

      <!-- 近 7 天：趋势用对齐的数字读，比折线图更容易比较 -->
      <section class="plate">
        <SectionHead title="近 7 天成交" note="按天下单量与成交额">
          <template #action>
            <span class="muted">合计 {{ trendTotal.orders }} 单 · {{ formatMoney(trendTotal.revenue) }}</span>
          </template>
        </SectionHead>

        <div v-if="loading" class="ghost" aria-busy="true">
          <div v-for="n in 4" :key="n" class="ghost__row skeleton" />
        </div>

        <EmptyState v-else-if="!trend.length" title="还没有成交记录" note="订单完成后会按天汇总在这里。" />

        <div v-else class="table-wrap">
          <el-table :data="trend" size="small" row-key="date">
            <el-table-column prop="date" label="日期" min-width="110" />
            <el-table-column label="订单" width="90" align="right">
              <template #default="{ row }">
                <span class="tnum">{{ row.orders }}</span>
              </template>
            </el-table-column>
            <el-table-column label="成交额" width="130" align="right">
              <template #default="{ row }">
                <span class="tnum">{{ formatMoney(row.revenue) }}</span>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </section>
    </template>
  </div>
</template>

<style scoped>
.plate {
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
  overflow: hidden;
}

.plate :deep(.section-head) {
  margin: 0;
  padding: var(--space-3) var(--pad-surface);
  border-bottom: var(--hairline);
}

.link {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--ink-1);
}

.link:hover {
  text-decoration: none;
  color: var(--signal-amber-deep);
}

.table-wrap {
  padding: var(--space-3) var(--pad-surface) var(--space-4);
}

.cell-name {
  color: var(--ink-0);
  font-weight: 500;
}

.row-actions {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  justify-content: flex-end;
}

.stock {
  font-weight: 600;
}

.stock--amber {
  color: var(--signal-amber-deep);
}

.stock--vermilion {
  color: var(--signal-vermilion-deep);
}

.table-note {
  margin-top: var(--space-3);
  color: var(--ink-3);
  font-size: var(--text-xs);
}

.ghost {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-4) var(--pad-surface);
}

.ghost__row {
  height: 20px;
  border-radius: var(--radius-xs);
}

@media (max-width: 900px) {
  .table-wrap {
    overflow-x: auto;
  }
}
</style>
