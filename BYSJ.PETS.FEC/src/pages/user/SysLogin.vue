<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import { useUserStore } from '@/stores/user'
import { errorText, getCaptcha, getCurrentUser, login } from '@/api/user/auth'

/**
 * 登录页。
 *
 * 与原实现的差别：
 * - 背景换成 public/media/hero-skyline.jpg：原图 13MB，而且写的是 `../../public`
 *   相对路径，嵌套路由下取不到；
 * - 验证码走 GET /captcha。后端校验过一次即从 Redis 删除，所以任何登录失败都
 *   重新取一张，不会拿旧图重试；
 * - 登录成功后只调用 store.login(token, userInfo)，角色分流在 store 里，
 *   页面不再自己 push，避免双重导航；
 * - 会话落盘由 store 负责，页面只维护「记住密码」的账号预填。
 */
const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const BRAND_LINES = [
  { key: '全新零售', note: '平台审核通过后上架，支持开发票' },
  { key: '二手流转', note: '单件库存，成色与瑕疵随商品标注' },
  { key: '器材租赁', note: '按天计价，押金与租期随商品标注' },
] as const

const formRef = ref<FormInstance>()
const form = reactive({
  username: '',
  password: '',
  captcha: '',
  remember: false,
})

const rules: FormRules = {
  username: [
    { required: true, message: '请输入账号', trigger: 'blur' },
    { min: 3, max: 50, message: '账号长度为 3 到 50 个字符', trigger: 'blur' },
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 20, message: '密码长度为 6 到 20 位', trigger: 'blur' },
  ],
  captcha: [
    { required: true, message: '请输入图中 4 位验证码', trigger: 'blur' },
    { len: 4, message: '验证码为 4 位字母或数字', trigger: 'blur' },
  ],
}

const showPassword = ref(false)
const loading = ref(false)
const error = ref('')

const captchaImage = ref('')
const captchaKey = ref('')
const captchaLoading = ref(false)
const captchaFailed = ref(false)

/** 请求一条新验证码。旧图无论是否用过都作废，输入框一并清空。 */
async function refreshCaptcha() {
  captchaLoading.value = true
  try {
    const res = await getCaptcha()
    if (res.code === 200 && res.data?.image) {
      captchaImage.value = res.data.image
      captchaKey.value = res.data.key
      captchaFailed.value = false
      form.captcha = ''
    } else if (res.code !== 200) {
      captchaFailed.value = true
    }
    // 被重复请求拦截取消的那次会 resolve 一个空对象，不算失败。
  } catch {
    captchaFailed.value = true
  } finally {
    captchaLoading.value = false
  }
}

async function validate(): Promise<boolean> {
  try {
    return (await formRef.value?.validate()) ?? false
  } catch {
    return false
  }
}

function handleBack() {
  if (window.history.length > 1) {
    router.back()
  } else {
    router.push('/index')
  }
}

