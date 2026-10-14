<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import PriceTag from '@/components/ui/PriceTag.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { AUDIT_STATUS, conditionLabel, labelOf, PRODUCT_TYPE, SHELF_STATUS } from '@/constants/domain'
import {
  createSku,
  deleteProduct,
  deleteSku,
  errorText,
  getProductImages,
  getProductList,
  getSkuList,
  isAuthError,
  PRODUCT_TYPE_CODE,
  setProductStatus,
  updateSku,
  type MerchantProduct,
  type MerchantTypeKey,
  type SkuRow,
} from '@/api/merchant/product'
import { formatDateTime, formatMoney, formatStock } from '@/utils/format'

/**
 * 商品管理。
 *
 * 列表的三处口径都在这一个文件里对齐：
 *   · 类型、上架状态、关键词 —— 后端支持，服务端筛选；
 *   · 审核状态 —— POST /merchant/product 落库后 auditStatus 才存在，而列表接口
 *     只按 is_on_shelf 过滤，所以这一项取回一屏后在客户端过滤，并把「只在最近
 *     100 条内筛选」写在界面上，不假装它是全量的；
 *   · 主图 —— 列表接口不返回图片，需按商品逐个读绑定关系，这里按页并发取一次并缓存。
 */

const route = useRoute()
const router = useRouter()

const TYPE_MODES: { key: MerchantTypeKey; label: string; note: string }[] = [
  { key: 'new', label: '全新', note: '库存制，审核通过后上架' },
  { key: 'used', label: '二手', note: '单件在售，需要成色与瑕疵说明' },
  { key: 'rental', label: '租赁', note: '按天计价，需要押金与起租天数' },
]

/** 审核状态在客户端过滤，一次取回的上限。 */
const AUDIT_WINDOW = 100
const EXPORT_LIMIT = 1000

function normalizeType(value: unknown): MerchantTypeKey {
  return value === 'used' || value === 'rental' ? value : 'new'
}

const type = ref<MerchantTypeKey>(normalizeType(route.query.type))
const shelf = ref<'' | 0 | 1>('')
const audit = ref<'' | 0 | 1 | 2>('')
const keyword = ref('')

const pageNum = ref(1)
const pageSize = ref(10)
const total = ref(0)
const fetched = ref<MerchantProduct[]>([])
const loading = ref(true)
const failed = ref(false)
const authFailed = ref(false)
const failureText = ref('')
const exporting = ref(false)
const selection = ref<MerchantProduct[]>([])

/** productId → 主图地址；null 表示这个商品确实没有图。 */
const imageMap = ref<Record<number, string | null>>({})

/** 窄屏收掉信息量最低的几列，其余交给表格自身的横向滚动。 */
const narrow = ref(false)
let mediaQuery: MediaQueryList | null = null
function syncNarrow(event?: MediaQueryListEvent) {
  narrow.value = event ? event.matches : (mediaQuery?.matches ?? false)
}

const auditMode = computed(() => audit.value !== '')
const auditFiltered = computed(() =>
  auditMode.value
    ? fetched.value.filter((item) => Number(item.auditStatus) === audit.value)
    : fetched.value,
)
const paged = computed(() =>
  auditMode.value
    ? auditFiltered.value.slice((pageNum.value - 1) * pageSize.value, pageNum.value * pageSize.value)
    : fetched.value,
)
const displayTotal = computed(() => (auditMode.value ? auditFiltered.value.length : total.value))
const hasFilter = computed(
  () => shelf.value !== '' || audit.value !== '' || keyword.value.trim() !== '',
)

const modeNote = computed(
  () => TYPE_MODES.find((item) => item.key === type.value)?.note ?? '',
)

const pendingAudit = computed(
  () => fetched.value.filter((item) => Number(item.auditStatus) === 0).length,
)

const canToggle = (row: MerchantProduct) => Number(row.auditStatus) === 1

function imageOf(productId: number) {
  return imageMap.value[productId] ?? null
}

function isSoldOut(row: MerchantProduct) {
  return Number(row.stock ?? 0) <= 0
}

function onSelectionChange(rows: MerchantProduct[]) {
  selection.value = rows
}

function priceUnit() {
  return type.value === 'rental' ? '/天' : null
}

function typeState(productType: number) {
  return labelOf(PRODUCT_TYPE, productType)
}

