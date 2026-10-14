<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import http from '@/axios'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import FileUploader from '@/components/ui/FileUploader.vue'
import { useUserStore } from '@/stores/user'
import { user } from '@/api'
import type { UploadedFile } from '@/api/files'
import { ACCOUNT_STATUS, labelOf, type Tone } from '@/constants/domain'
import { formatDate, formatDateTime, maskPhone, resolveImageUrl } from '@/utils/format'

/**
 * 个人中心。
 *
 * 原页面有几处是坏掉的：
 *   - 头像弹窗用 el-upload 直传 POST /user/avatar，而该接口把文件写死在
 *     UserController 里的绝对路径（还是旧工程目录）上，返回的 /head/xxx
 *     前端根本读不到。现在统一走 <FileUploader>（/files/upload，bizType=avatar）。
 *   - 实名认证走 PUT /user/verify，后端没有这个映射，提交必然失败。这里不再
 *     提供假的认证入口，改为如实展示认证状态。
 *   - 修改密码从不校验旧密码错误以外的结果，成功与否都提示成功。
 *   - 返回按钮 + 居中标题的版式与新版视觉无关，改成标准的页面头部。
 *
 * 接口说明：/user/profile 的读写暂时没有对应的 api 模块（auth.ts 只有登录注册
 * 那几支），所以这一页直接用底层 http 实例调用，路径与 UserController 一致。
 */
const userStore = useUserStore()

interface ProfileForm {
  userId: number | null
  username: string
  nickname: string
  gender: number
  phone: string
  email: string
  avatarUrl: string
  realName: string
  status: number
  createTime: string
}

interface ReviewItem {
  evalId: number
  productId: number
  productName?: string | null
  score?: number | null
  qualityScore?: number | null
  serviceScore?: number | null
  logisticsScore?: number | null
  content?: string | null
  imgUrls?: string | null
  replyContent?: string | null
  replyTime?: string | null
  createTime?: string | null
}

const loading = ref(true)
const error = ref('')
const saving = ref(false)
const savingPassword = ref(false)
const savingAvatar = ref(false)
const profileRef = ref<FormInstance>()
const passwordRef = ref<FormInstance>()

const profile = reactive<ProfileForm>({
  userId: null,
  username: '',
  nickname: '',
  gender: 0,
  phone: '',
  email: '',
  avatarUrl: '',
  realName: '',
  status: 2,
  createTime: '',
})

const password = reactive({ oldPassword: '', newPassword: '', confirmPassword: '' })

/** 头像上传控件是「一次性」的：传完立刻清空，控件始终可以再次使用。 */
const avatarFiles = ref<UploadedFile[]>([])

/** /user/avatar 按原始文件名的后缀判断格式，转交时要把后缀带过去。 */
const AVATAR_EXTENSIONS: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'image/gif': 'gif',
}

const reviews = ref<ReviewItem[]>([])
const reviewsLoading = ref(true)
const reviewsError = ref('')

const displayName = computed(() => profile.nickname || profile.username || '未登录用户')

const initial = computed(() => displayName.value.slice(0, 1).toUpperCase())

/** 账号状态：0 停用 / 1 正常 / 2 未实名（可浏览，不可下单与发布）。 */
const accountState = computed<{ label: string; tone: Tone }>(() => {
  if (Number(profile.status) === 2) return { label: '未实名认证', tone: 'amber' }
  return labelOf(ACCOUNT_STATUS, profile.status)
})

const realNameState = computed(() =>
  Number(profile.status) === 1 ? '已认证' : '未认证（不可下单与发布商品）',
)

const entries = [
  { label: '我的订单', note: '支付、发货、归还与售后', to: '/orders', icon: 'order' as const },
  { label: '我的收藏', note: '收藏的器材与价格对比', to: '/favorites', icon: 'star' as const },
  { label: '收货地址', note: '下单时可直接选用', to: '/address', icon: 'location' as const },
  { label: '消息中心', note: '订单与账号通知', to: '/messages', icon: 'message' as const },
]

const profileRules: FormRules = {
  nickname: [
    { required: true, message: '请填写昵称', trigger: 'blur' },
    { min: 2, max: 20, message: '昵称长度 2 到 20 个字符', trigger: 'blur' },
  ],
  phone: [{ pattern: /^1[3-9]\d{9}$/, message: '手机号码格式不正确', trigger: 'blur' }],
  email: [{ type: 'email', message: '邮箱格式不正确', trigger: 'blur' }],
}

