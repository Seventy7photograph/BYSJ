<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import SpecList from '@/components/ui/SpecList.vue'
import {
  auditMerchant,
  getMerchantAuditList,
  getMerchantDetail,
  shopStateOf,
} from '@/api/admin/merchant'
import type { AdminUser } from '@/api/admin/http'
import { formatDateTime, formatRelative, maskPhone, resolveImageUrl } from '@/utils/format'

/**
 * 商家认证审核 —— 这个后台最重要的一页。
 *
 * 审核是一次"看证据、下决定"的动作，所以列表只负责排队，证据和决定放在同一个
 * 抽屉里：店铺名称、营业执照、法人证件正反面、联系方式、申请时间，以及驳回原因
 * 输入框，一屏之内全部在场，不需要在弹窗之间来回翻。
 *
 * 原来的页面有三处不成立的地方：
 *   1. 认证材料弹窗只显示图片；上传的是 PDF 时那里永远是一张破图，也没有任何
 *      可点的链接，等于材料看不到；
 *   2. 状态文案是页面内自己写的（0 关闭 / 1 正常 / 2 审核中），和共享字典
 *      @/constants/domain 的 SHOP_STATUS 各说各话；
 *   3. 分页参数写成 `page`（后端认的是 pageNum），第 2 页开始永远是第 1 页。
 */

const route = useRoute()

const loading = ref(true)
const failed = ref(false)
const keyword = ref('')
const rows = ref<AdminUser[]>([])
const total = ref(0)
const page = ref(1)
const size = ref(10)
/** 关键词检索在后端会绕过 user_type / shop_status 过滤，被筛掉的条数要告诉管理员。 */
const filteredOut = ref(0)

const drawer = ref(false)
const detail = ref<AdminUser | null>(null)
/** 当前抽屉指向的商家，重试时要用它，不能回头看地址栏。 */
const detailId = ref(0)
const detailLoading = ref(false)
const detailError = ref('')
const revealPhone = ref(false)
const submitting = ref(false)
const submitError = ref('')
const rejectReason = ref('')
const decision = ref<'approve' | 'reject'>('approve')

const MAX_REASON = 200

const detailed = computed(() => detail.value)
const inQueue = computed(() => detailed.value?.shopStatus === 2)

function isPendingMerchant(row: AdminUser) {
  return row.userType === 2 && row.shopStatus === 2
}

async function load() {
  loading.value = true
  failed.value = false
  try {
    const pageData = await getMerchantAuditList({
      pageNum: page.value,
      pageSize: size.value,
      keyword: keyword.value.trim() || undefined,
    })
    const records = pageData.records ?? []
    const kept = records.filter(isPendingMerchant)
    filteredOut.value = records.length - kept.length
    rows.value = kept
    total.value = pageData.total ?? kept.length
  } catch {
    failed.value = true
    rows.value = []
    total.value = 0
    filteredOut.value = 0
  } finally {
    loading.value = false
  }
}

async function openAudit(userId: number) {
  if (!Number.isFinite(userId) || userId <= 0) return
  drawer.value = true
  detailId.value = userId
  detailLoading.value = true
  detailError.value = ''
  detail.value = null
  revealPhone.value = false
  rejectReason.value = ''
  submitError.value = ''
  decision.value = 'approve'
  try {
    detail.value = await getMerchantDetail(userId)
  } catch (error) {
    // 拦截器已经弹过一次提示，这里只留下可重试的页面内说明。
    detailError.value = error instanceof Error ? error.message : '认证材料没能取回来'
  } finally {
    detailLoading.value = false
  }
}

function search() {
  page.value = 1
  void load()
}

function resetSearch() {
  keyword.value = ''
  search()
}

function changeSize() {
  page.value = 1
  void load()
}

/** 资质材料可能是图片也可能是 PDF，分别给预览和新窗口打开。 */
function materialKind(url?: string | null): 'empty' | 'pdf' | 'image' {
  if (!url) return 'empty'
  return /\.pdf(\?|$)/i.test(url) ? 'pdf' : 'image'
}

function materialName(url: string) {
  const name = url.split('/').pop() ?? url
  return decodeURIComponent(name)
}

async function submitDecision() {
  const target = detail.value
  if (!target || submitting.value) return

  if (decision.value === 'reject') {
    const reason = rejectReason.value.trim()
    if (reason.length < 4) {
      submitError.value = '驳回理由至少 4 个字：商家要靠它知道该改什么。'
      return
    }
    submitError.value = ''
    submitting.value = true
    try {
      await auditMerchant(target.userId, { auditStatus: 2, rejectReason: reason })
      ElMessage.success('已驳回，理由已随站内通知发给商家')
      drawer.value = false
      await load()
    } catch (error) {
      submitError.value = error instanceof Error ? error.message : '驳回失败，请重试'
    } finally {
      submitting.value = false
    }
    return
  }

  try {
    await ElMessageBox.confirm(
      `通过后「${target.shopName || target.username}」可以正常营业并上架商品。确认资质材料已经看过？`,
      '确认通过认证',
      { confirmButtonText: '通过认证', cancelButtonText: '再核对一下' },
    )
  } catch {
    return
  }

  submitError.value = ''
  submitting.value = true
  try {
    await auditMerchant(target.userId, { auditStatus: 1 })
    ElMessage.success('已通过，商家可以开始营业')
    drawer.value = false
    await load()
  } catch (error) {
    submitError.value = error instanceof Error ? error.message : '审核失败，请重试'
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  void load()
  const focus = Number(route.query.merchant)
  if (Number.isFinite(focus) && focus > 0) void openAudit(focus)
})
</script>

