<template>
  <div class="my-orders-page">
    <div class="page-header">
      <div class="header-left">
        <el-button type="text" @click="goBack" class="back-button">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
      </div>
      <h1>我的订单</h1>
    </div>

    <div class="order-tabs">
      <el-tabs v-model="activeTab" size="large" @tab-change="handleTabChange">
        <el-tab-pane label="全部订单" name="all" />
        <el-tab-pane label="全新订单" name="new" />
        <el-tab-pane label="二手订单" name="second_hand" />
        <el-tab-pane label="租赁订单" name="rental" />
      </el-tabs>
    </div>

    <div class="order-filters">
      <el-radio-group v-model="activeStatus" size="large">
        <el-radio-button label="all">全部</el-radio-button>
        <el-radio-button label="0">待付款</el-radio-button>
        <el-radio-button label="1">已付款</el-radio-button>
        <el-radio-button label="2">已发货</el-radio-button>
        <el-radio-button label="3">已完成</el-radio-button>
        <el-radio-button label="4">已取消</el-radio-button>
        <el-radio-button label="8">租赁中</el-radio-button>
        <el-radio-button label="9">归还中</el-radio-button>
      </el-radio-group>
    </div>

    <div v-loading="loading" class="orders-container">
      <div v-if="filteredOrders.length === 0" class="empty-orders">
        <el-empty description="暂无订单" :image-size="200" />
        <el-button type="primary" @click="goToShop">去购物</el-button>
      </div>

      <div v-else class="orders-list">
        <div v-for="order in filteredOrders" :key="order.orderId" class="order-item">
          <div class="order-header">
            <div class="order-info">
              <span class="order-no">订单号：{{ order.orderNo }}</span>
              <span class="order-date">{{ formatDate(order.createTime) }}</span>
            </div>
            <div class="order-status">
              {{ getOrderStatusText(order.orderStatus) }}
            </div>
          </div>

          <div class="order-goods">
            <div
              v-for="item in (order.items || [])"
              :key="item.productId"
              class="order-goods-item"
              @click="goToProductDetail(item)"
            >
              <div class="goods-image-wrapper">
                <!-- 二手商品显示成色标签 -->
                <el-tag
                  v-if="item.productType === 2"
                  :type="item.quality === 'excellent' ? 'success' : item.quality === 'good' ? 'warning' : 'info'"
                  class="goods-quality-tag"
                >
                  {{ qualityLabelMap[item.quality] || '二手' }}
                </el-tag>
                <img :src="item.productImage" :alt="item.productName" class="goods-image">
              </div>
              <div class="goods-info">
                <div class="goods-name-wrapper">
                  <div class="goods-name">{{ item.productName }}</div>
                  <el-tag v-if="item.productType === 2" type="warning" size="small" class="second-hand-tag">
                    二手
                  </el-tag>
                </div>
                <div class="goods-brand" v-if="item.brandName">品牌：{{ item.brandName }}</div>
                <!-- 二手商品显示成色 -->
                <div class="goods-quality" v-if="item.productType === 2">
                  成色：{{ qualityLabelMap[item.quality] || '二手' }}
                </div>
                <!-- 二手商品显示卖家 -->
                <div class="goods-seller" v-if="item.productType === 2 && item.sellerName">
                  卖家：{{ item.sellerName }}
                </div>
              </div>
              <div class="goods-price">¥{{ item.unitPrice }}</div>
              <div class="goods-quantity">×{{ item.quantity }}</div>
              <div class="goods-total">¥{{ (item.unitPrice * item.quantity).toFixed(2) }}</div>
            </div>
          </div>

          <div class="order-footer">
            <div class="order-total">
              <span>共 {{ (order.items || []).length }} 件商品，合计：</span>
              <span class="total-amount">¥{{ (order.totalAmount || 0).toFixed(2) }}</span>
            </div>
            <div class="order-actions">
              <el-button
                type="text"
                @click="cancelOrder(order.orderId)"
                v-if="order.orderStatus === 0"
              >
                取消订单
              </el-button>
              <el-button
                type="primary"
                @click="goToPayment(order.orderId)"
                v-if="order.orderStatus === 0"
              >
                立即付款
              </el-button>
              <el-button
                type="success"
                @click="confirmReceived(order.orderId)"
                v-if="order.orderStatus === 2"
              >
                确认收货
              </el-button>

              <el-button
                type="text"
                @click="viewOrderDetail(order.orderId)"
              >
                查看详情
              </el-button>
              <el-button
                type="danger"
                @click="openRefundDialog(order)"
                v-if="canRefund(order.orderStatus, order.createTime)"
              >
                退款
              </el-button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 分页 -->
    <div v-if="filteredOrders.length > 0" class="pagination-container">
      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="pageSize"
        :page-sizes="[10, 20, 50]"
        layout="total, sizes, prev, pager, next, jumper"
        :total="total"
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
      />
    </div>

    <!-- 退款申请弹窗 -->
    <el-dialog
      v-model="refundDialogVisible"
      title="申请退款"
      width="500px"
    >
      <div v-if="selectedOrder">
        <div class="refund-order-info">
          <div class="order-no">订单号：{{ selectedOrder.orderNo }}</div>
          <div class="order-amount">订单金额：¥{{ (selectedOrder.totalAmount || 0).toFixed(2) }}</div>
        </div>

        <div class="refund-form">
          <div class="form-item">
            <label class="required">退款原因</label>
            <el-select
              v-model="refundForm.refundReason"
              placeholder="请选择退款原因"
              style="width: 100%"
            >
              <el-option label="商品质量问题" value="商品质量问题" />
              <el-option label="拍错商品" value="拍错商品" />
              <el-option label="商品与描述不符" value="商品与描述不符" />
              <el-option label="物流问题" value="物流问题" />
              <el-option label="其他原因" value="其他原因" />
            </el-select>
          </div>

          <div class="form-item">
            <label class="required">详细说明</label>
            <el-input
              v-model="refundForm.refundDescription"
              type="textarea"
              rows="4"
              placeholder="请详细描述退款原因（最多200字）"
              maxlength="200"
              show-word-limit
            />
          </div>
        </div>
      </div>

      <template #footer>
        <span class="dialog-footer">
          <el-button @click="refundDialogVisible = false">取消</el-button>
          <el-button
            type="primary"
            :loading="submittingRefund"
            @click="submitRefund"
          >
            提交申请
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft } from '@element-plus/icons-vue'
import axios from '@/axios'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()