const passwordRules: FormRules = {
  oldPassword: [{ required: true, message: '请填写当前密码', trigger: 'blur' }],
  newPassword: [
    { required: true, message: '请填写新密码', trigger: 'blur' },
    { min: 6, max: 32, message: '密码长度 6 到 32 位', trigger: 'blur' },
  ],
  confirmPassword: [
    { required: true, message: '请再次填写新密码', trigger: 'blur' },
    {
      validator: (_rule, value, callback) => {
        if (value !== password.newPassword) callback(new Error('两次输入的新密码不一致'))
        else callback()
      },
      trigger: 'blur',
    },
  ],
}

function unwrap(res: any): any {
  return res?.data ?? res
}

function syncStore() {
  userStore.setUserInfo({
    ...(userStore.userInfo ?? {}),
    userId: profile.userId,
    username: profile.username,
    nickname: profile.nickname,
    phone: profile.phone,
    email: profile.email,
    gender: profile.gender,
    avatarUrl: profile.avatarUrl,
    realName: profile.realName,
    status: profile.status,
  })
}

function payload() {
  return {
    nickname: profile.nickname.trim(),
    gender: profile.gender,
    phone: profile.phone.trim(),
    email: profile.email.trim(),
    realName: profile.realName,
    avatarUrl: profile.avatarUrl,
  }
}

function commitAvatar(url: string) {
  profile.avatarUrl = url
  syncStore()
  ElMessage.success('头像已更新')
}

async function loadProfile() {
  loading.value = true
  error.value = ''
  try {
    const data = unwrap(await http.get('/user/profile'))
    profile.userId = data?.userId ?? null
    profile.username = data?.username ?? ''
    profile.nickname = data?.nickname ?? ''
    profile.gender = Number(data?.gender ?? 0)
    profile.phone = data?.phone ?? ''
    profile.email = data?.email ?? ''
    profile.avatarUrl = data?.avatarUrl ?? ''
    profile.realName = data?.realName ?? ''
    profile.status = Number(data?.status ?? 2)
    profile.createTime = data?.createTime ?? ''
    syncStore()
  } catch (e: any) {
    error.value = e?.msg || (e instanceof Error ? e.message : '账号资料加载失败，请稍后重试')
  } finally {
    loading.value = false
  }
}

async function saveProfile() {
  if (!profileRef.value) return
  try {
    await profileRef.value.validate()
  } catch {
    return
  }
  saving.value = true
  try {
    const data = unwrap(await http.put('/user/profile', payload()))
    profile.nickname = data?.nickname ?? profile.nickname
    profile.phone = data?.phone ?? profile.phone
    profile.email = data?.email ?? profile.email
    profile.gender = Number(data?.gender ?? profile.gender)
    syncStore()
    ElMessage.success('账号资料已保存')
  } catch (e: any) {
    ElMessage.error(e?.msg || (e instanceof Error ? e.message : '保存失败，请稍后重试'))
  } finally {
    saving.value = false
  }
}

/**
 * 保存头像。
 *
 * 上传本身走统一的 /files/upload（FileUploader 内部完成，bizType=avatar），
 * 但"把这张图登记成我的头像"是另一件事：UserController.updateProfile 只回写
 * 昵称/手机/邮箱/性别/姓名/身份证，头像由 POST /user/avatar 负责。
 * 所以先用账号资料接口试一次（后端哪天支持 avatarUrl 就少一次搬运），
 * 没写进去再把同一张图交给头像接口登记，两条路都能落地才提示成功。
 */
