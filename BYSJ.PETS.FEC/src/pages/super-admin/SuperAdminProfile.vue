<template>
  <div class="super-admin-profile-page">
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
                <div class="avatar-hover">
                  <el-icon class="hover-icon"><Plus /></el-icon>
                  <span class="hover-text">上传头像</span>
                </div>
              </div>
            </div>
            <div class="avatar-text">
              <h3>{{ userInfo.nickname || '未设置昵称' }}</h3>
              <p class="username">{{ userInfo.username }}</p>
              <p class="admin-status">
                <el-tag :type="userInfo.status === 1 ? 'success' : 'danger'">
                  {{ userInfo.status === 1 ? '正常' : '禁用' }}
                </el-tag>
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
              <div v-if="userInfo.avatarUrl" class="avatar-current-preview">
                <h4>当前头像</h4>
                <el-avatar
                  :size="120"
                  :src="getAvatarUrl(userInfo.avatarUrl)"
                  :fit="'cover'"
                  style="margin-bottom: 20px;"
                />
              </div>
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
                <el-form-item label="用户名：">
                  <el-input
                    v-model="userInfo.username"
                    placeholder="请输入用户名"
                    :disabled="true"
                  />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="昵称：">
                  <el-input
                    v-model="userInfo.nickname"
                    placeholder="请输入昵称"
                    :disabled="!isEditing"
                  />
                </el-form-item>
              </el-col>
            </el-row>

            <el-row :gutter="20">
              <el-col :span="12">
                <el-form-item label="手机号码：">
                  <el-input
                    v-model="userInfo.phone"
                    placeholder="请输入手机号码"
                    :disabled="!isEditing"
                  />
                </el-form-item>
              </el-col>
              <el-col :span="12">
                <el-form-item label="邮箱：">
                  <el-input
                    v-model="userInfo.email"
                    placeholder="请输入邮箱"
                    :disabled="!isEditing"
                  />
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
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ArrowLeft, Plus, User } from '@element-plus/icons-vue'
import { useUserStore } from '@/stores/user'
import { ElMessage } from 'element-plus'
import axios from 'axios'

const router = useRouter()
const userStore = useUserStore()

const loading = ref(false)
const saving = ref(false)
const changingPassword = ref(false)
const uploading = ref(false)
const isEditing = ref(false)
const isPasswordExpanded = ref(false)
const showAvatarUploadDialog = ref(false)
const profileFormRef = ref()
const passwordFormRef = ref()
const avatarUploadRef = ref()

const baseUrl = import.meta.env.VITE_API_BASE_URL || '/api'
const uploadUrl = `${baseUrl}/user/avatar`

const userInfo = reactive({
  userId: '',
  username: '',
  nickname: '',
  phone: '',
  email: '',
  avatarUrl: '',
  createdAt: '',
  status: 1
})

const passwordForm = reactive({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

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

const formattedCreateTime = computed(() => {
  if (!userInfo.createdAt) return ''
  return new Date(userInfo.createdAt).toLocaleString('zh-CN')
})

const fetchUserInfo = async () => {
  try {
    loading.value = true
    const response = await axios.get(`${baseUrl}/user/profile`, {
      headers: { 'Authorization': 'Bearer ' + userStore.token }
    })
    const data = response.data.data
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

const getAvatarUrl = (avatarUrl) => {
  if (!avatarUrl) return null
  if (avatarUrl.startsWith('http')) {
    return avatarUrl
  }
  if (avatarUrl.startsWith('/')) {
    return avatarUrl
  }
  return `/head/${avatarUrl}`
}

const toggleEditMode = () => {
  if (isEditing.value) {
    fetchUserInfo()
  }
  isEditing.value = !isEditing.value
}

const saveProfile = async () => {
  if (!profileFormRef.value) return

  try {
    await profileFormRef.value.validate()
    saving.value = true

    const response = await axios.put(`${baseUrl}/user/profile`, userInfo, {
      headers: { 'Authorization': 'Bearer ' + userStore.token }
    })

    if (response.data && response.data.code === 200) {
      const updatedUser = response.data.data
      if (updatedUser) {
        Object.assign(userInfo, {
          ...updatedUser,
          createdAt: updatedUser.createTime || userInfo.createdAt
        })

        userStore.setUserInfo({
          ...userStore.userInfo,
          nickname: userInfo.nickname,
          phone: userInfo.phone,
          email: userInfo.email,
          avatarUrl: userInfo.avatarUrl
        })
      }

      ElMessage.success('保存成功')
      isEditing.value = false
    } else {
      const errorMsg = response.data?.msg || '保存失败'
      ElMessage.error(errorMsg)
    }
  } catch (error) {
    console.error('保存个人信息失败:', error)
    if (error.response) {
      const errorMsg = error.response.data?.msg || '保存失败'
      ElMessage.error(errorMsg)
    } else if (error.request) {
      ElMessage.error('服务器无响应，请稍后重试')
    }
  } finally {
    saving.value = false
  }
}

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

const changePassword = async () => {
  if (!passwordFormRef.value) return

  try {
    await passwordFormRef.value.validate()
    changingPassword.value = true

    const response = await axios.put(`${baseUrl}/user/password`, passwordForm, {
      headers: { 'Authorization': 'Bearer ' + userStore.token }
    })

    ElMessage.success('密码修改成功')
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

const goBack = () => {
  router.back()
}

onMounted(() => {
  fetchUserInfo()
})
</script>

<style scoped>
.super-admin-profile-page {
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

.avatar-wrapper {
  position: relative;
  display: inline-block;
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

.avatar-wrapper:hover .avatar-hover {
  opacity: 1;
}

.hover-icon {
  font-size: 32px;
  margin-bottom: 8px;
  color: white;
}

.hover-text {
  font-size: 14px;
  color: white;
  text-align: center;
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

.avatar-text .admin-status {
  margin: 5px 0 0 0;
}

.profile-form {
  padding: 0 20px;
}

.profile-form :deep(.el-form-item) {
  margin-bottom: 25px;
  width: 100%;
  display: flex;
  align-items: center;
}

.profile-form .el-col {
  padding: 0 15px;
}

.profile-form :deep(.el-form-item__label) {
  text-align: left;
  margin-right: 10px;
  min-width: 100px;
  white-space: nowrap;
  flex-shrink: 0;
}

.profile-form :deep(.el-form-item__content) {
  flex: 1;
  display: flex;
  align-items: center;
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

.avatar-upload-content {
  padding: 10px 0;
}

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

@media (max-width: 768px) {
  .super-admin-profile-page {
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
