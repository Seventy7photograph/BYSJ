<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import SpecList, { type SpecEntry } from '@/components/ui/SpecList.vue'
import StatePill from '@/components/ui/StatePill.vue'
import {
  changePassword,
  changePayPassword,
  getAuthInfo,
  getSecurityInfo,
  getShopInfo,
  setPayPassword,
  submitAuthInfo,
  updateShopInfo,
  uploadAuthMaterial,
  uploadShopLogo,
  type ShopAuthInfo,
  type ShopInfo,
} from '@/api/merchant/shop'
import { useUserStore } from '@/stores/user'
import { formatDate, resolveImageUrl } from '@/utils/format'

/**
 * 店铺管理：店铺资料 / 店铺认证 / 安全设置。
 *
 * 修掉的几件事：
 * - logo 走 POST /merchant/shop/upload-logo（写 user.shop_logo_url），既不会覆盖
 *   个人头像，也不像通用上传那样「上传完却没有落到店铺资料里」；
 * - 资质材料走 POST /merchant/shop/upload-auth-material，PNG / JPG / PDF 都收，
 *   PDF 以文件行呈现而不是硬塞进图片预览；
 * - 资料表单只提交店铺自己的字段（名称/类型/地址/简介）；联系电话与邮箱是账号
 *   信息，统一在个人中心改，避免两个入口互相覆盖；
 * - 「手机验证：已验证」「更换手机号（开发中）」这类假状态全部删掉。
 */
const userStore = useUserStore()

const TABS = [
  { value: 'info', label: '店铺资料' },
  { value: 'auth', label: '店铺认证' },
  { value: 'security', label: '安全设置' },
] as const

type TabValue = (typeof TABS)[number]['value']
type MaterialKey = 'businessLicense' | 'legalIdFront' | 'legalIdBack'

const MATERIALS: { key: MaterialKey; label: string; note: string }[] = [
  { key: 'businessLicense', label: '营业执照', note: '营业执照原件照片或扫描件' },
  { key: 'legalIdFront', label: '法人身份证正面', note: '人像面，证件四角完整' },
  { key: 'legalIdBack', label: '法人身份证反面', note: '国徽面，证件四角完整' },
]

const MATERIAL_ACCEPT = 'image/jpeg,image/png,image/webp,application/pdf'
const MAX_FILE_MB = 10

const SHOP_TYPE_LABEL: Record<string, string> = {
  personal: '个人店铺',
  enterprise: '企业店铺',
}

const SHOP_STATE: Record<string, { label: string; tone: 'teal' | 'amber' | 'outline' }> = {
  normal: { label: '正常营业', tone: 'teal' },
  pending: { label: '审核中', tone: 'amber' },
  closed: { label: '已关闭', tone: 'outline' },
}

const AUTH_STATE: Record<
  string,
  { label: string; tone: 'teal' | 'amber' | 'vermilion' | 'outline'; note: string }
> = {
  approved: { label: '已认证', tone: 'teal', note: '资质已通过平台审核，店铺可以正常经营。' },
  pending: { label: '审核中', tone: 'amber', note: '材料已提交，等平台审核结果。' },
  rejected: { label: '已驳回', tone: 'vermilion', note: '资质未通过，请核对材料后重新提交。' },
  closed: { label: '未认证', tone: 'outline', note: '提交营业执照与法人证件后才能开店经营。' },
}

const AUTH_FALLBACK = {
  label: '未认证',
  tone: 'outline' as const,
  note: '提交营业执照与法人证件后才能开店经营。',
}

const activeTab = ref<TabValue>('info')
const loading = ref(true)
const error = ref('')

const shop = ref<ShopInfo>({
  shopName: '',
  shopType: '',
  status: '',
  openTime: '',
  phone: '',
  email: '',
  address: '',
  description: '',
  logo: '',
})
const auth = ref<ShopAuthInfo>({
  status: '',
  authType: '',
  authTime: '',
  businessLicense: '',
  idCardFront: '',
  idCardBack: '',
})
const payPasswordSet = ref(false)

