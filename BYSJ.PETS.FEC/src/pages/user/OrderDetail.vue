<template>
  <div class="order-detail-page">
    <div class="page-header">
      <div class="header-left">
        <el-button type="text" @click="goBack" class="back-button">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
      </div>
      <h1>订单详情</h1>
      <el-steps :active="orderStatusIndex" align-center>
        <el-step title="待付款" />
        <el-step title="已付款" />
        <el-step title="已发货" />
        <el-step title="已完成" />
      </el-steps>
    </div>

    <div v-loading="loading" class="order-content">
      <!-- 订单基本信息 -->
      <div class="order-basic-info">
        <h3>订单信息</h3>
        <div class="info-items">
          <div class="info-item">
            <span class="label">订单号：</span>
            <span class="value">{{ orderDetail.orderNo }}</span>
          </div>
          <div class="info-item">
            <span class="label">下单时间：</span>
            <span class="value">{{ formatDate(orderDetail.createTime) }}</span>
          </div>
          <div class="info-item">
            <span class="label">订单状态：</span>
            <el-tag :type="orderStatusTagType" size="large">{{ getOrderStatusText(orderDetail.orderStatus) }}</el-tag>
          </div>
          <div class="info-item">
            <span class="label">支付方式：</span>
            <span class="value">{{ getPaymentMethodText(orderDetail.paymentMethod) }}</span>
          </div>
          <!-- 退款状态信息 -->
          <div v-if="refundInfo" class="info-item">
            <span class="label">退款状态：</span>
            <el-tag :type="getRefundStatusType(refundInfo.refundStatus)">
              {{ getRefundStatusText(refundInfo.refundStatus) }}
            </el-tag>
          </div>
          <div v-if="refundInfo" class="info-item">
            <span class="label">退款金额：</span>
            <span class="value" style="color: #ff4d4f;">¥{{ refundInfo.refundAmount?.toFixed(2) }}</span>
          </div>
          <div v-if="refundInfo" class="info-item">
            <span class="label">退款原因：</span>
            <span class="value">{{ refundInfo.refundReason }}</span>
          </div>
          <!-- 租赁商品特有信息 -->
          <div v-if="isRentalOrder" class="info-item">
            <span class="label">取货方式：</span>
            <span class="value">{{ getPickupMethodText(orderDetail.pickupMethod) }}</span>
          </div>
          <div v-if="isRentalOrder" class="info-item">
            <span class="label">归还方式：</span>
            <span class="value">{{ getReturnMethodText(orderDetail.returnMethod) }}</span>
          </div>
          <div v-if="isRentalOrder" class="info-item rental-end-date">
            <span class="label">租赁到期：</span>
            <span class="value" :class="{ 'expired': isRentalExpired, 'expiring-soon': isExpiringSoon }">{{ formatDate(orderDetail.endDate) }}</span>
            <el-tag v-if="isExpiringSoon" type="warning" size="small" style="margin-left: 10px;">即将到期</el-tag>
            <el-tag v-if="isRentalExpired" type="danger" size="small" style="margin-left: 10px;">已过期</el-tag>
          </div>
        </div>
      </div>

      <!-- 收货地址信息 -->
      <div class="order-address">
        <h3>收货信息</h3>
        <div class="address-content">
          <div class="recipient-info">
            <span class="name">{{ orderDetail.recipient }}</span>
            <span class="phone">{{ orderDetail.phone }}</span>
          </div>
          <div class="address-detail">{{ orderDetail.fullAddress }}</div>
        </div>
      </div>

      <!-- 商品列表 -->
      <div class="order-products">
        <h3>商品信息</h3>
        <div class="products-list">
          <div v-for="item in orderDetail.orderItems" :key="item.productId" class="product-item">
            <img :src="item.productImage" :alt="item.productName" class="product-image">
            <div class="product-info">
              <div class="product-name-wrapper">
                <div class="product-name">{{ item.productName }}</div>
                <el-tag v-if="item.productType === 3" type="success" size="small" class="rental-tag">
                  租赁
                </el-tag>
                <el-tag v-else-if="item.productType === 2" type="warning" size="small" class="second-hand-tag">
                  二手
                </el-tag>
              </div>
              <div class="product-brand" v-if="item.brandName">品牌：{{ item.brandName }}</div>
              <div class="product-spec" v-if="item.specifications">{{ formatSpecifications(item.specifications) }}</div>
            </div>
            <div class="product-price">¥{{ item.unitPrice }}</div>
            <div class="product-quantity">×{{ item.quantity }}</div>
            <div class="product-total">¥{{ (item.unitPrice * item.quantity).toFixed(2) }}</div>
          </div>
        </div>
      </div>

      <!-- 物流信息 -->
      <div class="order-logistics">
        <h3>{{ isRentalOrder ? '租赁流程' : '物流信息' }}</h3>
        <div class="logistics-content">
          <el-timeline>
            <el-timeline-item
              v-for="(log, index) in logisticsHistory"
              :key="index"
              :timestamp="log.timestamp"
              :type="log.type || (index === 0 ? 'success' : 'info')"
              :color="log.color"
              :icon="log.icon"
              :size="log.size"
            >
              <div class="timeline-content">
                <div class="content-title">{{ log.content }}</div>
                <div v-if="log.description" class="content-desc">{{ log.description }}</div>
              </div>
            </el-timeline-item>
          </el-timeline>
        </div>
      </div>

      <!-- 订单金额信息 -->
      <div class="order-amount">
        <h3>金额信息</h3>
        <div class="amount-items">
          <div class="amount-item">
            <span class="label">商品总价：</span>
            <span class="value">¥{{ orderDetail.totalAmount.toFixed(2) }}</span>
          </div>
          <div class="amount-item">
            <span class="label">运费：</span>
            <span class="value">¥{{ orderDetail.shippingFee.toFixed(2) }}</span>
          </div>
          <div class="amount-item total">
            <span class="label">实付金额：</span>
            <span class="value">¥{{ orderDetail.payAmount.toFixed(2) }}</span>
          </div>
        </div>
      </div>

      <!-- 订单操作按钮 -->
      <div class="order-actions" v-if="orderDetail.orderStatus === 2">
        <el-button
          type="primary"
          size="large"
          :loading="confirming"
          @click="confirmReceive"
        >
          确认收货
        </el-button>
      </div>

      <!-- 租赁中操作按钮 -->
      <div class="order-actions" v-if="orderDetail.orderStatus === 8">
        <el-button
          type="primary"
          size="large"
          @click="handleReturn"
        >
          {{ isRentalExpired ? '归还' : '租赁中，提前归还' }}
        </el-button>
      </div>

      <!-- 评价按钮 -->
      <div class="order-actions" v-if="orderDetail.orderStatus === 3">
        <el-button
          v-if="!hasEvaluated"
          type="success"
          size="large"
          @click="openEvaluationDialog"
        >
          评价商品
        </el-button>
        <el-button
          v-else
          type="info"
          size="large"
          :disabled="true"
        >
          已完成评价
        </el-button>
      </div>
    </div>

    <!-- 评价对话框 -->
    <el-dialog
      v-model="evaluationDialogVisible"
      title="评价商品"
      width="600px"
    >
      <div v-if="selectedProduct">
        <div class="evaluation-product-info">
          <img :src="selectedProduct.productImage" :alt="selectedProduct.productName" class="evaluation-product-image">
          <div class="evaluation-product-details">
            <div class="evaluation-product-name">{{ selectedProduct.productName }}</div>
            <div class="evaluation-product-price">¥{{ selectedProduct.unitPrice }}</div>
          </div>
        </div>

        <div class="evaluation-form">
          <div class="form-item">
            <label>综合评分</label>
            <RateComponent v-model="evaluationForm.score" :showScore="true" />
          </div>

          <div class="form-item">
            <label>器材质量</label>
            <RateComponent v-model="evaluationForm.qualityScore" />
          </div>

          <div class="form-item">
            <label>商家服务</label>
            <RateComponent v-model="evaluationForm.serviceScore" />
          </div>

          <div class="form-item" v-if="!isRentalOrder">
            <label>物流速度</label>
            <RateComponent v-model="evaluationForm.logisticsScore" />
          </div>

          <div class="form-item">
            <label>评价内容</label>
            <el-input
              v-model="evaluationForm.content"
              type="textarea"
              rows="4"
              placeholder="请输入评价内容"
              maxlength="500"
              show-word-limit
            />
          </div>
        </div>
      </div>

      <template #footer>
        <span class="dialog-footer">
          <el-button @click="evaluationDialogVisible = false">取消</el-button>
          <el-button
            type="primary"
            :loading="submittingEvaluation"
            @click="submitEvaluation"
          >
            提交评价
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft } from '@element-plus/icons-vue'
import axios from '@/axios'
import { useUserStore } from '@/stores/user'
import { user } from '@/api'
import RateComponent from '@/components/RateComponent.vue'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

