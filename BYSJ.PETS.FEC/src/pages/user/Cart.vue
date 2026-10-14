<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import {
  cartItemTypeCode,
  clearCart,
  deleteCartItem,
  getCartList,
  updateCartItem,
  type CartItem,
} from '@/api/user/cart'
import { conditionLabel, labelOf, PRODUCT_TYPE } from '@/constants/domain'
import { formatMoney, stockNote } from '@/utils/format'
import { useUserStore } from '@/stores/user'

/**
 * 购物车。
 *
 * 原来的问题：接口类型写成 cartId / imageUrl（后端实际是 id / productImage）、
 * 租赁类型的英文名判断写的是 'rental'（后端拼的是 'rent'，租赁筛选永远为空）、
 * 商品图直接挂 /public/ 路径、金额用浮点累加、删除没有二次确认之外的库存校验。
 * 现在：类型码统一走 domain 字典，金额用整数分累加，库存与类型冲突在结算前拦下。
 */
const router = useRouter()
const userStore = useUserStore()

interface CartRow extends CartItem {
  selected: boolean
}

const TABS = [
  { key: 'all', label: '全部' },
  { key: '1', label: '全新' },
  { key: '2', label: '二手' },
  { key: '3', label: '租赁' },
] as const

const rows = ref<CartRow[]>([])
const loading = ref(true)
const errorText = ref('')
const activeTab = ref<string>('all')
const pendingIds = ref<number[]>([])

const visibleRows = computed(() =>
  activeTab.value === 'all'
    ? rows.value
    : rows.value.filter((item) => String(cartItemTypeCode(item) ?? '') === activeTab.value),
)

const selectedRows = computed(() => rows.value.filter((item) => item.selected))
const selectedCount = computed(() => selectedRows.value.length)
const allSelected = computed(
  () => visibleRows.value.length > 0 && visibleRows.value.every((item) => item.selected),
)
const someSelected = computed(
  () => visibleRows.value.some((item) => item.selected) && !allSelected.value,
)

/** 金额一律按整数分计算，避免 0.1 + 0.2 这类浮点误差。 */
function lineCents(item: CartRow): number {
  return Math.round(Number(item.price ?? 0) * 100) * Number(item.quantity ?? 0)
}

function itemUnit(item: CartRow): string | null {
  return cartItemTypeCode(item) === 3 ? '/天' : null
}

const subtotalCents = computed(() =>
  selectedRows.value.reduce((sum, item) => sum + lineCents(item), 0),
)
const subtotalText = computed(() => formatMoney(subtotalCents.value / 100))

/** 购物车里的价格来自加购时刻，是否还有货要看最新库存。 */
function rowStock(item: CartRow) {
  return stockNote(item.stock ?? null, null)
}

function rowTypeLabel(item: CartRow) {
  return labelOf(PRODUCT_TYPE, cartItemTypeCode(item))
}

function rowGrade(item: CartRow): string | null {
  return cartItemTypeCode(item) === 1 ? null : conditionLabel(item.condition)
}

function isPending(id: number): boolean {
  return pendingIds.value.includes(id)
}

function markPending(id: number, active: boolean) {
  if (active) {
    if (!pendingIds.value.includes(id)) pendingIds.value = [...pendingIds.value, id]
  } else {
    pendingIds.value = pendingIds.value.filter((value) => value !== id)
  }
}

/* --- 数据 ----------------------------------------------------------------- */

let requestToken = 0

async function loadCart() {
  const token = ++requestToken
  loading.value = true
  errorText.value = ''
  try {
    const list = await getCartList()
    if (token !== requestToken) return
    rows.value = list.map((item) => ({ ...item, selected: false }))
  } catch {
    if (token !== requestToken) return
    rows.value = []
    errorText.value = '购物车没有加载出来，可能是网络中断或登录状态已失效。'
  } finally {
    if (token === requestToken) loading.value = false
  }
}

/* --- 交互 ----------------------------------------------------------------- */

async function changeQuantity(item: CartRow, value: number | undefined) {
  const previous = item.quantity
  const max = Math.max(1, Number(item.stock ?? 1))
  const next = Math.floor(Number(value))
  if (!Number.isFinite(next) || next < 1 || next > max) {
    item.quantity = previous
    if (Number.isFinite(next) && next > max) {
      ElMessage.warning(`这件器材最多还能买 ${max} 件`)
    }
    return
  }
  if (next === previous) return

  item.quantity = next
  markPending(item.id, true)
  try {
    await updateCartItem(item.id, next)
  } catch {
    item.quantity = previous
  } finally {
    markPending(item.id, false)
  }
}

