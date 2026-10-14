<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import SpecList from '@/components/ui/SpecList.vue'
import StatePill from '@/components/ui/StatePill.vue'
import service from '@/axios'
import { ACCOUNT_STATUS, USER_TYPE, labelOf } from '@/constants/domain'
import { useUserStore } from '@/stores/user'
import { IMAGE_PLACEHOLDER, formatDateTime, resolveImageUrl } from '@/utils/format'

/**
 * 管理员账户信息。
 *
 * 后端没有管理员专用的资料接口，能用的就是 /user/profile（对所有登录角色开放），
 * 头像也只有一个既写文件又落库的 POST /user/avatar。原页面直接用裸 axios 拼
 * `/api/user/avatar`（环境变量名还是错的 VITE_API_BASE_URL），并且把上传地址、
 * 令牌、错误提示又各写了一遍，这里统一回项目自己的请求层与 baseURL。
 *
 * 权限矩阵不在这一页：管理员读不到 /super-admin/**，角色与权限由超级管理员维护。
 */

const userStore = useUserStore()

const loading = ref(true)
const failed = ref(false)
const saving = ref(false)
const uploading = ref(false)
const editing = ref(false)
const formError = ref('')
const passwordOpen = ref(false)
const passwordSaving = ref(false)
const passwordError = ref('')

const profile = reactive({
  userId: 0,
  username: '',
  nickname: '',
  phone: '',
  email: '',
  realName: '',
  avatarUrl: '',
  userType: 1,
  status: 1,
  createTime: '',
  updateTime: '',
})

const passwordForm = reactive({ oldPassword: '', newPassword: '', confirmPassword: '' })

const avatarUrl = computed(() => (profile.avatarUrl ? resolveImageUrl(profile.avatarUrl) : IMAGE_PLACEHOLDER))
const role = computed(() => labelOf(USER_TYPE, profile.userType))
const accountState = computed(() => labelOf(ACCOUNT_STATUS, profile.status, '未认证'))

const avatarAction = `${import.meta.env.VITE_APP_BASE_API || '/api'}/user/avatar`
const avatarHeaders = computed(() => ({ Authorization: `Bearer ${userStore.token ?? ''}` }))

function fill(data: Record<string, unknown>) {
  profile.userId = Number(data.userId ?? 0)
  profile.username = String(data.username ?? '')
  profile.nickname = String(data.nickname ?? '')
  profile.phone = String(data.phone ?? '')
  profile.email = String(data.email ?? '')
  profile.realName = String(data.realName ?? '')
  profile.avatarUrl = String(data.avatarUrl ?? '')
  profile.userType = Number(data.userType ?? 1)
  profile.status = Number(data.status ?? 1)
  profile.createTime = String(data.createTime ?? '')
  profile.updateTime = String(data.updateTime ?? '')
}

async function load() {
  loading.value = true
  failed.value = false
  try {
    const body = (await service.get('/user/profile')) as unknown as {
      data: Record<string, unknown>
    }
    fill(body?.data ?? {})
  } catch {
    failed.value = true
  } finally {
    loading.value = false
  }
}

function openEditor() {
  editing.value = true
  formError.value = ''
}

function cancelEditor() {
  editing.value = false
  formError.value = ''
  void load()
}

async function saveProfile() {
  if (saving.value) return
  const phone = profile.phone.trim()
  const email = profile.email.trim()
  if (phone && !/^\d{6,20}$/.test(phone)) {
    formError.value = '手机号只能是 6 到 20 位数字。'
    return
  }
  if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    formError.value = '邮箱格式不正确。'
    return
  }
  formError.value = ''
  saving.value = true
  try {
    const body = (await service.put('/user/profile', {
      nickname: profile.nickname.trim(),
      phone: phone || null,
      email: email || null,
      gender: null,
      realName: profile.realName || null,
      idCard: null,
    })) as unknown as { data: Record<string, unknown> }
    fill(body?.data ?? {})
    userStore.setUserInfo({
      ...(userStore.userInfo ?? {}),
      nickname: profile.nickname,
      phone: profile.phone,
      email: profile.email,
      avatarUrl: profile.avatarUrl,
    })
    ElMessage.success('资料已保存')
    editing.value = false
  } catch (error) {
    formError.value = error instanceof Error ? error.message : '保存失败，请重试'
  } finally {
    saving.value = false
  }
}

