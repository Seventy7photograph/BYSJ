<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import { errorText, register } from '@/api/user/auth'

/**
 * 注册页。
 *
 * 账号口径与 user 表一致：个人用户用手机号，企业用户（器材商家）用 18 位统一
 * 社会信用代码；两种身份都要绑邮箱，因为找回密码是唯一的自助恢复路径。
 * 校验都在前端先做一遍，后端报错只作为兜底。
 */
const router = useRouter()

type Identity = 1 | 2

const BRAND_LINES = [
  { key: '个人用户', note: '手机号即账号，可下单、出二手、租器材' },
  { key: '企业商家', note: '统一社会信用代码即账号，需通过平台资质审核' },
] as const

const PHONE_RE = /^1[3-9]\d{9}$/
/** 统一社会信用代码：18 位，字母表去掉 I、O、S、V、Z。 */
const CREDIT_RE = /^[0-9A-HJ-NPQRTUWXY]{2}\d{6}[0-9A-HJ-NPQRTUWXY]{10}$/
const EMAIL_RE = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$/

const STRENGTH_LABEL = ['弱', '中', '强'] as const

const formRef = ref<FormInstance>()
const form = reactive({
  identity: 1 as Identity,
  account: '',
  contactPhone: '',
  email: '',
  password: '',
  confirm: '',
})

const showPassword = ref(false)
const loading = ref(false)
const error = ref('')

const isCompany = computed(() => form.identity === 2)
const accountLabel = computed(() => (isCompany.value ? '统一社会信用代码' : '手机号'))
const accountPlaceholder = computed(() =>
  isCompany.value ? '请输入 18 位统一社会信用代码' : '请输入 11 位手机号',
)

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

function accountError(value: string): string {
  if (!value) return ''
  if (isCompany.value) {
    return CREDIT_RE.test(value) ? '' : '统一社会信用代码为 18 位大写字母与数字'
  }
  return PHONE_RE.test(value) ? '' : '手机号格式不正确，应为 11 位数字且以 1 开头'
}

function passwordError(value: string): string {
  if (!value) return ''
  if (/\s/.test(value)) return '密码不能包含空格'
  if (value.length < 6 || value.length > 20) return '密码长度为 6 到 20 位'
  if (!/[A-Za-z]/.test(value) || !/\d/.test(value)) return '密码需同时包含字母和数字'
  return ''
}

const rules = computed<FormRules>(() => ({
  account: [
    {
      required: true,
      message: isCompany.value ? '请输入统一社会信用代码' : '请输入手机号',
      trigger: 'blur',
    },
    {
      validator: (_rule, value, callback) => {
        const message = accountError(String(value ?? '').trim())
        callback(message ? new Error(message) : undefined)
      },
      trigger: 'blur',
    },
  ],
  contactPhone: isCompany.value
    ? [
        { required: true, message: '请输入联系人手机号', trigger: 'blur' },
        {
          pattern: PHONE_RE,
          message: '手机号格式不正确，应为 11 位数字且以 1 开头',
          trigger: 'blur',
        },
      ]
    : [],
  email: [
    { required: true, message: '请输入邮箱，找回密码需要用到', trigger: 'blur' },
    {
      validator: (_rule, value, callback) => {
        const text = String(value ?? '').trim()
        callback(
          text && !EMAIL_RE.test(text)
            ? new Error('邮箱格式不正确，例如 name@example.com')
            : undefined,
        )
      },
      trigger: 'blur',
    },
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    {
      validator: (_rule, value, callback) => {
        const message = passwordError(String(value ?? ''))
        callback(message ? new Error(message) : undefined)
      },
      trigger: 'blur',
    },
  ],
  confirm: [
    { required: true, message: '请再次输入密码', trigger: 'blur' },
    {
      validator: (_rule, value, callback) => {
        callback(value === form.password ? undefined : new Error('两次输入的密码不一致'))
      },
      trigger: ['blur', 'change'],
    },
  ],
}))

/** 切换身份只清掉与身份绑定的账号字段，已填的密码和邮箱留着。 */
function changeIdentity(next: Identity) {
  if (form.identity === next) return
  form.identity = next
  form.account = ''
  form.contactPhone = ''
  formRef.value?.clearValidate(['account', 'contactPhone'])
}

async function validate(): Promise<boolean> {
  try {
    return (await formRef.value?.validate()) ?? false
  } catch {
    return false
  }
}

/** user.nickname 非空且没有默认值，按表里的约定给一个「用户_六位数字」。 */
function randomNickname(): string {
  return `用户_${String(Math.floor(Math.random() * 1_000_000)).padStart(6, '0')}`
}

