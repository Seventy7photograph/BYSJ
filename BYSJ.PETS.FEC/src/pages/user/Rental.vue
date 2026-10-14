<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import PriceTag from '@/components/ui/PriceTag.vue'
import SpecList, { type SpecEntry } from '@/components/ui/SpecList.vue'
import StatePill from '@/components/ui/StatePill.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import AppIcon from '@/components/ui/AppIcon.vue'
import { conditionLabel } from '@/constants/domain'
import { formatMoney, rentalUnit } from '@/utils/format'
import {
  getBrands,
  getCategories,
  getProducts,
  getSubCategories,
  type ShopQuery,
} from '@/api/user/shop'

/**
 * 器材租赁列表。
 *
 * 租赁按天计价，买家要回答的问题和买新机不一样：押金多少、几天起租、现在有没有
 * 空档、取货要不要加钱。所以这里没有沿用商城的网格卡片，而是把每条器材铺成一行
 * 「图 + 规格轨 + 租金」，押金与起租天数和价格一样醒目。
 *
 * 列表接口沿用 /shop/products（productType=3），租金范围、分类、品牌、排序与原来一致。
 */

const route = useRoute()

interface CategoryTab {
  id: number
  code: string
  name: string
}

interface Option {
  label: string
  value: string | number
}

const PRICE_RANGES: Option[] = [
  { label: '不限', value: '' },
  { label: '50 元/天以内', value: '0-50' },
  { label: '50 - 100 元/天', value: '50-100' },
  { label: '100 - 200 元/天', value: '100-200' },
  { label: '200 元/天以上', value: '200+' },
]

const categories = ref<CategoryTab[]>([])
const brands = ref<Option[]>([])
const subCategories = ref<Option[]>([])

const category = ref('all')
const brand = ref<string | number>('')
const type = ref('')
const priceRange = ref('')
const sort = ref('newest')
const keyword = ref('')

const pageNum = ref(1)
const pageSize = ref(12)
const total = ref(0)

const items = ref<any[]>([])
const loading = ref(true)
const failed = ref(false)

const tabs = computed<CategoryTab[]>(() => [
  { id: 0, code: 'all', name: '全部可租' },
  ...categories.value,
])

const hasFilter = computed(
  () =>
    category.value !== 'all' ||
    brand.value !== '' ||
    type.value !== '' ||
    priceRange.value !== '' ||
    keyword.value.trim() !== '',
)

const currentCategory = computed(() =>
  categories.value.find((item) => item.code === category.value),
)

/**
 * 分类页签。
 *
 * 页头与本页会在同一帧各取一次 /shop/categories，而 axios 层按「方法 + 路径 + 参数」
 * 取消并发重复请求，被取消的那一次会拿到 { list: [], total: 0 } 这种兜底值。这里读一次，
 * 拿不到成形结果就稍后重试一次，避免分类页签整排消失。
 */
async function loadCategoryTabs(): Promise<CategoryTab[]> {
  for (let attempt = 0; attempt < 2; attempt += 1) {
    try {
      const res = await getCategories()
      const list = Array.isArray(res?.categoryList) ? res.categoryList : []
      if (list.length) {
        return list.map((item: any) => ({
          id: Number(item.id),
          code: String(item.value),
          name: String(item.name),
        }))
      }
    } catch {
      // 取不到分类时保留「全部可租」页签，列表本身照常可用。
    }
    if (attempt === 0) await new Promise((resolve) => setTimeout(resolve, 150))
  }
  return []
}

function imageOf(path?: string | null): string | null {
  if (!path) return null
  const value = String(path)
  return value.includes('default-product') ? null : value
}

/** 每行器材的规格轨：押金、起租天数、成色、可租数量，都是决定租不租的硬信息。 */
function specOf(item: any): SpecEntry[] {
  const stock = Number(item.stock ?? 0)
  return [
    { key: '押金', value: formatMoney(item.deposit) },
    { key: '起租', value: rentalUnit(item.minRentalDays) },
    { key: '成色', value: conditionLabel(item.condition) },
    { key: '可租', value: stock > 0 ? `可租 ${stock} 台` : '已租完' },
  ]
}