// 订单详情数据
const orderDetail = ref({
  orderId: '',
  orderNo: '',
  createTime: '',
  orderStatus: 0,
  paymentMethod: '',
  recipient: '',
  phone: '',
  fullAddress: '',
  totalAmount: 0,
  shippingFee: 0,
  payAmount: 0,
  orderItems: []
})

const loading = ref(true)
const confirming = ref(false)

// 退款信息
const refundInfo = ref(null)

// 评价相关状态
const evaluationDialogVisible = ref(false)
const submittingEvaluation = ref(false)
const selectedProduct = ref(null)
const evaluationForm = ref({
  score: 5,
  qualityScore: 5,
  serviceScore: 5,
  logisticsScore: 5,
  content: ''
})
const hasEvaluated = ref(false) // 标记订单是否已评价

// 计算订单状态对应的步骤索引
const orderStatusIndex = computed(() => {
  switch (orderDetail.value.orderStatus) {
    case 0: return 0 // 待付款
    case 1: return 1 // 已付款
    case 2: return 2 // 已发货
    case 3: return 3 // 已完成
    case 8: return 3 // 租赁中（显示为已完成步骤，因为已经收到商品）
    case 9: return 3 // 归还中（显示为已完成步骤，因为已经收到商品）
    default: return 0
  }
})

