<script setup lang="ts">
import { computed, onUnmounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import {
  checkUser,
  errorText,
  resetPassword,
  sendResetPasswordCode,
  verifyResetPasswordCode,
} from '@/api/user/auth'

/**
 * 找回密码。
 *
 * 三步走：核对账号 → 邮箱验证码 → 设置新密码，对应后端
 * /auth/check-user、/auth/send-reset-code、/auth/verify-reset-code、/auth/reset-password。
 * 邮箱锁定为账号绑定的那一个（由 check-user 返回），避免把验证码发到任意地址。
 */
const router = useRouter()

const STEPS = [
  { no: 1, label: '验证账号' },
  { no: 2, label: '输入验证码' },
  { no: 3, label: '设置新密码' },
] as const

const BRAND_LINES = [
  { key: '验证码有效期', note: '5 分钟' },
  { key: '发送间隔', note: '每次发送后 60 秒可重发' },
  { key: '重置结果', note: '原密码立即失效，需用新密码登录' },
] as const

const HEAD = {
  1: {
    title: '找回密码',
    note: '填写注册时的账号，验证码会发到该账号绑定的邮箱。',
  },
  2: {
    title: '输入验证码',
    note: '验证码 5 分钟内有效，没收到可以重新发送或返回上一步核对账号。',
  },
  3: {
    title: '设置新密码',
    note: '新密码保存后原密码立即失效，其他设备需要重新登录。',
  },
} as const

const STRENGTH_LABEL = ['弱', '中', '强'] as const

const formRef = ref<FormInstance>()
const form = reactive({
  username: '',
  code: '',
  password: '',
  confirm: '',
})

const step = ref<1 | 2 | 3>(1)
const boundEmail = ref('')
const loading = ref(false)
const sending = ref(false)
const error = ref('')
const countdown = ref(0)
const showPassword = ref(false)

let countdownTimer: ReturnType<typeof setInterval> | undefined

const head = computed(() => HEAD[step.value])

/** 密码强度：长度打底，字符种类加分。0 弱 / 1 中 / 2 强。 */
function strengthOf(value: string): 0 | 1 | 2 {
  if (!value) return 0
  let kinds = 0
  if (/[A-Za-z]/.test(value)) kinds += 1
  if (/\d/.test(value)) kinds += 1
  if (/[^A-Za-z0-9]/.test(value)) kinds += 1
  if (value.length >= 10 && kinds >= 3) return 2
  if (value.length >= 8 && kinds >= 2) return 2
  if (value.length >= 6 && kinds >= 2) return 1
  return 0
}

const strength = computed(() => strengthOf(form.password))

function passwordError(value: string): string {
  if (!value) return ''
  if (/\s/.test(value)) return '密码不能包含空格'
  if (value.length < 6 || value.length > 20) return '密码长度为 6 到 20 位'
  if (!/[A-Za-z]/.test(value) || !/\d/.test(value)) return '密码需同时包含字母和数字'
  return ''
}

const rules: FormRules = {
  username: [
    { required: true, message: '请输入账号', trigger: 'blur' },
    { min: 3, max: 50, message: '账号长度为 3 到 50 个字符', trigger: 'blur' },
  ],
  code: [
    { required: true, message: '请输入邮箱收到的 6 位验证码', trigger: 'blur' },
    { pattern: /^\d{6}$/, message: '验证码为 6 位数字', trigger: 'blur' },
  ],
  password: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    {
      validator: (_rule, value, callback) => {
        const message = passwordError(String(value ?? ''))
        callback(message ? new Error(message) : undefined)
      },
      trigger: 'blur',
    },
  ],
  confirm: [
    { required: true, message: '请再次输入新密码', trigger: 'blur' },
    {
      validator: (_rule, value, callback) => {
        callback(value === form.password ? undefined : new Error('两次输入的密码不一致'))
      },
      trigger: ['blur', 'change'],
    },
  ],
}

