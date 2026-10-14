<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import ProductCard from '@/components/ui/ProductCard.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import AppIcon from '@/components/ui/AppIcon.vue'
import { conditionLabel } from '@/constants/domain'
import {
  getBrands,
  getCategories,
  getProducts,
  getSubCategories,
  type ShopQuery,
} from '@/api/user/shop'

/**
 * 二手交易列表。
 *
 * 二手是「单件在售 + 成色分级」的生意：买家先看成色，再看瑕疵与实拍图，最后才
 * 谈价格。页面按 分类 → 成色 → 价格 → 卖家 的顺序给信息，库存位写成
 * 「单件在售 / 已售出」，不冒充多件库存。
 *
 * 列表走商城的 /shop/products（productType=2）。原实现的三处问题在这里修掉：
 *  - 图片兜底指向并不存在的 /images/default-product.png
 *  - 成色筛选与成色文案各维护一张映射表，与后端 condition 的百分比口径不一致
 *  - 请求失败静默降级成空列表，用户分不清「没有货」和「没请求到」
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

const categories = ref<CategoryTab[]>([])
const brands = ref<Option[]>([])
const subCategories = ref<Option[]>([])

const category = ref('all')
const brand = ref<string | number>('')
const type = ref('')
const condition = ref('')
const sort = ref('newest')
const keyword = ref('')

const pageNum = ref(1)
const pageSize = ref(12)
const total = ref(0)

const items = ref<any[]>([])
const loading = ref(true)
const failed = ref(false)

const tabs = computed<CategoryTab[]>(() => [
  { id: 0, code: 'all', name: '全部在售' },
  ...categories.value,
])

/**
 * 成色选项从 domain 的 conditionLabel 反推，不再维护第二张映射表。
 * 相邻档位落在同一档（80 / 85 都是「8成新」）时自然去重。
 */
const conditionOptions = computed<Option[]>(() => {
  const seen = new Set<string>()
  const options: Option[] = []
  for (const value of [99, 95, 90, 85, 80]) {
    const label = conditionLabel(value)
    if (!label || seen.has(label)) continue
    seen.add(label)
    options.push({ value: String(value), label })
  }
  return options
})

const hasFilter = computed(
  () =>
    category.value !== 'all' ||
    brand.value !== '' ||
    type.value !== '' ||
    condition.value !== '' ||
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
      // 取不到分类时保留「全部在售」页签，列表本身照常可用。
    }
    if (attempt === 0) await new Promise((resolve) => setTimeout(resolve, 150))
  }
  return []
}

/** 后端对缺图商品会回填一个并不存在的 default-product.png，这里当成没图处理。 */
function imageOf(path?: string | null): string | null {
  if (!path) return null
  const value = String(path)
  return value.includes('default-product') ? null : value
}

async function load() {
  loading.value = true
  failed.value = false
  const query: ShopQuery = {
    productType: 2,
    category: category.value === 'all' ? undefined : category.value,
    brand: brand.value === '' ? undefined : brand.value,
    type: type.value === '' ? undefined : type.value,
    condition: condition.value === '' ? undefined : condition.value,
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
  condition.value = ''
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

/** 站内导航回到本页时，关键词以地址栏为准。 */
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
        <h1 class="head__title">二手交易</h1>
        <p class="head__note">
          单件在售，成色与瑕疵随商品标注。价格、使用时长与实拍图都在详情页里。
        </p>
      </div>
      <p v-if="!loading && !failed" class="head__count">
        <span class="tnum">{{ total }}</span> 件在售
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
          <span class="field__label">成色</span>
          <el-select
            v-model="condition"
            class="field__control"
            size="small"
            placeholder="不限"
            @change="applyFilter"
          >
            <el-option label="不限" value="" />
            <el-option
              v-for="item in conditionOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </label>

        <label class="field">
          <span class="field__label">排序</span>
          <el-select v-model="sort" class="field__control" size="small" @change="applyFilter">
            <el-option label="最新发布" value="newest" />
            <el-option label="价格从低到高" value="price_asc" />
            <el-option label="价格从高到低" value="price_desc" />
          </el-select>
        </label>
      </div>

      <form class="search" role="search" @submit.prevent="applyFilter">
        <AppIcon name="search" size="15" />
        <input
          v-model="keyword"
          class="search__input"
          type="search"
          placeholder="搜索品牌或型号，例如 D850、EOS R5"
          aria-label="搜索二手器材"
        />
        <button class="search__go" type="submit">搜索</button>
      </form>

      <button v-if="hasFilter" class="reset" type="button" @click="resetFilters">
        <AppIcon name="refresh" size="14" />
        清除筛选
      </button>
    </div>

    <div v-if="loading" class="grid" aria-busy="true">
      <div v-for="n in 8" :key="n" class="ghost">
        <div class="ghost__media skeleton" />
        <div class="ghost__line skeleton" />
        <div class="ghost__line ghost__line--short skeleton" />
      </div>
    </div>

    <EmptyState v-else-if="failed" title="加载失败" note="没能取到二手商品列表，检查网络后重试。">
      <el-button type="primary" @click="load">重试</el-button>
    </EmptyState>

    <EmptyState
      v-else-if="!items.length"
      :title="hasFilter ? '没有符合条件的二手器材' : '暂无在售的二手器材'"
      :note="
        hasFilter ? '放宽筛选条件，或换个关键词再试。' : '商家上架并通过审核后，器材会出现在这里。'
      "
    >
      <el-button v-if="hasFilter" @click="resetFilters">清除筛选</el-button>
      <RouterLink v-else class="link-more" to="/shop">看看全新器材</RouterLink>
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
        :image-url="imageOf(item.imageUrl)"
        :product-type="2"
        :condition="item.condition"
        :stock-tip="item.stock > 0 ? '单件在售' : '已售出'"
        :seller-name="item.sellerName"
        :to="`/second-hand/detail/${item.productId}`"
        :eager="index < 4"
      />
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

/* --- category tabs -------------------------------------------------------- */

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

/* --- filters -------------------------------------------------------------- */

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

.link-more {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--ink-1);
}

/* --- grid ----------------------------------------------------------------- */

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

.pager {
  display: flex;
  justify-content: flex-end;
  margin-top: var(--space-6);
}

@media (max-width: 900px) {
  .grid {
    grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
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

  .grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
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
