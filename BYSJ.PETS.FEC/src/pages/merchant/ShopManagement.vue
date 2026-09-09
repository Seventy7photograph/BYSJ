<template>
  <div class="merchant-shop-management">
    <h2 class="page-title">店铺管理</h2>

    <el-tabs v-model="activeTab" class="shop-tabs">
      <!-- 店铺信息 -->
      <el-tab-pane label="店铺信息" name="info">
        <div class="tab-content">
          <el-card class="shop-info-card">
            <template #header>
              <div class="card-header">
                <span>店铺基本信息</span>
                <el-button type="primary" size="small" @click="handleEditShopInfo">编辑信息</el-button>
              </div>
            </template>

            <div class="shop-info-content">
              <el-descriptions :column="2" border>
                <el-descriptions-item label="店铺名称">{{ shopInfo.shopName }}</el-descriptions-item>
                <el-descriptions-item label="店铺类型">{{ shopInfo.shopType }}</el-descriptions-item>
                <el-descriptions-item label="店铺状态">
                  <el-tag :type="shopInfo.status === 'normal' ? 'success' : 'warning'">
                    {{ shopInfo.status === 'normal' ? '正常' : '审核中' }}
                  </el-tag>
                </el-descriptions-item>
                <el-descriptions-item label="开店时间">{{ shopInfo.openTime }}</el-descriptions-item>
                <el-descriptions-item label="联系电话">{{ shopInfo.phone }}</el-descriptions-item>
                <el-descriptions-item label="联系邮箱">{{ shopInfo.email }}</el-descriptions-item>
                <el-descriptions-item label="店铺地址" :span="2">{{ shopInfo.address }}</el-descriptions-item>
                <el-descriptions-item label="店铺简介" :span="2">{{ shopInfo.description }}</el-descriptions-item>
              </el-descriptions>
            </div>
          </el-card>

          <el-card class="shop-logo-card" style="margin-top: 20px;">
            <template #header>
              <div class="card-header">
                <span>店铺logo</span>
              </div>
            </template>

            <div class="shop-logo-content">
              <!-- 头像显示 -->
              <div class="avatar-container" @click="showLogoUploadDialog = true">
                <div class="avatar-wrapper">
                  <el-avatar
                    :size="120"
                    :src="shopInfo.logo || '/用户头像.png'"
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
                    <span class="hover-text">上传Logo</span>
                  </div>
                </div>
              </div>
            </div>
          </el-card>

          <!-- Logo上传弹窗 -->
          <el-dialog
            v-model="showLogoUploadDialog"
            title="上传店铺Logo"
            width="500px"
          >
            <div class="avatar-upload-content">
              <!-- 当前Logo预览 -->
              <div v-if="shopInfo.logo" class="avatar-current-preview">
                <h4>当前Logo</h4>
                <el-avatar
                  :size="120"
                  :src="shopInfo.logo"
                  :fit="'cover'"
                  style="margin-bottom: 20px;"
                />
              </div>

              <!-- 上传区域 -->
              <div class="avatar-upload-area">
                <el-upload
                  ref="logoUploadRef"
                  action=""
                  :show-file-list="false"
                  :auto-upload="false"
                  :on-change="handleLogoFileChange"
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
                <el-button @click="showLogoUploadDialog = false">取消</el-button>
              </span>
            </template>
          </el-dialog>
        </div>
      </el-tab-pane>

      <!-- 店铺认证 -->
      <el-tab-pane label="店铺认证" name="authentication">
        <div class="tab-content">
          <el-card class="authentication-card">
            <template #header>
              <div class="card-header">
                <span>店铺认证信息</span>
              </div>
            </template>

            <div class="authentication-content">
              <div class="authentication-status">
                <h3 class="status-title">认证状态</h3>
                <div class="status-info">
                  <el-tag :type="authInfo.status === 'approved' ? 'success' : authInfo.status === 'pending' ? 'warning' : 'danger'">
                    {{ authInfo.status === 'approved' ? '已认证' : authInfo.status === 'pending' ? '审核中' : '未认证' }}
                  </el-tag>
                  <!-- <span v-if="authInfo.status === 'rejected'" class="reject-reason">
                    拒绝原因：{{ authInfo.rejectReason }}
                  </span> -->
                </div>
              </div>

              <div class="authentication-details">
                <h3 class="details-title">认证详情</h3>
                <el-descriptions :column="2" border>
                  <el-descriptions-item label="认证类型">{{ authInfo.authType }}</el-descriptions-item>
                  <el-descriptions-item label="认证时间">{{ authInfo.authTime || '未认证' }}</el-descriptions-item>
                  <el-descriptions-item label="营业执照" :span="2">
                    <el-image
                      v-if="authInfo.businessLicense"
                      :src="authInfo.businessLicense"
                      :preview-src-list="[authInfo.businessLicense]"
                      fit="cover"
                      style="width: 200px; height: 150px;"
                    />
                    <span v-else>未上传</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="法人身份证正面" :span="2">
                    <el-image
                      v-if="authInfo.idCardFront"
                      :src="authInfo.idCardFront"
                      :preview-src-list="[authInfo.idCardFront]"
                      fit="cover"
                      style="width: 200px; height: 150px;"
                    />
                    <span v-else>未上传</span>
                  </el-descriptions-item>
                  <el-descriptions-item label="法人身份证反面" :span="2">
                    <el-image
                      v-if="authInfo.idCardBack"
                      :src="authInfo.idCardBack"
                      :preview-src-list="[authInfo.idCardBack]"
                      fit="cover"
                      style="width: 200px; height: 150px;"
                    />
                    <span v-else>未上传</span>
                  </el-descriptions-item>
                </el-descriptions>
              </div>

              <div class="authentication-action">
                <el-button
                  type="primary"
                  size="large"
                  @click="handleStartAuth"
                  :disabled="authInfo.status === 'approved' || authInfo.status === 'pending'"
                >
                  {{ authInfo.status === 'approved' ? '已认证' : authInfo.status === 'pending' ? '审核中' : authInfo.status === 'rejected' ? '认证失败，重新认证' : '开始认证' }}
                </el-button>
              </div>
            </div>
          </el-card>
        </div>
      </el-tab-pane>

      <!-- 安全设置 -->
      <el-tab-pane label="安全设置" name="security">
        <div class="tab-content">
          <el-card class="security-card">
            <template #header>
              <div class="card-header">
                <span>账户安全</span>
              </div>
            </template>

            <div class="security-content">
              <div class="security-item">
                <div class="security-item-label">
                  <span>登录密码</span>
                  <el-tag type="info">已设置</el-tag>
                </div>
                <div class="security-item-action">
                  <el-button type="primary" @click="handleChangePassword">修改密码</el-button>
                </div>
              </div>

              <div class="security-item">
                <div class="security-item-label">
                  <span>支付密码</span>
                  <el-tag :type="securityInfo.payPasswordSet ? 'info' : 'warning'">
                    {{ securityInfo.payPasswordSet ? '已设置' : '未设置' }}
                  </el-tag>
                </div>
                <div class="security-item-action">
                  <el-button type="primary" @click="handleSetPayPassword">
                    {{ securityInfo.payPasswordSet ? '修改支付密码' : '设置支付密码' }}
                  </el-button>
                </div>
              </div>

              <div class="security-item">
                <div class="security-item-label">
                  <span>手机验证</span>
                  <el-tag type="success">已验证</el-tag>
                </div>
                <div class="security-item-action">
                  <el-button type="primary" @click="handleChangePhone">更换手机号</el-button>
                </div>
              </div>

              <div class="security-item">
                <div class="security-item-label">
                  <span>邮箱验证</span>
                  <el-tag type="success">已验证</el-tag>
                </div>
                <div class="security-item-action">
                  <el-button type="primary" @click="handleChangeEmail">更换邮箱</el-button>
                </div>
              </div>
            </div>
          </el-card>

          <el-card class="logout-card" style="margin-top: 20px;">
            <div class="logout-content">
              <h3>安全退出</h3>
              <p>点击下方按钮安全退出商家后台</p>
              <el-button type="danger" size="large" @click="handleLogout">安全退出</el-button>
            </div>
          </el-card>
        </div>
      </el-tab-pane>
    </el-tabs>

    <!-- 编辑店铺信息对话框 -->
    <el-dialog
      v-model="shopInfoDialogVisible"
      title="编辑店铺信息"
      width="600px"
    >
      <el-form
        ref="shopInfoFormRef"
        :model="shopInfoForm"
        :rules="shopInfoFormRules"
        label-width="120px"
      >
        <el-form-item label="店铺名称" prop="shopName">
          <el-input v-model="shopInfoForm.shopName" placeholder="请输入店铺名称" />
        </el-form-item>

        <el-form-item label="店铺类型" prop="shopType">
          <el-select v-model="shopInfoForm.shopType" placeholder="请选择店铺类型">
            <el-option label="个人店铺" value="personal" />
            <el-option label="企业店铺" value="enterprise" />
          </el-select>
        </el-form-item>

        <el-form-item label="联系电话" prop="phone">
          <el-input v-model="shopInfoForm.phone" placeholder="请输入联系电话" />
        </el-form-item>

        <el-form-item label="联系邮箱" prop="email">
          <el-input v-model="shopInfoForm.email" placeholder="请输入联系邮箱" />
        </el-form-item>

        <el-form-item label="店铺地址" prop="address">
          <el-input v-model="shopInfoForm.address" placeholder="请输入店铺地址" />
        </el-form-item>

        <el-form-item label="店铺简介" prop="description">
          <el-input
            v-model="shopInfoForm.description"
            type="textarea"
            :rows="4"
            placeholder="请输入店铺简介"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="shopInfoDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="submitShopInfoForm">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 修改密码对话框 -->
    <el-dialog
      v-model="changePasswordDialogVisible"
      title="修改密码"
      width="400px"
    >
      <el-form
        :model="changePasswordForm"
        :rules="changePasswordRules"
        label-width="100px"
      >
        <el-form-item label="旧密码" prop="oldPassword">
          <el-input v-model="changePasswordForm.oldPassword" type="password" placeholder="请输入旧密码" />
        </el-form-item>
        <el-form-item label="新密码" prop="newPassword">
          <el-input v-model="changePasswordForm.newPassword" type="password" placeholder="请输入新密码" />
        </el-form-item>
        <el-form-item label="确认新密码" prop="confirmPassword">
          <el-input v-model="changePasswordForm.confirmPassword" type="password" placeholder="请确认新密码" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="changePasswordDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="submitChangePassword">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 设置支付密码对话框 -->
    <el-dialog
      v-model="setPayPasswordDialogVisible"
      title="设置支付密码"
      width="400px"
    >
      <el-form
        :model="setPayPasswordForm"
        :rules="setPayPasswordRules"
        label-width="100px"
      >
        <el-form-item label="支付密码" prop="payPassword">
          <el-input v-model="setPayPasswordForm.payPassword" type="password" placeholder="请输入6位数字支付密码" />
        </el-form-item>
        <el-form-item label="确认支付密码" prop="confirmPassword">
          <el-input v-model="setPayPasswordForm.confirmPassword" type="password" placeholder="请确认支付密码" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="setPayPasswordDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="submitSetPayPassword">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 认证材料上传对话框 -->
    <el-dialog
      v-model="authDialogVisible"
      title="店铺认证"
      width="600px"
    >
      <el-form
        ref="authFormRef"
        :model="authForm"
        :rules="authFormRules"
        label-width="120px"
      >
        <el-form-item label="认证类型" prop="authType">
          <el-select v-model="authForm.authType" placeholder="请选择认证类型">
            <el-option label="企业认证" value="enterprise" />
            <el-option label="个人认证" value="personal" />
          </el-select>
        </el-form-item>

        <el-form-item label="营业执照" prop="businessLicense">
          <el-upload
            ref="businessLicenseUploadRef"
            action=""
            :show-file-list="false"
            :auto-upload="false"
            :on-change="handleBusinessLicenseFileChange"
          >
            <div v-if="!authForm.businessLicense" class="upload-area">
              <el-icon class="upload-icon"><Plus /></el-icon>
              <span>点击上传营业执照</span>
              <small class="upload-tip">支持JPG/PNG/PDF格式，不超过5MB</small>
            </div>
            <div v-else class="file-preview">
              <div v-if="isImageFile(authForm.businessLicense)" class="image-preview">
                <el-image
                  :src="authForm.businessLicense"
                  :preview-src-list="[authForm.businessLicense]"
                  fit="cover"
                  style="width: 200px; height: 150px; cursor: pointer;"
                />
                <el-button type="text" size="small" @click.stop="authForm.businessLicense = ''">删除</el-button>
              </div>
              <div v-else class="pdf-preview">
                <div class="pdf-icon">
                  <el-icon class="pdf-icon-large"><Document /></el-icon>
                  <span>PDF文件</span>
                </div>
                <el-button type="primary" size="small" @click.stop="openFile(authForm.businessLicense)">查看</el-button>
                <el-button type="text" size="small" @click.stop="authForm.businessLicense = ''">删除</el-button>
              </div>
            </div>
          </el-upload>
        </el-form-item>

        <el-form-item label="法人身份证正面" prop="idCardFront">
          <el-upload
            ref="idCardFrontUploadRef"
            action=""
            :show-file-list="false"
            :auto-upload="false"
            :on-change="handleIdCardFrontFileChange"
          >
            <div v-if="!authForm.idCardFront" class="upload-area">
              <el-icon class="upload-icon"><Plus /></el-icon>
              <span>点击上传身份证正面</span>
              <small class="upload-tip">支持JPG/PNG/PDF格式，不超过5MB</small>
            </div>
            <div v-else class="file-preview">
              <div v-if="isImageFile(authForm.idCardFront)" class="image-preview">
                <el-image
                  :src="authForm.idCardFront"
                  :preview-src-list="[authForm.idCardFront]"
                  fit="cover"
                  style="width: 200px; height: 150px; cursor: pointer;"
                />
                <el-button type="text" size="small" @click.stop="authForm.idCardFront = ''">删除</el-button>
              </div>
              <div v-else class="pdf-preview">
                <div class="pdf-icon">
                  <el-icon class="pdf-icon-large"><Document /></el-icon>
                  <span>PDF文件</span>
                </div>
                <el-button type="primary" size="small" @click.stop="openFile(authForm.idCardFront)">查看</el-button>
                <el-button type="text" size="small" @click.stop="authForm.idCardFront = ''">删除</el-button>
              </div>
            </div>
          </el-upload>
        </el-form-item>

        <el-form-item label="法人身份证反面" prop="idCardBack">
          <el-upload
            ref="idCardBackUploadRef"
            action=""
            :show-file-list="false"
            :auto-upload="false"
            :on-change="handleIdCardBackFileChange"
          >
            <div v-if="!authForm.idCardBack" class="upload-area">
              <el-icon class="upload-icon"><Plus /></el-icon>
              <span>点击上传身份证反面</span>
              <small class="upload-tip">支持JPG/PNG/PDF格式，不超过5MB</small>
            </div>
            <div v-else class="file-preview">
              <div v-if="isImageFile(authForm.idCardBack)" class="image-preview">
                <el-image
                  :src="authForm.idCardBack"
                  :preview-src-list="[authForm.idCardBack]"
                  fit="cover"
                  style="width: 200px; height: 150px; cursor: pointer;"
                />
                <el-button type="text" size="small" @click.stop="authForm.idCardBack = ''">删除</el-button>
              </div>
              <div v-else class="pdf-preview">
                <div class="pdf-icon">
                  <el-icon class="pdf-icon-large"><Document /></el-icon>
                  <span>PDF文件</span>
                </div>
                <el-button type="primary" size="small" @click.stop="openFile(authForm.idCardBack)">查看</el-button>
                <el-button type="text" size="small" @click.stop="authForm.idCardBack = ''">删除</el-button>
              </div>
            </div>
          </el-upload>
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="authDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="submitAuthForm">提交认证</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Document } from '@element-plus/icons-vue'
import {
  getShopInfo,
  updateShopInfo,
  uploadShopLogo,
  getAuthInfo,
  submitAuthInfo,
  getSecurityInfo,
  changePassword,
  setPayPassword
} from '@/api/merchant/shop'

