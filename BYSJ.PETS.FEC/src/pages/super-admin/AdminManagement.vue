<template>
  <div class="admin-management">
    <h2>管理员管理</h2>
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
          <div class="batch-actions" v-if="selectedAdmins.length > 0">
            <el-button type="success" size="small" @click="handleBatchEnable" :disabled="!canBatchEnable">
              批量启用
            </el-button>
            <el-button type="danger" size="small" @click="handleBatchDisable" :disabled="!canBatchDisable">
              批量禁用
            </el-button>
            <el-button type="danger" size="small" @click="handleBatchDelete">
              批量删除
            </el-button>
          </div>
          <el-button type="info" size="small" @click="handleExport">
            导出
          </el-button>
        </el-form>
      </div>
    </el-card>
    <el-card shadow="hover" class="action-card">
      <div class="action-buttons">
        <el-button type="primary" @click="handleAdd">添加管理员</el-button>
        <el-button type="success" @click="handleRefresh">刷新管理员</el-button>
      </div>
    </el-card>
    <el-card shadow="hover" class="table-card">
      <el-table
        :data="adminList"
        v-loading="loading"
        style="width: 100%"
        stripe
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column prop="userId" label="管理员ID" width="100" />
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
        <el-table-column label="操作" width="250" fixed="right">
          <template #default="scope">
            <el-button
              type="warning"
              size="small"
              @click="handleEdit(scope.row)"
            >
              编辑
            </el-button>
            <el-button
              v-if="scope.row.status === 1"
              type="danger"
              size="small"
              @click="handleDisable(scope.row)"
            >
              禁用
            </el-button>
            <el-button
              v-if="scope.row.status === 0"
              type="success"
              size="small"
              @click="handleEnable(scope.row)"
            >
              启用
            </el-button>
            <el-button
              type="danger"
              size="small"
              @click="handleDelete(scope.row)"
            >
              删除
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

    <!-- 编辑管理员抽屉 -->
    <el-drawer
      v-model="drawerVisible"
      :title="form.userId ? '编辑管理员' : '新建管理员'"
      direction="rtl"
      :size="400"
    >
      <el-form :model="form" label-position="top" :rules="formRules" ref="formRef">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="form.username" placeholder="请输入用户名" />
        </el-form-item>
        <el-form-item label="昵称" prop="nickname">
          <el-input v-model="form.nickname" placeholder="请输入昵称" />
        </el-form-item>
        <el-form-item label="密码" prop="password" v-if="!form.userId">
          <el-input v-model="form.password" type="password" placeholder="请输入密码" />
        </el-form-item>
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="form.phone" placeholder="请输入手机号" />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="form.email" placeholder="请输入邮箱" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
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
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance } from 'element-plus'

// 页面状态
const loading = ref(false)
const adminList = ref<any[]>([])
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)
const drawerVisible = ref(false)
const formRef = ref<FormInstance>()

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
  password: '',
  phone: '',
  email: '',
  status: null
})

// 表单验证规则
const formRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 5, max: 50, message: '用户名长度在 5 到 50 个字符', trigger: 'blur' }
  ],
  nickname: [
    { required: true, message: '请输入昵称', trigger: 'blur' },
    { min: 2, max: 50, message: '昵称长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 20, message: '密码长度在 6 到 20 个字符', trigger: 'blur' }
  ],
  phone: [
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号', trigger: 'blur' }
  ],
  email: [
    { pattern: /^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+$/, message: '请输入正确的邮箱', trigger: 'blur' }
  ]
}

// 加载管理员列表
const loadAdmins = async () => {
  loading.value = true
  try {
    const response = await axios.get('/super-admin/admins', {
      params: {
        page: currentPage.value,
        pageSize: pageSize.value,
        username: searchForm.username,
        phone: searchForm.phone,
        status: searchForm.status
      }
    })
    adminList.value = response.data.records || []
    total.value = response.data.total || 0
  } catch (error) {
    console.error('加载管理员列表失败:', error)
    ElMessage.error('加载管理员列表失败')
  } finally {
    loading.value = false
  }
}

