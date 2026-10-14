<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import PriceTag from '@/components/ui/PriceTag.vue'
import SpecList, { type SpecEntry } from '@/components/ui/SpecList.vue'
import StatePill from '@/components/ui/StatePill.vue'
import ProductCard from '@/components/ui/ProductCard.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import AppIcon from '@/components/ui/AppIcon.vue'
import { conditionLabel } from '@/constants/domain'
import { formatMoney, rentalUnit } from '@/utils/format'
import { addToCart as addCartItem } from '@/api/user/cart'
import { addFavorite, checkFavorite, removeFavorite } from '@/api/user/favorite'
import { getProductDetail, getRelated } from '@/api/user/shop'
import { useUserStore } from '@/stores/user'

/**
 * 租赁商品详情。
 *
 * 租赁的账要当场算清楚：押金多少、几天起租、最长能租多久、配送要不要加钱、逾期
 * 怎么算，然后才是「一共多少钱」。所以页面主体是租期计算器，规则表紧挨着它。
 * 合计口径：租金（单价 × 天数）+ 押金 + 配送费；商家另收保险费时单列一行。
 *
 * 原实现的问题：图片兜底指向不存在的占位图；租赁规则与费用说明散落在两处，且
 * 计算器不校验起租/最长天数；「加入购物车」把不认识的天数丢给后端。这里统一收口。
 */

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const DAY_MS = 86400000

const product = ref<any>({})
const related = ref<any[]>([])
const loading = ref(true)
const failed = ref(false)
const activeImage = ref(0)
const activeTab = ref<'detail' | 'specs' | 'shots'>('detail')
const favorited = ref(false)
const addingToCart = ref(false)

const days = ref(1)
const range = ref<[Date, Date] | null>(null)
const rangeHint = ref('')

const tabs = [
  { key: 'detail', label: '商品详情' },
  { key: 'specs', label: '规格参数' },
  { key: 'shots', label: '商品实拍图' },
] as const

function clean(path?: string | null): string | null {
  if (!path) return null
  const value = String(path).trim()
  if (!value || value.includes('default-product')) return null
  return value
}

/** 后端偶尔把 JSON 数组当字符串返回，这里统一收敛成字符串数组。 */
function toList(value: unknown): string[] {
  if (!value) return []
  if (Array.isArray(value)) {
    return value.map((item) => clean(item)).filter((item): item is string => Boolean(item))
  }
  if (typeof value === 'string') {
    const text = value.trim()
    if (!text) return []
    if (text.startsWith('[')) {
      try {
        const parsed = JSON.parse(text)
        return Array.isArray(parsed)
          ? parsed.map((item) => clean(item)).filter((item): item is string => Boolean(item))
          : []
      } catch {
        return []
      }
    }
    const single = clean(text)
    return single ? [single] : []
  }
  return []
}

function num(value: unknown): number {
  const result = Number(value)
  return Number.isFinite(result) ? result : 0
}

function toDateInput(value: Date): string {
  const pad = (input: number) => String(input).padStart(2, '0')
  return `${value.getFullYear()}-${pad(value.getMonth() + 1)}-${pad(value.getDate())}`
}

const title = computed(() => {
  const brand = product.value.brandName || ''
  const model = product.value.name || '未命名器材'
  return brand ? `${brand} ${model}` : model
})

const images = computed(() => {
  const list = [clean(product.value.imageUrl), ...toList(product.value.imageUrls)].filter(
    (item): item is string => Boolean(item),
  )
  return Array.from(new Set(list))
})

const activeSrc = computed(() => images.value[activeImage.value] ?? null)

const minDays = computed(() => Math.max(1, num(product.value.minRentalDays) || 1))
const maxDays = computed(() => Math.max(minDays.value, num(product.value.maxRentalDays) || 90))
const unitPrice = computed(() => num(product.value.price))
const stock = computed(() => num(product.value.stock))
const soldOut = computed(() => stock.value <= 0)
const grade = computed(() => conditionLabel(product.value.condition))
const stockLabel = computed(() => (soldOut.value ? '已租完' : `可租 ${stock.value} 台`))

const pickupKey = computed(() => String(product.value.pickupMethods || 'delivery'))
const pickupLabel = computed(() => (pickupKey.value === 'store_pickup' ? '门店自取' : '配送上门'))
const deliveryFee = computed(() =>
  pickupKey.value === 'store_pickup' ? 0 : num(product.value.deliveryFee),
)
const insuranceRate = computed(() => num(product.value.insuranceFee))

