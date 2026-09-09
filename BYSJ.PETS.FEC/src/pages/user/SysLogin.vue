<template>
<div class="login-container">
    <!-- 左侧品牌展示区 -->
    <div class="login-banner">
      <div class="banner-content">
        <div class="glass-title-container">
          <h1 class="brand-name">摄影器材交易系统</h1>
          <p class="brand-desc">高效、稳定、易用的交易系统</p>
        </div>
        <div class="decorative-element"></div>
      </div>
    </div>

    <!-- 右侧登录表单区 -->
    <div class="login-form-wrapper">
      <div class="back-button-container">
        <el-button type="text" class="back-button" @click="handleBack">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
      </div>
      <div class="form-card">
        <h2 class="form-title">账号登录</h2>
        <el-form ref="loginFormRef" :model="loginForm" :rules="loginRules" label-width="0px" class="login-form">
          <!-- 表单内容 -->
          <el-form-item prop="username">
            <el-input v-model="loginForm.username" placeholder="请输入用户名/手机号" :maxlength="20" clearable>
              <template #prefix>
                <el-icon class="el-input__icon"><User /></el-icon>
              </template>
            </el-input>
          </el-form-item>

          <el-form-item prop="password" @keyup.enter="handleLogin">
            <el-input v-model="loginForm.password" placeholder="请输入密码" :type="showPassword ? 'text' : 'password'" :maxlength="20" clearable>
              <template #prefix>
                <el-icon class="el-input__icon"><Lock /></el-icon>
              </template>
              <template #suffix>
                <el-icon @click="showPassword = !showPassword" class="password-toggle">
                  <View v-if="showPassword"/>
                  <Hide v-else />
                </el-icon>
              </template>
            </el-input>
          </el-form-item>

          <el-form-item prop="captcha" @keyup.enter="handleLogin">
            <div class="captcha-container">
              <el-input
                v-model="loginForm.captcha"
                placeholder="请输入验证码"
                :maxlength="4"
                clearable
                class="captcha-input"
              >
                <template #prefix>
                  <el-icon class="el-input__icon"><Key /></el-icon>
                </template>
              </el-input>
              <div class="captcha-image-container">
                <img
                  :src="captchaImage"
                  alt="验证码"
                  class="captcha-image"
                  @click="refreshCaptcha"
                >
                <el-icon class="refresh-icon" @click="refreshCaptcha">
                  <Refresh />
                </el-icon>
              </div>
            </div>
          </el-form-item>

          <div class="form-actions">
            <el-checkbox v-model="loginForm.rememberMe" label="记住密码" size="small" />
            <el-link type="primary" size="small" @click="handleForgotPassword">忘记密码?</el-link>
          </div>

          <el-form-item>
            <el-button
              type="primary"
              class="login-btn"
              :loading="isLoading"
              @click="handleLogin"
              block
            >
              登录
            </el-button>
          </el-form-item>

          <div class="register-link">
            还没有账号?
            <el-link type="primary" @click="handleRegister">立即注册</el-link>
          </div>
        </el-form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { ElForm, ElFormItem, ElInput, ElButton, ElCheckbox, ElLink, ElIcon, ElMessage } from 'element-plus';
import 'element-plus/es/components/message/style/css';
import { User, Lock, View, Hide ,Key,ArrowLeft, Refresh} from '@element-plus/icons-vue';
import service from '@/axios'
import type { AxiosError } from 'axios'
import { useUserStore } from '@/stores/user'
import { user } from '@/api'

const router = useRouter();

const handleBack = () => {
  if (window.history.length > 1) {
    router.back();
  } else {
    router.push('/index');
  }
};

// 自定义API响应类型
interface ApiResponse<T = any> {
  code: number;
  msg?: string;
  data: T;
}

interface LoginForm {
  username: string;
  password: string;
  captcha: string;
  rememberMe: boolean;
}

const loginFormRef = ref<InstanceType<typeof ElForm> | null>(null);
const loginForm = ref<LoginForm>({
  // username: '52440000799352866W',
  username: '',
  password: '',
  captcha: '',
  rememberMe: false
});

const captchaImage = ref('');
const captchaKey = ref('');
const showPassword = ref(false);
const isLoading = ref(false);

