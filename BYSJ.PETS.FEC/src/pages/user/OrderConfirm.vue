<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { getProductDetail } from '@/api/user/shop'
import {
  cancelOrder,
  checkPendingOrder,
  createFromCart,
  createTempOrder,
  getOrderDetail,
} from '@/api/user/order'
import {
  addAddress,
  getAddressList,
  setDefaultAddress,
  updateAddress,
  type AddressItem,
} from '@/api/user/address'
import { labelOf, PRODUCT_TYPE } from '@/constants/domain'
import { formatMoney, maskPhone } from '@/utils/format'
import { useUserStore } from '@/stores/user'

/**
 * 确认订单。
 *
 * 原页面的问题是「控件比后端能力多」：取货方式、归还方式、租赁日期区间、逐项改
 * 数量，后端 create-from-cart 只认 productIds / quantity / leaseTerm，其余参数
 * 直接丢弃；从支付页返回修改还会重复下单。这里按后端真实能力重排：
 * 地址、租期、支付方式是真的；数量由购物车决定，租期终点由后端规则决定，
 * 页面只陈述不假装可改。金额一律来自后端（/orders/temp 或订单详情）。
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

const PAYMENTS = [
  { value: 'wechat', label: '微信支付' },
  { value: 'alipay', label: '支付宝' },
] as const

const loading = ref(true)
const quoting = ref(false)
const submitting = ref(false)
const errorText = ref('')
const items = ref<OrderItem[]>([])
const totalAmount = ref(0)
const shippingFee = ref(0)
const paymentMethod = ref<string>('wechat')
const requestedLeaseTerm = Number(route.query.leaseTerm)
const rentalDays = ref(
  Number.isFinite(requestedLeaseTerm) && requestedLeaseTerm > 0
    ? Math.floor(requestedLeaseTerm)
    : 1,
)

const addresses = ref<AddressItem[]>([])
const selectedAddressId = ref<number | null>(null)
const addressDialogVisible = ref(false)
const addressSaving = ref(false)
const editingAddressId = ref<number | null>(null)
const addressErrors = ref<Record<string, string>>({})
const addressForm = ref({
  recipient: '',
  phone: '',
  province: '',
  city: '',
  district: '',
  detail: '',
  isDefault: false,
})

/** 已创建的订单（从支付页返回修改时带着订单号进来）。 */
const existingOrderId = computed(() => {
  const raw = route.params.orderId ?? route.query.orderId
  return raw === undefined || raw === null || raw === '' ? '' : String(raw)
})
const isExistingOrder = computed(() => Boolean(existingOrderId.value))
const existingOrder = ref<Record<string, any> | null>(null)

const productIds = computed(() => {
  const raw = route.query.productIds
  const text = Array.isArray(raw) ? String(raw[0] ?? '') : String(raw ?? '')
  return text
    .split(',')
    .map((value) => Number(value.trim()))
    .filter((value) => Number.isFinite(value) && value > 0)
})

const buyQuantity = computed(() => {
  const value = Number(route.query.quantity)
  return Number.isFinite(value) && value > 0 ? Math.floor(value) : 1
})

const hasRental = computed(() => items.value.some((item) => Number(item.productType) === 3))
const selectedAddress = computed(
  () => addresses.value.find((item) => item.addressId === selectedAddressId.value) ?? null,
)
const defaultAddress = computed(
  () => addresses.value.find((item) => Number(item.isDefault) === 1) ?? null,
)
const needSwitchDefault = computed(
  () => Boolean(selectedAddress.value) && Number(selectedAddress.value?.isDefault) !== 1,
)

/** 押金按件计，与后端 create-from-cart 的口径一致（原价 * 10% * 数量）。 */
const depositTotal = computed(() =>
  items.value.reduce(
    (sum, item) => sum + Number(item.deposit ?? 0) * Number(item.quantity ?? 0),
    0,
  ),
)
const goodsTotal = computed(() => Math.max(0, totalAmount.value - depositTotal.value))
const payableTotal = computed(() => totalAmount.value + shippingFee.value)

