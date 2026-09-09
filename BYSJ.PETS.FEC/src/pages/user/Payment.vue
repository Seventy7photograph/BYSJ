<template>
  <div class="payment-page">
    <div class="page-header">
      <h1>支付订单</h1>
      <el-steps :active="2" align-center>
        <el-step title="确认订单" />
        <el-step title="支付" />
        <el-step title="完成" />
      </el-steps>
    </div>

    <div v-loading="loading" class="payment-content">
      <!-- 订单信息 -->
      <div class="order-info">
        <div class="order-header">
          <h3>订单信息</h3>
          <div class="order-no">订单号：{{ paymentInfo.orderNo }}</div>
        </div>
        <div class="order-details">
          <div class="detail-item">
            <span class="label">商品总价：</span>
            <span class="value">¥{{ paymentInfo.totalAmount.toFixed(2) }}</span>
          </div>
          <div class="detail-item">
            <span class="label">运费：</span>
            <span class="value">¥{{ paymentInfo.shippingFee.toFixed(2) }}</span>
          </div>
          <div class="detail-item total">
            <span class="label">应付金额：</span>
            <span class="value">¥{{ paymentInfo.payAmount.toFixed(2) }}</span>
          </div>
        </div>
      </div>

      <!-- 支付方式 -->
      <div class="payment-methods">
        <h3>选择支付方式</h3>
        <div class="methods-list">
          <div
            v-for="method in paymentMethods"
            :key="method.value"
            class="method-item"
            :class="{ active: selectedMethod === method.value }"
            @click="selectMethod(method.value)"
          >
            <img :src="method.icon" :alt="method.name" class="method-icon">
            <div class="method-info">
              <div class="method-name">{{ method.name }}</div>
              <div class="method-desc">{{ method.description }}</div>
            </div>
            <el-icon v-if="selectedMethod === method.value" class="check-icon">
              <Check />
            </el-icon>
          </div>
        </div>
      </div>

      <!-- 支付二维码 -->
      <div v-if="selectedMethod && qrCodeUrl" class="qr-code-section">
        <h3>扫码支付</h3>
        <div class="qr-code-container">
          <img :src="qrCodeUrl" alt="支付二维码" class="qr-code">
          <div class="qr-tips">
            <p>请使用{{ selectedMethod === 'wechat' ? '微信' : '支付宝' }}扫描二维码完成支付</p>
            <p class="amount">支付金额：<span>¥{{ paymentInfo.payAmount.toFixed(2) }}</span></p>
          </div>
        </div>
        <div class="payment-status">
          <el-alert
            v-if="paymentStatus === 'pending'"
            title="等待支付中..."
            type="info"
            :closable="false"
            show-icon
          />
          <el-alert
            v-else-if="paymentStatus === 'success'"
            title="支付成功！"
            type="success"
            :closable="false"
            show-icon
          />
          <el-alert
            v-else-if="paymentStatus === 'failed'"
            title="支付失败，请重试"
            type="error"
            :closable="false"
            show-icon
          />
        </div>
      </div>

      <!-- 支付按钮 -->
      <div class="payment-actions">
        <el-button @click="goBack">返回修改</el-button>
        <el-button
          type="primary"
          size="large"
          :loading="paying"
          @click="handlePayment"
          v-if="!qrCodeUrl"
        >
          立即支付 ¥{{ paymentInfo.payAmount.toFixed(2) }}
        </el-button>
        <el-button
          type="success"
          size="large"
          @click="checkPaymentStatus"
          v-else
        >
          我已支付完成
        </el-button>
        <el-button
          type="danger"
          size="large"
          @click="cancelOrder"
        >
          取消订单
        </el-button>
      </div>
    </div>

    <!-- 支付成功对话框 -->
    <el-dialog
      v-model="showSuccessDialog"
      title="支付成功"
      width="400px"
      :show-close="false"
      :close-on-click-modal="false"
      :close-on-press-escape="false"
    >
      <div class="success-content">
        <el-icon color="#67C23A" size="48">
          <SuccessFilled />
        </el-icon>
        <h3>支付成功！</h3>
        <p>订单号：{{ paymentInfo.orderNo }}</p>
        <p>支付金额：¥{{ paymentInfo.payAmount.toFixed(2) }}</p>
      </div>
      <template #footer>
        <el-button type="primary" @click="goToOrders">查看订单</el-button>
        <el-button @click="goToShop">继续购物</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Check, SuccessFilled } from '@element-plus/icons-vue'
