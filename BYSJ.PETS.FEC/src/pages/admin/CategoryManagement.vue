<template>
  <div class="category-management">
    <h2>商品分类管理</h2>
    <el-card shadow="hover" class="action-card">
      <div class="action-buttons">
        <el-button type="primary" @click="handleAddRoot">添加顶级分类</el-button>
        <el-button type="success" @click="handleRefresh">刷新分类</el-button>
      </div>
    </el-card>
    <el-card shadow="hover" class="tree-card">
      <div class="tree-content">
        <el-tree
          ref="categoryTreeRef"
          :data="categoriesTree"
          node-key="categoryId"
          :props="defaultProps"
          :expand-on-click-node="false"
          @node-click="handleNodeClick"
          @node-contextmenu="handleContextMenu"
          :default-expand-all="true"
        >
          <template #default="{ node, data }">
            <span class="custom-tree-node">
              <span>{{ data.categoryName }}</span>
              <span class="node-actions">
                <el-button
                  type="primary"
                  size="small"
                  @click.stop="handleAddChild(data)"
                  :disabled="data.level >= 3"
                >
                  添加子分类
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

    <!-- 分类编辑抽屉 -->
    <el-drawer
      v-model="drawerVisible"
      :title="isEditMode ? '编辑分类' : (isAddChild ? '添加子分类' : '添加顶级分类')"
      direction="rtl"
      :size="400"
    >
      <el-form :model="form" label-position="top" :rules="formRules" ref="formRef">
        <el-form-item label="分类名称" prop="categoryName">
          <el-input v-model="form.categoryName" placeholder="请输入分类名称" />
        </el-form-item>
        <el-form-item label="父分类" v-if="isAddChild">
          <el-select v-model="form.parentId" disabled>
            <el-option :label="parentCategoryName" :value="form.parentId" />
          </el-select>
        </el-form-item>
        <el-form-item label="分类编码" prop="categoryCode">
          <el-input v-model="form.categoryCode" placeholder="请输入分类编码" />
        </el-form-item>
        <el-form-item label="分类状态" prop="status">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" />
        </el-form-item>
        <el-form-item label="分类描述" prop="description">
          <el-input
            v-model="form.description"
            type="textarea"
            :rows="3"
            placeholder="请输入分类描述"
          />
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
const categoriesTree = ref<any[]>([])
const categoryTreeRef = ref<any>(null)
const drawerVisible = ref(false)
const isAddChild = ref(false)
const parentCategoryName = ref('')
const isEditMode = ref(false)
const formRef = ref<FormInstance>()

// 表单数据
const form = reactive({
  categoryId: 0,
  categoryName: '',
  parentId: null,
  categoryCode: '',
  sort: 0,
  status: 1,
  description: ''
})

// 表单验证规则
const formRules = {
  categoryName: [
    { required: true, message: '请输入分类名称', trigger: 'blur' },
    { min: 2, max: 50, message: '分类名称长度在 2 到 50 个字符', trigger: 'blur' }
  ],
  categoryCode: [
    { required: true, message: '请输入分类编码', trigger: 'blur' },
    { pattern: /^[A-Za-z0-9-]+$/, message: '分类编码只能包含字母、数字和连字符', trigger: 'blur' }
  ],
  sort: [
    { required: true, message: '请输入排序值', trigger: 'blur' },
    { type: 'number', min: 0, message: '排序值必须大于等于 0', trigger: 'blur' }
  ]
}

// 树节点配置
const defaultProps = {
  children: 'children',
  label: 'categoryName'
}

// 加载分类树
const loadCategoryTree = async () => {
  loading.value = true
  try {
    const response = await axios.get('/admin/categories/tree')
    categoriesTree.value = response.data
  } catch (error) {
    console.error('加载分类树失败:', error)
    ElMessage.error('加载分类树失败')
  } finally {
    loading.value = false
  }
}

// 页面加载时获取分类树
onMounted(() => {
  loadCategoryTree()
})

// 节点点击事件
const handleNodeClick = (data: any) => {
  console.log('节点点击:', data)
}

// 节点右键菜单
const handleContextMenu = (event: MouseEvent, data: any) => {
  event.preventDefault()
  console.log('节点右键:', data)
}

// 添加顶级分类
const handleAddRoot = () => {
  form.categoryId = 0
  form.categoryName = ''
  form.parentId = null
  form.categoryCode = ''
  form.sort = 0
  form.status = 1
  form.description = ''
  isAddChild.value = false
  isEditMode.value = false
  parentCategoryName.value = ''
  drawerVisible.value = true
}

// 添加子分类
const handleAddChild = (data: any) => {
  form.categoryId = 0
  form.categoryName = ''
  form.parentId = data.categoryId
  form.categoryCode = ''
  form.sort = 0
  form.status = 1
  form.description = ''
  parentCategoryName.value = data.categoryName
  isAddChild.value = true
  isEditMode.value = false
  drawerVisible.value = true
}

// 编辑分类
const handleEdit = (data: any) => {
  form.categoryId = data.categoryId
  form.categoryName = data.categoryName
  form.parentId = data.parentId
  form.categoryCode = data.categoryCode
  form.sort = data.sort
  form.status = data.status
  form.description = data.description || ''
  if (data.parentId) {
    isAddChild.value = true
    isEditMode.value = true
    // 查找父分类名称
    const parentNode = findParentNode(categoriesTree.value, data.parentId)
    parentCategoryName.value = parentNode?.categoryName || ''
  } else {
    isAddChild.value = false
    isEditMode.value = true
    parentCategoryName.value = ''
  }
  drawerVisible.value = true
}

// 删除分类
const handleDelete = async (data: any) => {
  try {
    await ElMessageBox.confirm(
      '确认删除该分类吗？删除后无法恢复！',
      '删除确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    await axios.delete(`/admin/categories/${data.categoryId}`)
    ElMessage.success('分类删除成功')
    loadCategoryTree()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除分类失败:', error)
      ElMessage.error('删除分类失败')
    }
  }
}

// 保存分类
const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate(async (valid) => {
    if (valid) {
      try {
        if (form.categoryId) {
  // 更新分类
  await axios.put(`/admin/categories/${form.categoryId}`, form)
  ElMessage.success('分类更新成功')
} else {
  // 添加分类
  await axios.post('/admin/categories', form)
  ElMessage.success('分类添加成功')
}
        drawerVisible.value = false
        loadCategoryTree()
      } catch (error) {
        console.error('保存分类失败:', error)
        ElMessage.error('保存分类失败')
      }
    }
  })
}

// 重置表单
const resetForm = () => {
  form.categoryId = 0
  form.categoryName = ''
  form.parentId = null
  form.categoryCode = ''
  form.sort = 0
  form.status = 1
  form.description = ''
  if (formRef.value) {
    formRef.value.resetFields()
  }
}

// 刷新分类
const handleRefresh = () => {
  loadCategoryTree()
}

// 辅助函数：查找父节点
const findParentNode = (nodes: any[], parentId: number): any => {
  for (const node of nodes) {
    if (node.categoryId === parentId) {
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
.category-management {
  padding: 0;
}

.category-management h2 {
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
}

.custom-tree-node {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  padding: 8px 0;
}

.node-actions {
  display: flex;
  gap: 5px;
}

.node-actions .el-button {
  margin-right: 0;
}

.drawer-footer {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
  gap: 10px;
}

:deep(.el-tree-node__content) {
  height: 40px;
  line-height: 40px;
}

:deep(.el-tree-node__children) {
  .el-tree-node__content {
    height: 40px;
    line-height: 40px;
  }
}
</style>
