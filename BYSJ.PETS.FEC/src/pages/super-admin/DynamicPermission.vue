<template>
  <div class="dynamic-permission">
    <h2>动态权限分配</h2>
    <el-card shadow="hover" class="role-card">
      <div class="role-selector">
        <el-form :inline="true" :model="roleForm" class="demo-form-inline">
          <el-form-item label="选择角色">
            <el-select v-model="roleForm.roleType" placeholder="请选择角色" @change="handleRoleChange">
              <el-option label="普通用户" value="1" />
              <el-option label="商家" value="2" />
              <el-option label="管理员" value="3" />
              <el-option label="超级管理员" value="4" />
            </el-select>
          </el-form-item>
          <el-form-item label="角色名称">
            <el-input v-model="roleForm.roleName" disabled />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleSavePermissions">保存权限分配</el-button>
            <el-button type="success" @click="handleRefresh">刷新权限</el-button>
          </el-form-item>
        </el-form>
      </div>
    </el-card>
    <el-card shadow="hover" class="permission-card">
      <div class="permission-content">
        <div class="permission-left">
          <h3>所有权限</h3>
          <el-tree
            ref="allPermissionsTreeRef"
            :data="permissionsTree"
            node-key="permissionId"
            :props="defaultProps"
            :expand-on-click-node="false"
            :default-expand-all="true"
            show-checkbox
            :check-on-click-node="true"
            :checked-keys="checkedPermissionIds"
            @check="handlePermissionCheck"
          >
            <template #default="{ node, data }">
              <span class="custom-tree-node">
                <span>{{ data.permissionName }}</span>
                <el-tag size="small" type="info">{{ data.permissionCode }}</el-tag>
              </span>
            </template>
          </el-tree>
        </div>
        <div class="permission-right">
          <h3>已分配权限</h3>
          <div v-if="roleForm.roleType" class="assigned-permissions">
            <el-tag
              v-for="permission in assignedPermissions"
              :key="permission.permissionId"
              closable
              @close="handleRemovePermission(permission)"
              class="assigned-tag"
            >
              {{ permission.permissionName }}
            </el-tag>
            <div v-if="assignedPermissions.length === 0" class="no-permissions">
              该角色尚未分配权限
            </div>
          </div>
          <div v-else class="no-role-selected">
            请选择角色查看已分配权限
          </div>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, watch } from 'vue'
import axios from '@/axios'
import { ElMessage } from 'element-plus'

// 页面状态
const loading = ref(false)
const permissionsTree = ref<any[]>([])
const allPermissionsTreeRef = ref<any>(null)

// 角色表单
const roleForm = reactive({
  roleType: '',
  roleName: ''
})

// 已分配权限ID列表
const checkedPermissionIds = ref<number[]>([])

// 所有权限列表
const allPermissions = ref<any[]>([])

// 计算属性：已分配权限列表
const assignedPermissions = computed(() => {
  const result = allPermissions.value.filter(p => {
    const isIncluded = checkedPermissionIds.value.includes(p.permissionId)
    console.log(`权限 ${p.permissionName} (${p.permissionId}) 是否在已分配列表中: ${isIncluded}`)
    return isIncluded
  })
  console.log('assignedPermissions:', result)
  console.log('checkedPermissionIds:', checkedPermissionIds.value)
  console.log('allPermissions length:', allPermissions.value.length)
  return result
})

// 树节点配置
const defaultProps = {
  children: 'children',
  label: 'permissionName'
}

// 加载权限树
const loadPermissionsTree = async () => {
  loading.value = true
  try {
    const response = await axios.get('/super-admin/permissions')
    // 检查 response.data 的结构
    console.log('权限树响应:', response)
    permissionsTree.value = response.data?.data || response.data || []
    // 清空 allPermissions 数组，避免重复数据
    allPermissions.value = []
    // 扁平化所有权限，方便查找
    flattenPermissions(permissionsTree.value, allPermissions.value)
    console.log('allPermissions:', allPermissions.value)
  } catch (error) {
    console.error('加载权限树失败:', error)
    ElMessage.error('加载权限树失败')
  } finally {
    loading.value = false
  }
}

// 加载角色权限
const loadRolePermissions = async (roleType: string) => {
  loading.value = true
  try {
    const response = await axios.get(`/super-admin/roles/${roleType}/permissions`)
    // 检查 response.data 的结构
    console.log('角色权限响应:', response)
    const permissions = response.data?.data || response.data || []
    console.log('加载角色权限:', permissions)
    // 提取权限ID列表
    checkedPermissionIds.value = permissions.map((p: any) => p.permissionId)
    console.log('checkedPermissionIds:', checkedPermissionIds.value)
    // 同步更新权限树的勾选状态
    if (allPermissionsTreeRef.value) {
      // 先清除所有勾选
      allPermissionsTreeRef.value.setCheckedKeys([])
      // 再设置勾选的权限
      allPermissionsTreeRef.value.setCheckedKeys(checkedPermissionIds.value)
      console.log('已更新权限树勾选状态')
    }
  } catch (error) {
    console.error('加载角色权限失败:', error)
    ElMessage.error('加载角色权限失败')
  } finally {
    loading.value = false
  }
}

