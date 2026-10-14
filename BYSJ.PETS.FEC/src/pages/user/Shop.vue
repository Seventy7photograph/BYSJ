<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import SectionHead from '@/components/ui/SectionHead.vue'
import ProductCard from '@/components/ui/ProductCard.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import AppIcon from '@/components/ui/AppIcon.vue'
import {
  getBrands,
  getCategories,
  getProducts,
  getSubCategories,
  type ShopQuery,
} from '@/api/user/shop'

/**
 * 器材商城列表。
 *
 * 原页面把分类写死在 CategoryDataComponent 里，图片用的是 `/public/*.png`
 * （嵌套路由下必然 404），请求发到后端不存在的 `/shop/random-products`
 * 并且强制 `quality=brand_new`；筛选抽屉里的场景/防抖/传感器条件后端根本没有
 * 对应字段，点了只会清空结果。这里改成：条件全部来自路由 query，值直接对应
 * 后端 ShopController 支持的参数，刷新与分享链接都能还原同一份列表。
 */
const route = useRoute()
const router = useRouter()

interface CategoryOption {
  id: number
  code: string
  name: string
}

interface FacetOption {
  label: string
  value: string
}

/** 后端排序只认这三种，默认按上架时间。 */
const SORTS = [
  { value: 'newest', label: '最新上架' },
  { value: 'price_asc', label: '价格从低到高' },
  { value: 'price_desc', label: '价格从高到低' },
] as const

/** 后端 priceRange 的可选值，改这里必须同步 ProductMapper.xml。 */
const PRICE_RANGES = [
  { value: '0-50', label: '50 元以内' },
  { value: '50-100', label: '50-100 元' },
  { value: '100-200', label: '100-200 元' },
  { value: '200+', label: '200 元以上' },
] as const

const TYPE_TABS = [
  { value: '0', label: '全部' },
  { value: '1', label: '全新' },
  { value: '2', label: '二手' },
  { value: '3', label: '租赁' },
] as const

const PAGE_SIZES = [20, 40, 60] as const

function readQuery(value: unknown): string {
  if (Array.isArray(value)) return readQuery(value[0])
  if (value === null || value === undefined) return ''
  return String(value).trim()
}

/* --- 筛选条件：路由 query 是唯一真相 ------------------------------------- */

const keyword = computed(() => readQuery(route.query.keyword))
const categoryCode = computed(() => readQuery(route.query.category))
const subCategory = computed(() => readQuery(route.query.type))
const brand = computed(() => readQuery(route.query.brand))
const priceRange = computed(() => readQuery(route.query.priceRange))
const sort = computed(() => {
  const value = readQuery(route.query.sort)
  return SORTS.some((item) => item.value === value) ? value : 'newest'
})
/** 默认看全新器材，与「全新零售」交易线一致；选「全部」时不带该参数。 */
const typeTab = computed(() => {
  const value = readQuery(route.query.productType)
  return TYPE_TABS.some((item) => item.value === value) ? value : '1'
})
const pageNum = computed(() => {
  const value = Number(readQuery(route.query.pageNum))
  return Number.isFinite(value) && value > 0 ? Math.floor(value) : 1
})
const pageSize = computed(() => {
  const value = Number(readQuery(route.query.pageSize))
  return (PAGE_SIZES as readonly number[]).includes(value) ? value : PAGE_SIZES[0]
})

/** 合并一批筛选值写回路由；resetPage 为 true 时回到第 1 页。 */
function writeQuery(patch: Record<string, string | number | undefined>, resetPage = true) {
  const merged: Record<string, string> = {}
  const source: Record<string, unknown> = { ...route.query, ...patch }
  for (const [key, value] of Object.entries(source)) {
    if (value === undefined || value === null) continue
    const text = String(value).trim()
    if (!text || text === 'all') continue
    merged[key] = text
  }
  if (resetPage) delete merged.pageNum
  void router.push({ path: '/shop', query: merged })
}

const searchInput = ref(keyword.value)
watch(keyword, (value) => {
  searchInput.value = value
})

function submitSearch() {
  writeQuery({ keyword: searchInput.value.trim() })
}

function setType(value: string) {
  writeQuery({ productType: value })
}

function setCategory(code: string) {
  // 分类换了，属于旧分类的器材类型与品牌要一起清掉
  writeQuery({
    category: code || undefined,
    categoryId: undefined,
    type: undefined,
    brand: undefined,
  })
}

function clearFilters() {
  void router.push({ path: '/shop', query: { productType: typeTab.value } })
}

const hasFilters = computed(() =>
  Boolean(
    keyword.value || categoryCode.value || subCategory.value || brand.value || priceRange.value,
  ),
)

/* --- 分类与筛选项 --------------------------------------------------------- */