// 计算订单状态标签类型
const orderStatusTagType = computed(() => {
  switch (orderDetail.value.orderStatus) {
    case 0: return 'warning' // 待付款
    case 1: return 'info' // 已付款
    case 2: return 'success' // 已发货
    case 3: return 'success' // 已完成
    case 4: return 'danger' // 已取消
    case 5: return 'primary' // 退款处理中
    case 6: return 'success' // 退款成功
    case 7: return 'danger' // 退款失败
    case 8: return 'primary' // 租赁中
    case 9: return 'info' // 归还中
    default: return 'info'
  }
})

// 模拟物流历史
const logisticsHistory = ref([
  { content: '订单已创建，等待付款', timestamp: '2025-12-25 14:30:00' },
  { content: '订单已付款，等待发货', timestamp: '2025-12-25 14:35:00' },
  { content: '订单已发货，等待收货', timestamp: '2025-12-26 10:00:00' },
  { content: '包裹正在派送中', timestamp: '2025-12-27 09:00:00' }
])

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

// 获取退款状态文本
const getRefundStatusText = (status) => {
  const statusMap = {
    0: '申请中',
    1: '退款成功',
    2: '退款失败'
  }
  return statusMap[status] || '未知状态'
}

// 获取退款状态标签类型
const getRefundStatusType = (status) => {
  const typeMap = {
    0: 'warning',
    1: 'success',
    2: 'danger'
  }
  return typeMap[status] || 'info'
}

// 获取退款信息
const fetchRefundInfo = async (orderId) => {
  try {
    const res = await axios.get(`/refunds/order/${orderId}`)
    refundInfo.value = res.data.data.refund
  } catch (error) {
    console.error('获取退款信息失败:', error)
    // 静默失败，不影响订单详情的显示
  }
}

// 获取支付方式文本
const getPaymentMethodText = (method) => {
  const methodMap = {
    'wechat': '微信支付',
    'alipay': '支付宝',
    'online': '在线支付'
  }
  return methodMap[method] || '其他支付方式'
}

// 获取取货方式文本
const getPickupMethodText = (method) => {
  const methodMap = {
    'store_pickup': '线下到店自取',
    'delivery': '快递配送'
  }
  return methodMap[method] || '其他取货方式'
}

// 获取归还方式文本
const getReturnMethodText = (method) => {
  const methodMap = {
    'store_return': '线下到店归还',
    'delivery_return': '快递归还'
  }
  return methodMap[method] || '其他归还方式'
}

// 判断是否为租赁订单
const isRentalOrder = computed(() => {
  return orderDetail.value.orderItems && orderDetail.value.orderItems.some(item =>
    item.productType === 3 || item.productType === 'rental'
  )
})

