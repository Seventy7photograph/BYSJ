<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import axios from '@/axios'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import SpecList, { type SpecEntry } from '@/components/ui/SpecList.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { updateShopInfo } from '@/api/merchant/shop'
import { ACCOUNT_STATUS, labelOf, type Tone } from '@/constants/domain'
import { formatDate } from '@/utils/format'

/**
 * 商家个人中心。
 *
 * 原页面的表单是一个不会生效的壳：它把昵称、电话、邮箱、店铺名称、店铺地址、
 * 店铺描述一起 PUT 到 /user/profile，而后端只接收昵称/电话/邮箱（店铺字段在
 * /merchant/shop/info）。也就是说改了店铺名点保存，界面提示成功，数据库没动。
 * 现在按归属拆成两块：账号资料走 /user/profile，店铺资料走 /merchant/shop/info；
 * 头像走 POST /user/avatar（只有它会写 user.avatar_url）。
 *
 * shop_status 的取值以后端为准：0 关闭 / 1 正常 / 2 审核中（user 表注释）。
 */

const SHOP_STATE: Record<number, { label: string; tone: Tone }> = {
  0: { label: '已关闭', tone: 'outline' },
  1: { label: '正常营业', tone: 'teal' },
  2: { label: '审核中', tone: 'amber' },
}

const SHOP_TYPE_LABEL: Record<string, string> = {
  personal: '个人店铺',
  enterprise: '企业店铺',
}

const MAX_AVATAR_MB = 5

interface ProfileData {
  userId?: number
  username?: string
  nickname?: string
  phone?: string
  email?: string
  avatarUrl?: string
  shopName?: string
  businessType?: string
  shopStatus?: number
  shopAddress?: string
  shopDescription?: string
  shopLogoUrl?: string
  createTime?: string
  status?: number
  [key: string]: unknown
}

const loading = ref(true)
const error = ref('')
const profile = ref<ProfileData>({})

async function loadProfile() {
  loading.value = true
  error.value = ''
  try {
    const res: any = await axios.get('/user/profile')
    profile.value = (res?.data ?? res) ?? {}
  } catch (e) {
    profile.value = {}
    error.value = e instanceof Error ? e.message : '账号资料没有加载出来'
  } finally {
    loading.value = false
  }
}

onMounted(loadProfile)

const shopState = computed(
  () => SHOP_STATE[Number(profile.value.shopStatus ?? -1)] ?? { label: '未开店', tone: 'outline' as Tone },
)
const accountState = computed(() => labelOf(ACCOUNT_STATUS, Number(profile.value.status), '待审核'))

const accountFacts = computed<SpecEntry[]>(() => [
  { key: '登录账号', value: profile.value.username || '—', mono: true },
  { key: '昵称', value: profile.value.nickname || '未设置' },
  { key: '手机号', value: profile.value.phone || '未填写' },
  { key: '邮箱', value: profile.value.email || '未填写' },
  { key: '注册时间', value: profile.value.createTime ? formatDate(profile.value.createTime) : '—' },
])

const shopFacts = computed<SpecEntry[]>(() => [
  { key: '店铺名称', value: profile.value.shopName || '未填写' },
  { key: '店铺类型', value: SHOP_TYPE_LABEL[String(profile.value.businessType ?? '')] ?? '未选择' },
  { key: '店铺地址', value: profile.value.shopAddress || '未填写' },
  { key: '店铺简介', value: profile.value.shopDescription || '未填写' },
])

/* --- 头像 ---------------------------------------------------------------- */

const avatarUploading = ref(false)
const avatarInput = ref<HTMLInputElement | null>(null)

function pickAvatar() {
  if (avatarUploading.value) return
  avatarInput.value?.click()
}

async function onAvatarChange(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  input.value = ''
  if (!file) return
  if (!file.type.startsWith('image/')) {
    ElMessage.error('头像只能是图片')
    return
  }
  if (file.size > MAX_AVATAR_MB * 1024 * 1024) {
    ElMessage.error(`头像不能超过 ${MAX_AVATAR_MB}MB`)
    return
  }
  avatarUploading.value = true
  try {
    const form = new FormData()
    form.append('file', file)
    const res: any = await axios.post('/user/avatar', form, {
      headers: { 'Content-Type': 'multipart/form-data' },
      timeout: 60000,
    })
    const url = res?.data ?? res
    profile.value.avatarUrl = typeof url === 'string' ? url : profile.value.avatarUrl
    ElMessage.success('头像已更新')
  } catch (e) {
    ElMessage.error(e instanceof Error ? e.message : '头像上传失败')
  } finally {
    avatarUploading.value = false
  }
}

/* --- 账号资料 ------------------------------------------------------------ */

const accountOpen = ref(false)
const accountSaving = ref(false)
const accountError = ref('')
const accountForm = ref({ nickname: '', phone: '', email: '' })

function openAccount() {
  accountForm.value = {
    nickname: String(profile.value.nickname ?? ''),
    phone: String(profile.value.phone ?? ''),
    email: String(profile.value.email ?? ''),
  }
  accountError.value = ''
  accountOpen.value = true
}

