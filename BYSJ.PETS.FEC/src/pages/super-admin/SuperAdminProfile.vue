<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import ImageFrame from '@/components/ui/ImageFrame.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import SpecList from '@/components/ui/SpecList.vue'
import StatePill from '@/components/ui/StatePill.vue'
import {
  changePassword,
  fetchProfile,
  readableError,
  updateProfile,
  uploadAvatar,
  type ProfileUser,
} from '@/api/super-admin'
import { MAX_UPLOAD_MB } from '@/api/files'
import { ACCOUNT_STATUS, USER_TYPE, labelOf } from '@/constants/domain'
import { formatDateTime } from '@/utils/format'
import { useUserStore } from '@/stores/user'

/**
 * 超管个人中心：自己的资料、头像与密码。
 *
 * 原实现用的是 npm 的裸 axios 再加手写 Authorization 头，绕开了全局拦截器，
 * 头像走的是 POST /user/avatar（旧的写盘路径），成功回执和失败提示各写一套。
 * 现在统一走 @/axios 与文件入口 /files/upload（bizType=avatar，后端一次请求
 * 就把 user.avatar_url 写好），接口地址与令牌都由全局配置负责。
 */

const userStore = useUserStore()

const GENDERS = [
  { value: 0, label: '未填写' },
  { value: 1, label: '男' },
  { value: 2, label: '女' },
]

const loading = ref(true)
const error = ref('')
const profile = ref<ProfileUser | null>(null)

const editing = ref(false)
const saving = ref(false)
const formRef = ref<FormInstance>()
const form = reactive({
  nickname: '',
  phone: '',
  email: '',
  gender: 0,
  realName: '',
  idCard: '',
})

const avatarBusy = ref(false)
const avatarInput = ref<HTMLInputElement | null>(null)

const displayName = computed(() => profile.value?.nickname || profile.value?.username || '超级管理员')
const accountStatus = computed(() => labelOf(ACCOUNT_STATUS, profile.value?.status, '状态未知'))
const accountType = computed(() => labelOf(USER_TYPE, 4))

const genderLabel = computed(
  () => GENDERS.find((item) => item.value === (profile.value?.gender ?? 0))?.label ?? '未填写',
)

const specs = computed(() => [
  { key: '用户名', value: profile.value?.username, mono: true },
  { key: '昵称', value: profile.value?.nickname },
  { key: '手机号', value: profile.value?.phone, mono: true },
  { key: '邮箱', value: profile.value?.email },
  { key: '性别', value: genderLabel.value },
  { key: '真实姓名', value: profile.value?.realName },
  { key: '注册时间', value: formatDateTime(profile.value?.createTime) },
  { key: '最后更新', value: formatDateTime(profile.value?.updateTime) },
])

const rules: FormRules = {
  nickname: [
    { required: true, message: '请输入昵称', trigger: 'blur' },
    { min: 2, max: 50, message: '昵称长度 2 到 50 位', trigger: 'blur' },
  ],
  phone: [{ pattern: /^1[3-9]\d{9}$/, message: '请输入 11 位手机号', trigger: 'blur' }],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '邮箱格式不正确', trigger: 'blur' },
  ],
  idCard: [
    {
      pattern: /^\d{17}[\dXx]$/,
      message: '身份证号是 18 位，最后一位可为 X',
      trigger: 'blur',
    },
  ],
}

function syncStore(next: ProfileUser) {
  userStore.setUserInfo({
    ...(userStore.userInfo ?? {}),
    nickname: next.nickname,
    phone: next.phone,
    email: next.email,
    avatarUrl: next.avatarUrl,
  })
}

function fillForm(next: ProfileUser) {
  Object.assign(form, {
    nickname: next.nickname ?? '',
    phone: next.phone ?? '',
    email: next.email ?? '',
    gender: next.gender ?? 0,
    realName: next.realName ?? '',
    idCard: next.idCard ?? '',
  })
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const next = await fetchProfile()
    profile.value = next
    fillForm(next)
  } catch (e) {
    profile.value = null
    error.value = readableError(e, '账号资料加载失败')
  } finally {
    loading.value = false
  }
}

