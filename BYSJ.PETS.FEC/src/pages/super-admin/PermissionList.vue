<template>
  <div class="permission-list">
    <h2>权限列表</h2>
    <el-card shadow="hover" class="action-card">
      <div class="action-buttons">
        <el-button type="primary" @click="handleAddRoot">添加顶级权限</el-button>
        <el-button type="success" @click="handleRefresh">刷新权限</el-button>
        <el-button type="danger" @click="handleBatchDelete" :disabled="selectedPermissions.length === 0">批量删除</el-button>
        <el-button type="info" @click="handleExport">导出权限</el-button>
      </div>
    </el-card>
    <el-card shadow="hover" class="tree-card">
      <div class="tree-content">
        <el-tree
          ref="permissionTreeRef"
          :data="permissionsTree"
          node-key="permissionId"
          :props="defaultProps"
          :expand-on-click-node="false"
          @node-click="handleNodeClick"
          :default-expand-all="true"
          :empty-text="'暂无权限'"
          show-checkbox
          @check-change="handleCheckChange"
        >
          <template #default="{ node, data }">
            <span class="custom-tree-node">
              <span class="permission-name">{{ data.permissionName }}</span>
              <span class="node-info">
                <el-tag size="small" type="info">{{ data.permissionCode }}</el-tag>
                <el-tag size="small" type="warning">{{ data.method }}</el-tag>
                <el-tag size="small" type="success">{{ data.url }}</el-tag>
              </span>
              <span class="node-actions">
                <el-button
                  type="primary"
                  size="small"
                  @click.stop="handleAddChild(data)"
                >
                  添加子权限
                </el-button>
                <el-button
                  type="warning"
                  size="small"
                  @click.stop="handleEdit(data)"
                >
                  编辑
                </el-button>
                <el-button
                  type="danger"
                  size="small"
                  @click.stop="handleDelete(data)"
                >
                  删除
                </el-button>
              </span>
            </span>
          </template>
        </el-tree>
      </div>
    </el-card>

    <!-- 权限编辑抽屉 -->
    <el-drawer
      v-model="drawerVisible"
      title="编辑权限"
      direction="rtl"
      :size="500"
    >
      <el-form :model="form" label-position="top" :rules="formRules" ref="formRef">
        <el-form-item label="权限名称" prop="permissionName">
          <el-input v-model="form.permissionName" placeholder="请输入权限名称" />
        </el-form-item>
        <el-form-item label="权限编码" prop="permissionCode">
          <el-input v-model="form.permissionCode" placeholder="请输入权限编码，如：PRODUCT_AUDIT" />
        </el-form-item>
        <el-form-item label="接口URL" prop="url">
          <el-input v-model="form.url" placeholder="请输入接口URL，如：/admin/product/audit" />
        </el-form-item>
        <el-form-item label="请求方法" prop="method">
          <el-select v-model="form.method" placeholder="请选择请求方法">
            <el-option label="GET" value="GET" />
            <el-option label="POST" value="POST" />
            <el-option label="PUT" value="PUT" />
            <el-option label="DELETE" value="DELETE" />
          </el-select>
        </el-form-item>
        <el-form-item label="父权限" v-if="isAddChild">
          <el-select v-model="form.parentId" disabled>
            <el-option :label="parentPermissionName" :value="form.parentId" />
          </el-select>
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
import { ref, reactive, onMounted } from 'vue'
import axios from '@/axios'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance } from 'element-plus'

// 页面状态
const loading = ref(false)
const permissionsTree = ref<any[]>([])
const permissionTreeRef = ref<any>(null)
const drawerVisible = ref(false)
const isAddChild = ref(false)
const parentPermissionName = ref('')
const formRef = ref<FormInstance>()
const selectedPermissions = ref<any[]>([])

// 表单数据
const form = reactive({
  permissionId: 0,
  permissionName: '',
  permissionCode: '',
  url: '',
  method: 'GET',
  parentId: 0
})

