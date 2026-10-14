<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import axios from '@/axios'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import PriceTag from '@/components/ui/PriceTag.vue'
import ProductCard from '@/components/ui/ProductCard.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import SpecList from '@/components/ui/SpecList.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { getProductDetail, getRelated } from '@/api/user/shop'
import { addToCart } from '@/api/user/cart'
import { addFavorite, removeFavorite } from '@/api/user/favorite'
import evaluationApi from '@/api/user/evaluation'
import { conditionLabel, labelOf, PRODUCT_TYPE } from '@/constants/domain'
import { formatDateTime, formatMoney, resolveImageUrl, stockNote } from '@/utils/format'
import { useUserStore } from '@/stores/user'

/**
 * 商品详情。
 *
 * 原实现有四个真问题：
 * 1. 用 `/images/default-product.png` 兜底，这个文件在项目里不存在；
 * 2. 请求失败时保留一份假的「商品名称 / 品牌」占位数据，用户看到的是假商品；
 * 3. 收藏状态读的是 axios 响应信封（favoriteRes.isFavorited 恒为 undefined）；
 * 4. GoodsDetailVO 没有 productType 字段，页面一律按「全新」渲染，租赁的
 *    押金、起租天数、计价单位全部丢失。
 * 这里按规格表的方式重排：左图右规格，价格、库存、押金、成色都是数据。
 */
const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const product = ref<Record<string, any> | null>(null)
const loading = ref(true)
const errorText = ref('')
const notFound = ref(false)
const quantity = ref(1)
const activeImage = ref(0)
const activeTab = ref('detail')
const submitting = ref(false)
const favoriting = ref(false)
const isFavorited = ref(false)
const related = ref<any[]>([])
const evaluations = ref<any[]>([])

const productId = computed(() => String(route.params.id ?? ''))

/**
 * 商品类型。详情接口没有返回 product_type，只能按真实字段推断：
 * 有起租天数或押金 → 租赁；有二手表字段（质检 / 使用时长 / 瑕疵 / 卖家类型）→ 二手；否则全新。
 * 注意不能用 condition 判断：成色字段在「全新」商品上也有值。
 */
const productType = computed(() => {
  const data = product.value
  if (!data) return 1
  if (data.productType !== null && data.productType !== undefined) return Number(data.productType)
  if (data.minRentalDays !== null && data.minRentalDays !== undefined) return 3
  if (Number(data.deposit ?? 0) > 0) return 3
  const filled = (value: unknown) => value !== null && value !== undefined && value !== ''
  const listed = (value: unknown) => Array.isArray(value) && value.length > 0
  const hasSecondHandRow =
    Boolean(data.qualityReport || data.usedTime || data.defectDesc || data.secondHandDescription) ||
    listed(data.defectImg) ||
    listed(data.secondHandImgUrls) ||
    filled(data.sellerType) ||
    filled(data.negotiateStatus) ||
    filled(data.finalPrice) ||
    (data.parameters !== null &&
      typeof data.parameters === 'object' &&
      Object.keys(data.parameters ?? {}).length > 0)
  return hasSecondHandRow ? 2 : 1
})

const typeLabel = computed(() => labelOf(PRODUCT_TYPE, productType.value))
const isRental = computed(() => productType.value === 3)
const grade = computed(() =>
  productType.value === 1 ? null : conditionLabel(product.value?.condition),
)
const stock = computed(() => stockNote(product.value?.stock ?? null, null))
const payablePrice = computed(() => product.value?.displayPrice ?? product.value?.price ?? null)
const firstBuyable = computed(() => (product.value?.stock ?? 0) > 0)
const description = computed(() => String(product.value?.description ?? '').trim())

/** 图库：主图在前，详情图表里的图片去重后跟在后面。 */
const gallery = computed<string[]>(() => {
  const data = product.value
  if (!data) return []
  const list: string[] = []
  const push = (value: unknown) => {
    const path = typeof value === 'string' ? value.trim() : ''
    if (path && !list.includes(path)) list.push(path)
  }
  push(data.imageUrl)
  if (Array.isArray(data.imageUrls)) data.imageUrls.forEach(push)
  if (Array.isArray(data.secondHandImgUrls)) data.secondHandImgUrls.forEach(push)
  return list
})

const currentImage = computed(() => gallery.value[activeImage.value] ?? gallery.value[0] ?? null)

