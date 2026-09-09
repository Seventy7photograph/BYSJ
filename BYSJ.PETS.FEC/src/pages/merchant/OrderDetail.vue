<template>
  <div class="merchant-order-detail">
    <!-- 面包屑导航 -->
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item :to="'/merchant-dashboard'">后台首页</el-breadcrumb-item>
      <el-breadcrumb-item :to="'/merchant-dashboard/order-management'">订单管理</el-breadcrumb-item>
      <el-breadcrumb-item>订单详情</el-breadcrumb-item>
    </el-breadcrumb>

    <h2 class="page-title">订单详情</h2>

    <el-card class="order-info-card">
      <template #header>
        <div class="card-header">
          <span>订单基本信息</span>
          <el-button type="primary" size="small" @click="handleBack">返回订单列表</el-button>
        </div>
      </template>

      <div class="order-info-content">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="订单号">{{ orderDetail.orderNo }}</el-descriptions-item>
          <el-descriptions-item label="订单类型">
            <el-tag :type="orderDetail.orderType === 'new' ? 'success' : orderDetail.orderType === 'used' ? 'info' : 'warning'">
              {{ orderDetail.orderType === 'new' ? '全新商品' : orderDetail.orderType === 'used' ? '二手商品' : '租赁商品' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="订单状态">
            <el-tag :type="getStatusTagType(orderDetail.orderStatus)">
              {{ getStatusText(orderDetail.orderStatus) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="订单金额">¥{{ orderDetail.totalAmount }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ orderDetail.createTime }}</el-descriptions-item>
          <el-descriptions-item label="支付时间">{{ orderDetail.payTime || '未支付' }}</el-descriptions-item>
          <el-descriptions-item label="发货时间">{{ orderDetail.shipTime || '未发货' }}</el-descriptions-item>
          <el-descriptions-item label="完成时间">{{ orderDetail.completeTime || '未完成' }}</el-descriptions-item>
        </el-descriptions>
      </div>
    </el-card>

    <el-card class="customer-info-card" style="margin-top: 20px;">
      <template #header>
        <div class="card-header">
          <span>客户信息</span>
        </div>
      </template>

      <div class="customer-info-content">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="客户名称">{{ orderDetail.customerName }}</el-descriptions-item>
          <el-descriptions-item label="联系电话">{{ orderDetail.customerPhone }}</el-descriptions-item>
          <el-descriptions-item label="联系邮箱">{{ orderDetail.customerEmail }}</el-descriptions-item>
          <el-descriptions-item label="收货地址" :span="2">{{ orderDetail.shippingAddress }}</el-descriptions-item>
        </el-descriptions>
      </div>
    </el-card>

    <el-card class="product-list-card" style="margin-top: 20px;">
      <template #header>
        <div class="card-header">
          <span>商品列表</span>
        </div>
      </template>

      <div class="product-list-content">
        <el-table :data="orderDetail.products" stripe style="width: 100%">
          <el-table-column prop="productId" label="商品ID" width="80" />
          <el-table-column prop="productName" label="商品名称" min-width="200" />
          <el-table-column prop="productType" label="商品类型" width="100">
            <template #default="scope">
              <el-tag :type="scope.row.productType === 'new' ? 'success' : scope.row.productType === 'used' ? 'info' : 'warning'">
                {{ scope.row.productType === 'new' ? '全新' : scope.row.productType === 'used' ? '二手' : '租赁' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="price" label="单价" width="100">
            <template #default="scope">¥{{ scope.row.price }}</template>
          </el-table-column>
          <el-table-column prop="quantity" label="数量" width="80" />
          <el-table-column prop="totalPrice" label="小计" width="100">
            <template #default="scope">¥{{ scope.row.totalPrice }}</template>
          </el-table-column>
        </el-table>
      </div>
    </el-card>

    <el-card class="shipping-info-card" style="margin-top: 20px;">
      <template #header>
        <div class="card-header">
          <span>物流信息</span>
          <div>
            <el-button
              v-if="orderDetail.orderStatus === 1"
              type="primary"
              size="small"
              @click="handleShipOrder"
            >
              发货
            </el-button>
            <el-button
              v-if="orderDetail.orderStatus === 2"
              type="success"
              size="small"
              @click="handleConfirmReceive"
            >
              确认收货
            </el-button>
          </div>
        </div>
      </template>

      <div class="shipping-info-content">
        <div v-if="orderDetail.shippingInfo" class="shipping-detail">
          <el-descriptions :column="2" border>
            <el-descriptions-item label="物流公司">{{ orderDetail.shippingInfo.logisticsCompany }}</el-descriptions-item>
            <el-descriptions-item label="物流单号">{{ orderDetail.shippingInfo.trackingNumber }}</el-descriptions-item>
            <el-descriptions-item label="发货时间">{{ orderDetail.shippingInfo.shipTime }}</el-descriptions-item>
            <el-descriptions-item label="预计送达时间">{{ orderDetail.shippingInfo.estimatedDeliveryTime }}</el-descriptions-item>
          </el-descriptions>

          <div class="tracking-info" v-if="orderDetail.shippingInfo.trackingInfo">
            <h4>物流跟踪</h4>
            <el-timeline>
              <el-timeline-item
                v-for="(item, index) in orderDetail.shippingInfo.trackingInfo"
                :key="index"
                :timestamp="item.timestamp"
              >
                {{ item.description }}
              </el-timeline-item>
            </el-timeline>
          </div>
        </div>
        <div v-else-if="orderDetail.orderStatus < 2" class="no-shipping-info">
          <el-empty description="暂无物流信息" :image-size="100" />
          <el-button
            v-if="orderDetail.orderStatus === 1"
            type="primary"
            @click="handleShipOrder"
          >
            立即发货
          </el-button>
        </div>
      </div>
    </el-card>

    <el-card class="payment-info-card" style="margin-top: 20px;">
      <template #header>
        <div class="card-header">
          <span>支付信息</span>
        </div>
      </template>

      <div class="payment-info-content">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="支付方式">{{ orderDetail.paymentInfo?.paymentMethod || '未支付' }}</el-descriptions-item>
          <el-descriptions-item label="支付状态">
            <el-tag :type="orderDetail.paymentInfo?.paymentStatus === 'paid' ? 'success' : 'warning'">
              {{ orderDetail.paymentInfo?.paymentStatus === 'paid' ? '已支付' : '未支付' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="支付时间">{{ orderDetail.paymentInfo?.paymentTime || '未支付' }}</el-descriptions-item>
          <el-descriptions-item label="支付流水号">{{ orderDetail.paymentInfo?.transactionId || '未支付' }}</el-descriptions-item>
        </el-descriptions>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getOrderDetail as apiGetOrderDetail, shipOrder as apiShipOrder, confirmReceive as apiConfirmReceive } from '@/api/merchant/order'

const router = useRouter()
const route = useRoute()

// 订单详情类型定义
interface OrderProduct {
  productId: number;
  productName: string;
  productType: string;
  price: number;
  quantity: number;
  totalPrice: number;
}

// 订单ID - 初始化为空，在onMounted中获取
const orderId = ref<string | number>('')

// API返回的OrderItem类型
interface ApiOrderItem {
  itemId: number;
  orderId: number;
  productId: number;
  productName: string;
  productImage: string;
  unitPrice: number;
  quantity: number;
  specifications: string;
  brandName: string;
  productType: number;
  condition: string | null;
  deposit: number;
  freight: number;
  itemStatus: number;
  leaseTerm: number | null;
}

interface ShippingInfo {
  logisticsCompany: string;
  trackingNumber: string;
  shipTime: string;
  estimatedDeliveryTime: string;
  trackingInfo: {
    timestamp: string;
    description: string;
  }[];
}

interface OrderDetail {
  orderId: number;
  orderNo: string;
  orderType: string;
  orderStatus: number;
  totalAmount: number;
  createTime: string;
  payTime: string;
  shipTime: string;
  completeTime: string;
  customerName: string;
  customerPhone: string;
  customerEmail: string;
  shippingAddress: string;
  products: OrderProduct[];
  shippingInfo: ShippingInfo | null;
  paymentInfo: {
    paymentMethod: string;
    paymentStatus: string;
    paymentTime: string;
    transactionId: string;
  };
}

const orderDetail = ref<OrderDetail>({
  orderId: 0,
  orderNo: '',
  orderType: 'new',
  orderStatus: 1,
  totalAmount: 0,
  createTime: '',
  payTime: '',
  shipTime: '',
  completeTime: '',
  customerName: '',
  customerPhone: '',
  customerEmail: '',
  shippingAddress: '',
  products: [],
  shippingInfo: null,
  paymentInfo: {
    paymentMethod: '支付宝',
    paymentStatus: 'paid',
    paymentTime: '2025-12-29 14:35:00',
    transactionId: 'TXN202512290001'
  }
})

// 加载状态
const loading = ref(false)

// 获取订单状态标签类型
const getStatusTagType = (status: number) => {
  const typeMap: Record<number, string> = {
    0: 'warning',
    1: 'info',
    2: 'success',
    3: 'success',
    4: 'danger',
    5: 'primary',
    6: 'success'
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
    7: '退款失败'
  }
  return textMap[status] || '未知状态'
}

// 返回订单列表
const handleBack = () => {
  router.push('/merchant-dashboard/order-management')
}

// 获取订单详情
const getOrderDetail = async () => {
  loading.value = true
  try {
    // 调用真实API获取订单详情
    const response = await apiGetOrderDetail(orderId.value)
    const responseData = response.data
    const orderData = responseData.order
    const orderItems = responseData.orderItems || []

    // 适配API返回的数据结构
      // 将orderItems映射为符合OrderProduct接口的products数组
      const mappedProducts = (orderItems as ApiOrderItem[]).map((item: ApiOrderItem) => ({
        productId: item.productId || 0,
        productName: `${item.brandName || ''} ${item.productName || ''}`,
        productType: item.productType === 1 ? 'new' : item.productType === 2 ? 'used' : 'rental',
        price: item.unitPrice || 0,
        quantity: item.quantity || 0,
        totalPrice: (item.unitPrice || 0) * (item.quantity || 0)
      }));

      // 获取订单类型（取第一个商品的类型）
      const firstProductType = orderItems.length > 0 ? orderItems[0].productType : 1;

      // 格式化时间函数
      const formatTime = (timeStr: string) => {
        if (!timeStr) return '';
        const date = new Date(timeStr);
        return date.toLocaleString('zh-CN', {
          year: 'numeric',
          month: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit'
        });
      };

      // 为已发货的订单生成模拟物流信息
      let shippingInfo = null;
      if (orderData.orderStatus >= 2) { // 已发货或已完成的订单
        const shipTime = orderData.shipTime || new Date().toLocaleString();
        const completeTime = orderData.completeTime || new Date().toLocaleString();

        shippingInfo = {
          logisticsCompany: '顺丰速运',
          trackingNumber: 'SF' + Math.floor(Math.random() * 10000000000),
          shipTime: shipTime,
          estimatedDeliveryTime: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toLocaleString(),
          trackingInfo: [
            {
              timestamp: shipTime,
              description: '商家已发货，等待快递公司揽收'
            },
            {
              timestamp: new Date(Date.now() + 1 * 60 * 60 * 1000).toLocaleString(),
              description: '快递已揽收，正在前往分拣中心'
            },
            {
              timestamp: new Date(Date.now() + 6 * 60 * 60 * 1000).toLocaleString(),
              description: '快递已到达分拣中心，正在分拣'
            },
            {
              timestamp: new Date(Date.now() + 12 * 60 * 60 * 1000).toLocaleString(),
              description: '快递已离开分拣中心，正在前往目的地'
            }
          ]
        };

        // 如果订单已完成，添加已签收的物流信息
        if (orderData.orderStatus === 3) {
          shippingInfo.trackingInfo.push({
            timestamp: completeTime,
            description: '快递已送达，客户已签收'
          });
        }
      }

      orderDetail.value = {
        orderId: orderData.orderId || 0,
        orderNo: orderData.orderNo || '',
        orderType: firstProductType === 1 ? 'new' : firstProductType === 2 ? 'used' : 'rental',
        orderStatus: orderData.orderStatus || 0,
        totalAmount: orderData.totalAmount || 0,
        createTime: formatTime(orderData.createTime),
        payTime: formatTime(orderData.payTime),
        shipTime: formatTime(orderData.shipTime),
        completeTime: formatTime(orderData.completeTime),

        customerName: orderData.recipient || '',
        customerPhone: orderData.phone || '',
        customerEmail: '', // API可能不返回邮箱
        shippingAddress: `${orderData.province || ''}${orderData.city || ''}${orderData.district || ''}${orderData.detail || ''}`,
        products: mappedProducts,
        shippingInfo: shippingInfo,
        paymentInfo: {
          paymentMethod: orderData.paymentMethod || '',
          paymentStatus: orderData.orderStatus >= 1 ? 'paid' : 'unpaid', // 订单状态>=1时，支付状态为已支付
          paymentTime: orderData.payTime || '',
          transactionId: orderData.transactionId || '' // 使用后端返回的交易ID
        }
      }
  } catch (error) {
    console.error('获取订单详情失败:', error)
    ElMessage.error('获取订单详情失败，请稍后重试')
  } finally {
    loading.value = false
  }
}

// 发货
const handleShipOrder = async () => {
  ElMessageBox.confirm('确定要发货吗？', '发货确认', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    loading.value = true
    try {
      // 调用真实API发货，传递订单ID（数字类型）
      await apiShipOrder(orderDetail.value.orderId, {
        // 可以添加物流信息，这里暂时为空
      })

      // 更新订单状态
      orderDetail.value.orderStatus = 2
      orderDetail.value.shipTime = new Date().toLocaleString()
      orderDetail.value.shippingInfo = {
        logisticsCompany: '顺丰速运',
        trackingNumber: 'SF' + Math.floor(Math.random() * 10000000000),
        shipTime: orderDetail.value.shipTime,
        estimatedDeliveryTime: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toLocaleString(),
        trackingInfo: [
          {
            timestamp: orderDetail.value.shipTime,
            description: '商家已发货，等待快递公司揽收'
          }
        ]
      }

      // 确保支付状态保持为已支付
      orderDetail.value.paymentInfo.paymentStatus = 'paid'

      ElMessage.success('发货成功')
    } catch (error) {
      console.error('发货失败:', error)
      ElMessage.error('发货失败，请稍后重试')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消发货
  })
}

// 确认收货
const handleConfirmReceive = async () => {
  ElMessageBox.confirm('确定要确认收货吗？', '确认收货', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'success'
  }).then(async () => {
    loading.value = true
    try {
      // 调用真实API确认收货，传递订单ID（数字类型）
      await apiConfirmReceive(orderDetail.value.orderId)

      // 更新订单状态
      orderDetail.value.orderStatus = 3
      orderDetail.value.completeTime = new Date().toLocaleString()

      // 添加新的物流信息，标记为已签收
      if (orderDetail.value.shippingInfo) {
        const signTime = orderDetail.value.completeTime
        orderDetail.value.shippingInfo.trackingInfo.push({
          timestamp: signTime,
          description: '快递已送达，客户已签收'
        })
      }

      ElMessage.success('确认收货成功')
    } catch (error) {
      console.error('确认收货失败:', error)
      ElMessage.error('确认收货失败，请稍后重试')
    } finally {
      loading.value = false
    }
  }).catch(() => {
    // 取消确认收货
  })
}

// 页面加载时初始化
onMounted(() => {
  // 从路由参数获取订单ID
  const paramId = route.params.orderId as string;
  if (paramId) {
    orderId.value = paramId;
    getOrderDetail();
  } else {
    ElMessage.error('无效的订单ID');
    router.push('/merchant-dashboard/order-management');
  }
})
</script>

<style scoped>
.merchant-order-detail {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.page-title {
  font-size: 24px;
  margin-bottom: 20px;
  color: #333;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.order-info-card,
.customer-info-card,
.product-list-card,
.shipping-info-card,
.payment-info-card {
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
  margin-bottom: 20px;
}

.order-info-content,
.customer-info-content,
.product-list-content,
.shipping-info-content,
.payment-info-content {
  margin-top: 20px;
}

.no-shipping-info {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 50px 0;
  gap: 20px;
}

.shipping-detail {
  margin-top: 20px;
}

.tracking-info {
  margin-top: 20px;
}

.tracking-info h4 {
  font-size: 16px;
  margin-bottom: 15px;
  font-weight: bold;
  color: #304156;
}
</style>
