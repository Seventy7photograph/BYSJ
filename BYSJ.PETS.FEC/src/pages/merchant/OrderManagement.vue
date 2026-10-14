<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import PriceTag from '@/components/ui/PriceTag.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import {
  confirmReturn,
  getMerchantRefunds,
  getOrderDetail,
  getOrderList,
  missingReceiverFields,
  processRefund,
  shipOrder,
  type MerchantOrderRow,
  type MerchantRefundRow,
} from '@/api/merchant/order'
import { orderStatusLabel } from '@/api/user/order'
import { labelOf, ORDER_STATUS, type Tone } from '@/constants/domain'
import { formatDateTime, formatRelative } from '@/utils/format'

/**
 * 商家订单管理。
 *
 * 原页面把订单状态表在这里写了一份、在详情页又写了一份，退款状态还写第三份；
 * 发货点一下就调用接口，收件人/电话/地址缺不缺完全不管；「确认归还」的失败
 * 提示混着 cancel 一起被吞掉。现在：
 * - 状态文案统一取 @/constants/domain 与 orderStatusLabel()；
 * - 发货前先读订单详情，收货信息不齐就明确说缺哪几项，让买家去补；
 * - 一次取回该交易线的订单（最多 100 笔）后在页面内过滤分页 —— 后端把 status
 *   判断写在分页之后，跟着它分页会出现「有订单却搜不到」的假空结果；
 * - 退款处理只有同意/拒绝两种结果，处理完刷新列表。
 */
const route = useRoute()
const router = useRouter()

const PAGE_SIZE = 10
const FETCH_LIMIT = 100

const TABS = [
  { value: 'new', label: '全新订单' },
  { value: 'used', label: '二手订单' },
  { value: 'rental', label: '租赁订单' },
  { value: 'refund', label: '退款管理' },
] as const

type TabValue = (typeof TABS)[number]['value']

const REFUND_STATUS: Record<number, { label: string; tone: Tone }> = {
  0: { label: '申请中', tone: 'amber' },
  1: { label: '退款成功', tone: 'teal' },
  2: { label: '退款失败', tone: 'vermilion' },
}

const REFUND_TABS = [
  { value: '', label: '全部' },
  { value: '0', label: '申请中' },
  { value: '1', label: '退款成功' },
  { value: '2', label: '退款失败' },
] as const

function readQuery(value: unknown): string {
  if (Array.isArray(value)) return readQuery(value[0])
  if (value === null || value === undefined) return ''
  return String(value).trim()
}

const activeTab = computed<TabValue>(() => {
  const value = readQuery(route.query.type)
  return TABS.some((tab) => tab.value === value) ? (value as TabValue) : 'new'
})

function selectTab(value: TabValue) {
  void router.push({ path: '/merchant-dashboard/order-management', query: { type: value } })
}

/* --- 数据 ---------------------------------------------------------------- */

const rows = ref<MerchantOrderRow[]>([])
const refunds = ref<MerchantRefundRow[]>([])
const serverTotal = ref(0)
const loading = ref(true)
const error = ref('')
const status = ref('')
const refundStatus = ref('')
const keyword = ref('')
const page = ref(1)
const selectedIds = ref<number[]>([])
const acting = ref(false)
const refundDetail = ref<MerchantRefundRow | null>(null)
const refundDetailOpen = ref(false)

const isRefundTab = computed(() => activeTab.value === 'refund')

const statusOptions = computed(() => [
  { value: '', label: '全部状态' },
  ...Object.entries(ORDER_STATUS).map(([code, item]) => ({ value: code, label: item.label })),
])

const currentStatusLabel = computed(
  () => statusOptions.value.find((item) => item.value === status.value)?.label ?? '全部状态',
)

async function load() {
  loading.value = true
  error.value = ''
  selectedIds.value = []
  page.value = 1
  try {
    if (isRefundTab.value) {
      const res = await getMerchantRefunds({ page: 1, pageSize: FETCH_LIMIT })
      refunds.value = res.list
      serverTotal.value = res.total
      rows.value = []
    } else {
      const res = await getOrderList({
        type: activeTab.value as 'new' | 'used' | 'rental',
        pageNum: 1,
        pageSize: FETCH_LIMIT,
      })
      rows.value = res.list
      serverTotal.value = res.total
      refunds.value = []
    }
  } catch (e) {
    rows.value = []
    refunds.value = []
    serverTotal.value = 0
    error.value = e instanceof Error ? e.message : '订单没有加载出来'
  } finally {
    loading.value = false
  }
}