/** 规格栏：商品的身份是一行行对齐的数据，空值直接省略。 */
const specEntries = computed(() => {
  const data = product.value
  if (!data) return []
  return [
    { key: '品牌', value: data.brandName },
    { key: '型号', value: data.name },
    { key: '类型', value: typeLabel.value.label },
    { key: '成色', value: grade.value },
    { key: '库存', value: stock.value.out ? '已售完' : `${data.stock ?? '—'} 件` },
    { key: '押金', value: isRental.value ? formatMoney(data.deposit ?? 0) : null },
    {
      key: '起租天数',
      value: isRental.value && data.minRentalDays ? `${data.minRentalDays} 天起租` : null,
    },
    {
      key: '最长租期',
      value: isRental.value && data.maxRentalDays ? `${data.maxRentalDays} 天` : null,
    },
    { key: '卖家', value: data.sellerName },
    { key: '保修', value: data.warrantyInfo },
  ].filter((entry) => entry.value !== null && entry.value !== undefined && entry.value !== '')
})

/** 专业参数：product_detail.parameters 与 second_hand.parameters 合并后的键值对。 */
const parameterEntries = computed(() => {
  const merged = new Map<string, string>()
  for (const source of [product.value?.specifications, product.value?.parameters]) {
    if (!source || typeof source !== 'object') continue
    for (const [key, value] of Object.entries(source)) {
      if (!merged.has(key)) merged.set(key, String(value))
    }
  }
  return [...merged].map(([key, value]) => ({ key, value }))
})

const secondHandEntries = computed(() => {
  const data = product.value
  if (!data || productType.value !== 2) return []
  return [
    { key: '使用时长', value: data.usedTime },
    { key: '瑕疵描述', value: data.defectDesc },
    { key: '质检报告', value: data.qualityReport, mono: true },
    {
      key: '卖家类型',
      value: data.sellerType === 1 ? '个人闲置' : data.sellerType === 2 ? '企业商家' : null,
    },
    { key: '议价', value: data.negotiable === false ? '不接受议价' : null },
  ].filter((entry) => entry.value !== null && entry.value !== undefined && entry.value !== '')
})

const stockCaption = computed(() => {
  if (stock.value.out) return '这件器材已经售完，可以看看同类推荐'
  if (stock.value.low) return `${stock.value.text}，库存偏低`
  return stock.value.text
})

const averageScore = computed(() => {
  if (!evaluations.value.length) return 0
  const total = evaluations.value.reduce((sum, item) => sum + Number(item?.score ?? 0), 0)
  return total / evaluations.value.length
})

const scoreRows = computed(() => {
  const counts = [5, 4, 3, 2, 1].map((star) => ({
    star,
    count: evaluations.value.filter((item) => Math.round(Number(item?.score ?? 0)) === star).length,
  }))
  return counts
})

/* --- 数据加载 ------------------------------------------------------------- */

let requestToken = 0

async function loadProduct() {
  const id = productId.value
  const token = ++requestToken
  loading.value = true
  errorText.value = ''
  notFound.value = false
  product.value = null
  related.value = []
  evaluations.value = []
  activeImage.value = 0
  activeTab.value = 'detail'
  if (!id) {
    loading.value = false
    notFound.value = true
    return
  }
  try {
    const data = await getProductDetail(id)
    if (token !== requestToken) return
    if (!data) {
      notFound.value = true
      return
    }
    product.value = data
    quantity.value = 1
    void loadSideData(data)
  } catch {
    if (token !== requestToken) return
    errorText.value = '商品详情没有加载成功，可能是网络中断或该商品已被下架。'
  } finally {
    if (token === requestToken) loading.value = false
  }
}

/** 推荐、评价、收藏状态都是附加信息，失败不影响主信息展示。 */
async function loadSideData(data: Record<string, any>) {
  const token = requestToken
  if (data.categoryId) {
    try {
      const list = await getRelated(data.categoryId, data.id ?? productId.value, 4)
      if (token === requestToken && Array.isArray(list)) related.value = list
    } catch {
      related.value = []
    }
  }
  try {
    const list = await evaluationApi.getProductEvaluations(Number(productId.value))
    if (token === requestToken && Array.isArray(list)) evaluations.value = list
  } catch {
    evaluations.value = []
  }
  await loadFavoriteState()
}