async function applyAvatar(uploadedUrl: string) {
  savingAvatar.value = true
  try {
    const updated = unwrap(await http.put('/user/profile', { ...payload(), avatarUrl: uploadedUrl }))
    if ((updated?.avatarUrl ?? '') === uploadedUrl) {
      commitAvatar(uploadedUrl)
      return
    }

    let blob: Blob
    try {
      const res = await fetch(resolveImageUrl(uploadedUrl))
      if (!res.ok) throw new Error(String(res.status))
      blob = await res.blob()
    } catch {
      throw new Error('头像保存失败，请稍后重试')
    }

    const extension = AVATAR_EXTENSIONS[blob.type] ?? 'jpg'
    const form = new FormData()
    form.append('file', new File([blob], `avatar.${extension}`, { type: blob.type || 'image/jpeg' }))
    const saved = unwrap(
      await http.post('/user/avatar', form, {
        headers: { 'Content-Type': 'multipart/form-data' },
      }),
    )
    if (typeof saved !== 'string' || !saved) throw new Error('头像保存失败，请稍后重试')
    commitAvatar(saved)
  } catch (e: any) {
    ElMessage.error(e?.msg || (e instanceof Error ? e.message : '头像保存失败，请稍后重试'))
  } finally {
    savingAvatar.value = false
  }
}

watch(avatarFiles, (files) => {
  const url = files[0]?.url
  if (!url) return
  avatarFiles.value = []
  void applyAvatar(url)
})

async function changePassword() {
  if (!passwordRef.value) return
  try {
    await passwordRef.value.validate()
  } catch {
    return
  }
  savingPassword.value = true
  try {
    await http.put('/user/password', {
      oldPassword: password.oldPassword,
      newPassword: password.newPassword,
    })
    ElMessage.success('密码已修改，下次登录请使用新密码')
    passwordRef.value.resetFields()
  } catch (e: any) {
    ElMessage.error(e?.msg || (e instanceof Error ? e.message : '修改密码失败'))
  } finally {
    savingPassword.value = false
  }
}

async function loadReviews() {
  reviewsLoading.value = true
  reviewsError.value = ''
  try {
    const data = await user.evaluation.getUserEvaluations()
    reviews.value = Array.isArray(data) ? data : (data?.list ?? [])
  } catch (e: any) {
    reviewsError.value = e?.msg || (e instanceof Error ? e.message : '评价加载失败')
    reviews.value = []
  } finally {
    reviewsLoading.value = false
  }
}

function reviewImages(review: ReviewItem): string[] {
  const raw = review.imgUrls
  if (!raw) return []
  try {
    const parsed = JSON.parse(raw)
    if (Array.isArray(parsed)) return parsed.filter((item) => typeof item === 'string')
  } catch {
    // 历史数据可能是逗号分隔的一串路径
  }
  return String(raw)
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean)
}

function scoreText(review: ReviewItem): string {
  const n = Number(review.score)
  return Number.isFinite(n) && n > 0 ? `${n} / 5` : '未评分'
}

async function removeReview(review: ReviewItem) {
  try {
    await ElMessageBox.confirm('删除这条评价？删除后不会再展示在商品详情页。', '删除评价', {
      confirmButtonText: '删除',
      cancelButtonText: '取消',
      type: 'warning',
    })
  } catch {
    return
  }
  try {
    await user.evaluation.deleteEvaluation(review.evalId)
    reviews.value = reviews.value.filter((item) => item.evalId !== review.evalId)
    ElMessage.success('评价已删除')
  } catch (e: any) {
    ElMessage.error(e?.msg || (e instanceof Error ? e.message : '删除失败，请稍后重试'))
  }
}

onMounted(() => {
  void loadProfile()
  void loadReviews()
})
</script>