async function loadAll() {
  loading.value = true
  error.value = ''
  try {
    const [info, authInfo, security] = await Promise.all([getShopInfo(), getAuthInfo(), getSecurityInfo()])
    shop.value = { ...shop.value, ...info }
    auth.value = { ...auth.value, ...authInfo }
    payPasswordSet.value = Boolean(security?.payPasswordSet)
  } catch (e) {
    error.value = e instanceof Error ? e.message : '店铺信息没有加载出来'
  } finally {
    loading.value = false
  }
}

onMounted(loadAll)

const shopState = computed(() => SHOP_STATE[shop.value.status] ?? { label: '状态未知', tone: 'outline' as const })
const authState = computed(() => AUTH_STATE[auth.value.status] ?? AUTH_FALLBACK)

const infoFacts = computed<SpecEntry[]>(() => [
  { key: '店铺名称', value: shop.value.shopName || '未填写' },
  { key: '店铺类型', value: SHOP_TYPE_LABEL[shop.value.shopType] ?? (shop.value.shopType || '未选择') },
  { key: '开店时间', value: shop.value.openTime ? formatDate(shop.value.openTime) : null },
  { key: '联系电话', value: shop.value.phone || '未填写' },
  { key: '联系邮箱', value: shop.value.email || '未填写' },
  { key: '店铺地址', value: shop.value.address || '未填写' },
  { key: '店铺简介', value: shop.value.description || '未填写' },
])

/** 已提交的资质：把后端三个字段名收敛成同一套 key，模板里就不用来回判断。 */
const submittedMaterials = computed(() =>
  MATERIALS.map((item) => {
    const url =
      item.key === 'businessLicense'
        ? auth.value.businessLicense
        : item.key === 'legalIdFront'
          ? auth.value.idCardFront
          : auth.value.idCardBack
    return { ...item, url: url || '', pdf: /\.pdf$/i.test(url || '') }
  }),
)

function isPdf(url: string): boolean {
  return /\.pdf$/i.test(url)
}

function openFile(url: string) {
  window.open(resolveImageUrl(url), '_blank', 'noopener')
}

/* --- 资料编辑 ------------------------------------------------------------ */

const editOpen = ref(false)
const editSaving = ref(false)
const editError = ref('')
const editForm = ref({ shopName: '', shopType: '', address: '', description: '' })

function openEdit() {
  editForm.value = {
    shopName: shop.value.shopName,
    shopType: shop.value.shopType || 'personal',
    address: shop.value.address,
    description: shop.value.description,
  }
  editError.value = ''
  editOpen.value = true
}

async function submitEdit() {
  const form = editForm.value
  if (editSaving.value) return
  if (form.shopName.trim().length < 2) {
    editError.value = '店铺名称至少 2 个字'
    return
  }
  if (!form.address.trim()) {
    editError.value = '请填写店铺地址'
    return
  }
  editError.value = ''
  editSaving.value = true
  try {
    await updateShopInfo({
      shopName: form.shopName.trim(),
      shopType: form.shopType,
      address: form.address.trim(),
      description: form.description.trim(),
    })
    ElMessage.success('店铺资料已保存')
    editOpen.value = false
    const info = await getShopInfo()
    shop.value = { ...shop.value, ...info }
  } catch {
    // 拦截器已经说明了失败原因
  } finally {
    editSaving.value = false
  }
}

/* --- 店铺 logo ----------------------------------------------------------- */

const logoUploading = ref(false)
const logoInput = ref<HTMLInputElement | null>(null)

function pickLogo() {
  if (logoUploading.value) return
  logoInput.value?.click()
}

