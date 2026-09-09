<template>
  <div class="merchant-inventory-management">
    <h2 class="page-title">库存管理</h2>

    <!-- 筛选栏 -->
    <div class="filter-bar">
      <el-input placeholder="搜索商品名称" v-model="searchKeyword" clearable style="width: 200px; margin-right: 10px;">
        <template #prefix>
          <el-icon><Search /></el-icon>
        </template>
      </el-input>
      <el-select placeholder="商品类型" v-model="inventoryFilter.productType" style="width: 150px; margin-right: 10px;">
        <el-option label="全部" value="" />
        <el-option label="全新商品" value="new" />
        <el-option label="二手商品" value="used" />
        <el-option label="租赁商品" value="rental" />
      </el-select>
      <el-select placeholder="库存状态" v-model="inventoryFilter.stockStatus" style="width: 150px; margin-right: 10px;">
        <el-option label="全部" value="" />
        <el-option label="充足" value="sufficient" />
        <el-option label="预警" value="warning" />
        <el-option label="缺货" value="out" />
      </el-select>
      <el-button type="primary" @click="handleSearch">搜索</el-button>
      <el-button type="success" @click="handleBatchImport">批量导入</el-button>
      <div class="batch-actions" v-if="selectedInventory.length > 0">
        <el-button type="warning" size="small" @click="handleBatchAdjust">批量调整</el-button>
      </div>
      <el-button type="info" size="small" @click="handleExport">
        导出
      </el-button>
    </div>

    <!-- 库存列表 -->
    <div class="inventory-list">
      <el-table :data="filteredInventory" stripe style="width: 100%" v-loading="loading" @selection-change="handleSelectionChange">
        <el-table-column type="selection" width="55" />
        <el-table-column prop="productId" label="商品ID" width="80" />
        <el-table-column prop="productName" label="商品名称" min-width="200">
          <template #default="scope">
            <el-link type="primary" @click="handleViewProduct(scope.row)">{{ scope.row.productName }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="productType" label="商品类型" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.productType === 'new' ? 'success' : scope.row.productType === 'used' ? 'info' : 'warning'">
              {{ scope.row.productType === 'new' ? '全新' : scope.row.productType === 'used' ? '二手' : '租赁' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="skuAttribute" label="SKU属性" width="150" />
        <el-table-column prop="skuValue" label="SKU值" width="150" />
        <el-table-column prop="currentStock" label="当前库存" width="120">
          <template #default="scope">
            <div :class="getStockClass(scope.row.currentStock, scope.row.minStock)">
              {{ scope.row.currentStock }}
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="minStock" label="安全库存" width="100" />
        <el-table-column prop="sales" label="销量" width="80" />
        <el-table-column prop="lastUpdateTime" label="最后更新时间" width="180" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="scope">
            <el-button type="primary" size="small" @click="handleAdjustInventory(scope.row)">库存调整</el-button>
            <el-button type="success" size="small" @click="handleViewSku(scope.row)">SKU详情</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="pagination">
      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="pageSize"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        :total="filteredData.length"
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
      />
    </div>

    <!-- 库存调整弹窗 -->
    <el-dialog
      v-model="adjustDialogVisible"
      title="库存调整"
      width="500px"
    >
      <el-form
        ref="adjustFormRef"
        :model="adjustForm"
        :rules="adjustFormRules"
        label-width="120px"
      >
        <el-form-item label="商品名称" prop="productName">
          <el-input v-model="adjustForm.productName" disabled />
        </el-form-item>
        <el-form-item label="当前库存" prop="currentStock">
          <el-input v-model="adjustForm.currentStock" disabled />
        </el-form-item>
        <el-form-item label="安全库存" prop="minStock">
          <el-input-number
            v-model="adjustForm.minStock"
            :min="0"
            :step="1"
            placeholder="请输入安全库存"
          />
        </el-form-item>
        <el-form-item label="调整类型" prop="adjustType">
          <el-radio-group v-model="adjustForm.adjustType">
            <el-radio label="增加">增加</el-radio>
            <el-radio label="减少">减少</el-radio>
            <el-radio label="直接设置">直接设置</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="调整数量" prop="adjustQuantity">
          <el-input-number
            v-model="adjustForm.adjustQuantity"
            :min="adjustForm.adjustType === '减少' ? 1 : 0"
            :step="1"
            placeholder="请输入调整数量"
          />
        </el-form-item>
        <el-form-item label="调整原因" prop="reason">
          <el-input
            v-model="adjustForm.reason"
            type="textarea"
            :rows="3"
            placeholder="请输入调整原因"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="adjustDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="submitAdjustForm">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- SKU详情抽屉 -->
    <el-drawer
      v-model="skuDetailVisible"
      title="SKU详情"
      direction="rtl"
      size="50%"
    >
      <div v-if="currentSku" class="sku-detail">
        <h3 class="sku-title">{{ currentSku.productName }} - SKU详情</h3>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="商品ID">{{ currentSku.productId }}</el-descriptions-item>
          <el-descriptions-item label="商品类型">{{ currentSku.productType === 'new' ? '全新' : currentSku.productType === 'used' ? '二手' : '租赁' }}</el-descriptions-item>
          <el-descriptions-item label="SKU属性">{{ currentSku.skuAttribute }}</el-descriptions-item>
          <el-descriptions-item label="SKU值">{{ currentSku.skuValue }}</el-descriptions-item>
          <el-descriptions-item label="当前库存">{{ currentSku.currentStock }}</el-descriptions-item>
          <el-descriptions-item label="安全库存">{{ currentSku.minStock }}</el-descriptions-item>
          <el-descriptions-item label="销量">{{ currentSku.sales }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ currentSku.createTime }}</el-descriptions-item>
          <el-descriptions-item label="最后更新时间">{{ currentSku.lastUpdateTime }}</el-descriptions-item>
        </el-descriptions>

        <h4 class="sku-history-title">库存变更记录</h4>
        <el-table :data="skuHistory" stripe style="width: 100%" size="small">
          <el-table-column prop="changeTime" label="变更时间" width="180" />
          <el-table-column prop="changeType" label="变更类型" width="120">
            <template #default="scope">
              <el-tag :type="scope.row.changeType === '增加' ? 'success' : scope.row.changeType === '减少' ? 'danger' : 'warning'">
                {{ scope.row.changeType }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="beforeStock" label="变更前库存" width="120" />
          <el-table-column prop="afterStock" label="变更后库存" width="120" />
          <el-table-column prop="changeQuantity" label="变更数量" width="120" />
          <el-table-column prop="reason" label="变更原因" min-width="200" />
          <el-table-column prop="operator" label="操作人" width="100" />
        </el-table>
      </div>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import {
  InventoryItem,
  InventoryHistoryItem,
  getInventoryList,
  adjustInventory,
  getInventoryHistory
} from '@/api/merchant/inventory'

const router = useRouter()

// 搜索关键词
const searchKeyword = ref('')

// 库存筛选条件
const inventoryFilter = ref({
  productType: '',
  stockStatus: ''
})

// 加载状态
const loading = ref(false)

// 分页参数
const currentPage = ref(1)
const pageSize = ref(10)

// 库存数据
const inventoryList = ref<InventoryItem[]>([])
const skuHistory = ref<InventoryHistoryItem[]>([])

// 根据库存状态获取样式类
const getStockClass = (currentStock: number, minStock: number) => {
  if (currentStock <= 0) {
    return 'stock-out'
  } else if (currentStock < minStock) {
    return 'stock-warning'
  } else {
    return 'stock-sufficient'
  }
}

// 未分页的过滤数据
const filteredData = computed(() => {
  return inventoryList.value.filter(item => {
    // 商品名称筛选
    const matchesKeyword = searchKeyword.value === '' || item.productName.includes(searchKeyword.value)

    // 商品类型筛选
    const matchesType = inventoryFilter.value.productType === '' || item.productType === inventoryFilter.value.productType

    // 库存状态筛选
    let matchesStockStatus = true
    if (inventoryFilter.value.stockStatus) {
      if (inventoryFilter.value.stockStatus === 'out') {
        matchesStockStatus = item.currentStock <= 0
      } else if (inventoryFilter.value.stockStatus === 'warning') {
        matchesStockStatus = item.currentStock > 0 && item.currentStock < item.minStock
      } else if (inventoryFilter.value.stockStatus === 'sufficient') {
        matchesStockStatus = item.currentStock >= item.minStock
      }
    }

    return matchesKeyword && matchesType && matchesStockStatus
  })
})

// 分页后的库存列表
const filteredInventory = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredData.value.slice(start, end)
})

// 库存调整弹窗相关
const adjustDialogVisible = ref(false)
const adjustFormRef = ref()
const adjustForm = ref({
  productId: 0,
  productName: '',
  currentStock: 0,
  minStock: 10,
  adjustType: '增加',
  adjustQuantity: 0,
  reason: ''
})

const adjustFormRules = {
  adjustType: [
    { required: true, message: '请选择调整类型', trigger: 'change' }
  ],
  adjustQuantity: [
    { required: true, message: '请输入调整数量', trigger: 'blur' },
    { type: 'number', min: 1, message: '调整数量必须大于0', trigger: 'blur' }
  ],
  reason: [
    { max: 200, message: '调整原因长度不超过 200 个字符', trigger: 'blur' }
  ]
}

// SKU详情抽屉相关
const skuDetailVisible = ref(false)
const currentSku = ref<any>(null)

// 搜索库存
const handleSearch = () => {
  fetchInventoryList()
}

// 获取库存列表
const fetchInventoryList = async () => {
  loading.value = true
  try {
    const response = await getInventoryList({
      productType: inventoryFilter.value.productType,
      stockStatus: inventoryFilter.value.stockStatus,
      keyword: searchKeyword.value
    })
    inventoryList.value = response
  } catch (error) {
    console.error('获取库存列表失败:', error)
    ElMessage.error('获取库存列表失败')
  } finally {
    loading.value = false
  }
}

// 批量导入库存
const handleBatchImport = () => {
  ElMessage.info('批量导入功能开发中')
  // TODO: 实现批量导入功能
}

// 查看商品详情
const handleViewProduct = (row: any) => {
  router.push(`/merchant/product-edit/${row.productId}?type=${row.productType}`)
}

// 库存调整
const handleAdjustInventory = (row: any) => {
  adjustForm.value = {
    id: row.id,
    productId: row.productId,
    productName: row.productName,
    currentStock: row.currentStock,
    minStock: row.minStock,
    adjustType: '增加',
    adjustQuantity: 0,
    reason: ''
  }
  adjustDialogVisible.value = true
}

// 提交库存调整
const submitAdjustForm = async () => {
  if (!adjustFormRef.value) return

  adjustFormRef.value.validate(async (valid: boolean) => {
    if (valid) {
      try {
        await adjustInventory({
          inventoryId: adjustForm.value.id,
          adjustType: adjustForm.value.adjustType,
          adjustQuantity: adjustForm.value.adjustQuantity,
          reason: adjustForm.value.reason,
          minStock: adjustForm.value.minStock
        })

        // 计算调整后的库存
        let newStock = adjustForm.value.currentStock
        if (adjustForm.value.adjustType === '增加') {
          newStock += adjustForm.value.adjustQuantity
        } else if (adjustForm.value.adjustType === '减少') {
          newStock -= adjustForm.value.adjustQuantity
        } else if (adjustForm.value.adjustType === '直接设置') {
          newStock = adjustForm.value.adjustQuantity
        }

        // 更新库存列表中的数据
        const index = inventoryList.value.findIndex(item => item.id === adjustForm.value.id)
        if (index > -1) {
          const inventoryItem = inventoryList.value[index] as InventoryItem
          inventoryItem.currentStock = newStock
          inventoryItem.minStock = adjustForm.value.minStock
          inventoryItem.lastUpdateTime = new Date().toLocaleString()
        }

        ElMessage.success('库存调整成功')
        adjustDialogVisible.value = false
      } catch (error) {
        console.error('库存调整失败:', error)
        ElMessage.error('库存调整失败')
      }
    }
  })
}

// 查看SKU详情
const handleViewSku = async (row: any) => {
  currentSku.value = row
  skuDetailVisible.value = true

  // 获取SKU历史记录
  try {
    const response = await getInventoryHistory({
      inventoryId: row.id
    })
    skuHistory.value = response
  } catch (error) {
    console.error('获取SKU历史记录失败:', error)
    skuHistory.value = []
    ElMessage.error('获取SKU历史记录失败')
  }
}

// 分页处理
const handleSizeChange = (val: number) => {
  pageSize.value = val
  console.log(`每页 ${val} 条`)
}

const handleCurrentChange = (val: number) => {
  currentPage.value = val
  console.log(`当前页: ${val}`)
}

// 页面加载时初始化
onMounted(() => {
  fetchInventoryList()
})

// 选中的库存
const selectedInventory = ref<any[]>([])

// 处理选择变化
const handleSelectionChange = (val: any[]) => {
  selectedInventory.value = val
}

// 批量调整库存
const handleBatchAdjust = () => {
  if (selectedInventory.value.length === 0) {
    ElMessage.warning('请选择要调整的库存')
    return
  }

  ElMessage.info('批量调整功能开发中')
  // TODO: 实现批量调整功能
}

// 导出库存
const handleExport = async () => {
  try {
    const response = await getInventoryList({
      productType: inventoryFilter.value.productType,
      stockStatus: inventoryFilter.value.stockStatus,
      keyword: searchKeyword.value
    })

    const inventory = response
    const csvContent = generateInventoryCsvContent(inventory)
    downloadCsv(csvContent, `库存列表_${new Date().toISOString().split('T')[0]}.csv`)
    ElMessage.success('导出成功')
  } catch (error) {
    console.error('导出失败:', error)
    ElMessage.error('导出失败')
  }
}

// 生成库存CSV内容
const generateInventoryCsvContent = (inventory: any[]) => {
  const headers = ['商品ID', '商品名称', '商品类型', 'SKU属性', 'SKU值', '当前库存', '安全库存', '销量', '最后更新时间']
  const rows = inventory.map(item => [
    item.productId,
    item.productName,
    item.productType === 'new' ? '全新' : item.productType === 'used' ? '二手' : '租赁',
    item.skuAttribute,
    item.skuValue,
    item.currentStock,
    item.minStock,
    item.sales,
    item.lastUpdateTime
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
.merchant-inventory-management {
  padding: 20px;
}

.page-title {
  font-size: 24px;
  margin-bottom: 20px;
  color: #333;
}

.filter-bar {
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
}

.inventory-list {
  background-color: #fff;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  margin-bottom: 20px;
}

.pagination {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}

/* 库存状态样式 */
.stock-sufficient {
  color: #67c23a;
  font-weight: bold;
}

.stock-warning {
  color: #e6a23c;
  font-weight: bold;
}

.stock-out {
  color: #f56c6c;
  font-weight: bold;
}

/* SKU详情样式 */
.sku-detail {
  padding: 20px;
}

.sku-title {
  font-size: 18px;
  margin-bottom: 20px;
  color: #333;
  font-weight: bold;
}

.sku-history-title {
  font-size: 16px;
  margin: 20px 0 10px 0;
  color: #333;
  font-weight: bold;
}
</style>
