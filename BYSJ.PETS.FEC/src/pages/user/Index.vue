<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import SectionHead from '@/components/ui/SectionHead.vue'
import ProductCard from '@/components/ui/ProductCard.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import AppIcon from '@/components/ui/AppIcon.vue'
import { getCategories, getProducts, type ShopQuery } from '@/api/user/shop'

/**
 * 首页。
 *
 * 原首页把 60 多个商品、价格和图片路径硬编码在组件里，与数据库毫无关系：
 * 改价、下架、审核都不会反映出来，图片还用的是 `public/xxx` 这种在嵌套路由下
 * 会失效的写法。这里全部改成真实查询，只保留原来的信息结构：
 * 轮播 → 全新 / 二手 / 租赁三条交易线，每条按分类分页签。
 */
const router = useRouter()

interface CategoryTab {
  code: string
  name: string
}

const categories = ref<CategoryTab[]>([])
const keyword = ref('')

/** 三条交易线。productType 与 product.product_type 一一对应。 */
const LINES = [
  {
    key: 'new',
    productType: 1,
    title: '全新零售',
    note: '平台审核通过后上架，支持开发票',
    to: '/shop',
    action: '进入器材商城',
    empty: '暂无在售的全新器材',
  },
  {
    key: 'used',
    productType: 2,
    title: '二手流转',
    note: '单件库存，成色与瑕疵随商品标注',
    to: '/second-hand',
    action: '进入二手交易',
    empty: '暂无在售的二手器材',
  },
  {
    key: 'rental',
    productType: 3,
    title: '器材租赁',
    note: '按天计价，押金与起租天数随商品标注',
    to: '/rental',
    action: '进入租赁中心',
    empty: '暂无可租的器材',
  },
] as const

const activeTab = ref<Record<string, string>>({ new: 'all', used: 'all', rental: 'all' })
const items = ref<Record<string, any[]>>({ new: [], used: [], rental: [] })
const loading = ref<Record<string, boolean>>({ new: true, used: true, rental: true })
const totals = ref<Record<string, number>>({ new: 0, used: 0, rental: 0 })

/** 每个交易线各自的分类页签：全部 + 该分类下确实有货的一级分类。 */
const tabsFor = computed<CategoryTab[]>(() => [
  { code: 'all', name: '全部' },
  ...categories.value,
])

const heroStats = computed(() => [
  { label: '在售全新', value: totals.value.new, unit: '件' },
  { label: '在售二手', value: totals.value.used, unit: '件' },
  { label: '可租器材', value: totals.value.rental, unit: '台' },
])

/** 按交易线取数据，索引访问统一在这里做空值收敛。 */
function itemsOf(key: string): any[] {
  return items.value[key] ?? []
}

function isLoading(key: string): boolean {
  return loading.value[key] ?? false
}

function activeOf(key: string): string {
  return activeTab.value[key] ?? 'all'
}

async function loadLine(line: (typeof LINES)[number]) {
  const key = line.key
  loading.value[key] = true
  const tab = activeTab.value[key] ?? 'all'
  const query: ShopQuery = {
    productType: line.productType,
    category: tab === 'all' ? undefined : tab,
    pageNum: 1,
    pageSize: 8,
  }
  try {
    const res = await getProducts(query)
    items.value[key] = res.list
    totals.value[key] = res.total
  } catch {
    items.value[key] = []
  } finally {
    loading.value[key] = false
  }
}

function switchTab(key: string, code: string) {
  if (activeTab.value[key] === code) return
  activeTab.value[key] = code
  const line = LINES.find((l) => l.key === key)
  if (line) void loadLine(line)
}

function goSearch() {
  const q = keyword.value.trim()
  router.push({ path: '/shop', query: q ? { keyword: q } : {} })
}

function goCategory(code: string) {
  router.push({ path: '/shop', query: { category: code } })
}

onMounted(async () => {
  try {
    const res = await getCategories()
    const list = res?.categoryList ?? []
    categories.value = list.map((c: any) => ({ code: c.value, name: c.name }))
  } catch {
    categories.value = []
  }
  await Promise.all(LINES.map((line) => loadLine(line)))
})
</script>