async function onLogoChange(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  input.value = ''
  if (!file) return
  if (!file.type.startsWith('image/')) {
    ElMessage.error('店铺 logo 只能是图片')
    return
  }
  if (file.size > MAX_FILE_MB * 1024 * 1024) {
    ElMessage.error(`图片不能超过 ${MAX_FILE_MB}MB`)
    return
  }
  logoUploading.value = true
  try {
    const uploaded = await uploadShopLogo(file)
    shop.value.logo = uploaded.url
    ElMessage.success('店铺 logo 已更新')
  } catch (e) {
    ElMessage.error(e instanceof Error ? e.message : '上传失败')
  } finally {
    logoUploading.value = false
  }
}

/* --- 资质材料 ------------------------------------------------------------ */

const materialFiles = ref<Record<MaterialKey, string>>({
  businessLicense: '',
  legalIdFront: '',
  legalIdBack: '',
})
const materialUploading = ref<MaterialKey | null>(null)
const materialInput = ref<HTMLInputElement | null>(null)
const materialTarget = ref<MaterialKey>('businessLicense')
const authFormOpen = ref(false)
const authSubmitting = ref(false)

function pickMaterial(key: MaterialKey) {
  if (materialUploading.value) return
  materialTarget.value = key
  materialInput.value?.click()
}

async function onMaterialChange(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  const key = materialTarget.value
  input.value = ''
  if (!file) return
  const pdf = file.type === 'application/pdf' || /\.pdf$/i.test(file.name)
  if (!pdf && !file.type.startsWith('image/')) {
    ElMessage.error('资质材料支持 PNG / JPG / PDF')
    return
  }
  if (file.size > MAX_FILE_MB * 1024 * 1024) {
    ElMessage.error(`单个文件不能超过 ${MAX_FILE_MB}MB`)
    return
  }
  materialUploading.value = key
  try {
    const uploaded = await uploadAuthMaterial(file)
    materialFiles.value[key] = uploaded.url
    ElMessage.success('文件已上传')
  } catch (e) {
    ElMessage.error(e instanceof Error ? e.message : '上传失败')
  } finally {
    materialUploading.value = null
  }
}

function openAuthForm() {
  materialFiles.value = {
    businessLicense: auth.value.businessLicense || '',
    legalIdFront: auth.value.idCardFront || '',
    legalIdBack: auth.value.idCardBack || '',
  }
  authFormOpen.value = true
}

const missingMaterials = computed(() =>
  MATERIALS.filter((item) => !materialFiles.value[item.key]).map((item) => item.label),
)

async function submitAuth() {
  if (authSubmitting.value) return
  if (missingMaterials.value.length > 0) {
    ElMessage.warning(`还缺${missingMaterials.value.join('、')}`)
    return
  }
  authSubmitting.value = true
  try {
    await submitAuthInfo({
      businessLicense: materialFiles.value.businessLicense,
      legalIdFront: materialFiles.value.legalIdFront,
      legalIdBack: materialFiles.value.legalIdBack,
    })
    ElMessage.success('认证材料已提交，等待平台审核')
    authFormOpen.value = false
    await loadAll()
  } catch {
    // 拦截器已经说明了失败原因
  } finally {
    authSubmitting.value = false
  }
}

/* --- 安全设置 ------------------------------------------------------------ */

const passwordOpen = ref(false)
const passwordSaving = ref(false)
const passwordError = ref('')
const passwordForm = ref({ oldPassword: '', newPassword: '', confirmPassword: '' })

const payOpen = ref(false)
const paySaving = ref(false)
const payError = ref('')
const payForm = ref({ oldPayPassword: '', payPassword: '', confirmPassword: '' })

function openPassword() {
  passwordForm.value = { oldPassword: '', newPassword: '', confirmPassword: '' }
  passwordError.value = ''
  passwordOpen.value = true
}

