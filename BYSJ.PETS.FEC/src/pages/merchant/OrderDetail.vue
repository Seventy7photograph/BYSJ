<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import PriceTag from '@/components/ui/PriceTag.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import SpecList, { type SpecEntry } from '@/components/ui/SpecList.vue'
import StatePill from '@/components/ui/StatePill.vue'
import {
  confirmReturn,
  getOrderDetail,
  missingReceiverFields,
  shipOrder,
  type MerchantOrderItem,
} from '@/api/merchant/order'
import { conditionLabel, labelOf, ORDER_STATUS, PRODUCT_TYPE } from '@/constants/domain'
import { formatDateTime, formatMoney } from '@/utils/format'

/**
 * 商家订单详情。
 *
 * 原来的这一页编了一整套物流：随机单号、「已到达分拣中心」的固定轨迹、
 * 后端根本没有的 shipTime / completeTime / customerEmail，还让商家替买家点
 * 「确认收货」。现在只呈现订单里真实存在的东西：订单快照、收货信息、订单项、
 * 金额构成、支付流水，以及由真实时间字段推出的流程记录。
 */
const route = useRoute()
const router = useRouter()

const PAYMENT_METHOD: Record<string, string> = {
  wechat: '微信支付',
  alipay: '支付宝',
  online: '在线支付',
  balance: '余额支付',
}

const STATUS_HINT: Record<number, string> = {
  0: '买家还没有付款，耐心等一下，超时会自动取消。',
  1: '买家已付款，收货信息齐全就可以发货了。',
  2: '已发货，等买家确认收货。',
  3: '订单已完成。',
  4: '订单已关闭。',
  5: '买家申请了退款，去「退款管理」处理。',
  6: '退款已原路退回买家。',
  7: '退款未通过，可与买家沟通后续处理。',
  8: '器材在租期内，按期归还后在这里确认归还。',
  9: '买家已发起归还，收到器材后确认归还并退还押金。',
}

const loading = ref(true)
const error = ref('')
const acting = ref(false)
const order = ref<Record<string, any> | null>(null)
const items = ref<MerchantOrderItem[]>([])

const orderId = computed(() => String(route.params.orderId ?? '').trim())
const statusCode = computed(() => Number(order.value?.orderStatus ?? -1))
const status = computed(() => labelOf(ORDER_STATUS, statusCode.value))
const statusHint = computed(
  () => STATUS_HINT[statusCode.value] ?? '订单状态已更新，若有疑问可以联系买家。',
)

const isRental = computed(() => items.value.some((item) => Number(item.productType) === 3))

const fullAddress = computed(() => {
  const data = order.value
  if (!data) return ''
  return `${data.province ?? ''}${data.city ?? ''}${data.district ?? ''}${data.detail ?? ''}`.trim()
})

/** 发货前的收货信息校验：缺哪几项就写哪几项。 */
const missingReceiver = computed(() => missingReceiverFields(order.value))

const depositTotal = computed(() =>
  items.value.reduce((sum, item) => sum + Number(item.deposit ?? 0) * Number(item.quantity ?? 0), 0),
)

/**
 * 租赁天数。order_item.lease_term 这一列没有被写进库（insertBatch 漏掉了它），
 * 接口返回的 leaseTerm 恒为 null；租金 = 订单金额 - 押金合计 = Σ(单价 × 数量) × 天数，
 * 反推能得到精确天数，前台「我的订单」也用同一口径，两边数字必须一致。
 */
const rentalDays = computed(() => {
  const direct = Number(items.value.find((item) => Number(item.productType) === 3)?.leaseTerm ?? 0)
  if (direct > 0) return direct
  const base = items.value.reduce(
    (sum, item) => sum + Number(item.unitPrice ?? 0) * Number(item.quantity ?? 0),
    0,
  )
  const rent = Number(order.value?.totalAmount ?? 0) - depositTotal.value
  if (base <= 0 || rent <= 0) return 0
  const days = rent / base
  return Number.isFinite(days) && days >= 1 ? Math.round(days) : 0
})

