<template>
  <div class="brand-management">
    <h2>商品品牌管理</h2>
    <el-card shadow="hover" class="action-card">
      <div class="action-buttons">
        <el-button type="primary" @click="handleAdd">新增品牌大类</el-button>
        <el-button type="success" @click="loadBrandList">刷新品牌</el-button>
      </div>
    </el-card>
    <el-card shadow="hover" class="table-card">
      <el-table
        :data="brandTree"
        border
        stripe
        style="width: 100%"
        row-key="brandId"
        :tree-props="{ children: 'children', hasChildren: 'hasChildren' }"
        :default-expand-all="false"
      >
        <el-table-column prop="brandId" label="ID" width="80" />
        <el-table-column prop="brandName" label="品牌名称" width="200">
          <template #default="{ row }">
            <span :class="{ 'parent-brand': row.parentId === null || row.parentId === 0 }">
              {{ row.brandName }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="categoryCode" label="分类编码" width="150" />
        <el-table-column prop="sort" label="排序" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'">
              {{ row.status === 1 ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="描述" min-width="150" />
        <el-table-column prop="createTime" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDate(row.createTime) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="280" fixed="right">
          <template #default="{ row }">
            <div class="action-buttons">
              <el-button
                type="primary"
                size="small"
                @click="handleAddChild(row)"
              >
                添加子品牌
              </el-button>
              <el-button
                type="warning"
                size="small"
                @click="handleEdit(row)"
              >
                编辑
              </el-button>
              <el-button
                type="danger"
                size="small"
                @click="handleDelete(row)"
              >
                删除
              </el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-drawer v-model="drawerVisible" :title="isEditMode ? '品牌信息' : (form.parentId === null || form.parentId === 0) ? '品牌大类信息' : '品牌信息'" size="40%" :before-close="handleClose">
      <el-form :model="form" :rules="formRules" ref="formRef" label-width="100px">
        <el-form-item :label="(form.parentId === null || form.parentId === 0) ? '大类名称' : '品牌名称'" prop="brandName">
          <el-input v-model="form.brandName" :placeholder="(form.parentId === null || form.parentId === 0) ? '请输入大类名称' : '请输入品牌名称'" />
        </el-form-item>
        <el-form-item :label="(form.parentId === null || form.parentId === 0) ? '大类编码' : '分类编码'" prop="categoryCode">
          <el-input v-model="form.categoryCode" :placeholder="(form.parentId === null || form.parentId === 0) ? '请输入大类编码' : '请输入分类编码'" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input
            v-model="form.description"
            type="textarea"
            :rows="3"
            placeholder="请输入品牌描述"
          />
        </el-form-item>
      </el-form>
      <div class="drawer-footer">
        <el-button @click="drawerVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">保存</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from '@/axios'

const drawerVisible = ref(false)
const brandList = ref([])
const formRef = ref()
const isEditMode = ref(false)
const parentBrandName = ref('')

const form = reactive({
  brandId: 0,
  brandName: '',
  categoryCode: '',
  sort: 0,
  status: 1,
  description: '',
  parentId: null
})

const formRules = {
  brandName: [
    { required: true, message: '请输入品牌名称', trigger: 'blur' }
  ],
  categoryCode: [
    { required: true, message: '请输入分类编码', trigger: 'blur' }
  ],
  sort: [
    { required: true, message: '请输入排序', trigger: 'blur' }
  ]
}

const loadBrandList = async () => {
  try {
    const response = await axios.get('/admin/brands')
    brandList.value = response.data
  } catch (error) {
    console.error('加载品牌列表失败:', error)
    ElMessage.error('加载品牌列表失败')
  }
}

const buildBrandTree = (brands: any[]) => {
  const brandMap = new Map()
  const tree: any[] = []

  brands.forEach(brand => {
    brandMap.set(brand.brandId, { ...brand, children: [] })
  })

  brands.forEach(brand => {
    if (brand.parentId === null || brand.parentId === 0) {
      tree.push(brandMap.get(brand.brandId))
    } else {
      const parent = brandMap.get(brand.parentId)
      if (parent) {
        parent.children.push(brandMap.get(brand.brandId))
      }
    }
  })

  return tree
}

const brandTree = computed(() => {
  return buildBrandTree(brandList.value)
})

const handleAdd = () => {
  form.brandId = 0
  form.brandName = ''
  form.categoryCode = ''
  form.sort = 0
  form.status = 1
  form.description = ''
  form.parentId = null
  parentBrandName.value = ''
  isEditMode.value = false
  drawerVisible.value = true
}

const handleAddChild = (row: any) => {
  form.brandId = 0
  form.brandName = ''
  form.categoryCode = ''
  form.sort = row.sort + 1
  form.status = 1
  form.description = ''
  form.parentId = row.brandId
  parentBrandName.value = row.brandName
  isEditMode.value = false
  drawerVisible.value = true
}

const handleEdit = (row: any) => {
  form.brandId = row.brandId
  form.brandName = row.brandName
  form.categoryCode = row.categoryCode
  form.sort = row.sort
  form.status = row.status
  form.description = row.description
  form.parentId = row.parentId
  parentBrandName.value = row.parentId ? findBrandName(row.parentId) : ''
  isEditMode.value = true
  drawerVisible.value = true
}

const findBrandName = (parentId: number) => {
  const findInList = (list: any[], id: number): string => {
    for (const item of list) {
      if (item.brandId === id) {
        return item.brandName
      }
      if (item.children && item.children.length > 0) {
        const found = findInList(item.children, id)
        if (found) return found
      }
    }
    return ''
  }
  return findInList(brandTree.value, parentId)
}

const handleDelete = async (row: any) => {
  try {
    await ElMessageBox.confirm('确定要删除该品牌吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    await axios.delete(`/admin/brands/${row.brandId}`)
    ElMessage.success('删除成功')
    loadBrandList()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除品牌失败:', error)
      ElMessage.error('删除品牌失败')
    }
  }
}

const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate(async (valid) => {
    if (valid) {
      try {
        // 检查品牌名称和分类编码的组合是否已存在
        const isDuplicate = brandList.value.some(brand =>
          brand.brandName === form.brandName && brand.categoryCode === form.categoryCode
        )

        if (isDuplicate) {
          ElMessage.error('品牌名称和分类编码的组合已存在，请修改后重试')
          return
        }

        if (form.brandId) {
          await axios.put(`/admin/brands/${form.brandId}`, form)
          ElMessage.success('更新成功')
        } else {
          await axios.post('/admin/brands', form)
          ElMessage.success('添加成功')
        }
        drawerVisible.value = false
        loadBrandList()
      } catch (error) {
        console.error('保存品牌失败:', error)
        ElMessage.error('保存品牌失败')
      }
    }
  })
}

const handleClose = () => {
  formRef.value?.resetFields()
  drawerVisible.value = false
}

const formatDate = (date: string) => {
  if (!date) return ''
  return new Date(date).toLocaleString('zh-CN')
}

onMounted(() => {
  loadBrandList()
})
</script>

<style scoped>
.brand-management {
  padding: 0;
}

.brand-management h2 {
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

.table-card {
  margin-bottom: 20px;
}

.drawer-footer {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
  gap: 10px;
}

:deep(.el-table__expand-icon) {
  color: #409EFF;
}

:deep(.el-table__row) {
  transition: background-color 0.3s;
}

:deep(.el-table__row:hover) {
  background-color: #f5f7fa;
}

.parent-brand {
  background-color: #409EFF;
  color: #fff;
  padding: 6px 12px;
  border-radius: 4px;
  font-weight: bold;
  box-shadow: 0 2px 4px rgba(64, 158, 255, 0.3);
}

.action-buttons {
  display: flex;
  gap: 5px;
  flex-wrap: wrap;
}

.action-buttons .el-button {
  margin: 0;
}
</style>