<template>
  <div class="audit" data-density="admin">
    <SectionHead
      title="商家认证审核"
      note="队列里是已经提交资质、等待开业的店铺。通过前请把营业执照与法人证件看完。"
      size="lg"
    >
      <template #action>
        <button class="link-action" type="button" :disabled="loading" @click="load">
          <AppIcon name="refresh" size="14" />
          刷新队列
        </button>
      </template>
    </SectionHead>

    <div class="toolbar">
      <el-input
        v-model="keyword"
        class="toolbar__search"
        placeholder="按店铺名称或登录账号搜索"
        clearable
        @keyup.enter="search"
      />
      <el-button @click="search">查询</el-button>
      <el-button @click="resetSearch">重置</el-button>
      <span class="toolbar__count">
        待审 {{ total }} 家
        <template v-if="filteredOut > 0">（另有 {{ filteredOut }} 条非待审记录被过滤）</template>
      </span>
    </div>

    <p v-if="failed" class="band band--error">
      <AppIcon name="warning" size="15" />
      <span>队列没能加载。请确认后端服务在运行，然后重试。</span>
      <button class="band__action" type="button" @click="load">重试</button>
    </p>

    <section class="plate">
      <div v-if="loading" class="loading-list">
        <span v-for="n in 4" :key="n" class="skeleton loading-list__row" />
      </div>

      <EmptyState
        v-else-if="rows.length === 0"
        title="没有商家在等审核"
        note="商家提交营业执照和法人证件后，会自动进入这个队列。"
      />

      <div v-else class="table-scroll">
        <el-table :data="rows" size="small" style="width: 100%">
          <el-table-column label="店铺" min-width="200">
            <template #default="{ row }">
              <span class="cell-strong">{{ row.shopName || '未填写店铺名称' }}</span>
              <span class="cell-sub">账号 {{ row.username }}</span>
            </template>
          </el-table-column>
          <el-table-column label="联系方式" min-width="170">
            <template #default="{ row }">
              <span>{{ maskPhone(row.phone) }}</span>
              <span class="cell-sub">{{ row.email || '未填写邮箱' }}</span>
            </template>
          </el-table-column>
          <el-table-column label="资质" min-width="140">
            <template #default="{ row }">
              <span class="material-flags">
                <StatePill
                  label="营业执照"
                  :tone="row.businessLicense ? 'teal' : 'outline'"
                />
                <StatePill
                  label="法人证件"
                  :tone="row.legalIdFront && row.legalIdBack ? 'teal' : 'outline'"
                />
              </span>
            </template>
          </el-table-column>
          <el-table-column label="店铺状态" width="120">
            <template #default="{ row }">
              <StatePill
                :label="shopStateOf(row.shopStatus).label"
                :tone="shopStateOf(row.shopStatus).tone"
              />
            </template>
          </el-table-column>
          <el-table-column label="申请时间" min-width="170">
            <template #default="{ row }">
              <span>{{ formatDateTime(row.createTime) }}</span>
              <span class="cell-sub">{{ formatRelative(row.createTime) }}</span>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="120" fixed="right">
            <template #default="{ row }">
              <el-button type="primary" size="small" @click="openAudit(row.userId)">
                审核
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

    <!-- 审核抽屉：证据与决定同屏 -->
    <el-drawer
      v-model="drawer"
      :title="detailed?.shopName || '商家认证审核'"
      size="620px"
      direction="rtl"
    >
      <div v-if="detailLoading" class="drawer-state">
        <span class="skeleton drawer-state__block" />
        <span class="skeleton drawer-state__block" />
        <span class="skeleton drawer-state__block" />
      </div>

      <div v-else-if="detailError" class="band band--error">
        <AppIcon name="warning" size="15" />
        <span>{{ detailError }}</span>
        <button class="band__action" type="button" @click="openAudit(detailId)">
          重试
        </button>
      </div>

      <div v-else-if="detailed" class="drawer-body">
        <p v-if="!inQueue" class="band band--notice">
          <AppIcon name="info" size="15" />
          <span>
            这家店铺已经不在待审队列里（当前状态：{{ shopStateOf(detailed.shopStatus).label }}）。
            下面是档案，仅供查看。
          </span>
        </p>

        <SpecList
          :entries="[
            { key: '店铺名称', value: detailed.shopName || '未填写' },
            { key: '登录账号', value: detailed.username, mono: true },
            { key: '商家ID', value: `#${detailed.userId}`, mono: true },
            { key: '店铺类型', value: detailed.businessType === 'personal' ? '个人店铺' : detailed.businessType === 'enterprise' ? '企业店铺' : '未填写' },
            { key: '联系人', value: detailed.nickname },
            { key: '邮箱', value: detailed.email },
            { key: '店铺地址', value: detailed.shopAddress },
            { key: '申请时间', value: formatDateTime(detailed.createTime) },
          ]"
        />

        <section class="evidence">
          <h3 class="evidence__title">联系方式</h3>
          <div class="phone">
            <span class="phone__value mono">
              {{ revealPhone ? detailed.phone || '未填写' : maskPhone(detailed.phone) }}
            </span>
            <button
              v-if="detailed.phone"
              class="link-action"
              type="button"
              @click="revealPhone = !revealPhone"
            >
              {{ revealPhone ? '隐藏' : '显示完整号码' }}
            </button>
          </div>
        </section>

        <section class="evidence">
          <h3 class="evidence__title">资质材料</h3>
          <div class="materials">
            <figure
              v-for="item in [
                { label: '营业执照', url: detailed.businessLicense },
                { label: '法人身份证正面', url: detailed.legalIdFront },
                { label: '法人身份证反面', url: detailed.legalIdBack },
              ]"
              :key="item.label"
              class="material"
            >
              <figcaption class="material__label">{{ item.label }}</figcaption>

              <a
                v-if="materialKind(item.url) === 'image'"
                class="material__link"
                :href="resolveImageUrl(item.url)"
                target="_blank"
                rel="noopener"
                :title="`在新窗口查看${item.label}原图`"
              >
                <ImageFrame :src="item.url" :alt="item.label" ratio="16 / 10" fit="contain" />
              </a>

              <a
                v-else-if="materialKind(item.url) === 'pdf'"
                class="material__doc"
                :href="resolveImageUrl(item.url)"
                target="_blank"
                rel="noopener"
              >
                <AppIcon name="document" size="18" />
                <span class="material__doc-name">{{ materialName(item.url || '') }}</span>
                <span class="material__doc-hint">在新窗口打开 PDF</span>
              </a>

              <p v-else class="material__empty">未上传</p>
            </figure>
          </div>
          <p class="evidence__note">图片点开可在新窗口看原图，PDF 直接在新窗口打开。</p>
        </section>

        <section v-if="detailed.shopDescription" class="evidence">
          <h3 class="evidence__title">店铺简介</h3>
          <p class="evidence__text">{{ detailed.shopDescription }}</p>
        </section>
      </div>

      <template #footer>
        <div v-if="detailed && inQueue" class="decision">
          <div class="decision__modes">
            <label class="decision__mode" :class="{ 'is-on': decision === 'approve' }">
              <input v-model="decision" type="radio" value="approve" />
              通过
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
            placeholder="写清楚缺什么、哪一项不清楚，商家按这句话补材料"
          />

          <p v-if="submitError" class="decision__error">
            <AppIcon name="warning" size="14" />
            <span>{{ submitError }}</span>
          </p>

          <div class="decision__actions">
            <el-button @click="drawer = false">稍后再审</el-button>
            <el-button
              type="primary"
              :loading="submitting"
              @click="submitDecision"
            >
              {{ decision === 'reject' ? '确认驳回' : '确认通过' }}
            </el-button>
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

