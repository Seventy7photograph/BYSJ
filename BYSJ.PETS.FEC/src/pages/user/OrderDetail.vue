<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from '@/axios'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { confirmReceive, getOrderDetail, returnRental } from '@/api/user/order'
import evaluationApi from '@/api/user/evaluation'
import { conditionLabel, labelOf, ORDER_STATUS, PRODUCT_TYPE, type Tone } from '@/constants/domain'
import { formatDateTime, formatMoney, maskPhone } from '@/utils/format'
import { useUserStore } from '@/stores/user'

/**
 * 订单详情。
 *
 * 原页面有一整套假数据：写着「包裹正在派送中 2025-12-25 14:30」的固定物流记录、
 * 后端并不存在的取货方式/归还方式、永远取不到的 refundInfo（多读了一层 .data.data）。
 * 这里只保留站内真实存在的信息：订单快照、订单项、状态、支付流水，以及按真实
 * 时间字段生成的流程记录；退款信息按后端实际返回结构读取。
 */
const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

interface OrderItem {
  itemId?: number | null
  productId: number
  productName?: string | null
  productImage?: string | null
  unitPrice: number | string
  quantity: number
  productType?: number | null
  condition?: number | null
  deposit?: number | string | null
  leaseTerm?: number | null
  brandName?: string | null
}

const STATUS_HINT: Record<number, string> = {
  0: '支付完成后商家才会开始备货。',
  1: '商家正在备货，发货后流程记录会有新的节点。',
  2: '收到器材后请在本页确认收货，确认后订单才继续流转。',
  3: '交易已完成，可以对这个器材发表评价。',
  4: '订单已关闭，需要的话可以重新下单。',
  5: '退款申请已提交，平台正在处理。',
  6: '退款已原路退回，到账时间以银行为准。',
  7: '退款未通过，可以查看退款原因或联系商家。',
  8: '租期内的器材请按期归还，逾期会产生违约金。',
  9: '商家正在确认归还，确认后会按规则退还押金。',
}

const REFUND_STATUS: Record<number, { label: string; tone: Tone }> = {
  0: { label: '退款处理中', tone: 'amber' },
  1: { label: '退款成功', tone: 'teal' },
  2: { label: '退款失败', tone: 'vermilion' },
}

const PAYMENT_METHOD: Record<string, string> = {
  wechat: '微信支付',
  alipay: '支付宝',
  online: '在线支付',
}

const loading = ref(true)
const errorText = ref('')
const order = ref<Record<string, any> | null>(null)
const items = ref<OrderItem[]>([])
const refund = ref<Record<string, any> | null>(null)
const acting = ref(false)
const evaluated = ref(false)
const evaluating = ref(false)
const evaluationVisible = ref(false)
const evaluationTarget = ref<OrderItem | null>(null)
const evaluationForm = ref({
  score: 5,
  qualityScore: 5,
  serviceScore: 5,
  logisticsScore: 5,
  content: '',
})
const evaluationError = ref('')

const orderId = computed(() => String(route.params.orderId ?? ''))
const statusCode = computed(() => Number(order.value?.orderStatus ?? -1))
const status = computed(() => labelOf(ORDER_STATUS, statusCode.value))
const statusHint = computed(
  () => STATUS_HINT[statusCode.value] ?? '订单状态已更新，若有疑问可以联系商家。',
)
const isRentalOrder = computed(() => items.value.some((item) => Number(item.productType) === 3))

/**
 * 订单实际的租赁天数。
 *
 * 后端 order_item.lease_term 这一列没有被写进库（insertBatch 漏掉了它），
 * 订单接口返回的 leaseTerm 因此恒为 null。用金额反推可以精确还原：
 * 租金 = 订单总额 - 押金合计 = Σ(单价 × 数量) × 天数。
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

const fullAddress = computed(() => {
  const data = order.value
  if (!data) return ''
  return `${data.province ?? ''}${data.city ?? ''}${data.district ?? ''}${data.detail ?? ''}`
})

const depositTotal = computed(() =>
  items.value.reduce(
    (sum, item) => sum + Number(item.deposit ?? 0) * Number(item.quantity ?? 0),
    0,
  ),
)
const goodsTotal = computed(() =>
  Math.max(0, Number(order.value?.totalAmount ?? 0) - depositTotal.value),
)

const refundStatus = computed(() =>
  labelOf(REFUND_STATUS, Number(refund.value?.refundStatus ?? -1), '退款'),
)

/** 流程记录只陈述有据可查的节点，不编造物流轨迹。 */
const timeline = computed(() => {
  const data = order.value
  if (!data) return []
  const nodes: { title: string; time: string; note: string; done: boolean }[] = [
    {
      title: '订单已创建',
      time: formatDateTime(data.createTime),
      note: `订单号 ${data.orderNo}`,
      done: true,
    },
  ]
  if (data.payTime) {
    nodes.push({
      title: '支付完成',
      time: formatDateTime(data.payTime),
      note: data.transactionId ? `流水号 ${data.transactionId}` : '已收到付款',
      done: true,
    })
  }
  nodes.push({
    title: `当前状态：${status.value.label}`,
    time: formatDateTime(data.updateTime),
    note: statusHint.value,
    done: statusCode.value !== 0,
  })
  return nodes
})