// 页面加载时获取管理员列表
onMounted(() => {
  loadAdmins()
})

// 查询
const handleSearch = () => {
  currentPage.value = 1
  loadAdmins()
}

// 重置表单
const resetForm = () => {
  searchForm.username = ''
  searchForm.phone = ''
  searchForm.status = ''
  handleSearch()
}

// 添加管理员
const handleAdd = () => {
  resetFormData()
  drawerVisible.value = true
}

// 编辑管理员
const handleEdit = (row: any) => {
  form.userId = row.userId
  form.username = row.username
  form.nickname = row.nickname
  form.phone = row.phone
  form.email = row.email
  form.status = row.status
  drawerVisible.value = true
}

// 禁用管理员
const handleDisable = async (row: any) => {
  try {
    await axios.put(`/super-admin/admins/${row.userId}/status?status=0`)
    ElMessage.success('管理员已禁用')
    loadAdmins()
  } catch (error) {
    console.error('禁用管理员失败:', error)
    ElMessage.error('禁用管理员失败')
  }
}

// 启用管理员
const handleEnable = async (row: any) => {
  try {
    await axios.put(`/super-admin/admins/${row.userId}/status?status=1`)
    ElMessage.success('管理员已启用')
    loadAdmins()
  } catch (error) {
    console.error('启用管理员失败:', error)
    ElMessage.error('启用管理员失败')
  }
}