async function submit() {
  if (loading.value) return
  error.value = ''
  if (!(await validate())) return

  const account = form.account.trim()
  const email = form.email.trim()
  loading.value = true
  try {
    const res = await register({
      userType: form.identity,
      username: account,
      nickname: randomNickname(),
      password: form.password,
      email,
      phone: isCompany.value ? form.contactPhone.trim() : account,
    })

    if (res.code === 200) {
      ElMessage.success('注册成功，请使用该账号登录')
      router.push({ path: '/login', query: { username: account } })
      return
    }
    error.value = res.msg || '注册失败，请检查填写内容后重试'
  } catch (e) {
    error.value = errorText(e, '注册失败，请稍后重试')
  } finally {
    loading.value = false
  }
}

function handleBack() {
  if (window.history.length > 1) {
    router.back()
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
          <p class="brand__lede">个人用户手机号注册，企业商家需通过资质审核。</p>
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
          <span>返回</span>
        </button>

        <header class="panel__head">
          <h1 class="panel__title">账号注册</h1>
          <p class="panel__note">选择账号身份后填写资料，账号名一旦注册不能修改。</p>
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
          :validate-on-rule-change="false"
          hide-required-asterisk
          @submit.prevent="submit"
        >
          <div class="field">
            <span class="field__label">账号身份</span>
            <div class="seg" role="radiogroup" aria-label="账号身份">
              <button
                class="seg__item"
                type="button"
                role="radio"
                :aria-checked="!isCompany"
                :class="{ 'is-active': !isCompany }"
                @click="changeIdentity(1)"
              >
                个人用户
              </button>
              <button
                class="seg__item"
                type="button"
                role="radio"
                :aria-checked="isCompany"
                :class="{ 'is-active': isCompany }"
                @click="changeIdentity(2)"
              >
                企业商家
              </button>
            </div>
          </div>

          <el-form-item :label="accountLabel" prop="account">
            <el-input
              v-model="form.account"
              size="large"
              maxlength="50"
              clearable
              autocomplete="username"
              :placeholder="accountPlaceholder"
            >
              <template #prefix>
                <AppIcon :name="isCompany ? 'id' : 'user'" size="15" />
              </template>
            </el-input>
          </el-form-item>

          <el-form-item v-if="isCompany" label="联系人手机号" prop="contactPhone">
            <el-input
              v-model="form.contactPhone"
              size="large"
              maxlength="11"
              clearable
              autocomplete="tel"
              placeholder="用于订单与审核联系"
            >
              <template #prefix>
                <AppIcon name="service" size="15" />
              </template>
            </el-input>
          </el-form-item>

          <el-form-item label="邮箱" prop="email">
            <el-input
              v-model="form.email"
              size="large"
              maxlength="100"
              clearable
              autocomplete="email"
              placeholder="用于找回密码"
            >
              <template #prefix>
                <AppIcon name="message" size="15" />
              </template>
            </el-input>
          </el-form-item>

          <el-form-item label="密码" prop="password">
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

          <el-form-item label="确认密码" prop="confirm">
            <el-input
              v-model="form.confirm"
              size="large"
              :type="showPassword ? 'text' : 'password'"
              maxlength="20"
              autocomplete="new-password"
              placeholder="再次输入密码"
            >
              <template #prefix>
                <AppIcon name="lock" size="15" />
              </template>
            </el-input>
          </el-form-item>

          <el-button class="form__submit" type="primary" native-type="submit" :loading="loading">
            提交注册
          </el-button>
        </el-form>

        <p class="panel__foot">
          已有账号
          <RouterLink class="link" to="/login">去登录</RouterLink>
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
  grid-template-columns: 84px minmax(0, 1fr);
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

.panel__head {
  margin: var(--space-8) 0 var(--space-6);
}

.panel__title {
  font-size: var(--text-xl);
}

.panel__note {
  margin-top: var(--space-2);
  max-width: 32ch;
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

.field {
  margin-bottom: var(--space-5);
}

.field__label {
  display: block;
  margin-bottom: var(--space-2);
  color: var(--ink-2);
  font-size: var(--text-sm);
  font-weight: 500;
}

.seg {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 2px;
  padding: 2px;
  border: var(--edge);
  border-radius: var(--radius-xs);
  background: var(--paper-2);
}

.seg__item {
  height: calc(var(--control-h) - 6px);
  border: none;
  border-radius: var(--radius-xs);
  background: transparent;
  color: var(--ink-2);
  font-size: var(--text-base);
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.seg__item:hover {
  color: var(--ink-0);
}

.seg__item.is-active {
  background: var(--paper-0);
  color: var(--ink-0);
  font-weight: 600;
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

  .panel__head {
    margin-top: var(--space-6);
  }
}

@media (max-width: 767px) {
  .auth {
    --dense: 1.25;
  }
}
</style>
