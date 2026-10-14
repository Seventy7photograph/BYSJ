<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import axios from '@/axios'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { cancelOrder, confirmReceive, getOrderList, returnRental } from '@/api/user/order'
import {
  conditionLabel,
  labelOf,
  ORDER_STATUS,
  ORDER_STATUS_GROUP,
  PRODUCT_TYPE,
} from '@/constants/domain'
import { formatMoney, formatRelative } from '@/utils/format'
import { useUserStore } from '@/stores/user'

/**
 * 我的订单。
 *
 * 原来的问题：状态文案自己写了一张表、类型切换只在当前页做客户端过滤、
 * 退款弹窗的提交按钮没有防重复、接口路径有五处直接拼字符串。
 * 现在的口径：
 * - 交易线（全新 / 二手 / 租赁）走后端 type 参数，写进路由，刷新后保持；
 * - 状态分组用 domain 的 ORDER_STATUS_GROUP 文案，但过滤放在本地做：
 *   后端把 status 的判断写在了分页之后（只有当前页生效），本地过滤才不会
 *   出现「有订单却显示为空」的假结果；
 * - 因此一次性取回该交易线的订单（最多 100 笔）后在页面内分页，
 *   超过 100 笔时页面会明确说明。
 */
const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const TYPE_TABS = [
  { key: 'all', value: '', label: '全部' },
  { key: 'new', value: 'new', label: '全新' },
  { key: 'used', value: 'used', label: '二手' },
  { key: 'rental', value: 'rental', label: '租赁' },
] as const

const PAGE_SIZE = 10

const REFUND_REASONS = [
  '商品质量问题',
  '拍错商品',
  '商品与描述不符',
  '物流问题',
  '其他原因',
] as const

function readQuery(value: unknown): string {
  if (Array.isArray(value)) return readQuery(value[0])
  if (value === null || value === undefined) return ''
  return String(value).trim()
}

const orders = ref<any[]>([])
const serverTotal = ref(0)
const loading = ref(true)
const errorText = ref('')
const keyword = ref('')
const acting = ref<number | null>(null)
const refundVisible = ref(false)
const refundSubmitting = ref(false)
const refundTarget = ref<any>(null)
const refundError = ref('')
const refundReason = ref<string>(REFUND_REASONS[0])
const refundDescription = ref('')

const activeType = computed(() => {
  const value = readQuery(route.query.type)
  return TYPE_TABS.some((tab) => tab.value === value) ? value : ''
})
const activeStatus = computed(() => {
  const value = readQuery(route.query.status)
  return value in ORDER_STATUS_GROUP ? value : 'all'
})
const page = computed(() => {
  const value = Number(readQuery(route.query.page))
  return Number.isFinite(value) && value > 0 ? Math.floor(value) : 1
})

function writeQuery(patch: Record<string, string | undefined>, resetPage = true) {
  const merged: Record<string, string> = {}
  const source: Record<string, unknown> = { ...route.query, ...patch }
  for (const [key, value] of Object.entries(source)) {
    if (value === undefined || value === null) continue
    const text = String(value).trim()
    if (!text || text === 'all') continue
    merged[key] = text
  }
  if (resetPage) delete merged.page
  void router.push({ path: '/orders', query: merged })
}

const filteredOrders = computed(() => {
  const search = keyword.value.trim().toLowerCase()
  const codes = ORDER_STATUS_GROUP[activeStatus.value as keyof typeof ORDER_STATUS_GROUP]
    .codes as readonly number[]
  return orders.value.filter((order) => {
    if (activeStatus.value !== 'all' && !codes.includes(Number(order.orderStatus))) return false
    if (!search) return true
    const no = String(order.orderNo ?? '').toLowerCase()
    const names = (order.items ?? []).map((item: any) =>
      String(item.productName ?? '').toLowerCase(),
    )
    return no.includes(search) || names.some((name: string) => name.includes(search))
  })
})

const pagedOrders = computed(() => {
  const start = (page.value - 1) * PAGE_SIZE
  return filteredOrders.value.slice(start, start + PAGE_SIZE)
})

const truncated = computed(() => serverTotal.value > orders.value.length)

function statusOf(order: any) {
  return labelOf(ORDER_STATUS, Number(order?.orderStatus))
}

function itemType(item: any) {
  return labelOf(PRODUCT_TYPE, Number(item?.productType ?? 1))
}

function itemGrade(item: any): string | null {
  return Number(item?.productType) === 1 ? null : conditionLabel(item?.condition)
}