function itemTypeLabel(item: OrderItem) {
  return labelOf(PRODUCT_TYPE, Number(item.productType ?? 1))
}

function itemGrade(item: OrderItem): string | null {
  return Number(item.productType) === 1 ? null : conditionLabel(item.condition)
}

function lineAmount(item: OrderItem): number {
  const unit = Number(item.unitPrice ?? 0)
  const quantity = Number(item.quantity ?? 0)
  const days = Number(item.productType) > 2 ? Math.max(1, rentalDays.value) : 1
  return unit * quantity * days
}

function paymentText(method: unknown): string {
  return PAYMENT_METHOD[String(method ?? '')] ?? '未支付'
}

/* --- 数据加载 ------------------------------------------------------------- */

let requestToken = 0

async function loadDetail() {
  const token = ++requestToken
  loading.value = true
  errorText.value = ''
  try {
    const detail = await getOrderDetail(orderId.value)
    if (token !== requestToken) return
    if (!detail?.order) {
      order.value = null
      errorText.value = '这笔订单查不到，可能已被取消或不属于当前账号。'
      return
    }
    order.value = detail.order
    items.value = Array.isArray(detail.orderItems) ? detail.orderItems : []
    await Promise.all([loadRefund(), loadEvaluated()])
  } catch {
    if (token !== requestToken) return
    order.value = null
    errorText.value = '订单详情没有加载出来，可能是网络中断或登录状态已失效。'
  } finally {
    if (token === requestToken) loading.value = false
  }
}

async function loadRefund() {
  const code = Number(order.value?.orderStatus)
  if (![5, 6, 7].includes(code)) {
    refund.value = null
    return
  }
  try {
    const res: any = await axios.get(`/refunds/order/${orderId.value}`)
    refund.value = res?.refund ?? res?.data?.refund ?? null
  } catch {
    refund.value = null
  }
}

async function loadEvaluated() {
  evaluated.value = false
  if (Number(order.value?.orderStatus) !== 3) return
  try {
    const list = await evaluationApi.getUserEvaluations()
    if (!Array.isArray(list)) return
    evaluated.value = list.some((item: any) => Number(item?.orderId) === Number(orderId.value))
  } catch {
    evaluated.value = false
  }
}

onMounted(() => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录后查看订单')
    void router.push({ path: '/login', query: { redirect: route.fullPath } })
    return
  }
  void loadDetail()
})

/* --- 订单动作 ------------------------------------------------------------- */

async function handleConfirmReceive() {
  const message = isRentalOrder.value
    ? '确认已收到器材？确认后订单进入租赁中，租期开始计算。'
    : '确认已收到器材？确认后订单将标记为已完成。'
  try {
    await ElMessageBox.confirm(message, '确认收货', {
      confirmButtonText: '确认收货',
      cancelButtonText: '还没收到',
      type: 'warning',
    })
  } catch {
    return
  }
  acting.value = true
  try {
    await confirmReceive(Number(orderId.value))
    ElMessage.success('已确认收货')
    await loadDetail()
  } catch {
    // 拦截器已提示后端原因
  } finally {
    acting.value = false
  }
}

async function handleReturn() {
  try {
    await ElMessageBox.confirm(
      '发起归还后请按商家指引寄回器材，商家确认收货后押金按规则退还。确定发起归还？',
      '归还器材',
      { confirmButtonText: '发起归还', cancelButtonText: '取消', type: 'warning' },
    )
  } catch {
    return
  }
  acting.value = true
  try {
    await returnRental(Number(orderId.value))
    ElMessage.success('已提交归还，等待商家确认')
    await loadDetail()
  } catch {
    // 拦截器已提示后端原因
  } finally {
    acting.value = false
  }
}