const loginRules = ref({
  username: [
    { required: true, message: '请输入用户名/手机号', trigger: 'blur' },
    { min: 3, max: 20, message: '长度在 3 到 20 个字符之间', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 20, message: '长度在 6 到 20 个字符之间', trigger: 'blur' }
  ],
  captcha: [
    { required: true, message: '请输入验证码', trigger: 'blur' },
    { len: 4, message: '验证码长度为4个字符', trigger: 'blur' }
  ]
});

onMounted(() => {
  const savedUser = localStorage.getItem('rememberedUser');
  if (savedUser) {
    const { username, password } = JSON.parse(savedUser);
    loginForm.value.username = username;
    loginForm.value.password = password;
    loginForm.value.rememberMe = true;
  }
  refreshCaptcha();
});

const refreshCaptcha = async () => {
  try {
    const res = await service.get('/captcha');
    console.log('获取验证码响应:', res);
    if ((res as any).code === 200) {
      captchaImage.value = (res as any).data.image;
      captchaKey.value = (res as any).data.key;
    } else {
      ElMessage.error('获取验证码失败');
    }
  } catch (error) {
    console.error('获取验证码失败', error);
    ElMessage.error('获取验证码失败，请重试');
  }
};

const handleLogin = async () => {
  try {
    if (!loginForm.value.username || !loginForm.value.password) {
      ElMessage.error('请输入账号和密码！');
      return;
    }

    // 使用user.auth API模块进行登录
    const res = await user.auth.login({
      username: loginForm.value.username,
      password: loginForm.value.password,
      captcha: loginForm.value.captcha,
      captchaKey: captchaKey.value
    });

    if (res.code === 200) {
      console.log('登录成功，后端返回的数据结构:', res);
      const userStore = useUserStore();

      // 设置token到axios实例的默认请求头
      service.defaults.headers.common['Authorization'] = `Bearer ${res.data}`;

      // 如果记住密码，保存用户名和密码到localStorage
      if (loginForm.value.rememberMe) {
        localStorage.setItem('rememberedUser', JSON.stringify({
          username: loginForm.value.username,
          password: loginForm.value.password
        }));
      } else {
        // 如果取消记住密码，移除localStorage中的用户信息
        localStorage.removeItem('rememberedUser');
      }

      try {
        // 获取完整用户信息后再进行角色跳转
        const userData = await user.auth.getCurrentUser();
        console.log('从getCurrentUser接口获取的用户数据:', userData);

        if (userData.code === 200) {
          const userInfo = {
            userId: userData.data.userId,
            username: userData.data.username,
            role_type: userData.data.userType, // 使用userType字段作为角色标识
            nickname: userData.data.nickname,
            avatarUrl: userData.data.avatarUrl,
            ...userData.data
          };

          console.log('最终用户信息:', userInfo);

          // 调用userStore.login()设置token和用户信息，并根据角色跳转
          userStore.login(res.data, userInfo);
        } else {
          // 如果获取用户信息失败，使用默认用户信息
          const tempUserInfo = {
            userId: '',
            username: loginForm.value.username,
            role_type: 1 // 默认普通用户角色
          };
          userStore.login(res.data, tempUserInfo);
        }
      } catch (error) {
        console.error('获取用户信息失败，使用默认用户信息', error);
        // 如果获取用户信息失败，使用默认用户信息
        const tempUserInfo = {
          userId: '',
          username: loginForm.value.username,
          role_type: 1 // 默认普通用户角色
        };
        userStore.login(res.data, tempUserInfo);
      }
    } else {
      loginForm.value.captcha = '';
      refreshCaptcha();
      ElMessage.error(res.msg || '登录失败！');
    }

  } catch (error) {
    refreshCaptcha();
    const err = error as AxiosError<{ msg?: string }>;
    console.error('登录请求失败：', err);

    if (err.response) {
      const errorMsg = err.response.data?.msg || '服务器错误';
      ElMessage.error(`登录失败：${errorMsg}`);
    } else if (err.request) {
      ElMessage.error('登录失败：无法连接服务器，请检查接口地址或网络！');
    } else {
      ElMessage.error(`登录失败：${err.message}`);
    }
  }
};

const handleForgotPassword = () => {
  ElMessage.info('前往密码找回页面');
  router.push('/forgot-password');
};

const handleRegister = () => {
  router.push('/register');
};
</script>

