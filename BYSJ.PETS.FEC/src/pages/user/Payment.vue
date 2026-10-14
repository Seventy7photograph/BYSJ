<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { cancelOrder, getOrderDetail, payOrder } from '@/api/user/order'
import { labelOf, ORDER_STATUS } from '@/constants/domain'
import { formatDateTime, formatMoney } from '@/utils/format'
import { useUserStore } from '@/stores/user'

/**
 * 支付订单。
 *
 * 原页面的「扫码支付」用的是 picsum 随机图，点「立即支付」其实已经调用了后端
 * 支付接口，但页面还要再点一次「我已支付完成」才会置为成功，中间还有一个空轮询；
 * 取消订单只弹了一句「订单已取消」，后端根本没有被调用。这里改成一个诚实的
 * 确认页：调用后端支付接口 → 后端返回结果 → 展示结果。
 *
 * 路由参数 paymentId 就是订单 ID（后端 simulatePay 也把 paymentId 返回成 orderId）。
 */
const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const PAYMENTS = [
  { value: 'wechat', label: '微信支付' },
  { value: 'alipay', label: '支付宝' },
] as const

const loading = ref(true)
const paying = ref(false)
const cancelling = ref(false)
const errorText = ref('')
const order = ref<Record<string, any> | null>(null)
const items = ref<any[]>([])
const paidAt = ref('')

const orderId = computed(() => String(route.params.paymentId ?? ''))
const paymentMethod = ref<string>(
  typeof route.query.paymentMethod === 'string' ? route.query.paymentMethod : 'wechat',
)

const status = computed(() => labelOf(ORDER_STATUS, Number(order.value?.orderStatus ?? -1)))
const isPayable = computed(() => Number(order.value?.orderStatus) === 0)
const paid = computed(
  () => Number(order.value?.orderStatus) >= 1 && Number(order.value?.orderStatus) <= 3,
)

const depositTotal = computed(() =>
  items.value.reduce(
    (sum, item) => sum + Number(item.deposit ?? 0) * Number(item.quantity ?? 0),
    0,
  ),
)
const goodsTotal = computed(() =>
  Math.max(0, Number(order.value?.totalAmount ?? 0) - depositTotal.value),
)

let requestToken = 0

async function loadOrder() {
  const token = ++requestToken
  loading.value = true
  errorText.value = ''
  try {
    const detail = await getOrderDetail(orderId.value)
    if (token !== requestToken) return
    if (!detail?.order) {
      errorText.value = '这笔订单查不到，可能已被取消或不属于当前账号。'
      order.value = null
      return
    }
    order.value = detail.order
    items.value = Array.isArray(detail.orderItems) ? detail.orderItems : []
    if (detail.order.paymentMethod && !route.query.paymentMethod) {
      paymentMethod.value = String(detail.order.paymentMethod)
    }
  } catch {
    if (token !== requestToken) return
    order.value = null
    errorText.value = '订单信息没有加载出来，可能是网络中断或登录状态已失效。'
  } finally {
    if (token === requestToken) loading.value = false
  }
}

async function handlePay() {
  if (paying.value || !order.value) return
  paying.value = true
  try {
    const result: any = await payOrder(Number(orderId.value), {
      paymentMethod: paymentMethod.value,
      addressId: order.value.addressId ?? undefined,
    })
    paidAt.value = String(result?.payTime ?? new Date().toISOString())
    await loadOrder()
    ElMessage.success('支付已完成')
  } catch {
    // 拦截器已提示后端原因（例如订单状态已不允许支付）
  } finally {
    paying.value = false
  }
}

async function handleCancel() {
  if (cancelling.value) return
  try {
    await ElMessageBox.confirm('取消后这笔订单不能恢复，需要重新下单。确定取消？', '取消订单', {
      confirmButtonText: '取消订单',
      cancelButtonText: '先不取消',
      type: 'warning',
    })
  } catch {
    return
  }
  cancelling.value = true
  try {
    await cancelOrder(Number(orderId.value))
    ElMessage.success('订单已取消')
    await loadOrder()
  } catch {
    // 拦截器已提示后端原因（例如只有待支付订单可以取消）
  } finally {
    cancelling.value = false
  }
}

onMounted(() => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录后再支付')
    void router.push({ path: '/login', query: { redirect: route.fullPath } })
    return
  }
  void loadOrder()
})
</script>