async function loadFavoriteState() {
  isFavorited.value = false
  if (!userStore.isLoggedIn) return
  try {
    // 该接口直接返回 { isFavorited }，不套 Result 信封
    const res: any = await axios.get('/favorites/check', {
      params: { productId: Number(productId.value) },
    })
    isFavorited.value = Boolean(res?.isFavorited ?? res?.data?.isFavorited)
  } catch {
    isFavorited.value = false
  }
}

watch(productId, () => void loadProduct())
onMounted(() => void loadProduct())

/* --- 交互 ----------------------------------------------------------------- */

function requireLogin(): boolean {
  if (userStore.isLoggedIn) return true
  ElMessage.warning('请先登录后再购买')
  void router.push({ path: '/login', query: { redirect: route.fullPath } })
  return false
}

function changeQuantity(step: number) {
  const max = Math.max(1, Number(product.value?.stock ?? 1))
  const next = quantity.value + step
  quantity.value = Math.min(max, Math.max(1, next))
}

async function handleAddToCart() {
  if (!requireLogin() || submitting.value) return
  submitting.value = true
  try {
    await addToCart({ productId: Number(productId.value), quantity: quantity.value })
    ElMessage.success(`已加入购物车，共 ${quantity.value} 件`)
  } catch {
    // 拦截器已提示后端原因
  } finally {
    submitting.value = false
  }
}

function handleBuyNow() {
  if (!requireLogin()) return
  const query: Record<string, string> = {
    productIds: productId.value,
    quantity: String(quantity.value),
  }
  // 租赁商品把起租天数带过去，确认订单页据此初始化，避免默认 1 天低于商家要求
  if (isRental.value && product.value?.minRentalDays) {
    query.leaseTerm = String(product.value.minRentalDays)
  }
  void router.push({
    path: '/order/confirm',
    query,
  })
}

async function toggleFavorite() {
  if (!requireLogin() || favoriting.value) return
  favoriting.value = true
  try {
    if (isFavorited.value) {
      await removeFavorite(Number(productId.value))
      isFavorited.value = false
      ElMessage.success('已取消收藏')
    } else {
      await addFavorite({ productId: Number(productId.value) })
      isFavorited.value = true
      ElMessage.success('已加入收藏')
    }
  } catch {
    // 拦截器已提示后端原因
  } finally {
    favoriting.value = false
  }
}

function goSecondHand() {
  void router.push({ path: '/second-hand', query: { keyword: String(product.value?.name ?? '') } })
}
</script>