async function removeItem(item: CartRow) {
  try {
    await ElMessageBox.confirm(`将「${item.productName ?? '该商品'}」移出购物车？`, '移出购物车', {
      confirmButtonText: '移出',
      cancelButtonText: '保留',
      type: 'warning',
    })
  } catch {
    return
  }
  markPending(item.id, true)
  try {
    await deleteCartItem(item.id)
    rows.value = rows.value.filter((row) => row.id !== item.id)
    ElMessage.success('已移出购物车')
  } catch {
    // 拦截器已提示后端原因
  } finally {
    markPending(item.id, false)
  }
}

async function clearAll() {
  try {
    await ElMessageBox.confirm('清空购物车后需要重新挑选商品，确定清空？', '清空购物车', {
      confirmButtonText: '清空',
      cancelButtonText: '取消',
      type: 'warning',
    })
  } catch {
    return
  }
  try {
    await clearCart()
    rows.value = []
    ElMessage.success('购物车已清空')
  } catch {
    // 拦截器已提示后端原因
  }
}

function toggleAll(value: boolean | string | number) {
  const checked = Boolean(value)
  visibleRows.value.forEach((item) => {
    item.selected = checked
  })
}

function openItem(item: CartRow) {
  const type = cartItemTypeCode(item)
  if (type === 2) void router.push(`/second-hand/detail/${item.productId}`)
  else if (type === 3) void router.push(`/rental/detail/${item.productId}`)
  else void router.push(`/product/${item.productId}`)
}

function checkout() {
  const picked = selectedRows.value
  if (!picked.length) {
    ElMessage.warning('请先勾选要结算的商品')
    return
  }
  const soldOut = picked.find((item) => rowStock(item).out)
  if (soldOut) {
    ElMessage.error(`「${soldOut.productName ?? '部分商品'}」已经没有库存，请先移出购物车`)
    return
  }
  const overStock = picked.find((item) => Number(item.quantity) > Number(item.stock ?? 0))
  if (overStock) {
    ElMessage.error(`「${overStock.productName ?? '部分商品'}」的数量超过了库存，请先调整数量`)
    return
  }
  const hasRental = picked.some((item) => cartItemTypeCode(item) === 3)
  const hasOther = picked.some((item) => cartItemTypeCode(item) !== 3)
  if (hasRental && hasOther) {
    ElMessage.error('同一笔订单不能同时结算租赁器材和其他商品，请分开结算')
    return
  }
  void router.push({
    path: '/order/confirm',
    query: { productIds: picked.map((item) => item.productId).join(',') },
  })
}

onMounted(() => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录后查看购物车')
    void router.push({ path: '/login', query: { redirect: '/cart' } })
    return
  }
  void loadCart()
})
</script>