<template>
  <div class="shell page">
    <SectionHead title="支付订单" note="支付结果以平台记录为准">
      <template #action>
        <RouterLink class="link" to="/orders">我的订单</RouterLink>
      </template>
    </SectionHead>

    <el-steps :active="2" align-center class="steps">
      <el-step title="确认订单" />
      <el-step title="支付" />
      <el-step title="完成" />
    </el-steps>

    <div v-if="loading" class="panel" aria-busy="true">
      <div class="skeleton line line--sm" />
      <div class="skeleton line line--lg" />
      <div class="skeleton line" />
    </div>

    <EmptyState v-else-if="errorText" title="订单信息加载失败" :note="errorText">
      <button class="btn" type="button" @click="loadOrder()">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
      <RouterLink class="btn btn--ghost" to="/orders">返回我的订单</RouterLink>
    </EmptyState>

    <div v-else-if="order" class="grid">
      <section class="plate panel">
        <header class="panel__head">
          <h2 class="panel__title">订单信息</h2>
          <StatePill :label="status.label" :tone="status.tone" />
        </header>
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
            <dt>商品件数</dt>
            <dd>{{ items.reduce((sum, item) => sum + Number(item.quantity ?? 0), 0) }} 件</dd>
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

        <div v-if="paid" class="callout callout--ok">
          <AppIcon name="check-circle" size="16" />
          <div>
            <p class="callout__title">这笔订单已经支付完成</p>
            <p class="callout__note">
              {{ paidAt ? formatDateTime(paidAt) : '等待商家发货，可在订单详情里跟进。' }}
            </p>
          </div>
        </div>

        <div v-else-if="!isPayable" class="callout">
          <AppIcon name="info" size="16" />
          <div>
            <p class="callout__title">当前状态是「{{ status.label }}」，不能在这里支付</p>
            <p class="callout__note">
              如果订单已退款或已取消，可以重新下单；其他情况请到订单详情查看。
            </p>
          </div>
        </div>
      </section>

      <aside class="plate panel panel--pay">
        <header class="panel__head">
          <h2 class="panel__title">应付金额</h2>
        </header>
        <div class="pay">
          <dl class="amounts">
            <div class="amounts__row">
              <dt>商品金额</dt>
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
              <dt>应付金额</dt>
              <dd class="money">{{ formatMoney(order.payAmount) }}</dd>
            </div>
          </dl>

          <fieldset class="method" :disabled="!isPayable">
            <legend class="method__legend">支付方式</legend>
            <div class="seg">
              <button
                v-for="option in PAYMENTS"
                :key="option.value"
                class="seg__item"
                :class="{ 'is-active': paymentMethod === option.value }"
                type="button"
                :aria-pressed="paymentMethod === option.value"
                :disabled="!isPayable"
                @click="paymentMethod = option.value"
              >
                {{ option.label }}
              </button>
            </div>
          </fieldset>

          <button
            class="btn btn--solid btn--wide"
            type="button"
            :disabled="!isPayable || paying"
            @click="handlePay"
          >
            {{ paying ? '正在处理' : `确认支付 ${formatMoney(order.payAmount)}` }}
          </button>
          <button
            v-if="isPayable"
            class="btn btn--ghost btn--wide"
            type="button"
            :disabled="cancelling"
            @click="handleCancel"
          >
            取消订单
          </button>

          <div class="after">
            <RouterLink class="btn btn--wide" :to="`/order/detail/${order.orderId}`"
              >查看订单详情</RouterLink
            >
            <RouterLink class="link link--center" to="/shop">继续挑选器材</RouterLink>
          </div>
        </div>
      </aside>
    </div>
  </div>
</template>

<style scoped>
.page {
  padding-bottom: var(--space-8);
}

.steps {
  max-width: 560px;
  margin: 0 auto var(--space-6);
}

.grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(300px, 380px);
  gap: var(--space-5);
  align-items: start;
}

.panel {
  padding: var(--space-4);
}

.panel--pay {
  position: sticky;
  top: calc(var(--space-16) + var(--space-4));
}

.panel__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  padding-bottom: var(--space-3);
  border-bottom: var(--hairline);
  margin-bottom: var(--space-3);
}

.panel__title {
  font-size: var(--text-base);
  font-weight: 600;
}

/* --- 事实表 --------------------------------------------------------------- */

.facts {
  margin: 0;
}

.facts__row {
  display: grid;
  grid-template-columns: 96px minmax(0, 1fr);
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
  word-break: break-all;
}

/* --- 提示条 --------------------------------------------------------------- */

.callout {
  display: flex;
  gap: var(--space-3);
  margin-top: var(--space-4);
  padding: var(--space-3);
  border-radius: var(--radius-sm);
  background: var(--paper-1);
  color: var(--ink-2);
}

.callout--ok {
  background: var(--signal-teal-wash);
  color: var(--signal-teal-deep);
}

.callout__title {
  font-size: var(--text-sm);
  font-weight: 600;
}

.callout__note {
  font-size: var(--text-xs);
  margin-top: 2px;
}

/* --- 支付区 --------------------------------------------------------------- */

.amounts {
  margin: 0 0 var(--space-4);
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

.method {
  margin: 0 0 var(--space-4);
  padding: 0;
  border: none;
}

.method__legend {
  padding: 0;
  margin-bottom: var(--space-2);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.seg {
  display: grid;
  grid-auto-flow: column;
  grid-auto-columns: minmax(0, 1fr);
  gap: var(--space-2);
}

.seg__item {
  height: var(--control-h);
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  font-size: var(--text-sm);
  color: var(--ink-2);
  cursor: pointer;
}

.seg__item:hover:not(:disabled) {
  border-color: var(--ink-4);
}

.seg__item.is-active {
  border-color: var(--ink-0);
  background: var(--ink-0);
  color: var(--on-ink);
  font-weight: 600;
}

.seg__item:disabled {
  background: var(--paper-2);
  color: var(--ink-4);
  cursor: not-allowed;
}

.pay {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.after {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  margin-top: var(--space-3);
  padding-top: var(--space-3);
  border-top: var(--hairline);
}

/* --- 通用件 --------------------------------------------------------------- */

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

.btn--wide {
  width: 100%;
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

.link--center {
  text-align: center;
}

.line {
  height: 14px;
  border-radius: var(--radius-xs);
  margin-bottom: var(--space-3);
}

.line--sm {
  width: 30%;
}

.line--lg {
  height: 28px;
  width: 45%;
}

@media (max-width: 900px) {
  .grid {
    grid-template-columns: minmax(0, 1fr);
  }
  .panel--pay {
    position: static;
  }
}

@media (max-width: 520px) {
  .facts__row {
    grid-template-columns: minmax(0, 1fr);
    gap: 2px;
  }
}
</style>