/** 邮箱脱敏：只留前两位，域名保留。 */
function maskEmail(value: string): string {
  const at = value.indexOf('@')
  if (at <= 0) return value
  const name = value.slice(0, at)
  const head = name.slice(0, Math.min(2, name.length))
  return `${head}${'*'.repeat(Math.max(1, name.length - head.length))}${value.slice(at)}`
}

async function validateStep(): Promise<boolean> {
  const fields =
    step.value === 1 ? ['username'] : step.value === 2 ? ['code'] : ['password', 'confirm']
  try {
    return (await formRef.value?.validateField(fields)) ?? false
  } catch {
    return false
  }
}

function stopCountdown() {
  if (countdownTimer !== undefined) {
    clearInterval(countdownTimer)
    countdownTimer = undefined
  }
  countdown.value = 0
}

function startCountdown() {
  stopCountdown()
  countdown.value = 60
  countdownTimer = setInterval(() => {
    countdown.value -= 1
    if (countdown.value <= 0) stopCountdown()
  }, 1000)
}

onUnmounted(stopCountdown)

async function sendCode() {
  if (countdown.value > 0 || sending.value) return
  error.value = ''
  sending.value = true
  try {
    const res = await sendResetPasswordCode({ email: boundEmail.value })
    if (res.code !== 200) {
      error.value = res.msg || '验证码发送失败，请稍后重新发送'
      return
    }
    ElMessage.success(`验证码已发送到 ${maskEmail(boundEmail.value)}`)
    startCountdown()
  } catch (e) {
    error.value = errorText(e, '验证码发送失败，请稍后重新发送')
  } finally {
    sending.value = false
  }
}

async function stepCheckUser() {
  try {
    const res = await checkUser({ username: form.username.trim() })
    if (res.code !== 200 || !res.data?.email) {
      error.value = res.msg || '该账号没有绑定邮箱，无法自助找回，请联系平台客服'
      return
    }
    boundEmail.value = res.data.email
    form.code = ''
    step.value = 2
  } catch (e) {
    error.value = `${errorText(e, '账号校验失败')}，请确认账号与注册时填写的一致`
  }
}

async function stepVerifyCode() {
  try {
    const res = await verifyResetPasswordCode({ email: boundEmail.value, code: form.code.trim() })
    if (res.code !== 200) {
      error.value = res.msg || '验证码不正确或已过期，可重新发送后再试'
      return
    }
    step.value = 3
  } catch (e) {
    error.value = `${errorText(e, '验证码校验失败')}，可重新发送验证码后再试`
  }
}

async function stepReset() {
  try {
    const res = await resetPassword({
      username: form.username.trim(),
      email: boundEmail.value,
      code: form.code.trim(),
      newPassword: form.password,
    })
    if (res.code !== 200) {
      error.value = res.msg || '密码重置失败，请重新获取验证码后再试'
      return
    }
    stopCountdown()
    ElMessage.success('密码已重置，请使用新密码登录')
    router.push({ path: '/login', query: { username: form.username.trim() } })
  } catch (e) {
    error.value = `${errorText(e, '密码重置失败')}，请重新获取验证码后再试`
  }
}

async function submit() {
  if (loading.value) return
  error.value = ''
  if (!(await validateStep())) return

  loading.value = true
  try {
    if (step.value === 1) await stepCheckUser()
    else if (step.value === 2) await stepVerifyCode()
    else await stepReset()
  } finally {
    loading.value = false
  }
}

/** 从验证码一步退回账号一步，绑定的邮箱与已填验证码一并作废。 */
function backToAccount() {
  step.value = 1
  boundEmail.value = ''
  form.code = ''
  error.value = ''
  stopCountdown()
  formRef.value?.clearValidate(['code'])
}

function handleBack() {
  if (step.value > 1) {
    backToAccount()
  } else {
    router.push('/login')
  }
}
</script>

