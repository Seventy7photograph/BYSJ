<template>
  <div class="merchant-management">
    <h2>商家账户管理</h2>
    <el-card shadow="hover" class="filter-card">
      <div class="filter-form">
        <el-form :inline="true" :model="searchForm" class="demo-form-inline">
          <el-form-item label="用户名">
            <el-input v-model="searchForm.username" placeholder="请输入用户名" clearable />
          </el-form-item>
          <el-form-item label="店铺名称">
            <el-input v-model="searchForm.shopName" placeholder="请输入店铺名称" clearable />
          </el-form-item>
          <el-form-item label="状态">
            <el-select v-model="searchForm.status" placeholder="请选择状态" clearable style="width: 150px">
              <el-option label="全部" value="" />
              <el-option label="正常" value="1" />
              <el-option label="禁用" value="0" />
              <el-option label="待审核" value="2" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleSearch">查询</el-button>
            <el-button @click="resetForm">重置</el-button>
          </el-form-item>
          <div class="batch-actions" v-if="selectedMerchants.length > 0">
            <el-button type="success" size="small" @click="handleBatchEnable" :disabled="!canBatchEnable">
              批量启用
            </el-button>
            <el-button type="danger" size="small" @click="handleBatchDisable" :disabled="!canBatchDisable">
              批量禁用
            </el-button>
          </div>
          <el-button type="info" size="small" @click="handleExport">
            导出
          </el-button>
        </el-form>
      </div>
    </el-card>
    <el-card shadow="hover" class="table-card">
      <el-table
        :data="merchantList"
        v-loading="loading"
        style="width: 100%"
        stripe
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column prop="userId" label="商家ID" width="100" />
        <el-table-column prop="username" label="用户名" />
        <el-table-column prop="shopName" label="店铺名称" />
        <el-table-column prop="shopStatus" label="店铺状态" width="120">
          <template #default="scope">
            <el-tag :type="getStatusTagType(scope.row.shopStatus)">
              {{ getShopStatusText(scope.row.shopStatus) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="phone" label="手机号" />
        <el-table-column prop="status" label="账号状态" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.status === 1 ? 'success' : 'danger'">
              {{ scope.row.status === 1 ? '正常' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" width="200" />
        <el-table-column prop="updateTime" label="更新时间" width="200" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="scope">
            <el-button
              type="primary"
              size="small"
              @click="handleEdit(scope.row)"
            >
              编辑
            </el-button>
            <el-button
              v-if="scope.row.shopStatus === 1"
              type="danger"
              size="small"
              @click="handleDisable(scope.row)"
            >
              禁用店铺
            </el-button>
            <el-button
              v-if="scope.row.shopStatus === 0"
              type="success"
              size="small"
              @click="handleEnable(scope.row)"
            >
              启用店铺
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pagination-container">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          :total="total"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 编辑商家抽屉 -->
    <el-drawer
      v-model="drawerVisible"
      title="编辑商家信息"
      direction="rtl"
      :size="500"
    >
      <el-form :model="form" label-position="top">
        <el-form-item label="用户名">
          <el-input v-model="form.username" disabled />
        </el-form-item>
        <el-form-item label="店铺名称">
          <el-input v-model="form.shopName" />
        </el-form-item>
        <el-form-item label="店铺地址">
          <el-input v-model="form.shopAddress" />
        </el-form-item>
        <el-form-item label="店铺简介">
          <el-input v-model="form.shopDescription" type="textarea" :rows="3" />
        </el-form-item>
        <el-form-item label="手机号">
          <el-input v-model="form.phone" />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="form.email" />
        </el-form-item>
        <el-form-item label="账户状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" />
        </el-form-item>
        <div class="drawer-footer">
          <el-button @click="drawerVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit">保存</el-button>
        </div>
      </el-form>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import axios from '@/axios'
import { ElMessage } from 'element-plus'

// 页面状态
const loading = ref(false)
const merchantList = ref<any[]>([])
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)
const drawerVisible = ref(false)

// 搜索表单
const searchForm = reactive({
  username: '',
  shopName: '',
  status: ''
})

// 编辑表单
const form = reactive({
  userId: 0,
  username: '',
  shopName: '',
  shopAddress: '',
  shopDescription: '',
  phone: '',
  email: '',
  status: 1
})

// 加载商家列表
const loadMerchants = async () => {
  loading.value = true
  try {
    const response = await axios.get('/admin/merchants', {
      params: {
        page: currentPage.value,
        pageSize: pageSize.value,
        username: searchForm.username,
        shopName: searchForm.shopName,
        status: searchForm.status
      }
    })
    merchantList.value = response.data.records || []
    total.value = response.data.total || 0
  } catch (error) {
    console.error('加载商家列表失败:', error)
    ElMessage.error('加载商家列表失败')
  } finally {
    loading.value = false
  }
}

// 页面加载时获取商家列表
onMounted(() => {
  loadMerchants()
})

// 查询
const handleSearch = () => {
  currentPage.value = 1
  loadMerchants()
}

// 重置表单
const resetForm = () => {
  searchForm.username = ''
  searchForm.shopName = ''
  searchForm.status = ''
  handleSearch()
}

// 编辑商家
const handleEdit = (row: any) => {
  form.userId = row.userId
  form.username = row.username
  form.shopName = row.shopName
  form.shopAddress = row.shopAddress
  form.shopDescription = row.shopDescription
  form.phone = row.phone
  form.email = row.email
  form.status = row.status
  drawerVisible.value = true
}

// 禁用商家
const handleDisable = async (row: any) => {
  try {
    await axios.put(`/admin/merchants/${row.userId}/status?status=0`)
    ElMessage.success('商家已禁用')
    loadMerchants()
  } catch (error) {
    console.error('禁用商家失败:', error)
    ElMessage.error('禁用商家失败')
  }
}

// 启用商家
const handleEnable = async (row: any) => {
  try {
    await axios.put(`/admin/merchants/${row.userId}/status?status=1`)
    ElMessage.success('商家已启用')
    loadMerchants()
  } catch (error) {
    console.error('启用商家失败:', error)
    ElMessage.error('启用商家失败')
  }
}

// 保存编辑
const handleSubmit = async () => {
  try {
    await axios.put(`/admin/merchants/${form.userId}`, null, {
      params: {
        username: form.username,
        shopName: form.shopName,
        shopAddress: form.shopAddress,
        shopDescription: form.shopDescription,
        phone: form.phone,
        email: form.email,
        status: form.status
      }
    })
    ElMessage.success('商家信息已更新')
    drawerVisible.value = false
    loadMerchants()
  } catch (error) {
    console.error('更新商家信息失败:', error)
    ElMessage.error('更新商家信息失败')
  }
}

// 分页处理
const handleSizeChange = (val: number) => {
  pageSize.value = val
  loadMerchants()
}

const handleCurrentChange = (val: number) => {
  currentPage.value = val
  loadMerchants()
}

// 辅助函数：获取店铺状态文本
const getShopStatusText = (status: number) => {
  switch (status) {
    case 0: return '关闭'
    case 1: return '正常'
    case 2: return '审核中'
    default: return '未知'
  }
}

// 辅助函数：获取店铺状态标签类型
const getStatusTagType = (status: number) => {
  switch (status) {
    case 0: return 'danger'
    case 1: return 'success'
    case 2: return 'warning'
    default: return 'info'
  }
}

// 选中的商家
const selectedMerchants = ref<any[]>([])

// 处理选择变化
const handleSelectionChange = (val: any[]) => {
  selectedMerchants.value = val
}

// 是否可以进行批量启用操作
const canBatchEnable = computed(() => {
  return selectedMerchants.value.length > 0 && selectedMerchants.value.every(merchant => merchant.status === 0)
})

// 是否可以进行批量禁用操作
const canBatchDisable = computed(() => {
  return selectedMerchants.value.length > 0 && selectedMerchants.value.every(merchant => merchant.status === 1)
})

// 批量启用商家
const handleBatchEnable = async () => {
  if (selectedMerchants.value.length === 0) {
    ElMessage.warning('请选择要启用的商家')
    return
  }

  if (!canBatchEnable.value) {
    ElMessage.warning('只有禁用状态的商家才能进行启用操作')
    return
  }

  ElMessageBox.confirm(`确定要启用选中的 ${selectedMerchants.value.length} 个商家吗？`, '批量启用商家', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'success'
  }).then(async () => {
    loading.value = true
    try {
      for (const merchant of selectedMerchants.value) {
        await axios.put(`/admin/merchants/${merchant.userId}/status?status=1`)
      }
      ElMessage.success('批量启用商家成功')
      loadMerchants()
      selectedMerchants.value = []
    } catch (error) {
      console.error('批量启用商家失败:', error)
      ElMessage.error('批量启用商家失败')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消操作
  })
}

// 批量禁用商家
const handleBatchDisable = async () => {
  if (selectedMerchants.value.length === 0) {
    ElMessage.warning('请选择要禁用的商家')
    return
  }

  if (!canBatchDisable.value) {
    ElMessage.warning('只有正常状态的商家才能进行禁用操作')
    return
  }

  ElMessageBox.confirm(`确定要禁用选中的 ${selectedMerchants.value.length} 个商家吗？`, '批量禁用商家', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    loading.value = true
    try {
      for (const merchant of selectedMerchants.value) {
        await axios.put(`/admin/merchants/${merchant.userId}/status?status=0`)
      }
      ElMessage.success('批量禁用商家成功')
      loadMerchants()
      selectedMerchants.value = []
    } catch (error) {
      console.error('批量禁用商家失败:', error)
      ElMessage.error('批量禁用商家失败')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消操作
  })
}

// 导出商家
const handleExport = async () => {
  try {
    const response = await axios.get('/admin/merchants', {
      params: {
        page: 1,
        pageSize: 1000,
        username: searchForm.username,
        shopName: searchForm.shopName,
        status: searchForm.status
      }
    })

    const merchants = response.data?.records || []
    const csvContent = generateMerchantCsvContent(merchants)
    downloadCsv(csvContent, `商家列表_${new Date().toISOString().split('T')[0]}.csv`)
    ElMessage.success('导出成功')
  } catch (error) {
    console.error('导出失败:', error)
    ElMessage.error('导出失败')
  }
}

// 生成商家CSV内容
const generateMerchantCsvContent = (merchants: any[]) => {
  const headers = ['商家ID', '用户名', '店铺名称', '店铺状态', '手机号', '账号状态', '创建时间', '更新时间']
  const rows = merchants.map(merchant => [
    merchant.userId,
    merchant.username,
    merchant.shopName,
    getShopStatusText(merchant.shopStatus),
    merchant.phone,
    merchant.status === 1 ? '正常' : '禁用',
    merchant.createTime,
    merchant.updateTime
  ])

  const csvRows = [headers, ...rows]
  return csvRows.map(row => row.join(',')).join('\n')
}

// 下载CSV文件
const downloadCsv = (content: string, filename: string) => {
  // 添加BOM字符以解决中文乱码问题
  const blob = new Blob(['\ufeff' + content], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  link.setAttribute('href', url)
  link.setAttribute('download', filename)
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}
</script>

<style scoped>
.merchant-management {
  padding: 0;
}

.merchant-management h2 {
  margin-bottom: 20px;
  color: #304156;
  font-size: 24px;
}

.filter-card {
  margin-bottom: 20px;
}

.filter-form {
  display: flex;
  justify-content: flex-start;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.batch-actions {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-left: auto;
}

@media screen and (max-width: 768px) {
  .batch-actions {
    margin-left: 0;
    width: 100%;
    justify-content: flex-start;
    margin-top: 10px;
  }
}

.table-card {
  margin-bottom: 20px;
}

.pagination-container {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}

.drawer-footer {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
  gap: 10px;
}
</style>
