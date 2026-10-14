<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import FileUploader from '@/components/ui/FileUploader.vue'
import { conditionLabel } from '@/constants/domain'
import type { UploadedFile } from '@/api/files'
import {
  bindProductImages,
  composeDescription,
  createProduct,
  errorText,
  getBrandTree,
  getCategoryTree,
  getProductList,
  isAuthError,
  MAX_RENTAL_DAYS,
  PRODUCT_TYPE_CODE,
  specRowsToObject,
  type BrandNode,
  type CategoryNode,
  type MerchantTypeKey,
  type ProductPayload,
  type SpecEntry,
} from '@/api/merchant/product'

// 商品发布。
//
// 表单的骨架是「规格轨」：基础信息 → 规格参数 → 价格与库存 → 图片 → 描述，
// 二手商品在价格之后多一段成色与瑕疵。
//
// 原实现的四处问题：
//   1. 图片走 el-upload + /api/image/upload，拿的是 storagePath，页面自己拼数组，
//      失败时表单里会留下一张没有 imageId 的图；
//   2. 提交时把 condition 一起发给全新商品，还多发了 quality 这个后端不读的字段，
//      并自传 isOnShelf: 1（后端固定写 0，等审核）；
//   3. 类型切换后其他类型的字段仍留在 reactive 对象里，一起被提交；
//   4. 图片只写进 product_detail.img_urls，product_image 的绑定顺序没有统一口径。

const route = useRoute()
const router = useRouter()

const TYPE_MODES: { key: MerchantTypeKey; label: string }[] = [
  { key: 'new', label: '全新商品' },
  { key: 'used', label: '二手商品' },
  { key: 'rental', label: '租赁商品' },
]

const CONDITION_OPTIONS = [99, 95, 90, 80]

function normalizeType(value: unknown): MerchantTypeKey {
  return value === 'used' || value === 'rental' ? value : 'new'
}

const type = ref<MerchantTypeKey>(normalizeType(route.query.type))

const categoryTree = ref<CategoryNode[]>([])
const brandTree = ref<BrandNode[]>([])
const loading = ref(true)
const failed = ref(false)
const authFailed = ref(false)
const failureText = ref('')
const submitting = ref(false)
const problems = ref('')

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
const modeNote = computed(() => {
  if (isRental.value) return '按天计价，押金在归还验收后原路退回'
  if (isUsed.value) return '单件在售，成色与瑕疵会展示给买家'
  return '库存制商品，审核通过后可上架'
})

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

// 切换类型时清掉其他类型的字段，避免它们跟着一起提交。
function pickType(next: MerchantTypeKey) {
  if (type.value === next) return
  type.value = next
  form.price = 0
  form.stock = 0
  form.deposit = 0
  form.minRentalDays = 1
  form.condition = 95
  form.usageDuration = ''
  form.repairHistory = '0'
  form.accessories = ''
  form.defectDesc = ''
  form.color = ''
  problems.value = ''
  router.replace({ path: route.path, query: { ...route.query, type: next } })
}

async function load() {
  loading.value = true
  failed.value = false
  authFailed.value = false
  try {
    const [categories, brands] = await Promise.all([getCategoryTree(), getBrandTree()])
    categoryTree.value = categories
    brandTree.value = brands
  } catch (error) {
    failed.value = true
    authFailed.value = isAuthError(error)
    failureText.value = errorText(error, '没能取到分类与品牌')
  } finally {
    loading.value = false
  }
}

