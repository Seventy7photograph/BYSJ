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
import { addToCart as addCartItem } from '@/api/user/cart'
import { addFavorite, checkFavorite, removeFavorite } from '@/api/user/favorite'
import { getProductDetail, getRelated } from '@/api/user/shop'
import { useUserStore } from '@/stores/user'

/**
 * 二手商品详情。
 *
 * 二手是单件在售，买家真正要判断的是「值不值这个价」：成色几分、哪里有瑕疵、
 * 实拍图长什么样、卖家是谁、然后才是价格。信息列就按这个顺序排。
 *
 * 原实现里的三处问题：
 *  - 「议价」表单 POST /second-hand/negotiate，后端没有这个接口，点下去只有 404，
 *    这里换成「联系卖家」进消息中心，并在按钮下方说明议价的去处
 *  - 图片列表为空时塞一张不存在的 /images/default-product.png，现在走真实空态
 *  - 成色、议价状态的文案各自维护，现在统一用 @/constants/domain 与 SpecList
 */

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const product = ref<any>({})
const related = ref<any[]>([])
const loading = ref(true)
const failed = ref(false)
const activeImage = ref(0)
const activeTab = ref<'detail' | 'specs' | 'shots' | 'report'>('detail')
const favorited = ref(false)
const addingToCart = ref(false)

