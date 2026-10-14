<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import axios from '@/axios'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import FileUploader from '@/components/ui/FileUploader.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { AUDIT_STATUS, conditionLabel, labelOf, PRODUCT_TYPE, SHELF_STATUS } from '@/constants/domain'
import type { UploadedFile } from '@/api/files'
import {
  bindProductImages,
  composeDescription,
  errorText,
  getBrandTree,
  getCategoryTree,
  getProductDetail,
  getProductImages,
  isAuthError,
  MAX_RENTAL_DAYS,
  PRODUCT_TYPE_CODE,
  specObjectToRows,
  specRowsToObject,
  splitDescription,
  updateProduct,
  type BrandNode,
  type CategoryNode,
  type MerchantTypeKey,
  type ProductPayload,
  type SpecEntry,
} from '@/api/merchant/product'

// 商品编辑。
//
// 与发布页共用同一套骨架：基础信息 → 规格参数 → 价格与库存 → 图片 → 描述。
//
// 两处与发布页不同，都是刻意的：
//   1. 商品类型只读。改类型会让已经卖出去的订单、库存和租赁档案对不上，
//      需要换类型就新建一件商品；
//   2. 押金、起租天数、最长租期与规格参数不在商家详情接口里，需要另读一次
//      商品详情（/shop/products/{id}）—— 那里的 GoodsDetailVO 才带
//      product_rental_detail 与 product_detail.parameters。不读的话，保存时
//      押金会被后端按「原价 × 10%」的默认值覆盖掉。

const route = useRoute()
const router = useRouter()

const productId = String(route.params.id ?? '')
const CONDITION_OPTIONS = [99, 95, 90, 80]

const TYPE_LABEL: Record<MerchantTypeKey, string> = {
  new: '全新商品',
  used: '二手商品',
  rental: '租赁商品',
}

function typeKeyOf(productType: number): MerchantTypeKey {
  if (productType === 2) return 'used'
  if (productType === 3) return 'rental'
  return 'new'
}

const type = ref<MerchantTypeKey>('new')
const auditStatus = ref(1)
const shelfStatus = ref(0)
const rejectReason = ref('')

const categoryTree = ref<CategoryNode[]>([])
const brandTree = ref<BrandNode[]>([])
const loading = ref(true)
const failed = ref(false)
const authFailed = ref(false)
const failureText = ref('')
const submitting = ref(false)
const problems = ref('')
const rentalRuleLoaded = ref(false)

const formRef = ref<FormInstance>()
const files = ref<UploadedFile[]>([])
const specs = ref<SpecEntry[]>([{ key: '', value: '' }])

const form = reactive({
  brand: null as number | null,
  categoryId: null as number | null,
  model: '',
  color: '',
  originalPrice: 0,
  price: 0,
  stock: 0,
  minStock: 10,
  deposit: 0,
  minRentalDays: 1,
  condition: 95,
  usageDuration: '',
  repairHistory: '0',
  accessories: '',
  defectDesc: '',
  description: '',
})

const rules: FormRules = {
  categoryId: [{ required: true, message: '选择商品分类', trigger: 'change' }],
  brand: [{ required: true, message: '选择品牌', trigger: 'change' }],
  model: [{ required: true, message: '填写型号', trigger: 'blur' }],
  originalPrice: [
    { required: true, message: '填写原价', trigger: 'blur' },
    { type: 'number', min: 0.01, message: '原价要大于 0', trigger: 'blur' },
  ],
  price: [
    { required: true, message: '填写价格', trigger: 'blur' },
    { type: 'number', min: 0.01, message: '价格要大于 0', trigger: 'blur' },
  ],
  stock: [
    { required: true, message: '填写库存', trigger: 'blur' },
    { type: 'number', min: 0, message: '库存不能是负数', trigger: 'blur' },
  ],
  minStock: [
    { required: true, message: '填写安全库存', trigger: 'blur' },
    { type: 'number', min: 0, message: '安全库存不能是负数', trigger: 'blur' },
  ],
  description: [
    { required: true, message: '写一段商品描述', trigger: 'blur' },
    { min: 10, max: 1000, message: '描述在 10 到 1000 个字之间', trigger: 'blur' },
  ],
}