<style scoped>
/* 全局容器样式 */
.login-container {
  display: flex;
  height: 100vh;
  width: 100%;
  overflow: hidden;
}

/* 左侧banner样式 */
.login-banner {
  flex: 1;
  background-image: url('../../public/ZSJ_6847-Pano-2.jpg');
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  height: 100vh;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 50px;
  position: relative;
  overflow: hidden;
}

/* 右侧表单区域样式 */
.login-form-wrapper {
  flex: 0 0 420px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f8f9fa;
  padding: 0 20px;
  position: relative;
}

.glass-title-container {
  background: rgba(255, 255, 255, 0.03);
  backdrop-filter: blur(5px);
  -webkit-backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 16px;
  padding: 30px 40px;
  box-shadow: 0 4px 20px rgba(16, 65, 222, 0.08);
  margin-bottom: 250px;
}

.banner-content {
  z-index: 1;
}

.brand-name {
  font-size: 80px;
  font-weight: 600;
  margin-bottom: 20px;
  letter-spacing: 15px;
  color: rgba(255, 255, 255, 1);
  text-shadow: 0 2px 6px rgba(0, 0, 0, 0.05);
  text-align: center;
}

.brand-desc {
  font-size: 18px;
  opacity: 0.85;
  line-height: 1.8;
  color: #333;
  text-align: center;
  margin: 0;
}

.decorative-element {
  width: 200px;
  height: 200px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  position: absolute;
  bottom: -50px;
  right: -50px;
  filter: blur(50px);
}

.back-button-container {
  position: absolute;
  top: 20px;
  left: 20px;
  z-index: 10;
}

.back-button {
  color: #165DFF;
  font-size: 16px;
  padding: 8px 16px;
  border: 1px solid #E5E6EB;
  border-radius: 8px;
  background: white;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.back-button:hover {
  background: #F2F3F5;
  border-color: #165DFF;
  color: #165DFF;
}

.form-card {
  width: 100%;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  padding: 40px 30px;
  transition: all 0.3s ease;
}

.form-card:hover {
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.12);
}

.form-title {
  font-size: 24px;
  font-weight: 600;
  text-align: center;
  margin-bottom: 30px;
  color: #1989fa;
}

.login-form {
  width: 100%;
  max-width: 350px;
  margin: 0 auto;
}

.el-input {
  border-radius: 8px;
  margin-bottom: 2px;
  height: 48px !important;
}

.el-input__prefix {
  color: #8c9eff;
}

.password-toggle {
  cursor: pointer;
  color: #8c9eff;
  transition: color 0.2s;
}

.password-toggle:hover {
  color: #165dff;
}

.form-actions {
  display: flex;
  justify-content: space-between;
  margin: 10px 0 25px;
}

.login-btn {
  height: 48px;
  width: 100%;
  font-size: 16px;
  border-radius: 8px;
  background: linear-gradient(135deg, #165DFF 0%, #0E42D2 100%);
  border: none;
  padding: 0 20px;
}

.login-btn:hover {
  background: linear-gradient(135deg, #0E42D2 0%, #165DFF 100%);
}

.register-link {
  text-align: center;
  margin-top: 20px;
  font-size: 14px;
  color: #666;
}

.captcha-container {
  display: flex;
  gap: 10px;
}

.captcha-input {
  flex: 1;
}

.captcha-image-container {
  position: relative;
  width: 120px;
  height: 40px;
}

.captcha-image {
  width: 100%;
  height: 100%;
  border-radius: 8px;
  cursor: pointer;
  object-fit: cover;
}

.refresh-icon {
  position: absolute;
  right: -8px;
  top: -8px;
  background-color: white;
  border-radius: 50%;
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 12px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

@media (max-width: 768px) {
  .glass-title-container {
    padding: 20px 30px;
    width: 90%;
    margin: 0 auto 20px;
  }

  .login-container {
    flex-direction: column;
  }

  .login-banner {
    flex: 0 0 200px;
    padding: 0 20px;
  }

  .brand-name {
    font-size: 36px;
  }

  .brand-desc {
    font-size: 16px;
  }

  .login-form-wrapper {
    flex: 1;
    width: 100%;
    padding: 20px;
  }

  .form-card {
    padding: 30px 20px;
  }
}
</style>
