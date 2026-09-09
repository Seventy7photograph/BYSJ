<template>
  <div class="address-page">
    <div class="page-header">
      <div class="header-left">
        <el-button type="text" @click="goBack" class="back-button">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
      </div>
      <h1>地址管理</h1>
    </div>

    <div v-loading="loading" class="address-content">
      <!-- 新增地址按钮 - 只在有地址时显示 -->
      <div v-if="addresses.length > 0" class="add-address-section">
        <el-button type="primary" @click="openAddAddressDialog">
          <el-icon><Plus /></el-icon>
          新增收货地址
        </el-button>
      </div>

      <!-- 地址列表 -->
      <div class="address-list" v-if="addresses.length > 0">
        <el-card
          v-for="address in addresses"
          :key="address.addressId"
          class="address-card"
          :class="{ 'default-address': address.isDefault }"
        >
          <template #header>
            <div class="address-header">
              <div class="address-info">
                <h3>{{ address.recipient }} {{ address.phone }}</h3>
                <p class="address-detail">{{ address.province }}{{ address.city }}{{ address.district }}{{ address.detail }}</p>
              </div>
              <div class="address-actions">
                <el-button
                  type="text"
                  size="small"
                  @click="openEditAddressDialog(address)"
                >
                  编辑
                </el-button>
                <el-button
                  type="text"
                  size="small"
                  @click="setDefaultAddress(address.addressId)"
                  :disabled="address.isDefault"
                >
                  {{ address.isDefault ? '默认地址' : '设为默认' }}
                </el-button>
                <el-button
                  type="text"
                  size="small"
                  text-color="#F56C6C"
                  @click="deleteAddress(address.addressId)"
                >
                  删除
                </el-button>
              </div>
            </div>
          </template>
        </el-card>
      </div>

      <!-- 空地址提示 -->
      <el-empty v-else description="暂无收货地址">
        <el-button type="primary" @click="openAddAddressDialog">
          <el-icon><Plus /></el-icon>
          新增收货地址
        </el-button>
      </el-empty>
    </div>

    <!-- 地址编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="500px"
      center
      @close="resetAddressForm"
    >
      <el-form
        ref="addressFormRef"
        :model="addressForm"
        label-position="left"
        label-width="80px"
        :rules="addressRules"
      >
        <el-form-item label="收货人" prop="recipient">
          <el-input
            v-model="addressForm.recipient"
            placeholder="请输入收货人姓名"
          />
        </el-form-item>

        <el-form-item label="手机号码" prop="phone">
          <el-input
            v-model="addressForm.phone"
            placeholder="请输入手机号码"
            maxlength="11"
          />
        </el-form-item>

        <el-form-item label="所在地区" prop="region">
          <!-- 编辑模式下显示已有的省市区信息 -->
          <div v-if="isEditing && addressForm.province && addressForm.city && addressForm.district" class="existing-region">
            <span class="existing-label">当前地区：</span>
            <span class="existing-value">{{ addressForm.province }}{{ addressForm.city }}{{ addressForm.district }}</span>
            <el-button type="text" size="small" @click="clearExistingRegion">修改</el-button>
          </div>
          <!-- 地址选择器 -->
          <el-cascader
            v-model="tempRegion"
            :options="regionOptions"
            :props="{
              value: 'label',
              label: 'label',
              children: 'children'
            }"
            :placeholder="isEditing && addressForm.province ? '选择新的省/市/区' : '请选择省/市/区'"
            @change="onRegionChange"
            clearable
          />
        </el-form-item>

        <el-form-item label="详细地址" prop="detail">
          <el-input
            v-model="addressForm.detail"
            placeholder="请输入详细地址"
            type="textarea"
            :rows="3"
          />
        </el-form-item>

        <el-form-item>
          <el-checkbox v-model="addressForm.isDefault">设为默认地址</el-checkbox>
        </el-form-item>
      </el-form>

      <template #footer>
        <span class="dialog-footer">
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="saveAddress" :loading="saving">
            保存
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ArrowLeft, Plus } from '@element-plus/icons-vue'
import { useUserStore } from '@/stores/user'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'
import { regionData } from 'element-china-area-data'
import { user } from '@/api'

const router = useRouter()
const userStore = useUserStore()

// 状态管理
const loading = ref(false)
const saving = ref(false)
const dialogVisible = ref(false)
const addressFormRef = ref()

// API 地址
const baseUrl = import.meta.env.VITE_API_BASE_URL || '/api'

// 地址列表
const addresses = ref([])

// 编辑对话框
const dialogTitle = ref('新增收货地址')
const isEditing = ref(false)

// 省市区数据
const regionOptions = ref(regionData)

// 地址表单
const addressForm = reactive({
  addressId: null,
  recipient: '',
  phone: '',
  province: '',
  city: '',
  district: '',
  region: [],
  detail: '',
  isDefault: false
})

// 临时存储地址选择器的值，避免自动展开三级菜单
const tempRegion = ref([])

// 表单验证规则
const addressRules = reactive({
  recipient: [
    { required: true, message: '请输入收货人姓名', trigger: 'blur' }
  ],
  phone: [
    { required: true, message: '请输入手机号码', trigger: 'blur' },
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号码', trigger: 'blur' }
  ],
  region: [
    { required: true, message: '请选择省/市/区', trigger: 'change' }
  ],
  detail: [
    { required: true, message: '请输入详细地址', trigger: 'blur' }
  ]
})

// 获取地址列表
const fetchAddresses = async () => {
  try {
    loading.value = true
    const response = await user.address.getAddressList()
    addresses.value = response || [] 
  } catch (error) {
    console.error('获取地址列表失败:', error)
    ElMessage.error('获取地址列表失败')
  } finally {
    loading.value = false
  }
}