<template>
  <div class="shell profile">
    <SectionHead title="个人中心" note="账号资料、安全设置与自己发布的评价" size="lg" />

    <!-- 加载 -->
    <div v-if="loading" class="top" aria-busy="true">
      <div class="plate ghost ghost--identity">
        <div class="ghost__avatar skeleton" />
        <div class="ghost__lines">
          <span class="ghost__line skeleton" />
          <span class="ghost__line ghost__line--short skeleton" />
        </div>
      </div>
      <div class="plate ghost ghost--entries">
        <span class="ghost__line skeleton" v-for="n in 4" :key="n" />
      </div>
    </div>

    <!-- 错误 -->
    <div v-else-if="error" class="plate state">
      <AppIcon name="warning" size="22" />
      <p class="state__title">账号资料没能加载出来</p>
      <p class="state__note">{{ error }}</p>
      <button class="btn" type="button" @click="loadProfile">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
    </div>

    <template v-else>
      <div class="top">
        <!-- 身份 -->
        <section class="plate identity">
          <div class="identity__who">
            <span class="avatar">
              <img v-if="profile.avatarUrl" :src="resolveImageUrl(profile.avatarUrl)" :alt="displayName" />
              <span v-else class="avatar__initial">{{ initial }}</span>
            </span>
            <div class="identity__text">
              <h2 class="identity__name">{{ displayName }}</h2>
              <p class="identity__account mono">@{{ profile.username }}</p>
              <p class="identity__tags">
                <StatePill :label="accountState.label" :tone="accountState.tone" />
              </p>
            </div>
          </div>

          <dl class="spec identity__meta">
            <div class="spec__row">
              <dt class="spec__key">手机号码</dt>
              <dd class="spec__val">{{ maskPhone(profile.phone) }}</dd>
            </div>
            <div class="spec__row">
              <dt class="spec__key">邮箱</dt>
              <dd class="spec__val">{{ profile.email || '—' }}</dd>
            </div>
            <div class="spec__row">
              <dt class="spec__key">实名认证</dt>
              <dd class="spec__val">{{ realNameState }}</dd>
            </div>
            <div class="spec__row">
              <dt class="spec__key">注册时间</dt>
              <dd class="spec__val">{{ formatDateTime(profile.createTime) }}</dd>
            </div>
          </dl>
        </section>

        <!-- 常用入口 -->
        <section class="plate entries">
          <div class="plate__head">
            <span class="plate__title">常用入口</span>
          </div>
          <ul class="entries__list">
            <li v-for="entry in entries" :key="entry.to">
              <RouterLink class="entry" :to="entry.to">
                <AppIcon :name="entry.icon" size="17" />
                <span class="entry__text">
                  <span class="entry__label">{{ entry.label }}</span>
                  <span class="entry__note">{{ entry.note }}</span>
                </span>
                <AppIcon name="chevron-right" size="15" />
              </RouterLink>
            </li>
          </ul>
        </section>
      </div>

      <div class="forms">
        <!-- 账号资料（含头像上传） -->
        <section class="plate">
          <div class="plate__head">
            <span class="plate__title">账号资料</span>
            <span class="plate__note">头像与联系方式会用于订单与客服联系</span>
          </div>
          <div class="plate__body">
            <div class="avatar-block">
              <span class="avatar avatar--lg">
                <img
                  v-if="profile.avatarUrl"
                  :src="resolveImageUrl(profile.avatarUrl)"
                  :alt="displayName"
                />
                <span v-else class="avatar__initial">{{ initial }}</span>
              </span>
              <div class="avatar-field">
                <FileUploader
                  v-model="avatarFiles"
                  biz-type="avatar"
                  :max="1"
                  ratio="1 / 1"
                  :disabled="savingAvatar"
                  hint="JPG / PNG / WebP，不超过 10MB"
                />
              </div>
            </div>

            <el-form
              ref="profileRef"
              class="form"
              :model="profile"
              :rules="profileRules"
              label-position="top"
              @submit.prevent
            >
              <div class="form__grid">
                <el-form-item label="昵称" prop="nickname">
                  <el-input v-model="profile.nickname" maxlength="20" placeholder="显示在评价与订单中" />
                </el-form-item>

                <el-form-item label="性别">
                  <el-select v-model="profile.gender" placeholder="未填写">
                    <el-option label="未填写" :value="0" />
                    <el-option label="男" :value="1" />
                    <el-option label="女" :value="2" />
                  </el-select>
                </el-form-item>

                <el-form-item label="手机号码" prop="phone">
                  <el-input v-model="profile.phone" maxlength="11" placeholder="11 位手机号" />
                </el-form-item>

                <el-form-item label="邮箱" prop="email">
                  <el-input v-model="profile.email" maxlength="60" placeholder="用于找回密码" />
                </el-form-item>
              </div>

              <div class="form__foot">
                <button class="btn btn--primary" type="button" :disabled="saving" @click="saveProfile">
                  {{ saving ? '保存中…' : '保存资料' }}
                </button>
              </div>
            </el-form>
          </div>
        </section>

        <!-- 修改密码 -->
        <section class="plate">
          <div class="plate__head">
            <span class="plate__title">修改密码</span>
            <span class="plate__note">修改后请使用新密码重新登录</span>
          </div>
          <div class="plate__body">
            <el-form
              ref="passwordRef"
              class="form"
              :model="password"
              :rules="passwordRules"
              label-position="top"
              @submit.prevent
            >
              <el-form-item label="当前密码" prop="oldPassword">
                <el-input v-model="password.oldPassword" type="password" show-password />
              </el-form-item>
              <el-form-item label="新密码" prop="newPassword">
                <el-input v-model="password.newPassword" type="password" show-password />
              </el-form-item>
              <el-form-item label="确认新密码" prop="confirmPassword">
                <el-input v-model="password.confirmPassword" type="password" show-password />
              </el-form-item>

              <div class="form__foot">
                <button
                  class="btn btn--primary"
                  type="button"
                  :disabled="savingPassword"
                  @click="changePassword"
                >
                  {{ savingPassword ? '提交中…' : '修改密码' }}
                </button>
              </div>
            </el-form>
          </div>
        </section>
      </div>

      <!-- 我的评价 -->
      <section class="plate reviews">
        <div class="plate__head">
          <span class="plate__title">我的评价</span>
          <span v-if="reviews.length" class="plate__note">共 {{ reviews.length }} 条</span>
        </div>

        <div v-if="reviewsLoading" class="plate__body">
          <div class="ghost__line skeleton" v-for="n in 3" :key="n" />
        </div>

        <div v-else-if="reviewsError" class="state state--inline">
          <AppIcon name="warning" size="20" />
          <p class="state__title">评价没能加载出来</p>
          <p class="state__note">{{ reviewsError }}</p>
          <button class="btn" type="button" @click="loadReviews">
            <AppIcon name="refresh" size="14" />
            重新加载
          </button>
        </div>

        <EmptyState
          v-else-if="!reviews.length"
          title="还没有发表过评价"
          note="订单完成后可以在订单详情里评价器材与商家，评价会展示在商品页。"
        >
          <RouterLink class="btn" to="/orders">
            <AppIcon name="order" size="14" />
            查看我的订单
          </RouterLink>
        </EmptyState>

        <ul v-else class="review-list">
          <li v-for="review in reviews" :key="review.evalId" class="review">
            <div class="review__head">
              <RouterLink class="review__product" :to="`/product/${review.productId}`">
                {{ review.productName || '商品已下架' }}
              </RouterLink>
              <span class="review__score mono">{{ scoreText(review) }}</span>
              <time class="review__time">{{ formatDate(review.createTime) }}</time>
            </div>

            <p v-if="review.content" class="review__content">{{ review.content }}</p>

            <ul v-if="reviewImages(review).length" class="review__images">
              <li v-for="(img, index) in reviewImages(review)" :key="index">
                <ImageFrame :src="img" :alt="`评价图片 ${index + 1}`" ratio="1 / 1" fit="cover" />
              </li>
            </ul>

            <p v-if="review.replyContent" class="review__reply">商家回复：{{ review.replyContent }}</p>

            <div class="review__actions">
              <button class="link link--danger" type="button" @click="removeReview(review)">
                删除评价
              </button>
            </div>
          </li>
        </ul>
      </section>
    </template>
  </div>
