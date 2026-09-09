<template>
  <div class="register-container">
    <!-- 后退按钮 -->
      <div class="back-button-container">
        <el-button type="text" class="back-button" @click="handleBack">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
      </div>
    <div class="register-wrapper">
      <h2 class="register-title">账户注册</h2>
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="140px"
        class="register-form"
        :validate-on-rule-change="false"
      >
        <!-- 用户类型选择按钮 - 移回表单内部但保持吸顶效果 -->
        <div class="sticky-user-type">
          <div class="user-type-buttons">
            <div
              :class="['user-type-btn', { active: form.userType === 1 }]"
              @click="changeUserType(1)"
            >
              个人用户
            </div>
            <div
              :class="['user-type-btn', { active: form.userType === 2 }]"
              @click="changeUserType(2)"
            >
              企业用户
            </div>
          </div>
        </div>

        <!-- 动态表单项（手机号/统一信用代码） -->
        <el-form-item
    :label="form.userType === 1 ? '手机号' : '统一社会信用代码'"
    prop="username"
  >
    <el-input
      v-model="form.username"
      :placeholder="form.userType === 1 ? '请输入手机号' : '请输入18位统一信用代码'"
      class="input-with-focus"
      clearable
    >
      <template #prefix>
        <el-icon class="el-input__icon">
          <Phone v-if="form.userType === 1"/>
          <Document v-else />
        </el-icon>
      </template>
    </el-input>
  </el-form-item>

        <!-- 密码项 -->
<el-form-item label="密码" prop="password">
    <el-input
      v-model="form.password"
      :type="showPassword ? 'text' : 'password'"
      placeholder="请输入6-20位密码"
      class="input-with-focus"
      clearable
    >
      <template #prefix>
        <el-icon class="el-input__icon"><Lock /></el-icon>
      </template>
      <template #suffix>
        <el-icon @click="showPassword = !showPassword" class="password-toggle" style="cursor: pointer;">
          <View v-if="showPassword"/>
          <Hide v-else />
        </el-icon>
      </template>
    </el-input>
  </el-form-item>

<!-- 确认密码项 -->
 <el-form-item label="确认密码" prop="confirmPassword">
    <el-input
      v-model="form.confirmPassword"
      :type="showConfirmPassword ? 'text' : 'password'"
      placeholder="请再次输入密码"
      class="input-with-focus"
      clearable
    >
      <template #prefix>
        <el-icon class="el-input__icon"><Lock /></el-icon>
      </template>
      <template #suffix>
        <el-icon @click="showConfirmPassword = !showConfirmPassword" class="password-toggle" style="cursor: pointer;">
          <View v-if="showConfirmPassword"/>
          <Hide v-else />
        </el-icon>
      </template>
    </el-input>
  </el-form-item>

  <!-- 邮箱项 -->
  <el-form-item label="邮箱" prop="email">
    <el-input
      v-model="form.email"
      placeholder="请输入邮箱"
      class="input-with-focus"
      clearable
    >
      <template #prefix>
        <el-icon class="el-input__icon"><Message /></el-icon>
      </template>
    </el-input>
  </el-form-item>

        <!-- 按钮组：提交和重置 -->
        <el-form-item>
          <div class="button-group">
            <el-button type="primary" @click="handleSubmit" class="tech-button submit-btn">提交注册</el-button>
            <el-button @click="handleReset" class="tech-button reset-btn">重置表单</el-button>
          </div>
        </el-form-item>

        <!-- 登录链接 -->
        <div class="login-link">
          已有账号？<router-link to="/login" class="link-text">去登录</router-link>
        </div>
      </el-form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, nextTick } from 'vue';
import { useRouter } from 'vue-router';
import { ElMessage } from 'element-plus'; // 导入消息提示组件
import type { FormInstance } from 'element-plus';
import service from '../../axios';
import { Lock, View, Hide ,Phone,Document,ArrowLeft,Message} from '@element-plus/icons-vue'; // 导入图标

const router = useRouter();

// 处理返回逻辑
const handleBack = () => {
  // 如果有历史记录，则返回上一页，否则返回登录页
  if (window.history.length > 1) {
    router.back();
  } else {
    router.push('/login');
  }
};

// 密码显示状态控制变量
const showPassword = ref(false);
const showConfirmPassword = ref(false);

// 表单数据类型定义
interface RegisterForm {
  userType: 1 | 2; // 1=个人 2=企业
  username: string; // 个人存手机号/企业存统一信用代码
  password: string;
  confirmPassword: string;//确认密码字段
  email: string; // 邮箱
}