function openEvaluation(item?: OrderItem) {
  if (!item) return
  evaluationTarget.value = item
  evaluationError.value = ''
  evaluationForm.value = {
    score: 5,
    qualityScore: 5,
    serviceScore: 5,
    logisticsScore: 5,
    content: '',
  }
  evaluationVisible.value = true
}

async function submitEvaluation() {
  const target = evaluationTarget.value
  if (!target || evaluating.value) return
  const content = evaluationForm.value.content.trim()
  if (content.length < 5) {
    evaluationError.value = '评价内容请至少写 5 个字，说明器材成色或商家服务。'
    return
  }
  evaluationError.value = ''
  evaluating.value = true
  try {
    await evaluationApi.submitEvaluation({
      orderId: Number(orderId.value),
      productId: Number(target.productId),
      score: evaluationForm.value.score,
      qualityScore: evaluationForm.value.qualityScore,
      serviceScore: evaluationForm.value.serviceScore,
      logisticsScore: isRentalOrder.value ? undefined : evaluationForm.value.logisticsScore,
      content,
    })
    ElMessage.success('评价已提交')
    evaluationVisible.value = false
    evaluated.value = true
  } catch {
    // 拦截器已提示后端原因
  } finally {
    evaluating.value = false
  }
}

function goPay() {
  void router.push({
    path: `/order/payment/${orderId.value}`,
    query: { paymentMethod: String(order.value?.paymentMethod ?? 'wechat') },
  })
}
</script>