watch(activeTab, () => {
  status.value = ''
  refundStatus.value = ''
  keyword.value = ''
  void load()
})

watch([status, refundStatus, keyword], () => {
  page.value = 1
})

onMounted(() => void load())

/* --- 过滤与分页 ---------------------------------------------------------- */

const filteredOrders = computed(() => {
  const search = keyword.value.trim().toLowerCase()
  return rows.value.filter((row) => {
    if (status.value && String(row.orderStatus) !== status.value) return false
    if (!search) return true
    const names = (row.items ?? []).map((item) => String(item.productName ?? '').toLowerCase())
    return String(row.orderNo ?? '').toLowerCase().includes(search) || names.some((name) => name.includes(search))
  })
})

const filteredRefunds = computed(() => {
  const search = keyword.value.trim().toLowerCase()
  return refunds.value.filter((row) => {
    if (refundStatus.value && String(row.refundStatus) !== refundStatus.value) return false
    if (!search) return true
    return String(row.orderNo ?? '').toLowerCase().includes(search)
  })
})

const currentList = computed(() => (isRefundTab.value ? filteredRefunds.value : filteredOrders.value))

const pagedOrders = computed(() =>
  filteredOrders.value.slice((page.value - 1) * PAGE_SIZE, page.value * PAGE_SIZE),
)

const pagedRefunds = computed(() =>
  filteredRefunds.value.slice((page.value - 1) * PAGE_SIZE, page.value * PAGE_SIZE),
)

const filtered = computed(() => Boolean(status.value || refundStatus.value || keyword.value.trim()))

const truncated = computed(() => serverTotal.value > (isRefundTab.value ? refunds.value.length : rows.value.length))

const toShipCount = computed(() => rows.value.filter((row) => Number(row.orderStatus) === 1).length)

const headNote = computed(() => {
  if (isRefundTab.value) return `共 ${serverTotal.value} 条退款申请`
  return `共 ${serverTotal.value} 笔订单${toShipCount.value ? `，其中 ${toShipCount.value} 笔待发货` : ''}`
})

function resetFilters() {
  status.value = ''
  refundStatus.value = ''
  keyword.value = ''
}

function orderStatus(row: MerchantOrderRow) {
  return labelOf(ORDER_STATUS, Number(row.orderStatus))
}

function refundState(row: MerchantRefundRow) {
  return labelOf(REFUND_STATUS, Number(row.refundStatus))
}

function itemNames(row: MerchantOrderRow): string {
  return (row.items ?? [])
    .map((item) => [item.brandName, item.productName].filter(Boolean).join(' '))
    .filter(Boolean)
    .join('、')
}

/* --- 选择 ---------------------------------------------------------------- */

const selectableIds = computed(() =>
  pagedOrders.value.filter((row) => Number(row.orderStatus) === 1).map((row) => Number(row.orderId)),
)

const allSelected = computed(
  () => selectableIds.value.length > 0 && selectableIds.value.every((id) => selectedIds.value.includes(id)),
)

function toggleRow(orderId: number) {
  const index = selectedIds.value.indexOf(orderId)
  if (index >= 0) selectedIds.value.splice(index, 1)
  else selectedIds.value.push(orderId)
}

function toggleAll() {
  if (allSelected.value) {
    selectedIds.value = selectedIds.value.filter((id) => !selectableIds.value.includes(id))
  } else {
    selectedIds.value = Array.from(new Set([...selectedIds.value, ...selectableIds.value]))
  }
}

function openDetail(row: MerchantOrderRow) {
  void router.push(`/merchant-dashboard/order-detail/${row.orderId}`)
}

function openDetailById(orderId: number) {
  void router.push(`/merchant-dashboard/order-detail/${orderId}`)
}

/* --- 发货 ---------------------------------------------------------------- */

/**
 * 发货前的真实校验：订单上的收件人、电话、省市区与详细地址缺一项，
 * 包裹就发不出去。缺了就告诉商家缺什么，让买家去补，而不是发一个假成功。
 */
async function shipOne(orderId: number): Promise<'shipped' | 'incomplete' | 'failed'> {
  const detail = await getOrderDetail(orderId)
  const missing = missingReceiverFields(detail.order)
  if (missing.length > 0) {
    ElMessage.warning(
      `订单 ${detail.order.orderNo ?? orderId} 的收货信息不完整（缺少${missing.join('、')}），请让买家在「地址管理」补全后再发货`,
    )
    return 'incomplete'
  }
  await shipOrder(orderId)
  return 'shipped'
}