<template>
  <div class="shell page">
    <nav class="crumbs" aria-label="位置">
      <RouterLink to="/index">首页</RouterLink>
      <span aria-hidden="true">/</span>
      <RouterLink to="/shop">器材商城</RouterLink>
      <template v-if="product">
        <span aria-hidden="true">/</span>
        <span class="crumbs__now">{{ product.brandName }} {{ product.name }}</span>
      </template>
    </nav>

    <div v-if="loading" class="main" aria-busy="true">
      <div class="skeleton main__media" />
      <div class="main__info">
        <div class="skeleton line line--title" />
        <div class="skeleton line line--price" />
        <div class="skeleton line" />
        <div class="skeleton line line--short" />
      </div>
    </div>

    <EmptyState
      v-else-if="notFound"
      title="商品不存在或已下架"
      note="该器材可能已经下架，或者链接里的编号不正确。"
    >
      <RouterLink class="btn" to="/shop">回到器材商城</RouterLink>
    </EmptyState>

    <EmptyState v-else-if="errorText" title="商品详情加载失败" :note="errorText">
      <button class="btn" type="button" @click="loadProduct()">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
    </EmptyState>

    <template v-else-if="product">
      <div class="main">
        <div class="gallery">
          <ImageFrame
            class="gallery__main"
            :src="currentImage"
            :alt="`${product.brandName ?? ''} ${product.name ?? '商品图'}`"
            ratio="4 / 3"
            fit="contain"
            eager
          />
          <div
            v-if="gallery.length > 1"
            class="gallery__thumbs"
            role="tablist"
            aria-label="商品图片"
          >
            <button
              v-for="(image, index) in gallery"
              :key="image"
              class="gallery__thumb"
              :class="{ 'is-active': activeImage === index }"
              type="button"
              role="tab"
              :aria-selected="activeImage === index"
              :aria-label="`查看第 ${index + 1} 张图片`"
              @click="activeImage = index"
            >
              <img :src="resolveImageUrl(image)" :alt="`${product.name} 图片 ${index + 1}`" />
            </button>
          </div>
        </div>

        <div class="info">
          <div class="info__head">
            <StatePill :label="typeLabel.label" :tone="typeLabel.tone" />
            <StatePill v-if="grade" :label="grade" tone="amber" />
          </div>

          <h1 class="info__title">{{ product.brandName }} {{ product.name }}</h1>

          <div class="info__price">
            <PriceTag
              :price="payablePrice"
              :original-price="isRental ? null : product.originalPrice"
              :unit="isRental ? '/天' : null"
              size="lg"
            />
            <p class="info__payable">
              <template v-if="isRental">
                押金 ¥{{ product.deposit ?? 0 }}，起租
                {{ product.minRentalDays ?? 1 }} 天，租期在确认订单时选择
              </template>
              <template v-else>下单后由商家发货，库存以支付时的数量为准</template>
            </p>
          </div>

          <p class="info__stock" :class="{ 'is-out': stock.out, 'is-low': stock.low }">
            <AppIcon name="box" size="15" />
            {{ stockCaption }}
          </p>

          <SpecList :entries="specEntries" />

          <div class="buy">
            <div class="buy__qty">
              <span class="buy__label">{{ isRental ? '租借数量' : '购买数量' }}</span>
              <div class="stepper">
                <button
                  type="button"
                  aria-label="减少数量"
                  :disabled="quantity <= 1 || !firstBuyable"
                  @click="changeQuantity(-1)"
                >
                  <AppIcon name="minus" size="14" />
                </button>
                <span class="stepper__value">{{ quantity }}</span>
                <button
                  type="button"
                  aria-label="增加数量"
                  :disabled="!firstBuyable || quantity >= (product.stock ?? 1)"
                  @click="changeQuantity(1)"
                >
                  <AppIcon name="plus" size="14" />
                </button>
              </div>
            </div>

            <div class="buy__actions">
              <button
                class="btn btn--solid"
                type="button"
                :disabled="!firstBuyable || submitting"
                @click="handleBuyNow"
              >
                <AppIcon name="card" size="15" />
                立即购买
              </button>
              <button
                class="btn"
                type="button"
                :disabled="!firstBuyable || submitting"
                @click="handleAddToCart"
              >
                <AppIcon name="cart" size="15" />
                加入购物车
              </button>
              <button
                class="btn btn--ghost"
                type="button"
                :disabled="favoriting"
                @click="toggleFavorite"
              >
                <AppIcon name="star" size="15" />
                {{ isFavorited ? '已收藏' : '收藏' }}
              </button>
              <button class="btn btn--ghost" type="button" @click="goSecondHand">
                <AppIcon name="search" size="15" />
                看看二手
              </button>
            </div>
          </div>
        </div>
      </div>

      <section class="plate tabs">
        <el-tabs v-model="activeTab">
          <el-tab-pane label="商品详情" name="detail">
            <p v-if="description" class="prose">{{ description }}</p>
            <p v-else class="prose prose--empty">商家还没有填写详细描述。</p>
            <template v-if="secondHandEntries.length">
              <p class="subhead">二手说明</p>
              <SpecList :entries="secondHandEntries" :columns="2" />
            </template>
          </el-tab-pane>

          <el-tab-pane label="规格参数" name="specs">
            <SpecList v-if="parameterEntries.length" :entries="parameterEntries" :columns="2" />
            <p v-else class="prose prose--empty">该商品没有维护专业参数。</p>
          </el-tab-pane>

          <el-tab-pane :label="`用户评价 (${evaluations.length})`" name="evaluations">
            <div v-if="evaluations.length" class="evals">
              <div class="evals__summary">
                <div class="evals__score">
                  <span class="evals__number">{{ averageScore.toFixed(1) }}</span>
                  <el-rate
                    :model-value="Math.round(averageScore)"
                    disabled
                    size="small"
                    class="evals__stars"
                  />
                  <span class="evals__count">{{ evaluations.length }} 条评价</span>
                </div>
                <div class="evals__dist">
                  <div v-for="row in scoreRows" :key="row.star" class="evals__row">
                    <span class="evals__star">{{ row.star }} 星</span>
                    <span class="evals__bar">
                      <span
                        class="evals__fill"
                        :style="{
                          width: `${evaluations.length ? (row.count / evaluations.length) * 100 : 0}%`,
                        }"
                      />
                    </span>
                    <span class="evals__num">{{ row.count }}</span>
                  </div>
                </div>
              </div>

              <ul class="evals__list">
                <li v-for="item in evaluations" :key="item.evalId" class="evals__item">
                  <div class="evals__item-head">
                    <span class="evals__user">{{ item.userName || '匿名用户' }}</span>
                    <el-rate :model-value="Number(item.score ?? 0)" disabled size="small" />
                    <span class="evals__time">{{ formatDateTime(item.createTime) }}</span>
                  </div>
                  <p class="evals__content">{{ item.content }}</p>
                  <p class="evals__sub">
                    <span v-if="item.qualityScore">器材质量 {{ item.qualityScore }} 星</span>
                    <span v-if="item.serviceScore">商家服务 {{ item.serviceScore }} 星</span>
                    <span v-if="item.logisticsScore">物流速度 {{ item.logisticsScore }} 星</span>
                  </p>
                  <p v-if="item.replyContent" class="evals__reply">
                    商家回复：{{ item.replyContent }}
                  </p>
                </li>
              </ul>
            </div>
            <EmptyState
              v-else
              title="还没有评价"
              note="这件器材还没有买家评价，可以看看规格参数再决定。"
            />
          </el-tab-pane>
        </el-tabs>
      </section>

      <section v-if="related.length" class="related">
        <SectionHead title="同类推荐" note="与当前商品同类型、同分类的在售器材" />
        <div class="grid">
          <ProductCard
            v-for="item in related"
            :key="item.productId"
            :product-id="item.productId"
            :name="item.brandName ? `${item.brandName} ${item.name}` : item.name"
            :brand-name="item.brandName"
            :price="item.price"
            :image-url="item.imageUrl"
            stock-tip="在售"
          />
        </div>
      </section>
    </template>
  </div>