const categories = ref<CategoryOption[]>([])
const subCategories = ref<FacetOption[]>([])
const brands = ref<FacetOption[]>([])
const activeCategory = computed(() =>
  categories.value.find((item) => item.code === categoryCode.value),
)
const activeCategoryId = computed(() => activeCategory.value?.id ?? null)

async function loadCategories() {
  try {
    const res = await getCategories()
    const list: any[] = Array.isArray(res?.categoryList) ? res.categoryList : []
    categories.value = list
      .map((item) => ({
        id: Number(item?.id),
        code: String(item?.value ?? ''),
        name: String(item?.name ?? ''),
      }))
      .filter((item) => item.code && item.name && Number.isFinite(item.id))
  } catch {
    categories.value = []
  }
}

async function loadFacets(id: number | null) {
  if (id === null) {
    subCategories.value = []
    brands.value = []
    return
  }
  const [subs, brandList] = await Promise.all([
    getSubCategories(id).catch(() => []),
    getBrands(id).catch(() => []),
  ])
  subCategories.value = (Array.isArray(subs) ? subs : []).map((item: any) => ({
    label: String(item?.label ?? ''),
    value: String(item?.value ?? ''),
  }))
  brands.value = (Array.isArray(brandList) ? brandList : []).map((item: any) => ({
    label: String(item?.label ?? ''),
    value: String(item?.value ?? ''),
  }))
}

watch(activeCategoryId, (id) => void loadFacets(id), { immediate: true })

/* --- 列表 ----------------------------------------------------------------- */

const items = ref<any[]>([])
const total = ref(0)
const loading = ref(true)
const errorText = ref('')
let requestToken = 0

const query = computed<ShopQuery>(() => ({
  productType: typeTab.value === '0' ? undefined : Number(typeTab.value),
  category: categoryCode.value || undefined,
  type: subCategory.value || undefined,
  brand: brand.value || undefined,
  keyword: keyword.value || undefined,
  priceRange: priceRange.value || undefined,
  sort: sort.value,
  pageNum: pageNum.value,
  pageSize: pageSize.value,
}))

async function loadProducts() {
  const token = ++requestToken
  loading.value = true
  errorText.value = ''
  try {
    const res = await getProducts(query.value)
    if (token !== requestToken) return
    items.value = res.list
    total.value = res.total
  } catch {
    if (token !== requestToken) return
    items.value = []
    total.value = 0
    errorText.value = '列表请求没有成功，可能是网络中断或服务暂时不可用。'
  } finally {
    if (token === requestToken) loading.value = false
  }
}

watch(query, () => void loadProducts(), { deep: true, immediate: true })

/* --- 已选条件 ------------------------------------------------------------- */

interface FilterChip {
  key: string
  label: string
  clear: () => void
}

const chips = computed<FilterChip[]>(() => {
  const list: FilterChip[] = []
  if (keyword.value) {
    list.push({
      key: 'keyword',
      label: `关键词 ${keyword.value}`,
      clear: () => writeQuery({ keyword: undefined }),
    })
  }
  if (activeCategory.value) {
    list.push({ key: 'category', label: activeCategory.value.name, clear: () => setCategory('') })
  }
  const sub = subCategories.value.find((item) => item.value === subCategory.value)
  if (sub) {
    list.push({ key: 'type', label: sub.label, clear: () => writeQuery({ type: undefined }) })
  }
  const brandItem = brands.value.find((item) => item.value === brand.value)
  if (brandItem) {
    list.push({
      key: 'brand',
      label: brandItem.label,
      clear: () => writeQuery({ brand: undefined }),
    })
  }
  const price = PRICE_RANGES.find((item) => item.value === priceRange.value)
  if (price) {
    list.push({
      key: 'priceRange',
      label: price.label,
      clear: () => writeQuery({ priceRange: undefined }),
    })
  }
  return list
})

const emptyTitle = computed(() => (hasFilters.value ? '没有符合条件的器材' : '暂无在售器材'))
const emptyNote = computed(() =>
  hasFilters.value
    ? '可以减少筛选条件，或换一个关键词再试。'
    : '全新器材需要平台审核通过后才会出现在这里，稍后再来看看。',
)

onMounted(async () => {
  await loadCategories()
  // 顶部导航的分类入口带的是 categoryId，这里翻译成后端认识的分类编码
  const rawId = readQuery(route.query.categoryId)
  if (rawId && !categoryCode.value) {
    const hit = categories.value.find((item) => String(item.id) === rawId)
    writeQuery(hit ? { category: hit.code, categoryId: undefined } : { categoryId: undefined })
  }
})
</script>