// 页面加载时获取权限树
onMounted(() => {
  loadPermissionsTree()
})

// 角色变化处理
const handleRoleChange = (roleType: string) => {
  // 设置角色名称
  switch (roleType) {
    case '1': roleForm.roleName = '普通用户'; break
    case '2': roleForm.roleName = '商家'; break
    case '3': roleForm.roleName = '管理员'; break
    case '4': roleForm.roleName = '超级管理员'; break
    default: roleForm.roleName = ''
  }
  // 加载该角色的权限
  if (roleType) {
    loadRolePermissions(roleType)
  } else {
    checkedPermissionIds.value = []
  }
}

// 权限选中处理
const handlePermissionCheck = (data: any, checked: any, indeterminate: any) => {
  console.log('权限选中:', data, checked, indeterminate)
  // 获取当前树的所有勾选节点
  const checkedNodes = allPermissionsTreeRef.value.getCheckedKeys()
  console.log('当前勾选的权限:', checkedNodes)
  // 更新 checkedPermissionIds
  checkedPermissionIds.value = checkedNodes
  console.log('updated checkedPermissionIds:', checkedPermissionIds.value)
}

// 移除权限
const handleRemovePermission = (permission: any) => {
  console.log('移除权限:', permission)
  // 从已分配权限列表中移除
  const index = checkedPermissionIds.value.indexOf(permission.permissionId)
  if (index > -1) {
    checkedPermissionIds.value.splice(index, 1)
  }
  console.log('updated checkedPermissionIds after remove:', checkedPermissionIds.value)
  // 同步更新左边权限树的勾选状态
  if (allPermissionsTreeRef.value) {
    // 使用 setCheckedKeys 来更新所有勾选状态
    allPermissionsTreeRef.value.setCheckedKeys(checkedPermissionIds.value)
    console.log('已更新权限树勾选状态')
  }
}

// 保存权限分配
const handleSavePermissions = async () => {
  if (!roleForm.roleType) {
    ElMessage.warning('请先选择角色')
    return
  }
  try {
    const response = await axios.put(`/super-admin/roles/${roleForm.roleType}/permissions`, {
      permissionIds: checkedPermissionIds.value
    })
    ElMessage.success('权限分配保存成功')
  } catch (error) {
    console.error('保存权限分配失败:', error)
    ElMessage.error('保存权限分配失败')
  }
}

// 刷新权限
const handleRefresh = async () => {
  await loadPermissionsTree()
  if (roleForm.roleType) {
    await loadRolePermissions(roleForm.roleType)
  }
  console.log('权限已刷新')
}

// 辅助函数：扁平化权限列表
const flattenPermissions = (nodes: any[], result: any[]) => {
  for (const node of nodes) {
    console.log('扁平化权限:', node.permissionName, node.permissionId)
    result.push({
      permissionId: node.permissionId,
      permissionName: node.permissionName,
      permissionCode: node.permissionCode,
      url: node.url,
      method: node.method,
      parentId: node.parentId
    })
    if (node.children && node.children.length > 0) {
      flattenPermissions(node.children, result)
    }
  }
  console.log('扁平化完成，allPermissions length:', result.length)
}
</script>

<style scoped>
.dynamic-permission {
  padding: 0;
}

.dynamic-permission h2 {
  margin-bottom: 20px;
  color: #304156;
  font-size: 24px;
}

.role-card {
  margin-bottom: 20px;
}

.role-selector {
  display: flex;
  justify-content: flex-start;
  align-items: center;
}

.permission-card {
  margin-bottom: 20px;
}

.permission-content {
  display: flex;
  gap: 20px;
  height: 600px;
}

.permission-left {
  flex: 1;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  padding: 10px;
  overflow-y: auto;
}

.permission-left h3 {
  margin-top: 0;
  margin-bottom: 10px;
  color: #304156;
  font-size: 16px;
}

.permission-right {
  flex: 1;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  padding: 10px;
  overflow-y: auto;
}

.permission-right h3 {
  margin-top: 0;
  margin-bottom: 10px;
  color: #304156;
  font-size: 16px;
}

.assigned-permissions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.assigned-tag {
  margin: 5px;
  cursor: pointer;
}

.no-permissions {
  color: #909399;
  text-align: center;
  padding: 20px;
  font-size: 16px;
}

.no-role-selected {
  color: #909399;
  text-align: center;
  padding: 20px;
  font-size: 16px;
}

.custom-tree-node {
  display: flex;
  align-items: center;
  gap: 8px;
}
</style>