function auditState(code: number) {
  return labelOf(AUDIT_STATUS, code)
}

function shelfState(code: number) {
  return labelOf(SHELF_STATUS, code)
}

/** 主图按页并发取，只取一次，切页回来不再重复请求。 */
async function loadThumbs(list: MerchantProduct[]) {
  const queue = list.filter((item) => !(item.productId in imageMap.value))
  if (!queue.length) return
  const cache: Record<number, string | null> = { ...imageMap.value }
  const workers = Array.from({ length: Math.min(4, queue.length) }, async () => {
    for (let item = queue.shift(); item; item = queue.shift()) {
      try {
        const refs = await getProductImages(item.productId)
        cache[item.productId] = refs[0]?.url ?? null
      } catch {
        cache[item.productId] = null
      }
    }
  })
  await Promise.all(workers)
  imageMap.value = cache
}

async function load() {
  loading.value = true
  failed.value = false
  authFailed.value = false
  selection.value = []
  try {
    const page = await getProductList({
      type: type.value,
      status: shelf.value,
      keyword: keyword.value,
      pageNum: auditMode.value ? 1 : pageNum.value,
      pageSize: auditMode.value ? AUDIT_WINDOW : pageSize.value,
    })
    fetched.value = page.list
    total.value = page.total
    void loadThumbs(page.list)
  } catch (error) {
    fetched.value = []
    total.value = 0
    failed.value = true
    authFailed.value = isAuthError(error)
    failureText.value = errorText(error, '没能取到商品列表')
  } finally {
    loading.value = false
  }
}

function pickType(next: MerchantTypeKey) {
  if (type.value === next) return
  type.value = next
  pageNum.value = 1
  router.replace({ path: route.path, query: { ...route.query, type: next } })
  void load()
}

function applyFilter() {
  pageNum.value = 1
  void load()
}

function resetFilters() {
  shelf.value = ''
  audit.value = ''
  keyword.value = ''
  pageNum.value = 1
  void load()
}

function onPage(page: number) {
  pageNum.value = page
  if (!auditMode.value) void load()
}

function onSize(size: number) {
  pageSize.value = size
  pageNum.value = 1
  if (!auditMode.value) void load()
}

function goAdd() {
  router.push(`/merchant-dashboard/product-add?type=${type.value}`)
}

function goEdit(row: MerchantProduct) {
  router.push(`/merchant-dashboard/product-edit/${row.productId}?type=${type.value}`)
}

async function toggleShelf(row: MerchantProduct) {
  const next: 0 | 1 = Number(row.isOnShelf) === 1 ? 0 : 1
  try {
    await setProductStatus(row.productId, next)
    row.isOnShelf = next
    ElMessage.success(next === 1 ? '已上架' : '已下架')
  } catch (error) {
    ElMessage.error(errorText(error, '切换上架状态失败，请稍后重试'))
  }
}