function itemCount(order: any): number {
  return (order.items ?? []).reduce((sum: number, item: any) => sum + Number(item.quantity ?? 0), 0)
}

/**
 * 订单实际的租赁天数。
 *
 * 后端 order_item.lease_term 没有被写进库（insertBatch 漏了这一列），
 * 订单接口返回的 leaseTerm 恒为 null；用金额反推可以精确还原：
 * 租金 = 订单总额 - 押金合计 = Σ(单价 × 数量) × 天数。
 */
function rentalDaysOf(order: any): number {
  const rows: any[] = order?.items ?? []
  const direct = Number(rows.find((item) => Number(item?.productType) === 3)?.leaseTerm ?? 0)
  if (direct > 0) return direct
  const base = rows.reduce(
    (sum: number, item: any) => sum + Number(item?.unitPrice ?? 0) * Number(item?.quantity ?? 0),
    0,
  )
  const deposit = rows.reduce(
    (sum: number, item: any) => sum + Number(item?.deposit ?? 0) * Number(item?.quantity ?? 0),
    0,
  )
  const rent = Number(order?.totalAmount ?? 0) - deposit
  if (base <= 0 || rent <= 0) return 0
  const days = rent / base
  return Number.isFinite(days) && days >= 1 ? Math.round(days) : 0
}

function lineAmount(order: any, item: any): number {
  const unit = Number(item?.unitPrice ?? 0)
  const quantity = Number(item?.quantity ?? 0)
  const days = Number(item?.productType) > 2 ? Math.max(1, rentalDaysOf(order)) : 1
  return unit * quantity * days
}

/** 与后端 RefundService.canRefund 一致：只有已付款、已发货可以申请退款。 */
function canRefund(order: any): boolean {
  const code = Number(order?.orderStatus)
  return code === 1 || code === 2
}

/* --- 数据 ----------------------------------------------------------------- */

let requestToken = 0

async function loadOrders() {
  const token = ++requestToken
  loading.value = true
  errorText.value = ''
  try {
    const res = await getOrderList({
      type: (activeType.value || undefined) as 'new' | 'used' | 'rental' | undefined,
      pageNum: 1,
      pageSize: 100,
    })
    if (token !== requestToken) return
    orders.value = res.list
    serverTotal.value = res.total
  } catch {
    if (token !== requestToken) return
    orders.value = []
    serverTotal.value = 0
    errorText.value = '订单列表没有加载出来，可能是网络中断或登录状态已失效。'
  } finally {
    if (token === requestToken) loading.value = false
  }
}

watch(activeType, () => void loadOrders(), { immediate: true })

onMounted(() => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录后查看订单')
    void router.push({ path: '/login', query: { redirect: '/orders' } })
  }
})

/* --- 订单动作 ------------------------------------------------------------- */

async function handleCancel(order: any) {
  try {
    await ElMessageBox.confirm(`取消订单 ${order.orderNo}？取消后需要重新下单。`, '取消订单', {
      confirmButtonText: '取消订单',
      cancelButtonText: '先不取消',
      type: 'warning',
    })
  } catch {
    return
  }
  acting.value = Number(order.orderId)
  try {
    await cancelOrder(Number(order.orderId))
    ElMessage.success('订单已取消')
    await loadOrders()
  } catch {
    // 拦截器已提示后端原因
  } finally {
    acting.value = null
  }
}

async function handleConfirmReceive(order: any) {
  try {
    await ElMessageBox.confirm(
      '确认已收到器材？确认后订单会继续流转，租赁订单进入租赁中。',
      '确认收货',
      { confirmButtonText: '确认收货', cancelButtonText: '还没收到', type: 'warning' },
    )
  } catch {
    return
  }
  acting.value = Number(order.orderId)
  try {
    await confirmReceive(Number(order.orderId))
    ElMessage.success('已确认收货')
    await loadOrders()
  } catch {
    // 拦截器已提示后端原因
  } finally {
    acting.value = null
  }
}

async function handleReturn(order: any) {
  try {
    await ElMessageBox.confirm(
      '发起归还后请按商家指引寄回器材，商家确认后押金按规则退还。确定发起归还？',
      '归还器材',
      { confirmButtonText: '发起归还', cancelButtonText: '取消', type: 'warning' },
    )
  } catch {
    return
  }
  acting.value = Number(order.orderId)
  try {
    await returnRental(Number(order.orderId))
    ElMessage.success('已提交归还，等待商家确认')
    await loadOrders()
  } catch {
    // 拦截器已提示后端原因
  } finally {
    acting.value = null
  }
}