async function submitPassword() {
  const form = passwordForm.value
  if (passwordSaving.value) return
  if (!form.oldPassword) {
    passwordError.value = '请输入当前密码'
    return
  }
  if (form.newPassword.length < 6) {
    passwordError.value = '新密码至少 6 位'
    return
  }
  if (form.newPassword !== form.confirmPassword) {
    passwordError.value = '两次输入的新密码不一致'
    return
  }
  passwordError.value = ''
  passwordSaving.value = true
  try {
    await changePassword(form)
    ElMessage.success('登录密码已修改')
    passwordOpen.value = false
  } catch {
    passwordError.value = '修改失败，请确认当前密码是否正确'
  } finally {
    passwordSaving.value = false
  }
}

function openPayPassword() {
  payForm.value = { oldPayPassword: '', payPassword: '', confirmPassword: '' }
  payError.value = ''
  payOpen.value = true
}

async function submitPayPassword() {
  const form = payForm.value
  if (paySaving.value) return
  if (payPasswordSet.value && !form.oldPayPassword) {
    payError.value = '请输入当前支付密码'
    return
  }
  if (!/^\d{6}$/.test(form.payPassword)) {
    payError.value = '支付密码必须是 6 位数字'
    return
  }
  if (form.payPassword !== form.confirmPassword) {
    payError.value = '两次输入的支付密码不一致'
    return
  }
  payError.value = ''
  paySaving.value = true
  try {
    if (payPasswordSet.value) {
      await changePayPassword({
        oldPayPassword: form.oldPayPassword,
        newPayPassword: form.payPassword,
        confirmPassword: form.confirmPassword,
      })
    } else {
      await setPayPassword({ payPassword: form.payPassword, confirmPassword: form.confirmPassword })
    }
    payOpen.value = false
    // 以服务端返回的设置状态为准，而不是假定已经存下来了。
    const security = await getSecurityInfo()
    payPasswordSet.value = Boolean(security?.payPasswordSet)
    if (payPasswordSet.value) ElMessage.success('支付密码已保存')
    else ElMessage.warning('服务端还没有记录支付密码，稍后再确认一次')
  } catch {
    // 拦截器已经说明了失败原因
  } finally {
    paySaving.value = false
  }
}

async function handleLogout() {
  try {
    await ElMessageBox.confirm('确定退出商家后台？', '退出登录', {
      confirmButtonText: '退出登录',
      cancelButtonText: '取消',
      type: 'warning',
    })
  } catch {
    return
  }
  userStore.logout()
}
</script>