// 表单验证规则
const formRules = {
  permissionName: [
    { required: true, message: '请输入权限名称', trigger: 'blur' },
    { min: 2, max: 100, message: '权限名称长度在 2 到 100 个字符', trigger: 'blur' }
  ],
  permissionCode: [
    { required: true, message: '请输入权限编码', trigger: 'blur' },
    { pattern: /^[A-Z_]+$/, message: '权限编码只能包含大写字母和下划线', trigger: 'blur' }
  ],
  url: [
    { required: true, message: '请输入接口URL', trigger: 'blur' },
    { pattern: /^\/.+/, message: 'URL必须以/开头', trigger: 'blur' }
  ],
  method: [
    { required: true, message: '请选择请求方法', trigger: 'change' }
  ]
}

// 树节点配置
const defaultProps = {
  children: 'children',
  label: 'permissionName'
}

// 加载权限树
const loadPermissionsTree = async () => {
  loading.value = true
  try {
    console.log('开始请求权限列表...')
    const response = await axios.get('/super-admin/permissions')
    console.log('权限列表响应:', response)
    // axios拦截器已经处理了Result对象，直接使用response.data
    permissionsTree.value = response.data || []
    console.log('权限树数据:', permissionsTree.value)
  } catch (error) {
    console.error('加载权限树失败:', error)
    ElMessage.error('加载权限树失败')
  } finally {
    loading.value = false
  }
}

// 页面加载时获取权限树
onMounted(() => {
  loadPermissionsTree()
})

// 节点点击事件
const handleNodeClick = (data: any) => {
  console.log('节点点击:', data)
}

// 添加顶级权限
const handleAddRoot = () => {
  resetForm()
  form.parentId = null
  isAddChild.value = false
  drawerVisible.value = true
}

// 添加子权限
const handleAddChild = (data: any) => {
  resetForm()
  form.parentId = data.permissionId
  parentPermissionName.value = data.permissionName
  isAddChild.value = true
  drawerVisible.value = true
}

// 编辑权限
const handleEdit = (data: any) => {
  form.permissionId = data.permissionId
  form.permissionName = data.permissionName
  form.permissionCode = data.permissionCode
  form.url = data.url
  form.method = data.method
  if (data.parentId) {
    form.parentId = data.parentId
    isAddChild.value = true
    // 查找父权限名称
    const parentNode = findParentNode(permissionsTree.value, data.parentId)
    parentPermissionName.value = parentNode?.permissionName || ''
  } else {
    form.parentId = null
    isAddChild.value = false
    parentPermissionName.value = ''
  }
  drawerVisible.value = true
}

// 删除权限
const handleDelete = async (data: any) => {
  try {
    await ElMessageBox.confirm(
      '确认删除该权限吗？删除后无法恢复！',
      '删除确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    await axios.delete(`/super-admin/permissions/${data.permissionId}`)
    ElMessage.success('权限删除成功')
    loadPermissionsTree()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除权限失败:', error)
      ElMessage.error('删除权限失败')
    }
  }
}

// 保存权限
const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate(async (valid) => {
    if (valid) {
      try {
        if (form.permissionId) {
          // 更新权限
          await axios.put(`/super-admin/permissions/${form.permissionId}`, form)
          ElMessage.success('权限更新成功')
        } else {
          // 添加权限
          await axios.post('/super-admin/permissions', form)
          ElMessage.success('权限添加成功')
        }
        drawerVisible.value = false
        loadPermissionsTree()
      } catch (error) {
        console.error('保存权限失败:', error)
        ElMessage.error('保存权限失败')
      }
    }
  })
}

// 重置表单
const resetForm = () => {
  form.permissionId = 0
  form.permissionName = ''
  form.permissionCode = ''
  form.url = ''
  form.method = 'GET'
  form.parentId = null
  if (formRef.value) {
    formRef.value.resetFields()
  }
}

// 刷新权限
const handleRefresh = () => {
  loadPermissionsTree()
}

// 处理节点选中状态变化
const handleCheckChange = (data: any, checked: boolean, indeterminate: boolean) => {
  if (checked) {
    // 添加到选中列表
    selectedPermissions.value.push(data)
  } else {
    // 从选中列表移除
    selectedPermissions.value = selectedPermissions.value.filter(item => item.permissionId !== data.permissionId)
  }
}

