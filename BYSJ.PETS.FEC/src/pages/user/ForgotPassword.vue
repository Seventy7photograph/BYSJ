<template>
  <div class="forgot-password-container">
    <!-- 左侧品牌展示区 -->
    <div class="forgot-password-banner">
      <div class="banner-content">
        <div class="glass-title-container">
          <h1 class="brand-name">摄影器材交易系统</h1>
          <p class="brand-desc">高效、稳定、易用的交易系统</p>
        </div>
        <div class="decorative-element"></div>
      </div>
    </div>

    <!-- 右侧表单区 -->
    <div class="forgot-password-form-wrapper">
      <div class="back-button-container">
        <el-button type="text" class="back-button" @click="handleBack">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
      </div>
      <div class="form-card">
        <h2 class="form-title">忘记密码</h2>
        <el-form ref="forgotFormRef" :model="forgotForm" :rules="forgotRules" label-width="0px" class="forgot-password-form">
          <!-- 步骤1：输入用户名/手机号 -->
          <el-form-item v-if="currentStep === 1" prop="username">
            <el-input v-model="forgotForm.username" placeholder="请输入用户名/手机号" :maxlength="20" clearable>
              <template #prefix>
                <el-icon class="el-input__icon"><User /></el-icon>
              </template>
            </el-input>
          </el-form-item>

          <!-- 步骤2：输入邮箱和验证码 -->
          <template v-if="currentStep === 2">
            <el-form-item prop="email">
              <el-input v-model="forgotForm.email" placeholder="请输入绑定的邮箱" :maxlength="100" clearable>
                <template #prefix>
                  <el-icon class="el-input__icon"><Message /></el-icon>
                </template>
              </el-input>
            </el-form-item>

            <el-form-item prop="verificationCode">
              <div class="verification-code-container">
                <el-input
                  v-model="forgotForm.verificationCode"
                  placeholder="请输入验证码"
                  :maxlength="6"
                  clearable
                  class="verification-code-input"
                >
                  <template #prefix>
                    <el-icon class="el-input__icon"><Key /></el-icon>
                  </template>
                </el-input>
                <el-button
                  type="primary"
                  class="send-code-btn"
                  :disabled="countdown > 0"
                  @click="sendVerificationCode"
                >
                  {{ countdown > 0 ? `${countdown}秒后重发` : '发送验证码' }}
                </el-button>
              </div>
            </el-form-item>
          </template>

          <!-- 步骤3：重置密码 -->
          <template v-if="currentStep === 3">
            <el-form-item prop="newPassword">
              <el-input v-model="forgotForm.newPassword" placeholder="请输入新密码" :type="showPassword ? 'text' : 'password'" :maxlength="20" clearable>
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

            <el-form-item prop="confirmPassword">
              <el-input v-model="forgotForm.confirmPassword" placeholder="请确认新密码" :type="showPassword ? 'text' : 'password'" :maxlength="20" clearable>
                <template #prefix>
                  <el-icon class="el-input__icon"><Lock /></el-icon>
                </template>
              </el-input>
            </el-form-item>
          </template>

          <el-form-item>
            <el-button
              type="primary"
              class="submit-btn"
              :loading="isLoading"
              @click="handleSubmit"
              block
            >
              {{ currentStep === 1 ? '下一步' : currentStep === 2 ? '验证并下一步' : '重置密码' }}
            </el-button>
          </el-form-item>

          <div class="login-link">
            想起密码了?
            <el-link type="primary" @click="handleLogin">返回登录</el-link>
          </div>
        </el-form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue';
import { useRouter } from 'vue-router';
import { ElForm, ElFormItem, ElInput, ElButton, ElLink, ElIcon, ElMessage } from 'element-plus';
import 'element-plus/es/components/message/style/css';
import { User, Lock, View, Hide, Key, ArrowLeft, Message, Refresh } from '@element-plus/icons-vue';
import service from '@/axios'
import type { AxiosError } from 'axios'
import { user } from '@/api'

const router = useRouter();

const handleBack = () => {
  if (currentStep > 1) {
    currentStep.value--;
  } else {
    router.push('/login');
  }
};

const handleLogin = () => {
  router.push('/login');
};

interface ForgotForm {
  username: string;
  email: string;
  verificationCode: string;
  newPassword: string;
  confirmPassword: string;
}

const forgotFormRef = ref<InstanceType<typeof ElForm> | null>(null);
const forgotForm = reactive<ForgotForm>({
  username: '',
  email: '',
  verificationCode: '',
  newPassword: '',
  confirmPassword: ''
});

const currentStep = ref(1);
const isLoading = ref(false);
const showPassword = ref(false);
const countdown = ref(0);