/** 起租与最长租期来自商品详情；临时订单接口不返回这两个字段。 */
const minRentalDays = ref(1)
const maxRentalDays = ref(90)

/**
 * 从订单数据还原租赁天数。
 *
 * 后端 order_item.lease_term 没有被写进库（insertBatch 漏了这一列），订单接口
 * 返回的 leaseTerm 恒为 null；租金 = 订单总额 - 押金合计 = Σ(单价 × 数量) × 天数，
 * 所以天数可以精确反推。
 */
function rentalDaysFromOrder(data: Record<string, any> | null, rows: OrderItem[]): number {
  const direct = Number(rows.find((item) => Number(item.productType) === 3)?.leaseTerm ?? 0)
  if (direct > 0) return direct
  const base = rows.reduce(
    (sum, item) => sum + Number(item.unitPrice ?? 0) * Number(item.quantity ?? 0),
    0,
  )
  const deposit = rows.reduce(
    (sum, item) => sum + Number(item.deposit ?? 0) * Number(item.quantity ?? 0),
    0,
  )
  const rent = Number(data?.totalAmount ?? 0) - deposit
  if (base <= 0 || rent <= 0) return 0
  const days = rent / base
  return Number.isFinite(days) && days >= 1 ? Math.round(days) : 0
}

function typeOf(item: OrderItem) {
  return labelOf(PRODUCT_TYPE, Number(item.productType ?? 1))
}

function fullAddress(item: AddressItem): string {
  return `${item.province ?? ''}${item.city ?? ''}${item.district ?? ''}${item.detail ?? ''}`
}

/** 临时订单以 productIds 列表为准，productId 只是兼容封装签名的必填位。 */
function tempPayload(ids: number[], quantity: number, leaseTerm: number) {
  return {
    productId: ids[0] ?? 0,
    productIds: ids,
    quantity,
    leaseTerm,
  }
}

/* --- 数据加载 ------------------------------------------------------------- */

let requestToken = 0

async function loadAddresses() {
  try {
    const list = await getAddressList()
    addresses.value = Array.isArray(list) ? list : []
  } catch {
    addresses.value = []
  }
  const preferred =
    addresses.value.find((item) => item.addressId === selectedAddressId.value) ??
    defaultAddress.value ??
    addresses.value[0] ??
    null
  selectedAddressId.value = preferred?.addressId ?? null
}

async function loadQuote() {
  const token = ++requestToken
  loading.value = true
  errorText.value = ''
  try {
    if (isExistingOrder.value) {
      const detail = await getOrderDetail(existingOrderId.value)
      if (token !== requestToken) return
      const order = detail?.order ?? null
      if (!order) {
        errorText.value = '这笔订单查不到，可能已被取消或不属于当前账号。'
        items.value = []
        return
      }
      existingOrder.value = order
      items.value = Array.isArray(detail?.orderItems) ? detail.orderItems : []
      totalAmount.value = Number(order.totalAmount ?? 0)
      shippingFee.value = Number(order.shippingFee ?? 0)
      rentalDays.value = rentalDaysFromOrder(order, items.value) || 1
    } else {
      const ids = productIds.value
      if (!ids.length) {
        errorText.value = '没有拿到要结算的商品，返回购物车重新选择后再试。'
        items.value = []
        return
      }
      const quote = await createTempOrder(tempPayload(ids, buyQuantity.value, rentalDays.value))
      if (token !== requestToken) return
      items.value = Array.isArray(quote?.orderItems) ? quote.orderItems : []
      totalAmount.value = Number(quote?.totalAmount ?? 0)
      shippingFee.value = Number(quote?.shippingFee ?? 0)
      const rentalItem = items.value.find((item) => Number(item.productType) === 3)
      if (rentalItem?.leaseTerm) rentalDays.value = Number(rentalItem.leaseTerm)
      await applyRentalBounds()
    }
  } catch (error: any) {
    if (token !== requestToken) return
    items.value = []
    errorText.value =
      error?.msg ||
      '订单信息没有取到。若购物车里同时勾选了不同商家或租赁与其他类型的商品，请分开下单。'
  } finally {
    if (token === requestToken) loading.value = false
  }
}