<template>
  <div class="shell page">
    <SectionHead title="订单详情" :note="order ? `订单号 ${order.orderNo}` : '正在读取订单'">
      <template #action>
        <RouterLink class="link" to="/orders">
          <AppIcon name="chevron-left" size="13" />
          我的订单
        </RouterLink>
      </template>
    </SectionHead>

    <div v-if="loading" class="stack" aria-busy="true">
      <div class="skeleton block skeleton--sm" />
      <div class="skeleton block" />
    </div>

    <EmptyState v-else-if="errorText" title="订单详情加载失败" :note="errorText">
      <button class="btn" type="button" @click="loadDetail()">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
      <RouterLink class="btn btn--ghost" to="/orders">返回我的订单</RouterLink>
    </EmptyState>

    <div v-else-if="order" class="stack">
      <!-- 状态 -->
      <section class="plate banner">
        <div class="banner__head">
          <StatePill :label="status.label" :tone="status.tone" />
          <span class="banner__time">最近更新 {{ formatDateTime(order.updateTime) }}</span>
        </div>
        <p class="banner__hint">{{ statusHint }}</p>
        <div v-if="isRentalOrder && rentalDays > 0" class="banner__meta">
          租期 {{ rentalDays }} 天，起算时间以平台记录收货为准；逾期按商家规则计收违约金
        </div>
        <div class="banner__actions">
          <button v-if="statusCode === 0" class="btn btn--solid" type="button" @click="goPay">
            <AppIcon name="card" size="15" />
            立即支付
          </button>
          <button
            v-if="statusCode === 2"
            class="btn btn--solid"
            type="button"
            :disabled="acting"
            @click="handleConfirmReceive"
          >
            <AppIcon name="check" size="15" />
            确认收货
          </button>
          <button
            v-if="statusCode === 8"
            class="btn btn--solid"
            type="button"
            :disabled="acting"
            @click="handleReturn"
          >
            <AppIcon name="ship" size="15" />
            归还器材
          </button>
          <button
            v-if="statusCode === 3 && !evaluated && items.length"
            class="btn"
            type="button"
            @click="openEvaluation(items[0])"
          >
            <AppIcon name="star" size="15" />
            评价器材
          </button>
          <span v-else-if="statusCode === 3" class="btn btn--disabled">已评价</span>
        </div>
      </section>

      <div class="grid">
        <div class="stack">
          <!-- 商品 -->
          <section class="plate">
            <header class="block__head">
              <h2 class="block__title">商品信息</h2>
              <span class="block__note">共 {{ items.length }} 种器材</span>
            </header>
            <div class="block__body items">
              <article v-for="item in items" :key="item.productId" class="item">
                <div class="item__media">
                  <ImageFrame
                    :src="item.productImage"
                    :alt="item.productName ?? '商品图'"
                    ratio="1 / 1"
                  />
                </div>
                <div class="item__info">
                  <div class="item__title">
                    <RouterLink class="item__name" :to="`/product/${item.productId}`">
                      {{ item.productName || '未命名商品' }}
                    </RouterLink>
                    <StatePill
                      :label="itemTypeLabel(item).label"
                      :tone="itemTypeLabel(item).tone"
                    />
                  </div>
                  <p class="item__meta">
                    <span v-if="item.brandName">{{ item.brandName }}</span>
                    <span v-if="itemGrade(item)">成色 {{ itemGrade(item) }}</span>
                    <span>数量 {{ item.quantity }}</span>
                    <span v-if="Number(item.productType) === 3 && rentalDays > 0"
                      >租期 {{ rentalDays }} 天</span
                    >
                    <span v-if="Number(item.deposit) > 0">
                      押金 {{ formatMoney(Number(item.deposit) * Number(item.quantity)) }}
                    </span>
                  </p>
                </div>
                <div class="item__amount">
                  <span class="item__unit-price">
                    {{ formatMoney(item.unitPrice) }}
                    <span v-if="Number(item.productType) === 3" class="item__unit">/天</span>
                  </span>
                  <span class="item__line money">{{ formatMoney(lineAmount(item)) }}</span>
                </div>
              </article>
              <EmptyState
                v-if="!items.length"
                title="没有订单项"
                note="这笔订单没有可展示的商品明细，如有疑问请联系商家。"
              />
            </div>
          </section>

          <!-- 流程 -->
          <section class="plate">
            <header class="block__head">
              <h2 class="block__title">流程记录</h2>
              <span class="block__note">按订单时间字段生成</span>
            </header>
            <div class="block__body">
              <el-timeline>
                <el-timeline-item
                  v-for="node in timeline"
                  :key="node.title"
                  :timestamp="node.time"
                  :type="node.done ? 'primary' : 'info'"
                >
                  <p class="node__title">{{ node.title }}</p>
                  <p class="node__note">{{ node.note }}</p>
                </el-timeline-item>
              </el-timeline>
            </div>
          </section>
        </div>

        <div class="stack">
          <!-- 订单事实 -->
          <section class="plate">
            <header class="block__head">
              <h2 class="block__title">订单信息</h2>
            </header>
            <div class="block__body">
              <dl class="facts">
                <div class="facts__row">
                  <dt>订单号</dt>
                  <dd class="mono">{{ order.orderNo }}</dd>
                </div>
                <div class="facts__row">
                  <dt>下单时间</dt>
                  <dd>{{ formatDateTime(order.createTime) }}</dd>
                </div>
                <div class="facts__row">
                  <dt>支付方式</dt>
                  <dd>{{ paymentText(order.paymentMethod) }}</dd>
                </div>
                <div v-if="order.payTime" class="facts__row">
                  <dt>支付时间</dt>
                  <dd>{{ formatDateTime(order.payTime) }}</dd>
                </div>
                <div v-if="order.transactionId" class="facts__row">
                  <dt>支付流水号</dt>
                  <dd class="mono">{{ order.transactionId }}</dd>
                </div>
              </dl>
            </div>
          </section>

          <!-- 收货信息 -->
          <section class="plate">
            <header class="block__head">
              <h2 class="block__title">收货信息</h2>
            </header>
            <div class="block__body">
              <p class="addr__name">
                {{ order.recipient }}
                <span class="addr__phone">{{ maskPhone(order.phone) }}</span>
              </p>
              <p class="addr__text">{{ fullAddress }}</p>
            </div>
          </section>

          <!-- 金额 -->
          <section class="plate">
            <header class="block__head">
              <h2 class="block__title">金额信息</h2>
            </header>
            <div class="block__body">
              <dl class="amounts">
                <div class="amounts__row">
                  <dt>{{ isRentalOrder ? '租金合计' : '商品金额' }}</dt>
                  <dd>{{ formatMoney(goodsTotal) }}</dd>
                </div>
                <div v-if="depositTotal > 0" class="amounts__row">
                  <dt>押金合计</dt>
                  <dd>{{ formatMoney(depositTotal) }}</dd>
                </div>
                <div class="amounts__row">
                  <dt>运费</dt>
                  <dd>{{ formatMoney(order.shippingFee) }}</dd>
                </div>
                <div class="amounts__row amounts__row--total">
                  <dt>实付金额</dt>
                  <dd class="money">{{ formatMoney(order.payAmount) }}</dd>
                </div>
              </dl>
            </div>
          </section>

          <!-- 退款 -->
          <section v-if="refund" class="plate">
            <header class="block__head">
              <h2 class="block__title">退款信息</h2>
              <StatePill :label="refundStatus.label || '退款'" :tone="refundStatus.tone" />
            </header>
            <div class="block__body">
              <dl class="facts">
                <div class="facts__row">
                  <dt>退款金额</dt>
                  <dd>{{ formatMoney(refund.refundAmount) }}</dd>
                </div>
                <div class="facts__row">
                  <dt>申请原因</dt>
                  <dd>{{ refund.refundReason || '—' }}</dd>
                </div>
                <div v-if="refund.refundDescription" class="facts__row">
                  <dt>补充说明</dt>
                  <dd>{{ refund.refundDescription }}</dd>
                </div>
                <div v-if="refund.createTime" class="facts__row">
                  <dt>申请时间</dt>
                  <dd>{{ formatDateTime(refund.createTime) }}</dd>
                </div>
              </dl>
            </div>
          </section>
        </div>
      </div>
    </div>

    <!-- 评价 -->
    <el-dialog v-model="evaluationVisible" title="评价器材" width="520px">
      <div v-if="evaluationTarget" class="eval">
        <div class="eval__product">
          <div class="eval__media">
            <ImageFrame
              :src="evaluationTarget.productImage"
              :alt="evaluationTarget.productName ?? '商品图'"
              ratio="1 / 1"
            />
          </div>
          <div>
            <p class="eval__name">{{ evaluationTarget.productName }}</p>
            <p class="eval__price">{{ formatMoney(evaluationTarget.unitPrice) }}</p>
          </div>
        </div>

        <div v-if="items.length > 1" class="eval__field eval__field--block">
          <span class="eval__label">评价哪件器材</span>
          <div class="eval__picker">
            <button
              v-for="item in items"
              :key="item.productId"
              class="picker__item"
              :class="{ 'is-active': evaluationTarget?.productId === item.productId }"
              type="button"
              @click="evaluationTarget = item"
            >
              {{ item.productName || '未命名商品' }}
            </button>
          </div>
          <span class="eval__note">一笔订单只能提交一次评价，评价会挂在所选器材下。</span>
        </div>

        <div class="eval__field">
          <span class="eval__label">综合评分</span>
          <el-rate v-model="evaluationForm.score" />
        </div>
        <div class="eval__field">
          <span class="eval__label">器材质量</span>
          <el-rate v-model="evaluationForm.qualityScore" />
        </div>
        <div class="eval__field">
          <span class="eval__label">商家服务</span>
          <el-rate v-model="evaluationForm.serviceScore" />
        </div>
        <div v-if="!isRentalOrder" class="eval__field">
          <span class="eval__label">物流速度</span>
          <el-rate v-model="evaluationForm.logisticsScore" />
        </div>
        <label class="eval__field eval__field--block">
          <span class="eval__label">评价内容</span>
          <el-input
            v-model="evaluationForm.content"
            type="textarea"
            :rows="4"
            maxlength="500"
            show-word-limit
            placeholder="写下器材成色、配件完整度或商家服务的实际情况"
          />
          <span v-if="evaluationError" class="eval__error">{{ evaluationError }}</span>
        </label>
      </div>
      <template #footer>
        <div class="dialog-foot">
          <button class="btn btn--ghost" type="button" @click="evaluationVisible = false">
            取消
          </button>
          <button
            class="btn btn--solid"
            type="button"
            :disabled="evaluating"
            @click="submitEvaluation"
          >
            提交评价
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
  min-width: 0;
}