import axios from '@/axios'
import { useUserStore } from '@/stores/user'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

// 支付信息
const paymentInfo = ref({
  orderNo: '',
  totalAmount: 0,
  shippingFee: 0,
  payAmount: 0
})
const loading = ref(true)
const paying = ref(false)
const paymentStatus = ref('pending') // pending, success, failed
const qrCodeUrl = ref('')
const showSuccessDialog = ref(false)

// 支付方式
const selectedMethod = ref(route.query.paymentMethod || 'wechat')
const paymentMethods = ref([
  {
    value: 'wechat',
    name: '微信支付',
    description: '推荐微信用户使用',
    icon: '/public/微信支付.png'
  },
  {
    value: 'alipay',
    name: '支付宝',
    description: '推荐支付宝用户使用',
    icon: '/public/支付宝支付.png'
  }
])

// 定时器用于轮询支付状态
let paymentPollTimer = null

// 获取支付信息
const fetchPaymentInfo = async () => {
  try {
    loading.value = true
    const paymentId = route.params.paymentId

    // 如果paymentId不存在，返回错误信息
    if (!paymentId) {
      ElMessage.error('支付订单信息有误，请返回重新提交订单')
      return
    }

    // 使用paymentId（实际是orderId）从订单接口获取真实的订单信息
    const res = await axios.get(`/orders/${paymentId}`)

    // 从订单详情中提取支付相关信息
    const orderData = res.data.order
    paymentInfo.value = {
      orderNo: orderData.orderNo,
      totalAmount: orderData.totalAmount,
      shippingFee: orderData.shippingFee,
      payAmount: orderData.payAmount
    }
  } catch (error) {
    console.error('获取支付信息失败:', error)
    ElMessage.error('获取支付信息失败')
  } finally {
    loading.value = false
  }
}

// 选择支付方式
const selectMethod = (method) => {
  selectedMethod.value = method
  qrCodeUrl.value = '' // 清空二维码
}

// 处理支付
const handlePayment = async () => {
  try {
    paying.value = true
    const paymentId = route.params.paymentId

    // 如果paymentId不存在，返回错误信息
    if (!paymentId) {
      ElMessage.error('支付订单信息有误，请返回重新提交订单')
      return
    }

    // 调用真实的支付接口
    const res = await axios.post(`/orders/pay/${paymentId}`, {
      paymentMethod: selectedMethod.value
    })

    // 生成支付二维码（模拟）
    qrCodeUrl.value = 'https://picsum.photos/200/200?random=' + Date.now()
    startPaymentPolling(paymentId)
  } catch (error) {
    console.error('创建支付二维码失败:', error)
    ElMessage.error('创建支付二维码失败')
  } finally {
    paying.value = false
  }
}

// 开始轮询支付状态
const startPaymentPolling = (paymentId) => {
  paymentPollTimer = setInterval(async () => {
    try {
      // 这里应该调用后端接口查询支付状态
      // 由于后端还没有实现/payments/*接口，这里暂时不自动设置支付状态
      // 支付状态由用户手动确认
    } catch (error) {
      console.error('查询支付状态失败:', error)
    }
  }, 3000) // 每3秒查询一次
}

// 手动检查支付状态
const checkPaymentStatus = async () => {
  try {
    const paymentId = route.params.paymentId

    // 如果paymentId不存在，返回错误信息
    if (!paymentId) {
      ElMessage.error('支付订单信息有误，请返回重新提交订单')
      return
    }

    // 调用真实的支付接口，完成支付
    const res = await axios.post(`/orders/pay/${paymentId}`, {
      paymentMethod: selectedMethod.value
    })

    // 支付成功
    paymentStatus.value = 'success'
    showSuccessDialog.value = true
    if (paymentPollTimer) {
      clearInterval(paymentPollTimer)
    }
  } catch (error) {
    console.error('检查支付状态失败:', error)
    ElMessage.error('检查支付状态失败')
  }
}