<template>
  <div class="shell page">
    <SectionHead title="购物车" :note="`共 ${rows.length} 种器材，已选 ${selectedCount} 种`">
      <template #action>
        <button class="text-btn" type="button" :disabled="!rows.length" @click="clearAll">
          <AppIcon name="trash" size="14" />
          清空购物车
        </button>
      </template>
    </SectionHead>

    <div class="tabs" role="tablist" aria-label="购物车商品类型">
      <button
        v-for="tab in TABS"
        :key="tab.key"
        class="tabs__item"
        :class="{ 'is-active': activeTab === tab.key }"
        type="button"
        role="tab"
        :aria-selected="activeTab === tab.key"
        @click="activeTab = tab.key"
      >
        {{ tab.label }}
      </button>
    </div>

    <div v-if="loading" class="plate" aria-busy="true">
      <div v-for="n in 3" :key="n" class="row row--ghost">
        <div class="skeleton ghost__check" />
        <div class="skeleton ghost__media" />
        <div class="ghost__lines">
          <div class="skeleton ghost__line" />
          <div class="skeleton ghost__line ghost__line--short" />
        </div>
      </div>
    </div>

    <EmptyState v-else-if="errorText" title="购物车加载失败" :note="errorText">
      <button class="btn" type="button" @click="loadCart()">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
    </EmptyState>

    <EmptyState
      v-else-if="!rows.length"
      title="购物车还是空的"
      note="把想买的器材加入购物车，结算时再确认数量与收货地址。"
    >
      <RouterLink class="btn" to="/shop">去器材商城看看</RouterLink>
    </EmptyState>

    <template v-else>
      <div class="plate list">
        <div class="list__head">
          <el-checkbox :model-value="allSelected" :indeterminate="someSelected" @change="toggleAll">
            全选本页
          </el-checkbox>
          <span class="list__hint">
            {{
              activeTab === 'all'
                ? '共 ' + rows.length + ' 种器材'
                : '该类型 ' + visibleRows.length + ' 种器材'
            }}
          </span>
        </div>

        <EmptyState
          v-if="!visibleRows.length"
          title="这一类还没有商品"
          note="切换到其他分类看看，或者去商城继续挑选。"
        />

        <template v-else>
          <article v-for="item in visibleRows" :key="item.id" class="row">
            <div class="row__check">
              <el-checkbox v-model="item.selected" :aria-label="`选择 ${item.productName}`" />
            </div>

            <button class="row__media" type="button" @click="openItem(item)">
              <ImageFrame
                :src="item.productImage"
                :alt="item.productName ?? '商品图'"
                ratio="1 / 1"
              />
            </button>

            <div class="row__info">
              <div class="row__title">
                <button class="row__link" type="button" @click="openItem(item)">
                  {{ item.productName || '未命名商品' }}
                </button>
                <StatePill :label="rowTypeLabel(item).label" :tone="rowTypeLabel(item).tone" />
              </div>
              <p class="row__spec">
                <span v-if="item.brandName">{{ item.brandName }}</span>
                <span v-if="rowGrade(item)">成色 {{ rowGrade(item) }}</span>
                <span v-if="item.sellerName">卖家 {{ item.sellerName }}</span>
              </p>
              <p class="row__price">
                <span class="money">¥{{ Number(item.price).toLocaleString('zh-CN') }}</span>
                <span v-if="itemUnit(item)" class="row__unit">{{ itemUnit(item) }}</span>
                <span
                  class="row__stock"
                  :class="{ 'is-out': rowStock(item).out, 'is-low': rowStock(item).low }"
                >
                  {{ rowStock(item).text }}
                </span>
              </p>
            </div>

            <div class="row__qty">
              <span class="row__label">数量</span>
              <el-input-number
                :model-value="item.quantity"
                :min="1"
                :max="Math.max(1, Number(item.stock ?? 1))"
                size="small"
                :disabled="isPending(item.id) || rowStock(item).out"
                @change="(value: number | undefined) => changeQuantity(item, value)"
              />
            </div>

            <div class="row__total">
              <span class="row__label">小计</span>
              <span class="money row__total-value">{{ formatMoney(lineCents(item) / 100) }}</span>
            </div>

            <div class="row__remove">
              <button
                class="icon-btn"
                type="button"
                :disabled="isPending(item.id)"
                :aria-label="`移出 ${item.productName}`"
                @click="removeItem(item)"
              >
                <AppIcon name="trash" size="15" />
              </button>
            </div>
          </article>
        </template>
      </div>

      <footer class="bar">
        <div class="bar__left">
          <span class="bar__count">已选 {{ selectedCount }} 种器材</span>
          <span class="bar__note">
            同一订单只包含同一商家的商品，租赁不能与其他类型混选；应付金额以确认订单页为准
          </span>
        </div>
        <div class="bar__right">
          <span class="bar__label">商品小计</span>
          <span class="bar__amount money">{{ subtotalText }}</span>
          <button class="btn btn--solid" type="button" :disabled="!selectedCount" @click="checkout">
            去结算（{{ selectedCount }}）
          </button>
        </div>
      </footer>
    </template>
  </div>
</template>

<style scoped>
.page {
  padding-bottom: var(--space-8);
}

/* --- 类型页签 ------------------------------------------------------------- */

.tabs {
  display: flex;
  gap: var(--space-1);
  margin-bottom: var(--space-4);
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

/* --- 列表 ----------------------------------------------------------------- */

.list {
  margin-bottom: var(--space-4);
}

.list__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  background: var(--paper-2);
  border-bottom: var(--hairline);
  border-radius: var(--radius-md) var(--radius-md) 0 0;
}