const rentFee = computed(() => unitPrice.value * days.value)
const insuranceFee = computed(() => insuranceRate.value * days.value)
const depositFee = computed(() => num(product.value.deposit))
/** 合计 = 租金 + 押金 + 配送费；商家另收保险费时再计入。 */
const totalFee = computed(
  () => rentFee.value + depositFee.value + deliveryFee.value + insuranceFee.value,
)

const lateFeePercent = computed(() => {
  const rate = num(product.value.lateFeeRate)
  const percent = rate > 0 && rate <= 1 ? rate * 100 : rate
  return `${percent.toFixed(percent % 1 === 0 ? 0 : 1)}%`
})

const rentalSpecs = computed<SpecEntry[]>(() => [
  { key: '押金', value: formatMoney(product.value.deposit) },
  { key: '起租', value: rentalUnit(product.value.minRentalDays) },
  { key: '最长租期', value: `${maxDays.value} 天` },
  { key: '取货方式', value: pickupLabel.value },
  {
    key: '配送费',
    value:
      pickupKey.value === 'store_pickup' ? '门店自取免费' : formatMoney(product.value.deliveryFee),
  },
  {
    key: '保险费',
    value: insuranceRate.value > 0 ? `${formatMoney(insuranceRate.value)}/天` : '不另收保险',
  },
  { key: '成色', value: conditionLabel(product.value.condition) },
  { key: '卖家', value: product.value.sellerName },
])

const parameterSpecs = computed<SpecEntry[]>(() => {
  const source = product.value.specifications || product.value.parameters || {}
  if (!source || typeof source !== 'object') return []
  return Object.entries(source).map(([key, value]) => ({ key, value: value as string }))
})

const description = computed(() => product.value.description || '')

const feeHint = computed(() => {
  const parts = ['租金', '押金', '配送费']
  if (insuranceFee.value > 0) parts.push('保险')
  return parts.join(' + ')
})

function clampDays(value: number): number {
  return Math.min(maxDays.value, Math.max(minDays.value, value))
}

function disabledDate(time: Date): boolean {
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  return time.getTime() < today.getTime()
}

/** 选日期 → 算天数；不足起租或超出最长时按本商品的区间收敛，并把日期改回去。 */
function onRangeChange(value: unknown) {
  rangeHint.value = ''
  if (!Array.isArray(value) || value.length !== 2 || !value[0] || !value[1]) {
    return
  }
  const start = new Date(value[0] as Date)
  const end = new Date(value[1] as Date)
  const requested = Math.max(1, Math.round((end.getTime() - start.getTime()) / DAY_MS))
  const final = clampDays(requested)
  days.value = final
  if (final !== requested) {
    rangeHint.value =
      requested < minDays.value
        ? `该器材 ${minDays.value} 天起租，租期已按 ${final} 天计算。`
        : `该器材单次最长可租 ${maxDays.value} 天，租期已按 ${final} 天计算。`
    const fixedEnd = new Date(start.getTime() + final * DAY_MS)
    range.value = [start, fixedEnd]
  }
}

/** 改天数 → 已选日期时同步归还日期。 */
function onDaysChange(value: number | undefined) {
  rangeHint.value = ''
  const next = clampDays(num(value) || minDays.value)
  days.value = next
  if (range.value && range.value[0]) {
    const start = new Date(range.value[0])
    range.value = [start, new Date(start.getTime() + next * DAY_MS)]
  }
}

async function loadRelated() {
  if (!product.value.categoryId) {
    related.value = []
    return
  }
  try {
    const res = await getRelated(product.value.categoryId, product.value.id, 4)
    related.value = Array.isArray(res) ? res : []
  } catch {
    related.value = []
  }
}

async function loadFavorite() {
  favorited.value = false
  if (!userStore.isLoggedIn || !product.value.id) return
  try {
    favorited.value = await checkFavorite(Number(product.value.id))
  } catch {
    favorited.value = false
  }
}

async function fetchDetail() {
  loading.value = true
  failed.value = false
  activeImage.value = 0
  range.value = null
  rangeHint.value = ''
  try {
    const data = await getProductDetail(route.params.id as string)
    if (!data) throw new Error('empty')
    product.value = data
    days.value = Math.max(1, num(data.minRentalDays) || 1)
    await Promise.all([loadFavorite(), loadRelated()])
  } catch {
    product.value = {}
    related.value = []
    failed.value = true
  } finally {
    loading.value = false
  }
}