function startEdit() {
  if (profile.value) fillForm(profile.value)
  editing.value = true
  void formRef.value?.clearValidate()
}

function cancelEdit() {
  editing.value = false
  if (profile.value) fillForm(profile.value)
}

async function save() {
  if (!formRef.value) return
  try {
    await formRef.value.validate()
  } catch {
    return
  }

  saving.value = true
  try {
    const next = await updateProfile({
      nickname: form.nickname.trim(),
      phone: form.phone.trim(),
      email: form.email.trim(),
      gender: form.gender,
      realName: form.realName.trim(),
      idCard: form.idCard.trim(),
    })
    profile.value = next
    fillForm(next)
    syncStore(next)
    editing.value = false
    ElMessage.success('资料已保存')
  } catch (e) {
    ElMessage.error(readableError(e, '资料保存失败'))
  } finally {
    saving.value = false
  }
}

/* --- 头像 ---------------------------------------------------------------- */

function pickAvatar() {
  avatarInput.value?.click()
}

async function onAvatarChange(event: Event) {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  target.value = ''
  if (!file) return
  if (!file.type.startsWith('image/')) {
    ElMessage.error('只能上传图片文件')
    return
  }
  if (file.size > MAX_UPLOAD_MB * 1024 * 1024) {
    ElMessage.error(`图片不能超过 ${MAX_UPLOAD_MB}MB`)
    return
  }

  avatarBusy.value = true
  try {
    const url = await uploadAvatar(file)
    if (profile.value) {
      profile.value = { ...profile.value, avatarUrl: url }
      syncStore(profile.value)
    }
    ElMessage.success('头像已更新')
  } catch (e) {
    ElMessage.error(readableError(e, '头像上传失败'))
  } finally {
    avatarBusy.value = false
  }
}

/* --- 改密 ---------------------------------------------------------------- */

const passwordOpen = ref(false)
const passwordBusy = ref(false)
const passwordFormRef = ref<FormInstance>()
const passwordForm = reactive({ oldPassword: '', newPassword: '', confirmPassword: '' })

function passwordStrength(value: string): '弱' | '中' | '强' {
  const text = String(value ?? '')
  if (text.length < 8) return '弱'
  const kinds = [/[a-z]/, /[A-Z]/, /\d/, /[^A-Za-z0-9]/].filter((pattern) => pattern.test(text)).length
  return kinds >= 3 ? '强' : '中'
}

function validNewPassword(_rule: unknown, value: string, callback: (error?: Error) => void) {
  const text = String(value ?? '')
  if (!text) return callback(new Error('请输入新密码'))
  if (text.length < 6 || text.length > 20) return callback(new Error('新密码长度 6 到 20 位'))
  if (/\s/.test(text)) return callback(new Error('新密码不能包含空格'))
  if (!/[A-Za-z]/.test(text) || !/\d/.test(text)) {
    return callback(new Error('新密码需同时包含字母和数字'))
  }
  if (text === passwordForm.oldPassword) return callback(new Error('新密码不能与旧密码相同'))
  return callback()
}

const passwordRules: FormRules = {
  oldPassword: [{ required: true, message: '请输入当前密码', trigger: 'blur' }],
  newPassword: [{ required: true, validator: validNewPassword, trigger: 'blur' }],
  confirmPassword: [
    { required: true, message: '请再次输入新密码', trigger: 'blur' },
    {
      validator: (_rule: unknown, value: string, callback: (error?: Error) => void) =>
        value === passwordForm.newPassword ? callback() : callback(new Error('两次输入的密码不一致')),
      trigger: 'blur',
    },
  ],
}

function openPassword() {
  passwordForm.oldPassword = ''
  passwordForm.newPassword = ''
  passwordForm.confirmPassword = ''
  passwordOpen.value = true
  void passwordFormRef.value?.clearValidate()
}