function beforeAvatarUpload(file: File) {
  const okType = ['image/jpeg', 'image/png', 'image/webp'].includes(file.type)
  if (!okType) {
    ElMessage.error('头像只支持 JPG / PNG / WebP')
    return false
  }
  if (file.size / 1024 / 1024 > 5) {
    ElMessage.error('头像不能超过 5MB')
    return false
  }
  uploading.value = true
  return true
}

function onAvatarUploaded(response: { code?: number; msg?: string; data?: string }) {
  uploading.value = false
  if (response?.code !== 200 || !response.data) {
    ElMessage.error(response?.msg || '头像上传失败')
    return
  }
  profile.avatarUrl = response.data
  userStore.setUserInfo({ ...(userStore.userInfo ?? {}), avatarUrl: response.data })
  ElMessage.success('头像已更新')
}

function onAvatarFailed() {
  uploading.value = false
  ElMessage.error('头像上传失败，请确认后端服务与存储目录可用')
}

async function changePassword() {
  if (passwordSaving.value) return
  const { oldPassword, newPassword, confirmPassword } = passwordForm
  if (!oldPassword) {
    passwordError.value = '请输入当前密码。'
    return
  }
  if (newPassword.length < 6) {
    passwordError.value = '新密码至少 6 位。'
    return
  }
  if (newPassword !== confirmPassword) {
    passwordError.value = '两次输入的新密码不一致。'
    return
  }
  passwordError.value = ''
  passwordSaving.value = true
  try {
    await service.put('/user/password', { oldPassword, newPassword })
    ElMessage.success('密码已修改')
    passwordForm.oldPassword = ''
    passwordForm.newPassword = ''
    passwordForm.confirmPassword = ''
    passwordOpen.value = false
  } catch (error) {
    passwordError.value = error instanceof Error ? error.message : '修改失败，请重试'
  } finally {
    passwordSaving.value = false
  }
}

onMounted(() => {
  void load()
})
</script>