// 判断租赁是否过期
const isRentalExpired = computed(() => {
  if (!isRentalOrder.value || !orderDetail.value.endDate) return false
  const endDate = new Date(orderDetail.value.endDate)
  const now = new Date()
  return now > endDate
})

// 判断租赁是否即将过期（3天内）
const isExpiringSoon = computed(() => {
  if (!isRentalOrder.value || !orderDetail.value.endDate) return false
  const endDate = new Date(orderDetail.value.endDate)
  const now = new Date()
  const diffTime = Math.abs(endDate - now)
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  return diffDays <= 3 && !isRentalExpired.value
})

// 格式化日期
const formatDate = (dateString) => {
  if (!dateString) return ''
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
  if (!specs) return ''
  try {
    const specsObj = JSON.parse(specs)
    return Object.entries(specsObj)
      .map(([key, value]) => `${key}: ${value}`)
      .join(' | ')
  } catch (error) {
    return specs
  }
}

// 获取订单详情
const fetchOrderDetail = async () => {
  try {
    loading.value = true
    const orderId = route.params.orderId
    const res = await axios.get(`/orders/${orderId}`)

    // 适配后端返回的数据结构
    const orderData = res.data.order
    const orderItems = res.data.orderItems || []

    // 直接使用后端返回的地址字段构建完整地址
    const fullAddress = `${orderData.province || ''}${orderData.city || ''}${orderData.district || ''}${orderData.detail || ''}`

    orderDetail.value = {
      ...orderData,
      fullAddress,
      orderItems
    }

    // 检查订单是否已经评价过
    if (orderData.orderStatus === 3) {
      try {
        const evaluationRes = await user.evaluation.getUserEvaluations()
        const evaluations = evaluationRes || []
        hasEvaluated.value = evaluations.some(evalItem => evalItem.orderId === orderData.orderId)
      } catch (error) {
        console.error('检查评价状态失败:', error)
        hasEvaluated.value = false
      }
    }

    // 根据订单状态更新物流信息
    updateLogisticsHistory(orderData.orderStatus)

    // 获取退款信息
    await fetchRefundInfo(orderData.orderId)
  } catch (error) {
    console.error('获取订单详情失败:', error)
    ElMessage.error('获取订单详情失败')
  } finally {
    loading.value = false
  }
}

// 根据订单状态更新物流信息
const updateLogisticsHistory = (orderStatus) => {
  // 基础物流信息
  const baseLogistics = [
    { content: '订单已创建，等待付款', timestamp: orderDetail.value.createTime || new Date().toLocaleString() }
  ]

  // 已取消订单的特殊处理
  if (orderStatus === 4) {
    baseLogistics.push({ content: '订单已取消', timestamp: new Date().toLocaleString() })
    logisticsHistory.value = baseLogistics
    return
  }

  // 根据订单状态添加不同的物流信息
  if (orderStatus >= 1) {
    baseLogistics.push({ content: '订单已付款，等待发货', timestamp: new Date().toLocaleString() })
  }

  if (orderStatus >= 2) {
    baseLogistics.push({ content: '订单已发货，等待收货', timestamp: new Date().toLocaleString() })
    baseLogistics.push({ content: '包裹正在派送中', timestamp: new Date().toLocaleString() })
  }

  // 普通订单完成状态
  if (orderStatus >= 3 && !isRentalOrder.value) {
    baseLogistics.push({ content: '包裹已送达，订单已完成', timestamp: new Date().toLocaleString() })
  }

  // 租赁订单特殊处理
  if (isRentalOrder.value) {
    // 租赁中状态
    if (orderStatus === 8) {
      baseLogistics.push({ content: '商品已送达，开始租赁', timestamp: new Date().toLocaleString() })

      // 租赁到期提醒
      if (orderDetail.value.endDate) {
        baseLogistics.push({
          content: `租赁即将到期，到期时间：${formatDate(orderDetail.value.endDate)}`,
          timestamp: new Date(new Date(orderDetail.value.endDate).getTime() - 3 * 24 * 60 * 60 * 1000).toLocaleString(),
          type: 'warning'
        })
      }
    }

    // 归还中状态
    if (orderStatus === 9) {
      baseLogistics.push({ content: '商品已送达，开始租赁', timestamp: new Date().toLocaleString() })

      // 租赁到期提醒
      if (orderDetail.value.endDate) {
        baseLogistics.push({
          content: `租赁即将到期，到期时间：${formatDate(orderDetail.value.endDate)}`,
          timestamp: new Date(new Date(orderDetail.value.endDate).getTime() - 3 * 24 * 60 * 60 * 1000).toLocaleString(),
          type: 'warning'
        })
      }

      baseLogistics.push({
        content: '商品已归还，商家确认中',
        timestamp: new Date().toLocaleString(),
        type: 'info'
      })
    }

    // 已完成状态
    if (orderStatus === 3) {
      baseLogistics.push({ content: '商品已送达，开始租赁', timestamp: new Date().toLocaleString() })

      // 租赁到期提醒
      if (orderDetail.value.endDate) {
        baseLogistics.push({
          content: `租赁即将到期，到期时间：${formatDate(orderDetail.value.endDate)}`,
          timestamp: new Date(new Date(orderDetail.value.endDate).getTime() - 3 * 24 * 60 * 60 * 1000).toLocaleString(),
          type: 'warning'
        })
      }

      baseLogistics.push({
        content: '商品已归还，商家确认中',
        timestamp: new Date().toLocaleString(),
        type: 'info'
      })

      baseLogistics.push({
        content: '商家已确认归还，押金将于3-5个工作日内退还',
        timestamp: new Date().toLocaleString(),
        type: 'success'
      })

      baseLogistics.push({
        content: '租赁订单已完成',
        timestamp: new Date().toLocaleString(),
        type: 'success'
      })
    }
  }

  logisticsHistory.value = baseLogistics
}