async function submitPassword() {
  if (!passwordFormRef.value) return
  try {
    await passwordFormRef.value.validate()
  } catch {
    return
  }

  passwordBusy.value = true
  try {
    await changePassword(passwordForm.oldPassword, passwordForm.newPassword)
    ElMessage.success('密码已修改')
    passwordOpen.value = false
  } catch (e) {
    ElMessage.error(readableError(e, '密码修改失败'))
  } finally {
    passwordBusy.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="page">
    <SectionHead
      title="个人中心"
      :note="`${accountType.label}账号 · 可访问范围由角色权限决定`"
      size="lg"
    >
      <template #action>
        <div class="head-actions">
          <button v-if="!editing" class="btn" type="button" @click="openPassword">
            <AppIcon name="lock" size="14" />
            修改密码
          </button>
          <template v-if="editing">
            <button class="btn" type="button" :disabled="saving" @click="cancelEdit">取消</button>
            <button class="btn btn--solid" type="button" :disabled="saving" @click="save">
              {{ saving ? '保存中…' : '保存资料' }}
            </button>
          </template>
          <button v-else class="btn btn--solid" type="button" :disabled="loading || !profile" @click="startEdit">
            <AppIcon name="edit" size="14" />
            编辑资料
          </button>
        </div>
      </template>
    </SectionHead>

    <div v-if="loading" class="plate identity" aria-busy="true">
      <div class="identity__avatar skeleton" />
      <div class="identity__lines">
        <span class="skeleton skeleton--name" />
        <span class="skeleton skeleton--line" />
        <span class="skeleton skeleton--line" />
      </div>
    </div>

    <div v-else-if="error" class="plate">
      <EmptyState title="账号资料加载失败" :note="error">
        <button class="btn" type="button" @click="load">
          <AppIcon name="refresh" size="14" />
          重新加载
        </button>
      </EmptyState>
    </div>

    <template v-else-if="profile">
      <section class="plate identity">
        <div class="identity__left">
          <div class="avatar">
            <ImageFrame :src="profile.avatarUrl" :alt="`${displayName} 的头像`" ratio="1 / 1" fit="cover" />
          </div>
          <button class="btn btn--small" type="button" :disabled="avatarBusy" @click="pickAvatar">
            <AppIcon name="upload" size="14" />
            {{ avatarBusy ? '上传中…' : '更换头像' }}
          </button>
          <input
            ref="avatarInput"
            class="sr-only"
            type="file"
            accept="image/jpeg,image/png,image/webp"
            @change="onAvatarChange"
          />
        </div>

        <div class="identity__main">
          <div class="identity__head">
            <h2 class="identity__name">{{ displayName }}</h2>
            <StatePill :label="accountStatus.label" :tone="accountStatus.tone" />
            <StatePill :label="accountType.label" :tone="accountType.tone" />
          </div>
          <p class="identity__username mono">{{ profile.username }}</p>

          <el-form
            v-if="editing"
            ref="formRef"
            :model="form"
            :rules="rules"
            label-position="top"
            class="edit-form"
          >
            <div class="edit-grid">
              <el-form-item label="昵称" prop="nickname">
                <el-input v-model="form.nickname" maxlength="50" />
              </el-form-item>
              <el-form-item label="手机号" prop="phone">
                <el-input v-model="form.phone" placeholder="可留空" maxlength="11" />
              </el-form-item>
              <el-form-item label="邮箱" prop="email">
                <el-input v-model="form.email" maxlength="100" />
              </el-form-item>
              <el-form-item label="性别">
                <el-radio-group v-model="form.gender">
                  <el-radio v-for="item in GENDERS" :key="item.value" :value="item.value">
                    {{ item.label }}
                  </el-radio>
                </el-radio-group>
              </el-form-item>
              <el-form-item label="真实姓名">
                <el-input v-model="form.realName" placeholder="可留空" maxlength="50" />
              </el-form-item>
              <el-form-item label="身份证号" prop="idCard">
                <el-input v-model="form.idCard" placeholder="可留空" maxlength="18" />
              </el-form-item>
            </div>
          </el-form>

          <SpecList v-else class="identity__spec" :entries="specs" :columns="2" />
        </div>
      </section>

      <section class="plate sessions">
        <header class="plate__head">
          <p class="plate__title">登录与安全</p>
          <button class="btn btn--small" type="button" @click="openPassword">
            <AppIcon name="lock" size="14" />
            修改密码
          </button>
        </header>
        <div class="plate__body sessions__body">
          <p class="sessions__line">
            修改密码只影响下一次登录。已经登录的其它设备持有的是登录时签发的令牌，
            它们仍可继续访问，直到令牌过期或主动退出。
          </p>
          <p class="sessions__line">
            账号被停用后，任何后台请求都会在服务端被拒绝，无需等待令牌过期。
          </p>
        </div>
      </section>
    </template>

    <el-dialog v-model="passwordOpen" title="修改密码" width="440px">
      <el-form ref="passwordFormRef" :model="passwordForm" :rules="passwordRules" label-position="top">
        <el-form-item label="当前密码" prop="oldPassword">
          <el-input v-model="passwordForm.oldPassword" type="password" show-password />
        </el-form-item>
        <el-form-item label="新密码" prop="newPassword">
          <el-input v-model="passwordForm.newPassword" type="password" show-password />
        </el-form-item>
        <p class="strength">
          强度：{{ passwordStrength(passwordForm.newPassword) }}
          <span class="strength__hint">6 到 20 位，需含字母与数字</span>
        </p>
        <el-form-item label="确认新密码" prop="confirmPassword">
          <el-input v-model="passwordForm.confirmPassword" type="password" show-password />
        </el-form-item>
      </el-form>

      <template #footer>
        <div class="dialog-foot">
          <button class="btn" type="button" @click="passwordOpen = false">取消</button>
          <button class="btn btn--solid" type="button" :disabled="passwordBusy" @click="submitPassword">
            {{ passwordBusy ? '提交中…' : '确认修改' }}
          </button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.page {
  max-width: var(--shell-max);
  margin-inline: auto;
  padding-bottom: var(--space-8);
}

.head-actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.identity {
  display: flex;
  align-items: flex-start;
  gap: var(--space-6);
  padding: var(--pad-surface);
}

.identity__left {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-3);
  flex-shrink: 0;
}

.avatar {
  width: 104px;
  overflow: hidden;
  border: var(--edge);
  border-radius: var(--radius-md);
}

.identity__main {
  flex: 1;
  min-width: 0;
}

.identity__head {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.identity__name {
  font-size: var(--text-lg);
  font-weight: 600;
}

.identity__username {
  margin-top: 2px;
  color: var(--ink-3);
  font-size: var(--text-xs);
}

.identity__spec {
  margin-top: var(--space-4);
}

.edit-form {
  margin-top: var(--space-3);
}

.edit-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
  column-gap: var(--space-5);
}

.sessions {
  margin-top: var(--gap-surface);
}

.sessions__body {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.sessions__line {
  color: var(--ink-3);
  font-size: var(--text-sm);
}

.strength {
  margin: calc(-1 * var(--space-2)) 0 var(--space-3);
  color: var(--ink-2);
  font-size: var(--text-xs);
}

.strength__hint {
  margin-left: var(--space-2);
  color: var(--ink-4);
}

.identity__lines {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  flex: 1;
}

.identity__avatar {
  width: 104px;
  height: 104px;
  flex-shrink: 0;
  border-radius: var(--radius-md);
}

.skeleton {
  display: block;
}

.skeleton--name {
  width: 180px;
  height: 22px;
}

.skeleton--line {
  width: 60%;
  height: 14px;
}

.dialog-foot {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
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
  white-space: nowrap;
  transition:
    border-color var(--dur-state) ease,
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
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
  background: #262d33;
  border-color: #262d33;
}

.btn--small {
  height: calc(28px * var(--dense));
  padding-inline: 10px;
  font-size: var(--text-xs);
}

.btn:disabled {
  border-color: var(--line-2);
  background: var(--paper-2);
  color: var(--ink-4);
  cursor: not-allowed;
}

@media (max-width: 767px) {
  .identity {
    flex-direction: column;
    align-items: stretch;
  }

  .identity__left {
    flex-direction: row;
    align-items: center;
  }

  .avatar {
    width: 72px;
  }
}
</style>