function lineAmount(item: MerchantOrderItem): number {
  const unit = Number(item.unitPrice ?? 0)
  const quantity = Number(item.quantity ?? 0)
  const days = Number(item.productType) === 3 ? Math.max(1, rentalDays.value) : 1
  return unit * quantity * days
}

const orderFacts = computed<SpecEntry[]>(() => {
  const data = order.value
  if (!data) return []
  return [
    { key: '订单号', value: data.orderNo, mono: true },
    { key: '下单时间', value: formatDateTime(data.createTime) },
    { key: '支付时间', value: data.payTime ? formatDateTime(data.payTime) : '未支付' },
    {
      key: '支付方式',
      value: data.paymentMethod ? (PAYMENT_METHOD[data.paymentMethod] ?? data.paymentMethod) : '—',
    },
    { key: '支付流水号', value: data.transactionId || '—', mono: true },
    { key: '最近更新', value: formatDateTime(data.updateTime) },
  ]
})

const receiverFacts = computed<SpecEntry[]>(() => {
  const data = order.value
  if (!data) return []
  return [
    { key: '收件人', value: data.recipient || '未填写' },
    { key: '联系电话', value: data.phone || '未填写' },
    { key: '收货地址', value: fullAddress.value || '未填写' },
  ]
})

/** 流程记录只陈述有据可查的节点，不编造物流轨迹。 */
const timeline = computed(() => {
  const data = order.value
  if (!data) return []
  const nodes: { title: string; time: string; note: string }[] = [
    { title: '订单已创建', time: formatDateTime(data.createTime), note: `订单号 ${data.orderNo ?? '—'}` },
  ]
  if (data.payTime) {
    nodes.push({
      title: '支付完成',
      time: formatDateTime(data.payTime),
      note: data.transactionId ? `流水号 ${data.transactionId}` : '已收到买家付款',
    })
  }
  nodes.push({
    title: `当前状态：${status.value.label}`,
    time: formatDateTime(data.updateTime),
    note: statusHint.value,
  })
  return nodes
})

function itemType(item: MerchantOrderItem) {
  return labelOf(PRODUCT_TYPE, Number(item.productType ?? 1))
}

function itemGrade(item: MerchantOrderItem): string | null {
  return Number(item.productType) === 1 ? null : conditionLabel(item.condition)
}

/**
 * order_item.specifications 存的是 JSON 串（如 {"镜头卡口":"尼康Z卡口", …}），
 * 当文本直接显示会挤出一坨括号。这里解析成规格行 —— 正是这套系统的招牌样式；
 * 解析不出来（"{}" 或旧数据）就不占一行，而不是把原始 JSON 倒给商家看。
 */
function parsedSpecifications(item: MerchantOrderItem): SpecEntry[] {
  const raw = String(item.specifications ?? '').trim()
  if (!raw || raw === '{}' || raw === '[]') return []
  try {
    const parsed = JSON.parse(raw)
    if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
      return Object.entries(parsed as Record<string, unknown>)
        .filter(([, value]) => value !== null && value !== undefined && String(value).trim() !== '')
        .slice(0, 8)
        .map(([key, value]) => ({ key, value: String(value) }))
    }
  } catch {
    // 不是 JSON，按原文呈现
  }
  return [{ key: '规格', value: raw }]
}

/** 商品快照里的规格信息，逐行对齐，不写营销文案。 */
function itemSpecs(item: MerchantOrderItem): SpecEntry[] {
  return [
    { key: '品牌', value: item.brandName },
    ...parsedSpecifications(item),
    { key: '成色', value: itemGrade(item) },
    {
      key: '租期',
      value: Number(item.productType) === 3 && rentalDays.value > 0 ? `${rentalDays.value} 天` : null,
    },
    {
      key: '押金',
      value: Number(item.deposit ?? 0) > 0 ? `${formatMoney(item.deposit)} / 件` : null,
    },
  ]
}

/* --- 数据 ---------------------------------------------------------------- */

async function load() {
  if (!orderId.value) {
    loading.value = false
    error.value = '缺少订单号，无法打开这张订单。'
    return
  }
  loading.value = true
  error.value = ''
  try {
    const detail = await getOrderDetail(orderId.value)
    order.value = detail.order
    items.value = detail.orderItems
  } catch (e) {
    order.value = null
    items.value = []
    error.value = e instanceof Error ? e.message : '订单没有加载出来'
  } finally {
    loading.value = false
  }
}