function titleOf(item: any): string {
  const model = item.name || '未命名器材'
  return item.brandName ? `${item.brandName} ${model}` : model
}

async function load() {
  loading.value = true
  failed.value = false
  const query: ShopQuery = {
    productType: 3,
    category: category.value === 'all' ? undefined : category.value,
    brand: brand.value === '' ? undefined : brand.value,
    type: type.value === '' ? undefined : type.value,
    priceRange: priceRange.value === '' ? undefined : priceRange.value,
    keyword: keyword.value.trim() || undefined,
    sort: sort.value,
    pageNum: pageNum.value,
    pageSize: pageSize.value,
  }
  try {
    const res = await getProducts(query)
    items.value = res.list
    total.value = res.total
  } catch {
    items.value = []
    total.value = 0
    failed.value = true
  } finally {
    loading.value = false
  }
}

async function loadBrands() {
  const current = currentCategory.value
  brand.value = ''
  if (!current) {
    brands.value = []
    return
  }
  try {
    brands.value = await getBrands(current.id)
  } catch {
    brands.value = []
  }
}

async function loadSubCategories() {
  const current = currentCategory.value
  type.value = ''
  if (!current) {
    subCategories.value = []
    return
  }
  try {
    subCategories.value = await getSubCategories(current.id)
  } catch {
    subCategories.value = []
  }
}

function pickCategory(code: string) {
  if (category.value === code) return
  category.value = code
  void Promise.all([loadBrands(), loadSubCategories()]).then(() => {
    pageNum.value = 1
    return load()
  })
}

function applyFilter() {
  pageNum.value = 1
  void load()
}

function resetFilters() {
  category.value = 'all'
  brand.value = ''
  type.value = ''
  priceRange.value = ''
  keyword.value = ''
  brands.value = []
  subCategories.value = []
  pageNum.value = 1
  void load()
}

function onPage(page: number) {
  pageNum.value = page
  void load()
}

function onSize(size: number) {
  pageSize.value = size
  pageNum.value = 1
  void load()
}

watch(
  () => route.query.keyword,
  (value) => {
    const next = typeof value === 'string' ? value : ''
    if (next === keyword.value) return
    keyword.value = next
    pageNum.value = 1
    void load()
  },
)

onMounted(async () => {
  if (typeof route.query.keyword === 'string') keyword.value = route.query.keyword
  categories.value = await loadCategoryTabs()
  await load()
})
</script>