async function handleShip(row: MerchantOrderRow) {
  try {
    await ElMessageBox.confirm(
      `确认为订单 ${row.orderNo} 发货？发货后买家会收到通知。`,
      '发货确认',
      { confirmButtonText: '确认发货', cancelButtonText: '再等一下', type: 'warning' },
    )
  } catch {
    return
  }
  acting.value = true
  try {
    const result = await shipOne(Number(row.orderId))
    if (result === 'shipped') ElMessage.success('已发货')
    await load()
  } catch {
    // 拦截器已经说明了失败原因
  } finally {
    acting.value = false
  }
}

async function handleBatchShip() {
  if (selectedIds.value.length === 0) {
    ElMessage.warning('先勾选要发货的订单')
    return
  }
  try {
    await ElMessageBox.confirm(
      `为选中的 ${selectedIds.value.length} 笔订单发货？收货信息不完整的订单会被跳过。`,
      '批量发货',
      { confirmButtonText: '开始发货', cancelButtonText: '取消', type: 'warning' },
    )
  } catch {
    return
  }
  acting.value = true
  let shipped = 0
  let incomplete = 0
  let failed = 0
  for (const orderId of [...selectedIds.value]) {
    try {
      const result = await shipOne(orderId)
      if (result === 'shipped') shipped += 1
      else incomplete += 1
    } catch {
      failed += 1
    }
  }
  acting.value = false
  const parts = [`${shipped} 笔已发货`]
  if (incomplete) parts.push(`${incomplete} 笔收货信息不全`)
  if (failed) parts.push(`${failed} 笔失败`)
  ElMessage.success(parts.join('，'))
  await load()
}

/* --- 确认归还 ------------------------------------------------------------ */

async function handleConfirmReturn(row: MerchantOrderRow) {
  try {
    await ElMessageBox.confirm(
      `确认订单 ${row.orderNo} 已收到归还的器材？确认后押金按规则退还，库存回到可租数量。`,
      '确认归还',
      { confirmButtonText: '确认归还', cancelButtonText: '还没收到', type: 'warning' },
    )
  } catch {
    return
  }
  acting.value = true
  try {
    await confirmReturn(Number(row.orderId))
    ElMessage.success('已确认归还')
    await load()
  } catch {
    // 拦截器已经说明了失败原因
  } finally {
    acting.value = false
  }
}

/* --- 退款 ---------------------------------------------------------------- */

function openRefundDetail(row: MerchantRefundRow) {
  refundDetail.value = row
  refundDetailOpen.value = true
}

async function handleRefund(row: MerchantRefundRow, approve: boolean) {
  try {
    await ElMessageBox.confirm(
      approve
        ? `同意退款 ¥${Number(row.refundAmount ?? 0).toFixed(2)}？同意后订单进入退款成功，款项原路退回。`
        : `拒绝订单 ${row.orderNo} 的退款申请？拒绝后订单状态变为退款失败。`,
      approve ? '同意退款' : '拒绝退款',
      {
        confirmButtonText: approve ? '同意退款' : '确认拒绝',
        cancelButtonText: '取消',
        type: 'warning',
      },
    )
  } catch {
    return
  }
  acting.value = true
  try {
    await processRefund(Number(row.refundId), approve ? 1 : 2)
    ElMessage.success(approve ? '已同意退款' : '已拒绝退款')
    await load()
  } catch {
    // 拦截器已经说明了失败原因
  } finally {
    acting.value = false
  }
}

/* --- 导出 ---------------------------------------------------------------- */

function exportCsv() {
  if (isRefundTab.value) {
    if (filteredRefunds.value.length === 0) {
      ElMessage.warning('当前没有可导出的退款记录')
      return
    }
    const header = ['退款ID', '订单号', '退款金额', '退款状态', '退款原因', '申请时间']
    const body = filteredRefunds.value.map((row) => [
      row.refundId,
      row.orderNo,
      row.refundAmount,
      refundState(row).label,
      row.refundReason ?? '',
      formatDateTime(row.createTime),
    ])
    saveCsv([header, ...body], `退款列表_${new Date().toISOString().slice(0, 10)}.csv`)
    return
  }

  if (filteredOrders.value.length === 0) {
    ElMessage.warning('当前没有可导出的订单')
    return
  }
  const header = ['订单号', '买家账号', '收件人', '商品', '订单金额', '订单状态', '下单时间']
  const body = filteredOrders.value.map((row) => [
    row.orderNo,
    row.userName ?? '',
    row.customerName ?? '',
    itemNames(row),
    row.totalAmount,
    orderStatus(row).label,
    formatDateTime(row.createTime),
  ])
  saveCsv([header, ...body], `订单列表_${activeTab.value}_${new Date().toISOString().slice(0, 10)}.csv`)
}