.grid {
  display: grid;
  grid-template-columns: minmax(0, 1.4fr) minmax(300px, 1fr);
  gap: var(--space-4);
  align-items: start;
}

/* --- 状态条 --------------------------------------------------------------- */

.banner {
  padding: var(--space-4);
}

.banner__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
}

.banner__time {
  font-size: var(--text-xs);
  color: var(--ink-4);
}

.banner__hint {
  margin-top: var(--space-2);
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.banner__meta {
  margin-top: var(--space-1);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.banner__actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  margin-top: var(--space-4);
}

/* --- 区块 ----------------------------------------------------------------- */

.block__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  border-bottom: var(--hairline);
}

.block__title {
  font-size: var(--text-base);
  font-weight: 600;
}

.block__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.block__body {
  padding: var(--space-4);
}

/* --- 商品行 --------------------------------------------------------------- */

.items {
  padding: 0 var(--space-4);
}

.item {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  padding: var(--space-4) 0;
  border-bottom: var(--hairline);
}

.item:last-child {
  border-bottom: none;
}

.item__media {
  width: 72px;
  flex-shrink: 0;
  border: var(--edge);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.item__info {
  flex: 1;
  min-width: 0;
}

.item__title {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-2);
}

.item__name {
  font-size: var(--text-base);
  font-weight: 600;
  color: var(--ink-0);
  text-decoration: none;
}