// 打开新增地址对话框
const openAddAddressDialog = () => {
  // 重置表单验证
  if (addressFormRef.value) {
    addressFormRef.value.resetFields()
  }

  // 确保完全重置表单
  addressForm.addressId = null
  addressForm.recipient = ''
  addressForm.phone = ''
  addressForm.province = ''
  addressForm.city = ''
  addressForm.district = ''
  addressForm.region = []
  addressForm.detail = ''
  addressForm.isDefault = false

  // 重置临时变量
  tempRegion.value = []

  dialogTitle.value = '新增收货地址'
  isEditing.value = false
  dialogVisible.value = true
}

// 打开编辑地址对话框
const openEditAddressDialog = (address) => {
  // 重置表单
  resetAddressForm()

  // 复制地址数据
  Object.assign(addressForm, {
    ...address,
    // 确保isDefault是布尔类型
    isDefault: Boolean(address.isDefault)
  })

  // 设置省市区选择器的值
  // 根据省市区名称设置region数组
  if (address.province && address.city && address.district) {
    addressForm.region = [address.province, address.city, address.district]
  }

  dialogTitle.value = '编辑收货地址'
  isEditing.value = true
  dialogVisible.value = true
}

// 重置表单
const resetAddressForm = () => {
  // 重置表单验证
  if (addressFormRef.value) {
    addressFormRef.value.resetFields()
  }

  // 确保完全重置表单
  addressForm.addressId = null
  addressForm.recipient = ''
  addressForm.phone = ''
  addressForm.province = ''
  addressForm.city = ''
  addressForm.district = ''
  addressForm.region = []
  addressForm.detail = ''
  addressForm.isDefault = false

  // 重置临时变量
  tempRegion.value = []
}

// 清除已有的省市区信息，允许重新选择
const clearExistingRegion = () => {
  addressForm.province = ''
  addressForm.city = ''
  addressForm.district = ''
  addressForm.region = []
}

// 省市区选择变化处理
const onRegionChange = (value) => {
  if (value && value.length === 3) {
    addressForm.province = value[0]
    addressForm.city = value[1]
    addressForm.district = value[2]
    addressForm.region = value
    // 选择完成后清空临时变量，避免下次打开自动展开
    tempRegion.value = []
  }
}

// 保存地址
const saveAddress = async () => {
  if (!addressFormRef.value) return

  try {
    await addressFormRef.value.validate()
    saving.value = true

    // 准备提交数据，只发送后端需要的字段
    const submitData = {
      addressId: addressForm.addressId,
      recipient: addressForm.recipient,
      phone: addressForm.phone,
      province: addressForm.province,
      city: addressForm.city,
      district: addressForm.district,
      detail: addressForm.detail,
      // 将isDefault从布尔值转换为整数
      isDefault: addressForm.isDefault ? 1 : 0
    }

    let response
    if (isEditing.value) {
      // 更新地址
      response = await user.address.updateAddress(submitData)
    } else {
      // 新增地址
      response = await user.address.addAddress(submitData)
    }

    ElMessage.success(response.msg || '保存成功')
    dialogVisible.value = false
    fetchAddresses()
  } catch (error) {
    console.error('保存地址失败:', error)
    if (error.response && error.response.data) {
      ElMessage.error(error.response.data.msg || '保存失败')
    } else {
      ElMessage.error('保存地址失败')
    }
  } finally {
    saving.value = false
  }
}

// 设置默认地址
const setDefaultAddress = async (addressId) => {
  try {
    await user.address.setDefaultAddress(addressId)
    ElMessage.success('设置默认地址成功')
    fetchAddresses()
  } catch (error) {
    console.error('设置默认地址失败:', error)
    ElMessage.error('设置默认地址失败')
  }
}

// 删除地址
const deleteAddress = async (addressId) => {
  // 弹出确认删除提示
  ElMessageBox.confirm('确定要删除这个收货地址吗？', '删除确认', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    try {
      await user.address.deleteAddress(addressId)
      ElMessage.success('删除地址成功')
      fetchAddresses()
    } catch (error) {
      console.error('删除地址失败:', error)
      ElMessage.error('删除地址失败')
    }
  }).catch(() => {
    // 用户取消删除操作
  })
}

// 返回上一页
const goBack = () => {
  router.back()
}

onMounted(() => {
  fetchAddresses()
})
</script>

<style scoped>
.address-page {
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

.address-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.add-address-section {
  text-align: right;
}

.address-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 20px;
}

.address-card {
  transition: all 0.3s;
  position: relative;
}

.address-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.address-card.default-address {
  border-left: 4px solid #409EFF;
}

.address-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 20px;
}

.address-info h3 {
  margin: 0 0 10px 0;
  font-size: 18px;
  color: #333;
}

.address-detail {
  margin: 0;
  color: #666;
  line-height: 1.5;
}

.address-actions {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

/* 编辑模式下的已有地区样式 */
.existing-region {
  margin-bottom: 10px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.existing-label {
  color: #606266;
  font-size: 14px;
}

.existing-value {
  color: #303133;
  font-size: 14px;
  font-weight: 500;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .address-page {
    padding: 10px;
  }

  .address-list {
    grid-template-columns: 1fr;
  }

  .address-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .address-actions {
    flex-direction: row;
    gap: 10px;
    margin-top: 10px;
  }

  .existing-region {
    flex-direction: column;
    align-items: flex-start;
    gap: 5px;
  }
}
</style>
