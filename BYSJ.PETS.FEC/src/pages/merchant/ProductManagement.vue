<template>
  <div class="merchant-product-management">
    <!-- 面包屑导航 -->
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item :to="'/merchant-dashboard'">后台首页</el-breadcrumb-item>
      <el-breadcrumb-item>商品管理</el-breadcrumb-item>
      <el-breadcrumb-item>
        {{ activeTab === 'new' ? '全新商品' : activeTab === 'used' ? '二手商品' : '租赁商品' }}
      </el-breadcrumb-item>
    </el-breadcrumb>


    <h2 class="page-title">商品管理</h2>
    <el-tabs v-model="activeTab" class="product-tabs" @tab-change="handleTabChange">
      <!-- 全新商品 -->
      <el-tab-pane label="全新商品" name="new">
        <div class="tab-content">
          <!-- 筛选栏 -->
          <div class="filter-bar">
            <el-input placeholder="搜索商品名称" v-model="searchKeyword" clearable style="width: 200px; margin-right: 10px;">
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
            <el-select placeholder="商品状态" v-model="productFilter.status" style="width: 150px; margin-right: 10px;">
              <el-option label="全部" value="" />
              <el-option label="待审核" value="pending" />
              <el-option label="审核通过" value="approved" />
              <el-option label="审核未通过" value="rejected" />
              <el-option label="已上架" value="1" />
              <el-option label="已下架" value="0" />
            </el-select>
            <el-button type="primary" @click="handleSearch">搜索</el-button>
            <el-button type="success" @click="handleAddProduct">发布新商品</el-button>
            <div class="batch-actions" v-if="selectedProducts.length > 0">
              <el-button type="warning" size="small" @click="handleBatchToggleStatus" :disabled="!canBatchToggle">
                {{ batchToggleText }}
              </el-button>
              <el-button type="danger" size="small" @click="handleBatchDelete">
                批量删除
              </el-button>
            </div>
            <el-button type="info" size="small" @click="handleExport">
              导出
            </el-button>
          </div>

          <!-- 商品列表 -->
          <div class="product-list">
            <el-table :data="filteredProducts" stripe style="width: 100%" @selection-change="handleSelectionChange">
              <el-table-column type="selection" width="55" />
              <el-table-column prop="productId" label="商品ID" width="80" />
              <el-table-column prop="name" label="商品名称" min-width="200" />
              <el-table-column prop="price" label="价格" min-width="120">
                <template #default="scope">¥{{ scope.row.price }}</template>
              </el-table-column>
              <el-table-column prop="stock" label="库存" min-width="80" />
              <el-table-column prop="sales" label="销量" min-width="80" />
              <el-table-column prop="status" label="状态" min-width="180">
                <template #default="scope">
                  <div style="display: flex; gap: 8px; align-items: center;">
                    <el-tag
                      :type="getAuditStatusType(scope.row.auditStatus)"
                    >
                      {{ getAuditStatusText(scope.row.auditStatus) }}
                    </el-tag>
                    <el-tag
                      :type="scope.row.isOnShelf === 1 ? 'success' : 'warning'"
                      v-if="scope.row.auditStatus === 1"
                    >
                      {{ scope.row.isOnShelf === 1 ? '已上架' : '已下架' }}
                    </el-tag>
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="createTime" label="创建时间" min-width="180" />
              <el-table-column label="操作" width="300" fixed="right">
                <template #default="scope">
                  <el-button type="primary" size="small" @click="handleViewSku(scope.row)">SKU管理</el-button>
                  <el-button type="success" size="small" @click="handleEditProduct(scope.row)">编辑</el-button>
                  <el-button
                :type="scope.row.isOnShelf === 1 ? 'warning' : 'success'"
                size="small"
                @click="handleToggleStatus(scope.row)"
                :disabled="scope.row.auditStatus !== 1"
              >
                {{ scope.row.isOnShelf === 1 ? '下架' : '上架' }}
              </el-button>
                  <el-button type="danger" size="small" @click="handleDeleteProduct(scope.row)">删除</el-button>
                </template>
              </el-table-column>
            </el-table>

            <!-- 分页组件 -->
            <div class="pagination">
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
          </div>
        </div>
      </el-tab-pane>

      <!-- 二手商品 -->
      <el-tab-pane label="二手商品" name="used">
        <div class="tab-content">
          <!-- 筛选栏 -->
          <div class="filter-bar">
            <el-input placeholder="搜索商品名称" v-model="searchKeyword" clearable style="width: 200px; margin-right: 10px;">
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
            <el-select placeholder="商品状态" v-model="productFilter.status" style="width: 150px; margin-right: 10px;">
              <el-option label="全部" value="" />
              <el-option label="待审核" value="pending" />
              <el-option label="审核通过" value="approved" />
              <el-option label="审核未通过" value="rejected" />
              <el-option label="已上架" value="1" />
              <el-option label="已下架" value="0" />
            </el-select>
            <el-button type="primary" @click="handleSearch">搜索</el-button>
            <el-button type="success" @click="handleAddProduct">发布二手商品</el-button>
          </div>

          <!-- 商品列表 -->
          <div class="product-list">
            <el-table :data="filteredProducts" stripe style="width: 100%" @selection-change="handleSelectionChange">
              <el-table-column type="selection" width="55" />
              <el-table-column prop="productId" label="商品ID" width="80" />
              <el-table-column prop="name" label="商品名称" min-width="200" />
              <el-table-column prop="price" label="价格" min-width="120">
                <template #default="scope">¥{{ scope.row.price }}</template>
              </el-table-column>
              <el-table-column prop="condition" label="成色" min-width="100">
                <template #default="scope">
                  <el-tag type="info">
                    {{ scope.row.condition ? `${scope.row.condition}新` : '未知' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="stock" label="库存" min-width="80" />
              <el-table-column prop="sales" label="销量" min-width="80" />
              <el-table-column prop="status" label="状态" min-width="180">
                <template #default="scope">
                  <div style="display: flex; gap: 8px; align-items: center;">
                    <el-tag
                      :type="getAuditStatusType(scope.row.auditStatus)"
                    >
                      {{ getAuditStatusText(scope.row.auditStatus) }}
                    </el-tag>
                    <el-tag
                      :type="scope.row.isOnShelf === 1 ? 'success' : 'warning'"
                      v-if="scope.row.auditStatus === 1"
                    >
                      {{ scope.row.isOnShelf === 1 ? '已上架' : '已下架' }}
                    </el-tag>
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="createTime" label="创建时间" min-width="180" />
              <el-table-column label="操作" width="300" fixed="right">
                <template #default="scope">
                  <el-button type="primary" size="small" @click="handleViewSku(scope.row)">SKU管理</el-button>
                  <el-button type="success" size="small" @click="handleEditProduct(scope.row)">编辑</el-button>
                  <el-button
                :type="scope.row.isOnShelf === 1 ? 'warning' : 'success'"
                size="small"
                @click="handleToggleStatus(scope.row)"
                :disabled="scope.row.auditStatus !== 1"
              >
                {{ scope.row.isOnShelf === 1 ? '下架' : '上架' }}
              </el-button>
                  <el-button type="danger" size="small" @click="handleDeleteProduct(scope.row)">删除</el-button>
                </template>
              </el-table-column>
            </el-table>

            <!-- 分页组件 -->
            <div class="pagination">
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
          </div>
        </div>
      </el-tab-pane>

      <!-- 租赁商品 -->
      <el-tab-pane label="租赁商品" name="rental">
        <div class="tab-content">
          <!-- 筛选栏 -->
          <div class="filter-bar">
            <el-input placeholder="搜索商品名称" v-model="searchKeyword" clearable style="width: 200px; margin-right: 10px;">
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
            <el-select placeholder="商品状态" v-model="productFilter.status" style="width: 150px; margin-right: 10px;">
              <el-option label="全部" value="" />
              <el-option label="待审核" value="pending" />
              <el-option label="审核通过" value="approved" />
              <el-option label="审核未通过" value="rejected" />
              <el-option label="已上架" value="1" />
              <el-option label="已下架" value="0" />
            </el-select>
            <el-button type="primary" @click="handleSearch">搜索</el-button>
            <el-button type="success" @click="handleAddProduct">发布租赁商品</el-button>
          </div>

          <!-- 商品列表 -->
          <div class="product-list">
            <el-table :data="filteredProducts" stripe style="width: 100%" @selection-change="handleSelectionChange">
              <el-table-column type="selection" width="55" />
              <el-table-column prop="productId" label="商品ID" width="80" />
              <el-table-column prop="name" label="商品名称" min-width="200" />
              <el-table-column prop="price" label="日租金" min-width="120">
                <template #default="scope">¥{{ scope.row.price }}/天</template>
              </el-table-column>
              <el-table-column prop="deposit" label="押金" min-width="120">
                <template #default="scope">¥{{ scope.row.deposit }}</template>
              </el-table-column>
              <el-table-column prop="minRentalDays" label="起租天数" min-width="100" />
              <el-table-column prop="stock" label="库存" min-width="80" />
              <el-table-column prop="sales" label="出租次数" min-width="120" />
              <el-table-column prop="status" label="状态" min-width="180">
                <template #default="scope">
                  <div style="display: flex; gap: 8px; align-items: center;">
                    <el-tag
                      :type="getAuditStatusType(scope.row.auditStatus)"
                    >
                      {{ getAuditStatusText(scope.row.auditStatus) }}
                    </el-tag>
                    <el-tag
                      :type="scope.row.isOnShelf === 1 ? 'success' : 'warning'"
                      v-if="scope.row.auditStatus === 1"
                    >
                      {{ scope.row.isOnShelf === 1 ? '已上架' : '已下架' }}
                    </el-tag>
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="createTime" label="创建时间" min-width="180" />
              <el-table-column label="操作" width="300" fixed="right">
                <template #default="scope">
                  <el-button type="primary" size="small" @click="handleViewSku(scope.row)">SKU管理</el-button>
                  <el-button type="success" size="small" @click="handleEditProduct(scope.row)">编辑</el-button>
                  <el-button
                :type="scope.row.isOnShelf === 1 ? 'warning' : 'success'"
                size="small"
                @click="handleToggleStatus(scope.row)"
                :disabled="scope.row.auditStatus !== 1"
              >
                {{ scope.row.isOnShelf === 1 ? '下架' : '上架' }}
              </el-button>
                  <el-button type="danger" size="small" @click="handleDeleteProduct(scope.row)">删除</el-button>
                </template>
              </el-table-column>
            </el-table>

            <!-- 分页组件 -->
            <div class="pagination">
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
          </div>
        </div>
      </el-tab-pane>
    </el-tabs>

    <!-- SKU管理抽屉 -->
    <el-drawer
      v-model="skuDrawerVisible"
      title="SKU管理"
      direction="rtl"
      size="50%"
    >
      <div v-if="currentProduct" class="sku-management">
        <h3 class="sku-title">{{ currentProduct.name }} - SKU列表</h3>
        <el-button type="primary" size="small" @click="handleAddSku" style="margin-bottom: 20px;">添加SKU</el-button>

        <el-table :data="currentProduct.skus" stripe style="width: 100%">
          <el-table-column prop="skuId" label="SKU ID" width="100" />
          <el-table-column prop="skuAttribute" label="属性" width="120" />
          <el-table-column prop="skuValue" label="属性值" width="120" />
          <el-table-column prop="price" label="价格" width="100">
            <template #default="scope">¥{{ scope.row.price }}</template>
          </el-table-column>
          <el-table-column prop="stock" label="库存" width="100" />
          <el-table-column label="操作" width="150">
            <template #default="scope">
              <el-button type="success" size="small" @click="handleEditSku(scope.row)">编辑</el-button>
              <el-button type="danger" size="small" @click="handleDeleteSku(scope.$index)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>

        <div v-if="currentProduct.skus.length === 0" class="no-sku-tip">
          暂无SKU，点击添加SKU按钮开始添加
        </div>
      </div>
    </el-drawer>

    <!-- SKU表单对话框 -->
    <el-dialog
      v-model="skuFormVisible"
      :title="skuForm.skuId ? '编辑SKU' : '添加SKU'"
      width="500px"
    >
      <el-form
        ref="skuFormRef"
        :model="skuForm"
        :rules="skuFormRules"
        label-width="80px"
      >
        <el-form-item label="属性" prop="skuAttribute">
          <el-input v-model="skuForm.skuAttribute" placeholder="请输入属性名称" />
        </el-form-item>
        <el-form-item label="属性值" prop="skuValue">
          <el-input v-model="skuForm.skuValue" placeholder="请输入属性值" />
        </el-form-item>
        <el-form-item label="价格" prop="price">
          <el-input-number
            v-model="skuForm.price"
            :min="0.01"
            :step="0.01"
            :precision="2"
            placeholder="请输入价格"
          />
        </el-form-item>
        <el-form-item label="库存" prop="stock">
          <el-input-number
            v-model="skuForm.stock"
            :min="0"
            step="1"
            placeholder="请输入库存"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="skuFormVisible = false">取消</el-button>
          <el-button type="primary" @click="submitSkuForm">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import {
  getProductList,
  deleteProduct,
  toggleProductStatus,
  getSkuList,
  addSku,
  updateSku,
  deleteSku
} from '@/api/merchant/product'

const router = useRouter()
const route = useRoute()

// 激活的标签页
const activeTab = ref(route.query.type as string || 'new')

// 分页相关变量
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)

// 监听路由变化，根据URL中的type参数更新标签页
watch(() => route.fullPath, (newPath) => {
  const queryParams = newPath.split('?')[1] || ''
  const typeParam = new URLSearchParams(queryParams).get('type')
  if (typeParam) {
    activeTab.value = typeParam as string
  }
})

// 监听activeTab变化，确保无论何时标签页变化都会重新获取数据
watch(() => activeTab.value, () => {
  // 切换标签页时重置到第一页
  currentPage.value = 1
  fetchProductList()
})



// 搜索关键词
const searchKeyword = ref('')

// 商品筛选条件
const productFilter = ref({
  status: '',
  keyword: ''
})

// 商品列表数据
const newProducts = ref([])
const usedProducts = ref([])
const rentalProducts = ref([])

// 根据当前标签页获取商品列表
const currentProducts = computed(() => {
  switch (activeTab.value) {
    case 'new':
      return newProducts.value
    case 'used':
      return usedProducts.value
    case 'rental':
      return rentalProducts.value
    default:
      return []
  }
})

// 过滤后的商品列表
const filteredProducts = computed(() => {
  return currentProducts.value.filter(product => {
    const matchesKeyword = searchKeyword.value === '' || product.name.includes(searchKeyword.value)
    let matchesStatus = true

    if (productFilter.value.status) {
      const status = productFilter.value.status
      if (status === 'pending') {
        matchesStatus = product.auditStatus === 0
      } else if (status === 'approved') {
        matchesStatus = product.auditStatus === 1
      } else if (status === 'rejected') {
        matchesStatus = product.auditStatus === 2
      } else {
        matchesStatus = product.isOnShelf.toString() === status
      }
    }

    return matchesKeyword && matchesStatus
  })
})

// SKU管理相关
const skuDrawerVisible = ref(false)
const currentProduct = ref<any>(null)
const skuFormVisible = ref(false)
const skuFormRef = ref()

// SKU表单数据
const skuForm = ref({
  skuId: '',
  skuAttribute: '',
  skuValue: '',
  price: 0,
  stock: 0
})

// SKU表单验证规则
const skuFormRules = {
  skuAttribute: [
    { required: true, message: '请输入属性名称', trigger: 'blur' }
  ],
  skuValue: [
    { required: true, message: '请输入属性值', trigger: 'blur' }
  ],
  price: [
    { required: true, message: '请输入价格', trigger: 'blur' },
    { type: 'number', min: 0.01, message: '价格必须大于0', trigger: 'blur' }
  ],
  stock: [
    { required: true, message: '请输入库存', trigger: 'blur' },
    { type: 'number', min: 0, message: '库存必须大于等于0', trigger: 'blur' }
  ]
}

// 选中的商品
const selectedProducts = ref<any[]>([])

// 处理选择变化
const handleSelectionChange = (val: any[]) => {
  selectedProducts.value = val
}

// 是否可以进行批量上下架操作
const canBatchToggle = computed(() => {
  return selectedProducts.value.every(product => product.auditStatus === 1)
})

// 批量上下架文本
const batchToggleText = computed(() => {
  if (selectedProducts.value.length === 0) return '批量操作'
  const allOnShelf = selectedProducts.value.every(product => product.isOnShelf === 1)
  return allOnShelf ? '批量下架' : '批量上架'
})

// 批量上下架
const handleBatchToggleStatus = async () => {
  if (selectedProducts.value.length === 0) {
    ElMessage.warning('请选择要操作的商品')
    return
  }

  if (!canBatchToggle.value) {
    ElMessage.warning('只有审核通过的商品才能进行上下架操作')
    return
  }

  const allOnShelf = selectedProducts.value.every(product => product.isOnShelf === 1)
  const newStatus = allOnShelf ? 0 : 1

  try {
    for (const product of selectedProducts.value) {
      await toggleProductStatus(product.productId, newStatus)
      product.isOnShelf = newStatus
    }
    ElMessage.success(`商品已${newStatus === 1 ? '批量上架' : '批量下架'}`)
  } catch (error) {
    console.error('批量操作失败:', error)
    ElMessage.error('批量操作失败')
  }
}

// 批量删除
const handleBatchDelete = () => {
  if (selectedProducts.value.length === 0) {
    ElMessage.warning('请选择要删除的商品')
    return
  }

  ElMessageBox.confirm(`确定要删除选中的 ${selectedProducts.value.length} 个商品吗？`, '批量删除', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    try {
      for (const product of selectedProducts.value) {
        await deleteProduct(product.productId)
        const index = currentProducts.value.findIndex(p => p.productId === product.productId)
        if (index > -1) {
          currentProducts.value.splice(index, 1)
        }
      }
      selectedProducts.value = []
      ElMessage.success('商品批量删除成功')
    } catch (error) {
      console.error('批量删除失败:', error)
      ElMessage.error('批量删除失败')
    }
  }).catch(() => {
    // 取消删除
  })
}

