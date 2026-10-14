<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import PriceTag from '@/components/ui/PriceTag.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import SpecList, { type SpecEntry } from '@/components/ui/SpecList.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { getCategoryTree, type CategoryNode } from '@/api/admin/category'
import { getMerchantDetail } from '@/api/admin/merchant'
import {
  auditProduct,
  getProductAuditList,
  getProductDetail,
  getProductEvidence,
  setProductShelf,
  type AdminProduct,
  type AuditProductRow,
  type ProductEvidence,
} from '@/api/admin/product'
import { AUDIT_STATUS, PRODUCT_TYPE, SHELF_STATUS, conditionLabel, labelOf } from '@/constants/domain'
import { formatDateTime, formatRelative, formatStock } from '@/utils/format'

/**
 * 商品审核。
 *
 * 一个商品能不能上架，取决于审核员在抽屉里能不能看全：主图、品牌型号、分类、
 * 类型（全新/二手/租赁）、价格、库存、卖家，以及二手商品的成色与瑕疵说明。
 * 因此抽屉会同时取三份数据：
 *   · /admin/products/{id}   —— 商品本体与图片
 *   · /shop/products/{id}    —— 公开详情（成色描述、瑕疵、参数表、卖家名称）
 *   · /admin/categories/tree —— 分类名（商品只存 categoryId）
 *
 * 原来这一页有一堆硬伤：
 *   1. 批量操作调用了 ElMessageBox，但整个文件没有 import 它 —— 一点就 ReferenceError；
 *   2. "强制下架""撤销"打到 /admin/products/{id}/force-offline 与 /cancel-offline，
 *      后端根本没有这两个映射，按钮是假的；真正的接口是 /shelf（请求体 isOnShelf）
 *      与 /audit（把 audit_status 打回 0 重新送审）；
 *   3. 成色按 1/2/3/4 显示（99新/95新/9新/8新），而库里存的是成色百分比（85/90/95），
 *      于是"90"会显示成"未知"；
 *   4. 分页、状态文案、商品类型文案各写一份 switch，和共享字典并存；
 *   5. 图片直接用 el-image 吃 storagePath，商品图是新旧两套路径混着来的。
 */

const route = useRoute()

const STATUS_TABS = [
  { value: 0, label: '待审核' },
  { value: 1, label: '已通过' },
  { value: 2, label: '已驳回' },
] as const

const activeStatus = ref<number>(0)
const loading = ref(true)
const failed = ref(false)
const rows = ref<AuditProductRow[]>([])
const total = ref(0)
const page = ref(1)
const size = ref(10)
const selected = ref<AuditProductRow[]>([])
const bulkBusy = ref(false)

const filters = reactive({
  productName: '',
  brand: '',
  productType: '' as number | '',
})

const drawer = ref(false)
const product = ref<AdminProduct | null>(null)
const evidence = ref<ProductEvidence | null>(null)
const sellerShop = ref<string>('')
const drawerLoading = ref(false)
const drawerError = ref('')
const activeImage = ref<string | null>(null)
const submitting = ref(false)
const submitError = ref('')
const rejectReason = ref('')
const decision = ref<'approve' | 'reject'>('approve')

const categoryNames = ref<Record<number, string>>({})
const MAX_REASON = 200

function flattenCategories(nodes: CategoryNode[], map: Record<number, string> = {}) {
  for (const node of nodes) {
    map[node.categoryId] = node.categoryName
    if (node.children?.length) flattenCategories(node.children, map)
  }
  return map
}

const drawerTitle = computed(() =>
  product.value ? `${product.value.model}` : '商品审核',
)

const statusLabel = computed(() => labelOf(AUDIT_STATUS, product.value?.auditStatus))

const images = computed(() => (product.value?.images ?? []).filter(Boolean))

const defectImages = computed(() => (evidence.value?.defectImg ?? []).filter(Boolean))

const specEntries = computed<SpecEntry[]>(() => {
  const parameters = evidence.value?.parameters ?? evidence.value?.specifications ?? null
  if (!parameters) return []
  return Object.entries(parameters).map(([key, value]) => ({
    key,
    value: String(value),
  }))
})