const isRental = computed(() => type.value === 'rental')
const isUsed = computed(() => type.value === 'used')
const priceLabel = computed(() => (isRental.value ? '日租金' : '售价'))
const stockLabel = computed(() => (isRental.value ? '可租台数' : '库存'))
const audit = computed(() => labelOf(AUDIT_STATUS, auditStatus.value))
const shelf = computed(() => labelOf(SHELF_STATUS, shelfStatus.value))
const productTypeState = computed(() => labelOf(PRODUCT_TYPE, PRODUCT_TYPE_CODE[type.value]))

function imageIds() {
  return files.value.map((file) => file.id)
}

function addSpec() {
  specs.value = [...specs.value, { key: '', value: '' }]
}

function removeSpec(index: number) {
  specs.value = specs.value.filter((_, item) => item !== index)
  if (!specs.value.length) addSpec()
}

function toUploadedFiles(rows: { imageId: number; url: string }[]): UploadedFile[] {
  return rows.map((row) => ({
    id: row.imageId,
    url: row.url,
    name: row.url.split('/').pop() ?? `图片 ${row.imageId}`,
    size: 0,
    width: null,
    height: null,
  }))
}

/** 商品详情接口不含租赁规则与规格参数，这里补一次只读查询。 */
async function loadExtraDetail() {
  try {
    const body = await axios.get(`/shop/products/${productId}`)
    const data = (body as any)?.data ?? body ?? {}
    specs.value = specObjectToRows(data.specifications)
    if (!specs.value.length) specs.value = [{ key: '', value: '' }]
    if (isRental.value) {
      form.deposit = Number(data.deposit ?? 0)
      form.minRentalDays = Number(data.minRentalDays ?? 1)
      rentalRuleLoaded.value = true
    }
  } catch {
    // 读不到时保留商品详情里的起租天数，其余字段按空值提交会覆盖线上数据，
    // 所以租赁商品在这种情况下禁止保存（见 canSave）。
    rentalRuleLoaded.value = false
  }
}

async function load() {
  loading.value = true
  failed.value = false
  authFailed.value = false
  try {
    const [detail, categories, brands, images] = await Promise.all([
      getProductDetail(productId),
      getCategoryTree(),
      getBrandTree(),
      getProductImages(productId),
    ])
    categoryTree.value = categories
    brandTree.value = brands
    files.value = toUploadedFiles(images)

    type.value = typeKeyOf(Number(detail.productType))
    auditStatus.value = Number(detail.auditStatus ?? 0)
    shelfStatus.value = Number(detail.isOnShelf ?? 0)
    rejectReason.value = detail.rejectReason ?? ''

    form.brand = detail.brand ?? null
    form.categoryId = detail.categoryId ?? null
    form.model = detail.model ?? ''
    form.color = detail.color ?? ''
    form.originalPrice = Number(detail.originalPrice ?? 0)
    form.price = Number(detail.price ?? 0)
    form.stock = Number(detail.stock ?? 0)
    form.minStock = Number(detail.minStock ?? 10)
    form.minRentalDays = Number(detail.minRentalDays ?? 1)
    form.condition = Number(detail.condition ?? 95)
    form.usageDuration = detail.usageDuration ?? ''
    form.repairHistory = String(detail.repairHistory ?? '0')
    form.accessories = detail.accessories ?? ''

    const text = splitDescription(detail.description)
    form.description = text.description
    form.defectDesc = text.defectDesc

    await loadExtraDetail()
  } catch (error) {
    failed.value = true
    authFailed.value = isAuthError(error)
    failureText.value = errorText(error, '没能读取商品详情')
  } finally {
    loading.value = false
  }
}

const canSave = computed(() => !isRental.value || rentalRuleLoaded.value)

function checkDomain(): string {
  if (!imageIds().length) return '至少保留一张商品图片，第一张会作为主图。'
  if (!(form.price > 0)) return `${priceLabel.value}要大于 0。`
  if (form.stock < 0) return '库存不能是负数。'
  if (isRental.value) {
    if (!(form.minRentalDays >= 1)) return '起租天数至少 1 天。'
    if (form.minRentalDays > MAX_RENTAL_DAYS) {
      return `起租天数不能超过最长租期 ${MAX_RENTAL_DAYS} 天。`
    }
    if (form.deposit < 0) return '押金不能是负数。'
  }
  return ''
}