function requireLogin(): boolean {
  if (userStore.isLoggedIn) return true
  ElMessage.warning('请先登录')
  void router.push('/login')
  return false
}

async function onAddToCart() {
  if (!requireLogin()) return
  addingToCart.value = true
  try {
    // 后端 /cart/add 只接受 productId 与 quantity，租期在选择订单时随下单参数提交。
    await addCartItem({ productId: Number(product.value.id), quantity: 1 })
    ElMessage.success(`已加入购物车，租期 ${days.value} 天`)
  } catch {
    ElMessage.error('加入购物车失败')
  } finally {
    addingToCart.value = false
  }
}

function rentNow() {
  if (!requireLogin()) return
  const query: Record<string, string> = {
    productIds: String(product.value.id),
    leaseTerm: String(days.value),
  }
  if (range.value && range.value[0] && range.value[1]) {
    query.startDate = toDateInput(new Date(range.value[0]))
    query.endDate = toDateInput(new Date(range.value[1]))
  }
  void router.push({ path: '/order/confirm', query })
}

async function toggleFavorite() {
  if (!requireLogin()) return
  try {
    if (favorited.value) {
      await removeFavorite(Number(product.value.id))
      favorited.value = false
      ElMessage.success('已取消收藏')
    } else {
      await addFavorite({ productId: Number(product.value.id) })
      favorited.value = true
      ElMessage.success('已收藏')
    }
  } catch {
    ElMessage.error('操作失败，请稍后重试')
  }
}

watch(
  () => route.params.id,
  () => void fetchDetail(),
)

onMounted(() => void fetchDetail())
</script>