async function remove(row: MerchantProduct) {
  try {
    await ElMessageBox.confirm(
      `删除「${row.name}」后无法恢复。有历史订单的商品不能删除，需要先下架并保留记录。`,
      '删除商品',
      { confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning' },
    )
  } catch {
    return
  }
  try {
    await deleteProduct(row.productId)
    ElMessage.success('已删除')
    const rest = fetched.value.filter((item) => item.productId !== row.productId)
    fetched.value = rest
    total.value = Math.max(0, total.value - 1)
    if (!rest.length && pageNum.value > 1) pageNum.value -= 1
    void load()
  } catch (error) {
    ElMessage.error(errorText(error, '删除失败，请稍后重试'))
  }
}

async function batchShelf(next: 0 | 1) {
  const targets = selection.value.filter((row) => canToggle(row))
  if (!targets.length) {
    ElMessage.warning('只有审核通过的商品才能上下架')
    return
  }
  try {
    await Promise.all(targets.map((row) => setProductStatus(row.productId, next)))
    ElMessage.success(`已批量${next === 1 ? '上架' : '下架'} ${targets.length} 件`)
    void load()
  } catch (error) {
    ElMessage.error(errorText(error, '批量操作失败，请稍后重试'))
  }
}

async function batchRemove() {
  if (!selection.value.length) return
  try {
    await ElMessageBox.confirm(
      `删除选中的 ${selection.value.length} 件商品？有历史订单的商品会被跳过。`,
      '批量删除',
      { confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning' },
    )
  } catch {
    return
  }
  const results = await Promise.allSettled(
    selection.value.map((row) => deleteProduct(row.productId)),
  )
  const ok = results.filter((item) => item.status === 'fulfilled').length
  const skipped = results.length - ok
  if (ok) ElMessage.success(`已删除 ${ok} 件`)
  if (skipped) ElMessage.warning(`${skipped} 件未删除：有历史订单的商品需要保留`)
  selection.value = []
  void load()
}

function csvCell(value: unknown) {
  let text = value === null || value === undefined ? '' : String(value)
  // 公式注入防护：Excel / WPS 会把以 = + - @ 开头（以及以制表符、回车开头）的
  // 单元格当公式执行，商品名里塞一个 =HYPERLINK(...) 或 =cmd|'/C calc'!A0
  // 就能在商家打开导出文件时触发。前置一个单引号即可让它当纯文本处理。
  if (/^[=+\-@\t\r]/.test(text)) {
    text = `'${text}`
  }
  return /[",\n\r]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text
}

async function exportCsv() {
  exporting.value = true
  try {
    const page = await getProductList({
      type: type.value,
      status: shelf.value,
      keyword: keyword.value,
      pageNum: 1,
      pageSize: EXPORT_LIMIT,
    })
    const rows = page.list.filter((item) => !auditMode.value || Number(item.auditStatus) === audit.value)
    const header = ['商品ID', '名称', '类型', '价格', '库存', '销量', '审核状态', '上架状态', '创建时间']
    const body = rows.map((item) => [
      item.productId,
      item.name,
      typeState(PRODUCT_TYPE_CODE[type.value]).label,
      item.price,
      item.stock,
      item.sales,
      auditState(Number(item.auditStatus)).label,
      shelfState(Number(item.isOnShelf)).label,
      formatDateTime(item.createTime),
    ])
    const csv = [header, ...body].map((line) => line.map(csvCell).join(',')).join('\r\n')
    const blob = new Blob([`\ufeff${csv}`], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `商品列表-${type.value}-${new Date().toISOString().slice(0, 10)}.csv`
    link.click()
    URL.revokeObjectURL(url)
    ElMessage.success(`已导出 ${rows.length} 条`)
  } catch (error) {
    ElMessage.error(errorText(error, '导出失败，请稍后重试'))
  } finally {
    exporting.value = false
  }
}

/* --- SKU -------------------------------------------------------------- */

const skuOpen = ref(false)
const skuTarget = ref<MerchantProduct | null>(null)
const skuRows = ref<SkuRow[]>([])
const skuLoading = ref(false)
const skuError = ref('')
const skuDialog = ref(false)
const skuEditing = ref<number | null>(null)
const skuForm = ref({ skuAttribute: '', skuValue: '', price: 0, stock: 0, minStock: 10 })
const skuSaving = ref(false)

async function openSku(row: MerchantProduct) {
  skuTarget.value = row
  skuOpen.value = true
  skuRows.value = []
  skuError.value = ''
  skuLoading.value = true
  try {
    skuRows.value = await getSkuList(row.productId)
  } catch (error) {
    skuError.value = errorText(error, '没能读取 SKU 列表')
  } finally {
    skuLoading.value = false
  }
}

function addSku() {
  skuEditing.value = null
  skuForm.value = { skuAttribute: '', skuValue: '', price: 0, stock: 0, minStock: 10 }
  skuDialog.value = true
}

function editSku(row: SkuRow) {
  skuEditing.value = row.skuId
  skuForm.value = {
    skuAttribute: row.skuAttribute,
    skuValue: row.skuValue,
    price: Number(row.price),
    stock: Number(row.stock),
    minStock: Number(row.minStock ?? 10),
  }
  skuDialog.value = true
}

async function saveSku() {
  const target = skuTarget.value
  if (!target) return
  if (!skuForm.value.skuAttribute.trim() || !skuForm.value.skuValue.trim()) {
    ElMessage.warning('属性名与属性值都要填写')
    return
  }
  if (!(skuForm.value.price > 0)) {
    ElMessage.warning('SKU 价格要大于 0')
    return
  }
  skuSaving.value = true
  try {
    if (skuEditing.value === null) {
      await createSku(target.productId, { ...skuForm.value })
    } else {
      await updateSku(target.productId, skuEditing.value, { ...skuForm.value })
    }
    skuDialog.value = false
    skuRows.value = await getSkuList(target.productId)
    ElMessage.success(skuEditing.value === null ? '已添加 SKU' : '已保存 SKU')
  } catch (error) {
    ElMessage.error(errorText(error, '保存 SKU 失败'))
  } finally {
    skuSaving.value = false
  }
}

async function removeSku(row: SkuRow) {
  const target = skuTarget.value
  if (!target) return
  try {
    await ElMessageBox.confirm(`删除属性「${row.skuAttribute}：${row.skuValue}」？`, '删除 SKU', {
      confirmButtonText: '删除',
      cancelButtonText: '取消',
      type: 'warning',
    })
  } catch {
    return
  }
  try {
    await deleteSku(target.productId, row.skuId)
    skuRows.value = skuRows.value.filter((item) => item.skuId !== row.skuId)
    ElMessage.success('已删除 SKU')
  } catch (error) {
    ElMessage.error(errorText(error, '删除 SKU 失败'))
  }
}

watch(paged, (list) => void loadThumbs(list))

watch(
  () => route.query.type,
  (value) => {
    const next = normalizeType(value)
    if (next === type.value) return
    type.value = next
    pageNum.value = 1
    void load()
  },
)

onMounted(load)

onMounted(() => {
  mediaQuery = window.matchMedia('(max-width: 900px)')
  syncNarrow()
  mediaQuery.addEventListener('change', syncNarrow)
})

onBeforeUnmount(() => mediaQuery?.removeEventListener('change', syncNarrow))
</script>

<template>
  <div class="stack">
    <header class="page-head">
      <div>
        <h1 class="page-head__title">商品管理</h1>
        <p class="page-head__note">
          {{ modeNote }}
          <template v-if="!loading && !failed">· 共 {{ displayTotal }} 件</template>
        </p>
      </div>
      <el-button type="primary" @click="goAdd">
        <AppIcon name="plus" size="14" />
        发布商品
      </el-button>
    </header>

    <div class="modes" role="tablist" aria-label="商品类型">
      <button
        v-for="mode in TYPE_MODES"
        :key="mode.key"
        class="modes__item"
        :class="{ 'is-active': type === mode.key }"
        type="button"
        role="tab"
        :aria-selected="type === mode.key"
        @click="pickType(mode.key)"
      >
        {{ mode.label }}
      </button>
    </div>

    <div class="plate filters">
          <label class="field">
        <span class="field__label">上架状态</span>
            <el-select
              v-model="shelf"
              size="small"
              class="field__control"
              placeholder="全部"
              @change="applyFilter"
            >
          <el-option label="全部" value="" />
          <el-option label="已上架" :value="1" />
          <el-option label="未上架" :value="0" />
        </el-select>
      </label>

          <label class="field">
        <span class="field__label">审核状态</span>
            <el-select
              v-model="audit"
              size="small"
              class="field__control"
              placeholder="全部"
              @change="applyFilter"
            >
          <el-option label="全部" value="" />
          <el-option label="待审核" :value="0" />
          <el-option label="已通过" :value="1" />
          <el-option label="已驳回" :value="2" />
        </el-select>
      </label>

      <form class="search" role="search" @submit.prevent="applyFilter">
        <AppIcon name="search" size="15" />
        <input
          v-model="keyword"
          class="search__input"
          type="search"
          placeholder="搜索型号，例如 Z8、EOS R5"
          aria-label="搜索商品型号"
        />
        <button class="search__go" type="submit">搜索</button>
      </form>

      <button v-if="hasFilter" class="reset" type="button" @click="resetFilters">
        <AppIcon name="refresh" size="14" />
        清除筛选
      </button>

      <span class="spacer" />

      <el-button size="small" :loading="exporting" @click="exportCsv">
        <AppIcon name="download" size="14" />
        导出
      </el-button>
    </div>

    <section class="plate">
      <SectionHead
        :title="`${TYPE_MODES.find((item) => item.key === type)?.label}商品`"
        :note="pendingAudit ? `当前页待审核 ${pendingAudit} 件` : ''"
      >
        <template #action>
          <span v-if="auditMode" class="muted">审核状态在客户端筛选，取最近 {{ AUDIT_WINDOW }} 条</span>
        </template>
      </SectionHead>

      <div v-if="selection.length" class="batchbar">
        <span class="batchbar__count">已选 {{ selection.length }} 件</span>
        <el-button size="small" @click="batchShelf(1)">批量上架</el-button>
        <el-button size="small" @click="batchShelf(0)">批量下架</el-button>
        <el-button size="small" type="danger" plain @click="batchRemove">批量删除</el-button>
      </div>

      <div v-if="loading" class="ghost" aria-busy="true">
        <div v-for="n in 6" :key="n" class="ghost__row skeleton" />
      </div>

      <EmptyState
        v-else-if="failed"
        :title="authFailed ? '登录状态已失效' : '没能加载商品列表'"
        :note="
          authFailed
            ? '登录信息可能已过期，重新登录后即可继续管理商品。'
            : `${failureText}。确认后端服务已启动后重试。`
        "
      >
        <el-button v-if="authFailed" type="primary" @click="router.push('/login')">去登录</el-button>
        <el-button v-else type="primary" @click="load">重试</el-button>
      </EmptyState>

      <EmptyState
        v-else-if="!paged.length"
        :title="hasFilter ? '没有符合条件的商品' : `还没有${TYPE_MODES.find((item) => item.key === type)?.label}商品`"
        :note="
          hasFilter
            ? '放宽筛选条件，或换个型号关键词再试。'
            : '发布后商品会先进入平台审核，审核通过再手动上架。'
        "
      >
        <el-button v-if="hasFilter" @click="resetFilters">清除筛选</el-button>
        <el-button v-else type="primary" @click="goAdd">发布商品</el-button>
      </EmptyState>

      <template v-else>
        <el-table
          :data="paged"
          size="small"
          row-key="productId"
          @selection-change="onSelectionChange"
        >
          <el-table-column type="selection" width="40" />

          <el-table-column label="主图" width="68">
            <template #default="{ row }">
              <div class="thumb">
                <ImageFrame :src="imageOf(row.productId)" :alt="row.name" ratio="1 / 1" fit="contain" />
              </div>
            </template>
          </el-table-column>

          <el-table-column label="商品" min-width="200">
            <template #default="{ row }">
              <div class="cell-title">{{ row.name }}</div>
              <p v-if="Number(row.auditStatus) === 2 && row.rejectReason" class="cell-note">
                驳回原因：{{ row.rejectReason }}
              </p>
              <p v-else-if="type === 'used' && row.condition" class="cell-note">
                成色 {{ conditionLabel(row.condition) }}
              </p>
            </template>
          </el-table-column>

          <el-table-column v-if="!narrow" label="类型" width="80">
            <template #default="{ row }">
              <StatePill
                :label="typeState(PRODUCT_TYPE_CODE[type]).label"
                :tone="typeState(PRODUCT_TYPE_CODE[type]).tone"
              />
            </template>
          </el-table-column>

          <el-table-column label="价格" width="130" align="right">
            <template #default="{ row }">
              <PriceTag :price="row.price" :unit="priceUnit()" size="sm" :show-original="false" />
              <p v-if="type === 'rental' && row.deposit" class="cell-note">
                押金 {{ formatMoney(row.deposit) }}
              </p>
            </template>
          </el-table-column>

          <el-table-column label="库存" width="110" align="right">
            <template #default="{ row }">
              <span>{{ formatStock(row.stock) }}</span>
              <p v-if="isSoldOut(row)" class="cell-note cell-note--alert">已售完</p>
            </template>
          </el-table-column>

          <el-table-column v-if="!narrow" label="销量" width="80" align="right">
            <template #default="{ row }">
              <span class="tnum">{{ row.sales ?? 0 }}</span>
            </template>
          </el-table-column>

          <el-table-column label="审核" width="90">
            <template #default="{ row }">
              <StatePill
                :label="auditState(Number(row.auditStatus)).label"
                :tone="auditState(Number(row.auditStatus)).tone"
              />
            </template>
          </el-table-column>

          <el-table-column label="上架" width="90">
            <template #default="{ row }">
              <StatePill
                :label="shelfState(Number(row.isOnShelf)).label"
                :tone="shelfState(Number(row.isOnShelf)).tone"
              />
            </template>
          </el-table-column>

          <el-table-column v-if="!narrow" label="创建时间" width="150">
            <template #default="{ row }">
              <span class="muted">{{ formatDateTime(row.createTime) }}</span>
            </template>
          </el-table-column>

          <el-table-column label="操作" width="176" :fixed="narrow ? false : 'right'">
            <template #default="{ row }">
              <div class="row-actions">
                <button class="icon-btn" type="button" title="编辑" aria-label="编辑商品" @click="goEdit(row)">
                  <AppIcon name="edit" size="15" />
                </button>
                <button
                  class="icon-btn"
                  type="button"
                  :title="!canToggle(row) ? '审核通过后才能上架' : Number(row.isOnShelf) === 1 ? '下架' : '上架'"
                  :aria-label="Number(row.isOnShelf) === 1 ? '下架商品' : '上架商品'"
                  :disabled="!canToggle(row)"
                  @click="toggleShelf(row)"
                >
                  <AppIcon :name="Number(row.isOnShelf) === 1 ? 'chevron-down' : 'arrow-up'" size="15" />
                </button>
                <button class="icon-btn" type="button" title="SKU 管理" aria-label="SKU 管理" @click="openSku(row)">
                  <AppIcon name="list" size="15" />
                </button>
                <button
                  class="icon-btn icon-btn--danger"
                  type="button"
                  title="删除"
                  aria-label="删除商品"
                  @click="remove(row)"
                >
                  <AppIcon name="trash" size="15" />
                </button>
              </div>
            </template>
          </el-table-column>
        </el-table>

        <div v-if="displayTotal > pageSize" class="pager">
          <el-pagination
            :current-page="pageNum"
            :page-size="pageSize"
            :page-sizes="[10, 20, 50]"
            :total="displayTotal"
            background
            layout="total, sizes, prev, pager, next"
            @current-change="onPage"
            @size-change="onSize"
          />
        </div>
      </template>
    </section>

    <!-- SKU：同一件商品的多属性库存 -->
    <el-drawer
      v-model="skuOpen"
      :size="narrow ? '100%' : '560px'"
      :title="`SKU 管理 · ${skuTarget?.name ?? ''}`"
    >
      <div class="sku">
        <p class="sku__note">
          商品上架后由买家选择的属性组合，价格与库存以 SKU 为准。新建商品会自动带一条「默认」SKU。
        </p>
        <el-button size="small" type="primary" @click="addSku">
          <AppIcon name="plus" size="13" />
          添加 SKU
        </el-button>

        <div v-if="skuLoading" class="ghost" aria-busy="true">
          <div v-for="n in 3" :key="n" class="ghost__row skeleton" />
        </div>

        <EmptyState v-else-if="skuError" title="没能读取 SKU" :note="skuError">
          <el-button @click="skuTarget && openSku(skuTarget)">重试</el-button>
        </EmptyState>

        <EmptyState v-else-if="!skuRows.length" title="还没有 SKU" note="点上面的按钮添加第一条属性。" />

        <el-table v-else :data="skuRows" size="small" row-key="skuId">
          <el-table-column prop="skuAttribute" label="属性" min-width="90" />
          <el-table-column prop="skuValue" label="属性值" min-width="90" />
          <el-table-column label="价格" width="100" align="right">
            <template #default="{ row }">
              <PriceTag :price="row.price" size="sm" :show-original="false" />
            </template>
          </el-table-column>
          <el-table-column label="库存" width="80" align="right">
            <template #default="{ row }">
              <span class="tnum">{{ row.stock }}</span>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="96" fixed="right">
            <template #default="{ row }">
              <div class="row-actions">
                <button class="icon-btn" type="button" title="编辑" aria-label="编辑 SKU" @click="editSku(row)">
                  <AppIcon name="edit" size="14" />
                </button>
                <button
                  class="icon-btn icon-btn--danger"
                  type="button"
                  title="删除"
                  aria-label="删除 SKU"
                  @click="removeSku(row)"
                >
                  <AppIcon name="trash" size="14" />
                </button>
              </div>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </el-drawer>

    <el-dialog v-model="skuDialog" :title="skuEditing === null ? '添加 SKU' : '编辑 SKU'" width="420px">
      <div class="form">
        <label class="form__row">
          <span class="form__label">属性名</span>
          <el-input v-model="skuForm.skuAttribute" placeholder="如 颜色、套装、成色" />
        </label>
        <label class="form__row">
          <span class="form__label">属性值</span>
          <el-input v-model="skuForm.skuValue" placeholder="如 黑色、单机、95新" />
        </label>
        <label class="form__row">
          <span class="form__label">价格</span>
          <el-input-number v-model="skuForm.price" :min="0.01" :step="0.01" :precision="2" />
        </label>
        <label class="form__row">
          <span class="form__label">库存</span>
          <el-input-number v-model="skuForm.stock" :min="0" step="1" />
        </label>
        <label class="form__row">
          <span class="form__label">安全库存</span>
          <el-input-number v-model="skuForm.minStock" :min="0" step="1" />
        </label>
      </div>
      <template #footer>
        <el-button @click="skuDialog = false">取消</el-button>
        <el-button type="primary" :loading="skuSaving" @click="saveSku">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.modes {
  display: inline-flex;
  gap: 2px;
  padding: 2px;
  background: var(--paper-2);
  border-radius: var(--radius-sm);
  align-self: flex-start;
}

.modes__item {
  padding: 6px 16px;
  border: none;
  border-radius: var(--radius-xs);
  background: transparent;
  color: var(--ink-2);
  font-size: var(--text-sm);
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.modes__item:hover {
  color: var(--ink-0);
}

.modes__item.is-active {
  background: var(--paper-0);
  color: var(--ink-0);
  font-weight: 600;
}

/* --- filters ------------------------------------------------------------- */

.filters {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--pad-surface);
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
  width: 116px;
}

.search {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex: 0 1 280px;
  height: var(--control-h);
  padding-left: var(--space-3);
  background: var(--paper-1);
  border: 1px solid var(--line-2);
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
  color: var(--ink-3);
  font-size: var(--text-sm);
  cursor: pointer;
}

.reset:hover {
  background: var(--paper-2);
  color: var(--ink-0);
}

/* --- table --------------------------------------------------------------- */

.plate :deep(.section-head) {
  margin: 0;
  padding: var(--space-3) var(--pad-surface);
  border-bottom: var(--hairline);
}

.batchbar {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--pad-surface);
  background: var(--signal-amber-wash);
  border-bottom: var(--hairline);
}

.batchbar__count {
  margin-right: var(--space-2);
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--signal-amber-deep);
}

.thumb {
  width: 44px;
  border: var(--hairline);
  border-radius: var(--radius-xs);
  overflow: hidden;
}

.thumb :deep(.frame__img--contain) {
  padding: 3px;
}

.cell-title {
  color: var(--ink-0);
  font-weight: 500;
}

.cell-note {
  margin-top: 2px;
  font-size: var(--text-2xs);
  color: var(--ink-3);
}

.cell-note--alert {
  color: var(--signal-vermilion-deep);
  font-weight: 600;
}

.row-actions {
  display: inline-flex;
  align-items: center;
  gap: 2px;
}

.icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--ink-2);
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.icon-btn:hover:not(:disabled) {
  background: var(--paper-2);
  color: var(--ink-0);
}

.icon-btn:disabled {
  color: var(--ink-4);
  cursor: not-allowed;
}

.icon-btn--danger:hover:not(:disabled) {
  background: var(--signal-vermilion-wash);
  color: var(--signal-vermilion-deep);
}

.pager {
  display: flex;
  justify-content: flex-end;
  padding: var(--space-3) var(--pad-surface);
  border-top: var(--hairline);
}

.ghost {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-4) var(--pad-surface);
}

.ghost__row {
  height: 22px;
  border-radius: var(--radius-xs);
}

/* --- sku drawer ---------------------------------------------------------- */

.sku {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  align-items: flex-start;
}

.sku__note {
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.form {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.form__row {
  display: grid;
  grid-template-columns: 84px minmax(0, 1fr);
  align-items: center;
  gap: var(--space-3);
}

.form__label {
  font-size: var(--text-sm);
  color: var(--ink-2);
}

@media (max-width: 900px) {
  .filters {
    align-items: stretch;
  }

  .search {
    flex-basis: 100%;
  }

  .spacer {
    display: none;
  }
}
</style>