<template>
  <div class="shell">
    <header class="head">
      <div>
        <h1 class="head__title">器材租赁</h1>
        <p class="head__note">
          按天计价。押金在归还并验收后原路退回，租期与费用可以在详情页里先算一遍。
        </p>
      </div>
      <p v-if="!loading && !failed" class="head__count">
        <span class="tnum">{{ total }}</span> 台可租
      </p>
    </header>

    <div class="tabs" role="tablist" aria-label="器材分类">
      <button
        v-for="tab in tabs"
        :key="tab.code"
        class="tabs__item"
        :class="{ 'is-active': category === tab.code }"
        type="button"
        role="tab"
        :aria-selected="category === tab.code"
        @click="pickCategory(tab.code)"
      >
        {{ tab.name }}
      </button>
    </div>

    <div class="filters">
      <div class="filters__fields">
        <label v-if="brands.length" class="field">
          <span class="field__label">品牌</span>
          <el-select
            v-model="brand"
            class="field__control"
            size="small"
            placeholder="不限"
            @change="applyFilter"
          >
            <el-option label="不限" value="" />
            <el-option
              v-for="item in brands"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </label>

        <label v-if="subCategories.length" class="field">
          <span class="field__label">类型</span>
          <el-select
            v-model="type"
            class="field__control"
            size="small"
            placeholder="不限"
            @change="applyFilter"
          >
            <el-option label="不限" value="" />
            <el-option
              v-for="item in subCategories"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </label>

        <label class="field">
          <span class="field__label">租金</span>
          <el-select
            v-model="priceRange"
            class="field__control"
            size="small"
            placeholder="不限"
            @change="applyFilter"
          >
            <el-option
              v-for="item in PRICE_RANGES"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </label>

        <label class="field">
          <span class="field__label">排序</span>
          <el-select v-model="sort" class="field__control" size="small" @change="applyFilter">
            <el-option label="最新上架" value="newest" />
            <el-option label="租金从低到高" value="price_asc" />
            <el-option label="租金从高到低" value="price_desc" />
          </el-select>
        </label>
      </div>

      <form class="search" role="search" @submit.prevent="applyFilter">
        <AppIcon name="search" size="15" />
        <input
          v-model="keyword"
          class="search__input"
          type="search"
          placeholder="搜索品牌或型号，例如 A7M4、24-70"
          aria-label="搜索可租器材"
        />
        <button class="search__go" type="submit">搜索</button>
      </form>

      <button v-if="hasFilter" class="reset" type="button" @click="resetFilters">
        <AppIcon name="refresh" size="14" />
        清除筛选
      </button>
    </div>

    <div v-if="loading" class="list" aria-busy="true">
      <div v-for="n in 6" :key="n" class="ghost">
        <div class="ghost__media skeleton" />
        <div class="ghost__body">
          <div class="ghost__line skeleton" />
          <div class="ghost__line ghost__line--short skeleton" />
        </div>
      </div>
    </div>

    <EmptyState v-else-if="failed" title="加载失败" note="没能取到可租器材列表，检查网络后重试。">
      <el-button type="primary" @click="load">重试</el-button>
    </EmptyState>

    <EmptyState
      v-else-if="!items.length"
      :title="hasFilter ? '没有符合条件的可租器材' : '暂无可租的器材'"
      :note="
        hasFilter
          ? '放宽租金范围或换个分类，再试一次。'
          : '商家上架并通过审核后，可租器材会出现在这里。'
      "
    >
      <el-button v-if="hasFilter" @click="resetFilters">清除筛选</el-button>
    </EmptyState>

    <div v-else class="list">
      <RouterLink
        v-for="(item, index) in items"
        :key="item.productId"
        class="item"
        :to="`/rental/detail/${item.productId}`"
      >
        <div class="item__media">
          <ImageFrame
            :src="imageOf(item.imageUrl)"
            :alt="titleOf(item)"
            ratio="4 / 3"
            fit="contain"
            :eager="index < 4"
          />
          <span class="item__type"><StatePill label="租赁" tone="teal" /></span>
        </div>

        <div class="item__main">
          <h2 class="item__name">{{ titleOf(item) }}</h2>
          <SpecList class="item__spec" :entries="specOf(item)" :columns="2" />
          <p v-if="item.sellerName || item.categoryName" class="item__note">
            {{ item.sellerName || '未知卖家' }}
            <span v-if="item.categoryName"> · {{ item.categoryName }}</span>
          </p>
        </div>

        <div class="item__aside">
          <PriceTag :price="item.price" unit="/天" size="lg" :show-original="false" />
          <span class="item__hint">
            租期与押金计算
            <AppIcon name="chevron-right" size="14" />
          </span>
        </div>
      </RouterLink>
    </div>

    <div v-if="!loading && !failed && total > pageSize" class="pager">
      <el-pagination
        :current-page="pageNum"
        :page-size="pageSize"
        :page-sizes="[12, 24, 48]"
        :total="total"
        background
        layout="total, sizes, prev, pager, next"
        @current-change="onPage"
        @size-change="onSize"
      />
    </div>
  </div>
</template>

<style scoped>
.head {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--space-4);
  padding-bottom: var(--space-4);
}

.head__title {
  font-size: var(--text-lg);
}