<template>
  <div class="page">
    <SectionHead
      title="店铺管理"
      :note="shop.shopName ? `${shop.shopName} · ${shopState.label}` : '店铺资料、经营资质与账户安全'"
      size="lg"
    >
      <template #action>
        <div class="head-state">
          <StatePill :label="shopState.label" :tone="shopState.tone" />
          <StatePill :label="authState.label" :tone="authState.tone" />
        </div>
      </template>
    </SectionHead>

    <div class="tabs" role="tablist" aria-label="店铺管理分类">
      <button
        v-for="tab in TABS"
        :key="tab.value"
        class="tabs__item"
        :class="{ 'is-active': activeTab === tab.value }"
        type="button"
        role="tab"
        :aria-selected="activeTab === tab.value"
        @click="activeTab = tab.value"
      >
        {{ tab.label }}
      </button>
    </div>

    <!-- 加载 -->
    <div v-if="loading" class="stack" aria-busy="true">
      <div class="plate ghost-card skeleton" />
      <div class="plate ghost-card skeleton" />
    </div>

    <!-- 错误 -->
    <EmptyState v-else-if="error" title="店铺信息加载失败" :note="error">
      <button class="btn" type="button" @click="loadAll">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
    </EmptyState>

    <template v-else>
      <!-- 店铺资料 -->
      <div v-if="activeTab === 'info'" class="grid">
        <section class="plate">
          <header class="plate__head">
            <h2 class="plate__title">店铺资料</h2>
            <button class="btn" type="button" @click="openEdit">
              <AppIcon name="edit" size="14" />
              编辑资料
            </button>
          </header>
          <div class="plate__body">
            <SpecList :entries="infoFacts" />
            <p class="hint">联系电话与邮箱属于账号信息，随账号一起在个人中心修改。</p>
          </div>
        </section>

        <section class="plate">
          <header class="plate__head">
            <h2 class="plate__title">店铺 logo</h2>
          </header>
          <div class="plate__body logo">
            <div class="logo__frame">
              <ImageFrame :src="shop.logo || null" alt="店铺 logo" ratio="1 / 1" />
            </div>
            <div class="logo__side">
              <p class="hint">买家在店铺页看到的第一眼，建议使用清晰的正方形图片。</p>
              <button class="btn" type="button" :disabled="logoUploading" @click="pickLogo">
                <AppIcon name="upload" size="14" />
                {{ logoUploading ? '上传中…' : shop.logo ? '更换 logo' : '上传 logo' }}
              </button>
              <span class="hint">PNG / JPG，不超过 {{ MAX_FILE_MB }}MB</span>
            </div>
          </div>
        </section>
      </div>

      <!-- 店铺认证 -->
      <div v-else-if="activeTab === 'auth'" class="stack">
        <section class="plate">
          <header class="plate__head">
            <h2 class="plate__title">认证状态</h2>
            <StatePill :label="authState.label" :tone="authState.tone" />
          </header>
          <div class="plate__body">
            <SpecList
              :entries="[
                { key: '认证类型', value: SHOP_TYPE_LABEL[auth.authType] ?? auth.authType ?? '未提交' },
                { key: '认证时间', value: auth.authTime ? formatDate(auth.authTime) : null },
              ]"
              :columns="2"
            />
            <p class="hint">{{ authState.note }}</p>
          </div>
        </section>

        <section class="plate">
          <header class="plate__head">
            <h2 class="plate__title">资质材料</h2>
            <button class="btn" type="button" :disabled="auth.status === 'pending'" @click="openAuthForm">
              <AppIcon name="upload" size="14" />
              {{
                auth.status === 'pending'
                  ? '审核中不可修改'
                  : auth.status === 'approved'
                    ? '更新资质'
                    : '提交认证'
              }}
            </button>
          </header>
          <div class="plate__body">
            <ul class="materials">
              <li v-for="item in submittedMaterials" :key="item.key" class="material">
                <span class="material__label">{{ item.label }}</span>
                <template v-if="item.url">
                  <div v-if="!item.pdf" class="material__thumb">
                    <ImageFrame :src="item.url" :alt="item.label" ratio="4 / 3" />
                  </div>
                  <button class="link" type="button" @click="openFile(item.url)">
                    <AppIcon name="view" size="13" />
                    {{ item.pdf ? '查看 PDF' : '查看原图' }}
                  </button>
                </template>
                <span v-else class="material__empty">未提交</span>
              </li>
            </ul>
          </div>
        </section>
      </div>

      <!-- 安全设置 -->
      <div v-else class="stack">
        <section class="plate">
          <header class="plate__head">
            <h2 class="plate__title">登录与支付</h2>
          </header>
          <ul class="rows">
            <li class="row">
              <div class="row__text">
                <p class="row__label">登录密码</p>
                <p class="row__note">用于登录商家后台</p>
              </div>
              <button class="btn" type="button" @click="openPassword">修改登录密码</button>
            </li>
            <li class="row">
              <div class="row__text">
                <p class="row__label">支付密码</p>
                <p class="row__note">用于退款、提现等资金操作</p>
              </div>
              <div class="row__side">
                <StatePill
                  :label="payPasswordSet ? '已设置' : '未设置'"
                  :tone="payPasswordSet ? 'teal' : 'outline'"
                />
                <button class="btn" type="button" @click="openPayPassword">
                  {{ payPasswordSet ? '修改支付密码' : '设置支付密码' }}
                </button>
              </div>
            </li>
          </ul>
        </section>

        <section class="plate">
          <header class="plate__head">
            <h2 class="plate__title">账号绑定</h2>
          </header>
          <ul class="rows">
            <li class="row">
              <div class="row__text">
                <p class="row__label">联系电话</p>
                <p class="row__note">{{ shop.phone || '未填写' }}</p>
              </div>
            </li>
            <li class="row">
              <div class="row__text">
                <p class="row__label">联系邮箱</p>
                <p class="row__note">{{ shop.email || '未填写' }}</p>
              </div>
            </li>
          </ul>
          <div class="plate__body">
            <RouterLink class="btn" to="/merchant-dashboard/profile">去个人中心修改</RouterLink>
          </div>
        </section>

        <section class="plate">
          <header class="plate__head">
            <h2 class="plate__title">会话</h2>
          </header>
          <div class="plate__body row">
            <div class="row__text">
              <p class="row__label">退出当前账号</p>
              <p class="row__note">在公用电脑上用完请及时退出</p>
            </div>
            <button class="btn" type="button" @click="handleLogout">
              <AppIcon name="logout" size="14" />
              退出登录
            </button>
          </div>
        </section>
      </div>
    </template>

    <!-- 隐藏的上传入口：logo 与资质各一个 -->
    <input
      ref="logoInput"
      class="sr-only"
      type="file"
      accept="image/jpeg,image/png,image/webp"
      @change="onLogoChange"
    />
    <input
      ref="materialInput"
      class="sr-only"
      type="file"
      :accept="MATERIAL_ACCEPT"
      @change="onMaterialChange"
    />

    <!-- 编辑资料 -->
    <el-dialog v-model="editOpen" title="编辑店铺资料" width="520px">
      <div class="form">
        <label class="field">
          <span class="field__label">店铺名称</span>
          <el-input v-model="editForm.shopName" maxlength="50" placeholder="例如：光年影像器材" />
        </label>
        <label class="field">
          <span class="field__label">店铺类型</span>
          <el-select v-model="editForm.shopType" class="field__control">
            <el-option label="个人店铺" value="personal" />
            <el-option label="企业店铺" value="enterprise" />
          </el-select>
        </label>
        <label class="field">
          <span class="field__label">店铺地址</span>
          <el-input v-model="editForm.address" maxlength="200" placeholder="城市 + 门店或仓库地址" />
        </label>
        <label class="field">
          <span class="field__label">店铺简介</span>
          <el-input
            v-model="editForm.description"
            type="textarea"
            :rows="4"
            maxlength="500"
            show-word-limit
            placeholder="主营器材与售后说明"
          />
        </label>
        <p v-if="editError" class="field__error">{{ editError }}</p>
      </div>
      <template #footer>
        <div class="dialog-foot">
          <button class="btn btn--ghost" type="button" @click="editOpen = false">取消</button>
          <button class="btn btn--solid" type="button" :disabled="editSaving" @click="submitEdit">
            {{ editSaving ? '保存中…' : '保存' }}
          </button>
        </div>
      </template>
    </el-dialog>

    <!-- 提交认证 -->
    <el-dialog v-model="authFormOpen" title="提交认证材料" width="560px">
      <div class="form">
        <ul class="uploads">
          <li v-for="item in MATERIALS" :key="item.key" class="upload">
            <div class="upload__text">
              <p class="upload__label">{{ item.label }}</p>
              <p class="upload__note">{{ item.note }}</p>
            </div>
            <div class="upload__side">
              <div v-if="materialFiles[item.key] && !isPdf(materialFiles[item.key])" class="upload__thumb">
                <ImageFrame :src="materialFiles[item.key]" :alt="item.label" ratio="4 / 3" />
              </div>
              <button
                v-else-if="materialFiles[item.key]"
                class="file"
                type="button"
                @click="openFile(materialFiles[item.key])"
              >
                <AppIcon name="document" size="16" />
                查看 PDF
              </button>
              <button
                class="btn"
                type="button"
                :disabled="materialUploading !== null"
                @click="pickMaterial(item.key)"
              >
                <AppIcon name="upload" size="14" />
                {{
                  materialUploading === item.key
                    ? '上传中…'
                    : materialFiles[item.key]
                      ? '重新上传'
                      : '选择文件'
                }}
              </button>
            </div>
          </li>
        </ul>
        <p class="hint">
          支持 PNG / JPG / PDF，单个文件不超过 {{ MAX_FILE_MB }}MB。提交后进入平台审核。
        </p>
      </div>
      <template #footer>
        <div class="dialog-foot">
          <button class="btn btn--ghost" type="button" @click="authFormOpen = false">取消</button>
          <button class="btn btn--solid" type="button" :disabled="authSubmitting" @click="submitAuth">
            {{ authSubmitting ? '提交中…' : '提交审核' }}
          </button>
        </div>
      </template>
    </el-dialog>

    <!-- 修改登录密码 -->
    <el-dialog v-model="passwordOpen" title="修改登录密码" width="420px">
      <div class="form">
        <label class="field">
          <span class="field__label">当前密码</span>
          <el-input v-model="passwordForm.oldPassword" type="password" show-password />
        </label>
        <label class="field">
          <span class="field__label">新密码</span>
          <el-input v-model="passwordForm.newPassword" type="password" show-password placeholder="至少 6 位" />
        </label>
        <label class="field">
          <span class="field__label">确认新密码</span>
          <el-input v-model="passwordForm.confirmPassword" type="password" show-password />
        </label>
        <p v-if="passwordError" class="field__error">{{ passwordError }}</p>
      </div>
      <template #footer>
        <div class="dialog-foot">
          <button class="btn btn--ghost" type="button" @click="passwordOpen = false">取消</button>
          <button class="btn btn--solid" type="button" :disabled="passwordSaving" @click="submitPassword">
            {{ passwordSaving ? '提交中…' : '确认修改' }}
          </button>
        </div>
      </template>
    </el-dialog>

    <!-- 支付密码 -->
    <el-dialog v-model="payOpen" :title="payPasswordSet ? '修改支付密码' : '设置支付密码'" width="420px">
      <div class="form">
        <label v-if="payPasswordSet" class="field">
          <span class="field__label">当前支付密码</span>
          <el-input v-model="payForm.oldPayPassword" type="password" maxlength="6" show-password />
        </label>
        <label class="field">
          <span class="field__label">{{ payPasswordSet ? '新支付密码' : '支付密码' }}</span>
          <el-input v-model="payForm.payPassword" type="password" maxlength="6" show-password placeholder="6 位数字" />
        </label>
        <label class="field">
          <span class="field__label">确认支付密码</span>
          <el-input v-model="payForm.confirmPassword" type="password" maxlength="6" show-password />
        </label>
        <p v-if="payError" class="field__error">{{ payError }}</p>
      </div>
      <template #footer>
        <div class="dialog-foot">
          <button class="btn btn--ghost" type="button" @click="payOpen = false">取消</button>
          <button class="btn btn--solid" type="button" :disabled="paySaving" @click="submitPayPassword">
            {{ paySaving ? '提交中…' : '保存' }}
          </button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.page {
  padding-bottom: var(--space-8);
}