// 确认收货
const confirmReceive = async () => {
  try {
    const confirmMessage = isRentalOrder.value
      ? '确定已收到商品吗？确认后订单将进入租赁中状态'
      : '确定已收到商品吗？确认后订单将标记为已完成'

    await ElMessageBox.confirm(confirmMessage, '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })

    confirming.value = true
    const orderId = route.params.orderId
    await axios.post(`/orders/${orderId}/confirm-receive`)

    ElMessage.success('确认收货成功')
    // 重新获取订单详情
    await fetchOrderDetail()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('确认收货失败:', error)
      ElMessage.error('确认收货失败')
    }
  } finally {
    confirming.value = false
  }
}

// 打开评价对话框
const openEvaluationDialog = () => {
  // 对于多商品订单，默认选择第一个商品
  if (orderDetail.value.orderItems && orderDetail.value.orderItems.length > 0) {
    selectedProduct.value = orderDetail.value.orderItems[0]
    // 重置评价表单
    evaluationForm.value = {
      score: 5,
      qualityScore: 5,
      serviceScore: 5,
      logisticsScore: 5,
      content: ''
    }
    evaluationDialogVisible.value = true
  } else {
    ElMessage.warning('暂无商品可评价')
  }
}

// 提交评价
const submitEvaluation = async () => {
  if (!selectedProduct.value) return

  try {
    submittingEvaluation.value = true
    await user.evaluation.submitEvaluation({
      orderId: orderDetail.value.orderId,
      productId: selectedProduct.value.productId,
      score: evaluationForm.value.score,
      qualityScore: evaluationForm.value.qualityScore,
      serviceScore: evaluationForm.value.serviceScore,
      logisticsScore: isRentalOrder.value ? undefined : evaluationForm.value.logisticsScore,
      content: evaluationForm.value.content
    })

    ElMessage.success('评价提交成功')
    evaluationDialogVisible.value = false
    hasEvaluated.value = true // 标记订单已评价
  } catch (error) {
    console.error('提交评价失败:', error)
    ElMessage.error('提交评价失败')
  } finally {
    submittingEvaluation.value = false
  }
}

// 归还租赁商品
const handleReturn = async () => {
  try {
    await ElMessageBox.confirm('确定要归还商品吗？归还后将启动归还流程', '归还确认', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })

    const orderId = route.params.orderId
    await axios.post(`/orders/${orderId}/return`)

    ElMessage.success('归还成功，正在处理中')
    // 重新获取订单详情
    await fetchOrderDetail()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('归还失败:', error)
      ElMessage.error('归还失败')
    }
  }
}

// 返回上一页
const goBack = () => {
  router.back()
}