/** 用商品详情里的起租天数校正租期，避免默认 1 天低于商家的起租要求。 */
async function applyRentalBounds() {
  const rentalItem = items.value.find((item) => Number(item.productType) === 3)
  if (!rentalItem || isExistingOrder.value) return
  try {
    const detail = await getProductDetail(rentalItem.productId)
    const min = Number(detail?.minRentalDays)
    const max = Number(detail?.maxRentalDays)
    if (Number.isFinite(min) && min > 0) minRentalDays.value = Math.floor(min)
    if (Number.isFinite(max) && max >= minRentalDays.value) maxRentalDays.value = Math.floor(max)
  } catch {
    // 取不到商品详情时保持默认区间，不影响下单
  }
  if (rentalDays.value < minRentalDays.value) {
    rentalDays.value = minRentalDays.value
    await loadQuote()
  }
}

/** 改租期后重新取价：金额始终以后端返回为准。 */
async function requote() {
  if (isExistingOrder.value || quoting.value) return
  quoting.value = true
  try {
    await loadQuote()
  } finally {
    quoting.value = false
  }
}

onMounted(async () => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录后再下单')
    void router.push({ path: '/login', query: { redirect: route.fullPath } })
    return
  }
  await Promise.all([loadAddresses(), loadQuote()])
})

/* --- 地址管理 ------------------------------------------------------------- */

function openAddressDialog(address?: AddressItem) {
  editingAddressId.value = address?.addressId ?? null
  addressForm.value = {
    recipient: address?.recipient ?? '',
    phone: address?.phone ?? '',
    province: address?.province ?? '',
    city: address?.city ?? '',
    district: address?.district ?? '',
    detail: address?.detail ?? '',
    isDefault: Number(address?.isDefault ?? 0) === 1,
  }
  addressErrors.value = {}
  addressDialogVisible.value = true
}

function validateAddressForm(): boolean {
  const errors: Record<string, string> = {}
  const form = addressForm.value
  if (!form.recipient.trim()) errors.recipient = '请填写收货人姓名'
  if (!form.phone.trim()) errors.phone = '请填写手机号'
  else if (!/^1[3-9]\d{9}$/.test(form.phone.trim())) errors.phone = '手机号需要是 11 位大陆号码'
  if (!form.province.trim() || !form.city.trim() || !form.district.trim()) {
    errors.region = '请填齐省、市、区'
  }
  if (!form.detail.trim()) errors.detail = '请填写详细地址，例如街道与门牌号'
  addressErrors.value = errors
  return Object.keys(errors).length === 0
}

async function saveAddress() {
  if (!validateAddressForm() || addressSaving.value) return
  addressSaving.value = true
  const form = addressForm.value
  const payload = {
    recipient: form.recipient.trim(),
    phone: form.phone.trim(),
    province: form.province.trim(),
    city: form.city.trim(),
    district: form.district.trim(),
    detail: form.detail.trim(),
    isDefault: form.isDefault ? 1 : 0,
  }
  try {
    if (editingAddressId.value) {
      await updateAddress({ addressId: editingAddressId.value, ...payload })
      ElMessage.success('收货地址已更新')
      addressDialogVisible.value = false
      await loadAddresses()
    } else {
      const created: any = await addAddress(payload)
      ElMessage.success('收货地址已添加')
      addressDialogVisible.value = false
      await loadAddresses()
      const newId = Number(created?.addressId ?? created?.data?.addressId)
      if (Number.isFinite(newId) && newId > 0) selectedAddressId.value = newId
    }
  } catch {
    // 拦截器已提示后端原因
  } finally {
    addressSaving.value = false
  }
}