function goPay(order: any) {
  void router.push({
    path: `/order/payment/${order.orderId}`,
    query: { paymentMethod: String(order.paymentMethod ?? 'wechat') },
  })
}

function goDetail(order: any) {
  void router.push(`/order/detail/${order.orderId}`)
}

function openItem(item: any) {
  const type = Number(item?.productType)
  if (type === 2) void router.push(`/second-hand/detail/${item.productId}`)
  else if (type === 3) void router.push(`/rental/detail/${item.productId}`)
  else void router.push(`/product/${item.productId}`)
}

/* --- 退款 ----------------------------------------------------------------- */

function openRefund(order: any) {
  refundTarget.value = order
  refundReason.value = REFUND_REASONS[0]
  refundDescription.value = ''
  refundError.value = ''
  refundVisible.value = true
}

async function submitRefund() {
  const order = refundTarget.value
  if (!order || refundSubmitting.value) return
  if (!refundReason.value) {
    refundError.value = '请选择退款原因'
    return
  }
  if (refundDescription.value.trim().length < 5) {
    refundError.value = '请补充至少 5 个字的说明，方便平台判断'
    return
  }
  refundError.value = ''
  refundSubmitting.value = true
  try {
    await axios.post('/refunds/apply', {
      orderId: Number(order.orderId),
      refundReason: refundReason.value,
      refundDescription: refundDescription.value.trim(),
    })
    ElMessage.success('退款申请已提交，处理进度可在订单详情查看')
    refundVisible.value = false
    await loadOrders()
  } catch {
    // 拦截器已提示后端原因
  } finally {
    refundSubmitting.value = false
  }
}
</script>