// 导出商品
const handleExport = async () => {
  try {
    const response = await getProductList({
      type: activeTab.value as 'new' | 'used' | 'rental',
      status: productFilter.value.status,
      keyword: searchKeyword.value,
      page: 1,
      pageSize: 1000 // 导出较多数据
    })

    const products = response
    const csvContent = generateCsvContent(products)
    downloadCsv(csvContent, `商品列表_${activeTab.value}_${new Date().toISOString().split('T')[0]}.csv`)
    ElMessage.success('导出成功')
  } catch (error) {
    console.error('导出失败:', error)
    ElMessage.error('导出失败')
  }
}

// 生成CSV内容
const generateCsvContent = (products: any[]) => {
  const headers = ['商品ID', '商品名称', '价格', '库存', '销量', '审核状态', '上架状态', '创建时间']
  const rows = products.map(product => [
    product.productId,
    product.name,
    product.price,
    product.stock,
    product.sales,
    getAuditStatusText(product.auditStatus),
    product.isOnShelf === 1 ? '已上架' : '已下架',
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

// 搜索商品
const handleSearch = () => {
  // 搜索时重置到第一页
  currentPage.value = 1
  fetchProductList()
}

// 获取商品列表
const fetchProductList = async () => {
  try {
    const response = await getProductList({
      type: activeTab.value as 'new' | 'used' | 'rental',
      status: productFilter.value.status,
      keyword: searchKeyword.value,
      page: currentPage.value,
      pageSize: pageSize.value
    })

    if (activeTab.value === 'new') {
      newProducts.value = response
    } else if (activeTab.value === 'used') {
      usedProducts.value = response
    } else {
      rentalProducts.value = response
    }

    // 更新总数，使用API返回的total字段
    total.value = (response as any).total || response.length
  } catch (error) {
    console.error('获取商品列表失败:', error)
    ElMessage.error('获取商品列表失败')
  }
}

// 分页相关事件处理函数
const handleSizeChange = (val: number) => {
  pageSize.value = val
  currentPage.value = 1
  fetchProductList()
}

const handleCurrentChange = (val: number) => {
  currentPage.value = val
  fetchProductList()
}

// 添加商品
const handleAddProduct = () => {
  router.push(`/merchant-dashboard/product-add?type=${activeTab.value}`)
}

// 编辑商品
const handleEditProduct = (product: any) => {
  router.push(`/merchant-dashboard/product-edit/${product.productId}?type=${activeTab.value}`)
}

// 获取审核状态文本
const getAuditStatusText = (auditStatus: number): string => {
  switch (auditStatus) {
    case 0: return '待审核'
    case 1: return '审核通过'
    case 2: return '审核未通过'
    default: return '未知状态'
  }
}

// 获取审核状态标签类型
const getAuditStatusType = (auditStatus: number): string => {
  switch (auditStatus) {
    case 0: return 'info'
    case 1: return 'success'
    case 2: return 'danger'
    default: return 'warning'
  }
}

// 切换商品状态
const handleToggleStatus = async (product: any) => {
  const newStatus = product.isOnShelf === 1 ? 0 : 1
  try {
    await toggleProductStatus(product.productId, newStatus)
    product.isOnShelf = newStatus
    ElMessage.success(`商品已${newStatus === 1 ? '上架' : '下架'}`)
  } catch (error) {
    console.error('更新商品状态失败:', error)
    ElMessage.error('更新商品状态失败')
  }
}

// 删除商品
const handleDeleteProduct = (product: any) => {
  ElMessageBox.confirm(`确定要删除商品 "${product.name}" 吗？`, '删除商品', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    try {
      await deleteProduct(product.productId)
      const index = currentProducts.value.findIndex(p => p.productId === product.productId)
      if (index > -1) {
        currentProducts.value.splice(index, 1)
      }
      ElMessage.success('商品删除成功')
    } catch (error) {
      console.error('删除商品失败:', error)
      ElMessage.error('删除商品失败')
    }
  }).catch(() => {
    // 取消删除
  })
}

// 查看SKU
const handleViewSku = async (product: any) => {
  currentProduct.value = product
  // 初始化skus为空数组，防止渲染时出错
  currentProduct.value.skus = []
  skuDrawerVisible.value = true

  // 获取商品SKU列表
  try {
    const skus = await getSkuList(product.productId)
    currentProduct.value.skus = skus
  } catch (error) {
    console.error('获取SKU列表失败:', error)
    ElMessage.error('获取SKU列表失败')
  }
}

// 添加SKU
const handleAddSku = () => {
  skuForm.value = {
    skuId: '',
    skuAttribute: '',
    skuValue: '',
    price: 0,
    stock: 0
  }
  skuFormVisible.value = true
}

// 编辑SKU
const handleEditSku = (sku: any) => {
  skuForm.value = { ...sku }
  skuFormVisible.value = true
}

// 删除SKU
const handleDeleteSku = (index: number) => {
  const sku = currentProduct.value.skus[index]
  ElMessageBox.confirm('确定要删除该SKU吗？', '删除SKU', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    try {
      await deleteSku(currentProduct.value.productId, sku.skuId)
      currentProduct.value.skus.splice(index, 1)
      ElMessage.success('SKU删除成功')
    } catch (error) {
      console.error('删除SKU失败:', error)
      ElMessage.error('删除SKU失败')
    }
  }).catch(() => {
    // 取消删除
  })
}

// 提交SKU表单
const submitSkuForm = async () => {
  if (!skuFormRef.value) return

  skuFormRef.value.validate(async (valid: boolean) => {
    if (valid) {
      try {
        if (skuForm.value.skuId) {
          // 编辑现有SKU
          await updateSku(currentProduct.value.productId, skuForm.value.skuId, skuForm.value)
          const index = currentProduct.value.skus.findIndex((sku: any) => sku.skuId === skuForm.value.skuId)
          if (index > -1) {
            currentProduct.value.skus[index] = { ...skuForm.value }
          }
          ElMessage.success('SKU编辑成功')
        } else {
          // 添加新SKU
          const newSku = await addSku(currentProduct.value.productId, skuForm.value)
          currentProduct.value.skus.push(newSku)
          ElMessage.success('SKU添加成功')
        }
        skuFormVisible.value = false
      } catch (error) {
        console.error('保存SKU失败:', error)
        ElMessage.error('保存SKU失败')
      }
    }
  })
}

// 重置SKU表单
const resetSkuForm = () => {
  if (!skuFormRef.value) return
  skuFormRef.value.resetFields()
}

// 页面加载时初始化
onMounted(() => {
  fetchProductList()
})

// 监听标签页切换事件
const handleTabChange = () => {
  // 更新URL中的type参数，保持标签页状态
  router.push({
    path: route.path,
    query: {
      ...route.query,
      type: activeTab.value
    }
  })
  fetchProductList()
}
</script>

<style scoped>
.merchant-product-management {
  padding: 20px;
  width: 100%;
  box-sizing: border-box;
}

/* 面包屑导航样式 */
.breadcrumb {
  font-size: 14px;
  margin-bottom: 12px;
  padding: 8px 0;
  border-bottom: 1px solid #ebeef5;
}



/* 调整表格样式 */
:deep(.el-table) {
  width: 100% !important;
}

/* 增加表格行高 */
:deep(.el-table__row) {
  height: 60px;
}

/* 调整单元格内边距 */
:deep(.el-table__cell) {
  padding: 12px 0;
}

.page-title {
  font-size: 24px;
  margin-bottom: 20px;
  color: #333;
}

.product-tabs {
  background-color: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  padding: 20px;
}

.filter-bar {
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
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

.tab-content {
  padding: 10px 0;
}

.product-list {
  background-color: #fff;
  border-radius: 8px;
  overflow: hidden;
}

/* 分页组件样式 */
.pagination {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
  align-items: center;
  padding: 10px 0;
}

/* SKU管理样式 */
.sku-management {
  padding: 20px;
}

.sku-title {
  font-size: 18px;
  margin-bottom: 20px;
  color: #333;
  font-weight: bold;
}

.no-sku-tip {
  color: #909399;
  text-align: center;
  padding: 40px 0;
  background-color: #f5f7fa;
  border-radius: 4px;
  margin-top: 20px;
}

/* 操作按钮间距 */
:deep(.el-table__column--operation .el-button) {
  margin-right: 8px;
}

:deep(.el-table__column--operation .el-button:last-child) {
  margin-right: 0;
}

/* 状态标签水平排列 */
:deep(.el-table__cell .el-tag) {
  margin-right: 8px;
  margin-bottom: 0;
}

/* 增加状态列最小宽度，确保标签在同一行显示 */
:deep(.el-table__column--status) {
  min-width: 180px !important;
}
</style>
