<template>
  <div class="user-management">
    <h2>普通用户管理</h2>
    <el-card shadow="hover" class="filter-card">
      <div class="filter-form">
        <el-form :inline="true" :model="searchForm" class="demo-form-inline">
          <el-form-item label="用户名">
            <el-input v-model="searchForm.username" placeholder="请输入用户名" clearable />
          </el-form-item>
          <el-form-item label="手机号">
            <el-input v-model="searchForm.phone" placeholder="请输入手机号" clearable />
          </el-form-item>
          <el-form-item label="状态">
            <el-select v-model="searchForm.status" placeholder="请选择状态" clearable style="width: 120px">
              <el-option label="全部" :value="null" />
              <el-option label="正常" :value="1" />
              <el-option label="禁用" :value="0" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleSearch">查询</el-button>
            <el-button @click="resetForm">重置</el-button>
          </el-form-item>
          <div class="batch-actions" v-if="selectedUsers.length > 0">
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
        :data="userList"
        v-loading="loading"
        style="width: 100%"
        stripe
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column prop="userId" label="用户ID" width="100" />
        <el-table-column prop="username" label="用户名" />
        <el-table-column prop="nickname" label="昵称" />
        <el-table-column prop="phone" label="手机号" />
        <el-table-column prop="email" label="邮箱" />
        <el-table-column prop="status" label="状态" width="100">
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
              v-if="scope.row.status === 1"
            >
              编辑
            </el-button>
            <el-button
              type="danger"
              size="small"
              @click="handleDisable(scope.row)"
              v-if="scope.row.status === 1"
            >
              禁用
            </el-button>
            <el-button
              type="success"
              size="small"
              @click="handleEnable(scope.row)"
              v-if="scope.row.status === 0"
            >
              启用
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

    <!-- 编辑用户抽屉 -->
    <el-drawer
      v-model="drawerVisible"
      title="编辑用户信息"
      direction="rtl"
      :size="300"
    >
      <el-form :model="form" label-position="top">
        <el-form-item label="用户名">
          <el-input v-model="form.username" disabled />
        </el-form-item>
        <el-form-item label="昵称">
          <el-input v-model="form.nickname" />
        </el-form-item>
        <el-form-item label="手机号">
          <el-input v-model="form.phone" />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="form.email" />
        </el-form-item>
        <el-form-item label="状态">
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
import { admin } from '@/api'

// 页面状态
const loading = ref(false)
const userList = ref<any[]>([])
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)
const drawerVisible = ref(false)

// 搜索表单
const searchForm = reactive({
  username: '',
  phone: '',
  status: ''
})

// 编辑表单
const form = reactive({
  userId: 0,
  username: '',
  nickname: '',
  phone: '',
  email: '',
  status: 1
})

// 加载用户列表
const loadUsers = async () => {
  loading.value = true
  try {
    const response = await admin.getUserList({
      pageNum: currentPage.value,
      pageSize: pageSize.value,
      keyword: searchForm.username || searchForm.phone,
      status: searchForm.status
    })
    userList.value = response.records || []
    total.value = response.total || 0
  } catch (error) {
    console.error('加载用户列表失败:', error)
    ElMessage.error('加载用户列表失败')
  } finally {
    loading.value = false
  }
}

// 页面加载时获取用户列表
onMounted(() => {
  loadUsers()
})

// 查询
const handleSearch = () => {
  currentPage.value = 1
  loadUsers()
}

// 重置表单
const resetForm = () => {
  searchForm.username = ''
  searchForm.phone = ''
  searchForm.status = ''
  handleSearch()
}

// 编辑用户
const handleEdit = (row: any) => {
  form.userId = row.userId
  form.username = row.username
  form.nickname = row.nickname
  form.phone = row.phone
  form.email = row.email
  form.status = row.status
  drawerVisible.value = true
}

// 禁用用户
const handleDisable = async (row: any) => {
  try {
    await admin.updateUserStatus(row.userId, 0)
    ElMessage.success('用户已禁用')
    loadUsers()
  } catch (error) {
    console.error('禁用用户失败:', error)
    ElMessage.error('禁用用户失败')
  }
}