const condition = computed(() => conditionLabel(product.value?.condition ?? evidence.value?.condition))

/** 表格里要按类型加计价单位：租赁是元/天。 */
function priceUnit(type: number) {
  return type === 3 ? '/天' : null
}

async function load() {
  loading.value = true
  failed.value = false
  try {
    const pageData = await getProductAuditList({
      pageNum: page.value,
      pageSize: size.value,
      auditStatus: activeStatus.value,
      productName: filters.productName.trim() || undefined,
      brand: filters.brand.trim() || undefined,
      productType: filters.productType === '' ? undefined : Number(filters.productType),
    })
    rows.value = pageData.records ?? []
    total.value = pageData.total ?? 0
    selected.value = []
  } catch {
    failed.value = true
    rows.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

function switchStatus(value: number) {
  if (activeStatus.value === value) return
  activeStatus.value = value
  page.value = 1
  void load()
}

function search() {
  page.value = 1
  void load()
}

function resetFilters() {
  filters.productName = ''
  filters.brand = ''
  filters.productType = ''
  search()
}

function changeSize() {
  page.value = 1
  void load()
}

async function openProduct(productId: number) {
  drawer.value = true
  drawerLoading.value = true
  drawerError.value = ''
  product.value = null
  evidence.value = null
  sellerShop.value = ''
  activeImage.value = null
  rejectReason.value = ''
  submitError.value = ''
  decision.value = 'approve'

  try {
    const detail = await getProductDetail(productId)
    product.value = detail
    activeImage.value = detail.images?.[0] ?? null

    // 证据补充：失败不影响主档展示，只是这一块留空。
    const [ev, seller] = await Promise.allSettled([
      getProductEvidence(productId),
      detail.sellerId ? getMerchantDetail(detail.sellerId) : Promise.reject(new Error('no seller')),
    ])
    if (ev.status === 'fulfilled') evidence.value = ev.value
    if (seller.status === 'fulfilled') {
      sellerShop.value = seller.value.shopName || seller.value.nickname || `商家 #${detail.sellerId}`
    }
  } catch (error) {
    drawerError.value = error instanceof Error ? error.message : '商品详情没能取回来'
  } finally {
    drawerLoading.value = false
  }
}

async function submitDecision() {
  const target = product.value
  if (!target || submitting.value) return

  if (decision.value === 'reject') {
    const reason = rejectReason.value.trim()
    if (reason.length < 4) {
      submitError.value = '驳回理由至少 4 个字：商家要靠它知道哪一项不合格。'
      return
    }
    submitError.value = ''
    submitting.value = true
    try {
      await auditProduct(target.productId, { auditStatus: 2, rejectReason: reason })
      ElMessage.success('已驳回，商品不会出现在商城里')
      drawer.value = false
      await load()
    } catch (error) {
      submitError.value = error instanceof Error ? error.message : '驳回失败，请重试'
    } finally {
      submitting.value = false
    }
    return
  }

  submitting.value = true
  submitError.value = ''
  try {
    await auditProduct(target.productId, { auditStatus: 1 })
    ElMessage.success('已通过，商品同时上架')
    drawer.value = false
    await load()
  } catch (error) {
    submitError.value = error instanceof Error ? error.message : '审核失败，请重试'
  } finally {
    submitting.value = false
  }
}

async function resubmit(productId: number) {
  try {
    await auditProduct(productId, { auditStatus: 0 })
    ElMessage.success('已退回待审核队列')
    drawer.value = false
    await load()
  } catch (error) {
    submitError.value = error instanceof Error ? error.message : '操作失败，请重试'
  }
}

async function takeOffShelf(productId: number, model: string) {
  try {
    await ElMessageBox.confirm(
      `下架后「${model}」立刻从商城消失，已下单的订单不受影响。确认下架？`,
      '强制下架',
      { confirmButtonText: '下架', cancelButtonText: '取消' },
    )
  } catch {
    return
  }
  try {
    await setProductShelf(productId, 0)
    ElMessage.success('已下架')
    drawer.value = false
    await load()
  } catch (error) {
    submitError.value = error instanceof Error ? error.message : '下架失败，请重试'
  }
}

function canBatchApprove() {
  return selected.value.length > 0 && selected.value.every((row) => row.auditStatus === 0)
}

function canBatchOffShelf() {
  return selected.value.length > 0 && selected.value.every((row) => row.auditStatus === 1)
}

/** 批量动作逐条收集失败原因，能成功的照样处理，不再"整体成功/整体失败"。 */
async function runBatch(
  action: (row: AuditProductRow) => Promise<unknown>,
  doneText: string,
) {
  if (selected.value.length === 0 || bulkBusy.value) return
  bulkBusy.value = true
  const failures: string[] = []
  for (const row of selected.value) {
    try {
      await action(row)
    } catch (error) {
      failures.push(`${row.model}：${error instanceof Error ? error.message : '失败'}`)
    }
  }
  bulkBusy.value = false
  if (failures.length === 0) {
    ElMessage.success(`${doneText}（${selected.value.length} 件）`)
  } else {
    ElMessage.warning(`${doneText}完成 ${selected.value.length - failures.length} 件，${failures.length} 件失败`)
  }
  await load()
}

async function batchApprove() {
  if (!canBatchApprove()) {
    ElMessage.warning('只有待审核的商品可以批量通过')
    return
  }
  try {
    await ElMessageBox.confirm(
      `将通过 ${selected.value.length} 件商品，通过后它们会同时上架。`,
      '批量通过',
      { confirmButtonText: '全部通过', cancelButtonText: '取消' },
    )
  } catch {
    return
  }
  await runBatch((row) => auditProduct(row.productId, { auditStatus: 1 }), '批量通过')
}

async function batchReject() {
  if (!canBatchApprove()) {
    ElMessage.warning('只有待审核的商品可以批量驳回')
    return
  }
  let reason = ''
  try {
    const result = await ElMessageBox.prompt(
      '这条理由会作为同一批商品的驳回原因，请写清楚共性问题。',
      '批量驳回',
      {
        confirmButtonText: '全部驳回',
        cancelButtonText: '取消',
        inputType: 'textarea',
        inputPlaceholder: '例如：主图为网图，未提供实拍图',
        inputValidator: (value) => (value && value.trim().length >= 4 ? true : '至少写 4 个字'),
      },
    )
    reason = String(result.value).trim()
  } catch {
    return
  }
  await runBatch((row) => auditProduct(row.productId, { auditStatus: 2, rejectReason: reason }), '批量驳回')
}

async function batchOffShelf() {
  if (!canBatchOffShelf()) {
    ElMessage.warning('只有已通过的商品可以批量下架')
    return
  }
  try {
    await ElMessageBox.confirm(
      `将下架 ${selected.value.length} 件商品，它们会立刻从商城消失。`,
      '批量下架',
      { confirmButtonText: '全部下架', cancelButtonText: '取消' },
    )
  } catch {
    return
  }
  await runBatch((row) => setProductShelf(row.productId, 0), '批量下架')
}

function exportCsv() {
  const header = ['商品ID', '型号', '品牌', '类型', '价格', '库存', '审核状态', '提交时间']
  const body = rows.value.map((row) => [
    row.productId,
    row.model,
    row.brandName || row.brand,
    labelOf(PRODUCT_TYPE, row.productType).label,
    row.price ?? '',
    row.stock ?? '',
    labelOf(AUDIT_STATUS, row.auditStatus).label,
    formatDateTime(row.createTime),
  ])
  const csv = [header, ...body].map((row) => row.map(csvCell).join(',')).join('\n')
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  link.href = URL.createObjectURL(blob)
  link.download = `商品审核_${STATUS_TABS[activeStatus.value]?.label ?? ''}_${new Date().toISOString().slice(0, 10)}.csv`
  link.click()
  URL.revokeObjectURL(link.href)
}

function csvCell(value: string | number | null | undefined) {
  const text = value === null || value === undefined ? '' : String(value)
  return /[",\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text
}

onMounted(async () => {
  const statusParam = Number(route.query.status)
  if (Number.isFinite(statusParam) && [0, 1, 2].includes(statusParam)) {
    activeStatus.value = statusParam
  }
  try {
    categoryNames.value = flattenCategories(await getCategoryTree())
  } catch {
    categoryNames.value = {}
  }
  await load()
  const focus = Number(route.query.product)
  if (Number.isFinite(focus) && focus > 0) void openProduct(focus)
})
</script>

<template>
  <div class="audit" data-density="admin">
    <SectionHead
      title="商品审核"
      note="通过即上架。驳回必须写理由，理由会随站内通知发给商家。"
      size="lg"
    >
      <template #action>
        <button class="link-action" type="button" :disabled="loading" @click="load">
          <AppIcon name="refresh" size="14" />
          刷新
        </button>
      </template>
    </SectionHead>

    <div class="toolbar">
      <div class="segmented" role="tablist" aria-label="审核状态">
        <button
          v-for="tab in STATUS_TABS"
          :key="tab.value"
          class="segmented__item"
          :class="{ 'is-on': activeStatus === tab.value }"
          type="button"
          role="tab"
          :aria-selected="activeStatus === tab.value"
          @click="switchStatus(tab.value)"
        >
          {{ tab.label }}
        </button>
      </div>

      <el-input
        v-model="filters.productName"
        class="toolbar__input"
        placeholder="型号 / 名称"
        clearable
        @keyup.enter="search"
      />
      <el-input
        v-model="filters.brand"
        class="toolbar__input"
        placeholder="品牌"
        clearable
        @keyup.enter="search"
      />
      <el-select v-model="filters.productType" class="toolbar__select" placeholder="商品类型" clearable>
        <el-option label="全新" :value="1" />
        <el-option label="二手" :value="2" />
        <el-option label="租赁" :value="3" />
      </el-select>
      <el-button @click="search">查询</el-button>
      <el-button @click="resetFilters">重置</el-button>
      <el-button :disabled="rows.length === 0" @click="exportCsv">
        <AppIcon name="download" size="14" />
        导出当前页
      </el-button>
    </div>

    <div v-if="selected.length > 0" class="bulk">
      <span class="bulk__count">已选 {{ selected.length }} 件</span>
      <el-button v-if="activeStatus === 0" type="primary" size="small" :disabled="!canBatchApprove() || bulkBusy" @click="batchApprove">
        批量通过
      </el-button>
      <el-button v-if="activeStatus === 0" size="small" :disabled="!canBatchApprove() || bulkBusy" @click="batchReject">
        批量驳回
      </el-button>
      <el-button v-if="activeStatus === 1" size="small" :disabled="!canBatchOffShelf() || bulkBusy" @click="batchOffShelf">
        批量下架
      </el-button>
    </div>

    <p v-if="failed" class="band band--error">
      <AppIcon name="warning" size="15" />
      <span>审核队列没能加载。请确认后端服务在运行，然后重试。</span>
      <button class="band__action" type="button" @click="load">重试</button>
    </p>

    <section class="plate">
      <div v-if="loading" class="loading-list">
        <span v-for="n in 5" :key="n" class="skeleton loading-list__row" />
      </div>

      <EmptyState
        v-else-if="rows.length === 0"
        :title="`没有${STATUS_TABS.find((t) => t.value === activeStatus)?.label}的商品`"
        note="切换上方的状态页签，或调整筛选条件。"
      />

      <div v-else class="table-scroll">
        <el-table
          :data="rows"
          size="small"
          style="width: 100%"
          @selection-change="(val: AuditProductRow[]) => (selected = val)"
        >
          <el-table-column type="selection" width="42" />
          <el-table-column label="商品" min-width="240">
            <template #default="{ row }">
              <button class="cell-link" type="button" @click="openProduct(row.productId)">
                {{ row.brandName || row.brand }} {{ row.model }}
              </button>
              <span class="cell-sub">#{{ row.productId }}</span>
            </template>
          </el-table-column>
          <el-table-column label="类型" width="90">
            <template #default="{ row }">
              <StatePill
                :label="labelOf(PRODUCT_TYPE, row.productType).label"
                :tone="labelOf(PRODUCT_TYPE, row.productType).tone"
              />
            </template>
          </el-table-column>
          <el-table-column label="价格" min-width="130">
            <template #default="{ row }">
              <PriceTag :price="row.price" size="sm" :unit="priceUnit(row.productType)" :show-original="false" />
            </template>
          </el-table-column>
          <el-table-column label="库存" width="90">
            <template #default="{ row }">
              <span :class="{ 'is-warn': (row.stock ?? 0) <= 0 }">{{ formatStock(row.stock) }}</span>
            </template>
          </el-table-column>
          <el-table-column label="状态" width="100">
            <template #default="{ row }">
              <StatePill
                :label="labelOf(AUDIT_STATUS, row.auditStatus).label"
                :tone="labelOf(AUDIT_STATUS, row.auditStatus).tone"
              />
            </template>
          </el-table-column>
          <el-table-column label="提交时间" min-width="160">
            <template #default="{ row }">
              <span>{{ formatDateTime(row.createTime) }}</span>
              <span class="cell-sub">{{ formatRelative(row.createTime) }}</span>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="150" fixed="right">
            <template #default="{ row }">
              <el-button size="small" @click="openProduct(row.productId)">
                {{ row.auditStatus === 0 ? '审核' : '查看' }}
              </el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </section>

    <div v-if="!loading && rows.length > 0" class="pager">
      <el-pagination
        v-model:current-page="page"
        v-model:page-size="size"
        :page-sizes="[10, 20, 50]"
        layout="total, sizes, prev, pager, next"
        :total="total"
        @size-change="changeSize"
        @current-change="load"
      />
    </div>

    <!-- 审核抽屉 -->
    <el-drawer v-model="drawer" :title="drawerTitle" size="720px" direction="rtl">
      <div v-if="drawerLoading" class="drawer-state">
        <span class="skeleton drawer-state__block" />
        <span class="skeleton drawer-state__block" />
      </div>

      <div v-else-if="drawerError" class="band band--error">
        <AppIcon name="warning" size="15" />
        <span>{{ drawerError }}</span>
      </div>

      <div v-else-if="product" class="drawer-body">
        <div class="gallery">
          <a
            v-if="activeImage"
            class="gallery__main"
            :href="activeImage"
            target="_blank"
            rel="noopener"
            title="在新窗口查看原图"
          >
            <ImageFrame :src="activeImage" :alt="product.model" ratio="4 / 3" fit="contain" eager />
          </a>
          <p v-else class="gallery__empty">这件商品没有上传图片。没有实拍图的商品不应通过审核。</p>

          <div v-if="images.length > 1" class="gallery__strip">
            <button
              v-for="url in images"
              :key="url"
              class="gallery__thumb"
              :class="{ 'is-on': url === activeImage }"
              type="button"
              @click="activeImage = url"
            >
              <ImageFrame :src="url" :alt="product.model" ratio="4 / 3" fit="contain" />
            </button>
          </div>
        </div>

        <div class="facts">
          <div class="facts__pills">
            <StatePill :label="statusLabel.label" :tone="statusLabel.tone" />
            <StatePill
              :label="labelOf(PRODUCT_TYPE, product.productType).label"
              :tone="labelOf(PRODUCT_TYPE, product.productType).tone"
            />
            <StatePill
              :label="labelOf(SHELF_STATUS, product.isOnShelf).label"
              :tone="labelOf(SHELF_STATUS, product.isOnShelf).tone"
            />
          </div>

          <PriceTag :price="product.price" :original-price="product.originalPrice" :unit="priceUnit(product.productType)" size="lg" />

          <SpecList
            :entries="[
              { key: '商品ID', value: `#${product.productId}`, mono: true },
              { key: '品牌 / 型号', value: `${evidence?.brandName ?? ''} ${product.model}` },
              { key: '分类', value: categoryNames[product.categoryId ?? -1] ?? `分类 #${product.categoryId}` },
              { key: '成色', value: condition },
              { key: '库存', value: formatStock(product.stock) },
              { key: '安全库存', value: product.minStock !== null ? `${product.minStock} 件` : null },
              { key: '起租天数', value: product.minRentalDays ? `${product.minRentalDays} 天` : null },
              { key: '押金', value: evidence?.deposit ? `¥${evidence.deposit}` : null },
              { key: '颜色', value: product.color },
              { key: '卖家', value: sellerShop || (product.sellerId ? `商家 #${product.sellerId}` : null) },
              { key: '提交时间', value: formatDateTime(product.createTime) },
            ]"
          />
        </div>

        <section v-if="product.rejectReason" class="evidence">
          <h3 class="evidence__title">上一次的驳回原因</h3>
          <p class="evidence__reject">{{ product.rejectReason }}</p>
        </section>

        <section v-if="evidence?.defectDesc" class="evidence">
          <h3 class="evidence__title">二手瑕疵说明</h3>
          <p class="evidence__text">{{ evidence.defectDesc }}</p>
          <div v-if="defectImages.length" class="evidence__imgs">
            <a
              v-for="url in defectImages"
              :key="url"
              class="evidence__img"
              :href="url"
              target="_blank"
              rel="noopener"
            >
              <ImageFrame :src="url" alt="瑕疵图" ratio="1 / 1" fit="cover" />
            </a>
          </div>
        </section>

        <section v-if="specEntries.length" class="evidence">
          <h3 class="evidence__title">规格参数</h3>
          <SpecList :entries="specEntries" :columns="2" />
        </section>

        <section v-if="evidence?.description || evidence?.secondHandDescription" class="evidence">
          <h3 class="evidence__title">商品描述</h3>
          <p class="evidence__text">{{ evidence?.secondHandDescription || evidence?.description }}</p>
        </section>
      </div>

      <template #footer>
        <div v-if="product" class="decision">
          <template v-if="product.auditStatus === 0">
            <div class="decision__modes">
              <label class="decision__mode" :class="{ 'is-on': decision === 'approve' }">
                <input v-model="decision" type="radio" value="approve" />
                通过并上架
              </label>
              <label class="decision__mode" :class="{ 'is-on': decision === 'reject' }">
                <input v-model="decision" type="radio" value="reject" />
                驳回
              </label>
            </div>
            <el-input
              v-if="decision === 'reject'"
              v-model="rejectReason"
              type="textarea"
              :rows="3"
              :maxlength="MAX_REASON"
              show-word-limit
              placeholder="写清楚缺什么、哪一项不合规，商家按这句话改"
            />
          </template>

          <p v-if="submitError" class="decision__error">
            <AppIcon name="warning" size="14" />
            <span>{{ submitError }}</span>
          </p>

          <div class="decision__actions">
            <el-button @click="drawer = false">关闭</el-button>
            <el-button
              v-if="product.auditStatus === 0"
              type="primary"
              :loading="submitting"
              @click="submitDecision"
            >
              {{ decision === 'reject' ? '确认驳回' : '确认通过' }}
            </el-button>
            <el-button
              v-else-if="product.auditStatus === 1"
              :loading="submitting"
              @click="takeOffShelf(product.productId, product.model)"
            >
              强制下架
            </el-button>
            <el-button v-else type="primary" @click="resubmit(product.productId)">重新送审</el-button>
          </div>
        </div>
      </template>
    </el-drawer>
  </div>
</template>

<style scoped>
.audit {
  display: flex;
  flex-direction: column;
  gap: var(--gap-surface);
}

.link-action {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 0;
  border: none;
  background: none;
  color: var(--ink-2);
  font-size: var(--text-sm);
  font-weight: 500;
  cursor: pointer;
}

.link-action:hover {
  color: var(--ink-0);
  text-decoration: underline;
}

.link-action:disabled {
  color: var(--ink-4);
  cursor: default;
  text-decoration: none;
}

.toolbar {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.toolbar__input {
  max-width: 180px;
}

.toolbar__select {
  width: 140px;
}

.segmented {
  display: inline-flex;
  border: var(--edge);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.segmented__item {
  padding: 0 14px;
  height: calc(30px * var(--dense));
  border: none;
  border-right: var(--hairline);
  background: var(--paper-0);
  color: var(--ink-2);
  font-size: var(--text-sm);
  cursor: pointer;
}

.segmented__item:last-child {
  border-right: none;
}

.segmented__item.is-on {
  background: var(--ink-0);
  color: var(--on-ink);
  font-weight: 600;
}

.bulk {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--space-4);
  background: var(--paper-2);
  border: var(--edge);
  border-radius: var(--radius-md);
}

.bulk__count {
  font-size: var(--text-sm);
  color: var(--ink-2);
  margin-right: var(--space-2);
}

.band {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-3) var(--space-4);
  border: var(--edge);
  border-radius: var(--radius-md);
  font-size: var(--text-sm);
}

.band--error {
  background: var(--signal-vermilion-wash);
  border-color: var(--signal-vermilion);
  color: var(--signal-vermilion-deep);
}

.band__action {
  margin-left: auto;
  padding: 2px 10px;
  border: 1px solid currentColor;
  border-radius: var(--radius-sm);
  background: transparent;
  color: inherit;
  font-size: var(--text-xs);
  cursor: pointer;
}

.loading-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-4);
}