// 提交前的领域校验：这些规则跨字段，放进 el-form 的规则表反而更绕。
function checkDomain(): string {
  if (!imageIds().length) return '至少上传一张商品图片，第一张会作为主图。'
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

// 创建接口只回一句「添加商品成功」，不返回主键，所以按型号回查一次列表。
// 型号相同时取最大的 productId —— 自增主键，就是刚创建的那一条。
async function findCreatedProductId(model: string): Promise<number | null> {
  const page = await getProductList({
    type: type.value,
    keyword: model,
    pageNum: 1,
    pageSize: 50,
  })
  const matches = page.list.filter((item) => item.name === model)
  if (!matches.length) return null
  return matches.reduce((max, item) => Math.max(max, Number(item.productId)), 0)
}

// 统一图片绑定口径：主图一张、其余为详情图。
// 创建接口会把 imageIds 全部绑成 main，这里重绑一次把顺序定死。
async function normalizeBindings(productId: number, ids: number[]) {
  await bindProductImages(productId, 'main', ids.slice(0, 1))
  if (ids.length > 1) await bindProductImages(productId, 'detail', ids.slice(1))
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

  const payload = buildPayload()
  const ids = payload.imageIds
  const hasSpecs = Object.keys(payload.parameters ?? {}).length > 0
  submitting.value = true
  try {
    await createProduct(payload)
    try {
      const productId = await findCreatedProductId(payload.model)
      if (productId) await normalizeBindings(productId, ids)
    } catch {
      // 图片已随创建请求绑定成功；重绑失败只影响主图是否确定为第一张，
      // 在编辑页保存一次即可修正，不阻断发布。
    }

    if (hasSpecs) {
      ElMessage.warning('商品已提交审核。规格参数暂未被服务端保存，重新打开编辑页时会是空的。')
    } else {
      ElMessage.success('已提交，等平台审核通过后即可上架')
    }
    router.push(`/merchant-dashboard/product-management?type=${type.value}`)
  } catch (error) {
    problems.value = errorText(error, '提交失败，请稍后重试')
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
        <h1 class="page-head__title">发布商品</h1>
        <p class="page-head__note">{{ modeNote }}。提交后进入平台审核，审核通过再手动上架。</p>
      </div>
      <el-button @click="router.push(`/merchant-dashboard/product-management?type=${type}`)">
        返回商品管理
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

    <div v-if="loading" class="plate form" aria-busy="true">
      <div v-for="n in 8" :key="n" class="ghost__row skeleton" />
    </div>

    <section v-else-if="failed" class="plate">
      <EmptyState
        :title="authFailed ? '登录状态已失效' : '没能取到分类与品牌'"
        :note="
          authFailed
            ? '登录信息可能已过期，重新登录后即可继续发布商品。'
            : `${failureText}。分类与品牌是必填项，需要先取到才能发布。`
        "
      >
        <el-button v-if="authFailed" type="primary" @click="router.push('/login')">去登录</el-button>
        <el-button v-else type="primary" @click="load">重试</el-button>
      </EmptyState>
    </section>

    <section v-else-if="!categoryTree.length || !brandTree.length" class="plate">
      <EmptyState title="分类或品牌数据为空" note="商品必须挂在分类与品牌下，数据补全后才能发布。">
        <el-button type="primary" @click="load">重新加载</el-button>
      </EmptyState>
    </section>

    <template v-else>
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
                {{ isRental ? '按天计价，买家按租期天数结算' : '买家实付单价' }}
              </p>
            </el-form-item>

            <el-form-item :label="stockLabel" prop="stock" class="cell">
              <el-input-number v-model="form.stock" :min="0" step="1" controls-position="right" />
              <p class="cell__hint">
                {{ isUsed ? '二手是单件在售，通常填 1' : '大于 0 买家才能下单' }}
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
              <p class="cell__hint">买家先看成色，再读瑕疵</p>
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
            <p class="cell__hint">写得越具体，买家收到货后越少扯皮</p>
          </el-form-item>
        </fieldset>

        <fieldset class="block">
          <legend class="block__head">商品图片</legend>
          <FileUploader
            v-model="files"
            biz-type="product"
            :max="8"
            hint="第一张作为主图，支持 JPG / PNG / WebP，单张不超过 10MB"
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
              placeholder="写清成色、功能、配件与保修情况，以及买家需要提前知道的事"
            />
          </el-form-item>
        </fieldset>
      </el-form>

      <div class="actions">
        <p v-if="problems" class="actions__error">{{ problems }}</p>
        <span v-else class="actions__note">提交时会检查型号、价格、库存、租期与主图</span>
        <span class="spacer" />
        <el-button @click="router.push(`/merchant-dashboard/product-management?type=${type}`)">
          取消
        </el-button>
        <el-button type="primary" :loading="submitting" @click="submit">
          <AppIcon name="check" size="14" />
          发布商品
        </el-button>
      </div>
    </template>
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

.modes__item.is-active {
  background: var(--paper-0);
  color: var(--ink-0);
  font-weight: 600;
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