// 启用用户
const handleEnable = async (row: any) => {
  try {
    await admin.updateUserStatus(row.userId, 1)
    ElMessage.success('用户已启用')
    loadUsers()
  } catch (error) {
    console.error('启用用户失败:', error)
    ElMessage.error('启用用户失败')
  }
}

// 保存编辑
const handleSubmit = async () => {
  try {
    await admin.updateUser(form.userId, {
      username: form.username,
      nickname: form.nickname,
      phone: form.phone,
      email: form.email,
      status: form.status
    })
    ElMessage.success('用户信息已更新')
    drawerVisible.value = false
    loadUsers()
  } catch (error) {
    console.error('更新用户信息失败:', error)
    ElMessage.error('更新用户信息失败')
  }
}

// 分页处理
const handleSizeChange = (val: number) => {
  pageSize.value = val
  loadUsers()
}

const handleCurrentChange = (val: number) => {
  currentPage.value = val
  loadUsers()
}

// 选中的用户
const selectedUsers = ref<any[]>([])

// 处理选择变化
const handleSelectionChange = (val: any[]) => {
  selectedUsers.value = val
}

// 是否可以进行批量启用操作
const canBatchEnable = computed(() => {
  return selectedUsers.value.length > 0 && selectedUsers.value.every(user => user.status === 0)
})

// 是否可以进行批量禁用操作
const canBatchDisable = computed(() => {
  return selectedUsers.value.length > 0 && selectedUsers.value.every(user => user.status === 1)
})

// 批量启用用户
const handleBatchEnable = async () => {
  if (selectedUsers.value.length === 0) {
    ElMessage.warning('请选择要启用的用户')
    return
  }

  if (!canBatchEnable.value) {
    ElMessage.warning('只有禁用状态的用户才能进行启用操作')
    return
  }

  ElMessageBox.confirm(`确定要启用选中的 ${selectedUsers.value.length} 个用户吗？`, '批量启用用户', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'success'
  }).then(async () => {
    loading.value = true
    try {
      for (const user of selectedUsers.value) {
        await admin.updateUserStatus(user.userId, 1)
      }
      ElMessage.success('批量启用用户成功')
      loadUsers()
      selectedUsers.value = []
    } catch (error) {
      console.error('批量启用用户失败:', error)
      ElMessage.error('批量启用用户失败')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消操作
  })
}

// 批量禁用用户
const handleBatchDisable = async () => {
  if (selectedUsers.value.length === 0) {
    ElMessage.warning('请选择要禁用的用户')
    return
  }

  if (!canBatchDisable.value) {
    ElMessage.warning('只有正常状态的用户才能进行禁用操作')
    return
  }

  ElMessageBox.confirm(`确定要禁用选中的 ${selectedUsers.value.length} 个用户吗？`, '批量禁用用户', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    loading.value = true
    try {
      for (const user of selectedUsers.value) {
        await admin.updateUserStatus(user.userId, 0)
      }
      ElMessage.success('批量禁用用户成功')
      loadUsers()
      selectedUsers.value = []
    } catch (error) {
      console.error('批量禁用用户失败:', error)
      ElMessage.error('批量禁用用户失败')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消操作
  })
}

// 导出用户
const handleExport = async () => {
  try {
    const response = await admin.getUserList({
      pageNum: 1,
      pageSize: 1000,
      keyword: searchForm.username || searchForm.phone,
      status: searchForm.status
    })

    const users = response.records || []
    const csvContent = generateUserCsvContent(users)
    downloadCsv(csvContent, `用户列表_${new Date().toISOString().split('T')[0]}.csv`)
    ElMessage.success('导出成功')
  } catch (error) {
    console.error('导出失败:', error)
    ElMessage.error('导出失败')
  }
}

// 生成用户CSV内容
const generateUserCsvContent = (users: any[]) => {
  const headers = ['用户ID', '用户名', '昵称', '手机号', '邮箱', '状态', '创建时间', '更新时间']
  const rows = users.map(user => [
    user.userId,
    user.username,
    user.nickname,
    user.phone,
    user.email,
    user.status === 1 ? '正常' : '禁用',
    user.createTime,
    user.updateTime
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
.user-management {
  padding: 0;
}

.user-management h2 {
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
