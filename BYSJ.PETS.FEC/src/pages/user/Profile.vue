<template>
  <div class="profile-page">
    <div class="page-header">
      <div class="header-left">
        <el-button type="text" @click="goBack" class="back-button">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
      </div>
      <h1>个人中心</h1>
    </div>

    <div v-loading="loading" class="profile-content">
      <!-- 个人信息卡片 -->
      <el-card class="profile-card">
        <template #header>
          <div class="card-header">
            <span>个人信息</span>
            <el-button
              type="primary"
              size="small"
              @click="toggleEditMode"
              :disabled="uploading"
            >
              {{ isEditing ? '取消' : '编辑' }}
            </el-button>
          </div>
        </template>

        <div class="profile-main">
          <!-- 头像部分 -->
          <div class="avatar-section">
            <!-- 头像显示 -->
            <div class="avatar-container" @click="showAvatarUploadDialog = true">
              <div class="avatar-wrapper">
                <el-avatar
                  :size="120"
                  :src="userInfo.avatarUrl ? getAvatarUrl(userInfo.avatarUrl) : '/用户头像.png'"
                  :fit="'cover'"
                >
                  <template #fallback>
                    <div class="avatar-fallback">
                      <el-icon class="fallback-icon"><User /></el-icon>
                    </div>
                  </template>
                </el-avatar>
                <!-- 悬停层 -->
                <div class="avatar-hover">
                  <el-icon class="hover-icon"><Plus /></el-icon>
                  <span class="hover-text">上传头像</span>
                </div>
              </div>
            </div>
            <div class="avatar-text">
              <h3>{{ userInfo.nickname || '未设置昵称' }}</h3>
              <p class="username">{{ userInfo.username }}</p>
              <p class="auth-status" v-if="userInfo.status === 2">
                <el-tag type="warning">未实名认证</el-tag>
              </p>
              <p class="auth-status" v-else-if="userInfo.status === 1">
                <el-tag type="success">已实名认证</el-tag>
              </p>
            </div>
          </div>

          <!-- 头像上传弹窗 -->
          <el-dialog
            v-model="showAvatarUploadDialog"
            title="上传头像"
            width="500px"
          >
            <div class="avatar-upload-content">
              <!-- 当前头像预览 -->
              <div v-if="userInfo.avatarUrl" class="avatar-current-preview">
                <h4>当前头像</h4>
                <el-avatar
                  :size="120"
                  :src="getAvatarUrl(userInfo.avatarUrl)"
                  :fit="'cover'"
                  style="margin-bottom: 20px;"
                />
              </div>

              <!-- 上传区域 -->
              <div class="avatar-upload-area">
                <el-upload
                  ref="avatarUploadRef"
                  :action="uploadUrl"
                  :headers="{ 'Authorization': 'Bearer ' + userStore.token }"
                  :show-file-list="false"
                  :on-success="handleAvatarUploadSuccess"
                  :on-error="handleAvatarUploadError"
                  :before-upload="beforeAvatarUpload"
                  name="file"
                  :auto-upload="true"
                >
                  <el-button type="primary" size="large">
                    <el-icon><Plus /></el-icon>
                    选择文件
                  </el-button>
                </el-upload>
                <div class="upload-tip">
                  只能上传 JPG/PNG 文件，且不超过 5MB
                </div>
              </div>
            </div>
            <template #footer>
              <span class="dialog-footer">
                <el-button @click="showAvatarUploadDialog = false">取消</el-button>
              </span>
            </template>
          </el-dialog>

          <!-- 基本信息表单 -->
          <el-form
        ref="profileFormRef"
        :model="userInfo"
        label-position="left"
        label-width="100px"
        class="profile-form"
      >
            <el-row :gutter="30">
              <el-col :span="12">
                <el-form-item label="昵称：">
                  <el-input
                    v-model="userInfo.nickname"
                    placeholder="请输入昵称"
                    :disabled="!isEditing"
                  />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="性别：">
                  <el-select
                    v-model="userInfo.gender"
                    placeholder="请选择性别"
                    :disabled="!isEditing"
                  >
                    <el-option label="未知" :value="0" />
                    <el-option label="男" :value="1" />
                    <el-option label="女" :value="2" />
                  </el-select>
                </el-form-item>
              </el-col>
            </el-row>

            <el-row :gutter="20">
              <el-col :span="12">
                <el-form-item label="手机号码：">
                  <template v-if="!isEditing && userInfo.phone">
                    <div class="read-only-field">{{ maskPhone(userInfo.phone) }}</div>
                  </template>
                  <template v-else>
                    <el-input
                      v-model="userInfo.phone"
                      placeholder="请输入手机号码"
                      :disabled="!isEditing"
                    />
                  </template>
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="邮箱：">
                  <template v-if="!isEditing && userInfo.email">
                    <div class="read-only-field">{{ maskEmail(userInfo.email) }}</div>
                  </template>
                  <template v-else>
                    <el-input
                      v-model="userInfo.email"
                      placeholder="请输入邮箱"
                      :disabled="!isEditing"
                    />
                  </template>
                </el-form-item>
              </el-col>
            </el-row>

            <el-row :gutter="20">
              <el-col :span="12">
                <el-form-item label="真实姓名：">
                  <!-- 如果已认证，显示已认证的姓名且不可编辑 -->
                  <template v-if="userInfo.status === 1">
                    <div class="read-only-field">{{ userInfo.realName }}</div>
                  </template>
                  <template v-else-if="isEditing">
                    <el-input
                      v-model="userInfo.realName"
                      placeholder="请输入真实姓名"
                    />
                  </template>
                  <template v-else>
                    <el-button
                      type="primary"
                      size="small"
                      @click="openAuthDialog"
                    >
                      <el-icon><Star /></el-icon>
                      去认证
                    </el-button>
                  </template>
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="身份证号：">
                  <!-- 如果已认证，显示已认证的身份证号（部分隐藏）且不可编辑 -->
                  <template v-if="userInfo.status === 1">
                    <div class="read-only-field">{{ maskIdCard(userInfo.idCard) }}</div>
                  </template>
                  <template v-else-if="isEditing">
                    <el-input
                      v-model="userInfo.idCard"
                      placeholder="请输入身份证号"
                    />
                  </template>
                  <template v-else>
                    <el-button
                      type="primary"
                      size="small"
                      @click="openAuthDialog"
                    >
                      <el-icon><Star /></el-icon>
                      去认证
                    </el-button>
                  </template>
                </el-form-item>
              </el-col>
            </el-row>

            <el-row :gutter="20">
              <el-col :span="12">
                <el-form-item label="注册时间：">
                  <el-input
                    v-model="formattedCreateTime"
                    disabled
                  />
                </el-form-item>
              </el-col>
            </el-row>
          </el-form>

          <!-- 编辑模式下的保存按钮 -->
          <div v-if="isEditing" class="form-actions">
            <el-button type="primary" @click="saveProfile" :loading="saving">保存修改</el-button>
          </div>
        </div>
      </el-card>

      <!-- 修改密码卡片 -->
      <el-card class="password-card">
        <template #header>
          <div class="card-header" @click="isPasswordExpanded = !isPasswordExpanded">
            <span>修改密码</span>
            <el-button
              type="text"
              size="small"
              icon="el-icon-arrow-down"
              :icon-rotate="isPasswordExpanded ? 180 : 0"
            >
              {{ isPasswordExpanded ? '收起' : '展开' }}
            </el-button>
          </div>
        </template>

        <el-form
          v-if="isPasswordExpanded"
          ref="passwordFormRef"
          :model="passwordForm"
          label-position="left"
          label-width="120px"
          class="password-form"
          :rules="passwordRules"
        >
          <el-form-item label="旧密码：" prop="oldPassword">
            <el-input
              v-model="passwordForm.oldPassword"
              type="password"
              placeholder="请输入旧密码"
              show-password
            />
          </el-form-item>

          <el-form-item label="新密码：" prop="newPassword">
            <el-input
              v-model="passwordForm.newPassword"
              type="password"
              placeholder="请输入新密码"
              show-password
            />
          </el-form-item>

          <el-form-item label="确认新密码：" prop="confirmPassword">
            <el-input
              v-model="passwordForm.confirmPassword"
              type="password"
              placeholder="请确认新密码"
              show-password
            />
          </el-form-item>

          <div class="form-actions">
            <el-button type="primary" @click="changePassword" :loading="changingPassword">
              修改密码
            </el-button>
          </div>
        </el-form>
      </el-card>
    </div>

    <!-- 实名认证对话框 -->
    <el-dialog
      v-model="authDialogVisible"
      title="实名认证"
      width="500px"
      center
    >
      <el-form
        ref="authFormRef"
        :model="authForm"
        label-position="left"
        label-width="100px"
        :rules="authRules"
      >
        <el-form-item label="真实姓名：" prop="realName">
          <el-input
            v-model="authForm.realName"
            placeholder="请输入真实姓名"
          />
        </el-form-item>

        <el-form-item label="身份证号：" prop="idCard">
          <el-input
            v-model="authForm.idCard"
            placeholder="请输入身份证号"
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <span class="dialog-footer">
          <el-button @click="authDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="submitAuth" :loading="submittingAuth">
            提交认证
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ArrowLeft, Plus, Star, User } from '@element-plus/icons-vue'
import { useUserStore } from '@/stores/user'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