<template>
  <div class="shell page">
    <SectionHead title="我的订单" :note="`共 ${serverTotal} 笔订单`">
      <template #action>
        <RouterLink class="link" to="/shop">继续挑选器材</RouterLink>
      </template>
    </SectionHead>

    <div class="toolbar">
      <div class="tabs" role="tablist" aria-label="交易线">
        <button
          v-for="tab in TYPE_TABS"
          :key="tab.key"
          class="tabs__item"
          :class="{ 'is-active': activeType === tab.value }"
          type="button"
          role="tab"
          :aria-selected="activeType === tab.value"
          @click="writeQuery({ type: tab.value || undefined })"
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
          placeholder="订单号或商品名称"
          aria-label="在已加载的订单中搜索"
        />
      </label>
    </div>

    <div class="chips" role="tablist" aria-label="订单状态">
      <button
        v-for="(group, key) in ORDER_STATUS_GROUP"
        :key="key"
        class="chip"
        :class="{ 'is-active': activeStatus === key }"
        type="button"
        role="tab"
        :aria-selected="activeStatus === key"
        @click="writeQuery({ status: key === 'all' ? undefined : String(key) })"
      >
        {{ group.label }}
      </button>
    </div>

    <p v-if="truncated" class="note">
      只加载了最近 {{ orders.length }} 笔订单，更早的订单请按交易线切换或稍后再看。
    </p>

    <div v-if="loading" class="stack" aria-busy="true">
      <div v-for="n in 2" :key="n" class="skeleton card-ghost" />
    </div>

    <EmptyState v-else-if="errorText" title="订单列表加载失败" :note="errorText">
      <button class="btn" type="button" @click="loadOrders()">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
    </EmptyState>

    <EmptyState
      v-else-if="!filteredOrders.length"
      :title="orders.length ? '这个筛选条件下没有订单' : '还没有订单'"
      :note="
        orders.length
          ? '切换状态或交易线看看，也可以清空搜索词。'
          : '挑好器材下单后，订单会出现在这里。'
      "
    >
      <RouterLink v-if="!orders.length" class="btn" to="/shop">去器材商城</RouterLink>
      <button
        v-else
        class="btn"
        type="button"
        @click="writeQuery({ status: undefined, type: undefined })"
      >
        查看全部订单
      </button>
    </EmptyState>

    <div v-else class="stack">
      <article v-for="order in pagedOrders" :key="order.orderId" class="plate order">
        <header class="order__head">
          <div class="order__ids">
            <span class="order__no mono">{{ order.orderNo }}</span>
            <span class="order__time">{{ formatRelative(order.createTime) }}</span>
          </div>
          <StatePill :label="statusOf(order).label" :tone="statusOf(order).tone" />
        </header>

        <ul class="order__items">
          <li v-for="item in order.items ?? []" :key="item.productId">
            <button class="oi" type="button" @click="openItem(item)">
              <span class="oi__media">
                <ImageFrame
                  :src="item.productImage"
                  :alt="item.productName ?? '商品图'"
                  ratio="1 / 1"
                />
              </span>
              <span class="oi__info">
                <span class="oi__name">{{ item.productName || '未命名商品' }}</span>
                <span class="oi__meta">
                  <StatePill :label="itemType(item).label" :tone="itemType(item).tone" />
                  <span v-if="itemGrade(item)">成色 {{ itemGrade(item) }}</span>
                  <span v-if="Number(item.productType) === 3 && rentalDaysOf(order) > 0">
                    租期 {{ rentalDaysOf(order) }} 天
                  </span>
                  <span>数量 {{ item.quantity }}</span>
                </span>
              </span>
              <span class="oi__amount">
                <span class="oi__unit">
                  {{ formatMoney(item.unitPrice) }}
                  <span v-if="Number(item.productType) === 3" class="oi__unit-note">/天</span>
                </span>
                <span class="oi__line money">{{ formatMoney(lineAmount(order, item)) }}</span>
              </span>
            </button>
          </li>
        </ul>

        <footer class="order__foot">
          <div class="order__sum">
            共 {{ itemCount(order) }} 件器材，订单金额
            <span class="money order__amount">{{ formatMoney(order.totalAmount) }}</span>
          </div>
          <div class="order__actions">
            <button
              v-if="Number(order.orderStatus) === 0"
              class="btn btn--ghost"
              type="button"
              :disabled="acting === Number(order.orderId)"
              @click="handleCancel(order)"
            >
              取消订单
            </button>
            <button
              v-if="Number(order.orderStatus) === 0"
              class="btn btn--solid"
              type="button"
              @click="goPay(order)"
            >
              立即支付
            </button>
            <button
              v-if="Number(order.orderStatus) === 2"
              class="btn btn--solid"
              type="button"
              :disabled="acting === Number(order.orderId)"
              @click="handleConfirmReceive(order)"
            >
              确认收货
            </button>
            <button
              v-if="Number(order.orderStatus) === 8"
              class="btn btn--solid"
              type="button"
              :disabled="acting === Number(order.orderId)"
              @click="handleReturn(order)"
            >
              归还器材
            </button>
            <button
              v-if="canRefund(order)"
              class="btn btn--ghost"
              type="button"
              @click="openRefund(order)"
            >
              申请退款
            </button>
            <button class="btn" type="button" @click="goDetail(order)">订单详情</button>
          </div>
        </footer>
      </article>

      <div v-if="filteredOrders.length > PAGE_SIZE" class="pager">
        <span class="pager__count">{{ filteredOrders.length }} 笔订单</span>
        <el-pagination
          :current-page="page"
          :page-size="PAGE_SIZE"
          :total="filteredOrders.length"
          layout="prev, pager, next"
          background
          @current-change="(value: number) => writeQuery({ page: String(value) }, false)"
        />
      </div>
    </div>

    <!-- 退款申请 -->
    <el-dialog v-model="refundVisible" title="申请退款" width="480px">
      <div v-if="refundTarget" class="refund">
        <dl class="refund__facts">
          <div>
            <dt>订单号</dt>
            <dd class="mono">{{ refundTarget.orderNo }}</dd>
          </div>
          <div>
            <dt>订单金额</dt>
            <dd>{{ formatMoney(refundTarget.totalAmount) }}</dd>
          </div>
        </dl>

        <label class="field">
          <span class="field__label">退款原因</span>
          <el-select v-model="refundReason" class="field__control">
            <el-option
              v-for="reason in REFUND_REASONS"
              :key="reason"
              :label="reason"
              :value="reason"
            />
          </el-select>
        </label>

        <label class="field">
          <span class="field__label">详细说明</span>
          <el-input
            v-model="refundDescription"
            type="textarea"
            :rows="4"
            maxlength="200"
            show-word-limit
            placeholder="说明问题与期望的处理方式，例如「镜头卡口有划痕，希望退货退款」"
          />
        </label>

        <p class="hint">提交后订单进入退款处理中，退款进度可在订单详情查看。</p>
        <p v-if="refundError" class="field__error">{{ refundError }}</p>
      </div>
      <template #footer>
        <div class="dialog-foot">
          <button class="btn btn--ghost" type="button" @click="refundVisible = false">取消</button>
          <button
            class="btn btn--solid"
            type="button"
            :disabled="refundSubmitting"
            @click="submitRefund"
          >
            提交申请
          </button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.page {
  padding-bottom: var(--space-8);
}

