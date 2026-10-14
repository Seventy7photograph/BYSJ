<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import PriceTag from '@/components/ui/PriceTag.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { useUserStore } from '@/stores/user'
import { user } from '@/api'
import {
  batchRemoveFavorites,
  getFavoriteList,
  removeFavoriteById,
  type FavoriteItem,
} from '@/api/user/favorite'
import { conditionLabel, labelOf, PRODUCT_TYPE } from '@/constants/domain'
import { formatDate, stockNote } from '@/utils/format'

/**
 * 我的收藏。
 *
 * 原页面的三个硬伤：
 *   1. 列表接口把 Result 当分页对象读，list 恒为 undefined，页面永远空；
 *   2. 类型页签用 `Number(item.productType)` 判断，而后端给的 productType 是
 *      'new' / 'second-hand' / 'rent' 字符串，Number('new') 是 NaN，四个页签
 *      只有「全部」有结果；
 *   3. 批量删除用的 id 字段、成色映射（'99' → '99新'）都是自造的，与
 *      FavoriteDTO 的 condition 对不上。
 *
 * 现在：一次把收藏全部取回（分页拉完），类型筛选与分页在前端做，两者始终
 * 指向同一份完整数据；取消收藏按 favoriteId，批量走 /favorites/batch-delete。
 */
const router = useRouter()
const userStore = useUserStore()

const PAGE_SIZE = 100
const MAX_PAGES = 5

const items = ref<FavoriteItem[]>([])
const loading = ref(true)
const error = ref('')
const truncated = ref(false)

const activeType = ref<'all' | 1 | 2 | 3>('all')
const pageNum = ref(1)
const perPage = ref(12)
const selectedIds = ref<number[]>([])
const removing = ref(false)

const TYPE_TABS = [
  { key: 'all' as const, label: '全部' },
  { key: 1 as const, label: '全新' },
  { key: 2 as const, label: '二手' },
  { key: 3 as const, label: '租赁' },
]

const typed = computed(() =>
  activeType.value === 'all'
    ? items.value
    : items.value.filter((item) => Number(item.product_type) === activeType.value),
)

const totalPages = computed(() => Math.max(1, Math.ceil(typed.value.length / perPage.value)))

const paged = computed(() => {
  const start = (pageNum.value - 1) * perPage.value
  return typed.value.slice(start, start + perPage.value)
})

const allPicked = computed(
  () => paged.value.length > 0 && paged.value.every((item) => selectedIds.value.includes(item.id)),
)

const countOf = computed(() => {
  const counts: Record<string, number> = { all: items.value.length, '1': 0, '2': 0, '3': 0 }
  for (const item of items.value) {
    const key = String(item.product_type ?? '')
    if (key in counts) counts[key] = (counts[key] ?? 0) + 1
  }
  return counts
})

/** 取消收藏后当前页可能超出范围，回落到最后一页。 */
watch(totalPages, (max) => {
  if (pageNum.value > max) pageNum.value = max
})

function specLine(item: FavoriteItem): string {
  const grade = conditionLabel(item.condition)
  return [grade, item.brandName].filter(Boolean).join(' · ') || '—'
}

function detailLink(item: FavoriteItem): string {
  if (Number(item.product_type) === 2) return `/second-hand/detail/${item.productId}`
  if (Number(item.product_type) === 3) return `/rental/detail/${item.productId}`
  return `/product/${item.productId}`
}

/** 分页拉完整个收藏列表；后端单页上限之外还会继续翻页。 */
async function load() {
  loading.value = true
  error.value = ''
  truncated.value = false
  try {
    const collected: FavoriteItem[] = []
    let page = 1
    let total = 0
    do {
      const res = await getFavoriteList({ pageNum: page, pageSize: PAGE_SIZE })
      collected.push(...res.list)
      total = res.total
      page += 1
    } while (collected.length < total && page <= MAX_PAGES)

    items.value = collected
    truncated.value = collected.length < total
    selectedIds.value = []
    pageNum.value = 1
  } catch (e) {
    error.value = e instanceof Error ? e.message : '收藏列表加载失败，请稍后重试'
    items.value = []
  } finally {
    loading.value = false
  }
}