// 成色标签映射
const qualityLabelMap = {
  'excellent': '九成新',
  'good': '八成新',
  'fair': '七成新',
  'poor': '六成新'
};

// 订单数据
const orders = ref([])
const loading = ref(true)
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)
const activeStatus = ref('all')
const activeTab = ref('all') // 订单类型标签页

// 退款相关状态
const refundDialogVisible = ref(false)
const selectedOrder = ref(null)
const submittingRefund = ref(false)
const refundForm = ref({
  refundReason: '',
  refundDescription: ''
})

// 获取订单状态文本
const getOrderStatusText = (status) => {
  const statusMap = {
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
  return statusMap[status] || '未知状态'
}

// 格式化日期
const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 格式化规格参数
const formatSpecifications = (specs) => {
  return Object.entries(specs)
    .map(([key, value]) => `${key}: ${value}`)
    .join(' | ')
}

// 标签页切换处理
const handleTabChange = () => {
  // 标签页切换时可以重新获取数据或直接筛选
  // 这里直接使用计算属性筛选，无需重新请求
}

// 筛选订单
const filteredOrders = computed(() => {
  let result = orders.value

  // 1. 按订单类型筛选
  if (activeTab.value !== 'all') {
    // 订单类型映射：new(全新)=1, second_hand(二手)=2, rental(租赁)=3
    const typeMap = {
      'new': 1,
      'second_hand': 2,
      'rental': 3
    }
    const targetType = typeMap[activeTab.value]
    result = result.filter(order => {
      // 检查订单中的商品类型，只要有一个商品匹配就保留该订单
      const items = order.items || []
      return items.some(item => item.productType === targetType)
    })
  }

  // 2. 按订单状态筛选
  if (activeStatus.value !== 'all') {
    result = result.filter(order => order.orderStatus === Number(activeStatus.value))
  }

  return result
})

// 获取订单列表
    const fetchOrders = async () => {
      try {
        loading.value = true
        const res = await axios.get('/orders/list', {
          params: {
            pageNum: currentPage.value,
            pageSize: pageSize.value
          }
        })
        // 确保orders是一个数组，兼容两种响应格式（list和orders）
        const orderList = res.data?.list || res.data?.orders || []
        // 为每个订单添加默认值，确保items和totalAmount存在
        orders.value = orderList.map(order => ({
          ...order,
          items: order.items || [],
          totalAmount: order.totalAmount || 0
        }))
        total.value = res.data?.total || 0
      } catch (error) {
        console.error('获取订单列表失败:', error)
        orders.value = []
        total.value = 0
        ElMessage.error('获取订单列表失败')
      } finally {
        loading.value = false
      }
    }

// 取消订单
const cancelOrder = async (orderId) => {
  try {
    await ElMessageBox.confirm('确定要取消该订单吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })

    await axios.post(`/orders/${orderId}/cancel`)
    ElMessage.success('订单已取消')
    fetchOrders()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('取消订单失败:', error)
      ElMessage.error('取消订单失败')
    }
  }
}

// 去支付
const goToPayment = (orderId) => {
  router.push(`/order/payment/${orderId}`)
}

// 确认收货
const confirmReceived = async (orderId) => {
  try {
    await ElMessageBox.confirm('确定已收到商品吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })

    await axios.post(`/orders/${orderId}/confirm-receive`)
    ElMessage.success('确认收货成功')
    fetchOrders()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('确认收货失败:', error)
      ElMessage.error('确认收货失败')
    }
  }
}

// 查看订单详情
const viewOrderDetail = (orderId) => {
  router.push(`/order/detail/${orderId}`)
}

// 跳转到商品详情
const goToProductDetail = (item) => {
  // 根据商品类型判断跳转路径
  if (item.productType === 2) {
    router.push(`/second-hand/detail/${item.productId}`);
  } else if (item.productType === 3) {
    router.push(`/rental/detail/${item.productId}`);
  } else {
    router.push(`/product/${item.productId}`);
  }
}

// 跳转到商城
const goToShop = () => {
  router.push('/shop')
}

// 分页处理
const handleSizeChange = (size) => {
  pageSize.value = size
  currentPage.value = 1
  fetchOrders()
}

const handleCurrentChange = (page) => {
  currentPage.value = page
  fetchOrders()
}

// 返回上一页
const goBack = () => {
  router.back()
}

// 检查订单是否可以退款
const canRefund = (orderStatus, createTime) => {
  // 已付款或已发货状态可以申请退款，退款处理中状态不允许重复申请
  if (orderStatus !== 1 && orderStatus !== 2) {
    return false
  }

  // 检查订单创建时间是否超过7天
  const orderDate = new Date(createTime)
  const now = new Date()
  const diffHours = (now - orderDate) / (1000 * 60 * 60)

  // 超过7天（168小时）不允许退款
  return diffHours <= 168
}

// 打开退款弹窗
const openRefundDialog = (order) => {
  selectedOrder.value = order
  // 重置退款表单
  refundForm.value = {
    refundReason: '',
    refundDescription: ''
  }
  refundDialogVisible.value = true
}

// 提交退款申请
const submitRefund = async () => {
  if (!selectedOrder.value) return

  // 验证表单
  if (!refundForm.value.refundReason) {
    ElMessage.warning('请选择退款原因')
    return
  }

  try {
    submittingRefund.value = true
    await axios.post('/refunds/apply', {
      orderId: selectedOrder.value.orderId,
      refundReason: refundForm.value.refundReason,
      refundDescription: refundForm.value.refundDescription
    })

    ElMessage.success('退款申请提交成功')
    refundDialogVisible.value = false
    // 重新获取订单列表
    fetchOrders()
  } catch (error) {
    console.error('提交退款申请失败:', error)
    ElMessage.error(error.response?.data?.message || '提交退款申请失败，请稍后重试')
  } finally {
    submittingRefund.value = false
  }
}

onMounted(() => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }
  fetchOrders()
})
</script>