.list__hint {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.row {
  display: grid;
  grid-template-columns: 24px 72px minmax(0, 1fr) 132px 116px auto;
  grid-template-areas: 'check media info qty total remove';
  align-items: center;
  gap: var(--space-4);
  padding: var(--space-4);
  border-bottom: var(--hairline);
}

.row:last-child {
  border-bottom: none;
}

.row:hover {
  background: var(--paper-1);
}

.row__check {
  grid-area: check;
}

.row__media {
  grid-area: media;
  width: 72px;
  padding: 0;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  overflow: hidden;
  cursor: pointer;
}

.row__info {
  grid-area: info;
  min-width: 0;
}

.row__title {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-2);
}

.row__link {
  padding: 0;
  border: none;
  background: transparent;
  font-size: var(--text-base);
  font-weight: 600;
  color: var(--ink-0);
  text-align: left;
  cursor: pointer;
}

.row__link:hover {
  color: var(--signal-amber-deep);
}

.row__spec {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-3);
  margin-top: 2px;
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.row__price {
  display: flex;
  align-items: baseline;
  flex-wrap: wrap;
  gap: var(--space-2);
  margin-top: var(--space-1);
  font-size: var(--text-sm);
}

.row__unit {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.row__stock {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.row__stock.is-low {
  color: var(--signal-amber-deep);
  font-weight: 600;
}

.row__stock.is-out {
  color: var(--signal-vermilion-deep);
  font-weight: 600;
}

.row__qty {
  grid-area: qty;
}

.row__total {
  grid-area: total;
}

.row__label {
  display: block;
  margin-bottom: 2px;
  font-size: var(--text-xs);
  color: var(--ink-4);
}

.row__total-value {
  font-size: var(--text-base);
  font-weight: 600;
}

.row__remove {
  grid-area: remove;
}

.icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--ink-3);
  cursor: pointer;
}

.icon-btn:hover:not(:disabled) {
  background: var(--paper-2);
  color: var(--signal-vermilion-deep);
}

.icon-btn:disabled {
  color: var(--ink-4);
  cursor: not-allowed;
}

/* --- 骨架 ---------------------------------------------------------------- */

.row--ghost {
  grid-template-columns: 24px 72px minmax(0, 1fr);
  grid-template-areas: 'check media info';
}

.ghost__check {
  width: 24px;
  height: 24px;
  border-radius: var(--radius-xs);
}

.ghost__media {
  width: 72px;
  aspect-ratio: 1 / 1;
  border-radius: var(--radius-sm);
}

.ghost__lines {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.ghost__line {
  height: 12px;
  border-radius: var(--radius-xs);
}

.ghost__line--short {
  width: 40%;
}

/* --- 结算条 --------------------------------------------------------------- */

.bar {
  position: sticky;
  bottom: var(--space-4);
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  background: var(--paper-0);
  border-radius: var(--radius-md);
  box-shadow: var(--lift);
}

.bar__left {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.bar__count {
  font-size: var(--text-sm);
  color: var(--ink-1);
  font-weight: 500;
}

.bar__note {
  font-size: var(--text-xs);
  color: var(--ink-4);
}

.bar__right {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-left: auto;
}

.bar__label {
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.bar__amount {
  font-size: var(--text-lg);
}

.text-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 6px 10px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  font-size: var(--text-sm);
  color: var(--ink-3);
  cursor: pointer;
}

.text-btn:hover:not(:disabled) {
  background: var(--paper-2);
  color: var(--signal-vermilion-deep);
}

.text-btn:disabled {
  color: var(--ink-4);
  cursor: not-allowed;
}

.btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: var(--control-h);
  padding-inline: 18px;
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

.btn:disabled {
  border-color: var(--line-2);
  background: var(--paper-2);
  color: var(--ink-4);
  cursor: not-allowed;
}

@media (max-width: 900px) {
  .row {
    grid-template-columns: 24px 64px minmax(0, 1fr) auto;
    grid-template-areas:
      'check media info remove'
      'check media qty total';
    row-gap: var(--space-3);
    padding: var(--space-3);
  }
  .row__media {
    width: 64px;
  }
  .row__qty,
  .row__total {
    text-align: left;
  }
  .bar {
    bottom: var(--space-2);
  }
  .bar__right {
    width: 100%;
    justify-content: space-between;
  }
}

@media (max-width: 520px) {
  .row {
    grid-template-columns: 24px 56px minmax(0, 1fr) auto;
  }
  .row__media {
    width: 56px;
  }
  .row__link {
    font-size: var(--text-sm);
  }
  .bar__note {
    display: none;
  }
}
</style>