function switchType(key: 'all' | 1 | 2 | 3) {
  activeType.value = key
  pageNum.value = 1
  selectedIds.value = []
}

function togglePick(item: FavoriteItem, picked: boolean) {
  const next = new Set(selectedIds.value)
  if (picked) next.add(item.id)
  else next.delete(item.id)
  selectedIds.value = [...next]
}

function togglePickPage(picked: boolean) {
  const next = new Set(selectedIds.value)
  for (const item of paged.value) {
    if (picked) next.add(item.id)
    else next.delete(item.id)
  }
  selectedIds.value = [...next]
}

/** 复选框的 change 事件统一在这里取值，模板里不写类型断言。 */
function onPickItem(item: FavoriteItem, event: Event) {
  togglePick(item, (event.target as HTMLInputElement).checked)
}

function onPickPage(event: Event) {
  togglePickPage((event.target as HTMLInputElement).checked)
}

async function removeOne(item: FavoriteItem) {
  try {
    await ElMessageBox.confirm(`取消收藏「${item.productName || '该商品'}」？`, '取消收藏', {
      confirmButtonText: '取消收藏',
      cancelButtonText: '再想想',
    })
  } catch {
    return
  }
  try {
    await removeFavoriteById(item.id)
    items.value = items.value.filter((row) => row.id !== item.id)
    selectedIds.value = selectedIds.value.filter((id) => id !== item.id)
    ElMessage.success('已取消收藏')
  } catch (e) {
    ElMessage.error(e instanceof Error ? e.message : '取消收藏失败')
  }
}

async function removeSelected() {
  const ids = [...selectedIds.value]
  if (!ids.length) return
  try {
    await ElMessageBox.confirm(`取消收藏选中的 ${ids.length} 件商品？`, '批量取消收藏', {
      confirmButtonText: '取消收藏',
      cancelButtonText: '再想想',
    })
  } catch {
    return
  }
  removing.value = true
  try {
    await batchRemoveFavorites(ids)
    items.value = items.value.filter((row) => !ids.includes(row.id))
    selectedIds.value = []
    ElMessage.success(`已取消收藏 ${ids.length} 件商品`)
    if (pageNum.value > totalPages.value) pageNum.value = totalPages.value
  } catch (e) {
    ElMessage.error(e instanceof Error ? e.message : '批量取消收藏失败')
  } finally {
    removing.value = false
  }
}

async function addToCart(item: FavoriteItem) {
  try {
    await user.cart.addToCart({ productId: item.productId, quantity: 1 })
    ElMessage.success('已加入购物车')
  } catch (e: any) {
    ElMessage.error(e?.msg || (e instanceof Error ? e.message : '加入购物车失败'))
  }
}

onMounted(() => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }
  void load()
})
</script>