<template>
  <div class="shell page">
    <SectionHead title="器材商城" :note="`共 ${total} 件在售器材`">
      <template #action>
        <div class="seg" role="group" aria-label="商品类型">
          <button
            v-for="tab in TYPE_TABS"
            :key="tab.value"
            class="seg__item"
            :class="{ 'is-active': typeTab === tab.value }"
            type="button"
            :aria-pressed="typeTab === tab.value"
            @click="setType(tab.value)"
          >
            {{ tab.label }}
          </button>
        </div>
      </template>
    </SectionHead>

    <section class="plate filters" aria-label="筛选条件">
      <div class="filters__row">
        <form class="search" role="search" @submit.prevent="submitSearch">
          <AppIcon name="search" size="16" />
          <input
            v-model="searchInput"
            class="search__input"
            type="search"
            placeholder="搜索品牌或型号，例如 Z8、24-70、DJI"
            aria-label="搜索商品"
          />
          <button class="search__go" type="submit">搜索</button>
        </form>

        <div class="filters__controls">
          <el-select
            :model-value="sort"
            class="filters__select"
            aria-label="排序方式"
            @change="
              (value: string) => writeQuery({ sort: value === 'newest' ? undefined : value })
            "
          >
            <el-option
              v-for="item in SORTS"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>

          <el-select
            :model-value="priceRange || undefined"
            class="filters__select"
            placeholder="价格"
            clearable
            aria-label="价格区间"
            @change="(value: string) => writeQuery({ priceRange: value })"
          >
            <el-option
              v-for="item in PRICE_RANGES"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </div>
      </div>

      <div class="filters__row filters__row--cats">
        <button
          class="cat"
          :class="{ 'is-active': !categoryCode }"
          type="button"
          @click="setCategory('')"
        >
          全部分类
        </button>
        <button
          v-for="item in categories"
          :key="item.code"
          class="cat"
          :class="{ 'is-active': categoryCode === item.code }"
          type="button"
          @click="setCategory(item.code)"
        >
          {{ item.name }}
        </button>
      </div>

      <div v-if="subCategories.length || brands.length" class="filters__row filters__row--sub">
        <el-select
          v-if="subCategories.length"
          :model-value="subCategory || undefined"
          class="filters__select"
          placeholder="器材类型"
          clearable
          aria-label="器材类型"
          @change="(value: string) => writeQuery({ type: value })"
        >
          <el-option
            v-for="item in subCategories"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          />
        </el-select>

        <el-select
          v-if="brands.length"
          :model-value="brand || undefined"
          class="filters__select"
          placeholder="品牌"
          clearable
          aria-label="品牌"
          @change="(value: string) => writeQuery({ brand: value })"
        >
          <el-option
            v-for="item in brands"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          />
        </el-select>

        <button v-if="hasFilters" class="reset" type="button" @click="clearFilters">
          <AppIcon name="close" size="13" />
          清除筛选
        </button>
      </div>

      <div v-if="chips.length" class="chips">
        <span class="chips__label">已选</span>
        <button
          v-for="chip in chips"
          :key="chip.key"
          class="chip"
          type="button"
          @click="chip.clear()"
        >
          {{ chip.label }}
          <AppIcon name="close" size="12" />
        </button>
      </div>
    </section>

    <div v-if="loading" class="grid" aria-busy="true">
      <div v-for="n in 8" :key="n" class="ghost">
        <div class="ghost__media skeleton" />
        <div class="ghost__line skeleton" />
        <div class="ghost__line ghost__line--short skeleton" />
      </div>
    </div>

    <EmptyState v-else-if="errorText" title="商品列表加载失败" :note="errorText">
      <button class="btn" type="button" @click="loadProducts()">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
    </EmptyState>

    <EmptyState v-else-if="!items.length" :title="emptyTitle" :note="emptyNote">
      <button v-if="hasFilters" class="btn" type="button" @click="clearFilters">
        清除筛选条件
      </button>
    </EmptyState>

    <div v-else class="grid">
      <ProductCard
        v-for="(item, index) in items"
        :key="item.productId"
        :product-id="item.productId"
        :name="item.name"
        :brand-name="item.brandName"
        :category-name="item.categoryName"
        :price="item.price"
        :image-url="item.imageUrl"
        :product-type="item.productType"
        :condition="item.condition"
        :stock="item.stock"
        :min-stock="item.minStock"
        :seller-name="item.sellerName"
        :eager="index < 8"
      />
    </div>

    <div v-if="!loading && !errorText && total > 0" class="pager">
      <span class="pager__count">共 {{ total }} 件</span>
      <el-pagination
        :current-page="pageNum"
        :page-size="pageSize"
        :page-sizes="[...PAGE_SIZES]"
        :total="total"
        layout="prev, pager, next, sizes"
        background
        @current-change="(value: number) => writeQuery({ pageNum: value }, false)"
        @size-change="(value: number) => writeQuery({ pageSize: value })"
      />
    </div>
  </div>