<template>
  <div class="auth">
    <aside class="auth__brand">
      <img class="brand__photo" src="/media/hero-skyline.jpg" alt="" />
      <div class="brand__scrim" aria-hidden="true" />

      <div class="brand__inner">
        <RouterLink class="brand__link" to="/index">
          <img class="brand__mark" src="/相机.png" alt="" width="28" height="28" />
          <span class="brand__name">摄影器材交易系统</span>
        </RouterLink>

        <div class="brand__body">
          <p class="brand__lede">用绑定邮箱接收验证码，验证通过后设置新密码。</p>
          <dl class="brand__spec">
            <div v-for="line in BRAND_LINES" :key="line.key" class="brand__spec-row">
              <dt>{{ line.key }}</dt>
              <dd>{{ line.note }}</dd>
            </div>
          </dl>
        </div>
      </div>
    </aside>

    <main class="auth__panel">
      <div class="panel">
        <button class="back" type="button" @click="handleBack">
          <AppIcon name="chevron-left" size="15" />
          <span>{{ step > 1 ? '上一步' : '返回登录' }}</span>
        </button>

        <ol class="steps">
          <li
            v-for="item in STEPS"
            :key="item.no"
            class="steps__item"
            :class="{ 'is-current': step === item.no, 'is-done': step > item.no }"
            :aria-current="step === item.no ? 'step' : undefined"
          >
            <AppIcon v-if="step > item.no" name="check" size="13" />
            <span v-else class="steps__no mono">{{ item.no }}</span>
            <span class="steps__label">{{ item.label }}</span>
          </li>
        </ol>

        <header class="panel__head">
          <h1 class="panel__title">{{ head.title }}</h1>
          <p class="panel__note">{{ head.note }}</p>
        </header>

        <p v-if="error" class="alert" role="alert">
          <AppIcon name="warning" size="15" />
          <span>{{ error }}</span>
        </p>

        <el-form
          ref="formRef"
          class="form"
          :model="form"
          :rules="rules"
          label-position="top"
          hide-required-asterisk
          @submit.prevent="submit"
        >
          <el-form-item v-if="step === 1" label="账号" prop="username">
            <el-input
              v-model="form.username"
              size="large"
              maxlength="50"
              clearable
              autocomplete="username"
              placeholder="手机号 / 统一社会信用代码"
            >
              <template #prefix>
                <AppIcon name="user" size="15" />
              </template>
            </el-input>
          </el-form-item>

          <template v-if="step === 2">
            <div class="binding">
              <span class="binding__label">绑定邮箱</span>
              <span class="binding__value">{{ maskEmail(boundEmail) }}</span>
              <button class="binding__change" type="button" @click="backToAccount">更换账号</button>
            </div>

            <el-form-item label="邮箱验证码" prop="code">
              <div class="code-row">
                <el-input
                  v-model="form.code"
                  class="code-row__input"
                  size="large"
                  maxlength="6"
                  inputmode="numeric"
                  autocomplete="one-time-code"
                  placeholder="6 位数字"
                />
                <el-button
                  class="code-row__send"
                  :disabled="countdown > 0 || sending"
                  :loading="sending"
                  @click="sendCode"
                >
                  {{ countdown > 0 ? `${countdown} 秒后重发` : '发送验证码' }}
                </el-button>
              </div>
            </el-form-item>
          </template>

          <template v-if="step === 3">
            <el-form-item label="新密码" prop="password">
              <el-input
                v-model="form.password"
                size="large"
                :type="showPassword ? 'text' : 'password'"
                maxlength="20"
                autocomplete="new-password"
                placeholder="6 到 20 位，同时包含字母和数字"
              >
                <template #prefix>
                  <AppIcon name="lock" size="15" />
                </template>
                <template #suffix>
                  <button
                    class="peek"
                    type="button"
                    :title="showPassword ? '隐藏密码' : '显示密码'"
                    :aria-label="showPassword ? '隐藏密码' : '显示密码'"
                    @click="showPassword = !showPassword"
                  >
                    <AppIcon :name="showPassword ? 'hide' : 'view'" size="15" />
                  </button>
                </template>
              </el-input>
              <div v-if="form.password" class="meter" :data-level="strength">
                <span class="meter__bar" />
                <span class="meter__bar" />
                <span class="meter__bar" />
                <span class="meter__label">密码强度 {{ STRENGTH_LABEL[strength] }}</span>
              </div>
            </el-form-item>

            <el-form-item label="确认新密码" prop="confirm">
              <el-input
                v-model="form.confirm"
                size="large"
                :type="showPassword ? 'text' : 'password'"
                maxlength="20"
                autocomplete="new-password"
                placeholder="再次输入新密码"
              >
                <template #prefix>
                  <AppIcon name="lock" size="15" />
                </template>
              </el-input>
            </el-form-item>
          </template>

          <el-button class="form__submit" type="primary" native-type="submit" :loading="loading">
            {{ step === 1 ? '下一步' : step === 2 ? '验证并继续' : '重置密码' }}
          </el-button>
        </el-form>

        <p class="panel__foot">
          想起密码了
          <RouterLink class="link" to="/login">返回登录</RouterLink>
        </p>
      </div>
    </main>
  </div>