// 批量删除权限
const handleBatchDelete = async () => {
  if (selectedPermissions.value.length === 0) {
    ElMessage.warning('请选择要删除的权限')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确认删除选中的 ${selectedPermissions.value.length} 个权限吗？删除后无法恢复！`,
      '批量删除确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    loading.value = true
    // 批量删除权限
    const deletePromises = selectedPermissions.value.map(permission =>
      axios.delete(`/super-admin/permissions/${permission.permissionId}`)
    )
    await Promise.all(deletePromises)
    ElMessage.success('批量删除权限成功')
    selectedPermissions.value = []
    loadPermissionsTree()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('批量删除权限失败:', error)
      ElMessage.error('批量删除权限失败')
    }
  } finally {
    loading.value = false
  }
}

// 导出权限
const handleExport = () => {
  if (permissionsTree.value.length === 0) {
    ElMessage.warning('暂无权限数据可导出')
    return
  }

  // 扁平化权限树
  const flattenPermissions = (nodes: any[]): any[] => {
    let result: any[] = []
    for (const node of nodes) {
      result.push(node)
      if (node.children && node.children.length > 0) {
        result = result.concat(flattenPermissions(node.children))
      }
    }
    return result
  }

  const flatPermissions = flattenPermissions(permissionsTree.value)

  // 生成CSV内容
  const headers = ['权限ID', '权限名称', '权限编码', '接口URL', '请求方法', '父权限ID']
  const rows = flatPermissions.map(permission => [
    permission.permissionId,
    permission.permissionName,
    permission.permissionCode,
    permission.url,
    permission.method,
    permission.parentId || ''
  ])

  // 组合CSV内容
  const csvContent = [
    headers.join(','),
    ...rows.map(row => row.join(','))
  ].join('\n')

  // 创建Blob对象
  const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' })

  // 创建下载链接
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  link.setAttribute('href', url)
  link.setAttribute('download', `permissions_${new Date().getTime()}.csv`)
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)

  ElMessage.success('权限导出成功')
}

// 辅助函数：查找父节点
const findParentNode = (nodes: any[], parentId: number): any => {
  for (const node of nodes) {
    if (node.permissionId === parentId) {
      return node
    }
    if (node.children && node.children.length > 0) {
      const result = findParentNode(node.children, parentId)
      if (result) {
        return result
      }
    }
  }
  return null
}
</script>

<style scoped>
.permission-list {
  padding: 0;
}

.permission-list h2 {
  margin-bottom: 20px;
  color: #304156;
  font-size: 24px;
}

.action-card {
  margin-bottom: 20px;
}

.action-buttons {
  display: flex;
  gap: 10px;
}

.tree-card {
  margin-bottom: 20px;
}

.tree-content {
  max-height: 600px;
  overflow-y: auto;
  padding: 10px;
  background-color: #f9f9f9;
  border-radius: 4px;
}

/* 优化树节点样式 */
:deep(.el-tree-node) {
  margin-bottom: 4px;
}

:deep(.el-tree-node__content) {
  height: auto;
  padding: 4px 0;
  line-height: 1.5;
}

.custom-tree-node {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 8px 12px;
  background-color: white;
  border-radius: 6px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  margin: 2px 0;
  transition: all 0.3s ease;
  min-height: 40px;
}

.custom-tree-node:hover {
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.15);
  transform: translateY(-1px);
}

/* 权限名称样式 */
.permission-name {
  font-weight: 600;
  color: #304156;
  font-size: 14px;
  min-width: 120px;
  flex-shrink: 0;
}

.node-info {
  display: flex;
  gap: 8px;
  margin-left: 0;
  flex-wrap: nowrap;
  padding-left: 0;
  flex: 1;
  overflow: hidden;
}

.node-info .el-tag {
  margin: 0;
  font-size: 11px;
  padding: 2px 6px;
  height: auto;
  line-height: 16px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 150px;
}

.node-actions {
  display: flex;
  gap: 6px;
  margin-left: 0;
  padding-left: 0;
  flex-shrink: 0;
}

.node-actions .el-button {
  margin-right: 0;
  padding: 4px 10px;
  font-size: 12px;
  height: auto;
  line-height: 18px;
}

/* 优化滚动条样式 */
.tree-content::-webkit-scrollbar {
  width: 6px;
}

.tree-content::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 3px;
}

.tree-content::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 3px;
}

.tree-content::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}

.drawer-footer {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
  gap: 10px;
  padding: 16px;
  border-top: 1px solid #eee;
  background-color: #fafafa;
}
</style>