<template>
  <div class="shell">
    <nav class="crumbs" aria-label="面包屑">
      <RouterLink to="/index">首页</RouterLink>
      <span aria-hidden="true">/</span>
      <RouterLink to="/rental">器材租赁</RouterLink>
      <span aria-hidden="true">/</span>
      <span class="crumbs__now">{{ title }}</span>
    </nav>

    <div v-if="loading" class="layout" aria-busy="true">
      <div class="skeleton skeleton--media" />
      <div class="skeleton-stack">
        <div class="skeleton skeleton--title" />
        <div class="skeleton skeleton--line" />
        <div class="skeleton skeleton--line" />
        <div class="skeleton skeleton--block" />
      </div>
    </div>

    <EmptyState
      v-else-if="failed"
      title="器材不存在或已下架"
      note="商家可能已经停止出租这台器材。回到租赁中心看看其他可租的。"
    >
      <RouterLink class="link-btn" to="/rental">返回租赁中心</RouterLink>
    </EmptyState>

    <template v-else>
      <div class="layout">
        <section class="gallery">
          <div class="gallery__main">
            <ImageFrame
              :src="activeSrc"
              :alt="`${title} 器材图`"
              ratio="4 / 3"
              fit="contain"
              eager
            />
          </div>
          <div v-if="images.length > 1" class="gallery__rail" role="tablist" aria-label="器材图片">
            <button
              v-for="(image, index) in images"
              :key="image"
              class="thumb"
              :class="{ 'is-active': index === activeImage }"
              type="button"
              role="tab"
              :aria-selected="index === activeImage"
              @click="activeImage = index"
            >
              <ImageFrame
                :src="image"
                :alt="`${title} 图片 ${index + 1}`"
                ratio="1 / 1"
                fit="cover"
              />
            </button>
          </div>
          <EmptyState
            v-else-if="!images.length"
            title="商家没有上传器材图"
            note="可以在消息中心向商家索取机身、镜片与配件的照片。"
          />
        </section>

        <section class="info">
          <h1 class="info__title">{{ title }}</h1>

          <div class="info__state">
            <StatePill label="租赁" tone="teal" />
            <StatePill :label="stockLabel" :tone="soldOut ? 'vermilion' : 'teal'" />
            <StatePill v-if="grade" :label="grade" tone="neutral" />
          </div>

          <div class="info__price">
            <PriceTag :price="product.price" unit="/天" size="lg" :show-original="false" />
            <span class="info__deposit">押金 {{ formatMoney(product.deposit) }}</span>
          </div>

          <SpecList :entries="rentalSpecs" />

          <div class="info__actions">
            <el-button type="primary" size="large" :disabled="soldOut" @click="rentNow">
              <template #icon><AppIcon name="card" size="16" /></template>
              立即租赁
            </el-button>
            <el-button
              size="large"
              :disabled="soldOut"
              :loading="addingToCart"
              @click="onAddToCart"
            >
              <template #icon><AppIcon name="cart" size="16" /></template>
              按 {{ days }} 天加入购物车
            </el-button>
            <el-button size="large" @click="toggleFavorite">
              <template #icon><AppIcon name="star" size="16" /></template>
              {{ favorited ? '已收藏' : '收藏' }}
            </el-button>
          </div>
          <p class="info__note">
            当前按 {{ days }} 天计算：租金与押金一并结算，归还验收无误后退回押金。
          </p>
        </section>
      </div>

      <div class="ledger">
        <section class="plate calc">
          <header class="plate__head">
            <span class="plate__title">租期计算器</span>
            <span class="calc__unit">{{ formatMoney(product.price) }} / 天</span>
          </header>
          <div class="plate__body calc__body">
            <div class="calc__form">
              <label class="calc__field">
                <span class="calc__label">起租 · 归还日期</span>
                <el-date-picker
                  v-model="range"
                  type="daterange"
                  unlink-panels
                  range-separator="至"
                  start-placeholder="起租日"
                  end-placeholder="归还日"
                  :disabled-date="disabledDate"
                  size="small"
                  @change="onRangeChange"
                />
              </label>

              <label class="calc__field calc__field--days">
                <span class="calc__label">租期天数</span>
                <el-input-number
                  v-model="days"
                  :min="minDays"
                  :max="maxDays"
                  size="small"
                  controls-position="right"
                  @change="onDaysChange"
                />
              </label>

              <p class="calc__hint">
                {{ rangeHint || `${minDays} 天起租，单次最长 ${maxDays} 天。` }}
              </p>
            </div>

            <dl class="calc__fees">
              <div class="fee">
                <dt>租金</dt>
                <dd class="fee__note">{{ formatMoney(product.price) }} × {{ days }} 天</dd>
                <dd class="fee__value">{{ formatMoney(rentFee) }}</dd>
              </div>
              <div class="fee">
                <dt>押金</dt>
                <dd class="fee__note">归还验收后退回</dd>
                <dd class="fee__value">{{ formatMoney(depositFee) }}</dd>
              </div>
              <div v-if="insuranceFee > 0" class="fee">
                <dt>保险</dt>
                <dd class="fee__note">{{ formatMoney(insuranceRate) }} × {{ days }} 天</dd>
                <dd class="fee__value">{{ formatMoney(insuranceFee) }}</dd>
              </div>
              <div class="fee">
                <dt>配送费</dt>
                <dd class="fee__note">{{ pickupLabel }}</dd>
                <dd class="fee__value">
                  {{ deliveryFee > 0 ? formatMoney(deliveryFee) : '免配送' }}
                </dd>
              </div>
              <div class="fee fee--total">
                <dt>合计</dt>
                <dd class="fee__note">{{ feeHint }}</dd>
                <dd class="fee__total">
                  <PriceTag :price="totalFee" size="md" :show-original="false" />
                </dd>
              </div>
            </dl>
          </div>
        </section>

        <section class="rules">
          <h2 class="rules__title">租赁规则</h2>
          <dl class="rules__list">
            <div class="rules__row">
              <dt>逾期违约金</dt>
              <dd>逾期每天按租金的 {{ lateFeePercent }} 计收，从押金中扣除。</dd>
            </div>
            <div class="rules__row">
              <dt>损坏赔偿</dt>
              <dd>
                {{ product.damageFeeRule || '按器材损坏程度与商家协商赔偿，以平台记录为准。' }}
              </dd>
            </div>
            <div class="rules__row">
              <dt>取货与配送</dt>
              <dd>
                {{ pickupLabel
                }}<template v-if="deliveryFee > 0"
                  >，配送费 {{ formatMoney(deliveryFee) }} 在下单时一并支付</template
                >。
              </dd>
            </div>
            <div class="rules__row">
              <dt>租期范围</dt>
              <dd>{{ minDays }} 天起租，单次最长 {{ maxDays }} 天。需要更长租期请联系商家。</dd>
            </div>
            <div class="rules__row">
              <dt>押金退还</dt>
              <dd>归还器材并验收无误后原路退回，到账时间以支付渠道为准。</dd>
            </div>
            <div class="rules__row">
              <dt>承租条件</dt>
              <dd>承租人需年满 18 周岁，并持有有效身份证件。</dd>
            </div>
          </dl>
        </section>
      </div>

      <section class="panel">
        <div class="panel__tabs" role="tablist" aria-label="器材资料">
          <button
            v-for="tab in tabs"
            :key="tab.key"
            class="panel__tab"
            :class="{ 'is-active': activeTab === tab.key }"
            type="button"
            role="tab"
            :aria-selected="activeTab === tab.key"
            @click="activeTab = tab.key"
          >
            {{ tab.label }}
          </button>
        </div>

        <div v-if="activeTab === 'detail'" class="panel__body">
          <p v-if="description" class="prose">{{ description }}</p>
          <EmptyState
            v-else
            title="商家没有填写描述"
            note="押金、租期与配送信息在上面的计算器里，器材细节可以联系商家。"
          />
        </div>

        <div v-else-if="activeTab === 'specs'" class="panel__body">
          <SpecList v-if="parameterSpecs.length" :entries="parameterSpecs" :columns="2" />
          <template v-else>
            <p class="panel__note">商家未填写器材参数，以下是这台器材的租赁条款。</p>
            <SpecList :entries="rentalSpecs" :columns="2" />
          </template>
        </div>

        <div v-else class="panel__body">
          <div v-if="images.length" class="shots">
            <ImageFrame
              v-for="image in images"
              :key="image"
              :src="image"
              alt="器材实拍图"
              ratio="1 / 1"
              fit="cover"
            />
          </div>
          <EmptyState v-else title="暂无器材实拍图" note="可以在消息中心向商家索取细节照片。" />
        </div>
      </section>

      <section v-if="related.length" class="related">
        <h2 class="related__title">同分类的可租器材</h2>
        <div class="related__grid">
          <ProductCard
            v-for="item in related"
            :key="item.id || item.productId"
            :product-id="item.productId || item.id"
            :name="item.name"
            :brand-name="item.brandName"
            :price="item.price"
            :image-url="clean(item.imageUrl)"
            :product-type="3"
            stock-tip="在售"
            :to="`/rental/detail/${item.productId || item.id}`"
          />
        </div>
      </section>
    </template>
  </div>