function saveCsv(lines: (string | number)[][], filename: string) {
  const content = lines
    .map((line) => line.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(','))
    .join('\n')
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

function openProduct(productId: number) {
  void router.push(`/merchant-dashboard/product-edit/${productId}`)
}

/** 状态文案统一走 orderStatusLabel，本页不再存第二张表。 */
function statusText(code: number | null | undefined): string {
  return orderStatusLabel(code)
}
</script>

<template>
  <div class="page">
    <SectionHead title="订单管理" :note="headNote" size="lg">
      <template #action>
        <button class="btn" type="button" @click="exportCsv">
          <AppIcon name="download" size="14" />
          导出
        </button>
      </template>
    </SectionHead>

    <div class="tabs" role="tablist" aria-label="订单分类">
      <button
        v-for="tab in TABS"
        :key="tab.value"
        class="tabs__item"
        :class="{ 'is-active': activeTab === tab.value }"
        type="button"
        role="tab"
        :aria-selected="activeTab === tab.value"
        @click="selectTab(tab.value)"
      >
        {{ tab.label }}
      </button>
    </div>

    <div class="filters">
      <el-select
        v-if="!isRefundTab"
        v-model="status"
        class="filters__select"
        :placeholder="currentStatusLabel"
      >
        <el-option
          v-for="option in statusOptions"
          :key="option.value || 'all'"
          :label="option.label"
          :value="option.value"
        />
      </el-select>

      <div v-else class="seg" role="tablist" aria-label="退款状态">
        <button
          v-for="tab in REFUND_TABS"
          :key="tab.value || 'all'"
          class="seg__item"
          :class="{ 'is-active': refundStatus === tab.value }"
          type="button"
          role="tab"
          :aria-selected="refundStatus === tab.value"
          @click="refundStatus = tab.value"
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
          :placeholder="isRefundTab ? '订单号' : '订单号或商品名称'"
          aria-label="搜索订单"
        />
      </label>

      <button v-if="filtered" class="btn btn--ghost" type="button" @click="resetFilters">
        清空筛选
      </button>
    </div>

    <div v-if="!isRefundTab" class="bulk">
      <p class="bulk__count">
        {{ selectedIds.length ? `已选 ${selectedIds.length} 笔可发货订单` : `本页 ${pagedOrders.length} 笔` }}
      </p>
      <button
        v-if="selectedIds.length"
        class="btn btn--solid"
        type="button"
        :disabled="acting"
        @click="handleBatchShip"
      >
        批量发货
      </button>
      <button v-if="selectedIds.length" class="btn btn--ghost" type="button" @click="selectedIds = []">
        取消选择
      </button>
    </div>

    <p v-if="truncated" class="note">
      本次只取了最近 {{ isRefundTab ? refunds.length : rows.length }} 条（共 {{ serverTotal }} 条），
      更早的记录请用筛选条件缩小范围。
    </p>

    <!-- 加载 -->
    <div v-if="loading" class="plate" aria-busy="true">
      <div v-for="n in 5" :key="n" class="ghost-row">
        <span class="ghost ghost--lg skeleton" />
        <span class="ghost ghost--sm skeleton" />
        <span class="ghost ghost--md skeleton" />
      </div>
    </div>

    <!-- 错误 -->
    <EmptyState v-else-if="error" title="订单列表加载失败" :note="error">
      <button class="btn" type="button" @click="load">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
    </EmptyState>

    <!-- 空 -->
    <EmptyState
      v-else-if="currentList.length === 0"
      :title="filtered ? (isRefundTab ? '没有符合条件的退款申请' : '没有符合条件的订单') : isRefundTab ? '还没有退款申请' : '这一类还没有订单'"
      :note="
        filtered
          ? '换一个状态或清空搜索词再看。'
          : isRefundTab
            ? '买家为已付款或已发货的订单申请退款时会出现在这里。'
            : '买家下单后，订单会进入对应的交易线。'
      "
    >
      <button v-if="filtered" class="btn" type="button" @click="resetFilters">查看全部</button>
    </EmptyState>

    <!-- 订单表 -->
    <div v-else-if="!isRefundTab" class="plate table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th class="col-check">
              <input
                type="checkbox"
                :checked="allSelected"
                :disabled="selectableIds.length === 0"
                aria-label="选中本页可发货订单"
                @change="toggleAll"
              />
            </th>
            <th>订单号</th>
            <th>买家</th>
            <th>商品</th>
            <th class="num">金额</th>
            <th>状态</th>
            <th>下单时间</th>
            <th class="col-action">操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="row in pagedOrders" :key="row.orderId">
            <td class="col-check">
              <input
                v-if="Number(row.orderStatus) === 1"
                type="checkbox"
                :checked="selectedIds.includes(Number(row.orderId))"
                :aria-label="`选中订单 ${row.orderNo}`"
                @change="toggleRow(Number(row.orderId))"
              />
            </td>
            <td>
              <button class="link mono" type="button" @click="openDetail(row)">{{ row.orderNo }}</button>
            </td>
            <td>
              <span class="cell-main">{{ row.customerName || '未填收件人' }}</span>
              <span class="sub">{{ row.userName || '—' }}</span>
            </td>
            <td class="col-items">
              <ul class="items">
                <li v-for="item in row.items ?? []" :key="item.itemId ?? item.productId">
                  <button class="item-link" type="button" @click="openProduct(item.productId)">
                    {{ [item.brandName, item.productName].filter(Boolean).join(' ') || '未命名商品' }}
                  </button>
                  <span class="items__qty tnum">×{{ item.quantity }}</span>
                </li>
              </ul>
            </td>
            <td class="num">
              <PriceTag :price="row.totalAmount" :show-original="false" size="sm" />
            </td>
            <td>
              <StatePill :label="statusText(row.orderStatus)" :tone="orderStatus(row).tone" />
            </td>
            <td class="sub" :title="formatDateTime(row.createTime)">
              {{ formatRelative(row.createTime) }}
            </td>
            <td class="col-action">
              <div class="row-actions">
                <button
                  v-if="Number(row.orderStatus) === 1"
                  class="link link--strong"
                  type="button"
                  :disabled="acting"
                  @click="handleShip(row)"
                >
                  发货
                </button>
                <button
                  v-if="Number(row.orderStatus) === 9"
                  class="link link--strong"
                  type="button"
                  :disabled="acting"
                  @click="handleConfirmReturn(row)"
                >
                  确认归还
                </button>
                <button class="link" type="button" @click="openDetail(row)">订单详情</button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- 退款表 -->
    <div v-else class="plate table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>订单号</th>
            <th>商品</th>
            <th class="num">退款金额</th>
            <th>状态</th>
            <th>退款原因</th>
            <th>申请时间</th>
            <th class="col-action col-action--wide">操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="row in pagedRefunds" :key="row.refundId">
            <td>
              <button class="link mono" type="button" @click="openDetailById(Number(row.orderId))">
                {{ row.orderNo }}
              </button>
            </td>
            <td class="col-items">
              <ul class="items">
                <li v-for="item in row.items ?? []" :key="item.productId">
                  <span class="cell-main">
                    {{ [item.brandName, item.productName].filter(Boolean).join(' ') || '未命名商品' }}
                  </span>
                  <span class="items__qty tnum">×{{ item.quantity }}</span>
                </li>
              </ul>
            </td>
            <td class="num">
              <PriceTag :price="row.refundAmount" :show-original="false" size="sm" />
            </td>
            <td>
              <StatePill :label="refundState(row).label" :tone="refundState(row).tone" />
            </td>
            <td class="col-reason">{{ row.refundReason || '未填写' }}</td>
            <td class="sub" :title="formatDateTime(row.createTime)">
              {{ formatRelative(row.createTime) }}
            </td>
            <td class="col-action">
              <div class="row-actions">
                <button
                  v-if="Number(row.refundStatus) === 0"
                  class="link link--strong"
                  type="button"
                  :disabled="acting"
                  @click="handleRefund(row, true)"
                >
                  同意退款
                </button>
                <button
                  v-if="Number(row.refundStatus) === 0"
                  class="link link--danger"
                  type="button"
                  :disabled="acting"
                  @click="handleRefund(row, false)"
                >
                  拒绝退款
                </button>
                <button class="link" type="button" @click="openRefundDetail(row)">详情</button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="!loading && !error && currentList.length > PAGE_SIZE" class="pager">
      <span class="pager__count">{{ currentList.length }} 条</span>
      <el-pagination
        :current-page="page"
        :page-size="PAGE_SIZE"
        :total="currentList.length"
        layout="prev, pager, next"
        background
        @current-change="(value: number) => (page = value)"
      />
    </div>

    <!-- 退款详情 -->
    <el-dialog v-model="refundDetailOpen" title="退款详情" width="480px">
      <dl v-if="refundDetail" class="facts">
        <div>
          <dt>订单号</dt>
          <dd class="mono">{{ refundDetail.orderNo }}</dd>
        </div>
        <div>
          <dt>退款金额</dt>
          <dd>{{ Number(refundDetail.refundAmount ?? 0).toFixed(2) }} 元</dd>
        </div>
        <div>
          <dt>退款原因</dt>
          <dd>{{ refundDetail.refundReason || '未填写' }}</dd>
        </div>
        <div>
          <dt>申请时间</dt>
          <dd>{{ formatDateTime(refundDetail.createTime) }}</dd>
        </div>
        <div class="facts__wide">
          <dt>买家说明</dt>
          <dd class="facts__text">{{ refundDetail.refundDescription || '未填写' }}</dd>
        </div>
      </dl>
      <template #footer>
        <div class="dialog-foot">
          <button class="btn btn--ghost" type="button" @click="refundDetailOpen = false">关闭</button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.page {
  padding-bottom: var(--space-8);
}

/* --- 页签与筛选 ---------------------------------------------------------- */

.tabs {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-1);
  padding-bottom: var(--space-3);
  border-bottom: var(--hairline);
}

