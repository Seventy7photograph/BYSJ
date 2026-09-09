<template>
  <div class="merchant-order-management">
    <!-- 面包屑导航 -->
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item :to="'/merchant-dashboard'">后台首页</el-breadcrumb-item>
      <el-breadcrumb-item>订单管理</el-breadcrumb-item>
    </el-breadcrumb>

    <h2 class="page-title">订单管理</h2>
    <el-tabs v-model="activeTab" class="order-tabs">
      <!-- 全新订单 -->
      <el-tab-pane label="全新订单" name="new">
        <div class="tab-content">
          <!-- 筛选栏 -->
          <div class="filter-bar">
            <el-select placeholder="订单状态" v-model="newOrderFilter.status" style="width: 150px; margin-right: 10px;">
              <el-option label="全部" value="" />
              <el-option label="待付款" value="0" />
              <el-option label="已付款" value="1" />
              <el-option label="已发货" value="2" />
              <el-option label="已完成" value="3" />
              <el-option label="已取消" value="4" />
            </el-select>
            <el-input placeholder="搜索订单号" v-model="newOrderFilter.orderNo" clearable style="width: 200px; margin-right: 10px;">
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
            <el-button type="primary" @click="handleSearchNewOrders">搜索</el-button>
            <div class="batch-actions" v-if="selectedNewOrders.length > 0">
              <el-button type="success" size="small" @click="handleBatchShip" :disabled="!canBatchShip('new')">
                批量发货
              </el-button>
            </div>
            <el-button type="info" size="small" @click="handleExport('new')">
              导出
            </el-button>
          </div>

          <!-- 订单列表 -->
          <div class="order-list">
            <el-table :data="newOrders" stripe style="width: 100%" v-loading="loading" @selection-change="handleNewOrderSelectionChange">
              <el-table-column type="selection" width="55" />
              <el-table-column prop="orderNo" label="订单号" min-width="220" />
              <el-table-column prop="userName" label="用户名" min-width="150" />
              <el-table-column prop="customerName" label="客户" min-width="120" />
              <el-table-column label="商品信息" min-width="270">
                <template #default="scope">
                  <div v-for="(item, index) in scope.row.items" :key="item.productId" class="product-info-item">
                    <div class="product-details-horizontal">
                      <span class="brand">{{ item.brandName || '未知品牌' }}</span>
                      <span class="product-name">{{ item.productName }}</span>
                      <span class="quantity">×{{ item.quantity }}</span>
                    </div>
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="totalAmount" label="订单金额" min-width="120">
                <template #default="scope">¥{{ scope.row.totalAmount }}</template>
              </el-table-column>
              <el-table-column prop="orderStatus" label="状态" min-width="100">
                <template #default="scope">
                  <el-tag :type="getStatusTagType(scope.row.orderStatus)">
                    {{ getStatusText(scope.row.orderStatus) }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="createTime" label="创建时间" min-width="180" />
              <el-table-column label="操作" min-width="250" fixed="right">
                <template #default="scope">
                  <el-button type="primary" size="small" @click="handleViewOrderDetail(scope.row)">查看详情</el-button>
                  <el-button
                    v-if="scope.row.orderStatus === 1"
                    type="success"
                    size="small"
                    @click="handleShipOrder(scope.row)"
                  >
                    一键发货
                  </el-button>
                  <el-button
                    v-if="scope.row.orderStatus === 9"
                    type="success"
                    size="small"
                    @click="handleConfirmReturn(scope.row)"
                  >
                    确认归还
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
            <!-- 分页组件 -->
            <div class="pagination">
              <el-pagination
                v-model:current-page="newPage"
                v-model:page-size="newPageSize"
                :page-sizes="[5, 10, 20, 50]"
                layout="total, sizes, prev, pager, next, jumper"
                :total="newTotal"
                @size-change="handlePageSizeChange('new', $event)"
                @current-change="handlePageChange('new', $event)"
              />
            </div>
          </div>
        </div>
      </el-tab-pane>

      <!-- 二手订单 -->
      <el-tab-pane label="二手订单" name="used">
        <div class="tab-content">
          <!-- 筛选栏 -->
          <div class="filter-bar">
            <el-select placeholder="订单状态" v-model="usedOrderFilter.status" style="width: 150px; margin-right: 10px;">
              <el-option label="全部" value="" />
              <el-option label="待付款" value="0" />
              <el-option label="已付款" value="1" />
              <el-option label="已发货" value="2" />
              <el-option label="已完成" value="3" />
              <el-option label="已取消" value="4" />
            </el-select>
            <el-input placeholder="搜索订单号" v-model="usedOrderFilter.orderNo" clearable style="width: 200px; margin-right: 10px;">
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
            <el-button type="primary" @click="handleSearchUsedOrders">搜索</el-button>
            <div class="batch-actions" v-if="selectedUsedOrders.length > 0">
              <el-button type="success" size="small" @click="handleBatchShip" :disabled="!canBatchShip('used')">
                批量发货
              </el-button>
            </div>
            <el-button type="info" size="small" @click="handleExport('used')">
              导出
            </el-button>
          </div>

          <!-- 订单列表 -->
          <div class="order-list">
            <el-table :data="usedOrders" stripe style="width: 100%" v-loading="loading" @selection-change="handleUsedOrderSelectionChange">
              <el-table-column type="selection" width="55" />
              <el-table-column prop="orderNo" label="订单号" min-width="220" />
              <el-table-column prop="userName" label="用户名" min-width="150" />
              <el-table-column prop="customerName" label="客户" min-width="120" />
              <el-table-column label="商品信息" min-width="270">
                <template #default="scope">
                  <div v-for="(item, index) in scope.row.items" :key="item.productId" class="product-info-item">
                    <div class="product-details-horizontal">
                      <span class="brand">{{ item.brandName || '未知品牌' }}</span>
                      <span class="product-name">{{ item.productName }}</span>
                      <span class="quantity">×{{ item.quantity }}</span>
                    </div>
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="totalAmount" label="订单金额" min-width="120">
                <template #default="scope">¥{{ scope.row.totalAmount }}</template>
              </el-table-column>
              <el-table-column prop="orderStatus" label="状态" min-width="100">
                <template #default="scope">
                  <el-tag :type="getStatusTagType(scope.row.orderStatus)">
                    {{ getStatusText(scope.row.orderStatus) }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="createTime" label="创建时间" min-width="180" />
              <el-table-column label="操作" min-width="250" fixed="right">
                <template #default="scope">
                  <el-button type="primary" size="small" @click="handleViewOrderDetail(scope.row)">查看详情</el-button>
                  <el-button
                    v-if="scope.row.orderStatus === 1"
                    type="success"
                    size="small"
                    @click="handleShipOrder(scope.row)"
                  >
                    一键发货
                  </el-button>
                  <el-button
                    v-if="scope.row.orderStatus === 9"
                    type="success"
                    size="small"
                    @click="handleConfirmReturn(scope.row)"
                  >
                    确认归还
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
            <!-- 分页组件 -->
            <div class="pagination">
              <el-pagination
                v-model:current-page="usedPage"
                v-model:page-size="usedPageSize"
                :page-sizes="[5, 10, 20, 50]"
                layout="total, sizes, prev, pager, next, jumper"
                :total="usedTotal"
                @size-change="handlePageSizeChange('used', $event)"
                @current-change="handlePageChange('used', $event)"
              />
            </div>
          </div>
        </div>
      </el-tab-pane>

      <!-- 租赁订单 -->
      <el-tab-pane label="租赁订单" name="rental">
        <div class="tab-content">
          <!-- 筛选栏 -->
          <div class="filter-bar">
            <el-select placeholder="订单状态" v-model="rentalOrderFilter.status" style="width: 150px; margin-right: 10px;">
              <el-option label="全部" value="" />
              <el-option label="待付款" value="0" />
              <el-option label="已付款" value="1" />
              <el-option label="已发货" value="2" />
              <el-option label="已完成" value="3" />
              <el-option label="已取消" value="4" />
              <el-option label="租赁中" value="8" />
              <el-option label="归还中" value="9" />
            </el-select>
            <el-input placeholder="搜索订单号" v-model="rentalOrderFilter.orderNo" clearable style="width: 200px; margin-right: 10px;">
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
            <el-button type="primary" @click="handleSearchRentalOrders">搜索</el-button>
            <div class="batch-actions" v-if="selectedRentalOrders.length > 0">
              <el-button type="success" size="small" @click="handleBatchShip" :disabled="!canBatchShip('rental')">
                批量发货
              </el-button>
            </div>
            <el-button type="info" size="small" @click="handleExport('rental')">
              导出
            </el-button>
          </div>

          <!-- 订单列表 -->
          <div class="order-list">
            <el-table :data="rentalOrders" stripe style="width: 100%" v-loading="loading" @selection-change="handleRentalOrderSelectionChange">
              <el-table-column type="selection" width="55" />
              <el-table-column prop="orderNo" label="订单号" min-width="220" />
              <el-table-column prop="userName" label="用户名" min-width="150" />
              <el-table-column prop="customerName" label="客户" min-width="120" />
              <el-table-column label="商品信息" min-width="270">
                <template #default="scope">
                  <div v-for="(item, index) in scope.row.items" :key="item.productId" class="product-info-item">
                    <div class="product-details-horizontal">
                      <span class="brand">{{ item.brandName || '未知品牌' }}</span>
                      <span class="product-name">{{ item.productName }}</span>
                      <span class="quantity">×{{ item.quantity }}</span>
                    </div>
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="totalAmount" label="订单金额" min-width="120">
                <template #default="scope">¥{{ scope.row.totalAmount }}</template>
              </el-table-column>
              <el-table-column prop="orderStatus" label="状态" min-width="100">
                <template #default="scope">
                  <el-tag :type="getStatusTagType(scope.row.orderStatus)">
                    {{ getStatusText(scope.row.orderStatus) }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="createTime" label="创建时间" min-width="180" />
              <el-table-column label="操作" min-width="250" fixed="right">
                <template #default="scope">
                  <el-button type="primary" size="small" @click="handleViewOrderDetail(scope.row)">查看详情</el-button>
                  <el-button
                    v-if="scope.row.orderStatus === 1"
                    type="success"
                    size="small"
                    @click="handleShipOrder(scope.row)"
                  >
                    一键发货
                  </el-button>
                  <el-button
                    v-if="scope.row.orderStatus === 9"
                    type="success"
                    size="small"
                    @click="handleConfirmReturn(scope.row)"
                  >
                    确认归还
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
            <!-- 分页组件 -->
            <div class="pagination">
              <el-pagination
                v-model:current-page="rentalPage"
                v-model:page-size="rentalPageSize"
                :page-sizes="[5, 10, 20, 50]"
                layout="total, sizes, prev, pager, next, jumper"
                :total="rentalTotal"
                @size-change="handlePageSizeChange('rental', $event)"
                @current-change="handlePageChange('rental', $event)"
              />
            </div>
          </div>
        </div>
      </el-tab-pane>

      <!-- 退款管理 -->
      <el-tab-pane label="退款管理" name="refund">
        <div class="tab-content">
          <!-- 筛选栏 -->
          <div class="filter-bar">
            <el-select placeholder="退款状态" v-model="refundFilter.status" style="width: 150px; margin-right: 10px;">
              <el-option label="全部" value="" />
              <el-option label="申请中" value="0" />
              <el-option label="退款成功" value="1" />
              <el-option label="退款失败" value="2" />
            </el-select>
            <el-input placeholder="搜索订单号" v-model="refundFilter.orderNo" clearable style="width: 200px; margin-right: 10px;">
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
            <el-button type="primary" @click="handleSearchRefunds">搜索</el-button>
          </div>

          <!-- 退款列表 -->
          <div class="order-list">
            <el-table :data="refunds" stripe style="width: 100%" v-loading="loading" @selection-change="handleRefundSelectionChange">
              <el-table-column type="selection" width="55" />
              <el-table-column prop="refundId" label="退款ID" min-width="100" />
              <el-table-column prop="orderNo" label="订单号" min-width="280" />
              <el-table-column label="商品信息" min-width="200">
                <template #default="scope">
                  <div v-for="(item, index) in scope.row.items" :key="item.productId" class="product-info-item">
                    <div class="product-details-horizontal">
                      <span class="brand">{{ item.brandName || '未知品牌' }}</span>
                      <span class="product-name">{{ item.productName }}</span>
                      <span class="quantity">×{{ item.quantity }}</span>
                    </div>
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="refundAmount" label="退款金额" min-width="120">
                <template #default="scope">¥{{ scope.row.refundAmount }}</template>
              </el-table-column>
              <el-table-column prop="refundStatus" label="状态" min-width="100">
                <template #default="scope">
                  <el-tag :type="getRefundStatusTagType(scope.row.refundStatus)">
                    {{ getRefundStatusText(scope.row.refundStatus) }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="refundReason" label="退款原因" min-width="150" />
              <el-table-column prop="createTime" label="申请时间" min-width="180" />
              <el-table-column label="操作" min-width="250" fixed="right">
                <template #default="scope">
                  <el-button type="primary" size="small" @click="handleViewRefundDetail(scope.row)">查看详情</el-button>
                  <el-button
                    v-if="scope.row.refundStatus === 0"
                    type="success"
                    size="small"
                    @click="handleApproveRefund(scope.row)"
                  >
                    同意退款
                  </el-button>
                  <el-button
                    v-if="scope.row.refundStatus === 0"
                    type="danger"
                    size="small"
                    @click="handleRejectRefund(scope.row)"
                  >
                    拒绝退款
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
            <!-- 分页组件 -->
            <div class="pagination">
              <el-pagination
                v-model:current-page="refundPage"
                v-model:page-size="refundPageSize"
                :page-sizes="[5, 10, 20, 50]"
                layout="total, sizes, prev, pager, next, jumper"
                :total="refundTotal"
                @size-change="handlePageSizeChange('refund', $event)"
                @current-change="handlePageChange('refund', $event)"
              />
            </div>
          </div>
        </div>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search } from '@element-plus/icons-vue'
import { getOrderList, shipOrder } from '@/api/merchant/order'
import axios from '@/axios'

const router = useRouter()
const route = useRoute()

// 激活的标签页
const activeTab = ref('new')

// 全新订单筛选条件
const newOrderFilter = ref({
  status: '',
  orderNo: ''
})

// 二手订单筛选条件
const usedOrderFilter = ref({
  status: '',
  orderNo: ''
})

// 租赁订单筛选条件
const rentalOrderFilter = ref({
  status: '',
  orderNo: ''
})

// 退款筛选条件
const refundFilter = ref({
  status: '',
  orderNo: ''
})

// 加载状态
const loading = ref(false)

// 分页参数
const newPage = ref(1)
const newPageSize = ref(10)
const newTotal = ref(0)

const usedPage = ref(1)
const usedPageSize = ref(10)
const usedTotal = ref(0)

const rentalPage = ref(1)
const rentalPageSize = ref(10)
const rentalTotal = ref(0)

// 退款分页参数
const refundPage = ref(1)
const refundPageSize = ref(10)
const refundTotal = ref(0)

// 订单类型定义
interface Order {
  orderId: number
  orderNo: string
  customerName: string
  totalAmount: number
  orderStatus: number
  createTime: string
  [key: string]: any
}

// 订单列表数据
const newOrders = ref<Order[]>([])
const usedOrders = ref<Order[]>([])
const rentalOrders = ref<Order[]>([])

// 退款列表数据
const refunds = ref<any[]>([])

// 搜索订单 - 必须在watch之前定义，因为watch有immediate: true
const handleSearchOrders = async (type: 'new' | 'used' | 'rental' | 'refund') => {
  console.log('调用handleSearchOrders，类型:', type)
  loading.value = true
  try {
    if (type === 'refund') {
      // 处理退款列表
      const filter = refundFilter.value
      const page = refundPage.value
      const pageSize = refundPageSize.value

      console.log('准备获取退款列表，参数:', { status: filter.status, orderNo: filter.orderNo, page, pageSize })

      // 调用API获取退款列表
      const response = await axios.get('/refunds/merchant/list', {
        params: {
          status: filter.status,
          orderNo: filter.orderNo,
          page,
          pageSize
        }
      })

      console.log('获取退款列表响应:', response)
      console.log('响应数据结构:', response.data)

      // 处理响应：axios拦截器已处理，直接访问response.data
      const refundList = response.data?.list || []
      const total = response.data?.total || 0

      console.log('获取到的退款列表数据:', refundList)
      console.log('退款列表总数:', total)

      refunds.value = refundList
      refundTotal.value = total
      console.log('refunds.value:', refunds.value)
      console.log('refundTotal.value:', refundTotal.value)
    } else {
      // 处理订单列表
      const filter = type === 'new' ? newOrderFilter.value :
                    type === 'used' ? usedOrderFilter.value :
                    rentalOrderFilter.value

      // 确定当前分页参数
      const page = type === 'new' ? newPage.value :
                  type === 'used' ? usedPage.value :
                  rentalPage.value
      const pageSize = type === 'new' ? newPageSize.value :
                      type === 'used' ? usedPageSize.value :
                      rentalPageSize.value

      // 调用API获取订单列表
      const response = await getOrderList({
        type,
        status: filter.status,
        orderNo: filter.orderNo,
        page,
        pageSize
      })

      // 处理响应：axios返回的是完整的响应对象，数据在response.data中
      const orderList = response.data?.list || []
      const total = response.data?.total || 0

      // 根据订单类型更新对应的数据
      if (type === 'new') {
        newOrders.value = orderList
        newTotal.value = total
      } else if (type === 'used') {
        usedOrders.value = orderList
        usedTotal.value = total
      } else {
        rentalOrders.value = orderList
        rentalTotal.value = total
      }
    }
  } catch (error) {
    console.error('获取列表失败:', error)
    ElMessage.error('获取列表失败')
  } finally {
    loading.value = false
  }
}

// 监听路由变化，处理URL参数
watch(() => route.fullPath, (newPath) => {
  // 从URL查询参数中获取订单类型，处理没有查询参数的情况
  const queryParams = newPath.split('?')[1] || ''
  const typeParam = new URLSearchParams(queryParams).get('type')
  if (typeParam && ['new', 'used', 'rental', 'refund'].includes(typeParam)) {
    // 设置激活的标签页
    activeTab.value = typeParam as 'new' | 'used' | 'rental' | 'refund'
    // 加载对应类型的订单数据
    handleSearchOrders(activeTab.value as 'new' | 'used' | 'rental' | 'refund')
  }
})

// 监听activeTab变化，自动加载对应类型的订单数据
watch(activeTab, (newType) => {
  handleSearchOrders(newType as 'new' | 'used' | 'rental' | 'refund')
})

// 监听全新订单筛选条件变化，自动搜索
watch(
  () => newOrderFilter.value.status,
  (newStatus) => {
    if (activeTab.value === 'new') {
      newPage.value = 1 // 重置为第一页
      handleSearchOrders('new')
    }
  }
)

// 监听二手订单筛选条件变化，自动搜索
watch(
  () => usedOrderFilter.value.status,
  (newStatus) => {
    if (activeTab.value === 'used') {
      usedPage.value = 1 // 重置为第一页
      handleSearchOrders('used')
    }
  }
)

// 监听租赁订单筛选条件变化，自动搜索
watch(
  () => rentalOrderFilter.value.status,
  (newStatus) => {
    if (activeTab.value === 'rental') {
      rentalPage.value = 1 // 重置为第一页
      handleSearchOrders('rental')
    }
  }
)

// 监听退款筛选条件变化，自动搜索
watch(
  () => refundFilter.value.status,
  (newStatus) => {
    if (activeTab.value === 'refund') {
      refundPage.value = 1 // 重置为第一页
      handleSearchOrders('refund')
    }
  }
)

// 分页变更处理
const handlePageChange = (type: 'new' | 'used' | 'rental' | 'refund', page: number) => {
  if (type === 'new') {
    newPage.value = page
  } else if (type === 'used') {
    usedPage.value = page
  } else if (type === 'rental') {
    rentalPage.value = page
  } else if (type === 'refund') {
    refundPage.value = page
  }
  handleSearchOrders(type)
}

// 分页大小变更处理
const handlePageSizeChange = (type: 'new' | 'used' | 'rental' | 'refund', pageSize: number) => {
  if (type === 'new') {
    newPageSize.value = pageSize
    newPage.value = 1
  } else if (type === 'used') {
    usedPageSize.value = pageSize
    usedPage.value = 1
  } else if (type === 'rental') {
    rentalPageSize.value = pageSize
    rentalPage.value = 1
  } else if (type === 'refund') {
    refundPageSize.value = pageSize
    refundPage.value = 1
  }
  handleSearchOrders(type)
}

// 搜索全新订单
const handleSearchNewOrders = () => {
  handleSearchOrders('new')
}

// 搜索二手订单
const handleSearchUsedOrders = () => {
  handleSearchOrders('used')
}

// 搜索租赁订单
const handleSearchRentalOrders = () => {
  handleSearchOrders('rental')
}

// 搜索退款
const handleSearchRefunds = () => {
  handleSearchOrders('refund')
}

// 页面加载时获取订单列表
onMounted(() => {
  // 处理URL参数
  const queryParams = route.fullPath.split('?')[1] || ''
  const typeParam = new URLSearchParams(queryParams).get('type')
  if (typeParam && ['new', 'used', 'rental', 'refund'].includes(typeParam)) {
    // 设置激活的标签页
    activeTab.value = typeParam as 'new' | 'used' | 'rental' | 'refund'
  }
  // 加载对应类型的订单数据
  handleSearchOrders(activeTab.value as 'new' | 'used' | 'rental' | 'refund')
})

// 查看订单详情
const handleViewOrderDetail = (order: any) => {
  router.push(`/merchant-dashboard/order-detail/${order.orderId}`)
}

// 查看退款详情
const handleViewRefundDetail = (refund: any) => {
  // 这里可以跳转到退款详情页面，或者弹出详情对话框
  ElMessageBox.alert(
    `<div>
      <p><strong>退款ID：</strong>${refund.refundId}</p>
      <p><strong>订单号：</strong>${refund.orderNo}</p>
      <p><strong>退款金额：</strong>¥${refund.refundAmount}</p>
      <p><strong>退款原因：</strong>${refund.refundReason}</p>
      <p><strong>详细说明：</strong>${refund.refundDescription || '无'}</p>
      <p><strong>申请时间：</strong>${refund.createTime}</p>
      <p><strong>状态：</strong>${getRefundStatusText(refund.refundStatus)}</p>
    </div>`,
    '退款详情',
    {
      dangerouslyUseHTMLString: true,
      confirmButtonText: '确定'
    }
  )
}

// 同意退款
const handleApproveRefund = (refund: any) => {
  ElMessageBox.confirm('确定要同意该退款申请吗？', '同意退款', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'success'
  }).then(async () => {
    loading.value = true
    try {
      await axios.post('/refunds/process', {
        refundId: refund.refundId,
        status: 1 // 1表示退款成功
      })
      ElMessage.success('同意退款成功')
      // 重新加载退款列表
      handleSearchOrders('refund')
    } catch (error) {
      console.error('同意退款失败:', error)
      ElMessage.error('同意退款失败')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消操作
  })
}

// 拒绝退款
const handleRejectRefund = (refund: any) => {
  ElMessageBox.confirm('确定要拒绝该退款申请吗？', '拒绝退款', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'danger'
  }).then(async () => {
    loading.value = true
    try {
      await axios.post('/refunds/process', {
        refundId: refund.refundId,
        status: 2 // 2表示退款失败
      })
      ElMessage.success('拒绝退款成功')
      // 重新加载退款列表
      handleSearchOrders('refund')
    } catch (error) {
      console.error('拒绝退款失败:', error)
      ElMessage.error('拒绝退款失败')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消操作
  })
}

// 获取退款状态标签类型
const getRefundStatusTagType = (status: number) => {
  const typeMap: Record<number, string> = {
    0: 'warning',
    1: 'success',
    2: 'danger'
  }
  return typeMap[status] || 'info'
}

// 获取退款状态文本
const getRefundStatusText = (status: number) => {
  const textMap: Record<number, string> = {
    0: '申请中',
    1: '退款成功',
    2: '退款失败'
  }
  return textMap[status] || '未知状态'
}

// 发货
const handleShipOrder = (order: any) => {
  // 弹出确认发货对话框
  ElMessageBox.confirm('确定要发货吗？', '发货确认', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    // 调用API更新订单状态
    loading.value = true
    try {
      await shipOrder(order.orderId, {
        // 可以添加物流信息，这里暂时为空
      })

      // 更新订单状态
      order.orderStatus = 2
      ElMessage.success('发货成功')

      // 更新对应订单列表中的订单状态
      if (activeTab.value === 'new') {
        const index = newOrders.value.findIndex(o => o.orderNo === order.orderNo)
        if (index > -1) {
          (newOrders.value[index] as any).orderStatus = 2
        }
      } else if (activeTab.value === 'used') {
        const index = usedOrders.value.findIndex(o => o.orderNo === order.orderNo)
        if (index > -1) {
          (usedOrders.value[index] as any).orderStatus = 2
        }
      } else if (activeTab.value === 'rental') {
        const index = rentalOrders.value.findIndex(o => o.orderNo === order.orderNo)
        if (index > -1) {
          (rentalOrders.value[index] as any).orderStatus = 2
        }
      }
    } catch (error) {
      console.error('发货失败:', error)
      ElMessage.error('发货失败')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消发货
  })
}

// 获取订单状态标签类型
const getStatusTagType = (status: number) => {
  const typeMap: Record<number, string> = {
    0: 'warning',
    1: 'info',
    2: 'success',
    3: 'success',
    4: 'danger',
    5: 'primary',
    6: 'success',
    7: 'danger',
    8: 'primary',
    9: 'info'
  }
  return typeMap[status] || 'info'
}

// 获取订单状态文本
const getStatusText = (status: number) => {
  const textMap: Record<number, string> = {
    0: '待付款',
    1: '已付款',
    2: '已发货',
    3: '已完成',
    4: '已取消',
    5: '退款处理中',
    6: '退款成功',
    7: '退款失败',
    8: '租赁中',
    9: '归还中'
  }
  return textMap[status] || '未知状态'
}

// 选中的订单
const selectedNewOrders = ref<any[]>([])
const selectedUsedOrders = ref<any[]>([])
const selectedRentalOrders = ref<any[]>([])
const selectedRefunds = ref<any[]>([])

// 处理全新订单选择变化
const handleNewOrderSelectionChange = (val: any[]) => {
  selectedNewOrders.value = val
  selectedUsedOrders.value = []
  selectedRentalOrders.value = []
  selectedRefunds.value = []
}

// 处理二手订单选择变化
const handleUsedOrderSelectionChange = (val: any[]) => {
  selectedUsedOrders.value = val
  selectedNewOrders.value = []
  selectedRentalOrders.value = []
  selectedRefunds.value = []
}

// 处理租赁订单选择变化
const handleRentalOrderSelectionChange = (val: any[]) => {
  selectedRentalOrders.value = val
  selectedNewOrders.value = []
  selectedUsedOrders.value = []
  selectedRefunds.value = []
}

// 处理退款选择变化
const handleRefundSelectionChange = (val: any[]) => {
  selectedRefunds.value = val
  selectedNewOrders.value = []
  selectedUsedOrders.value = []
  selectedRentalOrders.value = []
}

// 是否可以进行批量发货操作
const canBatchShip = (type: 'new' | 'used' | 'rental') => {
  const selectedOrders = type === 'new' ? selectedNewOrders.value :
                       type === 'used' ? selectedUsedOrders.value :
                       selectedRentalOrders.value
  return selectedOrders.length > 0 && selectedOrders.every(order => order.orderStatus === 1)
}

// 批量发货
const handleBatchShip = async () => {
  let selectedOrders: any[] = []
  let type: 'new' | 'used' | 'rental' = 'new'

  if (selectedNewOrders.value.length > 0) {
    selectedOrders = selectedNewOrders.value
    type = 'new'
  } else if (selectedUsedOrders.value.length > 0) {
    selectedOrders = selectedUsedOrders.value
    type = 'used'
  } else if (selectedRentalOrders.value.length > 0) {
    selectedOrders = selectedRentalOrders.value
    type = 'rental'
  }

  if (selectedOrders.length === 0) {
    ElMessage.warning('请选择要发货的订单')
    return
  }

  if (!canBatchShip(type)) {
    ElMessage.warning('只有已付款的订单才能进行发货操作')
    return
  }

  // 弹出确认发货对话框
  ElMessageBox.confirm(`确定要为选中的 ${selectedOrders.length} 个订单发货吗？`, '批量发货确认', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    // 调用API更新订单状态
    loading.value = true
    try {
      for (const order of selectedOrders) {
        await shipOrder(order.orderId, {
          // 可以添加物流信息，这里暂时为空
        })

        // 更新订单状态
        order.orderStatus = 2
      }

      ElMessage.success('批量发货成功')

      // 重新加载订单列表
      handleSearchOrders(type)
    } catch (error) {
      console.error('批量发货失败:', error)
      ElMessage.error('批量发货失败')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消发货
  })
}

// 确认归还
const handleConfirmReturn = async (order: any) => {
  try {
    await ElMessageBox.confirm('确定要确认归还吗？确认后将启动押金退还流程', '确认归还', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })

    // 调用API确认归还
    await axios.post(`/orders/${order.orderId}/confirm-return`)

    ElMessage.success('确认归还成功，押金将在3-5个工作日内退还')

    // 重新加载订单列表
    handleSearchOrders(activeTab.value as 'new' | 'used' | 'rental' | 'refund')
  } catch (error) {
    if (error !== 'cancel') {
      console.error('确认归还失败:', error)
      ElMessage.error('确认归还失败')
    }
  }
}

// 导出订单
const handleExport = async (type: 'new' | 'used' | 'rental') => {
  try {
    const filter = type === 'new' ? newOrderFilter.value :
                  type === 'used' ? usedOrderFilter.value :
                  rentalOrderFilter.value

    // 调用API获取订单列表
    const response = await getOrderList({
      type,
      status: filter.status,
      orderNo: filter.orderNo,
      page: 1,
      pageSize: 1000 // 导出较多数据
    })

    const orders = response.data?.list || []
    const csvContent = generateOrderCsvContent(orders)
    downloadCsv(csvContent, `订单列表_${type}_${new Date().toISOString().split('T')[0]}.csv`)
    ElMessage.success('导出成功')
  } catch (error) {
    console.error('导出失败:', error)
    ElMessage.error('导出失败')
  }
}

// 生成订单CSV内容
const generateOrderCsvContent = (orders: any[]) => {
  const headers = ['订单号', '用户名', '客户', '订单金额', '订单状态', '创建时间']
  const rows = orders.map(order => [
    order.orderNo,
    order.userName,
    order.customerName,
    order.totalAmount,
    getStatusText(order.orderStatus),
    order.createTime
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
.merchant-order-management {
  padding: 20px;
  width: 100%;
  min-height: 100vh;
  background-color: #f0f2f5;
}

.page-title {
  font-size: 24px;
  margin: 20px;
  color: #333;
}

.order-tabs {
  background-color: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  padding: 20px;
  width: calc(100% - 40px);
  margin: 0 20px;
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

.order-list {
  background-color: #fff;
  border-radius: 8px;
  overflow: hidden;
  width: 100%;
}

/* 让表格宽度占满整个容器 */
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



/* 商品信息样式 */
.product-info-item {
  margin-bottom: 8px;
  padding: 5px;
  background-color: #fafafa;
  border-radius: 4px;
}

.product-info-item:last-child {
  margin-bottom: 0;
}

/* 水平商品详情样式 */
.product-details-horizontal {
  display: flex;
  align-items: center;
  gap: 15px;
  font-size: 14px;
}

.product-details-horizontal .brand {
  font-weight: 500;
  color: #333;
  background-color: #e6f7ff;
  padding: 2px 6px;
  border-radius: 3px;
}

.product-details-horizontal .product-name {
  flex: 1;
  color: #666;
  margin-bottom: 0;
  font-size: 14px;
}

.product-details-horizontal .quantity {
  color: #409EFF;
  font-weight: 500;
  background-color: #f0f9ff;
  padding: 2px 8px;
  border-radius: 3px;
}

/* 垂直商品详情样式（保留兼容旧版本） */
.product-name {
  font-weight: 500;
  color: #333;
  margin-bottom: 4px;
  font-size: 14px;
}

.product-details {
  display: flex;
  gap: 15px;
  font-size: 13px;
  color: #666;
}

.product-details .brand {
  font-weight: 500;
}

.product-details .quantity {
  color: #409EFF;
  font-weight: 500;
}

/* 分页样式 */
.pagination {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
  align-items: center;
  padding: 15px;
  background-color: #fff;
  border-radius: 0 0 8px 8px;
}
</style>