</template>

<style scoped>
.crumbs {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding-bottom: var(--space-4);
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.crumbs a:hover {
  color: var(--ink-0);
}

.crumbs__now {
  color: var(--ink-1);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.link-btn {
  display: inline-flex;
  align-items: center;
  height: var(--control-h);
  padding-inline: var(--space-4);
  border: var(--edge);
  border-radius: var(--radius-sm);
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--ink-1);
}

.link-btn:hover {
  text-decoration: none;
  border-color: var(--ink-4);
  background: var(--paper-1);
}

/* --- layout --------------------------------------------------------------- */

.layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(320px, 420px);
  gap: var(--space-8);
  align-items: start;
}

.gallery {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.gallery__main {
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
  overflow: hidden;
}

.gallery__rail {
  display: flex;
  gap: var(--space-2);
  overflow-x: auto;
  scrollbar-width: none;
  padding-bottom: var(--space-1);
}

.gallery__rail::-webkit-scrollbar {
  display: none;
}

.thumb {
  flex: 0 0 auto;
  width: 72px;
  padding: 0;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  overflow: hidden;
  cursor: pointer;
  transition: border-color var(--dur-state) ease;
}

.thumb:hover {
  border-color: var(--ink-4);
}

.thumb.is-active {
  border-color: var(--ink-0);
}

/* --- info column ---------------------------------------------------------- */

.info {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.info__title {
  font-size: var(--text-xl);
  line-height: 1.3;
}

.info__state {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.info__price {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: var(--space-3);
  padding: var(--space-3) 0;
  border-top: var(--hairline);
  border-bottom: var(--hairline);
}

.info__deposit {
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.info__actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.info__actions :deep(.el-button) {
  flex: 1 1 140px;
  margin-left: 0;
}

.info__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
  line-height: 1.6;
}

/* --- calculator & rules --------------------------------------------------- */

.ledger {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  gap: var(--space-4);
  align-items: start;
  margin-top: var(--space-8);
}

.calc__unit {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.calc__body {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.calc__form {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  gap: var(--space-4);
}

.calc__field {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.calc__label {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.calc__field--days :deep(.el-input-number) {
  width: calc(var(--space-16) * 2.4);
}

.calc__hint {
  flex: 1 1 100%;
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.calc__fees {
  display: flex;
  flex-direction: column;
  margin: 0;
  border-top: var(--hairline);
}

.fee {
  display: grid;
  grid-template-columns: 80px minmax(0, 1fr) auto;
  align-items: baseline;
  gap: var(--space-3);
  padding: var(--space-2) 0;
  border-bottom: var(--hairline);
}

.fee dt {
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.fee__note {
  margin: 0;
  font-size: var(--text-xs);
  color: var(--ink-4);
}

.fee__value {
  margin: 0;
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--ink-1);
}

.fee--total {
  border-bottom: none;
  padding-top: var(--space-3);
}

.fee--total dt {
  color: var(--ink-0);
  font-weight: 600;
}

.fee__total {
  margin: 0;
}

.rules {
  padding: var(--space-4);
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
}

.rules__title {
  padding-bottom: var(--space-3);
  border-bottom: var(--hairline);
  font-size: var(--text-base);
}

.rules__list {
  margin: 0;
}

.rules__row {
  display: grid;
  grid-template-columns: 96px minmax(0, 1fr);
  gap: var(--space-3);
  padding: var(--space-3) 0;
  border-bottom: var(--hairline);
}

.rules__row:last-child {
  border-bottom: none;
  padding-bottom: 0;
}

.rules__row dt {
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.rules__row dd {
  margin: 0;
  font-size: var(--text-sm);
  line-height: 1.7;
  color: var(--ink-2);
}

/* --- panel ---------------------------------------------------------------- */

.panel {
  margin-top: var(--space-10);
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
}

.panel__tabs {
  display: flex;
  gap: var(--space-4);
  padding: 0 var(--pad-surface);
  border-bottom: var(--hairline);
  overflow-x: auto;
  scrollbar-width: none;
}

.panel__tabs::-webkit-scrollbar {
  display: none;
}

.panel__tab {
  flex-shrink: 0;
  padding: var(--space-3) 0;
  border: none;
  border-bottom: 2px solid transparent;
  background: transparent;
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--ink-3);
  cursor: pointer;
  transition: color var(--dur-state) ease;
}

.panel__tab:hover {
  color: var(--ink-1);
}

.panel__tab.is-active {
  color: var(--ink-0);
  font-weight: 600;
  border-bottom-color: var(--ink-0);
}

.panel__body {
  padding: var(--pad-surface);
}

.panel__note {
  margin-bottom: var(--space-4);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.prose {
  font-size: var(--text-base);
  line-height: 1.8;
  color: var(--ink-2);
  white-space: pre-wrap;
  max-width: 72ch;
}

.shots {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: var(--space-3);
}

.shots :deep(.frame) {
  border: var(--edge);
  border-radius: var(--radius-sm);
}

/* --- related -------------------------------------------------------------- */

.related {
  margin-top: var(--space-10);
}

.related__title {
  padding-bottom: var(--space-3);
  margin-bottom: var(--space-5);
  border-bottom: var(--hairline);
  font-size: var(--text-md);
}

.related__grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(232px, 1fr));
  gap: var(--space-4);
}

/* --- skeleton ------------------------------------------------------------- */

.skeleton--media {
  aspect-ratio: 4 / 3;
  border-radius: var(--radius-md);
}

.skeleton-stack {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.skeleton--title {
  height: 28px;
  width: 70%;
}

.skeleton--line {
  height: 14px;
}

.skeleton--block {
  height: 120px;
  margin-top: var(--space-4);
}

@media (max-width: 900px) {
  .layout {
    grid-template-columns: minmax(0, 1fr);
    gap: var(--space-6);
  }

  .ledger {
    grid-template-columns: minmax(0, 1fr);
  }

  .shots {
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  }
}

@media (max-width: 520px) {
  .info__title {
    font-size: var(--text-lg);
  }

  .calc__form {
    gap: var(--space-3);
  }

  .calc__field,
  .calc__field :deep(.el-date-editor) {
    width: 100%;
  }

  .fee {
    grid-template-columns: 72px minmax(0, 1fr);
  }

  .fee__value,
  .fee__total {
    grid-column: 2;
    text-align: left;
  }

  .related__grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: var(--space-3);
  }
}
</style>