onMounted(() => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }
  fetchOrderDetail()
})
</script>

<style scoped>
.order-detail-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.page-header {
  margin-bottom: 30px;
  text-align: center;
  position: relative;
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
  margin-bottom: 20px;
  color: #333;
}

.order-content {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.1);
  padding: 20px;
}

.order-basic-info,
.order-address,
.order-products,
.order-logistics,
.order-amount {
  margin-bottom: 30px;
  padding-bottom: 20px;
  border-bottom: 1px solid #e0e0e0;
}

.order-basic-info:last-child,
.order-address:last-child,
.order-products:last-child,
.order-logistics:last-child,
.order-amount:last-child {
  border-bottom: none;
  margin-bottom: 0;
  padding-bottom: 0;
}

h3 {
  margin-bottom: 15px;
  color: #333;
  font-size: 16px;
}

.info-items {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.info-item {
  display: flex;
  align-items: center;
}

.info-item .label {
  color: #666;
  margin-right: 10px;
  min-width: 80px;
}

.info-item .value {
  color: #333;
  font-weight: 500;
}

.address-content {
  padding: 15px;
  background: #fafafa;
  border-radius: 4px;
}

.recipient-info {
  margin-bottom: 10px;
}

.recipient-info .name {
  font-weight: bold;
  margin-right: 15px;
}

.address-detail {
  color: #666;
  line-height: 1.4;
}

.products-list {
  border: 1px solid #e0e0e0;
  border-radius: 4px;
}

.product-item {
  display: flex;
  align-items: center;
  padding: 15px;
  border-bottom: 1px solid #e0e0e0;
}

.product-item:last-child {
  border-bottom: none;
}

.product-image {
  width: 80px;
  height: 80px;
  object-fit: contain;
  margin-right: 20px;
  border: 1px solid #e0e0e0;
  border-radius: 4px;
}

.product-info {
  flex: 1;
}

.product-name-wrapper {
  display: flex;
  align-items: center;
  margin-bottom: 5px;
}

.product-name {
  font-weight: 500;
  margin-right: 8px;
  color: #333;
}

.second-hand-tag {
  margin-left: 8px;
}

.product-brand,
.product-spec {
  font-size: 12px;
  color: #666;
  margin-bottom: 3px;
}

.product-price,
.product-quantity,
.product-total {
  width: 100px;
  text-align: center;
}

.product-price {
  color: #666;
}

.product-total {
  font-weight: bold;
  color: #ff4d4f;
}

.logistics-content {
  padding: 15px;
  background: #fafafa;
  border-radius: 4px;
}

.amount-items {
  max-width: 300px;
  margin-left: auto;
}

.amount-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
  padding: 8px 0;
}

.amount-item.total {
  border-top: 1px solid #e0e0e0;
  font-size: 18px;
  font-weight: bold;
  color: #ff4d4f;
}

.order-actions {
  display: flex;
  justify-content: center;
  margin-top: 30px;
  padding-top: 20px;
  border-top: 1px solid #e0e0e0;
}

/* 评价相关样式 */
.evaluation-product-info {
  display: flex;
  align-items: center;
  margin-bottom: 20px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 4px;
}

.evaluation-product-image {
  width: 80px;
  height: 80px;
  object-fit: contain;
  margin-right: 20px;
  border: 1px solid #e0e0e0;
  border-radius: 4px;
}

.evaluation-product-details {
  flex: 1;
}

.evaluation-product-name {
  font-weight: 500;
  margin-bottom: 5px;
  color: #333;
}

.evaluation-product-price {
  color: #ff4d4f;
  font-weight: bold;
}

.evaluation-form {
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

@media (max-width: 768px) {
  .order-detail-page {
    padding: 10px;
  }

  .order-content {
    padding: 15px;
  }

  .info-items {
    grid-template-columns: 1fr;
  }

  .product-item {
    flex-wrap: wrap;
  }

  .product-info {
    order: 2;
    width: 100%;
    margin-top: 10px;
  }

  .product-price,
  .product-quantity,
  .product-total {
    order: 1;
    width: auto;
    margin: 0 10px;
  }

  .amount-items {
    max-width: 100%;
  }

  .evaluation-product-info {
    flex-direction: column;
    align-items: flex-start;
  }

  .evaluation-product-image {
    margin-bottom: 10px;
  }
}
</style>