<template>
  <!-- 首屏：真实照片承载，文案直接压在图上，不做卡片 -->
  <section class="hero">
    <img class="hero__bg" src="/media/hero-shoot.jpg" alt="两位摄影师在开花的树下取景" />
    <div class="hero__scrim" aria-hidden="true" />

    <div class="shell hero__inner">
      <h1 class="hero__title">摄影器材交易系统</h1>
      <p class="hero__lede">
        全新零售、二手流转、器材租赁，同一套库存与订单流转。带成色标注、押金与起租天数的器材，都在这里。
      </p>

      <form class="hero__search" role="search" @submit.prevent="goSearch">
        <AppIcon name="search" size="16" />
        <input
          v-model="keyword"
          class="hero__input"
          type="search"
          placeholder="搜索机身、镜头、品牌，例如 Z8、24-70、DJI"
          aria-label="搜索商品"
        />
        <button class="hero__go" type="submit">搜索</button>
      </form>

      <dl class="hero__stats">
        <div v-for="stat in heroStats" :key="stat.label" class="hero__stat">
          <dt>{{ stat.label }}</dt>
          <dd>{{ (stat.value ?? 0).toLocaleString('zh-CN') }}<span>{{ stat.unit }}</span></dd>
        </div>
      </dl>
    </div>
  </section>

  <!-- 三条交易线 -->
  <section v-for="line in LINES" :key="line.key" class="shell band">
    <SectionHead :title="line.title" :note="line.note" size="lg">
      <template #action>
        <RouterLink class="more" :to="line.to">
          {{ line.action }}
          <AppIcon name="chevron-right" size="14" />
        </RouterLink>
      </template>
    </SectionHead>

    <div class="tabs" role="tablist" :aria-label="`${line.title}分类`">
      <button
        v-for="tab in tabsFor"
        :key="tab.code"
        class="tabs__item"
        :class="{ 'is-active': activeOf(line.key) === tab.code }"
        type="button"
        role="tab"
        :aria-selected="activeOf(line.key) === tab.code"
        @click="switchTab(line.key, tab.code)"
      >
        {{ tab.name }}
      </button>
    </div>

    <div v-if="isLoading(line.key)" class="grid" aria-busy="true">
      <div v-for="n in 4" :key="n" class="ghost">
        <div class="ghost__media skeleton" />
        <div class="ghost__line skeleton" />
        <div class="ghost__line ghost__line--short skeleton" />
      </div>
    </div>

    <EmptyState
      v-else-if="itemsOf(line.key).length === 0"
      :title="line.empty"
      note="换个分类看看，或直接进入对应频道浏览全部器材。"
    >
      <RouterLink class="more" :to="line.to">
        {{ line.action }}
        <AppIcon name="chevron-right" size="14" />
      </RouterLink>
    </EmptyState>

    <div v-else class="grid">
      <ProductCard
        v-for="(item, index) in itemsOf(line.key)"
        :key="item.productId"
        :product-id="item.productId"
        :name="item.name"
        :brand-name="item.brandName"
        :category-name="item.categoryName"
        :price="item.price"
        :image-url="item.imageUrl"
        :product-type="item.productType ?? line.productType"
        :condition="item.condition"
        :stock="item.stock"
        :min-stock="item.minStock"
        :seller-name="item.sellerName"
        :eager="index < 4"
      />
    </div>
  </section>

  <!-- 分类导航 -->
  <section v-if="categories.length" class="shell band band--last">
    <SectionHead title="按分类浏览" note="相机、镜头、无人机与支撑器材" />
    <div class="cats">
      <button
        v-for="cat in categories"
        :key="cat.code"
        class="cats__item"
        type="button"
        @click="goCategory(cat.code)"
      >
        <span class="cats__name">{{ cat.name }}</span>
        <AppIcon name="chevron-right" size="15" />
      </button>
    </div>
  </section>
</template>

<style scoped>
/* --- hero ---------------------------------------------------------------- */

.hero {
  position: relative;
  display: flex;
  align-items: flex-end;
  min-height: min(58vh, 520px);
  overflow: hidden;
  background: var(--ink-0);
}

.hero__bg {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: center 42%;
}