.head__note {
  margin-top: var(--space-1);
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.head__count {
  flex-shrink: 0;
  font-size: var(--text-sm);
  color: var(--ink-3);
}

/* --- tabs & filters ------------------------------------------------------- */

.tabs {
  display: flex;
  gap: var(--space-1);
  padding-bottom: var(--space-3);
  border-bottom: var(--hairline);
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

.filters {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-4) 0 var(--space-3);
}

.filters__fields {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-3);
}

.field {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
}

.field__label {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.field__control {
  width: calc(var(--space-16) * 2);
}

.search {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex: 1 1 240px;
  max-width: 360px;
  height: var(--control-h);
  padding-left: var(--space-3);
  background: var(--paper-1);
  border: 1px solid var(--line-2);
  border-radius: var(--radius-xs);
  color: var(--ink-3);
  transition: border-color var(--dur-state) ease;
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
  font-size: var(--text-sm);
  color: var(--ink-0);
}

.search__input::placeholder {
  color: var(--ink-4);
}

.search__go {
  height: 100%;
  padding-inline: var(--space-4);
  border: none;
  border-left: 1px solid var(--line-2);
  background: transparent;
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-1);
  cursor: pointer;
  transition: background-color var(--dur-state) ease;
}

.search__go:hover {
  background: var(--paper-2);
}

.reset {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  height: var(--control-h);
  padding-inline: var(--space-3);
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  font-size: var(--text-sm);
  color: var(--ink-3);
  cursor: pointer;
  transition: background-color var(--dur-state) ease;
}

.reset:hover {
  background: var(--paper-2);
  color: var(--ink-0);
}

/* --- listing rows --------------------------------------------------------- */

.list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.item {
  display: grid;
  grid-template-columns: 208px minmax(0, 1fr) 224px;
  align-items: center;
  gap: var(--space-5);
  padding: var(--space-4);
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
  transition:
    background-color var(--dur-state) ease,
    border-color var(--dur-state) ease;
}

.item:hover {
  text-decoration: none;
  border-color: var(--ink-4);
  background: var(--paper-1);
}

.item:focus-visible {
  box-shadow: var(--focus-ring);
}

.item__media {
  position: relative;
  border: var(--hairline);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.item__type {
  position: absolute;
  top: var(--space-2);
  left: var(--space-2);
}

.item__main {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  min-width: 0;
}

.item__name {
  margin: 0;
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--ink-0);
  line-height: 1.4;
}

.item__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.item__aside {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: var(--space-2);
  text-align: right;
}

.item__hint {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.item:hover .item__hint {
  color: var(--signal-amber-deep);
}

/* --- skeleton ------------------------------------------------------------- */

.ghost {
  display: grid;
  grid-template-columns: 208px minmax(0, 1fr);
  align-items: center;
  gap: var(--space-5);
  padding: var(--space-4);
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
}

.ghost__media {
  aspect-ratio: 4 / 3;
  border-radius: var(--radius-sm);
}

.ghost__body {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.ghost__line {
  height: 12px;
  border-radius: var(--radius-xs);
}

.ghost__line--short {
  width: 55%;
}

.pager {
  display: flex;
  justify-content: flex-end;
  margin-top: var(--space-6);
}

@media (max-width: 900px) {
  .item,
  .ghost {
    grid-template-columns: 148px minmax(0, 1fr);
    gap: var(--space-4);
  }

  .item__aside {
    grid-column: 2;
    text-align: left;
    flex-direction: row;
    align-items: baseline;
    justify-content: space-between;
    gap: var(--space-3);
  }

  .search {
    flex-basis: 100%;
    max-width: none;
  }
}

@media (max-width: 520px) {
  .head {
    flex-direction: column;
    align-items: flex-start;
    gap: var(--space-2);
  }

  .item,
  .ghost {
    grid-template-columns: minmax(0, 1fr);
    gap: var(--space-3);
  }

  .item__aside {
    grid-column: 1;
  }

  .filters__fields {
    width: 100%;
    gap: var(--space-2);
  }

  .field__control {
    width: calc(var(--space-16) * 1.5);
  }
}
</style>