onMounted(load)

/* --- 动作 ---------------------------------------------------------------- */

async function handleShip() {
  const data = order.value
  if (!data) return
  if (missingReceiver.value.length > 0) {
    ElMessage.warning(`收货信息不完整：缺少${missingReceiver.value.join('、')}，请让买家补全后再发货`)
    return
  }
  try {
    await ElMessageBox.confirm(
      `确认为订单 ${data.orderNo} 发货？发货后买家会收到通知。`,
      '发货确认',
      { confirmButtonText: '确认发货', cancelButtonText: '再等一下', type: 'warning' },
    )
  } catch {
    return
  }
  acting.value = true
  try {
    await shipOrder(Number(data.orderId))
    ElMessage.success('已发货')
    await load()
  } catch {
    // 拦截器已经说明了失败原因
  } finally {
    acting.value = false
  }
}

async function handleConfirmReturn() {
  const data = order.value
  if (!data) return
  try {
    await ElMessageBox.confirm(
      '确认已收到归还的器材？确认后押金按规则退还，库存回到可租数量。',
      '确认归还',
      { confirmButtonText: '确认归还', cancelButtonText: '还没收到', type: 'warning' },
    )
  } catch {
    return
  }
  acting.value = true
  try {
    await confirmReturn(Number(data.orderId))
    ElMessage.success('已确认归还')
    await load()
  } catch {
    // 拦截器已经说明了失败原因
  } finally {
    acting.value = false
  }
}

function goBack() {
  void router.push('/merchant-dashboard/order-management')
}

function openProduct(productId: number) {
  void router.push(`/merchant-dashboard/product-edit/${productId}`)
}
</script>