</template>

<style scoped>
.profile {
  padding-block: var(--space-6) var(--space-16);
}

/* --- identity + entries --------------------------------------------------- */

.top {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 340px;
  align-items: start;
  gap: var(--space-4);
}

.identity {
  padding: var(--pad-surface);
}

.identity__who {
  display: flex;
  align-items: center;
  gap: var(--space-5);
}

.avatar {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 68px;
  height: 68px;
  flex-shrink: 0;
  overflow: hidden;
  border: var(--edge);
  border-radius: var(--radius-pill);
  background: var(--paper-2);
}

.avatar--lg {
  width: 88px;
  height: 88px;
}

.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar__initial {
  font-size: var(--text-lg);
  font-weight: 600;
  color: var(--ink-2);
}

.identity__name {
  font-size: var(--text-lg);
}

.identity__account {
  margin-top: 2px;
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.identity__tags {
  margin-top: var(--space-2);
}

.identity__meta {
  margin-top: var(--space-4);
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  column-gap: var(--space-8);
}

.entries__list {
  margin: 0;
  padding: 0;
  list-style: none;
}

.entry {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: 12px var(--pad-surface);
  border-bottom: var(--hairline);
  color: var(--ink-1);
  transition: background-color var(--dur-state) ease;
}

.entry:hover {
  text-decoration: none;
  background: var(--paper-1);
}

.entries__list li:last-child .entry {
  border-bottom: none;
}

.entry__text {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
}

.entry__label {
  font-size: var(--text-base);
  font-weight: 500;
  color: var(--ink-0);
}

.entry__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

/* --- forms ---------------------------------------------------------------- */

.forms {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--space-4);
  margin-top: var(--space-4);
  align-items: start;
}