.head-state {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.tabs {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-1);
  padding-bottom: var(--space-3);
  margin-bottom: var(--gap-surface);
  border-bottom: var(--hairline);
}

.tabs__item {
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

.grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 340px;
  gap: var(--gap-surface);
  align-items: start;
}

.stack {
  display: flex;
  flex-direction: column;
  gap: var(--gap-surface);
}

.plate__title {
  font-size: var(--text-base);
}

.hint {
  margin-top: var(--space-3);
  font-size: var(--text-xs);
  color: var(--ink-3);
  line-height: 1.65;
}

/* --- logo ---------------------------------------------------------------- */

.logo {
  display: flex;
  align-items: flex-start;
  gap: var(--space-4);
}

.logo__frame {
  flex-shrink: 0;
  width: 112px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.logo__side {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: var(--space-2);
  min-width: 0;
}

.logo__side .hint {
  margin-top: 0;
}

/* --- 资质材料 ------------------------------------------------------------ */

.materials {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: var(--space-4);
  margin: 0;
  padding: 0;
  list-style: none;
}

.material {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-3);
  border: var(--edge);
  border-radius: var(--radius-sm);
}

.material__label {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-0);
}

.material__thumb {
  width: 100%;
  border: var(--hairline);
  border-radius: var(--radius-xs);
  overflow: hidden;
}