/* --- 提交 ----------------------------------------------------------------- */

/** 已创建的订单是否与当前选择的租期一致，用于判断能否直接继续支付。 */
async function pendingOrderMatchesDays(orderId: number): Promise<boolean> {
  try {
    const detail = await getOrderDetail(orderId)
    const list: OrderItem[] = Array.isArray(detail?.orderItems) ? detail.orderItems : []
    const rentalItem = list.find((item) => Number(item.productType) === 3)
    if (!rentalItem) return true
    const days = rentalDaysFromOrder(detail?.order ?? null, list)
    return days === 0 || days === Number(rentalDays.value)
  } catch {
    return true
  }
}

async function submit() {
  if (submitting.value) return
  if (!isExistingOrder.value && !selectedAddressId.value) {
    ElMessage.warning('请先添加并选择收货地址')
    return
  }

  if (isExistingOrder.value) {
    void router.push({
      path: `/order/payment/${existingOrderId.value}`,
      query: { paymentMethod: paymentMethod.value },
    })
    return
  }

  const ids = items.value.map((item) => Number(item.productId)).filter((id) => id > 0)
  if (!ids.length) {
    ElMessage.error('没有可提交的商品，请返回购物车重新选择')
    return
  }

  submitting.value = true
  try {
    // 后端按下单时的默认地址快照收货，所以下单前先把所选地址设为默认地址
    if (needSwitchDefault.value && selectedAddress.value) {
      await setDefaultAddress(selectedAddress.value.addressId)
    }

    const pending: any = await checkPendingOrder(
      tempPayload(ids, buyQuantity.value, rentalDays.value),
    )
    const pendingId = Number(pending?.orderId ?? 0)
    if (pending?.hasPendingOrder && pendingId > 0) {
      const sameTerms = await pendingOrderMatchesDays(pendingId)
      if (pending.orderInfoMatches && sameTerms) {
        try {
          await ElMessageBox.confirm('你有一笔内容相同的未支付订单，直接继续支付？', '继续支付', {
            confirmButtonText: '继续支付',
            cancelButtonText: '取消',
            type: 'warning',
          })
        } catch {
          return
        }
        void router.push({
          path: `/order/payment/${pendingId}`,
          query: { paymentMethod: paymentMethod.value },
        })
        return
      }
      try {
        await ElMessageBox.confirm(
          '你有一笔未支付的订单，但商品或租期已经变化。取消旧订单并下新订单？',
          '订单内容已变化',
          { confirmButtonText: '取消旧订单并继续', cancelButtonText: '返回', type: 'warning' },
        )
      } catch {
        return
      }
      await cancelOrder(pendingId)
    }

    const created: any = await createFromCart({
      addressId: Number(selectedAddressId.value ?? 0),
      productIds: ids,
      quantity: buyQuantity.value,
      leaseTerm: rentalDays.value,
    })
    const orderId = Number(created?.orderId ?? 0)
    if (!orderId) {
      ElMessage.error('订单已提交，但没有拿到订单号，请到「我的订单」确认')
      void router.push('/orders')
      return
    }
    ElMessage.success('订单已创建，请完成支付')
    void router.push({
      path: `/order/payment/${orderId}`,
      query: { paymentMethod: paymentMethod.value },
    })
  } catch {
    // 拦截器已提示后端原因（例如库存不足、卖家不一致）
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="shell page">
    <SectionHead
      title="确认订单"
      :note="isExistingOrder ? '订单已创建，确认后可继续支付' : '核对收货信息与金额后提交订单'"
    >
      <template #action>
        <RouterLink class="link" to="/cart">
          <AppIcon name="chevron-left" size="13" />
          返回购物车
        </RouterLink>
      </template>
    </SectionHead>

    <el-steps :active="1" align-center class="steps">
      <el-step title="确认订单" />
      <el-step title="支付" />
      <el-step title="完成" />
    </el-steps>

    <div v-if="loading" class="layout" aria-busy="true">
      <div class="stack">
        <div class="skeleton block skeleton--sm" />
        <div class="skeleton block" />
      </div>
      <div class="skeleton block skeleton--tall" />
    </div>

    <EmptyState v-else-if="errorText" title="无法确认订单" :note="errorText">
      <RouterLink class="btn" to="/cart">返回购物车</RouterLink>
      <button class="btn btn--ghost" type="button" @click="loadQuote()">重新加载</button>
    </EmptyState>

    <div v-else class="layout">
      <div class="stack">
        <section class="plate">
          <header class="block__head">
            <h2 class="block__title">收货信息</h2>
            <RouterLink v-if="!isExistingOrder" class="link" to="/address">管理地址</RouterLink>
          </header>

          <div class="block__body">
            <template v-if="isExistingOrder && existingOrder">
              <p class="addr__name">
                {{ existingOrder.recipient }}
                <span class="addr__phone">{{ maskPhone(existingOrder.phone) }}</span>
              </p>
              <p class="addr__text">
                {{ existingOrder.province }}{{ existingOrder.city }}{{ existingOrder.district
                }}{{ existingOrder.detail }}
              </p>
            </template>

            <template v-else-if="addresses.length">
              <div class="addr-list">
                <button
                  v-for="item in addresses"
                  :key="item.addressId"
                  class="addr"
                  :class="{ 'is-active': selectedAddressId === item.addressId }"
                  type="button"
                  @click="selectedAddressId = item.addressId"
                >
                  <span class="addr__radio" aria-hidden="true" />
                  <span class="addr__body">
                    <span class="addr__name">
                      {{ item.recipient }}
                      <span class="addr__phone">{{ maskPhone(item.phone) }}</span>
                      <StatePill v-if="Number(item.isDefault) === 1" label="默认" tone="outline" />
                    </span>
                    <span class="addr__text">{{ fullAddress(item) }}</span>
                  </span>
                  <span
                    class="addr__edit"
                    role="button"
                    tabindex="0"
                    @click.stop="openAddressDialog(item)"
                    @keydown.enter.stop="openAddressDialog(item)"
                  >
                    编辑
                  </span>
                </button>
              </div>
              <p v-if="needSwitchDefault" class="hint">
                该地址不是默认地址，提交订单时会把它设为默认收货地址。
              </p>
            </template>

            <EmptyState
              v-else
              title="还没有收货地址"
              note="订单必须有一个收货地址，添加后就能继续下单。"
            />

            <button v-if="!isExistingOrder" class="btn" type="button" @click="openAddressDialog()">
              <AppIcon name="plus" size="14" />
              新增地址
            </button>
          </div>
        </section>

        <section v-if="hasRental" class="plate">
          <header class="block__head">
            <h2 class="block__title">租赁租期</h2>
            <span class="block__note"
              >最短 {{ minRentalDays }} 天，最长 {{ maxRentalDays }} 天</span
            >
          </header>
          <div class="block__body rent">
            <div class="rent__field">
              <span class="rent__label">租期（天）</span>
              <el-input-number
                v-model="rentalDays"
                :min="minRentalDays"
                :max="maxRentalDays"
                :disabled="isExistingOrder || quoting"
                @change="requote"
              />
            </div>
            <p class="hint">租期从平台记录收货当日起算，到期后按商家规则归还；续租请联系商家。</p>
          </div>
        </section>

        <section class="plate">
          <header class="block__head">
            <h2 class="block__title">商品清单</h2>
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
                  <span class="item__name">{{ item.productName || '未命名商品' }}</span>
                  <StatePill :label="typeOf(item).label" :tone="typeOf(item).tone" />
                </div>
                <p class="item__meta">
                  <span v-if="item.brandName">{{ item.brandName }}</span>
                  <span>数量 {{ item.quantity }}</span>
                  <span v-if="Number(item.productType) === 3">租期 {{ rentalDays }} 天</span>
                  <span v-if="Number(item.deposit) > 0">
                    押金 {{ formatMoney(Number(item.deposit) * Number(item.quantity)) }}
                  </span>
                </p>
                <p class="hint hint--tight">数量以购物车为准，需要修改请回到购物车调整。</p>
              </div>
              <div class="item__amount">
                <span class="money">{{ formatMoney(item.unitPrice) }}</span>
                <span v-if="Number(item.productType) === 3" class="item__unit">/天</span>
              </div>
            </article>
          </div>
        </section>
      </div>

      <aside class="summary plate">
        <header class="block__head">
          <h2 class="block__title">金额与支付</h2>
        </header>
        <div class="summary__body">
          <dl class="amounts">
            <div class="amounts__row">
              <dt>{{ hasRental ? '租金合计' : '商品金额' }}</dt>
              <dd>{{ formatMoney(goodsTotal) }}</dd>
            </div>
            <div v-if="depositTotal > 0" class="amounts__row">
              <dt>押金合计</dt>
              <dd>{{ formatMoney(depositTotal) }}</dd>
            </div>
            <div class="amounts__row">
              <dt>运费</dt>
              <dd>{{ formatMoney(shippingFee) }}</dd>
            </div>
            <div class="amounts__row amounts__row--total">
              <dt>应付金额</dt>
              <dd class="money">{{ formatMoney(payableTotal) }}</dd>
            </div>
          </dl>

          <p class="hint">金额由系统按下单商品实时计算，前端不做加减。</p>

          <fieldset class="pay">
            <legend class="pay__legend">支付方式</legend>
            <div class="seg">
              <button
                v-for="option in PAYMENTS"
                :key="option.value"
                class="seg__item"
                :class="{ 'is-active': paymentMethod === option.value }"
                type="button"
                :aria-pressed="paymentMethod === option.value"
                @click="paymentMethod = option.value"
              >
                {{ option.label }}
              </button>
            </div>
          </fieldset>

          <button
            class="btn btn--solid btn--wide"
            type="button"
            :disabled="submitting || (!isExistingOrder && !selectedAddressId)"
            @click="submit"
          >
            {{ isExistingOrder ? '继续支付' : '提交订单' }}
          </button>
          <p v-if="!isExistingOrder && !selectedAddressId" class="hint">
            需要先有一个收货地址才能提交订单。
          </p>
        </div>
      </aside>
    </div>

    <el-dialog
      v-model="addressDialogVisible"
      :title="editingAddressId ? '编辑收货地址' : '新增收货地址'"
      width="480px"
    >
      <div class="form">
        <label class="field">
          <span class="field__label">收货人</span>
          <el-input v-model="addressForm.recipient" placeholder="收货人姓名" maxlength="20" />
          <span v-if="addressErrors.recipient" class="field__error">{{
            addressErrors.recipient
          }}</span>
        </label>
        <label class="field">
          <span class="field__label">手机号</span>
          <el-input v-model="addressForm.phone" placeholder="11 位手机号" maxlength="11" />
          <span v-if="addressErrors.phone" class="field__error">{{ addressErrors.phone }}</span>
        </label>
        <div class="field">
          <span class="field__label">所在地区</span>
          <div class="field__region">
            <el-input v-model="addressForm.province" placeholder="省" maxlength="20" />
            <el-input v-model="addressForm.city" placeholder="市" maxlength="20" />
            <el-input v-model="addressForm.district" placeholder="区/县" maxlength="20" />
          </div>
          <span v-if="addressErrors.region" class="field__error">{{ addressErrors.region }}</span>
        </div>
        <label class="field">
          <span class="field__label">详细地址</span>
          <el-input
            v-model="addressForm.detail"
            type="textarea"
            :rows="3"
            maxlength="120"
            placeholder="街道、门牌号、楼层房间号"
          />
          <span v-if="addressErrors.detail" class="field__error">{{ addressErrors.detail }}</span>
        </label>
        <el-checkbox v-model="addressForm.isDefault">设为默认收货地址</el-checkbox>
      </div>
      <template #footer>
        <div class="dialog-foot">
          <button class="btn btn--ghost" type="button" @click="addressDialogVisible = false">
            取消
          </button>
          <button
            class="btn btn--solid"
            type="button"
            :disabled="addressSaving"
            @click="saveAddress"
          >
            保存
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

.steps {
  max-width: 560px;
  margin: 0 auto var(--space-6);
}

.layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(300px, 360px);
  gap: var(--space-5);
  align-items: start;
}

.stack {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  min-width: 0;
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
  color: var(--ink-0);
}

.block__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.block__body {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  padding: var(--space-4);
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

.hint {
  font-size: var(--text-xs);
  color: var(--ink-3);
  max-width: 60ch;
}

.hint--tight {
  margin-top: 2px;
}

/* --- 地址 ----------------------------------------------------------------- */

.addr-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.addr {
  display: flex;
  align-items: flex-start;
  gap: var(--space-3);
  width: 100%;
  padding: var(--space-3);
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  text-align: left;
  cursor: pointer;
  transition:
    border-color var(--dur-state) ease,
    background-color var(--dur-state) ease;
}

.addr:hover {
  border-color: var(--ink-4);
}

.addr.is-active {
  border-color: var(--ink-0);
  background: var(--paper-1);
}

.addr__radio {
  flex-shrink: 0;
  width: 14px;
  height: 14px;
  margin-top: 4px;
  border: 1px solid var(--line-2);
  border-radius: var(--radius-pill);
  background: var(--paper-0);
}

.addr.is-active .addr__radio {
  border-color: var(--ink-0);
  box-shadow:
    inset 0 0 0 3px var(--paper-0),
    inset 0 0 0 8px var(--ink-0);
}

.addr__body {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
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
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.addr__edit {
  margin-left: auto;
  padding: 2px 6px;
  border-radius: var(--radius-xs);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.addr__edit:hover,
.addr__edit:focus-visible {
  background: var(--paper-2);
  color: var(--ink-0);
}

/* --- 租期 ----------------------------------------------------------------- */

.rent {
  gap: var(--space-2);
}

.rent__field {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.rent__label {
  font-size: var(--text-sm);
  color: var(--ink-2);
}

/* --- 商品行 --------------------------------------------------------------- */

.items {
  gap: 0;
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
  align-items: baseline;
  gap: 2px;
  font-size: var(--text-base);
  white-space: nowrap;
}

.item__unit {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

/* --- 汇总 ----------------------------------------------------------------- */

.summary {
  position: sticky;
  top: calc(var(--space-16) + var(--space-4));
}

.summary__body {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  padding: var(--space-4);
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

.pay {
  margin: var(--space-2) 0 0;
  padding: 0;
  border: none;
}

.pay__legend {
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

.seg__item:hover {
  border-color: var(--ink-4);
}

.seg__item.is-active {
  border-color: var(--ink-0);
  background: var(--ink-0);
  color: var(--on-ink);
  font-weight: 600;
}

/* --- 弹窗表单 ------------------------------------------------------------- */

.form {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
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

.field__region {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--space-2);
}

.field__error {
  font-size: var(--text-xs);
  color: var(--signal-vermilion-deep);
}

.dialog-foot {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}

/* --- 按钮与骨架 ----------------------------------------------------------- */

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

.block {
  min-height: 88px;
}

.skeleton--sm {
  height: 96px;
}

.skeleton--tall {
  height: 320px;
}

@media (max-width: 900px) {
  .layout {
    grid-template-columns: minmax(0, 1fr);
  }
  .summary {
    position: static;
  }
}

@media (max-width: 520px) {
  .item {
    flex-wrap: wrap;
    gap: var(--space-3);
  }
  .item__amount {
    margin-left: auto;
  }
  .field__region {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