const forgotRules = reactive({
  username: [
    { required: true, message: '请输入用户名/手机号', trigger: 'blur' },
    { min: 3, max: 20, message: '长度在 3 到 20 个字符之间', trigger: 'blur' }
  ],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱格式', trigger: ['blur', 'change'] }
  ],
  verificationCode: [
    { required: true, message: '请输入验证码', trigger: 'blur' },
    { len: 6, message: '验证码长度为6个字符', trigger: 'blur' }
  ],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, max: 20, message: '长度在 6 到 20 个字符之间', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    { min: 6, max: 20, message: '长度在 6 到 20 个字符之间', trigger: 'blur' },
    {
      validator: (rule: any, value: string, callback: any) => {
        if (value !== forgotForm.newPassword) {
          callback(new Error('两次输入的密码不一致'));
        } else {
          callback();
        }
      },
      trigger: 'blur'
    }
  ]
});

const sendVerificationCode = async () => {
  try {
    if (!forgotForm.email) {
      ElMessage.error('请输入邮箱');
      return;
    }

    isLoading.value = true;
    const res = await user.auth.sendResetPasswordCode({
      email: forgotForm.email
    });

    if (res.code === 200) {
      ElMessage.success('验证码已发送，请注意查收');
      startCountdown();
    } else {
      ElMessage.error(res.msg || '发送验证码失败');
    }
  } catch (error) {
    console.error('发送验证码失败', error);
    ElMessage.error('发送验证码失败，请重试');
  } finally {
    isLoading.value = false;
  }
};

const startCountdown = () => {
  countdown.value = 60;
  const timer = setInterval(() => {
    countdown.value--;
    if (countdown.value <= 0) {
      clearInterval(timer);
    }
  }, 1000);
};

const handleSubmit = async () => {
  try {
    await forgotFormRef.value?.validate();
    isLoading.value = true;

    if (currentStep.value === 1) {
      // 验证用户是否存在并获取邮箱
      const res = await user.auth.checkUser({
        username: forgotForm.username
      });

      if (res.code === 200) {
        forgotForm.email = res.data.email;
        currentStep.value = 2;
      } else {
        ElMessage.error(res.msg || '用户不存在');
      }
    } else if (currentStep.value === 2) {
      // 验证验证码
      const res = await user.auth.verifyResetPasswordCode({
        email: forgotForm.email,
        code: forgotForm.verificationCode
      });

      if (res.code === 200) {
        currentStep.value = 3;
      } else {
        ElMessage.error(res.msg || '验证码错误');
      }
    } else if (currentStep.value === 3) {
      // 重置密码
            const res = await user.auth.resetPassword({
              username: forgotForm.username,
              email: forgotForm.email,
              code: forgotForm.verificationCode,
              newPassword: forgotForm.newPassword
            });

      if (res.code === 200) {
        ElMessage.success('密码重置成功，请登录');
        router.push('/login');
      } else {
        ElMessage.error(res.msg || '密码重置失败');
      }
    }
  } catch (error) {
    console.error('操作失败', error);
    const err = error as AxiosError<{ msg?: string }>;
    if (err.response) {
      ElMessage.error(err.response.data?.msg || '操作失败');
    } else {
      ElMessage.error('操作失败，请重试');
    }
  } finally {
    isLoading.value = false;
  }
};
</script>

<style scoped>
/* 全局容器样式 */
.forgot-password-container {
  display: flex;
  height: 100vh;
  width: 100%;
  overflow: hidden;
}

/* 左侧banner样式 */
.forgot-password-banner {
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
.forgot-password-form-wrapper {
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

.forgot-password-form {
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

.submit-btn {
  height: 48px;
  width: 100%;
  font-size: 16px;
  border-radius: 8px;
  background: linear-gradient(135deg, #165DFF 0%, #0E42D2 100%);
  border: none;
  padding: 0 20px;
  margin-top: 10px;
}

.submit-btn:hover {
  background: linear-gradient(135deg, #0E42D2 0%, #165DFF 100%);
}

.login-link {
  text-align: center;
  margin-top: 20px;
  font-size: 14px;
  color: #666;
}

.verification-code-container {
  display: flex;
  gap: 10px;
}

.verification-code-input {
  flex: 1;
}

.send-code-btn {
  width: 120px;
  height: 48px;
  font-size: 14px;
  border-radius: 8px;
}

@media (max-width: 768px) {
  .glass-title-container {
    padding: 20px 30px;
    width: 90%;
    margin: 0 auto 20px;
  }

  .forgot-password-container {
    flex-direction: column;
  }

  .forgot-password-banner {
    flex: 0 0 200px;
    padding: 0 20px;
  }

  .brand-name {
    font-size: 36px;
  }

  .brand-desc {
    font-size: 16px;
  }

  .forgot-password-form-wrapper {
    flex: 1;
    width: 100%;
    padding: 20px;
  }

  .form-card {
    padding: 30px 20px;
  }
}
</style>