// 取消订单
const cancelOrder = async () => {
  try {
    await ElMessageBox.confirm('确定要取消订单吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })

    const paymentId = route.params.paymentId

    // 如果paymentId不存在，返回错误信息
    if (!paymentId) {
      ElMessage.error('支付订单信息有误，请返回重新提交订单')
      return
    }

    // 由于后端还没有实现/payments/*接口，这里直接返回成功
    ElMessage.success('订单已取消')
    router.push('/orders')
  } catch (error) {
    if (error !== 'cancel') {
      console.error('取消订单失败:', error)
      ElMessage.error('取消订单失败')
    }
  }
}

// 返回上一步
const goBack = () => {
  const paymentId = route.params.paymentId
  // 返回到订单确认页面，并携带订单ID
  router.push({
    path: '/order/confirm',
    query: { orderId: paymentId }
  })
}

// 跳转到订单页面
const goToOrders = () => {
  router.push('/orders')
}

// 跳转到商城
const goToShop = () => {
  router.push('/shop')
}

// 清理定时器
onUnmounted(() => {
  if (paymentPollTimer) {
    clearInterval(paymentPollTimer)
  }
})

onMounted(() => {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    router.push('/login')
    return
  }
  fetchPaymentInfo()
})
</script>

<style scoped>
.payment-page {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.page-header {
  margin-bottom: 30px;
  text-align: center;
}

.page-header h1 {
  margin-bottom: 20px;
  color: #333;
}

.payment-content {
  background: white;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.1);
}

.order-info {
  margin-bottom: 30px;
  padding-bottom: 20px;
  border-bottom: 1px solid #e0e0e0;
}

.order-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.order-header h3 {
  margin: 0;
}

.order-no {
  color: #666;
  font-size: 14px;
}

.order-details {
  max-width: 300px;
}

.detail-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
  padding: 8px 0;
}

.detail-item.total {
  border-top: 1px solid #e0e0e0;
  font-size: 18px;
  font-weight: bold;
  color: #ff4d4f;
}

.payment-methods {
  margin-bottom: 30px;
}

.payment-methods h3 {
  margin-bottom: 15px;
}

.methods-list {
  display: grid;
  gap: 10px;
}

.method-item {
  display: flex;
  align-items: center;
  padding: 15px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
  position: relative;
}

.method-item.active {
  border-color: #409EFF;
  background: #f0f9ff;
}

.method-item:hover {
  border-color: #409EFF;
}

.method-icon {
  width: 40px;
  height: 40px;
  margin-right: 15px;
}

.method-info {
  flex: 1;
}

.method-name {
  font-weight: 500;
  margin-bottom: 5px;
}

.method-desc {
  font-size: 12px;
  color: #666;
}

.check-icon {
  color: #409EFF;
  font-size: 20px;
}

.qr-code-section {
  text-align: center;
  margin-bottom: 30px;
}

.qr-code-container {
  display: inline-block;
  padding: 20px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  margin: 20px 0;
}

.qr-code {
  width: 200px;
  height: 200px;
  display: block;
  margin: 0 auto 15px;
}

.qr-tips {
  text-align: center;
}

.qr-tips .amount {
  margin-top: 10px;
  font-weight: bold;
}

.qr-tips .amount span {
  color: #ff4d4f;
  font-size: 18px;
}

.payment-status {
  margin: 20px 0;
}

.payment-actions {
  display: flex;
  justify-content: center;
  gap: 15px;
  padding-top: 20px;
  border-top: 1px solid #e0e0e0;
}

.success-content {
  text-align: center;
  padding: 20px 0;
}

.success-content h3 {
  margin: 15px 0 10px;
  color: #67C23A;
}

.success-content p {
  margin: 5px 0;
  color: #666;
}

@media (max-width: 768px) {
  .payment-content {
    padding: 20px;
  }

  .order-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }

  .payment-actions {
    flex-direction: column;
  }

  .qr-code {
    width: 150px;
    height: 150px;
  }
}
</style>