function buildPayload(): ProductPayload {
  const payload: ProductPayload = {
    model: form.model.trim(),
    brand: Number(form.brand),
    categoryId: Number(form.categoryId),
    productType: PRODUCT_TYPE_CODE[type.value],
    originalPrice: form.originalPrice,
    price: form.price,
    stock: form.stock,
    minStock: form.minStock,
    description: composeDescription(form.description, isUsed.value ? form.defectDesc : ''),
    imageIds: imageIds(),
    parameters: specRowsToObject(specs.value),
  }
  if (isUsed.value) {
    payload.condition = form.condition
    payload.usageDuration = form.usageDuration.trim()
    payload.repairHistory = form.repairHistory
    payload.accessories = form.accessories.trim()
    payload.defectDesc = form.defectDesc.trim()
  } else if (isRental.value) {
    payload.deposit = form.deposit
    payload.minRentalDays = form.minRentalDays
    payload.maxRentalDays = MAX_RENTAL_DAYS
  } else {
    payload.color = form.color.trim()
  }
  return payload
}

async function submit() {
  problems.value = ''
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) {
    ElMessage.warning('还有必填项没填完，标红的地方需要补上')
    return
  }
  const issue = checkDomain()
  if (issue) {
    problems.value = issue
    ElMessage.warning(issue)
    return
  }
  if (!canSave.value) {
    problems.value = '没能读到这件商品的押金与租期，直接保存会把它们覆盖成默认值。'
    ElMessage.warning(problems.value)
    return
  }

  const payload = buildPayload()
  const ids = payload.imageIds
  submitting.value = true
  try {
    await updateProduct(productId, payload)
    await bindProductImages(Number(productId), 'main', ids.slice(0, 1))
    if (ids.length > 1) await bindProductImages(Number(productId), 'detail', ids.slice(1))
    ElMessage.success('已保存，买家看到的就是这里的内容')
    router.push(`/merchant-dashboard/product-management?type=${type.value}`)
  } catch (error) {
    problems.value = errorText(error, '保存失败，请稍后重试')
    ElMessage.error(problems.value)
  } finally {
    submitting.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="stack">
    <header class="page-head">
      <div>
        <h1 class="page-head__title">编辑商品</h1>
        <p class="page-head__note">
          {{ form.model || '未命名商品' }} · 商品类型发布后不能修改，需要换类型请新建商品。
        </p>
        <div class="pills">
          <StatePill :label="productTypeState.label" :tone="productTypeState.tone" />
          <StatePill :label="audit.label" :tone="audit.tone" />
          <StatePill :label="shelf.label" :tone="shelf.tone" />
        </div>
      </div>
      <el-button @click="router.push(`/merchant-dashboard/product-management?type=${type}`)">
        返回商品管理
      </el-button>
    </header>

    <section v-if="loading" class="plate form" aria-busy="true">
      <div v-for="n in 8" :key="n" class="ghost__row skeleton" />
    </section>

    <section v-else-if="failed" class="plate">
      <EmptyState
        :title="authFailed ? '登录状态已失效' : '没能读取商品详情'"
        :note="
          authFailed
            ? '登录信息可能已过期，重新登录后即可继续编辑。'
            : `${failureText}。确认这件商品还在你的店铺里。`
        "
      >
        <el-button v-if="authFailed" type="primary" @click="router.push('/login')">去登录</el-button>
        <el-button v-else type="primary" @click="load">重试</el-button>
      </EmptyState>
    </section>

    <template v-else>
      <p v-if="auditStatus === 2" class="banner banner--reject">
        平台驳回：{{ rejectReason || '未填写驳回原因' }}。改完再保存，商品会重新进入审核队列。
      </p>

      <p v-else-if="isRental && !rentalRuleLoaded" class="banner banner--warn">
        没能读到这件商品的押金与租期，为避免把它们覆盖成默认值，保存已暂时停用。
        <button class="banner__link" type="button" @click="loadExtraDetail">重新读取</button>
      </p>

      <el-form
        ref="formRef"
        class="plate form"
        :model="form"
        :rules="rules"
        label-position="top"
        @submit.prevent
      >
        <fieldset class="block">
          <legend class="block__head">基础信息</legend>
          <div class="cols">
            <el-form-item label="品牌" prop="brand" class="cell">
              <el-tree-select
                v-model="form.brand"
                :data="brandTree"
                :render-after-expand="false"
                :props="{ label: 'name', value: 'id', children: 'children' }"
                placeholder="选择品牌"
              />
            </el-form-item>

            <el-form-item label="分类" prop="categoryId" class="cell">
              <el-tree-select
                v-model="form.categoryId"
                :data="categoryTree"
                :render-after-expand="false"
                :props="{ label: 'name', value: 'id', children: 'children' }"
                placeholder="选择分类"
              />
            </el-form-item>

            <el-form-item label="型号" prop="model" class="cell">
              <el-input v-model="form.model" placeholder="如 Z8、EOS R5 Mark II" />
            </el-form-item>

            <el-form-item v-if="type === 'new'" label="颜色" class="cell">
              <el-input v-model="form.color" placeholder="如 黑色、银黑" />
            </el-form-item>
          </div>
        </fieldset>

        <fieldset class="block">
          <legend class="block__head">规格参数</legend>
          <div class="specs">
            <div v-for="(row, index) in specs" :key="index" class="specs__row">
              <el-input v-model="row.key" placeholder="参数名，如 卡口" />
              <el-input v-model="row.value" placeholder="参数值，如 尼康 Z" />
              <button
                class="icon-btn"
                type="button"
                title="删除这一行"
                aria-label="删除这一行参数"
                @click="removeSpec(index)"
              >
                <AppIcon name="minus" size="14" />
              </button>
            </div>
          </div>
          <el-button size="small" @click="addSpec">
            <AppIcon name="plus" size="13" />
            添加参数
          </el-button>
        </fieldset>

        <fieldset class="block">
          <legend class="block__head">价格与库存</legend>
          <div class="cols">
            <el-form-item label="原价" prop="originalPrice" class="cell">
              <el-input-number
                v-model="form.originalPrice"
                :min="0"
                :step="100"
                :precision="2"
                controls-position="right"
              />
              <p class="cell__hint">展示为划线价，也是押金的参考基数</p>
            </el-form-item>

            <el-form-item :label="priceLabel" prop="price" class="cell">
              <el-input-number
                v-model="form.price"
                :min="0"
                :step="10"
                :precision="2"
                controls-position="right"
              />
              <p class="cell__hint">
                {{ isRental ? '按天计价，直接改动会影响新订单' : '买家实付单价，直接改动立即生效' }}
              </p>
            </el-form-item>

            <el-form-item :label="stockLabel" prop="stock" class="cell">
              <el-input-number v-model="form.stock" :min="0" step="1" controls-position="right" />
              <p class="cell__hint">
                {{ isUsed ? '二手是单件在售，通常为 1' : '调低库存不会影响已经成立的订单' }}
              </p>
            </el-form-item>

            <el-form-item label="安全库存" prop="minStock" class="cell">
              <el-input-number v-model="form.minStock" :min="0" step="1" controls-position="right" />
              <p class="cell__hint">低于这个数时在商家首页提示补货</p>
            </el-form-item>
          </div>

          <div v-if="isRental" class="cols cols--split">
            <el-form-item label="押金" class="cell">
              <el-input-number
                v-model="form.deposit"
                :min="0"
                :step="100"
                :precision="2"
                controls-position="right"
              />
              <p class="cell__hint">归还验收后原路退回</p>
            </el-form-item>

            <el-form-item label="起租天数" class="cell">
              <el-input-number
                v-model="form.minRentalDays"
                :min="1"
                step="1"
                controls-position="right"
              />
              <p class="cell__hint">1 到 {{ MAX_RENTAL_DAYS }} 天，最长租期由平台统一设定</p>
            </el-form-item>
          </div>
        </fieldset>

        <fieldset v-if="isUsed" class="block">
          <legend class="block__head">成色与瑕疵</legend>
          <div class="cols">
            <el-form-item label="成色" class="cell">
              <el-radio-group v-model="form.condition">
                <el-radio-button v-for="grade in CONDITION_OPTIONS" :key="grade" :value="grade">
                  {{ conditionLabel(grade) }}
                </el-radio-button>
              </el-radio-group>
            </el-form-item>

            <el-form-item label="使用时长" class="cell">
              <el-input v-model="form.usageDuration" placeholder="如 1 年 3 个月" />
            </el-form-item>

            <el-form-item label="维修记录" class="cell">
              <el-radio-group v-model="form.repairHistory">
                <el-radio value="0">无维修记录</el-radio>
                <el-radio value="1">有维修记录</el-radio>
              </el-radio-group>
            </el-form-item>

            <el-form-item label="配件清单" class="cell">
              <el-input
                v-model="form.accessories"
                type="textarea"
                :rows="2"
                placeholder="如 原装电池、充电器、机身盖"
              />
            </el-form-item>
          </div>

          <el-form-item label="瑕疵说明" class="cell cell--wide">
            <el-input
              v-model="form.defectDesc"
              type="textarea"
              :rows="3"
              maxlength="300"
              show-word-limit
              placeholder="如实写明磕碰、掉漆、进灰或功能异常的位置与程度"
            />
          </el-form-item>
        </fieldset>

        <fieldset class="block">
          <legend class="block__head">商品图片</legend>
          <FileUploader
            v-model="files"
            biz-type="product"
            :max="8"
            hint="第一张作为主图，删掉再传会替换这一张"
          />
        </fieldset>

        <fieldset class="block">
          <legend class="block__head">商品描述</legend>
          <el-form-item prop="description" class="cell cell--wide">
            <el-input
              v-model="form.description"
              type="textarea"
              :rows="5"
              maxlength="1000"
              show-word-limit
              placeholder="写清成色、功能、配件与保修情况"
            />
          </el-form-item>
        </fieldset>
      </el-form>

      <div class="actions">
        <p v-if="problems" class="actions__error">{{ problems }}</p>
        <span v-else class="actions__note">保存后买家看到的即是这里的内容</span>
        <span class="spacer" />
        <el-button @click="router.push(`/merchant-dashboard/product-management?type=${type}`)">
          取消
        </el-button>
        <el-button type="primary" :loading="submitting" :disabled="!canSave" @click="submit">
          <AppIcon name="check" size="14" />
          保存修改
        </el-button>
      </div>
    </template>
  </div>
</template>

<style scoped>
.pills {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  margin-top: var(--space-2);
}

.banner {
  padding: var(--space-3) var(--pad-surface);
  border: var(--edge);
  border-radius: var(--radius-md);
  font-size: var(--text-sm);
}

.banner--reject {
  background: var(--signal-vermilion-wash);
  border-color: var(--signal-vermilion);
  color: var(--signal-vermilion-deep);
}

.banner--warn {
  background: var(--signal-amber-wash);
  border-color: var(--signal-amber);
  color: var(--signal-amber-deep);
}

.banner__link {
  margin-left: var(--space-2);
  border: none;
  background: transparent;
  color: inherit;
  font-weight: 600;
  text-decoration: underline;
  cursor: pointer;
}

.form {
  padding: var(--pad-surface);
}

.block {
  margin: 0;
  padding: 0;
  border: none;
  min-width: 0;
}

.block + .block {
  margin-top: var(--space-5);
  padding-top: var(--space-5);
  border-top: var(--hairline);
}

.block__head {
  padding: 0;
  margin-bottom: var(--space-3);
  color: var(--ink-0);
  font-size: var(--text-base);
  font-weight: 600;
}

.cols {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
  gap: var(--space-4);
}

.cols--split {
  margin-top: var(--space-4);
}

.cell {
  margin-bottom: 0;
}

.cell--wide {
  margin-top: var(--space-3);
}

.cell :deep(.el-form-item__label) {
  padding-bottom: 2px;
  line-height: 1.4;
}

.cell :deep(.el-input-number) {
  width: 100%;
}

.cell__hint {
  margin-top: 2px;
  color: var(--ink-4);
  font-size: var(--text-2xs);
  line-height: 1.5;
}

.specs {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  margin-bottom: var(--space-3);
}

.specs__row {
  display: grid;
  grid-template-columns: 200px minmax(0, 1fr) 28px;
  gap: var(--space-2);
  align-items: center;
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
  color: var(--ink-3);
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.icon-btn:hover {
  background: var(--signal-vermilion-wash);
  color: var(--signal-vermilion-deep);
}

.actions {
  position: sticky;
  bottom: 0;
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--pad-surface);
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
}

.actions__note {
  color: var(--ink-4);
  font-size: var(--text-xs);
}

.actions__error {
  color: var(--signal-vermilion-deep);
  font-size: var(--text-sm);
}

.ghost__row {
  height: 22px;
  margin-bottom: var(--space-3);
  border-radius: var(--radius-xs);
}

@media (max-width: 767px) {
  .specs__row {
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr) 28px;
  }

  .actions {
    flex-wrap: wrap;
  }

  .actions__note,
  .actions__error {
    flex-basis: 100%;
  }
}
</style>