async function submitAccount() {
  const form = accountForm.value
  if (accountSaving.value) return
  if (form.nickname.trim().length < 2) {
    accountError.value = '昵称至少 2 个字'
    return
  }
  if (form.phone && !/^1[3-9]\d{9}$/.test(form.phone.trim())) {
    accountError.value = '请输入 11 位手机号'
    return
  }
  if (form.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email.trim())) {
    accountError.value = '请输入正确的邮箱地址'
    return
  }
  accountError.value = ''
  accountSaving.value = true
  try {
    await axios.put('/user/profile', {
      nickname: form.nickname.trim(),
      phone: form.phone.trim(),
      email: form.email.trim(),
    })
    ElMessage.success('账号资料已保存')
    accountOpen.value = false
    await loadProfile()
  } catch {
    // 拦截器已经说明了失败原因
  } finally {
    accountSaving.value = false
  }
}

/* --- 店铺资料 ------------------------------------------------------------ */

const shopOpen = ref(false)
const shopSaving = ref(false)
const shopError = ref('')
const shopForm = ref({ shopName: '', shopType: '', address: '', description: '' })

function openShop() {
  shopForm.value = {
    shopName: String(profile.value.shopName ?? ''),
    shopType: String(profile.value.businessType ?? '') || 'personal',
    address: String(profile.value.shopAddress ?? ''),
    description: String(profile.value.shopDescription ?? ''),
  }
  shopError.value = ''
  shopOpen.value = true
}

async function submitShop() {
  const form = shopForm.value
  if (shopSaving.value) return
  if (form.shopName.trim().length < 2) {
    shopError.value = '店铺名称至少 2 个字'
    return
  }
  if (!form.address.trim()) {
    shopError.value = '请填写店铺地址'
    return
  }
  shopError.value = ''
  shopSaving.value = true
  try {
    await updateShopInfo({
      shopName: form.shopName.trim(),
      shopType: form.shopType,
      address: form.address.trim(),
      description: form.description.trim(),
    })
    ElMessage.success('店铺资料已保存')
    shopOpen.value = false
    await loadProfile()
  } catch {
    // 拦截器已经说明了失败原因
  } finally {
    shopSaving.value = false
  }
}

/* --- 登录密码 ------------------------------------------------------------ */

const passwordOpen = ref(false)
const passwordSaving = ref(false)
const passwordError = ref('')
const passwordForm = ref({ oldPassword: '', newPassword: '', confirmPassword: '' })

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
    await axios.put('/user/password', {
      oldPassword: form.oldPassword,
      newPassword: form.newPassword,
    })
    ElMessage.success('登录密码已修改')
    passwordOpen.value = false
  } catch {
    passwordError.value = '修改失败，请确认当前密码是否正确'
  } finally {
    passwordSaving.value = false
  }
}
</script>