</template>

<style scoped>
/* --- shell --------------------------------------------------------------- */

.auth {
  --dense: 1.35;
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(420px, 480px);
  min-height: 100vh;
  background: var(--paper-1);
}

.auth__brand {
  position: relative;
  display: flex;
  align-items: flex-end;
  overflow: hidden;
  padding: var(--space-10);
  background: var(--ink-0);
}

.brand__photo {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: center 40%;
}

.brand__scrim {
  position: absolute;
  inset: 0;
  background:
    linear-gradient(105deg, rgb(8 11 14 / 90%) 0%, rgb(8 11 14 / 68%) 46%, rgb(8 11 14 / 30%) 100%),
    linear-gradient(to top, rgb(8 11 14 / 62%) 0%, transparent 46%);
}

.brand__inner {
  position: relative;
  width: 100%;
  max-width: 520px;
  color: #fff;
}

.brand__link {
  display: inline-flex;
  align-items: center;
  gap: var(--space-3);
  color: #fff;
}

.brand__link:hover {
  text-decoration: none;
}

.brand__mark {
  width: 28px;
  height: 28px;
  object-fit: contain;
}

.brand__name {
  font-size: var(--text-md);
  font-weight: 600;
  letter-spacing: -0.02em;
}

.brand__body {
  margin-top: var(--space-10);
}

.brand__lede {
  font-size: var(--text-lg);
  font-weight: 500;
  line-height: 1.5;
  letter-spacing: -0.02em;
  color: #fff;
}

.brand__spec {
  margin: var(--space-8) 0 0;
  border-top: 1px solid rgb(255 255 255 / 18%);
}

.brand__spec-row {
  display: grid;
  grid-template-columns: 96px minmax(0, 1fr);
  gap: var(--space-4);
  align-items: baseline;
  padding: var(--space-3) 0;
  border-bottom: 1px solid rgb(255 255 255 / 14%);
}

.brand__spec-row dt {
  font-size: var(--text-sm);
  color: rgb(255 255 255 / 62%);
}

.brand__spec-row dd {
  margin: 0;
  font-size: var(--text-sm);
  color: rgb(255 255 255 / 90%);
}

/* --- 表单面 ---------------------------------------------------------------- */

.auth__panel {
  display: flex;
  padding: var(--space-10) var(--space-6);
}

.panel {
  width: 100%;
  max-width: 392px;
  margin: auto;
}

.back {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  height: 30px;
  margin-left: -6px;
  padding: 0 8px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--ink-3);
  font-size: var(--text-sm);
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.back:hover {
  background: var(--paper-2);
  color: var(--ink-0);
}

.steps {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--space-2);
  margin: var(--space-6) 0 0;
  padding: 0;
  list-style: none;
}

.steps__item {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  padding-top: var(--space-2);
  border-top: 2px solid var(--line-2);
  color: var(--ink-3);
  font-size: var(--text-xs);
  white-space: nowrap;
}

.steps__item.is-current,
.steps__item.is-done {
  border-top-color: var(--ink-0);
  color: var(--ink-1);
}

.steps__item.is-current {
  font-weight: 600;
}

.steps__no {
  color: var(--ink-2);
}

.panel__head {
  margin: var(--space-6) 0 var(--space-6);
}

.panel__title {
  font-size: var(--text-xl);
}