</template>

<style scoped>
.page {
  padding-bottom: var(--space-8);
}

.crumbs {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-bottom: var(--space-4);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.crumbs__now {
  color: var(--ink-2);
}

/* --- 主体 ----------------------------------------------------------------- */

.main {
  display: grid;
  grid-template-columns: minmax(0, 1.15fr) minmax(0, 1fr);
  gap: var(--space-8);
  margin-bottom: var(--space-8);
}

.main__media {
  aspect-ratio: 4 / 3;
  border-radius: var(--radius-md);
}

.main__info {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  padding-top: var(--space-2);
}

.line {
  height: 14px;
  border-radius: var(--radius-xs);
}

.line--title {
  height: 26px;
  width: 78%;
}

.line--price {
  height: 30px;
  width: 40%;
}

.line--short {
  width: 55%;
}

.gallery {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  min-width: 0;
}

.gallery__main {
  border: var(--edge);
  border-radius: var(--radius-md);
}

.gallery__thumbs {
  display: flex;
  gap: var(--space-2);
  overflow-x: auto;
  scrollbar-width: none;
}

.gallery__thumbs::-webkit-scrollbar {
  display: none;
}

.gallery__thumb {
  flex-shrink: 0;
  width: 72px;
  height: 54px;
  padding: 4px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  cursor: pointer;
  transition: border-color var(--dur-state) ease;
}

.gallery__thumb img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.gallery__thumb.is-active {
  border-color: var(--ink-0);
}

.info {
  min-width: 0;
}

.info__head {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  margin-bottom: var(--space-3);
}

.info__title {
  font-size: var(--text-lg);
  letter-spacing: -0.02em;
  margin-bottom: var(--space-4);
}

.info__price {
  padding: var(--space-4);
  background: var(--paper-1);
  border-radius: var(--radius-md);
  margin-bottom: var(--space-4);
}

.info__payable {
  margin-top: var(--space-2);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.info__stock {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-bottom: var(--space-4);
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.info__stock.is-low {
  color: var(--signal-amber-deep);
}

.info__stock.is-out {
  color: var(--signal-vermilion-deep);
}

/* --- 购买区 --------------------------------------------------------------- */

.buy {
  margin-top: var(--space-5);
  padding-top: var(--space-4);
  border-top: var(--hairline);
}

.buy__qty {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-bottom: var(--space-4);
}

.buy__label {
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.stepper {
  display: inline-flex;
  align-items: center;
  border: var(--edge);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.stepper button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border: none;
  background: var(--paper-0);
  color: var(--ink-1);
  cursor: pointer;
}

.stepper button:hover:not(:disabled) {
  background: var(--paper-2);
}

.stepper button:disabled {
  color: var(--ink-4);
  cursor: not-allowed;
}

.stepper__value {
  min-width: 44px;
  text-align: center;
  font-size: var(--text-base);
  font-weight: 600;
  border-left: var(--hairline);
  border-right: var(--hairline);
  line-height: 32px;
}

.buy__actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: var(--control-h);
  padding-inline: 16px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  color: var(--ink-1);
  font-size: var(--text-base);
  font-weight: 500;
  cursor: pointer;
  text-decoration: none;
  transition:
    background-color var(--dur-state) ease,
    border-color var(--dur-state) ease;
}

.btn:hover:not(:disabled) {
  border-color: var(--ink-3);
}

.btn:disabled {
  color: var(--ink-4);
  cursor: not-allowed;
}

.btn--solid {
  border-color: var(--ink-0);
  background: var(--ink-0);
  color: var(--on-ink);
}

.btn--solid:hover:not(:disabled) {
  background: var(--ink-1);
  border-color: var(--ink-1);
}

.btn--ghost {
  border-color: transparent;
  color: var(--ink-2);
}

/* --- 详情 / 规格 / 评价 ---------------------------------------------------- */

.tabs {
  padding: var(--space-2) var(--space-5) var(--space-5);
  margin-bottom: var(--space-8);
}

.prose {
  max-width: 78ch;
  font-size: var(--text-base);
  line-height: 1.8;
  color: var(--ink-2);
  white-space: pre-wrap;
}

.prose--empty {
  color: var(--ink-4);
}

.subhead {
  margin: var(--space-5) 0 var(--space-2);
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-1);
}

.evals__summary {
  display: grid;
  grid-template-columns: minmax(0, 180px) minmax(0, 1fr);
  gap: var(--space-6);
  padding-bottom: var(--space-4);
  border-bottom: var(--hairline);
}

.evals__score {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.evals__number {
  font-size: var(--text-2xl);
  font-weight: 600;
  color: var(--ink-0);
  letter-spacing: -0.02em;
}

.evals__count {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.evals__row {
  display: grid;
  grid-template-columns: 40px minmax(0, 1fr) 28px;
  align-items: center;
  gap: var(--space-2);
  margin-bottom: 6px;
}

.evals__star,
.evals__num {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.evals__num {
  text-align: right;
}

.evals__bar {
  height: 6px;
  border-radius: var(--radius-pill);
  background: var(--paper-2);
  overflow: hidden;
}

.evals__fill {
  display: block;
  height: 100%;
  background: var(--signal-amber);
}

.evals__list {
  margin: 0;
  padding: 0;
  list-style: none;
}

.evals__item {
  padding: var(--space-4) 0;
  border-bottom: var(--hairline);
}

.evals__item:last-child {
  border-bottom: none;
}

.evals__item-head {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-3);
  margin-bottom: var(--space-2);
}

.evals__user {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-1);
}

.evals__time {
  margin-left: auto;
  font-size: var(--text-xs);
  color: var(--ink-4);
}

.evals__content {
  font-size: var(--text-base);
  color: var(--ink-2);
}

.evals__sub {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-3);
  margin-top: var(--space-1);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.evals__reply {
  margin-top: var(--space-2);
  padding: var(--space-2) var(--space-3);
  background: var(--paper-1);
  border-radius: var(--radius-sm);
  font-size: var(--text-sm);
  color: var(--ink-2);
}

:deep(.el-rate) {
  --el-rate-fill-color: var(--signal-amber);
  --el-rate-void-color: var(--paper-3);
  --el-rate-disabled-void-color: var(--paper-3);
  height: 18px;
}

/* --- 推荐 ----------------------------------------------------------------- */

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(232px, 1fr));
  gap: var(--space-4);
}

@media (max-width: 900px) {
  .main {
    grid-template-columns: minmax(0, 1fr);
    gap: var(--space-5);
  }
  .evals__summary {
    grid-template-columns: minmax(0, 1fr);
    gap: var(--space-4);
  }
  .grid {
    grid-template-columns: repeat(auto-fill, minmax(166px, 1fr));
    gap: var(--space-3);
  }
}

@media (max-width: 520px) {
  .info__title {
    font-size: var(--text-md);
  }
  .buy__actions .btn {
    flex: 1;
    justify-content: center;
  }
  .tabs {
    padding-inline: var(--space-4);
  }
  .grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>