const router = useRouter()
const userStore = useUserStore()

// 激活的标签页
const activeTab = ref('info')

// 店铺信息
const shopInfo = ref({
  shopName: '',
  shopType: '',
  status: '',
  openTime: '',
  phone: '',
  email: '',
  address: '',
  description: '',
  logo: ''
})

// Logo上传相关
const showLogoUploadDialog = ref(false)
const uploading = ref(false)
// 使用与其他API相同的上传方式
const uploadUrl = import.meta.env.VITE_APP_BASE_API + '/merchant/shop/upload-logo'
// 认证材料上传路径
const authMaterialUploadUrl = import.meta.env.VITE_APP_BASE_API + '/merchant/shop/upload-auth-material'

// 认证信息
const authInfo = ref({
  status: '',
  authType: '',
  authTime: '',
  rejectReason: '',
  businessLicense: '',
  idCardFront: '',
  idCardBack: ''
})

// 认证对话框
const authDialogVisible = ref(false)
const authFormRef = ref()
const authForm = ref({
  authType: '',
  businessLicense: '',
  idCardFront: '',
  idCardBack: ''
})

const authFormRules = {
  authType: [
    { required: true, message: '请选择认证类型', trigger: 'change' }
  ],
  businessLicense: [
    { required: true, message: '请上传营业执照', trigger: 'change' }
  ],
  idCardFront: [
    { required: true, message: '请上传法人身份证正面', trigger: 'change' }
  ],
  idCardBack: [
    { required: true, message: '请上传法人身份证反面', trigger: 'change' }
  ]
}

