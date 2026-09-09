<template>
  <div class="product-audit">
    <h2>商品审核</h2>
    <el-card shadow="hover" class="filter-card">
      <div class="filter-form">
        <!-- 审核状态切换按钮 -->
        <div class="status-buttons">
          <el-button-group>
            <el-button
              :type="activeStatus === 0 ? 'primary' : 'default'"
              @click="handleStatusChange(0)"
            >
              待审核
            </el-button>
            <el-button
              :type="activeStatus === 1 ? 'primary' : 'default'"
              @click="handleStatusChange(1)"
            >
              已通过
            </el-button>
            <el-button
              :type="activeStatus === 2 ? 'primary' : 'default'"
              @click="handleStatusChange(2)"
            >
              已驳回
            </el-button>
          </el-button-group>
        </div>

        <el-form :inline="true" :model="searchForm" class="demo-form-inline filter-form-right">
          <el-form-item label="商品名称">
            <el-input v-model="searchForm.productName" placeholder="请输入商品名称" clearable />
          </el-form-item>
          <el-form-item label="品牌">
            <el-input v-model="searchForm.brand" placeholder="请输入品牌" clearable />
          </el-form-item>
          <el-form-item label="型号">
            <el-input v-model="searchForm.model" placeholder="请输入型号" clearable />
          </el-form-item>
          <el-form-item label="商品类型">
            <el-select v-model="searchForm.productType" placeholder="请选择商品类型" clearable style="width: 150px">
              <el-option label="全部" value="" />
              <el-option label="全新商品" value="1" />
              <el-option label="二手商品" value="2" />
              <el-option label="租赁商品" value="3" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleSearch">查询</el-button>
            <el-button @click="resetForm">重置</el-button>
          </el-form-item>
          <div class="batch-actions" v-if="selectedProducts.length > 0">
            <el-button type="success" size="small" @click="handleBatchApprove" :disabled="!canBatchApprove">
              批量通过
            </el-button>
            <el-button type="danger" size="small" @click="handleBatchReject" :disabled="!canBatchReject">
              批量驳回
            </el-button>
            <el-button type="warning" size="small" @click="handleBatchForceOffline" :disabled="!canBatchForceOffline">
              批量强制下架
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
        :data="productList"
        v-loading="loading"
        style="width: 100%"
        stripe
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column prop="productId" label="商品ID" width="80" />
        <el-table-column prop="model" label="商品型号" min-width="200" />
        <el-table-column prop="brand" label="品牌" width="100">
          <template #default="scope">
            {{ scope.row.brandName || scope.row.brand }}
          </template>
        </el-table-column>
        <el-table-column prop="productType" label="商品类型" min-width="120">
          <template #default="scope">
            <el-tag :type="getProductTypeTagType(scope.row.productType)">
              {{ getProductTypeText(scope.row.productType) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="price" label="价格" min-width="120">
          <template #default="scope">
            {{ scope.row.productType === 3 ? `￥${scope.row.price}/天` : `￥${scope.row.price}` }}
          </template>
        </el-table-column>
        <el-table-column prop="stock" label="库存" min-width="80" />
        <el-table-column prop="auditStatus" label="审核状态" min-width="120">
          <template #default="scope">
            <el-tag :type="getAuditStatusTagType(scope.row.auditStatus)">
              {{ getAuditStatusText(scope.row.auditStatus) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" min-width="180" />
        <el-table-column label="操作" width="400" fixed="right">
          <template #default="scope">
            <div style="display: flex; gap: 8px;">
              <el-button
                type="primary"
                size="small"
                @click="viewProductDetail(scope.row)"
              >
                查看详情
              </el-button>
              <el-button
                v-if="scope.row.auditStatus === 0"
                type="success"
                size="small"
                @click="handleApprove(scope.row)"
              >
                审核通过
              </el-button>
              <el-button
                v-if="scope.row.auditStatus === 0"
                type="danger"
                size="small"
                @click="handleReject(scope.row)"
              >
                审核驳回
              </el-button>
              <el-button
                v-if="scope.row.auditStatus === 1"
                type="warning"
                size="small"
                @click="handleForceOffline(scope.row)"
              >
                强制下架
              </el-button>
              <el-button
                v-if="scope.row.auditStatus === 2"
                type="success"
                size="small"
                @click="handleCancelOffline(scope.row)"
              >
                撤销
              </el-button>
            </div>
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

    <!-- 审核驳回对话框 -->
    <el-dialog
      v-model="rejectDialogVisible"
      title="审核驳回"
      width="500px"
    >
      <el-form :model="rejectForm" label-position="top">
        <el-form-item label="驳回原因" required>
          <el-input
            v-model="rejectForm.rejectReason"
            type="textarea"
            :rows="4"
            placeholder="请输入审核驳回原因"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="rejectDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="confirmReject">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 商品详情查看对话框 -->
    <el-dialog
      v-model="detailDialogVisible"
      title="商品详情"
      width="800px"
    >
      <div v-if="currentProduct" class="product-detail-content">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="商品ID">{{ currentProduct.productId }}</el-descriptions-item>
          <el-descriptions-item label="商品型号">{{ currentProduct.model }}</el-descriptions-item>
          <el-descriptions-item label="品牌">{{ currentProduct.brandName || currentProduct.brand }}</el-descriptions-item>
          <el-descriptions-item label="商品类型">{{ getProductTypeText(currentProduct.productType) }}</el-descriptions-item>
          <el-descriptions-item label="价格">{{ currentProduct.productType === 3 ? `￥${currentProduct.price}/天` : `￥${currentProduct.price}` }}</el-descriptions-item>
          <el-descriptions-item label="库存">{{ currentProduct.stock }}</el-descriptions-item>
          <el-descriptions-item label="原价">{{ currentProduct.originalPrice }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ currentProduct.createTime }}</el-descriptions-item>
          <el-descriptions-item label="成色" v-if="currentProduct.condition">{{ currentProduct.condition === 1 ? '99新' : currentProduct.condition === 2 ? '95新' : currentProduct.condition === 3 ? '9新' : currentProduct.condition === 4 ? '8新' : '未知' }}</el-descriptions-item>
          <el-descriptions-item label="最短租赁期限" v-if="currentProduct.minRentalDays">{{ currentProduct.minRentalDays }}天</el-descriptions-item>
          <el-descriptions-item label="安全库存" v-if="currentProduct.minStock">{{ currentProduct.minStock }}</el-descriptions-item>
          <el-descriptions-item label="颜色" v-if="currentProduct.color">{{ currentProduct.color }}</el-descriptions-item>
          <el-descriptions-item label="审核状态">{{ getAuditStatusText(currentProduct.auditStatus) }}</el-descriptions-item>
          <el-descriptions-item label="上架状态">{{ currentProduct.isOnShelf === 1 ? '已上架' : '已下架' }}</el-descriptions-item>
          <el-descriptions-item label="驳回原因" v-if="currentProduct.rejectReason" :span="2">{{ currentProduct.rejectReason }}</el-descriptions-item>
          <el-descriptions-item label="商品简介" v-if="currentProduct.description" :span="2">{{ currentProduct.description }}</el-descriptions-item>
          <el-descriptions-item label="使用时长" v-if="currentProduct.usageDuration">{{ currentProduct.usageDuration }}</el-descriptions-item>
          <el-descriptions-item label="维修历史" v-if="currentProduct.repairHistory">{{ currentProduct.repairHistory === '0' ? '无' : currentProduct.repairHistory }}</el-descriptions-item>
          <el-descriptions-item label="配件" v-if="currentProduct.accessories" :span="2">{{ currentProduct.accessories }}</el-descriptions-item>
        </el-descriptions>

        <!-- 商品图片显示 -->
        <div v-if="currentProduct.images && currentProduct.images.length > 0" class="product-images">
          <h3>商品图片</h3>
          <div class="image-list">
            <el-image
              v-for="(image, index) in currentProduct.images"
              :key="index"
              :src="image.storagePath || image.imagePath || image"
              class="product-image"
              fit="cover"
              preview-teleported
            >
              <template #error>
                <div class="image-error">加载失败</div>
              </template>
            </el-image>
          </div>
        </div>
        <div v-else-if="currentProduct && !currentProduct.images" class="product-images">
          <h3>商品图片</h3>
          <div class="no-images">暂无图片</div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import axios from '@/axios'
import { ElMessage } from 'element-plus'

// 页面状态
const loading = ref(false)
const productList = ref<any[]>([])
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)

// 审核状态切换
const activeStatus = ref(0) // 默认选中待审核

// 搜索表单
const searchForm = reactive({
  productName: '',
  brand: '',
  model: '',
  productType: ''
})

// 审核驳回对话框
const rejectDialogVisible = ref(false)
const rejectForm = reactive({
  rejectReason: ''
})
const currentProductId = ref(0)

// 商品详情查看对话框
const detailDialogVisible = ref(false)
const currentProduct = ref<any>(null)

// 加载商品列表
const loadProducts = async () => {
  loading.value = true
  try {
    console.log('Loading products with auditStatus:', activeStatus.value)
    const response = await axios.get('/admin/products/audit', {
      params: {
        pageNum: currentPage.value,
        pageSize: pageSize.value,
        productName: searchForm.productName,
        brand: searchForm.brand,
        model: searchForm.model,
        productType: searchForm.productType,
        auditStatus: activeStatus.value,
        timestamp: new Date().getTime() // 防止缓存
      }
    })
    console.log('Response data:', response.data)
    productList.value = response.data.records || []
    total.value = response.data.total || 0
  } catch (error) {
    console.error('加载商品列表失败:', error)
    ElMessage.error('加载商品列表失败')
  } finally {
    loading.value = false
  }
}

// 切换审核状态
const handleStatusChange = (status: number) => {
  activeStatus.value = status
  currentPage.value = 1 // 切换状态时重置到第一页
  loadProducts()
}

// 页面加载时获取待审核商品列表
onMounted(() => {
  loadProducts()
})

// 查询
const handleSearch = () => {
  currentPage.value = 1
  loadProducts()
}

// 重置表单
const resetForm = () => {
  searchForm.productName = ''
  searchForm.brand = ''
  searchForm.model = ''
  searchForm.productType = ''
  handleSearch()
}

// 查看商品详情
const viewProductDetail = async (row: any) => {
  try {
    const response = await axios.get(`/admin/products/${row.productId}`)
    currentProduct.value = response.data
    detailDialogVisible.value = true
  } catch (error) {
    console.error('获取商品详情失败:', error)
    ElMessage.error('获取商品详情失败')
  }
}

// 审核通过
const handleApprove = async (row: any) => {
  try {
    await axios.put(`/admin/products/${row.productId}/audit`, {
      auditStatus: 1
    })
    ElMessage.success('审核通过')
    loadProducts()
  } catch (error) {
    console.error('审核通过失败:', error)
    ElMessage.error('审核通过失败')
  }
}

// 审核驳回
const handleReject = (row: any) => {
  currentProductId.value = row.productId
  rejectForm.rejectReason = ''
  rejectDialogVisible.value = true
}

// 确认驳回
const confirmReject = async () => {
  if (!rejectForm.rejectReason) {
    ElMessage.warning('请输入驳回原因')
    return
  }
  try {
    await axios.put(`/admin/products/${currentProductId.value}/audit`, {
      auditStatus: 2,
      rejectReason: rejectForm.rejectReason
    })
    ElMessage.success('审核驳回成功')
    rejectDialogVisible.value = false
    loadProducts()
  } catch (error) {
    console.error('审核驳回失败:', error)
    ElMessage.error('审核驳回失败')
  }
}

// 强制下架
const handleForceOffline = async (row: any) => {
  try {
    await axios.put(`/admin/products/${row.productId}/force-offline`)
    ElMessage.success('强制下架成功')
    loadProducts()
  } catch (error) {
    console.error('强制下架失败:', error)
    ElMessage.error('强制下架失败')
  }
}

// 撤销下架
const handleCancelOffline = async (row: any) => {
  try {
    await axios.put(`/admin/products/${row.productId}/cancel-offline`)
    ElMessage.success('撤销成功，待重新审核')
    loadProducts()
  } catch (error) {
    console.error('撤销失败:', error)
    ElMessage.error('撤销失败')
  }
}

// 分页处理
const handleSizeChange = (val: number) => {
  pageSize.value = val
  loadProducts()
}

const handleCurrentChange = (val: number) => {
  currentPage.value = val
  loadProducts()
}

// 辅助函数：获取商品类型文本
const getProductTypeText = (type: number) => {
  switch (type) {
    case 1: return '全新商品'
    case 2: return '二手商品'
    case 3: return '租赁商品'
    default: return '未知'
  }
}

// 辅助函数：获取商品类型标签类型
const getProductTypeTagType = (type: number) => {
  switch (type) {
    case 1: return 'success'
    case 2: return 'warning'
    case 3: return 'info'
    default: return 'info'
  }
}

// 辅助函数：获取审核状态文本
const getAuditStatusText = (status: number) => {
  switch (status) {
    case 0: return '待审核'
    case 1: return '审核通过'
    case 2: return '审核驳回'
    default: return '未知'
  }
}

// 辅助函数：获取审核状态标签类型
const getAuditStatusTagType = (status: number) => {
  switch (status) {
    case 0: return 'info'
    case 1: return 'success'
    case 2: return 'danger'
    default: return 'info'
  }
}

// 选中的商品
const selectedProducts = ref<any[]>([])

// 处理选择变化
const handleSelectionChange = (val: any[]) => {
  selectedProducts.value = val
}

// 是否可以进行批量通过操作
const canBatchApprove = computed(() => {
  return selectedProducts.value.length > 0 && selectedProducts.value.every(product => product.auditStatus === 0)
})

// 是否可以进行批量驳回操作
const canBatchReject = computed(() => {
  return selectedProducts.value.length > 0 && selectedProducts.value.every(product => product.auditStatus === 0)
})

// 是否可以进行批量强制下架操作
const canBatchForceOffline = computed(() => {
  return selectedProducts.value.length > 0 && selectedProducts.value.every(product => product.auditStatus === 1)
})

// 批量通过审核
const handleBatchApprove = async () => {
  if (selectedProducts.value.length === 0) {
    ElMessage.warning('请选择要审核的商品')
    return
  }

  if (!canBatchApprove.value) {
    ElMessage.warning('只有待审核的商品才能进行通过操作')
    return
  }

  ElMessageBox.confirm(`确定要通过选中的 ${selectedProducts.value.length} 个商品吗？`, '批量审核通过', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'success'
  }).then(async () => {
    loading.value = true
    try {
      for (const product of selectedProducts.value) {
        await axios.put(`/admin/products/${product.productId}/audit`, {
          auditStatus: 1
        })
      }
      ElMessage.success('批量审核通过成功')
      loadProducts()
      selectedProducts.value = []
    } catch (error) {
      console.error('批量审核通过失败:', error)
      ElMessage.error('批量审核通过失败')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消操作
  })
}

// 批量驳回审核
const handleBatchReject = () => {
  if (selectedProducts.value.length === 0) {
    ElMessage.warning('请选择要审核的商品')
    return
  }

  if (!canBatchReject.value) {
    ElMessage.warning('只有待审核的商品才能进行驳回操作')
    return
  }

  // 弹出驳回原因输入框
  ElMessageBox.prompt('请输入驳回原因', '批量审核驳回', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    inputPlaceholder: '请输入驳回原因',
    inputType: 'textarea'
  }).then(async ( { value } ) => {
    if (!value) {
      ElMessage.warning('请输入驳回原因')
      return
    }

    loading.value = true
    try {
      for (const product of selectedProducts.value) {
        await axios.put(`/admin/products/${product.productId}/audit`, {
          auditStatus: 2,
          rejectReason: value
        })
      }
      ElMessage.success('批量审核驳回成功')
      loadProducts()
      selectedProducts.value = []
    } catch (error) {
      console.error('批量审核驳回失败:', error)
      ElMessage.error('批量审核驳回失败')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消操作
  })
}

// 批量强制下架
const handleBatchForceOffline = async () => {
  if (selectedProducts.value.length === 0) {
    ElMessage.warning('请选择要操作的商品')
    return
  }

  if (!canBatchForceOffline.value) {
    ElMessage.warning('只有审核通过的商品才能进行强制下架操作')
    return
  }

  ElMessageBox.confirm(`确定要强制下架选中的 ${selectedProducts.value.length} 个商品吗？`, '批量强制下架', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    loading.value = true
    try {
      for (const product of selectedProducts.value) {
        await axios.put(`/admin/products/${product.productId}/force-offline`)
      }
      ElMessage.success('批量强制下架成功')
      loadProducts()
      selectedProducts.value = []
    } catch (error) {
      console.error('批量强制下架失败:', error)
      ElMessage.error('批量强制下架失败')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消操作
  })
}

// 导出商品
const handleExport = async () => {
  try {
    const response = await axios.get('/admin/products/audit', {
      params: {
        pageNum: 1,
        pageSize: 1000,
        productName: searchForm.productName,
        brand: searchForm.brand,
        model: searchForm.model,
        productType: searchForm.productType,
        auditStatus: activeStatus.value,
        timestamp: new Date().getTime()
      }
    })

    const products = response.data?.records || []
    const csvContent = generateProductCsvContent(products)
    downloadCsv(csvContent, `商品审核列表_${new Date().toISOString().split('T')[0]}.csv`)
    ElMessage.success('导出成功')
  } catch (error) {
    console.error('导出失败:', error)
    ElMessage.error('导出失败')
  }
}

// 生成商品CSV内容
const generateProductCsvContent = (products: any[]) => {
  const headers = ['商品ID', '商品型号', '品牌', '商品类型', '价格', '库存', '审核状态', '创建时间']
  const rows = products.map(product => [
    product.productId,
    product.model,
    product.brandName || product.brand,
    getProductTypeText(product.productType),
    product.price,
    product.stock,
    getAuditStatusText(product.auditStatus),
    product.createTime
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
.product-audit {
  padding: 0;
}

.product-audit h2 {
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
  gap: 20px;
  flex-wrap: nowrap;
}

.status-buttons {
  margin: 0;
}

.filter-form-right {
  display: flex;
  align-items: center;
  margin: 0;
  flex: 1;
  justify-content: flex-end;
  flex-wrap: wrap;
  gap: 10px;
}

.batch-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

@media screen and (max-width: 768px) {
  .batch-actions {
    width: 100%;
    justify-content: flex-start;
    margin-top: 10px;
  }
}

.filter-form-right .el-form-item {
  margin-bottom: 0;
}

/* 调整按钮组样式 */
:deep(.el-button-group) {
  margin-right: 10px;
}

:deep(.el-button-group .el-button) {
  border-radius: 0;
}

:deep(.el-button-group .el-button:first-child) {
  border-top-left-radius: 4px;
  border-bottom-left-radius: 4px;
}

:deep(.el-button-group .el-button:last-child) {
  border-top-right-radius: 4px;
  border-bottom-right-radius: 4px;
}

/* 增加表格行高 */
:deep(.el-table__row) {
  height: 60px;
}

/* 调整单元格内边距 */
:deep(.el-table__cell) {
  padding: 12px 0;
}

.table-card {
  margin-bottom: 20px;
}

.pagination-container {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}

.product-detail-content {
  padding: 20px 0;
}

.product-images {
  margin-top: 20px;
}

.product-images h3 {
  margin-bottom: 10px;
  font-size: 16px;
  color: #304156;
}

.image-list {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.product-image {
  width: 150px;
  height: 150px;
  cursor: pointer;
  border: 1px solid #ebeef5;
  border-radius: 4px;
}

.no-images {
  padding: 40px 0;
  text-align: center;
  color: #909399;
  background-color: #f5f7fa;
  border: 1px dashed #ebeef5;
  border-radius: 4px;
  margin-top: 10px;
}

.image-error {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f5f7fa;
  color: #909399;
}
</style>