.stack {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

/* --- 工具栏 --------------------------------------------------------------- */

.toolbar {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-bottom: var(--space-3);
}

.tabs {
  display: flex;
  gap: var(--space-1);
  overflow-x: auto;
  scrollbar-width: none;
}

.tabs::-webkit-scrollbar {
  display: none;
}

.tabs__item {
  flex-shrink: 0;
  padding: 6px 12px;
  border: 1px solid transparent;
  border-radius: var(--radius-sm);
  background: transparent;
  font-size: var(--text-sm);
  color: var(--ink-3);
  cursor: pointer;
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

.chips {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  margin-bottom: var(--space-4);
}

.chip {
  padding: 5px 10px;
  border: 1px solid transparent;
  border-radius: var(--radius-sm);
  background: transparent;
  font-size: var(--text-xs);
  color: var(--ink-3);
  cursor: pointer;
}

.chip:hover {
  background: var(--paper-2);
  color: var(--ink-1);
}

.chip.is-active {
  border-color: var(--line-2);
  background: var(--paper-0);
  color: var(--ink-0);
  font-weight: 600;
}

.note {
  margin-bottom: var(--space-3);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

/* --- 订单卡片 ------------------------------------------------------------- */

.order {
  overflow: hidden;
}

.order__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  background: var(--paper-2);
  border-bottom: var(--hairline);
}

.order__ids {
  display: flex;
  align-items: baseline;
  flex-wrap: wrap;
  gap: var(--space-3);
  min-width: 0;
}

.order__no {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-1);
}

.order__time {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.order__items {
  margin: 0;
  padding: 0 var(--space-4);
  list-style: none;
}

.order__items li + li {
  border-top: var(--hairline);
}

.oi {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  width: 100%;
  padding: var(--space-3) 0;
  border: none;
  background: transparent;
  text-align: left;
  cursor: pointer;
}

.oi:hover {
  background: var(--paper-1);
}

.oi__media {
  width: 64px;
  flex-shrink: 0;
  border: var(--edge);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.oi__info {
  display: flex;
  flex-direction: column;
  gap: 2px;
  flex: 1;
  min-width: 0;
}

.oi__name {
  font-size: var(--text-base);
  font-weight: 600;
  color: var(--ink-0);
}

.oi__meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.oi__amount {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
  white-space: nowrap;
}

.oi__unit {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.oi__unit-note {
  color: var(--ink-4);
}

.oi__line {
  font-size: var(--text-base);
}

.order__foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  border-top: var(--hairline);
}

.order__sum {
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.order__amount {
  font-size: var(--text-md);
  margin-left: var(--space-1);
}

.order__actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  margin-left: auto;
}

/* --- 分页 ----------------------------------------------------------------- */

.pager {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  padding-top: var(--space-2);
}

.pager__count {
  font-size: var(--text-sm);
  color: var(--ink-3);
}

/* --- 退款弹窗 ------------------------------------------------------------- */

.refund {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.refund__facts {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--space-3);
  margin: 0;
  padding: var(--space-3);
  background: var(--paper-1);
  border-radius: var(--radius-sm);
}

.refund__facts dt {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.refund__facts dd {
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

.field__control {
  width: 100%;
}

.field__error {
  font-size: var(--text-xs);
  color: var(--signal-vermilion-deep);
}

.hint {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.dialog-foot {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}

/* --- 通用 ---------------------------------------------------------------- */

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

.link {
  font-size: var(--text-sm);
  color: var(--ink-2);
  text-decoration: none;
}

.link:hover {
  color: var(--signal-amber-deep);
}

.card-ghost {
  height: 168px;
  border-radius: var(--radius-md);
}

@media (max-width: 900px) {
  .toolbar {
    flex-wrap: wrap;
  }
  .search {
    margin-left: 0;
    width: 100%;
  }
  .order__foot {
    flex-direction: column;
    align-items: flex-start;
  }
  .order__actions {
    margin-left: 0;
    width: 100%;
  }
  .order__actions .btn {
    flex: 1;
  }
}

@media (max-width: 520px) {
  .oi {
    flex-wrap: wrap;
    gap: var(--space-3);
  }
  .oi__amount {
    align-items: flex-start;
    margin-left: auto;
  }
  .refund__facts {
    grid-template-columns: minmax(0, 1fr);
  }
  .pager {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