<template>
  <div class="shell favorites">
    <SectionHead
      title="我的收藏"
      :note="`共 ${items.length} 件，已选 ${selectedIds.length} 件`"
      size="lg"
    >
      <template #action>
        <button
          class="btn btn--danger"
          type="button"
          :disabled="!selectedIds.length || removing"
          @click="removeSelected"
        >
          <AppIcon name="trash" size="14" />
          批量取消收藏
        </button>
      </template>
    </SectionHead>

    <div class="tabs" role="tablist" aria-label="收藏商品类型">
      <button
        v-for="tab in TYPE_TABS"
        :key="String(tab.key)"
        class="tabs__item"
        :class="{ 'is-active': activeType === tab.key }"
        type="button"
        role="tab"
        :aria-selected="activeType === tab.key"
        @click="switchType(tab.key)"
      >
        {{ tab.label }}
        <span class="tabs__count">{{ countOf[String(tab.key)] ?? 0 }}</span>
      </button>
    </div>

    <!-- 加载：与卡片同规格的骨架 -->
    <div v-if="loading" class="grid" aria-busy="true">
      <div v-for="n in 8" :key="n" class="ghost">
        <div class="ghost__media skeleton" />
        <div class="ghost__line skeleton" />
        <div class="ghost__line ghost__line--short skeleton" />
      </div>
    </div>

    <!-- 错误：说明问题并给出重试 -->
    <div v-else-if="error" class="plate state">
      <AppIcon name="warning" size="22" />
      <p class="state__title">收藏没能加载出来</p>
      <p class="state__note">{{ error }}</p>
      <button class="btn" type="button" @click="load">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
    </div>

    <EmptyState
      v-else-if="!typed.length"
      :title="items.length ? '这个类型下没有收藏' : '还没有收藏任何器材'"
      :note="
        items.length
          ? '换一个类型看看，或选「全部」查看所有收藏。'
          : '在商品页点「收藏」，之后就能在这里比较价格和成色。'
      "
    >
      <RouterLink class="btn" to="/shop">
        去商城逛逛
        <AppIcon name="chevron-right" size="14" />
      </RouterLink>
    </EmptyState>

    <template v-else>
      <div class="pickbar">
        <label class="check">
          <input
            type="checkbox"
            :checked="allPicked"
            @change="onPickPage"
          />
          <span>全选本页</span>
        </label>
        <span class="pickbar__note">
          {{ paged.length }} 件 / 本页，第 {{ pageNum }} / {{ totalPages }} 页
        </span>
      </div>

      <ul class="grid">
        <li
          v-for="item in paged"
          :key="item.id"
          class="fav"
          :class="{ 'is-picked': selectedIds.includes(item.id) }"
        >
          <div class="fav__media">
            <ImageFrame
              :src="item.productImage"
              :alt="item.productName || '商品图'"
              ratio="4 / 3"
              fit="contain"
            />
            <span class="fav__type">
              <StatePill
                :label="labelOf(PRODUCT_TYPE, item.product_type).label"
                :tone="labelOf(PRODUCT_TYPE, item.product_type).tone"
              />
            </span>
            <label class="fav__pick">
              <input
                type="checkbox"
                :checked="selectedIds.includes(item.id)"
                @change="onPickItem(item, $event)"
              />
              <span class="sr-only">选择 {{ item.productName || '该商品' }}</span>
            </label>
          </div>

          <div class="fav__body">
            <h3 class="fav__name">
              <RouterLink :to="detailLink(item)">{{ item.productName || '未命名商品' }}</RouterLink>
            </h3>
            <p class="fav__spec">{{ specLine(item) }}</p>
            <div class="fav__foot">
              <PriceTag
                :price="item.price"
                :unit="Number(item.product_type) === 3 ? '/天' : null"
                size="sm"
                :show-original="false"
              />
              <span
                class="fav__stock"
                :class="{ 'is-out': stockNote(item.stock).out, 'is-low': stockNote(item.stock).low }"
              >
                {{ stockNote(item.stock).text }}
              </span>
            </div>
            <p class="fav__time">收藏于 {{ formatDate(item.createdAt) }}</p>
          </div>

          <div class="fav__actions">
            <button
              v-if="Number(item.product_type) !== 3 && (item.stock ?? 0) > 0"
              class="link"
              type="button"
              @click="addToCart(item)"
            >
              加入购物车
            </button>
            <RouterLink v-else class="link" :to="detailLink(item)">查看商品</RouterLink>
            <button class="link link--danger" type="button" @click="removeOne(item)">取消收藏</button>
          </div>
        </li>
      </ul>

      <div v-if="totalPages > 1" class="pager">
        <el-pagination
          :current-page="pageNum"
          :page-size="perPage"
          :total="typed.length"
          :pager-count="5"
          layout="prev, pager, next"
          background
          @current-change="(page: number) => (pageNum = page)"
        />
      </div>

      <p v-if="truncated" class="foot-note">
        收藏超过 {{ PAGE_SIZE * MAX_PAGES }} 件，这里只显示前 {{ items.length }} 件。
      </p>
    </template>
  </div>
</template>

<style scoped>
.favorites {
  padding-block: var(--space-6) var(--space-16);
}

/* --- type tabs ------------------------------------------------------------ */

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
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border: 1px solid transparent;
  border-radius: var(--radius-sm);
  background: transparent;
  font-size: var(--text-sm);
  color: var(--ink-3);
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    border-color var(--dur-state) ease,
    color var(--dur-state) ease;
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

.tabs__count {
  font-size: var(--text-2xs);
  color: var(--ink-4);
}

.tabs__item.is-active .tabs__count {
  color: var(--ink-3);
}

/* --- pick bar ------------------------------------------------------------- */

.pickbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  padding: 10px 14px;
  margin-bottom: var(--space-3);
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-sm);
}

.pickbar__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.check {
  display: inline-flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--ink-1);
  cursor: pointer;
}

input[type='checkbox'] {
  width: 15px;
  height: 15px;
  accent-color: var(--ink-0);
  cursor: pointer;
}

/* --- grid ----------------------------------------------------------------- */

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(232px, 1fr));
  gap: var(--space-4);
  margin: 0;
  padding: 0;
  list-style: none;
}

/* --- card ----------------------------------------------------------------- */

.fav {
  display: flex;
  flex-direction: column;
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
  overflow: hidden;
  transition:
    border-color var(--dur-state) ease,
    background-color var(--dur-state) ease;
}

.fav:hover {
  border-color: var(--ink-4);
}

.fav.is-picked {
  border-color: var(--ink-0);
  background: var(--paper-1);
}

.fav__media {
  position: relative;
  border-bottom: var(--hairline);
}

.fav__type {
  position: absolute;
  top: var(--space-2);
  left: var(--space-2);
}

.fav__pick {
  position: absolute;
  top: var(--space-2);
  right: var(--space-2);
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  border: 1px solid var(--line-2);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  cursor: pointer;
}

.fav__pick input {
  margin: 0;
}

.fav__body {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-3) var(--space-4);
}

.fav__name {
  margin: 0;
  font-size: var(--text-base);
  font-weight: 600;
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: calc(1.4em * 2);
}

.fav__name a {
  color: var(--ink-0);
}

.fav__name a:hover {
  text-decoration: none;
  color: var(--signal-amber-deep);
}

.fav__spec {
  margin: 0;
  font-size: var(--text-xs);
  color: var(--ink-3);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.fav__foot {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: var(--space-2);
}

.fav__stock {
  font-size: var(--text-2xs);
  color: var(--ink-3);
  white-space: nowrap;
}

.fav__stock.is-low {
  color: var(--signal-amber-deep);
  font-weight: 600;
}

.fav__stock.is-out {
  color: var(--signal-vermilion-deep);
  font-weight: 600;
}

.fav__time {
  font-size: var(--text-2xs);
  color: var(--ink-4);
}

.fav__actions {
  display: flex;
  justify-content: space-between;
  gap: var(--space-3);
  padding: 10px var(--space-4);
  border-top: var(--hairline);
  background: var(--paper-1);
}

/* --- primitives ----------------------------------------------------------- */

.btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding-inline: 14px;
  border: 1px solid var(--line-2);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--ink-1);
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    border-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.btn:hover:not(:disabled) {
  border-color: var(--ink-3);
  background: var(--paper-1);
  text-decoration: none;
}

.btn:disabled {
  color: var(--ink-4);
  border-color: var(--line-1);
  cursor: not-allowed;
}

.btn--danger:hover:not(:disabled) {
  border-color: var(--signal-vermilion);
  color: var(--signal-vermilion-deep);
}

.link {
  padding: 0;
  border: none;
  background: transparent;
  font-size: var(--text-xs);
  color: var(--ink-2);
  cursor: pointer;
}

.link:hover {
  color: var(--ink-0);
  text-decoration: underline;
}

.link--danger:hover {
  color: var(--signal-vermilion-deep);
}

/* --- states & skeleton ---------------------------------------------------- */

.state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-12) var(--space-6);
  text-align: center;
  color: var(--ink-3);
}

.state__title {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--ink-1);
}

.state__note {
  font-size: var(--text-sm);
  max-width: 42ch;
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
  justify-content: center;
  margin-top: var(--space-6);
}

.foot-note {
  margin-top: var(--space-4);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

@media (max-width: 900px) {
  .favorites {
    padding-block: var(--space-4) var(--space-12);
  }
  .grid {
    grid-template-columns: repeat(auto-fill, minmax(168px, 1fr));
    gap: var(--space-3);
  }
}

@media (max-width: 520px) {
  .grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
  .fav__body {
    padding: var(--space-2) var(--space-3);
  }
  .fav__name {
    font-size: var(--text-sm);
  }
  .fav__actions {
    padding: 8px var(--space-3);
  }
  .pickbar {
    flex-wrap: wrap;
  }
}
</style>