.plate__note {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.avatar-block {
  display: flex;
  align-items: flex-start;
  gap: var(--space-5);
  padding-bottom: var(--space-4);
  margin-bottom: var(--space-4);
  border-bottom: var(--hairline);
}

.avatar-field {
  flex: 1;
  max-width: 260px;
}

.form__grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  column-gap: var(--space-4);
}

.form__foot {
  display: flex;
  justify-content: flex-end;
  margin-top: var(--space-2);
}

/* --- reviews -------------------------------------------------------------- */

.reviews {
  margin-top: var(--space-4);
}

.review-list {
  margin: 0;
  padding: 0;
  list-style: none;
}

.review {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-4) var(--pad-surface);
  border-bottom: var(--hairline);
}

.review:last-child {
  border-bottom: none;
}

.review__head {
  display: flex;
  align-items: baseline;
  gap: var(--space-3);
}

.review__product {
  flex: 1;
  min-width: 0;
  font-size: var(--text-base);
  font-weight: 600;
  color: var(--ink-0);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.review__product:hover {
  text-decoration: none;
  color: var(--signal-amber-deep);
}

.review__score {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--signal-amber-deep);
}

.review__time {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.review__content {
  font-size: var(--text-base);
  line-height: 1.7;
  color: var(--ink-1);
}

.review__images {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  margin: 0;
  padding: 0;
  list-style: none;
}

.review__images li {
  width: 76px;
  overflow: hidden;
  border: var(--edge);
  border-radius: var(--radius-sm);
}

.review__reply {
  padding: 8px 12px;
  border-radius: var(--radius-sm);
  background: var(--paper-2);
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.review__actions {
  display: flex;
  justify-content: flex-end;
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

.btn--primary {
  background: var(--ink-0);
  border-color: var(--ink-0);
  color: var(--on-ink);
}

.btn--primary:hover:not(:disabled) {
  background: var(--ink-1);
  border-color: var(--ink-1);
  color: var(--on-ink);
}

.btn--primary:disabled {
  background: var(--ink-4);
  border-color: var(--ink-4);
  color: var(--paper-0);
}

.link {
  padding: 0;
  border: none;
  background: transparent;
  font-size: var(--text-xs);
  color: var(--ink-2);
  cursor: pointer;
}

.link--danger:hover {
  color: var(--signal-vermilion-deep);
  text-decoration: underline;
}

/* --- states --------------------------------------------------------------- */

.state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-12) var(--space-6);
  text-align: center;
  color: var(--ink-3);
}

.state--inline {
  padding: var(--space-8) var(--space-6);
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
  gap: var(--space-4);
  padding: var(--pad-surface);
}

.ghost--identity {
  align-items: center;
}

.ghost--entries {
  flex-direction: column;
  gap: var(--space-3);
  justify-content: center;
}

.ghost__avatar {
  width: 68px;
  height: 68px;
  border-radius: var(--radius-pill);
}

.ghost__lines {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  flex: 1;
}

.ghost__line {
  display: block;
  height: 13px;
  border-radius: var(--radius-xs);
}

.ghost__line--short {
  width: 46%;
}

@media (max-width: 900px) {
  .profile {
    padding-block: var(--space-4) var(--space-12);
  }
  .top,
  .forms {
    grid-template-columns: minmax(0, 1fr);
  }
  .identity__meta {
    column-gap: var(--space-5);
  }
  .avatar-block {
    flex-direction: column;
    align-items: flex-start;
    gap: var(--space-4);
  }
  .avatar-field {
    max-width: 100%;
  }
}

@media (max-width: 520px) {
  .form__grid {
    grid-template-columns: minmax(0, 1fr);
  }
  .identity__meta {
    grid-template-columns: minmax(0, 1fr);
  }
  .review__head {
    flex-wrap: wrap;
  }
}
</style>