<template>
  <div class="page">
    <SectionHead
      title="订单详情"
      :note="order ? `订单号 ${order.orderNo}` : '按订单号追一张订单的来龙去脉'"
      size="lg"
    >
      <template #action>
        <button class="btn" type="button" @click="goBack">
          <AppIcon name="chevron-left" size="14" />
          返回订单列表
        </button>
      </template>
    </SectionHead>

    <!-- 加载 -->
    <div v-if="loading" class="layout" aria-busy="true">
      <div class="main-col">
        <div class="plate ghost-card skeleton" />
        <div class="plate ghost-card ghost-card--tall skeleton" />
      </div>
      <div class="side-col">
        <div class="plate ghost-card skeleton" />
      </div>
    </div>

    <!-- 错误 -->
    <EmptyState v-else-if="error" title="订单打不开" :note="error">
      <button class="btn" type="button" @click="load">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
      <button class="btn btn--ghost" type="button" @click="goBack">返回订单列表</button>
    </EmptyState>

    <div v-else-if="order" class="layout">
      <div class="main-col">
        <!-- 订单快照 -->
        <section class="plate">
          <header class="plate__head">
            <h2 class="plate__title">订单信息</h2>
            <StatePill :label="status.label" :tone="status.tone" />
          </header>
          <div class="plate__body">
            <SpecList :entries="orderFacts" :columns="2" />
          </div>
        </section>

        <!-- 收货信息 -->
        <section class="plate">
          <header class="plate__head">
            <h2 class="plate__title">收货信息</h2>
            <span v-if="statusCode === 1 && missingReceiver.length === 0" class="head-note">可以发货</span>
          </header>
          <div class="plate__body">
            <SpecList :entries="receiverFacts" />
            <p v-if="missingReceiver.length > 0" class="alert">
              缺少 {{ missingReceiver.join('、') }}，发货前需要买家在「地址管理」补全。
            </p>
          </div>
        </section>

        <!-- 订单项 -->
        <section class="plate">
          <header class="plate__head">
            <h2 class="plate__title">商品（{{ items.length }} 项）</h2>
            <span v-if="isRental && rentalDays > 0" class="head-note">租期 {{ rentalDays }} 天</span>
          </header>

          <ul class="lines">
            <li v-for="item in items" :key="item.itemId ?? item.productId" class="line">
              <button class="line__media" type="button" @click="openProduct(item.productId)">
                <ImageFrame :src="item.productImage" :alt="item.productName ?? '商品图'" ratio="1 / 1" />
              </button>

              <div class="line__info">
                <button class="line__name" type="button" @click="openProduct(item.productId)">
                  {{ [item.brandName, item.productName].filter(Boolean).join(' ') || '未命名商品' }}
                </button>
                <div class="line__tags">
                  <StatePill :label="itemType(item).label" :tone="itemType(item).tone" />
                  <span v-if="itemGrade(item)" class="line__meta">成色 {{ itemGrade(item) }}</span>
                </div>
                <SpecList class="line__spec" :entries="itemSpecs(item)" :columns="1" />
              </div>

              <div class="line__price">
                <PriceTag
                  :price="item.unitPrice"
                  :unit="Number(item.productType) === 3 ? '/天' : null"
                  :show-original="false"
                  size="sm"
                />
                <span class="line__qty tnum">×{{ item.quantity }}</span>
                <span class="line__amount money">{{ formatMoney(lineAmount(item)) }}</span>
              </div>
            </li>
          </ul>

          <dl class="totals">
            <div v-if="depositTotal > 0" class="totals__row">
              <dt>押金合计</dt>
              <dd class="tnum">{{ formatMoney(depositTotal) }}</dd>
            </div>
            <div class="totals__row">
              <dt>订单金额</dt>
              <dd class="tnum">{{ formatMoney(order.totalAmount) }}</dd>
            </div>
            <div class="totals__row">
              <dt>运费</dt>
              <dd class="tnum">{{ formatMoney(order.shippingFee ?? 0) }}</dd>
            </div>
            <div class="totals__row totals__row--strong">
              <dt>实付金额</dt>
              <dd class="money tnum">{{ formatMoney(order.payAmount ?? order.totalAmount) }}</dd>
            </div>
          </dl>
        </section>
      </div>

      <aside class="side-col">
        <!-- 处理 -->
        <section class="plate">
          <header class="plate__head">
            <h2 class="plate__title">本次要做的</h2>
          </header>
          <div class="plate__body stack">
            <p class="hint">{{ statusHint }}</p>

            <button
              v-if="statusCode === 1"
              class="btn btn--solid btn--block"
              type="button"
              :disabled="acting || missingReceiver.length > 0"
              @click="handleShip"
            >
              <AppIcon name="ship" size="14" />
              发货
            </button>
            <p v-if="statusCode === 1 && missingReceiver.length > 0" class="alert">
              收货信息缺少 {{ missingReceiver.join('、') }}，补全后才能发货。
            </p>

            <button
              v-if="statusCode === 9"
              class="btn btn--solid btn--block"
              type="button"
              :disabled="acting"
              @click="handleConfirmReturn"
            >
              <AppIcon name="check" size="14" />
              确认归还
            </button>

            <p v-if="statusCode !== 1 && statusCode !== 9" class="hint">
              现在不需要商家操作，状态变化会更新这一页。
            </p>
          </div>
        </section>

        <!-- 流程记录 -->
        <section class="plate">
          <header class="plate__head">
            <h2 class="plate__title">流程记录</h2>
          </header>
          <ol class="timeline">
            <li v-for="(node, index) in timeline" :key="node.title" class="node">
              <span class="node__dot" :class="{ 'node__dot--last': index === timeline.length - 1 }" />
              <div class="node__body">
                <p class="node__title">{{ node.title }}</p>
                <time class="node__time">{{ node.time }}</time>
                <p class="node__note">{{ node.note }}</p>
              </div>
            </li>
          </ol>
        </section>
      </aside>
    </div>
  </div>
</template>

<style scoped>
.page {
  padding-bottom: var(--space-8);
}

.layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 320px;
  gap: var(--gap-surface);
  align-items: start;
}

.main-col,
.side-col {
  display: flex;
  flex-direction: column;
  gap: var(--gap-surface);
  min-width: 0;
}

.plate__title {
  font-size: var(--text-base);
}