const tabs = [
  { key: 'detail', label: '商品详情' },
  { key: 'specs', label: '规格参数' },
  { key: 'shots', label: '商品实拍图' },
  { key: 'report', label: '质检报告' },
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

const title = computed(() => {
  const brand = product.value.brandName || ''
  const model = product.value.name || '未命名器材'
  return brand ? `${brand} ${model}` : model
})

const grade = computed(() => conditionLabel(product.value.condition))

/** 主图 + 二手实拍图 + 详情图，去重后就是这台机器的全部影像。 */
const shots = computed(() => {
  const list = [
    clean(product.value.imageUrl),
    ...toList(product.value.secondHandImgUrls),
    ...toList(product.value.imageUrls),
  ].filter((item): item is string => Boolean(item))
  return Array.from(new Set(list))
})

const defectImages = computed(() => toList(product.value.defectImg))

const activeSrc = computed(() => shots.value[activeImage.value] ?? null)

const description = computed(
  () => product.value.secondHandDescription || product.value.description || '',
)

const soldOut = computed(() => Number(product.value.stock ?? 0) <= 0)

const sellerSpecs = computed<SpecEntry[]>(() => [
  { key: '卖家', value: product.value.sellerName },
  { key: '卖家类型', value: product.value.sellerType === 2 ? '企业商家' : '个人闲置' },
  { key: '成色', value: grade.value },
  { key: '使用时长', value: product.value.usedTime },
  { key: '保修', value: product.value.warrantyInfo },
  { key: '质检报告', value: product.value.qualityReport ? '已上传' : null },
])

const parameterSpecs = computed<SpecEntry[]>(() => {
  const source = product.value.parameters || product.value.specifications || {}
  if (!source || typeof source !== 'object') return []
  return Object.entries(source).map(([key, value]) => ({ key, value: value as string }))
})

const reportIsImage = computed(() =>
  /\.(png|jpe?g|webp|gif)$/i.test(String(product.value.qualityReport || '')),
)

function setActive(index: number) {
  activeImage.value = index
}

function showDefectAsMain(image: string) {
  const index = shots.value.indexOf(image)
  if (index >= 0) activeImage.value = index
}

async function loadRelated() {
  const categoryId = product.value.categoryId
  if (!categoryId) {
    related.value = []
    return
  }
  try {
    const res = await getRelated(categoryId, product.value.id, 4)
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
  const productId = route.params.id
  try {
    const data = await getProductDetail(productId as string)
    if (!data) throw new Error('empty')
    product.value = data
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
    await addCartItem({ productId: Number(product.value.id), quantity: 1 })
    ElMessage.success('已加入购物车')
  } catch {
    ElMessage.error('加入购物车失败')
  } finally {
    addingToCart.value = false
  }
}

function buyNow() {
  if (!requireLogin()) return
  void router.push({ path: '/order/confirm', query: { productIds: String(product.value.id) } })
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

function contactSeller() {
  if (!requireLogin()) return
  void router.push('/messages')
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
      <RouterLink to="/second-hand">二手交易</RouterLink>
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
      title="商品不存在或已下架"
      note="卖家可能已经卖出这件器材，或商品正在重新审核。回到列表看看其他在售的。"
    >
      <RouterLink class="link-btn" to="/second-hand">返回二手交易</RouterLink>
    </EmptyState>

    <template v-else>
      <div class="layout">
        <section class="gallery">
          <div class="gallery__main">
            <ImageFrame
              :src="activeSrc"
              :alt="`${title} 实拍图`"
              ratio="4 / 3"
              fit="contain"
              eager
            />
          </div>
          <div v-if="shots.length > 1" class="gallery__rail" role="tablist" aria-label="商品图片">
            <button
              v-for="(image, index) in shots"
              :key="image"
              class="thumb"
              :class="{ 'is-active': index === activeImage }"
              type="button"
              role="tab"
              :aria-selected="index === activeImage"
              @click="setActive(index)"
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
            v-else-if="!shots.length"
            title="卖家没有上传实拍图"
            note="可以在消息中心向卖家索取机身、镜片与卡口的细节照片。"
          />
        </section>

        <section class="info">
          <h1 class="info__title">{{ title }}</h1>

          <div class="info__grade">
            <StatePill label="二手" tone="amber" />
            <StatePill v-if="grade" :label="grade" tone="neutral" />
            <StatePill
              :label="soldOut ? '已售出' : '在售'"
              :tone="soldOut ? 'vermilion' : 'teal'"
            />
          </div>

          <section class="block">
            <h2 class="block__title">瑕疵说明</h2>
            <p v-if="product.defectDesc" class="block__text">{{ product.defectDesc }}</p>
            <p v-else class="block__text block__text--muted">
              卖家没有标注瑕疵。机身、镜片与卡口的细节请在消息中心向卖家确认。
            </p>
            <div v-if="defectImages.length" class="block__media">
              <button
                v-for="image in defectImages"
                :key="image"
                class="thumb thumb--wide"
                type="button"
                @click="showDefectAsMain(image)"
              >
                <ImageFrame :src="image" alt="瑕疵实拍图" ratio="1 / 1" fit="cover" />
              </button>
            </div>
          </section>

          <section class="block">
            <h2 class="block__title">实拍图</h2>
            <p v-if="!shots.length" class="block__text block__text--muted">暂无实拍图。</p>
            <div v-else class="block__media">
              <button
                v-for="(image, index) in shots.slice(0, 5)"
                :key="image"
                class="thumb thumb--wide"
                :class="{ 'is-active': index === activeImage }"
                type="button"
                @click="setActive(index)"
              >
                <ImageFrame :src="image" :alt="`实拍图 ${index + 1}`" ratio="1 / 1" fit="cover" />
              </button>
              <span class="block__count tnum">共 {{ shots.length }} 张</span>
            </div>
          </section>

          <section class="block">
            <h2 class="block__title">卖家</h2>
            <SpecList :entries="sellerSpecs" />
          </section>

          <section class="commit">
            <PriceTag :price="product.price" :original-price="product.originalPrice" size="lg" />
            <p class="commit__state">
              {{ soldOut ? '这件器材已经卖出。' : '单件在售，下单后与卖家确认发货方式。' }}
            </p>
            <div class="commit__actions">
              <el-button type="primary" size="large" :disabled="soldOut" @click="buyNow">
                <template #icon><AppIcon name="card" size="16" /></template>
                立即购买
              </el-button>
              <el-button
                size="large"
                :disabled="soldOut"
                :loading="addingToCart"
                @click="onAddToCart"
              >
                <template #icon><AppIcon name="cart" size="16" /></template>
                加入购物车
              </el-button>
              <el-button size="large" @click="toggleFavorite">
                <template #icon><AppIcon name="star" size="16" /></template>
                {{ favorited ? '已收藏' : '收藏' }}
              </el-button>
            </div>
            <div class="commit__ask">
              <el-button text @click="contactSeller">
                <template #icon><AppIcon name="message" size="16" /></template>
                联系卖家
              </el-button>
              <p class="commit__note">平台没有线上议价。价格、瑕疵与运费请在消息中心与卖家确认。</p>
            </div>
            <RouterLink
              class="commit__link"
              :to="{ path: '/shop', query: { keyword: product.name } }"
            >
              看看全新同款
              <AppIcon name="chevron-right" size="14" />
            </RouterLink>
          </section>
        </section>
      </div>

      <section class="panel">
        <div class="panel__tabs" role="tablist" aria-label="商品资料">
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
            title="卖家没有填写描述"
            note="规格参数与实拍图仍然可以判断这台器材。"
          />
        </div>

        <div v-else-if="activeTab === 'specs'" class="panel__body">
          <SpecList v-if="parameterSpecs.length" :entries="parameterSpecs" :columns="2" />
          <SpecList v-else :entries="sellerSpecs" />
        </div>

        <div v-else-if="activeTab === 'shots'" class="panel__body">
          <template v-if="shots.length || defectImages.length">
            <h3 v-if="defectImages.length" class="panel__sub">瑕疵图</h3>
            <div v-if="defectImages.length" class="shots">
              <ImageFrame
                v-for="image in defectImages"
                :key="image"
                :src="image"
                alt="瑕疵实拍图"
                ratio="1 / 1"
                fit="cover"
              />
            </div>
            <h3 class="panel__sub">实拍图</h3>
            <div v-if="shots.length" class="shots">
              <ImageFrame
                v-for="image in shots"
                :key="image"
                :src="image"
                alt="商品实拍图"
                ratio="1 / 1"
                fit="cover"
              />
            </div>
            <EmptyState v-else title="暂无实拍图" note="可以在消息中心向卖家索取细节照片。" />
          </template>
          <EmptyState
            v-else
            title="暂无实拍图"
            note="可以在消息中心向卖家索取机身与镜头的细节照片。"
          />
        </div>

        <div v-else class="panel__body">
          <template v-if="product.qualityReport">
            <ImageFrame
              v-if="reportIsImage"
              :src="product.qualityReport"
              alt="第三方质检报告"
              ratio="3 / 4"
              fit="contain"
            />
            <a class="report-link" :href="product.qualityReport" target="_blank" rel="noopener">
              <AppIcon name="document" size="16" />
              查看第三方质检报告
            </a>
          </template>
          <EmptyState
            v-else
            title="没有质检报告"
            note="这台器材由卖家自行描述成色，细节以实拍图和与卖家的确认为准。"
          />
        </div>
      </section>

      <section v-if="related.length" class="related">
        <h2 class="related__title">同分类的二手器材</h2>
        <div class="related__grid">
          <ProductCard
            v-for="item in related"
            :key="item.id || item.productId"
            :product-id="item.productId || item.id"
            :name="item.name"
            :brand-name="item.brandName"
            :price="item.price"
            :image-url="clean(item.imageUrl)"
            :product-type="2"
            stock-tip="在售"
            :to="`/second-hand/detail/${item.productId || item.id}`"
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

.thumb--wide {
  width: 84px;
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

.info__grade {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.block {
  padding-top: var(--space-4);
  border-top: var(--hairline);
}

.block__title {
  font-size: var(--text-base);
  font-weight: 600;
}

.block__text {
  margin-top: var(--space-2);
  font-size: var(--text-sm);
  line-height: 1.7;
  color: var(--ink-2);
  white-space: pre-wrap;
}

.block__text--muted {
  color: var(--ink-3);
}

.block__media {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-2);
  margin-top: var(--space-3);
}

.block__count {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

/* --- commit --------------------------------------------------------------- */

.commit {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  padding: var(--space-4);
  border-top: var(--hairline);
}

.commit__state {
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.commit__actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.commit__actions :deep(.el-button) {
  flex: 1 1 140px;
  margin-left: 0;
}

.commit__ask {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
  padding-top: var(--space-2);
  border-top: var(--hairline);
}

.commit__ask :deep(.el-button) {
  justify-content: flex-start;
}

.commit__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
  line-height: 1.6;
}

.commit__link {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.commit__link:hover {
  text-decoration: none;
  color: var(--signal-amber-deep);
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

.panel__sub {
  margin-bottom: var(--space-3);
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-2);
}

.panel__sub + .shots {
  margin-bottom: var(--space-6);
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

.report-link {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  margin-top: var(--space-3);
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--ink-1);
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

  .shots {
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  }
}

@media (max-width: 520px) {
  .info__title {
    font-size: var(--text-lg);
  }

  .panel__tabs {
    gap: var(--space-3);
  }

  .related__grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: var(--space-3);
  }
}
</style>