.loading-list__row {
  height: calc(40px * var(--dense));
}

.table-scroll {
  width: 100%;
  overflow-x: auto;
}

.cell-link {
  padding: 0;
  border: none;
  background: none;
  color: var(--ink-0);
  font-weight: 600;
  font-size: var(--text-sm);
  cursor: pointer;
  text-align: left;
}

.cell-link:hover {
  text-decoration: underline;
}

.cell-sub {
  display: block;
  color: var(--ink-3);
  font-size: var(--text-xs);
}

.is-warn {
  color: var(--signal-vermilion-deep);
}

.pager {
  display: flex;
  justify-content: flex-end;
}

/* --- 抽屉 ---------------------------------------------------------------- */

.drawer-body {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}

.drawer-state {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.drawer-state__block {
  height: calc(180px * var(--dense));
}

.gallery__main {
  display: block;
  border: var(--edge);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.gallery__empty {
  padding: var(--space-8) var(--space-4);
  border: 1px dashed var(--line-2);
  border-radius: var(--radius-sm);
  color: var(--ink-3);
  font-size: var(--text-sm);
  text-align: center;
}

.gallery__strip {
  display: flex;
  gap: var(--space-2);
  margin-top: var(--space-2);
  overflow-x: auto;
  padding-bottom: 2px;
}

.gallery__thumb {
  width: calc(72px * var(--dense) + 16px);
  flex-shrink: 0;
  padding: 0;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  cursor: pointer;
  overflow: hidden;
}

.gallery__thumb.is-on {
  border-color: var(--ink-0);
}

.facts {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.facts__pills {
  display: flex;
  gap: var(--space-1);
  flex-wrap: wrap;
}

.evidence__title {
  margin-bottom: var(--space-2);
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-0);
}

.evidence__text {
  font-size: var(--text-sm);
  color: var(--ink-2);
  white-space: pre-wrap;
  max-width: 68ch;
}

.evidence__reject {
  padding: var(--space-2) var(--space-3);
  background: var(--signal-vermilion-wash);
  border-radius: var(--radius-sm);
  color: var(--signal-vermilion-deep);
  font-size: var(--text-sm);
}

.evidence__imgs {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(96px, 1fr));
  gap: var(--space-2);
  margin-top: var(--space-2);
}

.evidence__img {
  display: block;
  border: var(--edge);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

/* --- 决定区 --------------------------------------------------------------- */

.decision {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  text-align: left;
}

.decision__modes {
  display: flex;
  gap: var(--space-2);
}

.decision__mode {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  padding: 6px 12px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  font-size: var(--text-sm);
  color: var(--ink-2);
  cursor: pointer;
}

.decision__mode.is-on {
  background: var(--paper-2);
  border-color: var(--ink-0);
  color: var(--ink-0);
  font-weight: 600;
}

.decision__error {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  color: var(--signal-vermilion-deep);
  font-size: var(--text-xs);
}

.decision__actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}

@media (max-width: 767px) {
  .toolbar__input,
  .toolbar__select {
    max-width: 100%;
    width: 100%;
  }
}
</style>