.head-note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.stack {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.hint {
  font-size: var(--text-sm);
  color: var(--ink-3);
  line-height: 1.65;
}

.alert {
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-sm);
  background: var(--signal-amber-wash);
  color: var(--signal-amber-deep);
  font-size: var(--text-xs);
  line-height: 1.6;
}

/* --- 订单项 -------------------------------------------------------------- */

.lines {
  margin: 0;
  padding: 0;
  list-style: none;
}

.line {
  display: flex;
  align-items: flex-start;
  gap: var(--space-4);
  padding: var(--space-4);
  border-bottom: var(--hairline);
}

.line__media {
  flex-shrink: 0;
  width: 76px;
  padding: 0;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: transparent;
  overflow: hidden;
  cursor: pointer;
}

.line__info {
  flex: 1;
  min-width: 0;
}

.line__name {
  padding: 0;
  border: none;
  background: transparent;
  text-align: left;
  font-size: var(--text-base);
  font-weight: 600;
  color: var(--ink-0);
  cursor: pointer;
}

.line__name:hover {
  color: var(--signal-amber-deep);
  text-decoration: underline;
}

.line__tags {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-top: 4px;
}

.line__meta {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.line__spec {
  margin-top: var(--space-2);
}

.line__spec :deep(.spec__row) {
  border-bottom: none;
  padding: 1px 0;
  grid-template-columns: 92px minmax(0, 1fr);
}

.line__price {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
  flex-shrink: 0;
  white-space: nowrap;
}

.line__qty {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.line__amount {
  font-size: var(--text-base);
}

/* --- 金额 ---------------------------------------------------------------- */

.totals {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  margin: 0;
  padding: var(--space-4);
  background: var(--paper-1);
  border-top: var(--hairline);
}

.totals__row {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: var(--space-4);
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.totals__row dd {
  margin: 0;
  font-weight: 500;
  color: var(--ink-1);
}

.totals__row--strong {
  padding-top: var(--space-2);
  border-top: var(--hairline);
  font-size: var(--text-base);
}

.totals__row--strong dd {
  font-size: var(--text-lg);
}

/* --- 流程记录 ------------------------------------------------------------ */

.timeline {
  margin: 0;
  padding: var(--space-4);
  list-style: none;
}

.node {
  position: relative;
  display: flex;
  gap: var(--space-3);
  padding-bottom: var(--space-4);
}

.node:last-child {
  padding-bottom: 0;
}

.node::before {
  content: '';
  position: absolute;
  left: 4px;
  top: 14px;
  bottom: 0;
  width: 1px;
  background: var(--line-2);
}

.node:last-child::before {
  display: none;
}

.node__dot {
  position: relative;
  z-index: 1;
  flex-shrink: 0;
  width: 9px;
  height: 9px;
  margin-top: 5px;
  border: 2px solid var(--line-2);
  border-radius: var(--radius-pill);
  background: var(--paper-0);
}

.node__dot--last {
  border-color: var(--ink-0);
  background: var(--ink-0);
}

.node__body {
  min-width: 0;
}

.node__title {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-0);
}

.node__time {
  display: block;
  font-size: var(--text-xs);
  color: var(--ink-3);
  font-variant-numeric: tabular-nums;
}

.node__note {
  margin-top: 2px;
  font-size: var(--text-xs);
  color: var(--ink-3);
  line-height: 1.6;
}

/* --- 骨架与控件 ---------------------------------------------------------- */

.ghost-card {
  height: 132px;
}

.ghost-card--tall {
  height: 260px;
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

.btn--block {
  width: 100%;
}

.btn:disabled {
  border-color: var(--line-2);
  background: var(--paper-2);
  color: var(--ink-4);
  cursor: not-allowed;
}

@media (max-width: 1080px) {
  .layout {
    grid-template-columns: minmax(0, 1fr);
  }
  .side-col {
    order: -1;
  }
}

@media (max-width: 640px) {
  .line {
    flex-wrap: wrap;
    gap: var(--space-3);
  }
  .line__price {
    align-items: flex-start;
    margin-left: auto;
  }
  .line__spec :deep(.spec__row) {
    grid-template-columns: 84px minmax(0, 1fr);
  }
}
</style>