<template>
  <div class="profile" data-density="admin">
    <SectionHead
      title="账户信息"
      note="这里改的是当前登录管理员的账号资料与密码，不涉及权限分配。"
      size="lg"
    >
      <template #action>
        <button class="link-action" type="button" :disabled="loading" @click="load">
          <AppIcon name="refresh" size="14" />
          刷新
        </button>
      </template>
    </SectionHead>

    <p v-if="failed" class="band band--error">
      <AppIcon name="warning" size="15" />
      <span>账户信息没能加载。请确认登录状态与后端服务，然后重试。</span>
      <button class="band__action" type="button" @click="load">重试</button>
    </p>

    <div class="grid">
      <section class="plate identity">
        <div v-if="loading" class="loading-list">
          <span class="skeleton loading-list__row" />
          <span class="skeleton loading-list__row" />
        </div>

        <template v-else>
          <div class="identity__head">
            <img class="identity__avatar" :src="avatarUrl" :alt="profile.nickname || profile.username" />
            <div class="identity__text">
              <p class="identity__name">{{ profile.nickname || '未设置昵称' }}</p>
              <p class="identity__account mono">{{ profile.username }}</p>
              <div class="identity__pills">
                <StatePill :label="role.label" :tone="role.tone" />
                <StatePill :label="accountState.label" :tone="accountState.tone" />
              </div>
            </div>
          </div>

          <el-upload
            class="identity__upload"
            :action="avatarAction"
            :headers="avatarHeaders"
            :show-file-list="false"
            name="file"
            :before-upload="beforeAvatarUpload"
            :on-success="onAvatarUploaded"
            :on-error="onAvatarFailed"
          >
            <el-button size="small" :loading="uploading">
              <AppIcon name="upload" size="14" />
              更换头像
            </el-button>
          </el-upload>
          <p class="identity__hint">JPG / PNG / WebP，单张不超过 5MB，服务端会等比压缩到 1920px。</p>
        </template>
      </section>

      <section class="plate">
        <div class="plate__head">
          <span class="plate__title">账号资料</span>
          <button class="link-action" type="button" @click="editing ? cancelEditor() : openEditor()">
            {{ editing ? '取消编辑' : '编辑资料' }}
          </button>
        </div>

        <div v-if="loading" class="loading-list">
          <span class="skeleton loading-list__row" />
          <span class="skeleton loading-list__row" />
          <span class="skeleton loading-list__row" />
        </div>

        <div v-else-if="editing" class="form">
          <label class="field">
            <span class="field__label">登录账号</span>
            <el-input :model-value="profile.username" disabled />
          </label>
          <label class="field">
            <span class="field__label">昵称</span>
            <el-input v-model="profile.nickname" placeholder="显示在后台顶栏" />
          </label>
          <label class="field">
            <span class="field__label">手机号</span>
            <el-input v-model="profile.phone" placeholder="用于验证码登录与通知" />
          </label>
          <label class="field">
            <span class="field__label">邮箱</span>
            <el-input v-model="profile.email" placeholder="用于找回密码" />
          </label>
          <label class="field">
            <span class="field__label">真实姓名</span>
            <el-input v-model="profile.realName" placeholder="可留空" />
          </label>

          <p v-if="formError" class="form__error">
            <AppIcon name="warning" size="14" />
            <span>{{ formError }}</span>
          </p>

          <div class="form__actions">
            <el-button @click="cancelEditor">取消</el-button>
            <el-button type="primary" :loading="saving" @click="saveProfile">保存</el-button>
          </div>
        </div>

        <div v-else class="plate__body">
          <SpecList
            :entries="[
              { key: '用户ID', value: `#${profile.userId}`, mono: true },
              { key: '登录账号', value: profile.username, mono: true },
              { key: '昵称', value: profile.nickname },
              { key: '真实姓名', value: profile.realName },
              { key: '手机号', value: profile.phone },
              { key: '邮箱', value: profile.email },
              { key: '账号状态', value: accountState.label },
              { key: '注册时间', value: formatDateTime(profile.createTime) },
              { key: '资料更新时间', value: formatDateTime(profile.updateTime) },
            ]"
          />
        </div>
      </section>
    </div>

    <section class="plate">
      <div class="plate__head">
        <span class="plate__title">修改密码</span>
        <button class="link-action" type="button" @click="passwordOpen = !passwordOpen">
          {{ passwordOpen ? '收起' : '展开' }}
        </button>
      </div>

      <div v-if="passwordOpen" class="form plate__body">
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

        <p v-if="passwordError" class="form__error">
          <AppIcon name="warning" size="14" />
          <span>{{ passwordError }}</span>
        </p>

        <div class="form__actions">
          <el-button type="primary" :loading="passwordSaving" @click="changePassword">
            修改密码
          </el-button>
        </div>
      </div>
      <p v-else class="plate__foot">密码修改需要验证当前密码，改完后新密码立即生效。</p>
    </section>
  </div>
</template>

<style scoped>
.profile {
  display: flex;
  flex-direction: column;
  gap: var(--gap-surface);
}

.grid {
  display: grid;
  grid-template-columns: minmax(260px, 340px) minmax(0, 1fr);
  gap: var(--gap-surface);
  align-items: start;
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

.identity {
  padding: var(--space-5) var(--space-4);
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.identity__head {
  display: flex;
  align-items: center;
  gap: var(--space-4);
}

.identity__avatar {
  width: calc(64px * var(--dense) + 16px);
  height: calc(64px * var(--dense) + 16px);
  border-radius: var(--radius-pill);
  border: var(--edge);
  object-fit: cover;
  background: var(--paper-1);
}

.identity__text {
  min-width: 0;
}

.identity__name {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--ink-0);
}

.identity__account {
  color: var(--ink-3);
  font-size: var(--text-xs);
}

.identity__pills {
  display: flex;
  gap: var(--space-1);
  margin-top: var(--space-1);
  flex-wrap: wrap;
}

.identity__upload {
  align-self: flex-start;
}

.identity__hint,
.plate__foot {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.plate__foot {
  padding: var(--space-3) var(--space-4);
}

.loading-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-4);
}

.loading-list__row {
  height: calc(34px * var(--dense));
}

.form {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.field {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
  max-width: 420px;
}

.field__label {
  font-size: var(--text-sm);
  color: var(--ink-2);
}

.form__error {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  color: var(--signal-vermilion-deep);
  font-size: var(--text-xs);
}

.form__actions {
  display: flex;
  gap: var(--space-2);
}

@media (max-width: 900px) {
  .grid {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