</template>

<style scoped>
.page {
  padding-bottom: var(--space-8);
}

/* --- 类型分段控件 --------------------------------------------------------- */

.seg {
  display: inline-flex;
  padding: 2px;
  background: var(--paper-2);
  border-radius: var(--radius-sm);
}

.seg__item {
  padding: 5px 12px;
  border: none;
  border-radius: var(--radius-xs);
  background: transparent;
  font-size: var(--text-sm);
  color: var(--ink-3);
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.seg__item:hover {
  color: var(--ink-1);
}

.seg__item.is-active {
  background: var(--paper-0);
  color: var(--ink-0);
  font-weight: 600;
}

/* --- 筛选面板 ------------------------------------------------------------- */

.filters {
  margin-bottom: var(--space-5);
}

.filters__row {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  border-bottom: var(--hairline);
}

.filters__row:last-child {
  border-bottom: none;
}

.filters__row--cats {
  gap: var(--space-1);
  background: var(--paper-1);
  overflow-x: auto;
  scrollbar-width: none;
}

.filters__row--cats::-webkit-scrollbar {
  display: none;
}

.filters__controls {
  display: flex;
  gap: var(--space-2);
  margin-left: auto;
  flex-shrink: 0;
}

.filters__select {
  width: 150px;
}

.search {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex: 1;
  min-width: 200px;
  max-width: 460px;
  height: var(--control-h);
  padding-left: 10px;
  background: var(--paper-1);
  border: var(--edge);
  border-radius: var(--radius-xs);
  color: var(--ink-3);
}

.search:focus-within {
  border-color: var(--ink-0);
  background: var(--paper-0);
}

.search__input {
  flex: 1;
  min-width: 0;
  border: none;
  outline: none;
  background: transparent;
  font-size: var(--text-base);
  color: var(--ink-0);
}

.search__input::placeholder {
  color: var(--ink-4);
}

.search__go {
  height: 100%;
  padding-inline: 14px;
  border: none;
  border-left: var(--hairline);
  background: transparent;
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-1);
  cursor: pointer;
}

.search__go:hover {
  background: var(--paper-2);
}

.cat {
  flex-shrink: 0;
  padding: 6px 12px;
  border: 1px solid transparent;
  border-radius: var(--radius-sm);
  background: transparent;
  font-size: var(--text-sm);
  color: var(--ink-3);
  cursor: pointer;
  white-space: nowrap;
  transition:
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.cat:hover {
  background: var(--paper-2);
  color: var(--ink-1);
}

.cat.is-active {
  background: var(--paper-0);
  border-color: var(--line-2);
  color: var(--ink-0);
  font-weight: 600;
}

.reset {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  margin-left: auto;
  padding: 6px 10px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  font-size: var(--text-sm);
  color: var(--ink-3);
  cursor: pointer;
  white-space: nowrap;
}

.reset:hover {
  background: var(--paper-2);
  color: var(--ink-1);
}

/* --- 已选条件 ------------------------------------------------------------- */

.chips {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-3) var(--space-4);
  background: var(--paper-1);
  border-top: var(--hairline);
}

.chips__label {
  font-size: var(--text-xs);
  color: var(--ink-4);
}

.chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 8px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  font-size: var(--text-xs);
  color: var(--ink-2);
  cursor: pointer;
}

.chip:hover {
  border-color: var(--ink-4);
  color: var(--ink-0);
}

/* --- 网格 ----------------------------------------------------------------- */

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

/* --- 分页 ----------------------------------------------------------------- */

.pager {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  margin-top: var(--space-6);
  padding-top: var(--space-4);
  border-top: var(--hairline);
}

.pager__count {
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  height: var(--control-h);
  padding-inline: 14px;
  border: none;
  border-radius: var(--radius-sm);
  background: var(--ink-0);
  color: var(--on-ink);
  font-size: var(--text-sm);
  font-weight: 600;
  cursor: pointer;
}

.btn:hover {
  background: var(--ink-1);
}

@media (max-width: 900px) {
  .filters__row {
    flex-wrap: wrap;
  }
  .filters__controls {
    margin-left: 0;
  }
  .filters__select {
    width: calc(50% - var(--space-1));
  }
  .search {
    max-width: none;
  }
  .grid {
    grid-template-columns: repeat(auto-fill, minmax(166px, 1fr));
    gap: var(--space-3);
  }
  .pager {
    flex-direction: column;
    align-items: flex-start;
  }
}

@media (max-width: 520px) {
  .seg__item {
    padding: 5px 9px;
  }
  .grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .filters__select {
    width: 100%;
  }
}
</style>