.hero__scrim {
  position: absolute;
  inset: 0;
  background:
    linear-gradient(105deg, rgb(8 11 14 / 88%) 0%, rgb(8 11 14 / 62%) 44%, rgb(8 11 14 / 18%) 100%),
    linear-gradient(to top, rgb(8 11 14 / 55%) 0%, transparent 42%);
}

.hero__inner {
  position: relative;
  padding-block: var(--space-12) var(--space-8);
  color: #fff;
}

.hero__title {
  color: #fff;
  font-size: var(--text-3xl);
  font-weight: 600;
  letter-spacing: -0.03em;
}

.hero__lede {
  margin-top: var(--space-3);
  max-width: 40ch;
  font-size: var(--text-md);
  line-height: 1.65;
  color: rgb(255 255 255 / 82%);
}

.hero__search {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-top: var(--space-6);
  max-width: 560px;
  height: 46px;
  padding-left: 14px;
  background: var(--paper-0);
  border-radius: var(--radius-sm);
  color: var(--ink-3);
}

.hero__input {
  flex: 1;
  min-width: 0;
  border: none;
  outline: none;
  background: transparent;
  font-size: var(--text-base);
  color: var(--ink-0);
}

.hero__input::placeholder {
  color: var(--ink-4);
}

.hero__go {
  height: 100%;
  padding-inline: 22px;
  border: none;
  border-radius: 0 var(--radius-sm) var(--radius-sm) 0;
  background: var(--ink-0);
  color: #fff;
  font-size: var(--text-base);
  font-weight: 600;
  cursor: pointer;
  transition: background-color var(--dur-state) ease;
}

.hero__go:hover {
  background: #262d33;
}

.hero__stats {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-8);
  margin: var(--space-8) 0 0;
}

.hero__stat dt {
  font-size: var(--text-xs);
  color: rgb(255 255 255 / 62%);
}

.hero__stat dd {
  margin: 2px 0 0;
  font-size: var(--text-lg);
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  letter-spacing: -0.02em;
}

.hero__stat dd span {
  margin-left: 3px;
  font-size: var(--text-xs);
  font-weight: 500;
  color: rgb(255 255 255 / 62%);
}

/* --- bands --------------------------------------------------------------- */

.band {
  padding-top: var(--space-12);
}

.band--last {
  padding-top: var(--space-10);
  padding-bottom: var(--space-8);
}

.more {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--ink-1);
}

.more:hover {
  text-decoration: none;
  color: var(--signal-amber-deep);
}

/* --- tabs ---------------------------------------------------------------- */

.tabs {
  display: flex;
  gap: var(--space-1);
  margin-bottom: var(--space-5);
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
  transition:
    background-color var(--dur-state) ease,
    color var(--dur-state) ease,
    border-color var(--dur-state) ease;
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

/* --- product grid -------------------------------------------------------- */

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(232px, 1fr));
  gap: var(--space-4);
}

.ghost {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4) var(--space-4);
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
}

.ghost__media {
  aspect-ratio: 4 / 3;
  border-radius: var(--radius-sm);
}

.ghost__line {
  height: 12px;
  border-radius: var(--radius-xs);
}

.ghost__line--short {
  width: 60%;
}

/* --- category nav -------------------------------------------------------- */

.cats {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: var(--space-3);
}

.cats__item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  padding: 14px 16px;
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
  color: var(--ink-1);
  text-align: left;
  cursor: pointer;
  transition:
    border-color var(--dur-state) ease,
    background-color var(--dur-state) ease;
}

.cats__item:hover {
  border-color: var(--ink-4);
  background: var(--paper-1);
}

.cats__name {
  font-size: var(--text-base);
  font-weight: 500;
}

@media (max-width: 900px) {
  .hero {
    min-height: 42vh;
  }
  .hero__title {
    font-size: var(--text-2xl);
  }
  .hero__lede {
    font-size: var(--text-base);
  }
  .hero__stats {
    gap: var(--space-6);
  }
  .grid {
    grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
    gap: var(--space-3);
  }
  .band {
    padding-top: var(--space-8);
  }
}

@media (max-width: 520px) {
  .hero__inner {
    padding-block: var(--space-8) var(--space-6);
  }
  .grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .cats {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