.tabs__item {
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

.tabs__item:hover {
  background: var(--paper-2);
  color: var(--ink-1);
}

.tabs__item.is-active {
  background: var(--paper-0);
  border-color: var(--line-2);
  color: var(--ink-0);
  font-weight: 600;
}

.filters {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-3);
  margin: var(--space-4) 0 var(--space-3);
}

.filters__select {
  width: 176px;
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
  align-items: center;
  gap: var(--space-3);
  min-height: 32px;
  margin-bottom: var(--space-3);
}

.bulk__count {
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
  min-width: 1020px;
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
  vertical-align: top;
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

.table .num :deep(.price) {
  justify-content: flex-end;
}

.col-check {
  width: 40px;
  padding-right: 0 !important;
}

.col-items {
  min-width: 240px;
}

.col-reason {
  max-width: 220px;
}

.col-action {
  width: 176px;
}

.col-action--wide {
  width: 232px;
}

.cell-main {
  display: block;
  color: var(--ink-1);
}

.sub {
  display: block;
  color: var(--ink-3);
  font-size: var(--text-xs);
}

.items {
  display: flex;
  flex-direction: column;
  gap: 2px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.items li {
  display: flex;
  align-items: baseline;
  gap: var(--space-2);
}

.items__qty {
  flex-shrink: 0;
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.item-link {
  padding: 0;
  border: none;
  background: transparent;
  text-align: left;
  font-size: var(--text-sm);
  color: var(--ink-1);
  cursor: pointer;
}

.item-link:hover {
  color: var(--signal-amber-deep);
  text-decoration: underline;
}

.row-actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-2) var(--space-4);
}

.link {
  padding: 0;
  border: none;
  background: transparent;
  font-size: var(--text-sm);
  color: var(--ink-2);
  cursor: pointer;
}

.link:hover:not(:disabled) {
  color: var(--signal-amber-deep);
  text-decoration: underline;
}

.link:disabled {
  color: var(--ink-4);
  cursor: not-allowed;
}

.link--strong {
  color: var(--ink-0);
  font-weight: 600;
}

.link--danger {
  color: var(--signal-vermilion-deep);
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

/* --- 退款详情 ------------------------------------------------------------ */

.facts {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--space-3);
  margin: 0;
}

.facts__wide {
  grid-column: 1 / -1;
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

.facts__text {
  font-weight: 400;
  line-height: 1.6;
  white-space: pre-wrap;
}

.dialog-foot {
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
  width: 26%;
  height: 18px;
}

.ghost--md {
  width: 28%;
}

.ghost--sm {
  width: 12%;
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
  .filters__select {
    width: 100%;
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