const router = useRouter()
const userStore = useUserStore()

// 状态管理
const loading = ref(false)
const saving = ref(false)
const changingPassword = ref(false)
const uploading = ref(false)
const isEditing = ref(false)
const submittingAuth = ref(false)
const isPasswordExpanded = ref(false)
const showAvatarUploadDialog = ref(false)
const profileFormRef = ref()
const passwordFormRef = ref()
const authFormRef = ref()
const avatarUploadRef = ref()

// API 地址
const baseUrl = import.meta.env.VITE_API_BASE_URL || '/api'
const uploadUrl = `${baseUrl}/user/avatar`

// 用户信息
const userInfo = reactive({
  userId: '',
  username: '',
  nickname: '',
  gender: 0,
  phone: '',
  email: '',
  avatarUrl: '',
  createdAt: '',
  realName: '',
  idCard: '',
  status: 2 // 默认未认证状态
})

// 密码修改表单
const passwordForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

// 密码验证规则
const passwordRules = reactive({
  oldPassword: [
    { required: true, message: '请输入旧密码', trigger: 'blur' }
  ],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, message: '新密码长度不能少于6位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    {
      validator: (rule, value, callback) => {
        if (value !== passwordForm.newPassword) {
          callback(new Error('两次输入密码不一致'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ]
})

// 实名认证对话框
const authDialogVisible = ref(false)
const authForm = reactive({
  realName: '',
  idCard: ''
})

// 实名认证表单规则
const authRules = reactive({
  realName: [
    { required: true, message: '请输入真实姓名', trigger: 'blur' }
  ],
  idCard: [
    { required: true, message: '请输入身份证号', trigger: 'blur' },
    { pattern: /^[1-9]\d{5}(18|19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dXx]$/, message: '请输入正确的身份证号', trigger: 'blur' }
  ]
})

// 格式化创建时间
const formattedCreateTime = computed(() => {
  if (!userInfo.createdAt) return ''
  return new Date(userInfo.createdAt).toLocaleString('zh-CN')
})

// 获取用户信息
const fetchUserInfo = async () => {
  try {
    loading.value = true
    const response = await axios.get(`${baseUrl}/user/profile`, {
      headers: { 'Authorization': 'Bearer ' + userStore.token }
    })
    const data = response.data.data
    // 处理字段名映射
    Object.assign(userInfo, {
      ...data,
      createdAt: data.createTime || ''
    })
  } catch (error) {
    console.error('获取用户信息失败:', error)
    ElMessage.error('获取用户信息失败')
  } finally {
    loading.value = false
  }
}

// 获取头像完整URL
const getAvatarUrl = (avatarUrl) => {
  if (!avatarUrl) return null
  if (avatarUrl.startsWith('http')) {
    return avatarUrl
  }
  // 如果是相对路径，直接返回（针对保存在public目录下的头像）
  if (avatarUrl.startsWith('/')) {
    return avatarUrl
  }
  // 如果是文件名或短路径，添加完整路径
  return `/head/${avatarUrl}`
}

// 切换编辑模式
const toggleEditMode = () => {
  if (isEditing.value) {
    // 取消编辑，恢复原始数据
    fetchUserInfo()
  }
  isEditing.value = !isEditing.value
}

// 保存个人信息
const saveProfile = async () => {
  if (!profileFormRef.value) return

  try {
    await profileFormRef.value.validate()
    saving.value = true

    const response = await axios.put(`${baseUrl}/user/profile`, userInfo, {
      headers: { 'Authorization': 'Bearer ' + userStore.token }
    })

    // 检查响应是否成功
    if (response.data && response.data.code === 200) {
      // 更新用户信息
      const updatedUser = response.data.data
      if (updatedUser) {
        Object.assign(userInfo, {
          ...updatedUser,
          createdAt: updatedUser.createTime || userInfo.createdAt
        })

        // 更新用户存储中的信息
        userStore.setUserInfo({
          ...userStore.userInfo,
          nickname: userInfo.nickname,
          gender: userInfo.gender,
          phone: userInfo.phone,
          email: userInfo.email,
          avatarUrl: userInfo.avatarUrl,
          realName: userInfo.realName,
          status: userInfo.status
        })
      }

      ElMessage.success('保存成功')
      isEditing.value = false
    } else {
      // 处理失败情况
      const errorMsg = response.data?.msg || '保存失败'
      ElMessage.error(errorMsg)
    }
  } catch (error) {
    console.error('保存个人信息失败:', error)
    // 处理网络错误或其他异常
    if (error.response) {
      // 服务器返回了错误响应
      const errorMsg = error.response.data?.msg || '保存失败'
      ElMessage.error(errorMsg)
    } else if (error.request) {
      // 请求已发送但没有收到响应
      ElMessage.error('服务器无响应，请稍后重试')
    } else {
      // 其他错误
      console.error('保存个人信息时发生未知错误:', error)
      // 注意：这里不再显示通用的"保存个人信息失败"提示，避免双重提示
    }
  } finally {
    saving.value = false
  }
}

// 头像上传相关
const handleAvatarUploadSuccess = (response) => {
  uploading.value = false
  if (response.code === 200) {
    userInfo.avatarUrl = response.data
    ElMessage.success('头像上传成功')
    showAvatarUploadDialog.value = false
  } else {
    ElMessage.error(response.msg || '头像上传失败')
  }
}

const handleAvatarUploadError = (error) => {
  uploading.value = false
  console.error('头像上传失败:', error)
  ElMessage.error('头像上传失败')
}

const beforeAvatarUpload = (file) => {
  const isJPG = file.type === 'image/jpeg' || file.type === 'image/png'
  const isLt5M = file.size / 1024 / 1024 < 5

  if (!isJPG) {
    ElMessage.error('只能上传 JPG/PNG 格式的图片')
  }
  if (!isLt5M) {
    ElMessage.error('上传图片大小不能超过 5MB')
  }

  uploading.value = isJPG && isLt5M
  return isJPG && isLt5M
}

// 修改密码
const changePassword = async () => {
  if (!passwordFormRef.value) return

  try {
    await passwordFormRef.value.validate()
    changingPassword.value = true

    const response = await axios.put(`${baseUrl}/user/password`, passwordForm, {
      headers: { 'Authorization': 'Bearer ' + userStore.token }
    })

    ElMessage.success('密码修改成功')
    // 重置表单
    passwordForm.oldPassword = ''
    passwordForm.newPassword = ''
    passwordForm.confirmPassword = ''
    passwordFormRef.value.resetFields()
  } catch (error) {
    console.error('修改密码失败:', error)
    if (error.response && error.response.data) {
      ElMessage.error(error.response.data.msg || '修改密码失败')
    } else {
      ElMessage.error('修改密码失败')
    }
  } finally {
    changingPassword.value = false
  }
}

// 身份证号掩码处理
const maskIdCard = (idCard) => {
  if (!idCard || idCard.length < 18) return idCard
  return idCard.substring(0, 6) + '********' + idCard.substring(14)
}

// 手机号掩码处理
const maskPhone = (phone) => {
  if (!phone || phone.length < 11) return phone
  return phone.substring(0, 3) + '****' + phone.substring(7)
}

// 邮箱掩码处理
const maskEmail = (email) => {
  if (!email) return email
  const parts = email.split('@')
  if (parts.length !== 2) return email
  const username = parts[0]
  const domain = parts[1]
  if (username.length <= 3) {
    return username.substring(0, 1) + '***@' + domain
  } else {
    return username.substring(0, 3) + '***@' + domain
  }
}

// 打开实名认证对话框
const openAuthDialog = () => {
  authForm.realName = userInfo.realName || ''
  authForm.idCard = userInfo.idCard || ''
  authDialogVisible.value = true
}

// 提交实名认证
const submitAuth = async () => {
  if (!authFormRef.value) return

  try {
    await authFormRef.value.validate()
    submittingAuth.value = true

    const response = await axios.put(`${baseUrl}/user/verify`, authForm, {
      headers: { 'Authorization': 'Bearer ' + userStore.token }
    })

    if (response.data && response.data.code === 200) {
      ElMessage.success('实名认证提交成功，待审核')
      authDialogVisible.value = false
      // 更新用户信息
      fetchUserInfo()
    } else {
      const errorMsg = response.data?.msg || '提交认证失败'
      ElMessage.error(errorMsg)
    }
  } catch (error) {
    console.error('提交认证失败:', error)
    if (error.response && error.response.data) {
      ElMessage.error(error.response.data.msg || '提交认证失败')
    } else if (error.request) {
      ElMessage.error('服务器无响应，请稍后重试')
    } else {
      ElMessage.error('提交认证失败')
    }
  } finally {
    submittingAuth.value = false
  }
}

// 返回上一页
const goBack = () => {
  router.back()
}

onMounted(() => {
  fetchUserInfo()
})
</script>

<style scoped>
.profile-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.page-header {
  margin-bottom: 30px;
  text-align: center;
  position: relative;
}

.header-left {
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
}

.back-button {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 16px;
  color: #666;
}

.page-header h1 {
  margin: 0;
  color: #333;
}

.profile-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.profile-card, .password-card {
  box-shadow: 0 2px 12px rgba(0,0,0,0.1);
  border-radius: 8px;
  overflow: hidden;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 18px;
  font-weight: 600;
  color: #333;
}

/* 个人信息样式 */
.profile-main {
  padding: 20px 0;
}

.avatar-section {
  display: flex;
  align-items: center;
  gap: 30px;
  margin-bottom: 30px;
  padding: 0 20px;
}

.avatar-uploader {
  width: 120px;
  height: 120px;
  position: relative;
  border-radius: 50%;
  overflow: hidden;
  border: 2px solid #e0e0e0;
}

.avatar-uploader:hover .avatar {
  opacity: 0.8;
}

.avatar-uploader .el-upload__tip {
  text-align: center;
  margin-top: 10px;
}

.avatar {
  width: 100%;
  height: 100%;
  display: block;
  object-fit: cover;
  transition: opacity 0.3s;
}

.avatar-uploader-icon {
  font-size: 40px;
  color: #909399;
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f0f0f0;
}

.avatar-text {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.avatar-text h3 {
  margin: 0;
  font-size: 24px;
  color: #333;
}

.avatar-text .username {
  margin: 0;
  font-size: 16px;
  color: #666;
}

.avatar-text .auth-status {
  margin: 5px 0 0 0;
}

.profile-form {
  padding: 0 20px;
}

/* 调整表单项目的对齐方式 */
.profile-form :deep(.el-form-item) {
  margin-bottom: 25px;
  width: 100%;
  display: flex;
  align-items: center;
}

/* 确保每个表单项目都包含在自己的列中，避免交叉影响 */
.profile-form .el-col {
  padding: 0 15px;
}

/* 确保所有表单项目的label和input之间有适当的间距 */
.profile-form :deep(.el-form-item__label) {
  text-align: left;
  margin-right: 10px;
  min-width: 100px;
  white-space: nowrap;
  flex-shrink: 0;
}

/* 调整输入框和选择器的宽度和高度，确保一致 */
.profile-form :deep(.el-form-item__content) {
  flex: 1;
  display: flex;
  align-items: center;
}

.profile-form :deep(.el-input__wrapper),
.profile-form :deep(.el-select__wrapper),
.profile-form .read-only-field {
  width: 100%;
  height: 32px;
  box-sizing: border-box;
  display: flex;
  align-items: center;
}

/* 确保输入框内容垂直居中 */
.profile-form :deep(.el-input__inner),
.profile-form :deep(.el-select__input) {
  height: 32px;
  line-height: 32px;
  padding: 0 10px;
}



.password-form {
  padding: 20px;
}

.form-actions {
  margin-top: 20px;
  display: flex;
  justify-content: center;
  gap: 10px;
}

/* 只读字段样式 */
.read-only-field {
  padding: 10px;
  background-color: #f5f7fa;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  color: #606266;
  min-height: 32px;
  line-height: 32px;
  box-sizing: border-box;
}

/* 头像样式 */
.avatar-container {
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.avatar-container:hover {
  transform: scale(1.05);
}

.avatar-fallback {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
}

.fallback-icon {
  font-size: 40px;
  margin-bottom: 8px;
  color: #909399;
}

.fallback-text {
  font-size: 14px;
  color: #606266;
}

/* 头像提示文字样式 */
.avatar-hint {
  font-size: 14px;
  color: #606266;
  text-align: center;
  margin-top: 5px;
}

/* 头像包装器，用于定位悬停层 */
.avatar-wrapper {
  position: relative;
  display: inline-block;
}

/* 悬停层样式 */
.avatar-hover {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  border-radius: 50%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.3s;
  cursor: pointer;
  color: white;
}

/* 鼠标悬停时显示悬停层 */
.avatar-wrapper:hover .avatar-hover {
  opacity: 1;
}

/* 悬停层图标样式 */
.hover-icon {
  font-size: 32px;
  margin-bottom: 8px;
  color: white;
}

/* 悬停层文字样式 */
.hover-text {
  font-size: 14px;
  color: white;
  text-align: center;
}

/* 头像上传弹窗样式 */
.avatar-upload-content {
  padding: 10px 0;
}

/* 当前头像预览样式 */
.avatar-current-preview {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 20px;
}

.avatar-current-preview h4 {
  margin: 0 0 15px 0;
  color: #303133;
  font-size: 16px;
}

/* 上传区域样式 */
.avatar-upload-area {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.upload-tip {
  margin-top: 10px;
  font-size: 14px;
  color: #909399;
  text-align: center;
}

/* 隐藏默认的上传样式 */
.avatar-upload-area :deep(.el-upload) {
  margin: 0;
}

.avatar-upload-area :deep(.el-upload-dragger) {
  background-color: transparent;
  border: none;
  box-shadow: none;
  margin: 0;
}

.avatar-upload-area :deep(.el-upload__text) {
  display: none;
}

.avatar-upload-area :deep(.el-upload__tip) {
  margin-top: 10px;
  color: #909399;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .profile-page {
    padding: 10px;
  }

  .avatar-section {
    flex-direction: column;
    text-align: center;
    gap: 20px;
  }

  .el-row {
    flex-direction: column;
  }

  .el-col {
    width: 100% !important;
  }

  .profile-form, .password-form {
    padding: 0 10px;
  }
}
</style>