.panel__note {
  margin-top: var(--space-2);
  max-width: 34ch;
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.panel__foot {
  margin-top: var(--space-6);
  font-size: var(--text-sm);
  color: var(--ink-3);
}

.link {
  margin-left: var(--space-1);
  color: var(--ink-0);
  font-weight: 500;
}

.link:hover {
  color: var(--signal-amber-deep);
}

.alert {
  display: flex;
  align-items: flex-start;
  gap: var(--space-2);
  margin-bottom: var(--space-5);
  padding: var(--space-3) var(--space-4);
  border-radius: var(--radius-sm);
  background: var(--signal-vermilion-wash);
  color: var(--signal-vermilion-deep);
  font-size: var(--text-sm);
}

.alert :deep(.app-icon) {
  margin-top: 3px;
}

/* --- 表单 ------------------------------------------------------------------ */

.form {
  --el-component-size-large: var(--control-h);
}

.form :deep(.el-form-item) {
  margin-bottom: var(--space-5);
}

.form :deep(.el-form-item__label) {
  margin-bottom: 2px;
}

.form :deep(.el-form-item__error) {
  position: static;
  padding-top: var(--space-1);
  font-size: var(--text-xs);
  line-height: 1.5;
}

.form__submit {
  width: 100%;
  margin-top: var(--space-1);
}

.peek {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 100%;
  border: none;
  background: transparent;
  color: var(--ink-3);
  cursor: pointer;
  transition: color var(--dur-state) ease;
}

.peek:hover {
  color: var(--ink-0);
}

/* --- 绑定邮箱与验证码 ------------------------------------------------------- */

.binding {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-bottom: var(--space-4);
  padding: var(--space-3) var(--space-4);
  border: var(--edge);
  border-radius: var(--radius-xs);
  background: var(--paper-0);
}

.binding__label {
  flex-shrink: 0;
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.binding__value {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: var(--text-sm);
  color: var(--ink-1);
}

.binding__change {
  flex-shrink: 0;
  border: none;
  background: transparent;
  padding: 0;
  color: var(--ink-0);
  font-size: var(--text-sm);
  font-weight: 500;
  cursor: pointer;
}

.binding__change:hover {
  color: var(--signal-amber-deep);
}

.code-row {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  width: 100%;
}

.code-row__input {
  flex: 1 1 auto;
  min-width: 0;
}

.code-row__send {
  flex: 0 0 124px;
  padding-inline: 0;
}

/* --- 密码强度 -------------------------------------------------------------- */

.meter {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  margin-top: var(--space-2);
}

.meter__bar {
  width: 26px;
  height: 3px;
  border-radius: var(--radius-pill);
  background: var(--paper-3);
}

.meter__label {
  margin-left: var(--space-2);
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.meter[data-level='0'] .meter__bar:nth-child(1) {
  background: var(--signal-vermilion);
}

.meter[data-level='1'] .meter__bar:nth-child(-n + 2) {
  background: var(--signal-amber);
}

.meter[data-level='2'] .meter__bar {
  background: var(--signal-teal);
}

/* --- 窄屏 ------------------------------------------------------------------ */

@media (max-width: 900px) {
  .auth {
    grid-template-columns: minmax(0, 1fr);
  }

  .auth__brand {
    align-items: flex-start;
    min-height: 172px;
    padding: var(--space-6) var(--shell-gutter);
  }

  .brand__body {
    margin-top: var(--space-4);
  }

  .brand__lede {
    font-size: var(--text-base);
  }

  .brand__spec {
    display: none;
  }

  .auth__panel {
    padding: var(--space-8) var(--shell-gutter) var(--space-16);
  }

  .panel {
    max-width: none;
  }
}

@media (max-width: 767px) {
  .auth {
    --dense: 1.25;
  }
}

@media (max-width: 560px) {
  .steps__item {
    font-size: var(--text-2xs);
  }

  .code-row {
    flex-wrap: wrap;
  }

  .code-row__input {
    flex: 1 1 100%;
  }

  .code-row__send {
    flex: 1 1 auto;
  }
}
</style>