// 表单数据
const form = reactive<RegisterForm>({
  userType: 1,
  username: '',
  password: '',
  confirmPassword: '',//确认密码字段
  email: '' // 邮箱
});

// 表单引用
const formRef = ref<FormInstance>();

// 验证规则类型定义 - 使用基本的属性避免TypeScript错误
interface RegisterRules {
  username: Array<{ required: boolean; message: string; trigger: string; pattern?: RegExp; }>;
  password: Array<{ required: boolean; message: string; trigger: string; pattern?: RegExp; }>;
  confirmPassword: Array<{ // 新增：确认密码的验证规则类型
    required: boolean;
    message: string;
    trigger: string;
    validator?: (rule: any, value: string, callback: (error?: Error) => void) => void; // 使用validator进行密码一致性验证
  }>;
  email: Array<{ required: boolean; message: string; trigger: string; pattern?: RegExp; }>; // 邮箱验证规则
}


// 初始验证规则 - 使用pattern代替min/max/len
const rules = ref<RegisterRules>({
  username: [
    {
      required: true,
      message: '请输入手机号',
      trigger: 'blur'
    },
    {
      pattern: /^1[3-9]\d{9}$/,
      message: '请输入正确的手机号格式',
      trigger: 'blur',
      required: false
    }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    {
      pattern: /^.{6,20}$/, message: '密码长度为6-20位', trigger: 'blur',
      required: false
    }
  ],
  confirmPassword: [ // 新增：确认密码验证规则
    { required: true, message: '请确认密码', trigger: 'blur' },
    {
      trigger: 'blur',
      validator: (rule, value, callback) => {
        if (value === '' || !form.password) {
          return callback();
        }
        if (value !== form.password) {
          callback(new Error('两次输入的密码不一致'));
        } else {
          callback();
        }
      },
      required: false,
      message: ''
    }
  ],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱格式', trigger: ['blur', 'change'] }
  ]
});

// 切换用户类型（修复验证问题）
const changeUserType = async (type: 1 | 2) => {
  // 首先清除验证状态
  if (formRef.value) {
    formRef.value.clearValidate();
  }

  // 修改用户类型
  form.userType = type;

  // 清空用户名输入框
  form.username = '';
  // 清空密码和确认密码
  form.password = '';
  form.confirmPassword = '';
  // 清空邮箱
  form.email = '';

  // 重置密码显示状态
  showPassword.value = false;
  showConfirmPassword.value = false;

  // 等待DOM更新
  await nextTick();

  // 更新验证规则
  if (type === 1) {
    // 个人用户规则
    rules.value.username = [
      {
        required: true,
        message: '请输入手机号',
        trigger: 'blur'
      },
      {
        pattern: /^1[3-9]\d{9}$/,
        message: '请输入正确的手机号格式',
        trigger: 'blur',
        required: false
      }
    ];
  } else {
    // 企业用户规则 - 只使用pattern进行验证
    rules.value.username = [
      {
        required: true,
        message: '请输入统一社会信用代码',
        trigger: 'blur'
      },
      {
        pattern: /^[0-9A-HJ-NPQRTUWXY]{2}\d{6}[0-9A-HJ-NPQRTUWXY]{10}$/,
        message: '信用代码格式错误',
        trigger: 'blur',
        required: false
      }
    ];
  }
};

// 重置表单
const handleReset = () => {
  if (formRef.value) {
    formRef.value.resetFields();
  }
  form.confirmPassword = '';
  form.email = '';
  // 重置密码显示状态
  showPassword.value = false;
  showConfirmPassword.value = false;
};

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return;
  try {
    await formRef.value.validate();

    // 移除confirmPassword字段，只发送必要字段到后端
    const submitData = {
      userType: form.userType,
      username: form.username,
      password: form.password,
      email: form.email
    };

    // 调用后端注册接口
    const response = await service.post('/register', submitData);

    // 显示成功提示消息
    ElMessage({
      message: '注册成功！即将跳转到登录页面...',
      type: 'success',
      duration: 2500 // 消息显示2.5秒
    });

    // 3秒后跳转到登录页面
    setTimeout(() => {
      router.push('/login');
    }, 3000);

  } catch (err: any) {
    // 处理验证失败或API调用失败的情况
    if (err.msg) {
      // 显示后端返回的错误信息
      ElMessage.error(err.msg || '注册失败');
    } else {
      console.log('表单验证失败或请求错误');
    }
  }
};
</script>

<style scoped>
/* 后退按钮样式 */
.back-button-container {
  position: absolute;
  top: 20px;
  left: 20px;
  z-index: 10;
}