.item__name:hover {
  color: var(--signal-amber-deep);
}

.item__meta {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-3);
  margin-top: 2px;
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.item__amount {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
  white-space: nowrap;
}

.item__unit-price {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.item__unit {
  color: var(--ink-4);
}

.item__line {
  font-size: var(--text-base);
}

/* --- 流程 ----------------------------------------------------------------- */

.node__title {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-1);
}

.node__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

/* --- 事实表 / 金额 -------------------------------------------------------- */

.facts {
  margin: 0;
}

.facts__row {
  display: grid;
  grid-template-columns: 88px minmax(0, 1fr);
  gap: var(--space-3);
  align-items: baseline;
  padding: var(--space-2) 0;
  border-bottom: var(--hairline);
}

.facts__row:last-child {
  border-bottom: none;
}

.facts__row dt {
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.facts__row dd {
  margin: 0;
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--ink-1);
  word-break: break-word;
}

.addr__name {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: var(--space-2);
  font-size: var(--text-base);
  font-weight: 600;
  color: var(--ink-0);
}

.addr__phone {
  font-size: var(--text-sm);
  font-weight: 400;
  color: var(--ink-3);
}

.addr__text {
  margin-top: 2px;
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.amounts {
  margin: 0;
}

.amounts__row {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: var(--space-3);
  padding: var(--space-1) 0;
  font-size: var(--text-sm);
}

.amounts__row dt {
  color: var(--ink-3);
}

.amounts__row dd {
  margin: 0;
  color: var(--ink-1);
}

.amounts__row--total {
  margin-top: var(--space-2);
  padding-top: var(--space-3);
  border-top: var(--hairline);
}

.amounts__row--total dd {
  font-size: var(--text-lg);
  font-weight: 600;
}

/* --- 评价弹窗 ------------------------------------------------------------- */

.eval {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.eval__product {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3);
  background: var(--paper-1);
  border-radius: var(--radius-sm);
}

.eval__media {
  width: 56px;
  flex-shrink: 0;
  border: var(--edge);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.eval__name {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-0);
}

.eval__price {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.eval__field {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.eval__field--block {
  display: flex;
  flex-direction: column;
  align-items: stretch;
  gap: 6px;
}

.eval__label {
  min-width: 72px;
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.eval__error {
  font-size: var(--text-xs);
  color: var(--signal-vermilion-deep);
}

.eval__picker {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.picker__item {
  padding: 5px 10px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  font-size: var(--text-xs);
  color: var(--ink-2);
  cursor: pointer;
}

.picker__item:hover {
  border-color: var(--ink-4);
}

.picker__item.is-active {
  border-color: var(--ink-0);
  background: var(--paper-1);
  color: var(--ink-0);
  font-weight: 600;
}

.eval__note {
  font-size: var(--text-xs);
  color: var(--ink-4);
}

.dialog-foot {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}

:deep(.el-rate) {
  --el-rate-fill-color: var(--signal-amber);
  --el-rate-void-color: var(--paper-3);
  height: 20px;
}

/* --- 通用 ---------------------------------------------------------------- */

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: var(--control-h);
  padding-inline: 16px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  color: var(--ink-1);
  font-size: var(--text-base);
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

.btn--disabled {
  border-color: var(--line-2);
  background: var(--paper-2);
  color: var(--ink-4);
  cursor: default;
}

.btn:disabled {
  border-color: var(--line-2);
  background: var(--paper-2);
  color: var(--ink-4);
  cursor: not-allowed;
}

.link {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  font-size: var(--text-sm);
  color: var(--ink-2);
  text-decoration: none;
}

.link:hover {
  color: var(--signal-amber-deep);
}

.block {
  min-height: 88px;
}

.skeleton--sm {
  height: 108px;
}

@media (max-width: 900px) {
  .grid {
    grid-template-columns: minmax(0, 1fr);
  }
}

@media (max-width: 520px) {
  .item {
    flex-wrap: wrap;
    gap: var(--space-3);
  }
  .item__amount {
    align-items: flex-start;
    margin-left: auto;
  }
  .facts__row {
    grid-template-columns: minmax(0, 1fr);
    gap: 2px;
  }
}
</style>