<style scoped>
.my-orders-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.page-header {
  margin-bottom: 30px;
  position: relative;
  text-align: center;
}

.header-left {
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
}

.back-button {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 16px;
  color: #666;
}

.page-header h1 {
  margin: 0;
  color: #333;
}

.order-filters {
  margin-bottom: 30px;
  padding: 20px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.1);
}

.orders-container {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.1);
  overflow: hidden;
}

.empty-orders {
  padding: 80px 20px;
  text-align: center;
}

.orders-list {
  padding: 20px;
}

.order-item {
  margin-bottom: 20px;
  padding: 20px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background: #fafafa;
}

.order-item:last-child {
  margin-bottom: 0;
}

.order-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 1px solid #e0e0e0;
}

.order-info {
  display: flex;
  gap: 20px;
}

.order-no {
  font-weight: 500;
  color: #333;
}

.order-date {
  color: #666;
  font-size: 14px;
}

.order-status {
  font-weight: bold;
  color: #409EFF;
}

.order-goods {
  margin-bottom: 20px;
}

.order-goods-item {
  display: flex;
  align-items: center;
  padding: 15px 0;
  border-bottom: 1px solid #e0e0e0;
  cursor: pointer;
  transition: all 0.3s;
}

.order-goods-item:hover {
  background: rgba(0,0,0,0.02);
}