.toolbar__search {
  max-width: 320px;
}

.toolbar__count {
  margin-left: auto;
  font-size: var(--text-xs);
  color: var(--ink-3);
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

.band--notice {
  background: var(--paper-2);
  color: var(--ink-2);
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

.cell-strong {
  display: block;
  color: var(--ink-0);
  font-weight: 600;
}

.cell-sub {
  display: block;
  color: var(--ink-3);
  font-size: var(--text-xs);
}

.material-flags {
  display: inline-flex;
  gap: var(--space-1);
  flex-wrap: wrap;
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
  gap: var(--space-3);
}

.drawer-state__block {
  height: calc(48px * var(--dense));
}

.evidence__title {
  margin-bottom: var(--space-2);
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-0);
}

.evidence__note {
  margin-top: var(--space-2);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.evidence__text {
  font-size: var(--text-sm);
  color: var(--ink-2);
  white-space: pre-wrap;
}

.phone {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.phone__value {
  font-size: var(--text-md);
  color: var(--ink-0);
}

.materials {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: var(--space-3);
  margin: 0;
}

.material {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
  margin: 0;
}

.material__label {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.material__link {
  display: block;
  border: var(--edge);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.material__doc {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-4);
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-1);
  color: var(--ink-1);
}

.material__doc:hover {
  border-color: var(--ink-3);
  text-decoration: none;
}

.material__doc-name {
  font-size: var(--text-sm);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.material__doc-hint {
  margin-left: auto;
  font-size: var(--text-2xs);
  color: var(--ink-3);
  white-space: nowrap;
}

.material__empty {
  padding: var(--space-6) var(--space-4);
  border: 1px dashed var(--line-2);
  border-radius: var(--radius-sm);
  color: var(--ink-4);
  font-size: var(--text-sm);
  text-align: center;
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
  .toolbar__count {
    margin-left: 0;
  }

  .materials {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