async function submit() {
  if (loading.value) return
  error.value = ''
  if (!(await validate())) return

  if (!captchaKey.value) {
    await refreshCaptcha()
    error.value = '验证码未加载，请填写重新获取的验证码后再登录'
    return
  }

  const account = form.username.trim()
  loading.value = true
  try {
    const res = await login({
      username: account,
      password: form.password,
      captcha: form.captcha.trim(),
      captchaKey: captchaKey.value,
    })

    if (res.code !== 200 || typeof res.data !== 'string') {
      form.captcha = ''
      void refreshCaptcha()
      error.value = res.msg || '登录失败，请检查账号与密码后重试'
      return
    }

    if (form.remember) {
      localStorage.setItem(
        'rememberedUser',
        JSON.stringify({ username: account, password: form.password }),
      )
    } else {
      localStorage.removeItem('rememberedUser')
    }

    // store 需要 roleType 决定进哪个工作台，用刚拿到的 token 取一次用户信息。
    let info: Record<string, unknown> = { username: account, role_type: 1 }
    try {
      const profile = await getCurrentUser(res.data)
      if (profile.code === 200 && profile.data) {
        info = { ...profile.data, role_type: profile.data.userType }
      }
    } catch {
      // 取不到用户信息不阻断登录，store 会按默认角色回到首页。
      ElMessage.warning('已登录，但用户信息未能加载，请刷新页面重试')
    }

    userStore.login(res.data, info)
  } catch (e) {
    form.captcha = ''
    void refreshCaptcha()
    error.value = errorText(e, '登录失败，请稍后重试')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  const saved = localStorage.getItem('rememberedUser')
  if (saved) {
    try {
      const parsed = JSON.parse(saved) as { username?: string; password?: string }
      form.username = parsed.username ?? ''
      form.password = parsed.password ?? ''
      form.remember = Boolean(form.username)
    } catch {
      // 存坏了就当没记住，避免一直读到一个坏值。
      localStorage.removeItem('rememberedUser')
    }
  } else if (typeof route.query.username === 'string') {
    form.username = route.query.username
  }
  void refreshCaptcha()
})
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
          <p class="brand__lede">摄影器材的全新零售、二手流转与器材租赁。</p>
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
          <h1 class="panel__title">账号登录</h1>
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
          <el-form-item label="账号" prop="username">
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

          <el-form-item label="密码" prop="password">
            <el-input
              v-model="form.password"
              size="large"
              :type="showPassword ? 'text' : 'password'"
              maxlength="20"
              autocomplete="current-password"
              placeholder="登录密码"
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
          </el-form-item>

          <el-form-item label="验证码" prop="captcha">
            <div class="captcha">
              <el-input
                v-model="form.captcha"
                class="captcha__input"
                size="large"
                maxlength="4"
                autocomplete="off"
                placeholder="4 位字母或数字"
              />
              <button
                class="captcha__tile"
                type="button"
                title="换一张验证码"
                aria-label="换一张验证码"
                @click="refreshCaptcha"
              >
                <img v-if="captchaImage" :src="captchaImage" alt="" />
                <span v-else class="captcha__fallback">
                  {{ captchaFailed ? '点击重试' : '加载中' }}
                </span>
              </button>
              <button
                class="icon-btn"
                type="button"
                title="刷新验证码"
                aria-label="刷新验证码"
                :disabled="captchaLoading"
                @click="refreshCaptcha"
              >
                <AppIcon name="refresh" size="16" />
              </button>
            </div>
          </el-form-item>

          <div class="form__row">
            <el-checkbox v-model="form.remember">记住密码</el-checkbox>
            <RouterLink class="link" to="/forgot-password">忘记密码</RouterLink>
          </div>

          <el-button class="form__submit" type="primary" native-type="submit" :loading="loading">
            登录
          </el-button>
        </el-form>

        <p class="panel__foot">
          还没有账号
          <RouterLink class="link" to="/register">立即注册</RouterLink>
        </p>
      </div>
    </main>
  </div>
</template>

<style scoped>
/* --- shell --------------------------------------------------------------- */

.auth {
  /* 认证页服务全部角色，沿用买家的密度节奏；窄屏再放松一点，保证触控高度。 */
  --dense: 1.35;
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(420px, 480px);
  min-height: 100vh;
  background: var(--paper-1);
}

/* --- 品牌面：真实照片承载，文字直接压在图上 ---------------------------------- */

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

/* 错误文案留在文档流里，长文案换行时不会压住下一个字段。 */
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

.form__row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-3);
  margin: var(--space-1) 0 var(--space-6);
}

.form__row .link {
  margin-left: 0;
  font-size: var(--text-sm);
}

.form__submit {
  width: 100%;
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

/* --- 验证码 ---------------------------------------------------------------- */

.captcha {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  width: 100%;
}

.captcha__input {
  flex: 1 1 auto;
  min-width: 0;
}

.captcha__tile {
  flex: 0 0 104px;
  display: flex;
  align-items: center;
  justify-content: center;
  height: var(--control-h);
  padding: 0;
  overflow: hidden;
  border: var(--edge);
  border-radius: var(--radius-xs);
  background: var(--paper-0);
  cursor: pointer;
}

.captcha__tile img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.captcha__fallback {
  font-size: var(--text-xs);
  color: var(--ink-3);
}

.icon-btn {
  flex: 0 0 auto;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: var(--control-h);
  height: var(--control-h);
  border: var(--edge);
  border-radius: var(--radius-xs);
  background: var(--paper-0);
  color: var(--ink-2);
  cursor: pointer;
  transition:
    border-color var(--dur-state) ease,
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.icon-btn:hover {
  border-color: var(--ink-4);
  background: var(--paper-1);
  color: var(--ink-0);
}

.icon-btn:disabled {
  color: var(--ink-4);
  cursor: progress;
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

@media (max-width: 520px) {
  .captcha {
    flex-wrap: wrap;
  }

  .captcha__input {
    flex: 1 1 100%;
  }

  .captcha__tile {
    flex: 0 0 132px;
  }
}
</style>