// 上传组件引用
const businessLicenseUploadRef = ref()
const idCardFrontUploadRef = ref()
const idCardBackUploadRef = ref()

// 安全设置信息
const securityInfo = ref({
  payPasswordSet: false
})

// 编辑店铺信息相关
const shopInfoDialogVisible = ref(false)
const shopInfoFormRef = ref()
const shopInfoForm = ref({
  shopName: '',
  shopType: '',
  phone: '',
  email: '',
  address: '',
  description: ''
})

const shopInfoFormRules = {
  shopName: [
    { required: true, message: '请输入店铺名称', trigger: 'blur' },
    { min: 2, max: 50, message: '店铺名称长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  shopType: [
    { required: true, message: '请选择店铺类型', trigger: 'change' }
  ],
  phone: [
    { required: true, message: '请输入联系电话', trigger: 'blur' },
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号码', trigger: 'blur' }
  ],
  email: [
    { required: true, message: '请输入联系邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱地址', trigger: 'blur' }
  ],
  address: [
    { required: true, message: '请输入店铺地址', trigger: 'blur' },
    { min: 5, max: 200, message: '店铺地址长度在 5 到 200 个字符', trigger: 'blur' }
  ],
  description: [
    { max: 500, message: '店铺简介长度不能超过 500 个字符', trigger: 'blur' }
  ]
}

// logo上传相关
const logoUploadRef = ref()

// 处理logo上传成功
const handleLogoUploadSuccess = (response) => {
  uploading.value = false
  if (response.success) {
    shopInfo.value.logo = response.url
    ElMessage.success('Logo上传成功')
    showLogoUploadDialog.value = false
  } else {
    ElMessage.error(response.message || 'Logo上传失败')
  }
}

// 处理logo上传失败
const handleLogoUploadError = (error) => {
  uploading.value = false
  console.error('Logo上传失败:', error)
  ElMessage.error('Logo上传失败')
}

// 上传前校验
const beforeLogoUpload = (file) => {
  const isAllowed = file.type === 'image/jpeg' || file.type === 'image/png' || file.type === 'application/pdf'
  const isLt5M = file.size / 1024 / 1024 < 5

  if (!isAllowed) {
    ElMessage.error('只能上传 JPG/PNG/PDF 格式的文件')
  }
  if (!isLt5M) {
    ElMessage.error('上传文件大小不能超过 5MB')
  }

  uploading.value = isAllowed && isLt5M
  return isAllowed && isLt5M
}

// 处理Logo文件选择
const handleLogoFileChange = (file: any) => {
  uploadLogoFile(file, (response) => {
    uploading.value = false
    if (response.success) {
      shopInfo.value.logo = response.url
      ElMessage.success('Logo上传成功')
      showLogoUploadDialog.value = false
    } else {
      ElMessage.error(response.message || 'Logo上传失败')
    }
  })
}

// 上传Logo文件
const uploadLogoFile = async (file: any, callback: (response: any) => void) => {
  // 验证文件
  const isAllowed = file.raw.type === 'image/jpeg' || file.raw.type === 'image/png' || file.raw.type === 'application/pdf'
  const isLt5M = file.raw.size / 1024 / 1024 < 5

  if (!isAllowed) {
    ElMessage.error('只能上传 JPG/PNG/PDF 格式的文件')
    callback({ success: false, message: '文件格式错误' })
    return
  }
  if (!isLt5M) {
    ElMessage.error('上传文件大小不能超过 5MB')
    callback({ success: false, message: '文件大小超过限制' })
    return
  }

  uploading.value = true

  // 创建FormData
  const formData = new FormData()
  formData.append('file', file.raw)

  try {
    // 使用axios上传文件
    const axios = (await import('@/axios')).default
    const response = await axios.post('/merchant/shop/upload-logo', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
    callback(response.data)
  } catch (error) {
    console.error('文件上传失败:', error)
    ElMessage.error('文件上传失败')
    callback({ success: false, message: '上传失败' })
  }
}

// 编辑店铺信息
const handleEditShopInfo = () => {
  // 初始化表单数据
  shopInfoForm.value = {
    shopName: shopInfo.value.shopName,
    shopType: shopInfo.value.shopType,
    phone: shopInfo.value.phone,
    email: shopInfo.value.email,
    address: shopInfo.value.address,
    description: shopInfo.value.description
  }
  shopInfoDialogVisible.value = true
}

// 提交店铺信息表单
const submitShopInfoForm = async () => {
  if (!shopInfoFormRef.value) return

  shopInfoFormRef.value.validate(async (valid: boolean) => {
    if (valid) {
      try {
        await updateShopInfo(shopInfoForm.value)
        // 更新店铺信息
        Object.assign(shopInfo.value, shopInfoForm.value)
        ElMessage.success('店铺信息更新成功')
        shopInfoDialogVisible.value = false
      } catch (error) {
        console.error('更新店铺信息失败:', error)
        ElMessage.error('更新店铺信息失败')
      }
    }
  })
}

// 处理营业执照上传成功
const handleBusinessLicenseUploadSuccess = (response) => {
  if (response.success) {
    authForm.value.businessLicense = response.url
    ElMessage.success('营业执照上传成功')
  } else {
    ElMessage.error(response.message || '营业执照上传失败')
  }
}

// 处理身份证正面上传成功
const handleIdCardFrontUploadSuccess = (response) => {
  if (response.success) {
    authForm.value.idCardFront = response.url
    ElMessage.success('身份证正面上传成功')
  } else {
    ElMessage.error(response.message || '身份证正面上传失败')
  }
}

// 处理身份证反面上传成功
const handleIdCardBackUploadSuccess = (response) => {
  if (response.success) {
    authForm.value.idCardBack = response.url
    ElMessage.success('身份证反面上传成功')
  } else {
    ElMessage.error(response.message || '身份证反面上传失败')
  }
}

// 处理上传错误
const handleUploadError = (error) => {
  console.error('文件上传失败:', error)
  ElMessage.error('文件上传失败')
}

// 文件上传前验证
const beforeFileUpload = (file) => {
  const isAllowed = file.type === 'image/jpeg' || file.type === 'image/png' || file.type === 'application/pdf'
  const isLt5M = file.size / 1024 / 1024 < 5

  if (!isAllowed) {
    ElMessage.error('只能上传 JPG/PNG/PDF 格式的文件')
  }
  if (!isLt5M) {
    ElMessage.error('上传文件大小不能超过 5MB')
  }

  return isAllowed && isLt5M
}

// 开始认证
const handleStartAuth = () => {
  // 重置认证表单
  authForm.value = {
    authType: '',
    businessLicense: '',
    idCardFront: '',
    idCardBack: ''
  }
  authDialogVisible.value = true
}

// 提交认证表单
const submitAuthForm = async () => {
  if (!authFormRef.value) return

  authFormRef.value.validate(async (valid: boolean) => {
    if (valid) {
      try {
        await submitAuthInfo(authForm.value)
        ElMessage.success('认证信息提交成功，请等待审核')
        authDialogVisible.value = false
        // 重新加载认证信息
        loadAuthInfo()
      } catch (error) {
        console.error('提交认证信息失败:', error)
        ElMessage.error('提交认证信息失败')
      }
    }
  })
}

// 判断是否为图片文件
const isImageFile = (fileUrl: string): boolean => {
  const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp']
  const lowerUrl = fileUrl.toLowerCase()
  return imageExtensions.some(ext => lowerUrl.endsWith(ext))
}

// 打开文件
const openFile = (fileUrl: string) => {
  // 构建完整的文件URL
  const fullUrl = window.location.origin + fileUrl
  window.open(fullUrl, '_blank')
}

// 处理营业执照文件选择
const handleBusinessLicenseFileChange = (file: any) => {
  uploadAuthFile(file, (response) => {
    if (response.success) {
      authForm.value.businessLicense = response.url
      ElMessage.success('营业执照上传成功')
    } else {
      ElMessage.error(response.message || '营业执照上传失败')
    }
  })
}

// 处理身份证正面文件选择
const handleIdCardFrontFileChange = (file: any) => {
  uploadAuthFile(file, (response) => {
    if (response.success) {
      authForm.value.idCardFront = response.url
      ElMessage.success('身份证正面上传成功')
    } else {
      ElMessage.error(response.message || '身份证正面上传失败')
    }
  })
}

// 处理身份证反面文件选择
const handleIdCardBackFileChange = (file: any) => {
  uploadAuthFile(file, (response) => {
    if (response.success) {
      authForm.value.idCardBack = response.url
      ElMessage.success('身份证反面上传成功')
    } else {
      ElMessage.error(response.message || '身份证反面上传失败')
    }
  })
}

// 上传认证文件
const uploadAuthFile = async (file: any, callback: (response: any) => void) => {
  // 验证文件
  const isAllowed = file.raw.type === 'image/jpeg' || file.raw.type === 'image/png' || file.raw.type === 'application/pdf'
  const isLt5M = file.raw.size / 1024 / 1024 < 5

  if (!isAllowed) {
    ElMessage.error('只能上传 JPG/PNG/PDF 格式的文件')
    return
  }
  if (!isLt5M) {
    ElMessage.error('上传文件大小不能超过 5MB')
    return
  }

  // 创建FormData
  const formData = new FormData()
  formData.append('file', file.raw)

  try {
    // 使用axios上传文件
    const axios = (await import('@/axios')).default
    const response = await axios.post('/merchant/shop/upload-auth-material', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
    callback(response.data)
  } catch (error) {
    console.error('文件上传失败:', error)
    ElMessage.error('文件上传失败')
    callback({ success: false, message: '上传失败' })
  }
}

// 修改密码相关
const changePasswordDialogVisible = ref(false)
const changePasswordForm = ref({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const changePasswordRules = {
  oldPassword: [
    { required: true, message: '请输入旧密码', trigger: 'blur' }
  ],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, max: 20, message: '密码长度在 6 到 20 个字符', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    { validator: (rule, value, callback) => {
        if (value !== changePasswordForm.value.newPassword) {
          callback(new Error('两次输入的密码不一致'))
        } else {
          callback()
        }
      }, trigger: 'blur' }
  ]
}

// 修改密码
const handleChangePassword = () => {
  changePasswordForm.value = {
    oldPassword: '',
    newPassword: '',
    confirmPassword: ''
  }
  changePasswordDialogVisible.value = true
}

// 提交修改密码
const submitChangePassword = async () => {
  try {
    await changePassword(changePasswordForm.value)
    ElMessage.success('密码修改成功')
    changePasswordDialogVisible.value = false
  } catch (error) {
    console.error('修改密码失败:', error)
    ElMessage.error('修改密码失败')
  }
}

// 设置支付密码相关
const setPayPasswordDialogVisible = ref(false)
const setPayPasswordForm = ref({
  payPassword: '',
  confirmPassword: ''
})

const setPayPasswordRules = {
  payPassword: [
    { required: true, message: '请输入支付密码', trigger: 'blur' },
    { pattern: /^\d{6}$/, message: '支付密码必须是6位数字', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认支付密码', trigger: 'blur' },
    { validator: (rule, value, callback) => {
        if (value !== setPayPasswordForm.value.payPassword) {
          callback(new Error('两次输入的密码不一致'))
        } else {
          callback()
        }
      }, trigger: 'blur' }
  ]
}

// 设置支付密码
const handleSetPayPassword = () => {
  setPayPasswordForm.value = {
    payPassword: '',
    confirmPassword: ''
  }
  setPayPasswordDialogVisible.value = true
}

// 提交设置支付密码
const submitSetPayPassword = async () => {
  try {
    await setPayPassword(setPayPasswordForm.value)
    ElMessage.success('支付密码设置成功')
    setPayPasswordDialogVisible.value = false
    // 重新加载安全设置
    loadSecurityInfo()
  } catch (error) {
    console.error('设置支付密码失败:', error)
    ElMessage.error('设置支付密码失败')
  }
}

// 更换手机号
const handleChangePhone = () => {
  ElMessage.info('更换手机号功能开发中')
  // TODO: 实现更换手机号功能
}

// 更换邮箱
const handleChangeEmail = () => {
  ElMessage.info('更换邮箱功能开发中')
  // TODO: 实现更换邮箱功能
}

// 安全退出
const handleLogout = () => {
  ElMessageBox.confirm('确定要退出登录吗？', '退出登录', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(() => {
    // 调用退出登录
    userStore.logout()
    router.push('/login')
    ElMessage.success('退出登录成功')
  }).catch(() => {
    // 取消退出
  })
}

// 加载店铺信息
const loadShopInfo = async () => {
  try {
    const response = await getShopInfo()
    console.log('获取店铺信息:', response)
    // 直接更新整个对象，确保响应式更新
    shopInfo.value = {
      shopName: response.shopName || '',
      shopType: response.shopType || '',
      status: response.status || '',
      openTime: response.openTime || '',
      phone: response.phone || '',
      email: response.email || '',
      address: response.address || '',
      description: response.description || '',
      logo: response.logo || ''
    }
  } catch (error) {
    console.error('获取店铺信息失败:', error)
    ElMessage.error('获取店铺信息失败')
  }
}

// 加载认证信息
const loadAuthInfo = async () => {
  try {
    const response = await getAuthInfo()
    console.log('获取认证信息:', response)
    // 直接更新整个对象，确保响应式更新
    authInfo.value = {
      status: response.status || '',
      authType: response.authType || '',
      authTime: response.authTime || '',
      rejectReason: response.rejectReason || '',
      businessLicense: response.businessLicense || '',
      idCardFront: response.idCardFront || '',
      idCardBack: response.idCardBack || ''
    }
  } catch (error) {
    console.error('获取认证信息失败:', error)
    ElMessage.error('获取认证信息失败')
  }
}

// 加载安全设置
const loadSecurityInfo = async () => {
  try {
    const response = await getSecurityInfo()
    console.log('获取安全设置:', response)
    // 直接更新整个对象，确保响应式更新
    securityInfo.value = {
      payPasswordSet: response.payPasswordSet || false
    }
  } catch (error) {
    console.error('获取安全设置失败:', error)
    ElMessage.error('获取安全设置失败')
  }
}

// 页面加载时初始化
onMounted(() => {
  // 加载店铺相关信息
  loadShopInfo()
  loadAuthInfo()
  loadSecurityInfo()
})
</script>

<style scoped>
.merchant-shop-management {
  padding: 20px;
}

.page-title {
  font-size: 24px;
  margin-bottom: 20px;
  color: #333;
}

.shop-tabs {
  background-color: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  padding: 20px;
}

.tab-content {
  padding: 10px 0;
}

/* 卡片样式 */
.shop-info-card, .shop-logo-card, .authentication-card, .security-card, .logout-card {
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* 店铺信息样式 */
.shop-info-content {
  margin-top: 20px;
}

/* 店铺logo样式 */
.shop-logo-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 20px;
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

/* Logo上传弹窗样式 */
.avatar-upload-content {
  padding: 10px 0;
}

/* 当前Logo预览样式 */
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

/* 认证信息样式 */
.authentication-status {
  margin-bottom: 30px;
}

.status-title {
  font-size: 16px;
  margin-bottom: 10px;
  font-weight: bold;
}

.status-info {
  display: flex;
  align-items: center;
  gap: 10px;
}

.reject-reason {
  color: #f56c6c;
}

.authentication-details {
  margin-bottom: 30px;
}

.details-title {
  font-size: 16px;
  margin-bottom: 15px;
  font-weight: bold;
}

/* 安全设置样式 */
.security-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding: 20px 0;
}

.security-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  background-color: #f5f7fa;
  border-radius: 8px;
}

.security-item-label {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 16px;
}

.security-item-action {
  display: flex;
  gap: 10px;
}

/* 退出登录样式 */
.logout-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 50px 0;
}

.logout-content h3 {
  font-size: 20px;
  margin-bottom: 10px;
  color: #333;
}

.logout-content p {
  margin-bottom: 30px;
  color: #606266;
}

/* 认证材料上传样式 */
.upload-area {
  border: 2px dashed #d9d9d9;
  border-radius: 6px;
  padding: 30px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
  background-color: #fafafa;
}

.upload-area:hover {
  border-color: #409eff;
  background-color: #f0f9ff;
}

.upload-icon {
  font-size: 48px;
  color: #c0c4cc;
  margin-bottom: 16px;
}

.upload-area span {
  display: block;
  font-size: 16px;
  color: #606266;
  margin-bottom: 8px;
}

.upload-tip {
  font-size: 12px;
  color: #909399;
  display: block;
  margin-top: 8px;
}

/* 隐藏默认的上传样式 */
:deep(.el-upload-dragger) {
  background-color: transparent;
  border: none;
  box-shadow: none;
  margin: 0;
  padding: 0;
}

:deep(.el-upload__text) {
  display: none;
}

:deep(.el-upload__tip) {
  margin-top: 10px;
  color: #909399;
}

/* 文件预览样式 */
.file-preview {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px;
  background-color: #f5f7fa;
  border-radius: 6px;
  border: 1px solid #ebeef5;
}

.image-preview {
  display: flex;
  align-items: center;
  gap: 10px;
}

.pdf-preview {
  display: flex;
  align-items: center;
  gap: 10px;
}

.pdf-icon {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 100px;
  height: 120px;
  background-color: #f0f9ff;
  border: 1px solid #d9ecff;
  border-radius: 6px;
  padding: 10px;
}

.pdf-icon-large {
  font-size: 48px;
  color: #409eff;
  margin-bottom: 10px;
}

.pdf-icon span {
  font-size: 14px;
  color: #606266;
}
</style>