.material__empty {
  font-size: var(--text-xs);
  color: var(--ink-4);
}

/* --- 设置行 -------------------------------------------------------------- */

.rows {
  margin: 0;
  padding: 0;
  list-style: none;
}

.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  padding: var(--space-4) var(--pad-surface);
  border-bottom: var(--hairline);
}

.rows .row:last-child,
.plate__body.row {
  border-bottom: none;
}

.row__text {
  min-width: 0;
}

.row__label {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-0);
}

.row__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.row__side {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

/* --- 弹窗表单 ------------------------------------------------------------ */

.form {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field__label {
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.field__control {
  width: 100%;
}

.field__error {
  font-size: var(--text-xs);
  color: var(--signal-vermilion-deep);
}

.uploads {
  display: flex;
  flex-direction: column;
  margin: 0;
  padding: 0;
  list-style: none;
}

.upload {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  padding: var(--space-3) 0;
  border-bottom: var(--hairline);
}

.upload:last-child {
  border-bottom: none;
}

.upload__label {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--ink-0);
}

.upload__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.upload__side {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  flex-shrink: 0;
}

.upload__thumb {
  width: 72px;
  border: var(--edge);
  border-radius: var(--radius-xs);
  overflow: hidden;
}

.file {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 10px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-1);
  font-size: var(--text-xs);
  color: var(--ink-2);
  cursor: pointer;
}

.dialog-foot {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}

/* --- 控件 ---------------------------------------------------------------- */

.ghost-card {
  height: 168px;
}

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: var(--control-h);
  padding-inline: 14px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  color: var(--ink-1);
  font-size: var(--text-sm);
  font-weight: 500;
  text-decoration: none;
  cursor: pointer;
  transition:
    border-color var(--dur-state) ease,
    background-color var(--dur-state) ease;
}

.btn:hover:not(:disabled) {
  border-color: var(--ink-3);
}

.btn--solid {
  border-color: var(--ink-0);
  background: var(--ink-0);
  color: var(--on-ink);
  font-weight: 600;
}

.btn--solid:hover:not(:disabled) {
  background: var(--ink-1);
  border-color: var(--ink-1);
}

.btn--ghost {
  border-color: transparent;
  color: var(--ink-3);
}

.btn:disabled {
  border-color: var(--line-2);
  background: var(--paper-2);
  color: var(--ink-4);
  cursor: not-allowed;
}

.link {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 0;
  border: none;
  background: transparent;
  font-size: var(--text-xs);
  color: var(--ink-2);
  cursor: pointer;
}

.link:hover {
  color: var(--signal-amber-deep);
  text-decoration: underline;
}

@media (max-width: 1080px) {
  .grid {
    grid-template-columns: minmax(0, 1fr);
  }
}

@media (max-width: 640px) {
  .logo {
    flex-direction: column;
  }
  .row {
    flex-direction: column;
    align-items: flex-start;
    gap: var(--space-3);
  }
  .upload {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