.order-goods-item:last-child {
  border-bottom: none;
}

.goods-image-wrapper {
  position: relative;
  margin-right: 20px;
}

.goods-image {
  width: 80px;
  height: 80px;
  object-fit: contain;
  border: 1px solid #e0e0e0;
  border-radius: 4px;
}

.goods-quality-tag {
  position: absolute;
  top: -5px;
  left: -5px;
  z-index: 1;
  font-size: 12px;
  padding: 2px 6px;
}

.goods-info {
  flex: 1;
}

.goods-name-wrapper {
  display: flex;
  align-items: center;
  margin-bottom: 5px;
}

.goods-name {
  font-weight: 500;
  margin-right: 8px;
  color: #333;
}

.second-hand-tag {
  margin-left: 8px;
}

.goods-spec,
.goods-brand,
.goods-quality,
.goods-seller {
  font-size: 12px;
  color: #666;
  margin-bottom: 3px;
}

.goods-quality {
  color: #409eff;
}

.goods-price,
.goods-quantity,
.goods-total {
  width: 100px;
  text-align: center;
}

.goods-price {
  color: #666;
}

.goods-total {
  font-weight: bold;
  color: #ff4d4f;
}

.order-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 15px;
  border-top: 1px solid #e0e0e0;
}

.order-total {
  font-weight: bold;
  color: #333;
}

.total-amount {
  color: #ff4d4f;
  font-size: 18px;
  margin-left: 10px;
}

.order-actions {
  display: flex;
  gap: 10px;
}

.pagination-container {
  padding: 20px;
  display: flex;
  justify-content: center;
  background: white;
  margin-top: 10px;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.1);
}

.refund-order-info {
  background: #f8f9fa;
  padding: 15px;
  border-radius: 4px;
  margin-bottom: 20px;
}

.order-no {
  font-weight: 500;
  margin-bottom: 5px;
  color: #333;
}

.order-amount {
  color: #ff4d4f;
  font-weight: bold;
}

.refund-form {
  margin-top: 20px;
}

.form-item {
  margin-bottom: 20px;
}

.form-item label {
  display: block;
  margin-bottom: 8px;
  font-weight: 500;
  color: #333;
}

.form-item label.required::after {
  content: '*';
  color: #ff4d4f;
  margin-left: 4px;
}

@media (max-width: 768px) {
  .my-orders-page {
    padding: 10px;
  }

  .order-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }

  .order-info {
    flex-direction: column;
    gap: 10px;
  }

  .order-goods-item {
    flex-wrap: wrap;
  }

  .goods-info {
    order: 2;
    width: 100%;
    margin-top: 10px;
  }

  .goods-price,
  .goods-quantity,
  .goods-total {
    order: 1;
    width: auto;
    margin: 0 10px;
  }

  .order-footer {
    flex-direction: column;
    align-items: flex-start;
    gap: 15px;
  }

  .order-actions {
    width: 100%;
    flex-direction: column;
  }
}
</style>