.back-button {
  color: white;
  font-size: 16px;
  padding: 8px 16px;
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(5px);
  transition: all 0.3s ease;
}

.back-button:hover {
  background: rgba(255, 255, 255, 0.2);
  border-color: rgba(255, 255, 255, 0.5);
}


/* 动画定义 */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes pulse {
  0% { box-shadow: 0 0 0 0 rgba(64, 169, 255, 0.4); }
  70% { box-shadow: 0 0 0 10px rgba(64, 169, 255, 0); }
  100% { box-shadow: 0 0 0 0 rgba(64, 169, 255, 0); }
}

.password-toggle {
  cursor: pointer;
}

/* 容器样式 */
.register-container {
  background-image: url("/ZSJ_0831.jpg");
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  height: 98vh;
  width: 100%;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 0px;
  position: relative;
  overflow: hidden;
}


/* 表单包装器 */
.register-wrapper {
  width: 580px; /* 增加宽度以容纳较长的标签文本 */
  position: relative;
  z-index: 1;
  backdrop-filter: blur(10px);
  margin-bottom: 200px;
}

/* 注册标题 */
.register-title {
  text-align: center;
  color: #fff;
  margin-bottom: 20px;
  font-size: 28px;
  font-weight: 600;
  letter-spacing: 2px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

/* 表单内部的吸顶用户类型按钮 */
.sticky-user-type {
  width: 100%;
  margin-bottom: 30px;
  position: sticky;
  top: 0;
  background: rgba(255, 255, 255, 0);
  padding: 10px 0;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.077);
  z-index: 10;
}

/* 用户类型按钮组 */
.user-type-buttons {
  display: flex;
  gap: 0;
  border-radius: 8px;
  overflow: hidden;
  border: 2px solid #dcdfe6;
  transition: border-color 0.3s ease;
}

.user-type-buttons:hover {
  border-color: #40a9ff;
}

.user-type-btn {
  flex: 1;
  padding: 14px 24px; /* 增加高度 */
  text-align: center;
  cursor: pointer;
  background: #f5f7fa;
  color: #606266;
  font-weight: 500;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.user-type-btn::before {
  content: '';
  position: absolute;
  top: 50%;
  left: 50%;
  width: 0;
  height: 0;
  border-radius: 50%;
  background: rgba(64, 169, 255, 0.2);
  transform: translate(-50%, -50%);
  transition: width 0.6s, height 0.6s;
}

.user-type-btn:hover::before {
  width: 300px;
  height: 300px;
}

.user-type-btn.active {
  background: #40a9ff;
  color: white;
  border-color: #40a9ff;
  animation: pulse 1.5s infinite;
}

/* 表单样式 */
.register-form {
  padding: 40px;
  background: rgba(255, 255, 255, 0.9); /* 半透明背景 */
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
}

.register-form:hover {
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.2);
}

/* 输入框样式 */
.input-with-focus .el-input__wrapper {
  border-radius: 8px;
  transition: all 0.3s ease;
}
.el-input {
  border-radius: 8px;
  margin-bottom: 2px;
  height: 40px !important;
}

.input-with-focus .el-input__wrapper:focus-within {
  box-shadow: 0 0 0 2px rgba(64, 169, 255, 0.2);
  border-color: #40a9ff;
}

/* 按钮组样式 */
.button-group {
  display: flex;
  gap: 16px;
  margin-bottom: 20px;
}

.tech-button {
  flex: 1;
  padding: 12px 24px;
  font-size: 16px;
  font-weight: 500;
  border-radius: 8px;
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.submit-btn {
  background: linear-gradient(135deg, #40a9ff, #667eea);
  border: none;
}

.submit-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(64, 169, 255, 0.4);
}

.reset-btn {
  background: #f0f2f5;
  color: #606266;
  border: 1px solid #dcdfe6;
}

.reset-btn:hover {
  background: #e6f7ff;
  color: #40a9ff;
  border-color: #91d5ff;
}

/* 登录链接样式 */
.login-link {
  text-align: center;
  color: #606266;
  margin-top: 20px;
  font-size: 14px;
}

.link-text {
  color: #40a9ff;
  text-decoration: none;
  transition: all 0.3s ease;
  font-weight: 500;
}

.link-text:hover {
  color: #667eea;
  text-decoration: underline;
}

/* 确保响应式设计 */
@media (max-width: 600px) {
  .register-wrapper {
    width: 90%;
    margin: 0 16px;
  }

  .register-form {
    padding: 24px;
  }

  .el-form {
    label-width: 120px !important;
  }
}
</style>