// 删除管理员
const handleDelete = async (row: any) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除管理员 ${row.username} 吗？此操作不可恢复。`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    await axios.delete(`/super-admin/admins/${row.userId}`)
    ElMessage.success('管理员已删除')
    loadAdmins()
  } catch (error: any) {
    if (error.message !== 'cancel') {
      console.error('删除管理员失败:', error)
      ElMessage.error('删除管理员失败')
    }
  }
}

// 保存编辑
const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate(async (valid) => {
    if (valid) {
      try {
        if (form.userId) {
          // 更新管理员 - 只发送需要的字段，不包含密码
          const updateData = {
            username: form.username,
            nickname: form.nickname,
            phone: form.phone,
            email: form.email,
            status: form.status
          }
          await axios.put(`/super-admin/admins/${form.userId}`, updateData)
          ElMessage.success('管理员信息已更新')
        } else {
          // 添加管理员 - 直接发送密码（后端会进行BCrypt加密）
          const addData = {
            username: form.username,
            password: form.password,
            nickname: form.nickname,
            phone: form.phone,
            email: form.email,
            status: form.status || 1,
            roleId: 3 // 管理员角色ID
          }
          console.log('添加管理员请求数据:', addData)
          await axios.post('/super-admin/admins', addData)
          ElMessage.success('管理员添加成功')
        }
        drawerVisible.value = false
        loadAdmins()
      } catch (error) {
        console.error('保存管理员信息失败:', error)
        ElMessage.error('保存管理员信息失败')
      }
    }
  })
}

// 刷新管理员
const handleRefresh = () => {
  loadAdmins()
}

// 重置表单数据
const resetFormData = () => {
  form.userId = 0
  form.username = ''
  form.nickname = ''
  form.password = ''
  form.phone = ''
  form.email = ''
  form.status = null
  if (formRef.value) {
    formRef.value.resetFields()
  }
}

// 分页处理
const handleSizeChange = (val: number) => {
  pageSize.value = val
  loadAdmins()
}

const handleCurrentChange = (val: number) => {
  currentPage.value = val
  loadAdmins()
}

// 选中的管理员
const selectedAdmins = ref<any[]>([])

// 处理选择变化
const handleSelectionChange = (val: any[]) => {
  selectedAdmins.value = val
}

// 是否可以进行批量启用操作
const canBatchEnable = computed(() => {
  return selectedAdmins.value.length > 0 && selectedAdmins.value.every(admin => admin.status === 0)
})

// 是否可以进行批量禁用操作
const canBatchDisable = computed(() => {
  return selectedAdmins.value.length > 0 && selectedAdmins.value.every(admin => admin.status === 1)
})

// 批量启用管理员
const handleBatchEnable = async () => {
  if (selectedAdmins.value.length === 0) {
    ElMessage.warning('请选择要启用的管理员')
    return
  }

  if (!canBatchEnable.value) {
    ElMessage.warning('只有禁用状态的管理员才能进行启用操作')
    return
  }

  ElMessageBox.confirm(`确定要启用选中的 ${selectedAdmins.value.length} 个管理员吗？`, '批量启用管理员', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'success'
  }).then(async () => {
    loading.value = true
    try {
      for (const admin of selectedAdmins.value) {
        await axios.put(`/super-admin/admins/${admin.userId}/status?status=1`)
      }
      ElMessage.success('批量启用管理员成功')
      loadAdmins()
      selectedAdmins.value = []
    } catch (error) {
      console.error('批量启用管理员失败:', error)
      ElMessage.error('批量启用管理员失败')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消操作
  })
}

// 批量禁用管理员
const handleBatchDisable = async () => {
  if (selectedAdmins.value.length === 0) {
    ElMessage.warning('请选择要禁用的管理员')
    return
  }

  if (!canBatchDisable.value) {
    ElMessage.warning('只有正常状态的管理员才能进行禁用操作')
    return
  }

  ElMessageBox.confirm(`确定要禁用选中的 ${selectedAdmins.value.length} 个管理员吗？`, '批量禁用管理员', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    loading.value = true
    try {
      for (const admin of selectedAdmins.value) {
        await axios.put(`/super-admin/admins/${admin.userId}/status?status=0`)
      }
      ElMessage.success('批量禁用管理员成功')
      loadAdmins()
      selectedAdmins.value = []
    } catch (error) {
      console.error('批量禁用管理员失败:', error)
      ElMessage.error('批量禁用管理员失败')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消操作
  })
}

// 批量删除管理员
const handleBatchDelete = async () => {
  if (selectedAdmins.value.length === 0) {
    ElMessage.warning('请选择要删除的管理员')
    return
  }

  ElMessageBox.confirm(`确定要删除选中的 ${selectedAdmins.value.length} 个管理员吗？此操作不可恢复。`, '批量删除管理员', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    loading.value = true
    try {
      for (const admin of selectedAdmins.value) {
        await axios.delete(`/super-admin/admins/${admin.userId}`)
      }
      ElMessage.success('批量删除管理员成功')
      loadAdmins()
      selectedAdmins.value = []
    } catch (error) {
      console.error('批量删除管理员失败:', error)
      ElMessage.error('批量删除管理员失败')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消操作
  })
}

// 导出管理员
const handleExport = async () => {
  try {
    const response = await axios.get('/super-admin/admins', {
      params: {
        page: 1,
        pageSize: 1000,
        username: searchForm.username,
        phone: searchForm.phone,
        status: searchForm.status
      }
    })

    const admins = response.data?.records || []
    const csvContent = generateAdminCsvContent(admins)
    downloadCsv(csvContent, `管理员列表_${new Date().toISOString().split('T')[0]}.csv`)
    ElMessage.success('导出成功')
  } catch (error) {
    console.error('导出失败:', error)
    ElMessage.error('导出失败')
  }
}

// 生成管理员CSV内容
const generateAdminCsvContent = (admins: any[]) => {
  const headers = ['管理员ID', '用户名', '昵称', '手机号', '邮箱', '状态', '创建时间', '更新时间']
  const rows = admins.map(admin => [
    admin.userId,
    admin.username,
    admin.nickname,
    admin.phone,
    admin.email,
    admin.status === 1 ? '正常' : '禁用',
    admin.createTime,
    admin.updateTime
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
.admin-management {
  padding: 0;
}

.admin-management h2 {
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

.action-card {
  margin-bottom: 20px;
}

.action-buttons {
  display: flex;
  gap: 10px;
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