<template>
  <div class="page">
    <SectionHead
      title="个人中心"
      :note="profile.username ? `账号 ${profile.username}` : '账号资料与所属店铺'"
      size="lg"
    >
      <template #action>
        <RouterLink class="btn" to="/merchant-dashboard/shop-management">去店铺管理</RouterLink>
      </template>
    </SectionHead>

    <!-- 加载 -->
    <div v-if="loading" class="grid" aria-busy="true">
      <div class="plate ghost-card skeleton" />
      <div class="plate ghost-card skeleton" />
    </div>

    <!-- 错误 -->
    <EmptyState v-else-if="error" title="账号资料加载失败" :note="error">
      <button class="btn" type="button" @click="loadProfile">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
    </EmptyState>

    <div v-else class="grid">
      <section class="plate">
        <header class="plate__head">
          <h2 class="plate__title">账号资料</h2>
          <div class="head-actions">
            <StatePill :label="accountState.label" :tone="accountState.tone" />
            <button class="btn" type="button" @click="openAccount">
              <AppIcon name="edit" size="14" />
              编辑资料
            </button>
          </div>
        </header>

        <div class="plate__body">
          <div class="identity">
            <button class="identity__avatar" type="button" :disabled="avatarUploading" @click="pickAvatar">
              <ImageFrame :src="profile.avatarUrl || null" alt="账号头像" ratio="1 / 1" />
              <span class="identity__overlay">
                <AppIcon name="upload" size="16" />
                {{ avatarUploading ? '上传中…' : '更换头像' }}
              </span>
            </button>
            <div class="identity__text">
              <p class="identity__name">{{ profile.nickname || profile.shopName || '未设置昵称' }}</p>
              <p class="identity__note">头像用于后台抬头与店铺会话展示</p>
            </div>
          </div>

          <SpecList :entries="accountFacts" :columns="2" />
        </div>
      </section>

      <section class="plate">
        <header class="plate__head">
          <h2 class="plate__title">店铺资料</h2>
          <div class="head-actions">
            <StatePill :label="shopState.label" :tone="shopState.tone" />
            <button class="btn" type="button" @click="openShop">
              <AppIcon name="edit" size="14" />
              编辑店铺
            </button>
          </div>
        </header>

        <div class="plate__body">
          <SpecList :entries="shopFacts" />
          <div class="password-row">
            <div>
              <p class="row__label">登录密码</p>
              <p class="row__note">修改后需要重新登录一次</p>
            </div>
            <button class="btn" type="button" @click="openPassword">修改登录密码</button>
          </div>
        </div>
      </section>
    </div>

    <input
      ref="avatarInput"
      class="sr-only"
      type="file"
      accept="image/jpeg,image/png,image/webp"
      @change="onAvatarChange"
    />

    <!-- 账号资料 -->
    <el-dialog v-model="accountOpen" title="编辑账号资料" width="460px">
      <div class="form">
        <label class="field">
          <span class="field__label">昵称</span>
          <el-input v-model="accountForm.nickname" maxlength="20" show-word-limit />
        </label>
        <label class="field">
          <span class="field__label">手机号</span>
          <el-input v-model="accountForm.phone" maxlength="11" placeholder="11 位手机号" />
        </label>
        <label class="field">
          <span class="field__label">邮箱</span>
          <el-input v-model="accountForm.email" placeholder="用于接收平台通知" />
        </label>
        <p v-if="accountError" class="field__error">{{ accountError }}</p>
      </div>
      <template #footer>
        <div class="dialog-foot">
          <button class="btn btn--ghost" type="button" @click="accountOpen = false">取消</button>
          <button class="btn btn--solid" type="button" :disabled="accountSaving" @click="submitAccount">
            {{ accountSaving ? '保存中…' : '保存' }}
          </button>
        </div>
      </template>
    </el-dialog>

    <!-- 店铺资料 -->
    <el-dialog v-model="shopOpen" title="编辑店铺资料" width="520px">
      <div class="form">
        <label class="field">
          <span class="field__label">店铺名称</span>
          <el-input v-model="shopForm.shopName" maxlength="50" />
        </label>
        <label class="field">
          <span class="field__label">店铺类型</span>
          <el-select v-model="shopForm.shopType" class="field__control">
            <el-option label="个人店铺" value="personal" />
            <el-option label="企业店铺" value="enterprise" />
          </el-select>
        </label>
        <label class="field">
          <span class="field__label">店铺地址</span>
          <el-input v-model="shopForm.address" maxlength="200" />
        </label>
        <label class="field">
          <span class="field__label">店铺简介</span>
          <el-input v-model="shopForm.description" type="textarea" :rows="4" maxlength="500" show-word-limit />
        </label>
        <p v-if="shopError" class="field__error">{{ shopError }}</p>
      </div>
      <template #footer>
        <div class="dialog-foot">
          <button class="btn btn--ghost" type="button" @click="shopOpen = false">取消</button>
          <button class="btn btn--solid" type="button" :disabled="shopSaving" @click="submitShop">
            {{ shopSaving ? '保存中…' : '保存' }}
          </button>
        </div>
      </template>
    </el-dialog>

    <!-- 登录密码 -->
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
  </div>
</template>

<style scoped>
.page {
  padding-bottom: var(--space-8);
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(360px, 1fr));
  gap: var(--gap-surface);
  align-items: start;
}

.plate__title {
  font-size: var(--text-base);
}

.head-actions {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

/* --- 身份区 -------------------------------------------------------------- */

.identity {
  display: flex;
  align-items: center;
  gap: var(--space-4);
  padding-bottom: var(--space-4);
  margin-bottom: var(--space-2);
  border-bottom: var(--hairline);
}

.identity__avatar {
  position: relative;
  flex-shrink: 0;
  width: 84px;
  padding: 0;
  border: var(--edge);
  border-radius: var(--radius-pill);
  background: transparent;
  overflow: hidden;
  cursor: pointer;
}

.identity__avatar:disabled {
  cursor: progress;
}

.identity__overlay {
  position: absolute;
  inset: auto 0 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  padding: 4px 0;
  background: rgb(13 17 20 / 72%);
  color: #fff;
  font-size: var(--text-2xs);
  opacity: 0;
  transition: opacity var(--dur-state) ease;
}

.identity__avatar:hover .identity__overlay,
.identity__avatar:focus-visible .identity__overlay {
  opacity: 1;
}

.identity__text {
  min-width: 0;
}

.identity__name {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--ink-0);
}

.identity__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

/* --- 设置行 -------------------------------------------------------------- */

.password-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  margin-top: var(--space-4);
  padding-top: var(--space-4);
  border-top: var(--hairline);
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

/* --- 表单 ---------------------------------------------------------------- */

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

.dialog-foot {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}

/* --- 控件 ---------------------------------------------------------------- */

.ghost-card {
  height: 240px;
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

@media (max-width: 640px) {
  .grid {
    grid-template-columns: minmax(0, 1fr);
  }
  .plate__head {
    flex-wrap: wrap;
  }
  .head-actions {
    width: 100%;
  }
  .password-row {
    flex-direction: column;
    align-items: flex-start;
    gap: var(--space-3);
  }
}
</style>
